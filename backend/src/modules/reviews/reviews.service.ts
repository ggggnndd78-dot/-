import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { AuditService } from '../audit/audit.service';
import { NotificationsService } from '../notifications/notifications.service';
import {
  CreateMerchantReviewDto,
  CreateProductReviewDto,
  CreateServiceReviewDto,
  CreateWorkshopReviewDto,
  DtoReviewModerationActionType,
  DtoReviewTargetType,
  ModerateReviewDto,
  ReplyToReviewDto,
  ReportReviewDto,
} from './dto/reviews.dto';

type TargetType = 'PRODUCT' | 'MERCHANT' | 'WORKSHOP' | 'SERVICE';

const REVIEW_MODEL: Record<TargetType, string> = {
  PRODUCT: 'productReview',
  MERCHANT: 'merchantReview',
  WORKSHOP: 'workshopReview',
  SERVICE: 'serviceReview',
};

const REVIEW_ID_FIELD: Record<TargetType, string> = {
  PRODUCT: 'productReviewId',
  MERCHANT: 'merchantReviewId',
  WORKSHOP: 'workshopReviewId',
  SERVICE: 'serviceReviewId',
};

@Injectable()
export class ReviewsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    private readonly notifications: NotificationsService,
  ) {}

  private get db() { return this.prisma as any; }

  private normalizeTarget(targetType: string): TargetType {
    const upper = String(targetType).toUpperCase();
    if (!['PRODUCT', 'MERCHANT', 'WORKSHOP', 'SERVICE'].includes(upper)) {
      throw new BadRequestException({ message: 'نوع التقييم غير صحيح', error_code: 'INVALID_REVIEW_TARGET' });
    }
    return upper as TargetType;
  }

  private assertRating(rating: number) {
    if (!Number.isInteger(rating) || rating < 1 || rating > 5) {
      throw new BadRequestException({ message: 'التقييم يجب أن يكون من 1 إلى 5', error_code: 'INVALID_RATING' });
    }
  }

  private async assertNotOrganizationMember(userId: number, organizationId: number) {
    const member = await this.db.organizationMember.findFirst({ where: { userId, organizationId, status: { not: 'REMOVED' } } });
    if (member) {
      throw new ForbiddenException({ message: 'لا يمكن تقييم مؤسسة أنت عضو فيها', error_code: 'SELF_REVIEW_DENIED' });
    }
  }

  private async assertOrganizationMember(userId: number, organizationId: number) {
    const member = await this.db.organizationMember.findFirst({ where: { userId, organizationId, status: 'ACTIVE' } });
    if (!member) {
      throw new ForbiddenException({ message: 'ليس لديك صلاحية الرد باسم هذه المؤسسة', error_code: 'REVIEW_REPLY_ORG_DENIED' });
    }
    return member;
  }

  private async verifyDeliveredOrder(userId: number, orderId: number) {
    const order = await this.db.order.findFirst({
      where: { id: orderId, userId },
      include: { items: { include: { listing: { include: { product: true, organization: true } } } }, organization: true },
    });
    if (!order) throw new ForbiddenException({ message: 'لا يمكنك تقييم طلب لا يخصك', error_code: 'ORDER_REVIEW_DENIED' });
    if (order.status !== 'DELIVERED') throw new BadRequestException({ message: 'يمكن التقييم بعد اكتمال الطلب فقط', error_code: 'ORDER_NOT_DELIVERED' });
    return order;
  }

  private async verifyCompletedServiceOrder(userId: number, serviceOrderId: number) {
    const serviceOrder = await this.db.serviceOrder.findFirst({
      where: { id: serviceOrderId, userId },
      include: { organization: true, workshopService: true },
    });
    if (!serviceOrder) throw new ForbiddenException({ message: 'لا يمكنك تقييم خدمة لا تخصك', error_code: 'SERVICE_REVIEW_DENIED' });
    if (serviceOrder.status !== 'COMPLETED') throw new BadRequestException({ message: 'يمكن تقييم الخدمة بعد اكتمالها فقط', error_code: 'SERVICE_ORDER_NOT_COMPLETED' });
    return serviceOrder;
  }

  private reviewInclude() {
    return { user: { select: { id: true, displayName: true } }, replies: { include: { author: { select: { id: true, displayName: true } }, organization: true }, orderBy: { createdAt: 'asc' } }, media: true } as any;
  }

  private async createMedia(tx: any, targetType: TargetType, reviewId: number, userId: number, media?: { mediaUrl: string; mediaType?: string }[]) {
    if (!media?.length) return;
    const field = REVIEW_ID_FIELD[targetType];
    await tx.reviewMedia.createMany({
      data: media.slice(0, 6).map((item, index) => ({
        targetType,
        [field]: reviewId,
        uploadedByUserId: userId,
        mediaUrl: item.mediaUrl,
        mediaType: item.mediaType ?? 'image',
        sortOrder: index,
      })),
    });
  }

  private async replaceMedia(tx: any, targetType: TargetType, reviewId: number, userId: number, media?: { mediaUrl: string; mediaType?: string }[]) {
    if (!media) return;
    const field = REVIEW_ID_FIELD[targetType];
    await tx.reviewMedia.deleteMany({ where: { [field]: reviewId } });
    await this.createMedia(tx, targetType, reviewId, userId, media);
  }

  private async notifyOrganizationReview(organizationId: number, title: string, body: string, data: Record<string, unknown>) {
    const members = await this.db.organizationMember.findMany({ where: { organizationId, status: 'ACTIVE' }, take: 20 });
    await Promise.all(members.map((m: any) => this.notifications.dispatchToUser(m.userId, { title, body, data, sendInApp: true, sendPush: true, eventKey: 'review_event' }).catch(() => null)));
  }

  async createProductReview(userId: number, dto: CreateProductReviewDto) {
    this.assertRating(dto.rating);
    const order = await this.verifyDeliveredOrder(userId, dto.orderId);
    const item = order.items.find((entry: any) => Number(entry.listing?.productId) === Number(dto.productId));
    if (!item) throw new BadRequestException({ message: 'لا يمكن تقييم منتج لم يتم شراؤه في هذا الطلب', error_code: 'PRODUCT_NOT_PURCHASED' });
    await this.assertNotOrganizationMember(userId, item.listing.organizationId);

    const data = await this.db.$transaction(async (tx: any) => {
      const existing = await tx.productReview.findFirst({ where: { userId, productId: dto.productId, orderId: dto.orderId } });
      const review = existing
        ? await tx.productReview.update({ where: { id: existing.id }, data: { rating: dto.rating, title: dto.title ?? null, body: dto.body ?? null, status: 'PUBLISHED' } })
        : await tx.productReview.create({ data: { userId, productId: dto.productId, orderId: dto.orderId, rating: dto.rating, title: dto.title ?? null, body: dto.body ?? null } });
      await this.replaceMedia(tx, 'PRODUCT', review.id, userId, dto.media);
      return review;
    });
    await this.refreshReputation('PRODUCT', dto.productId, item.listing.organizationId);
    await this.audit.write({ actorUserId: userId, action: 'reviews.product.saved', entityType: 'product_review', entityId: data.id, metadata: { product_id: dto.productId, order_id: dto.orderId } });
    await this.notifyOrganizationReview(item.listing.organizationId, 'تقييم جديد على منتج', 'تم إضافة تقييم جديد لمنتج من منتجاتكم.', { type: 'PRODUCT', review_id: data.id });
    return { success: true, message: 'Product review saved', data };
  }

  async createMerchantReview(userId: number, dto: CreateMerchantReviewDto) {
    this.assertRating(dto.rating);
    const order = await this.verifyDeliveredOrder(userId, dto.orderId);
    if (Number(order.organizationId) !== Number(dto.organizationId)) throw new BadRequestException({ message: 'هذا الطلب لا يتبع التاجر المحدد', error_code: 'ORDER_ORGANIZATION_MISMATCH' });
    await this.assertNotOrganizationMember(userId, dto.organizationId);

    const data = await this.db.$transaction(async (tx: any) => {
      const existing = await tx.merchantReview.findFirst({ where: { userId, organizationId: dto.organizationId, orderId: dto.orderId } });
      const review = existing
        ? await tx.merchantReview.update({ where: { id: existing.id }, data: { rating: dto.rating, title: dto.title ?? null, body: dto.body ?? null, status: 'PUBLISHED' } })
        : await tx.merchantReview.create({ data: { userId, organizationId: dto.organizationId, orderId: dto.orderId, rating: dto.rating, title: dto.title ?? null, body: dto.body ?? null } });
      await this.replaceMedia(tx, 'MERCHANT', review.id, userId, dto.media);
      return review;
    });
    await this.refreshReputation('MERCHANT', dto.organizationId, dto.organizationId);
    await this.audit.write({ actorUserId: userId, action: 'reviews.merchant.saved', entityType: 'merchant_review', entityId: data.id, metadata: { organization_id: dto.organizationId, order_id: dto.orderId } });
    await this.notifyOrganizationReview(dto.organizationId, 'تقييم جديد للمتجر', 'تم إضافة تقييم جديد لمؤسستكم.', { type: 'MERCHANT', review_id: data.id });
    return { success: true, message: 'Merchant review saved', data };
  }

  async createWorkshopReview(userId: number, dto: CreateWorkshopReviewDto) {
    this.assertRating(dto.rating);
    const serviceOrder = await this.verifyCompletedServiceOrder(userId, dto.serviceOrderId);
    if (Number(serviceOrder.organizationId) !== Number(dto.organizationId)) throw new BadRequestException({ message: 'أمر الخدمة لا يتبع الورشة المحددة', error_code: 'SERVICE_ORGANIZATION_MISMATCH' });
    await this.assertNotOrganizationMember(userId, dto.organizationId);

    const data = await this.db.$transaction(async (tx: any) => {
      const existing = await tx.workshopReview.findFirst({ where: { userId, organizationId: dto.organizationId, serviceOrderId: dto.serviceOrderId } });
      const review = existing
        ? await tx.workshopReview.update({ where: { id: existing.id }, data: { rating: dto.rating, title: dto.title ?? null, body: dto.body ?? null, status: 'PUBLISHED' } })
        : await tx.workshopReview.create({ data: { userId, organizationId: dto.organizationId, serviceOrderId: dto.serviceOrderId, rating: dto.rating, title: dto.title ?? null, body: dto.body ?? null } });
      await this.replaceMedia(tx, 'WORKSHOP', review.id, userId, dto.media);
      return review;
    });
    await this.refreshReputation('WORKSHOP', dto.organizationId, dto.organizationId);
    await this.audit.write({ actorUserId: userId, action: 'reviews.workshop.saved', entityType: 'workshop_review', entityId: data.id, metadata: { organization_id: dto.organizationId, service_order_id: dto.serviceOrderId } });
    await this.notifyOrganizationReview(dto.organizationId, 'تقييم جديد للورشة', 'تم إضافة تقييم جديد لورشتكم.', { type: 'WORKSHOP', review_id: data.id });
    return { success: true, message: 'Workshop review saved', data };
  }

  async createServiceReview(userId: number, dto: CreateServiceReviewDto) {
    this.assertRating(dto.rating);
    const serviceOrder = await this.verifyCompletedServiceOrder(userId, dto.serviceOrderId);
    await this.assertNotOrganizationMember(userId, serviceOrder.organizationId);
    const targetId = serviceOrder.workshopServiceId ?? serviceOrder.id;

    const data = await this.db.$transaction(async (tx: any) => {
      const existing = await tx.serviceReview.findFirst({ where: { userId, serviceOrderId: dto.serviceOrderId } });
      const review = existing
        ? await tx.serviceReview.update({ where: { id: existing.id }, data: { rating: dto.rating, title: dto.title ?? null, body: dto.body ?? null, status: 'PUBLISHED' } })
        : await tx.serviceReview.create({ data: { userId, organizationId: serviceOrder.organizationId, workshopServiceId: serviceOrder.workshopServiceId ?? null, serviceOrderId: dto.serviceOrderId, rating: dto.rating, title: dto.title ?? null, body: dto.body ?? null } });
      await this.replaceMedia(tx, 'SERVICE', review.id, userId, dto.media);
      return review;
    });
    await this.refreshReputation('SERVICE', targetId, serviceOrder.organizationId);
    await this.audit.write({ actorUserId: userId, action: 'reviews.service.saved', entityType: 'service_review', entityId: data.id, metadata: { service_order_id: dto.serviceOrderId, organization_id: serviceOrder.organizationId } });
    await this.notifyOrganizationReview(serviceOrder.organizationId, 'تقييم جديد لخدمة', 'تم إضافة تقييم جديد لخدمة من خدماتكم.', { type: 'SERVICE', review_id: data.id });
    return { success: true, message: 'Service review saved', data };
  }

  private async findReview(targetType: TargetType, reviewId: number) {
    const model = REVIEW_MODEL[targetType];
    const include = targetType === 'PRODUCT'
      ? { order: true, product: true, replies: true, media: true }
      : targetType === 'SERVICE'
        ? { organization: true, serviceOrder: true, workshopService: true, replies: true, media: true }
        : { organization: true, replies: true, media: true, ...(targetType === 'MERCHANT' ? { order: true } : { serviceOrder: true }) };
    const review = await this.db[model].findUnique({ where: { id: reviewId }, include });
    if (!review) throw new NotFoundException({ message: 'التقييم غير موجود', error_code: 'REVIEW_NOT_FOUND' });
    return review;
  }

  private ownerOrganizationForReview(targetType: TargetType, review: any) {
    if (targetType === 'PRODUCT') return review.order?.organizationId ?? null;
    return review.organizationId;
  }

  async replyToReview(userId: number, dto: ReplyToReviewDto) {
    const targetType = this.normalizeTarget(dto.targetType);
    const review = await this.findReview(targetType, dto.reviewId);
    const ownerOrgId = this.ownerOrganizationForReview(targetType, review);
    if (!ownerOrgId || Number(ownerOrgId) !== Number(dto.organizationId)) throw new ForbiddenException({ message: 'لا يمكن الرد على تقييم لا يخص مؤسستك', error_code: 'REVIEW_REPLY_TARGET_DENIED' });
    await this.assertOrganizationMember(userId, dto.organizationId);
    const field = REVIEW_ID_FIELD[targetType];
    const reply = await this.db.reviewReply.create({ data: { targetType, [field]: dto.reviewId, organizationId: dto.organizationId, authorUserId: userId, body: dto.body } });
    await this.audit.write({ actorUserId: userId, action: 'reviews.reply.created', entityType: 'review_reply', entityId: reply.id, metadata: { target_type: targetType, review_id: dto.reviewId, organization_id: dto.organizationId } });
    await this.notifications.dispatchToUser(review.userId, { title: 'رد جديد على تقييمك', body: 'تم الرد على تقييمك من قبل المؤسسة.', data: { target_type: targetType, review_id: dto.reviewId }, sendInApp: true, sendPush: true, eventKey: 'review_replied' }).catch(() => null);
    return { success: true, message: 'Review reply saved', data: reply };
  }

  async reportReview(userId: number, dto: ReportReviewDto) {
    const targetType = this.normalizeTarget(dto.targetType);
    await this.findReview(targetType, dto.reviewId);
    const field = REVIEW_ID_FIELD[targetType];
    const action = await this.db.reviewModerationAction.create({ data: { targetType, [field]: dto.reviewId, actorUserId: userId, actionType: 'REPORTED', reason: dto.reason ?? null } });
    await this.audit.write({ actorUserId: userId, action: 'reviews.reported', entityType: 'review_moderation_action', entityId: action.id, metadata: { target_type: targetType, review_id: dto.reviewId } });
    return { success: true, message: 'Review reported', data: action };
  }

  async moderateReview(userId: number, dto: ModerateReviewDto) {
    const targetType = this.normalizeTarget(dto.targetType);
    await this.findReview(targetType, dto.reviewId);
    const model = REVIEW_MODEL[targetType];
    const field = REVIEW_ID_FIELD[targetType];
    const status = dto.action === DtoReviewModerationActionType.RESTORED ? 'PUBLISHED' : dto.action === DtoReviewModerationActionType.HIDDEN ? 'HIDDEN' : dto.action === DtoReviewModerationActionType.REJECTED ? 'REJECTED' : undefined;
    if (!status) throw new BadRequestException({ message: 'إجراء المراجعة غير مسموح هنا', error_code: 'INVALID_MODERATION_ACTION' });
    const updated = await this.db.$transaction(async (tx: any) => {
      const review = await tx[model].update({ where: { id: dto.reviewId }, data: { status } });
      await tx.reviewModerationAction.create({ data: { targetType, [field]: dto.reviewId, actorUserId: userId, actionType: dto.action, reason: dto.reason ?? null } });
      return review;
    });
    const targetId = targetType === 'PRODUCT' ? updated.productId : targetType === 'SERVICE' ? (updated.workshopServiceId ?? updated.serviceOrderId) : updated.organizationId;
    await this.refreshReputation(targetType, targetId, targetType === 'PRODUCT' ? null : updated.organizationId);
    await this.audit.write({ actorUserId: userId, action: 'reviews.moderated', entityType: model, entityId: dto.reviewId, metadata: { target_type: targetType, status, reason: dto.reason ?? null } });
    return { success: true, message: 'Review moderated', data: updated };
  }

  async myReviews(userId: number) {
    const [products, merchants, workshops, services] = await Promise.all([
      this.db.productReview.findMany({ where: { userId }, include: { product: true, media: true, replies: true }, orderBy: { createdAt: 'desc' } }),
      this.db.merchantReview.findMany({ where: { userId }, include: { organization: true, media: true, replies: true }, orderBy: { createdAt: 'desc' } }),
      this.db.workshopReview.findMany({ where: { userId }, include: { organization: true, media: true, replies: true }, orderBy: { createdAt: 'desc' } }),
      this.db.serviceReview.findMany({ where: { userId }, include: { organization: true, workshopService: true, media: true, replies: true }, orderBy: { createdAt: 'desc' } }),
    ]);
    return { success: true, data: { products, merchants, workshops, services } };
  }

  async publicReviews(targetTypeRaw: string, targetId: number) {
    const targetType = this.normalizeTarget(targetTypeRaw);
    const model = REVIEW_MODEL[targetType];
    const where = targetType === 'PRODUCT'
      ? { productId: targetId, status: 'PUBLISHED' }
      : targetType === 'SERVICE'
        ? { workshopServiceId: targetId, status: 'PUBLISHED' }
        : { organizationId: targetId, status: 'PUBLISHED' };
    const [reviews, summary] = await Promise.all([
      this.db[model].findMany({ where, include: this.reviewInclude(), orderBy: { createdAt: 'desc' }, take: 100 }),
      this.db.reviewReputationSummary.findUnique({ where: { targetType_targetId: { targetType, targetId } } }).catch(() => null),
    ]);
    const average = summary ? Number(summary.averageRating) : reviews.length ? reviews.reduce((sum: number, r: any) => sum + Number(r.rating), 0) / reviews.length : 0;
    return { success: true, data: { average, count: reviews.length, summary, reviews } };
  }

  async reputation(targetTypeRaw: string, targetId: number) {
    const targetType = this.normalizeTarget(targetTypeRaw);
    const data = await this.db.reviewReputationSummary.findUnique({ where: { targetType_targetId: { targetType, targetId } } }).catch(() => null);
    return { success: true, data: data ?? { targetType, targetId, averageRating: 0, totalReviews: 0, reputationScore: 0 } };
  }

  async adminList(params: { targetType?: string; status?: string }) {
    const targetTypes: TargetType[] = params.targetType ? [this.normalizeTarget(params.targetType)] : ['PRODUCT', 'MERCHANT', 'WORKSHOP', 'SERVICE'];
    const result: Record<string, any[]> = {};
    for (const targetType of targetTypes) {
      const model = REVIEW_MODEL[targetType];
      result[targetType.toLowerCase()] = await this.db[model].findMany({
        where: params.status ? { status: params.status } : undefined,
        include: this.reviewInclude(),
        orderBy: { createdAt: 'desc' },
        take: 100,
      });
    }
    return { success: true, data: result };
  }

  async refreshReputation(targetType: TargetType, targetId: number, organizationId?: number | null) {
    const model = REVIEW_MODEL[targetType];
    const where = targetType === 'PRODUCT'
      ? { productId: targetId, status: 'PUBLISHED' }
      : targetType === 'SERVICE'
        ? { workshopServiceId: targetId, status: 'PUBLISHED' }
        : { organizationId: targetId, status: 'PUBLISHED' };
    const reviews = await this.db[model].findMany({ where, select: { rating: true } });
    const counts: Record<number, number> = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 };
    let sum = 0;
    for (const r of reviews) { const value = Number(r.rating); counts[value] = (counts[value] ?? 0) + 1; sum += value; }
    const total = reviews.length;
    const average = total ? Number((sum / total).toFixed(2)) : 0;
    const reputationScore = total ? Number(((average / 5) * 80 + Math.min(total, 100) * 0.2).toFixed(2)) : 0;
    return this.db.reviewReputationSummary.upsert({
      where: { targetType_targetId: { targetType, targetId } },
      update: { organizationId: organizationId ?? null, averageRating: average, totalReviews: total, rating1Count: counts[1], rating2Count: counts[2], rating3Count: counts[3], rating4Count: counts[4], rating5Count: counts[5], reputationScore },
      create: { targetType, targetId, organizationId: organizationId ?? null, averageRating: average, totalReviews: total, rating1Count: counts[1], rating2Count: counts[2], rating3Count: counts[3], rating4Count: counts[4], rating5Count: counts[5], reputationScore },
    }).catch(() => null);
  }
}
