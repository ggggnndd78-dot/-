import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { AuditService } from '../audit/audit.service';
import { NotificationsService } from '../notifications/notifications.service';
import { ReviewsService } from '../reviews/reviews.service';
import {
  AddTicketMessageDto,
  AssignSupportTicketDto,
  CreateComplaintDto,
  CreateMerchantReviewDto,
  CreateProductReviewDto,
  CreateSupportTicketDto,
  CreateWorkshopReviewDto,
  ModerateReviewDto,
  UpdateComplaintStatusDto,
  UpdateSupportTicketStatusDto,
  UpsertFaqDto,
  UpsertHelpCenterArticleDto,
  UpsertHelpCenterCategoryDto,
  UpsertWhatsappSupportLinkDto,
} from './dto/support.dto';

const SUPPORT_ADMIN_PERMISSIONS = [
  'support.tickets.manage',
  'support.content.manage',
  'support.whatsapp.manage',
  'manage_support',
  'manage_complaints',
  'manage_reviews',
  'manage_system',
];
const TERMINAL_TICKET_STATUSES = ['RESOLVED', 'CLOSED'];
const SUPPORT_VISIBLE_TAKE = 100;

@Injectable()
export class SupportService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notifications: NotificationsService,
    private readonly audit: AuditService,
    private readonly reviews: ReviewsService,
  ) {}
  private get db() { return this.prisma as any; }

  private async userPermissions(userId: number): Promise<string[]> {
    const userRoles = await this.db.userRole.findMany({
      where: { userId },
      include: { role: { include: { rolePermissions: { include: { permission: true } } } } },
    });
    return userRoles.flatMap((ur: any) => ur.role.rolePermissions.map((rp: any) => rp.permission.code));
  }

  private async isSupportAdmin(userId: number) {
    const permissions = await this.userPermissions(userId);
    return permissions.some((code) => SUPPORT_ADMIN_PERMISSIONS.includes(code));
  }

  private async assertSupportAdmin(userId: number) {
    if (!(await this.isSupportAdmin(userId))) {
      throw new ForbiddenException({ message: 'ليس لديك صلاحية إدارة الدعم', error_code: 'SUPPORT_ACCESS_DENIED' });
    }
  }

  private async assertOrganizationAccess(userId: number, organizationId: number) {
    const member = await this.db.organizationMember.findFirst({ where: { userId, organizationId } });
    if (!member && !(await this.isSupportAdmin(userId))) {
      throw new ForbiddenException({ message: 'ليس لديك صلاحية على هذه المؤسسة', error_code: 'ORGANIZATION_ACCESS_DENIED' });
    }
    return member;
  }

  private async ticketNumber(tx: any) {
    const d = new Date();
    const date = `${d.getFullYear()}${String(d.getMonth() + 1).padStart(2, '0')}${String(d.getDate()).padStart(2, '0')}`;
    for (let i = 0; i < 5; i += 1) {
      const value = `TKT-${date}-${Math.floor(100000 + Math.random() * 900000)}`;
      if (!(await tx.supportTicket.findUnique({ where: { ticketNumber: value } }))) return value;
    }
    throw new BadRequestException({ message: 'تعذر توليد رقم تذكرة', error_code: 'TICKET_NUMBER_FAILED' });
  }

  private async complaintNumber(tx: any) {
    const d = new Date();
    const date = `${d.getFullYear()}${String(d.getMonth() + 1).padStart(2, '0')}${String(d.getDate()).padStart(2, '0')}`;
    for (let i = 0; i < 5; i += 1) {
      const value = `CMP-${date}-${Math.floor(100000 + Math.random() * 900000)}`;
      if (!(await tx.complaint.findUnique({ where: { complaintNumber: value } }))) return value;
    }
    throw new BadRequestException({ message: 'تعذر توليد رقم شكوى', error_code: 'COMPLAINT_NUMBER_FAILED' });
  }

  private async validateSupportContext(userId: number, input: { organizationId?: number; orderId?: number; serviceOrderId?: number; paymentId?: number; shipmentId?: number }) {
    if (input.organizationId) {
      const org = await this.db.organization.findUnique({ where: { id: input.organizationId } });
      if (!org) throw new NotFoundException({ message: 'Organization not found', error_code: 'ORGANIZATION_NOT_FOUND' });
    }
    if (input.orderId) {
      const order = await this.db.order.findFirst({ where: { id: input.orderId } });
      if (!order) throw new NotFoundException({ message: 'Order not found', error_code: 'ORDER_NOT_FOUND' });
      if (order.userId !== userId) await this.assertOrganizationAccess(userId, order.organizationId);
    }
    if (input.serviceOrderId) {
      const serviceOrder = await this.db.serviceOrder.findFirst({ where: { id: input.serviceOrderId } });
      if (!serviceOrder) throw new NotFoundException({ message: 'Service order not found', error_code: 'SERVICE_ORDER_NOT_FOUND' });
      if (serviceOrder.userId !== userId) await this.assertOrganizationAccess(userId, serviceOrder.organizationId);
    }
    if (input.paymentId) {
      const payment = await this.db.paymentTransaction.findFirst({ where: { id: input.paymentId } });
      if (!payment) throw new NotFoundException({ message: 'Payment not found', error_code: 'PAYMENT_NOT_FOUND' });
      if (payment.payerUserId !== userId && payment.organizationId) await this.assertOrganizationAccess(userId, payment.organizationId);
      if (payment.payerUserId !== userId && !payment.organizationId) await this.assertSupportAdmin(userId);
    }
    if (input.shipmentId) {
      const shipment = await this.db.shipment.findFirst({ where: { id: input.shipmentId }, include: { order: true } });
      if (!shipment) throw new NotFoundException({ message: 'Shipment not found', error_code: 'SHIPMENT_NOT_FOUND' });
      if (shipment.order?.userId !== userId) await this.assertOrganizationAccess(userId, shipment.organizationId);
    }
  }

  private async assertTicketAccess(userId: number, ticket: any, options: { allowInternal?: boolean } = {}) {
    const isRequester = ticket.requesterUserId === userId;
    const isAdmin = await this.isSupportAdmin(userId);
    const isAssigned = ticket.assignedUserId === userId;
    const isOrgMember = ticket.organizationId ? !!(await this.db.organizationMember.findFirst({ where: { userId, organizationId: ticket.organizationId } })) : false;
    if (!isRequester && !isAdmin && !isAssigned && !isOrgMember) {
      throw new ForbiddenException({ message: 'ليس لديك صلاحية على التذكرة', error_code: 'TICKET_ACCESS_DENIED' });
    }
    if (options.allowInternal && !isAdmin && !isOrgMember && !isAssigned) {
      throw new ForbiddenException({ message: 'الملاحظات الداخلية للدعم فقط', error_code: 'INTERNAL_MESSAGE_DENIED' });
    }
    return { isRequester, isAdmin, isAssigned, isOrgMember };
  }

  private async createAttachments(tx: any, ticketId: number, messageId: number | null, userId: number, attachments?: any[]) {
    if (!attachments?.length) return [];
    return Promise.all(attachments.slice(0, 10).map((attachment) => tx.supportTicketAttachment.create({
      data: {
        ticketId,
        messageId,
        uploadedByUserId: userId,
        scope: messageId ? 'MESSAGE' : 'TICKET',
        fileUrl: attachment.fileUrl,
        fileName: attachment.fileName ?? null,
        fileType: attachment.fileType ?? null,
        fileSizeBytes: attachment.fileSizeBytes ?? null,
      },
    })));
  }

  async createTicket(userId: number, dto: CreateSupportTicketDto) {
    await this.validateSupportContext(userId, dto);
    const data = await this.db.$transaction(async (tx: any) => {
      const ticket = await tx.supportTicket.create({
        data: {
          ticketNumber: await this.ticketNumber(tx),
          requesterUserId: userId,
          organizationId: dto.organizationId ?? null,
          orderId: dto.orderId ?? null,
          serviceOrderId: dto.serviceOrderId ?? null,
          paymentId: dto.paymentId ?? null,
          shipmentId: dto.shipmentId ?? null,
          category: dto.category,
          priority: dto.priority ?? 'NORMAL',
          subject: dto.subject,
          description: dto.description,
          status: 'OPEN',
          lastMessageAt: new Date(),
          messages: {
            create: {
              authorUserId: userId,
              messageType: 'CUSTOMER_MESSAGE',
              body: dto.description,
              attachments: dto.attachments?.length ? dto.attachments as any : undefined,
              isInternal: false,
            },
          },
        },
        include: { messages: true, organization: true, order: true, serviceOrder: true, payment: true, shipment: true },
      });
      const firstMessage = ticket.messages?.[0];
      await this.createAttachments(tx, ticket.id, firstMessage?.id ?? null, userId, dto.attachments);
      return ticket;
    });
    await this.audit.write({ actorUserId: userId, action: 'support.ticket.created', entityType: 'support_ticket', entityId: data.id, metadata: { ticketNumber: data.ticketNumber, category: data.category } });
    return { success: true, message: 'Support ticket created', data };
  }

  async myTickets(userId: number) {
    const data = await this.db.supportTicket.findMany({
      where: { requesterUserId: userId },
      include: { organization: true, order: true, serviceOrder: true, payment: true, shipment: true, messages: { orderBy: { createdAt: 'desc' }, take: 1 } },
      orderBy: { updatedAt: 'desc' },
      take: SUPPORT_VISIBLE_TAKE,
    });
    return { success: true, data };
  }

  async manageTickets(userId: number, status?: string) {
    await this.assertSupportAdmin(userId);
    const where = status ? { status } : {};
    const data = await this.db.supportTicket.findMany({
      where,
      include: { requester: true, assignedUser: true, organization: true, messages: { orderBy: { createdAt: 'desc' }, take: 1 } },
      orderBy: [{ priority: 'desc' }, { updatedAt: 'desc' }],
      take: 200,
    });
    return { success: true, data };
  }

  async ticketDetails(userId: number, id: number) {
    const ticket = await this.db.supportTicket.findUnique({
      where: { id },
      include: {
        requester: true,
        assignedUser: true,
        organization: true,
        order: true,
        serviceOrder: true,
        payment: true,
        shipment: true,
        attachments: true,
        messages: { orderBy: { createdAt: 'asc' }, include: { author: true, attachmentRecords: true } },
      },
    });
    if (!ticket) throw new NotFoundException({ message: 'Ticket not found', error_code: 'TICKET_NOT_FOUND' });
    const access = await this.assertTicketAccess(userId, ticket);
    const visibleMessages = access.isRequester && !access.isAdmin ? ticket.messages.filter((m: any) => !m.isInternal) : ticket.messages;
    return { success: true, data: { ...ticket, messages: visibleMessages } };
  }

  async addTicketMessage(userId: number, ticketId: number, dto: AddTicketMessageDto) {
    const ticket = await this.db.supportTicket.findUnique({ where: { id: ticketId } });
    if (!ticket) throw new NotFoundException({ message: 'Ticket not found', error_code: 'TICKET_NOT_FOUND' });
    const access = await this.assertTicketAccess(userId, ticket, { allowInternal: dto.isInternal });
    if (TERMINAL_TICKET_STATUSES.includes(ticket.status)) throw new BadRequestException({ message: 'التذكرة مغلقة', error_code: 'TICKET_CLOSED' });

    const messageType = access.isRequester ? 'CUSTOMER_MESSAGE' : access.isOrgMember ? 'MERCHANT_MESSAGE' : dto.isInternal ? 'INTERNAL_NOTE' : 'SUPPORT_MESSAGE';
    const nextStatus = access.isRequester ? 'WAITING_SUPPORT' : 'WAITING_CUSTOMER';
    const data = await this.db.$transaction(async (tx: any) => {
      const message = await tx.supportTicketMessage.create({
        data: {
          ticketId,
          authorUserId: userId,
          messageType,
          body: dto.body,
          attachments: dto.attachments?.length ? dto.attachments as any : undefined,
          isInternal: dto.isInternal ?? false,
        },
      });
      await this.createAttachments(tx, ticketId, message.id, userId, dto.attachments);
      await tx.supportTicket.update({ where: { id: ticketId }, data: { status: nextStatus, lastMessageAt: new Date() } });
      return message;
    });
    await this.audit.write({ actorUserId: userId, action: 'support.ticket.message_added', entityType: 'support_ticket', entityId: ticketId, metadata: { internal: dto.isInternal ?? false } });
    const notifyUserId = access.isRequester ? ticket.assignedUserId : ticket.requesterUserId;
    if (notifyUserId) await this.notifications.createForUser(notifyUserId, 'رسالة جديدة في الدعم', `تحديث على التذكرة ${ticket.ticketNumber}`, { ticket_id: ticket.id });
    return { success: true, message: 'Ticket message added', data };
  }

  async assignTicket(userId: number, ticketId: number, dto: AssignSupportTicketDto) {
    await this.assertSupportAdmin(userId);
    const ticket = await this.db.supportTicket.findUnique({ where: { id: ticketId } });
    if (!ticket) throw new NotFoundException({ message: 'Ticket not found', error_code: 'TICKET_NOT_FOUND' });
    const assignee = await this.db.user.findUnique({ where: { id: dto.assignedUserId } });
    if (!assignee) throw new NotFoundException({ message: 'Assigned user not found', error_code: 'ASSIGNEE_NOT_FOUND' });
    const data = await this.db.$transaction(async (tx: any) => {
      const updated = await tx.supportTicket.update({ where: { id: ticketId }, data: { assignedUserId: dto.assignedUserId, status: 'IN_PROGRESS' } });
      await tx.supportTicketMessage.create({ data: { ticketId, authorUserId: userId, messageType: 'SYSTEM_NOTE', body: dto.note ?? 'تم تعيين التذكرة', isInternal: true } });
      return updated;
    });
    await this.audit.write({ actorUserId: userId, action: 'support.ticket.assigned', entityType: 'support_ticket', entityId: ticketId, metadata: { assignedUserId: dto.assignedUserId } });
    await this.notifications.createForUser(dto.assignedUserId, 'تم تعيين تذكرة لك', `تم تعيين التذكرة ${ticket.ticketNumber} لك`, { ticket_id: ticketId });
    return { success: true, message: 'Ticket assigned', data };
  }

  async updateTicketStatus(userId: number, id: number, dto: UpdateSupportTicketStatusDto) {
    const ticket = await this.db.supportTicket.findUnique({ where: { id } });
    if (!ticket) throw new NotFoundException({ message: 'Ticket not found', error_code: 'TICKET_NOT_FOUND' });
    const isRequester = ticket.requesterUserId === userId;
    if (!isRequester) await this.assertSupportAdmin(userId);
    if (isRequester && !['CLOSED'].includes(dto.status)) {
      throw new ForbiddenException({ message: 'العميل يمكنه إغلاق التذكرة فقط', error_code: 'TICKET_STATUS_DENIED' });
    }
    const payload: any = { status: dto.status };
    if (dto.status === 'RESOLVED') payload.resolvedAt = new Date();
    if (dto.status === 'CLOSED') payload.closedAt = new Date();
    if (['OPEN', 'IN_PROGRESS', 'WAITING_SUPPORT', 'WAITING_CUSTOMER', 'ESCALATED'].includes(dto.status)) {
      payload.resolvedAt = null;
      payload.closedAt = null;
    }
    const data = await this.db.$transaction(async (tx: any) => {
      const updated = await tx.supportTicket.update({ where: { id }, data: payload });
      await tx.supportTicketMessage.create({ data: { ticketId: id, authorUserId: userId, messageType: 'SYSTEM_NOTE', body: dto.note ?? `Status changed to ${dto.status}`, isInternal: !isRequester } });
      return updated;
    });
    await this.audit.write({ actorUserId: userId, action: 'support.ticket.status_updated', entityType: 'support_ticket', entityId: id, metadata: { status: dto.status } });
    if (!isRequester) await this.notifications.createForUser(ticket.requesterUserId, 'تحديث حالة التذكرة', `تم تحديث حالة التذكرة إلى ${dto.status}`, { ticket_id: id });
    return { success: true, message: 'Ticket status updated', data };
  }

  async reopenTicket(userId: number, id: number) {
    const ticket = await this.db.supportTicket.findUnique({ where: { id } });
    if (!ticket) throw new NotFoundException({ message: 'Ticket not found', error_code: 'TICKET_NOT_FOUND' });
    await this.assertTicketAccess(userId, ticket);
    if (!TERMINAL_TICKET_STATUSES.includes(ticket.status)) throw new BadRequestException({ message: 'التذكرة ليست مغلقة', error_code: 'TICKET_NOT_CLOSED' });
    const data = await this.db.supportTicket.update({ where: { id }, data: { status: 'OPEN', resolvedAt: null, closedAt: null, lastMessageAt: new Date() } });
    await this.audit.write({ actorUserId: userId, action: 'support.ticket.reopened', entityType: 'support_ticket', entityId: id });
    return { success: true, message: 'Ticket reopened', data };
  }

  async createComplaint(userId: number, dto: CreateComplaintDto) {
    await this.validateSupportContext(userId, dto);
    const data = await this.db.$transaction(async (tx: any) => {
      const ticket = await tx.supportTicket.create({
        data: {
          ticketNumber: await this.ticketNumber(tx),
          requesterUserId: userId,
          organizationId: dto.organizationId ?? null,
          orderId: dto.orderId ?? null,
          serviceOrderId: dto.serviceOrderId ?? null,
          paymentId: dto.paymentId ?? null,
          shipmentId: dto.shipmentId ?? null,
          category: 'COMPLAINT',
          priority: dto.severity === 'CRITICAL' || dto.severity === 'HIGH' ? 'HIGH' : 'NORMAL',
          subject: dto.subject,
          description: dto.description,
          lastMessageAt: new Date(),
          messages: { create: { authorUserId: userId, messageType: 'CUSTOMER_MESSAGE', body: dto.description, attachments: dto.attachments?.length ? dto.attachments as any : undefined } },
        },
        include: { messages: true },
      });
      const firstMessage = ticket.messages?.[0];
      await this.createAttachments(tx, ticket.id, firstMessage?.id ?? null, userId, dto.attachments);
      return tx.complaint.create({
        data: {
          complaintNumber: await this.complaintNumber(tx),
          requesterUserId: userId,
          organizationId: dto.organizationId ?? null,
          orderId: dto.orderId ?? null,
          serviceOrderId: dto.serviceOrderId ?? null,
          paymentId: dto.paymentId ?? null,
          shipmentId: dto.shipmentId ?? null,
          ticketId: ticket.id,
          severity: dto.severity ?? 'NORMAL',
          subject: dto.subject,
          description: dto.description,
        },
        include: { ticket: true, organization: true, order: true, serviceOrder: true, payment: true, shipment: true },
      });
    });
    await this.audit.write({ actorUserId: userId, action: 'support.complaint.created', entityType: 'support_complaint', entityId: data.id, metadata: { complaintNumber: data.complaintNumber, severity: data.severity } });
    return { success: true, message: 'Complaint submitted', data };
  }

  async myComplaints(userId: number) {
    const data = await this.db.complaint.findMany({
      where: { requesterUserId: userId },
      include: { ticket: true, organization: true, order: true, serviceOrder: true, payment: true, shipment: true },
      orderBy: { createdAt: 'desc' },
      take: SUPPORT_VISIBLE_TAKE,
    });
    return { success: true, data };
  }

  async manageComplaints(userId: number, status?: string) {
    await this.assertSupportAdmin(userId);
    const data = await this.db.complaint.findMany({
      where: status ? { status } : {},
      include: { requester: true, ticket: true, organization: true, order: true, serviceOrder: true, payment: true, shipment: true },
      orderBy: [{ severity: 'desc' }, { createdAt: 'desc' }],
      take: 200,
    });
    return { success: true, data };
  }

  async complaintDetails(userId: number, id: number) {
    const complaint = await this.db.complaint.findUnique({
      where: { id },
      include: { requester: true, ticket: { include: { messages: { orderBy: { createdAt: 'asc' }, include: { author: true, attachmentRecords: true } }, attachments: true } }, organization: true, order: true, serviceOrder: true, payment: true, shipment: true },
    });
    if (!complaint) throw new NotFoundException({ message: 'Complaint not found', error_code: 'COMPLAINT_NOT_FOUND' });
    if (complaint.requesterUserId !== userId) {
      if (complaint.organizationId) await this.assertOrganizationAccess(userId, complaint.organizationId);
      else await this.assertSupportAdmin(userId);
    }
    return { success: true, data: complaint };
  }

  async updateComplaintStatus(userId: number, id: number, dto: UpdateComplaintStatusDto) {
    await this.assertSupportAdmin(userId);
    const complaint = await this.db.complaint.findUnique({ where: { id }, include: { ticket: true } });
    if (!complaint) throw new NotFoundException({ message: 'Complaint not found', error_code: 'COMPLAINT_NOT_FOUND' });
    const payload: any = { status: dto.status, resolutionNote: dto.resolutionNote ?? complaint.resolutionNote };
    if (['RESOLVED', 'REJECTED', 'CLOSED'].includes(dto.status)) {
      payload.resolvedByUserId = userId;
      payload.resolvedAt = new Date();
    }
    const data = await this.db.$transaction(async (tx: any) => {
      const updated = await tx.complaint.update({ where: { id }, data: payload });
      if (complaint.ticketId) {
        await tx.supportTicket.update({ where: { id: complaint.ticketId }, data: { status: dto.status === 'RESOLVED' ? 'RESOLVED' : dto.status === 'CLOSED' ? 'CLOSED' : 'IN_PROGRESS' } }).catch(() => null);
        await tx.supportTicketMessage.create({ data: { ticketId: complaint.ticketId, authorUserId: userId, messageType: 'SYSTEM_NOTE', body: dto.resolutionNote ?? `Complaint status changed to ${dto.status}`, isInternal: false } }).catch(() => null);
      }
      return updated;
    });
    await this.audit.write({ actorUserId: userId, action: 'support.complaint.status_updated', entityType: 'support_complaint', entityId: id, metadata: { status: dto.status } });
    await this.notifications.createForUser(complaint.requesterUserId, 'تحديث حالة الشكوى', `تم تحديث الشكوى إلى ${dto.status}`, { complaint_id: id });
    return { success: true, message: 'Complaint status updated', data };
  }

  async listHelpCategories(publicOnly = true) {
    const data = await this.db.helpCenterCategory.findMany({
      where: publicOnly ? { status: 'PUBLISHED' } : undefined,
      include: { _count: { select: { articles: true, faqs: true } } },
      orderBy: [{ sortOrder: 'asc' }, { titleAr: 'asc' }],
    });
    return { success: true, data };
  }


  async manageHelpCategories(userId: number) {
    await this.assertSupportAdmin(userId);
    return this.listHelpCategories(false);
  }

  async upsertHelpCategory(userId: number, dto: UpsertHelpCenterCategoryDto, id?: number) {
    await this.assertSupportAdmin(userId);
    const data = id
      ? await this.db.helpCenterCategory.update({ where: { id }, data: { ...dto } })
      : await this.db.helpCenterCategory.upsert({ where: { code: dto.code }, update: { ...dto }, create: { ...dto, createdByUserId: userId } });
    await this.audit.write({ actorUserId: userId, action: 'support.help_category.upserted', entityType: 'help_center_category', entityId: data.id });
    return { success: true, data };
  }

  async listHelpArticles(query: { q?: string; categoryId?: number; publicOnly?: boolean }) {
    const where: any = {};
    if (query.publicOnly !== false) where.status = 'PUBLISHED';
    if (query.categoryId) where.categoryId = query.categoryId;
    if (query.q) where.OR = [{ titleAr: { contains: query.q } }, { summaryAr: { contains: query.q } }, { bodyAr: { contains: query.q } }];
    const data = await this.db.helpCenterArticle.findMany({
      where,
      include: { category: true },
      orderBy: [{ isFeatured: 'desc' }, { sortOrder: 'asc' }, { updatedAt: 'desc' }],
      take: 100,
    });
    return { success: true, data };
  }


  async manageHelpArticles(userId: number, query: { q?: string; categoryId?: number }) {
    await this.assertSupportAdmin(userId);
    return this.listHelpArticles({ ...query, publicOnly: false });
  }

  async helpArticleDetails(slug: string, publicOnly = true) {
    const article = await this.db.helpCenterArticle.findUnique({ where: { slug }, include: { category: true } });
    if (!article || (publicOnly && article.status !== 'PUBLISHED')) throw new NotFoundException({ message: 'Article not found', error_code: 'ARTICLE_NOT_FOUND' });
    await this.db.helpCenterArticle.update({ where: { id: article.id }, data: { viewCount: { increment: 1 } } }).catch(() => null);
    return { success: true, data: article };
  }

  async upsertHelpArticle(userId: number, dto: UpsertHelpCenterArticleDto, id?: number) {
    await this.assertSupportAdmin(userId);
    if (dto.categoryId) {
      const category = await this.db.helpCenterCategory.findUnique({ where: { id: dto.categoryId } });
      if (!category) throw new NotFoundException({ message: 'Category not found', error_code: 'CATEGORY_NOT_FOUND' });
    }
    const data = id
      ? await this.db.helpCenterArticle.update({ where: { id }, data: { ...dto, updatedByUserId: userId, publishedAt: dto.status === 'PUBLISHED' ? new Date() : undefined } })
      : await this.db.helpCenterArticle.create({ data: { ...dto, createdByUserId: userId, updatedByUserId: userId, publishedAt: dto.status === 'PUBLISHED' ? new Date() : null } });
    await this.audit.write({ actorUserId: userId, action: 'support.help_article.upserted', entityType: 'help_center_article', entityId: data.id, metadata: { status: data.status } });
    return { success: true, data };
  }

  async listFaqs(query: { q?: string; categoryId?: number; publicOnly?: boolean }) {
    const where: any = {};
    if (query.publicOnly !== false) where.status = 'PUBLISHED';
    if (query.categoryId) where.categoryId = query.categoryId;
    if (query.q) where.OR = [{ questionAr: { contains: query.q } }, { answerAr: { contains: query.q } }];
    const data = await this.db.faq.findMany({ where, include: { category: true }, orderBy: [{ sortOrder: 'asc' }, { updatedAt: 'desc' }], take: 120 });
    return { success: true, data };
  }


  async manageFaqs(userId: number, query: { q?: string; categoryId?: number }) {
    await this.assertSupportAdmin(userId);
    return this.listFaqs({ ...query, publicOnly: false });
  }

  async upsertFaq(userId: number, dto: UpsertFaqDto, id?: number) {
    await this.assertSupportAdmin(userId);
    const data = id
      ? await this.db.faq.update({ where: { id }, data: { ...dto } })
      : await this.db.faq.create({ data: { ...dto, createdByUserId: userId } });
    await this.audit.write({ actorUserId: userId, action: 'support.faq.upserted', entityType: 'faq', entityId: data.id });
    return { success: true, data };
  }

  async listWhatsappLinks(publicOnly = true) {
    const data = await this.db.whatsappSupportLink.findMany({
      where: publicOnly ? { isActive: true } : undefined,
      orderBy: [{ department: 'asc' }, { sortOrder: 'asc' }],
    });
    const withUrls = data.map((link: any) => ({ ...link, url: `https://wa.me/${String(link.phoneE164).replace(/[^0-9]/g, '')}${link.messageTemplate ? `?text=${encodeURIComponent(link.messageTemplate)}` : ''}` }));
    return { success: true, data: withUrls };
  }


  async manageWhatsappLinks(userId: number) {
    await this.assertSupportAdmin(userId);
    return this.listWhatsappLinks(false);
  }

  async upsertWhatsappLink(userId: number, dto: UpsertWhatsappSupportLinkDto, id?: number) {
    await this.assertSupportAdmin(userId);
    const data = id
      ? await this.db.whatsappSupportLink.update({ where: { id }, data: { ...dto } })
      : await this.db.whatsappSupportLink.create({ data: { ...dto, createdByUserId: userId } });
    await this.audit.write({ actorUserId: userId, action: 'support.whatsapp_link.upserted', entityType: 'whatsapp_support_link', entityId: data.id, metadata: { department: data.department } });
    return { success: true, data };
  }

  async createProductReview(userId: number, dto: CreateProductReviewDto) {
    return this.reviews.createProductReview(userId, dto as any);
  }

  async createMerchantReview(userId: number, dto: CreateMerchantReviewDto) {
    return this.reviews.createMerchantReview(userId, dto as any);
  }

  async createWorkshopReview(userId: number, dto: CreateWorkshopReviewDto) {
    return this.reviews.createWorkshopReview(userId, dto as any);
  }

  async myReviews(userId: number) {
    return this.reviews.myReviews(userId);
  }

  async productReviews(productId: number) {
    return this.reviews.publicReviews('PRODUCT', productId);
  }

  async merchantReviews(organizationId: number) {
    return this.reviews.publicReviews('MERCHANT', organizationId);
  }

  async workshopReviews(organizationId: number) {
    return this.reviews.publicReviews('WORKSHOP', organizationId);
  }

  async moderateReview(userId: number, type: string, id: number, dto: ModerateReviewDto) {
    await this.assertSupportAdmin(userId);
    const mapped = type === 'product' ? 'PRODUCT' : type === 'merchant' ? 'MERCHANT' : type === 'workshop' ? 'WORKSHOP' : type === 'service' ? 'SERVICE' : null;
    if (!mapped) throw new BadRequestException({ message: 'نوع تقييم غير معروف', error_code: 'INVALID_REVIEW_TYPE' });
    const action = dto.status === 'PUBLISHED' ? 'RESTORED' : dto.status === 'HIDDEN' ? 'HIDDEN' : 'REJECTED';
    return this.reviews.moderateReview(userId, { targetType: mapped as any, reviewId: id, action: action as any });
  }
}
