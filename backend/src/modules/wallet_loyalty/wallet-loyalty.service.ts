import { BadRequestException, ConflictException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { AuditService } from '../audit/audit.service';
import { NotificationsService } from '../notifications/notifications.service';
import {
  ApplyReferralDto,
  AwardPointsDto,
  CreateCouponDto,
  CreateRetentionCampaignDto,
  QualifyReferralDto,
  RedeemCouponDto,
  RedeemPointsDto,
  ReversePointsDto,
  UpdateCouponStatusDto,
  ValidateCouponDto,
  WalletAdjustmentDto,
  WalletTopUpDto,
} from './dto/wallet-loyalty.dto';

const ADMIN_PERMISSIONS = [
  'finance.wallets.manage',
  'loyalty.manage',
  'coupons.manage',
  'referrals.manage',
  'manage_wallets',
  'manage_loyalty',
  'manage_retention',
  'manage_system',
];
const POINT_TO_WALLET_RATE = 10;
const DEFAULT_REFERRER_POINTS = 250;
const DEFAULT_REFERRED_POINTS = 100;

type Tx = any;

@Injectable()
export class WalletLoyaltyService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notifications: NotificationsService,
    private readonly audit: AuditService,
  ) {}

  private get db() { return this.prisma as any; }

  private amountNumber(value: unknown) { return Number(value ?? 0); }

  private normalizedCode(code: string) {
    return code.trim().toUpperCase().replace(/[^A-Z0-9_-]/g, '');
  }

  private async userPermissions(userId: number): Promise<string[]> {
    const userRoles = await this.db.userRole.findMany({
      where: { userId },
      include: { role: { include: { rolePermissions: { include: { permission: true } } } } },
    });
    return userRoles.flatMap((ur: any) => ur.role.rolePermissions.map((rp: any) => rp.permission.code));
  }

  private async assertAdmin(userId: number) {
    const permissions = await this.userPermissions(userId);
    if (!permissions.some((code) => ADMIN_PERMISSIONS.includes(code))) {
      throw new ForbiddenException({ message: 'ليس لديك صلاحية تنفيذ هذه العملية', error_code: 'WALLET_LOYALTY_ACCESS_DENIED' });
    }
  }

  private async assertOrganizationAccess(userId: number, organizationId: number) {
    const member = await this.db.organizationMember.findFirst({ where: { userId, organizationId, status: 'ACTIVE' } });
    if (!member) throw new ForbiddenException({ message: 'ليس لديك صلاحية على هذه المؤسسة', error_code: 'ORGANIZATION_ACCESS_DENIED' });
    return member;
  }

  private async auditWrite(actorUserId: number | null, action: string, entityType: string, entityId: string | number | null, metadata?: Record<string, unknown>) {
    await this.audit.write({ actorUserId, action, entityType, entityId, metadata }).catch(() => null);
  }

  private tierForLifetime(lifetimeEarned: number) {
    if (lifetimeEarned >= 5000) return 'PLATINUM';
    if (lifetimeEarned >= 2000) return 'GOLD';
    if (lifetimeEarned >= 700) return 'SILVER';
    return 'BRONZE';
  }

  private async ensureWallet(userId: number, tx?: Tx, currency = 'YER') {
    const db = tx ?? this.db;
    const existing = await db.walletAccount.findFirst({ where: { ownerType: 'USER', userId, currency } });
    if (existing) return existing;
    return db.walletAccount.create({ data: { ownerType: 'USER', userId, currency, balance: 0, lockedBalance: 0, status: 'ACTIVE' } });
  }

  private async ensureLoyalty(userId: number, tx?: Tx) {
    const db = tx ?? this.db;
    const existing = await db.loyaltyAccount.findUnique({ where: { userId } });
    if (existing) return existing;
    return db.loyaltyAccount.create({ data: { userId, pointsBalance: 0, lifetimeEarned: 0, lifetimeRedeemed: 0, tier: 'BRONZE' } });
  }

  private async createWalletEntry(tx: Tx, wallet: any, direction: 'CREDIT' | 'DEBIT', entryType: string, amount: number, payload: any) {
    if (amount <= 0) throw new BadRequestException({ message: 'المبلغ غير صحيح', error_code: 'INVALID_AMOUNT' });
    if (payload?.idempotencyKey) {
      const existing = await tx.walletLedgerEntry.findUnique({ where: { idempotencyKey: payload.idempotencyKey } }).catch(() => null);
      if (existing) return { wallet, entry: existing, duplicate: true };
    }
    const before = this.amountNumber(wallet.balance);
    const after = direction === 'CREDIT' ? before + amount : before - amount;
    if (after < 0) throw new BadRequestException({ message: 'رصيد المحفظة غير كافٍ', error_code: 'INSUFFICIENT_WALLET_BALANCE' });
    const updated = await tx.walletAccount.update({ where: { id: wallet.id }, data: { balance: after } });
    const entry = await tx.walletLedgerEntry.create({
      data: {
        walletAccountId: wallet.id,
        direction,
        entryType,
        amount,
        balanceBefore: before,
        balanceAfter: after,
        currency: wallet.currency,
        ...payload,
      },
    });
    return { wallet: updated, entry, duplicate: false };
  }

  private async addPoints(tx: Tx, userId: number, points: number, source: string, payload: any) {
    if (points <= 0) throw new BadRequestException({ message: 'عدد النقاط غير صحيح', error_code: 'INVALID_POINTS' });
    if (payload?.idempotencyKey) {
      const existing = await tx.loyaltyPointTransaction.findUnique({ where: { idempotencyKey: payload.idempotencyKey } }).catch(() => null);
      if (existing) return { account: await this.ensureLoyalty(userId, tx), entry: existing, duplicate: true };
    }
    const account = await this.ensureLoyalty(userId, tx);
    const balanceAfter = account.pointsBalance + points;
    const lifetimeEarned = account.lifetimeEarned + points;
    const updated = await tx.loyaltyAccount.update({
      where: { id: account.id },
      data: { pointsBalance: balanceAfter, lifetimeEarned, tier: this.tierForLifetime(lifetimeEarned) },
    });
    const entry = await tx.loyaltyPointTransaction.create({
      data: { accountId: account.id, userId, direction: 'EARN', source, points, balanceAfter, ...payload },
    });
    return { account: updated, entry, duplicate: false };
  }

  private async spendPoints(tx: Tx, userId: number, points: number, source: string, payload: any) {
    if (points <= 0) throw new BadRequestException({ message: 'عدد النقاط غير صحيح', error_code: 'INVALID_POINTS' });
    if (payload?.idempotencyKey) {
      const existing = await tx.loyaltyPointTransaction.findUnique({ where: { idempotencyKey: payload.idempotencyKey } }).catch(() => null);
      if (existing) return { account: await this.ensureLoyalty(userId, tx), entry: existing, duplicate: true };
    }
    const account = await this.ensureLoyalty(userId, tx);
    if (account.pointsBalance < points) throw new BadRequestException({ message: 'رصيد النقاط غير كافٍ', error_code: 'INSUFFICIENT_POINTS' });
    const balanceAfter = account.pointsBalance - points;
    const updated = await tx.loyaltyAccount.update({
      where: { id: account.id },
      data: { pointsBalance: balanceAfter, lifetimeRedeemed: account.lifetimeRedeemed + points },
    });
    const entry = await tx.loyaltyPointTransaction.create({
      data: { accountId: account.id, userId, direction: 'REDEEM', source, points, balanceAfter, ...payload },
    });
    return { account: updated, entry, duplicate: false };
  }

  async myWallet(userId: number) {
    const wallet = await this.ensureWallet(userId);
    return { success: true, data: wallet };
  }

  async myWalletLedger(userId: number, take = 50) {
    const wallet = await this.ensureWallet(userId);
    const data = await this.db.walletLedgerEntry.findMany({
      where: { walletAccountId: wallet.id },
      orderBy: { createdAt: 'desc' },
      take: Math.min(Math.max(take, 1), 100),
    });
    return { success: true, data };
  }

  async requestWalletTopUp(userId: number, dto: WalletTopUpDto) {
    if (dto.idempotencyKey) {
      const existing = await this.db.paymentTransaction.findUnique({ where: { idempotencyKey: dto.idempotencyKey } }).catch(() => null);
      if (existing) return { success: true, message: 'Wallet top-up request already exists', data: existing };
    }
    const wallet = await this.ensureWallet(userId, undefined, dto.currency ?? 'YER');
    const data = await this.db.paymentTransaction.create({
      data: {
        payerUserId: userId,
        type: 'ADJUSTMENT',
        provider: 'BANK_TRANSFER',
        method: 'BANK_TRANSFER',
        status: 'PENDING_REVIEW',
        amount: dto.amount,
        currency: wallet.currency,
        externalReference: dto.externalReference ?? null,
        receiptUrl: dto.receiptUrl ?? null,
        reviewNote: dto.note ?? 'Wallet top-up request',
        idempotencyKey: dto.idempotencyKey ?? null,
        meta: { wallet_account_id: wallet.id, purpose: 'WALLET_TOP_UP' },
      },
    });
    await this.auditWrite(userId, 'wallet.top_up.requested', 'payment_transaction', data.id, { amount: dto.amount, currency: wallet.currency });
    await this.notifications.createForUser(userId, 'تم استلام طلب شحن المحفظة', 'سيتم مراجعة طلب الشحن واعتماده من الإدارة.', { payment_transaction_id: data.id });
    return { success: true, message: 'Wallet top-up request created', data };
  }

  async approveWalletTopUp(adminUserId: number, transactionId: number) {
    await this.assertAdmin(adminUserId);
    const txData = await this.db.paymentTransaction.findUnique({ where: { id: transactionId } });
    if (!txData) throw new NotFoundException({ message: 'Transaction not found', error_code: 'TRANSACTION_NOT_FOUND' });
    if (txData.status === 'PAID') return { success: true, data: txData };
    if (txData.status !== 'PENDING_REVIEW' || txData.provider !== 'BANK_TRANSFER') {
      throw new BadRequestException({ message: 'عملية الشحن غير قابلة للاعتماد', error_code: 'TOP_UP_NOT_APPROVABLE' });
    }
    const data = await this.db.$transaction(async (tx: Tx) => {
      const wallet = await this.ensureWallet(txData.payerUserId, tx, txData.currency);
      const result = await this.createWalletEntry(tx, wallet, 'CREDIT', 'TOP_UP', this.amountNumber(txData.amount), {
        referenceType: 'PAYMENT_TRANSACTION',
        referenceId: String(txData.id),
        createdByUserId: adminUserId,
        idempotencyKey: `wallet-topup-${txData.id}`,
        description: 'اعتماد شحن المحفظة',
        metadata: { transaction_id: txData.id },
      });
      const updatedTransaction = await tx.paymentTransaction.update({ where: { id: txData.id }, data: { status: 'PAID', paidAt: new Date() } });
      return { wallet: result.wallet, entry: result.entry, transaction: updatedTransaction };
    });
    await this.auditWrite(adminUserId, 'wallet.top_up.approved', 'payment_transaction', transactionId, { payerUserId: txData.payerUserId });
    if (txData.payerUserId) await this.notifications.createForUser(txData.payerUserId, 'تم شحن المحفظة', `تم إضافة ${txData.amount} ${txData.currency} إلى محفظتك.`, { payment_transaction_id: txData.id });
    return { success: true, message: 'Wallet top-up approved', data };
  }

  async adminAdjustWallet(adminUserId: number, dto: WalletAdjustmentDto) {
    await this.assertAdmin(adminUserId);
    const data = await this.db.$transaction(async (tx: Tx) => {
      const wallet = await this.ensureWallet(dto.userId, tx, dto.currency ?? 'YER');
      return this.createWalletEntry(tx, wallet, dto.direction, 'ADMIN_ADJUSTMENT', dto.amount, {
        createdByUserId: adminUserId,
        idempotencyKey: dto.idempotencyKey ?? `wallet-adjust-${adminUserId}-${dto.userId}-${Date.now()}`,
        description: dto.note ?? 'تعديل إداري على المحفظة',
      });
    });
    await this.auditWrite(adminUserId, 'wallet.adjusted', 'wallet_account', data.wallet.id, { targetUserId: dto.userId, direction: dto.direction, amount: dto.amount });
    await this.notifications.createForUser(dto.userId, 'تحديث رصيد المحفظة', dto.note ?? 'تم تحديث رصيد محفظتك.', { wallet_entry_id: data.entry.id });
    return { success: true, message: 'Wallet adjusted', data };
  }

  async payOrderWithWallet(userId: number, orderId: number) {
    const order = await this.db.order.findFirst({ where: { id: orderId, userId }, include: { organization: true } });
    if (!order) throw new NotFoundException({ message: 'Order not found', error_code: 'ORDER_NOT_FOUND' });
    if (order.paymentStatus === 'PAID') return { success: true, message: 'Order already paid', data: order };
    if (['CANCELLED', 'REFUNDED'].includes(order.status)) throw new BadRequestException({ message: 'لا يمكن دفع طلب ملغي أو مسترد', error_code: 'ORDER_NOT_PAYABLE' });
    const amount = this.amountNumber(order.totalAmount);
    const data = await this.db.$transaction(async (tx: Tx) => {
      const wallet = await this.ensureWallet(userId, tx, order.currency);
      const ledger = await this.createWalletEntry(tx, wallet, 'DEBIT', 'ORDER_PAYMENT', amount, {
        orderId: order.id,
        referenceType: 'ORDER',
        referenceId: order.orderNumber,
        createdByUserId: userId,
        idempotencyKey: `wallet-order-payment-${order.id}`,
        description: `دفع الطلب ${order.orderNumber}`,
      });
      const transaction = await tx.paymentTransaction.create({ data: { orderId: order.id, payerUserId: userId, organizationId: order.organizationId, type: 'ORDER_PAYMENT', provider: 'WALLET', method: 'WALLET', status: 'PAID', amount, currency: order.currency, paidAt: new Date(), idempotencyKey: `payment-wallet-order-${order.id}`, meta: { wallet_ledger_entry_id: ledger.entry.id } } });
      const updatedOrder = await tx.order.update({ where: { id: order.id }, data: { paymentMethod: 'WALLET', paymentStatus: 'PAID' } });
      return { wallet: ledger.wallet, entry: ledger.entry, transaction, order: updatedOrder };
    });
    await this.auditWrite(userId, 'wallet.order.paid', 'order', order.id, { amount });
    await this.notifications.createForUser(userId, 'تم الدفع من المحفظة', `تم دفع الطلب ${order.orderNumber} بنجاح.`, { order_id: order.id });
    return { success: true, message: 'Order paid with wallet', data };
  }

  async payServiceOrderWithWallet(userId: number, serviceOrderId: number) {
    const order = await this.db.serviceOrder.findFirst({ where: { id: serviceOrderId, userId } });
    if (!order) throw new NotFoundException({ message: 'Service order not found', error_code: 'SERVICE_ORDER_NOT_FOUND' });
    const amount = this.amountNumber(order.finalAmount ?? order.approvedAmount ?? order.estimatedAmount);
    if (amount <= 0) throw new BadRequestException({ message: 'لا يوجد مبلغ قابل للدفع لأمر الصيانة', error_code: 'SERVICE_ORDER_AMOUNT_MISSING' });
    const data = await this.db.$transaction(async (tx: Tx) => {
      const wallet = await this.ensureWallet(userId, tx, order.currency ?? 'YER');
      const ledger = await this.createWalletEntry(tx, wallet, 'DEBIT', 'SERVICE_ORDER_PAYMENT', amount, { serviceOrderId: order.id, referenceType: 'SERVICE_ORDER', referenceId: order.serviceOrderNumber, createdByUserId: userId, idempotencyKey: `wallet-service-order-payment-${order.id}`, description: `دفع أمر الصيانة ${order.serviceOrderNumber}` });
      const transaction = await tx.paymentTransaction.create({ data: { serviceOrderId: order.id, payerUserId: userId, organizationId: order.organizationId, type: 'SERVICE_ORDER_PAYMENT', provider: 'WALLET', method: 'WALLET', status: 'PAID', amount, currency: order.currency ?? 'YER', paidAt: new Date(), idempotencyKey: `payment-wallet-service-order-${order.id}`, meta: { wallet_ledger_entry_id: ledger.entry.id } } });
      return { wallet: ledger.wallet, entry: ledger.entry, transaction };
    });
    await this.auditWrite(userId, 'wallet.service_order.paid', 'service_order', order.id, { amount });
    await this.notifications.createForUser(userId, 'تم دفع أمر الصيانة', `تم دفع أمر الصيانة ${order.serviceOrderNumber} من المحفظة.`, { service_order_id: order.id });
    return { success: true, message: 'Service order paid with wallet', data };
  }

  async myLoyalty(userId: number) {
    const account = await this.ensureLoyalty(userId);
    return { success: true, data: account };
  }

  async myLoyaltyTransactions(userId: number) {
    const account = await this.ensureLoyalty(userId);
    const data = await this.db.loyaltyPointTransaction.findMany({ where: { accountId: account.id }, orderBy: { createdAt: 'desc' }, take: 100 });
    return { success: true, data };
  }

  async awardOrderPoints(userId: number, orderId: number, dto: AwardPointsDto) {
    const order = await this.db.order.findUnique({ where: { id: orderId } });
    if (!order) throw new NotFoundException({ message: 'Order not found', error_code: 'ORDER_NOT_FOUND' });
    if (order.status !== 'DELIVERED') throw new BadRequestException({ message: 'لا تمنح النقاط إلا بعد اكتمال الطلب', error_code: 'ORDER_NOT_COMPLETED' });
    if (order.userId !== userId) await this.assertOrganizationAccess(userId, order.organizationId);
    const idempotencyKey = dto.idempotencyKey ?? `loyalty-order-${order.id}`;
    const existing = await this.db.loyaltyPointTransaction.findUnique({ where: { idempotencyKey } }).catch(() => null);
    if (existing) return { success: true, message: 'Order reward already recorded', data: existing };
    const points = dto.points ?? Math.max(1, Math.floor(this.amountNumber(order.totalAmount) / 1000));
    const data = await this.db.$transaction((tx: Tx) => this.addPoints(tx, order.userId, points, 'ORDER_REWARD', { orderId, createdByUserId: userId, idempotencyKey, description: dto.note ?? `مكافأة الطلب ${order.orderNumber}` }));
    await this.auditWrite(userId, 'loyalty.order_points.awarded', 'order', order.id, { points, customerId: order.userId });
    await this.notifications.createForUser(order.userId, 'تمت إضافة نقاط ولاء', `حصلت على ${points} نقطة من طلبك.`, { order_id: order.id });
    return { success: true, message: 'Order loyalty points awarded', data };
  }

  async awardServiceOrderPoints(userId: number, serviceOrderId: number, dto: AwardPointsDto) {
    const order = await this.db.serviceOrder.findUnique({ where: { id: serviceOrderId } });
    if (!order) throw new NotFoundException({ message: 'Service order not found', error_code: 'SERVICE_ORDER_NOT_FOUND' });
    if (order.status !== 'COMPLETED') throw new BadRequestException({ message: 'لا تمنح النقاط إلا بعد اكتمال الخدمة', error_code: 'SERVICE_ORDER_NOT_COMPLETED' });
    if (order.userId !== userId) await this.assertOrganizationAccess(userId, order.organizationId);
    const idempotencyKey = dto.idempotencyKey ?? `loyalty-service-${order.id}`;
    const existing = await this.db.loyaltyPointTransaction.findUnique({ where: { idempotencyKey } }).catch(() => null);
    if (existing) return { success: true, message: 'Service reward already recorded', data: existing };
    const base = this.amountNumber(order.finalAmount ?? order.approvedAmount ?? order.estimatedAmount);
    const points = dto.points ?? Math.max(1, Math.floor(base / 1000));
    const data = await this.db.$transaction((tx: Tx) => this.addPoints(tx, order.userId, points, 'SERVICE_REWARD', { serviceOrderId, createdByUserId: userId, idempotencyKey, description: dto.note ?? `مكافأة أمر الصيانة ${order.serviceOrderNumber}` }));
    await this.auditWrite(userId, 'loyalty.service_points.awarded', 'service_order', order.id, { points, customerId: order.userId });
    await this.notifications.createForUser(order.userId, 'تمت إضافة نقاط صيانة', `حصلت على ${points} نقطة من خدمة الصيانة.`, { service_order_id: order.id });
    return { success: true, message: 'Service loyalty points awarded', data };
  }

  async reverseOrderPoints(userId: number, orderId: number, dto: ReversePointsDto) {
    await this.assertAdmin(userId);
    const order = await this.db.order.findUnique({ where: { id: orderId } });
    if (!order) throw new NotFoundException({ message: 'Order not found', error_code: 'ORDER_NOT_FOUND' });
    const idempotencyKey = dto.idempotencyKey ?? `loyalty-reversal-order-${order.id}`;
    const data = await this.db.$transaction((tx: Tx) => this.spendPoints(tx, order.userId, dto.points, 'REVERSAL', { orderId, createdByUserId: userId, idempotencyKey, description: dto.reason }));
    await this.auditWrite(userId, 'loyalty.points.reversed', 'order', order.id, { points: dto.points, reason: dto.reason });
    await this.notifications.createForUser(order.userId, 'تم عكس نقاط ولاء', `تم عكس ${dto.points} نقطة بسبب: ${dto.reason}`, { order_id: order.id });
    return { success: true, message: 'Loyalty points reversed', data };
  }

  async redeemPointsToWallet(userId: number, dto: RedeemPointsDto) {
    const amount = dto.points * POINT_TO_WALLET_RATE;
    const idempotencyKey = dto.idempotencyKey ?? `points-wallet-${userId}-${dto.points}-${Date.now()}`;
    const data = await this.db.$transaction(async (tx: Tx) => {
      const point = await this.spendPoints(tx, userId, dto.points, 'WALLET_REDEMPTION', { createdByUserId: userId, idempotencyKey, description: `تحويل ${dto.points} نقطة إلى رصيد محفظة` });
      const wallet = await this.ensureWallet(userId, tx, 'YER');
      const walletEntry = await this.createWalletEntry(tx, wallet, 'CREDIT', 'LOYALTY_REDEMPTION', amount, { referenceType: 'LOYALTY_REDEMPTION', referenceId: String(point.entry.id), createdByUserId: userId, idempotencyKey: `wallet-${idempotencyKey}`, description: 'رصيد من استبدال نقاط الولاء' });
      return { loyalty: point.account, pointEntry: point.entry, wallet: walletEntry.wallet, walletEntry: walletEntry.entry };
    });
    await this.auditWrite(userId, 'loyalty.points.redeemed_to_wallet', 'user', userId, { points: dto.points, amount });
    await this.notifications.createForUser(userId, 'تم استبدال نقاط الولاء', `تم تحويل ${dto.points} نقطة إلى ${amount} YER في محفظتك.`, { points: dto.points, amount });
    return { success: true, message: 'Points redeemed to wallet', data };
  }

  async activeCoupons() {
    const now = new Date();
    const data = await this.db.coupon.findMany({
      where: { status: 'ACTIVE', OR: [{ startsAt: null }, { startsAt: { lte: now } }], AND: [{ OR: [{ endsAt: null }, { endsAt: { gte: now } }] }] },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });
    return { success: true, data };
  }

  async adminCoupons(userId: number) {
    await this.assertAdmin(userId);
    const data = await this.db.coupon.findMany({ include: { redemptions: true }, orderBy: { createdAt: 'desc' }, take: 100 });
    return { success: true, data };
  }

  async createCoupon(userId: number, dto: CreateCouponDto) {
    await this.assertAdmin(userId);
    const data = await this.db.coupon.create({
      data: {
        code: this.normalizedCode(dto.code),
        titleAr: dto.titleAr,
        titleEn: dto.titleEn ?? null,
        description: dto.description ?? null,
        discountType: dto.discountType,
        discountValue: dto.discountType === 'FREE_DELIVERY' ? 0 : dto.discountValue,
        maxDiscountAmount: dto.maxDiscountAmount ?? null,
        minOrderAmount: dto.minOrderAmount ?? 0,
        scope: dto.scope ?? 'ALL',
        stackable: dto.stackable ?? false,
        eligibleCategoryIds: dto.eligibleCategoryIds ?? null,
        eligibleServiceIds: dto.eligibleServiceIds ?? null,
        eligibleMerchantIds: dto.eligibleMerchantIds ?? null,
        eligibleWorkshopIds: dto.eligibleWorkshopIds ?? null,
        usageLimit: dto.usageLimit ?? null,
        perUserLimit: dto.perUserLimit ?? 1,
        startsAt: dto.startsAt ? new Date(dto.startsAt) : null,
        endsAt: dto.endsAt ? new Date(dto.endsAt) : null,
        status: dto.status ?? 'ACTIVE',
        createdByUserId: userId,
      },
    });
    await this.auditWrite(userId, 'coupon.created', 'coupon', data.id, { code: data.code, scope: data.scope });
    return { success: true, message: 'Coupon created', data };
  }

  async updateCouponStatus(userId: number, couponId: number, dto: UpdateCouponStatusDto) {
    await this.assertAdmin(userId);
    const data = await this.db.coupon.update({ where: { id: couponId }, data: { status: dto.status } });
    await this.auditWrite(userId, 'coupon.status.updated', 'coupon', couponId, { status: dto.status });
    return { success: true, message: 'Coupon status updated', data };
  }

  private jsonList(value: any): number[] {
    if (Array.isArray(value)) return value.map(Number).filter((n) => Number.isFinite(n));
    return [];
  }

  private intersects(allowed: number[], actual?: number[]) {
    if (!allowed.length) return true;
    const source = actual ?? [];
    return source.some((id) => allowed.includes(Number(id)));
  }

  private async validateCouponEntity(userId: number, code: string, amount: number, scope: string, options: Partial<ValidateCouponDto> = {}) {
    const coupon = await this.db.coupon.findUnique({ where: { code: this.normalizedCode(code) } });
    if (!coupon) throw new NotFoundException({ message: 'Coupon not found', error_code: 'COUPON_NOT_FOUND' });
    const now = new Date();
    if (coupon.status !== 'ACTIVE') throw new BadRequestException({ message: 'الكوبون غير نشط', error_code: 'COUPON_NOT_ACTIVE' });
    if (coupon.startsAt && coupon.startsAt > now) throw new BadRequestException({ message: 'الكوبون لم يبدأ بعد', error_code: 'COUPON_NOT_STARTED' });
    if (coupon.endsAt && coupon.endsAt < now) throw new BadRequestException({ message: 'انتهت صلاحية الكوبون', error_code: 'COUPON_EXPIRED' });
    if (coupon.scope !== 'ALL' && coupon.scope !== scope) throw new BadRequestException({ message: 'الكوبون غير متاح لهذا النوع', error_code: 'COUPON_SCOPE_MISMATCH' });
    if (coupon.usageLimit && coupon.usedCount >= coupon.usageLimit) throw new BadRequestException({ message: 'تم استهلاك الكوبون بالكامل', error_code: 'COUPON_USAGE_LIMIT' });
    if (amount < this.amountNumber(coupon.minOrderAmount)) throw new BadRequestException({ message: 'قيمة الطلب أقل من الحد الأدنى للكوبون', error_code: 'COUPON_MIN_AMOUNT' });
    if (!this.intersects(this.jsonList(coupon.eligibleCategoryIds), options.categoryIds)) throw new BadRequestException({ message: 'الكوبون غير متاح لهذه الفئة', error_code: 'COUPON_CATEGORY_NOT_ELIGIBLE' });
    if (!this.intersects(this.jsonList(coupon.eligibleServiceIds), options.serviceIds)) throw new BadRequestException({ message: 'الكوبون غير متاح لهذه الخدمة', error_code: 'COUPON_SERVICE_NOT_ELIGIBLE' });
    if (this.jsonList(coupon.eligibleMerchantIds).length && !this.jsonList(coupon.eligibleMerchantIds).includes(Number(options.merchantId))) throw new BadRequestException({ message: 'الكوبون غير متاح لهذا التاجر', error_code: 'COUPON_MERCHANT_NOT_ELIGIBLE' });
    if (this.jsonList(coupon.eligibleWorkshopIds).length && !this.jsonList(coupon.eligibleWorkshopIds).includes(Number(options.workshopId))) throw new BadRequestException({ message: 'الكوبون غير متاح لهذه الورشة', error_code: 'COUPON_WORKSHOP_NOT_ELIGIBLE' });
    const userUsage = await this.db.couponRedemption.count({ where: { couponId: coupon.id, userId } });
    if (userUsage >= coupon.perUserLimit) throw new BadRequestException({ message: 'استخدمت هذا الكوبون مسبقًا', error_code: 'COUPON_USER_LIMIT' });
    let discount = 0;
    if (coupon.discountType === 'FREE_DELIVERY') discount = this.amountNumber(options.deliveryFee);
    else discount = coupon.discountType === 'PERCENTAGE' ? amount * (this.amountNumber(coupon.discountValue) / 100) : this.amountNumber(coupon.discountValue);
    if (coupon.maxDiscountAmount) discount = Math.min(discount, this.amountNumber(coupon.maxDiscountAmount));
    discount = Math.max(0, Math.min(amount + this.amountNumber(options.deliveryFee), Math.round(discount * 100) / 100));
    return { coupon, discount };
  }

  async validateCoupon(userId: number, dto: ValidateCouponDto) {
    const result = await this.validateCouponEntity(userId, dto.code, dto.amount, dto.scope ?? 'ALL', dto);
    return { success: true, data: { coupon: result.coupon, discountAmount: result.discount } };
  }

  async redeemOrderCoupon(userId: number, orderId: number, dto: RedeemCouponDto) {
    const order = await this.db.order.findFirst({ where: { id: orderId, userId }, include: { items: { include: { listing: { include: { product: true } } } } } });
    if (!order) throw new NotFoundException({ message: 'Order not found', error_code: 'ORDER_NOT_FOUND' });
    if (order.paymentStatus === 'PAID') throw new BadRequestException({ message: 'لا يمكن تطبيق كوبون على طلب مدفوع', error_code: 'ORDER_ALREADY_PAID' });
    const amount = this.amountNumber(order.subtotalAmount);
    const categoryIds = order.items.map((i: any) => i.listing?.product?.categoryId).filter(Boolean);
    const { coupon, discount } = await this.validateCouponEntity(userId, dto.code, amount, 'MARKETPLACE', { categoryIds, merchantId: order.organizationId, deliveryFee: this.amountNumber(order.deliveryFee) });
    const idempotencyKey = dto.idempotencyKey ?? `coupon-order-${order.id}`;
    const existing = await this.db.couponRedemption.findFirst({ where: { OR: [{ orderId }, { idempotencyKey }] } });
    if (existing) throw new BadRequestException({ message: 'تم تطبيق كوبون مسبقًا على هذا الطلب', error_code: 'ORDER_COUPON_EXISTS' });
    const data = await this.db.$transaction(async (tx: Tx) => {
      const redemption = await tx.couponRedemption.create({ data: { couponId: coupon.id, userId, orderId, discountAmount: discount, currency: order.currency, idempotencyKey } });
      const updated = await tx.order.update({ where: { id: order.id }, data: { discountAmount: discount, totalAmount: Math.max(0, this.amountNumber(order.subtotalAmount) + this.amountNumber(order.deliveryFee) - discount) } });
      await tx.coupon.update({ where: { id: coupon.id }, data: { usedCount: { increment: 1 } } });
      return { redemption, order: updated };
    });
    await this.auditWrite(userId, 'coupon.redeemed.order', 'order', order.id, { couponId: coupon.id, discount });
    return { success: true, message: 'Coupon redeemed for order', data };
  }

  async redeemServiceOrderCoupon(userId: number, serviceOrderId: number, dto: RedeemCouponDto) {
    const order = await this.db.serviceOrder.findFirst({ where: { id: serviceOrderId, userId } });
    if (!order) throw new NotFoundException({ message: 'Service order not found', error_code: 'SERVICE_ORDER_NOT_FOUND' });
    const amount = this.amountNumber(order.finalAmount ?? order.approvedAmount ?? order.estimatedAmount);
    const { coupon, discount } = await this.validateCouponEntity(userId, dto.code, amount, 'WORKSHOP', { serviceIds: order.workshopServiceId ? [order.workshopServiceId] : [], workshopId: order.organizationId });
    const idempotencyKey = dto.idempotencyKey ?? `coupon-service-order-${order.id}`;
    const existing = await this.db.couponRedemption.findFirst({ where: { OR: [{ serviceOrderId }, { idempotencyKey }] } });
    if (existing) throw new BadRequestException({ message: 'تم تطبيق كوبون مسبقًا على أمر الصيانة', error_code: 'SERVICE_COUPON_EXISTS' });
    const data = await this.db.$transaction(async (tx: Tx) => {
      const redemption = await tx.couponRedemption.create({ data: { couponId: coupon.id, userId, serviceOrderId, discountAmount: discount, currency: order.currency ?? 'YER', idempotencyKey } });
      await tx.coupon.update({ where: { id: coupon.id }, data: { usedCount: { increment: 1 } } });
      return { redemption, discountAmount: discount };
    });
    await this.auditWrite(userId, 'coupon.redeemed.service_order', 'service_order', order.id, { couponId: coupon.id, discount });
    return { success: true, message: 'Coupon redeemed for service order', data };
  }

  private referralCodeForUser(user: any) {
    const base = (user.displayName || user.phoneNormalized || user.email || `USER${user.id}`).toString().replace(/[^A-Za-z0-9]/g, '').toUpperCase().slice(0, 8) || `USER${user.id}`;
    return `${base}${user.id}`.slice(0, 20);
  }

  async myReferralDashboard(userId: number) {
    const code = await this.ensureReferralCode(userId);
    const relationships = await this.db.referralRelationship.findMany({ where: { referrerUserId: userId }, include: { referred: true, rewards: true }, orderBy: { createdAt: 'desc' }, take: 100 }).catch(() => []);
    return { success: true, data: { code, relationships } };
  }

  async ensureReferralCode(userId: number) {
    const existing = await this.db.referralCode.findFirst({ where: { userId, status: 'ACTIVE' }, orderBy: { id: 'asc' } }).catch(() => null);
    if (existing) return existing;
    const user = await this.db.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException({ message: 'User not found', error_code: 'USER_NOT_FOUND' });
    let code = this.referralCodeForUser(user);
    for (let i = 0; i < 5; i += 1) {
      const exists = await this.db.referralCode.findUnique({ where: { code } }).catch(() => null);
      if (!exists) break;
      code = `${this.referralCodeForUser(user)}${Math.floor(100 + Math.random() * 900)}`.slice(0, 30);
    }
    const data = await this.db.referralCode.create({ data: { userId, code, status: 'ACTIVE' } });
    await this.auditWrite(userId, 'referral.code.created', 'referral_code', data.id, { code: data.code });
    return data;
  }

  async applyReferralCode(userId: number, dto: ApplyReferralDto) {
    const code = await this.db.referralCode.findUnique({ where: { code: this.normalizedCode(dto.code) } });
    if (!code || code.status !== 'ACTIVE') throw new NotFoundException({ message: 'Referral code not found', error_code: 'REFERRAL_CODE_NOT_FOUND' });
    if (code.userId === userId) throw new BadRequestException({ message: 'لا يمكن استخدام كود إحالة خاص بك', error_code: 'SELF_REFERRAL_NOT_ALLOWED' });
    const existing = await this.db.referralRelationship.findUnique({ where: { referredUserId: userId } }).catch(() => null);
    if (existing) throw new ConflictException({ message: 'تم ربط هذا الحساب بإحالة مسبقًا', error_code: 'REFERRAL_ALREADY_EXISTS' });
    const data = await this.db.$transaction(async (tx: Tx) => {
      const relationship = await tx.referralRelationship.create({ data: { referralCodeId: code.id, referrerUserId: code.userId, referredUserId: userId, status: 'PENDING' } });
      await tx.referralCode.update({ where: { id: code.id }, data: { usesCount: { increment: 1 } } });
      return relationship;
    });
    await this.auditWrite(userId, 'referral.applied', 'referral_relationship', data.id, { referrerUserId: code.userId, code: code.code });
    await this.notifications.createForUser(code.userId, 'تم استخدام كود الإحالة', 'قام مستخدم جديد باستخدام كود الإحالة الخاص بك.', { referral_relationship_id: data.id });
    return { success: true, message: 'Referral code applied', data };
  }

  async qualifyReferral(userId: number, relationshipId: number, dto: QualifyReferralDto) {
    await this.assertAdmin(userId);
    const relationship = await this.db.referralRelationship.findUnique({ where: { id: relationshipId } });
    if (!relationship) throw new NotFoundException({ message: 'Referral not found', error_code: 'REFERRAL_NOT_FOUND' });
    if (relationship.status === 'REWARDED') return { success: true, message: 'Referral already rewarded', data: relationship };
    const referrerPoints = dto.referrerPoints ?? DEFAULT_REFERRER_POINTS;
    const referredPoints = dto.referredPoints ?? DEFAULT_REFERRED_POINTS;
    const baseKey = dto.idempotencyKey ?? `referral-${relationship.id}-${dto.orderId ?? dto.serviceOrderId ?? 'manual'}`;
    const data = await this.db.$transaction(async (tx: Tx) => {
      const updated = await tx.referralRelationship.update({ where: { id: relationship.id }, data: { status: 'REWARDED', qualifiedAt: relationship.qualifiedAt ?? new Date(), rewardedAt: new Date(), qualifyingOrderId: dto.orderId ?? relationship.qualifyingOrderId ?? null } });
      const referrerPoint = await this.addPoints(tx, relationship.referrerUserId, referrerPoints, 'REFERRAL_REWARD', { orderId: dto.orderId ?? null, serviceOrderId: dto.serviceOrderId ?? null, createdByUserId: userId, idempotencyKey: `${baseKey}-referrer-points`, description: 'مكافأة إحالة للمرسل' });
      const referredPoint = await this.addPoints(tx, relationship.referredUserId, referredPoints, 'REFERRAL_REWARD', { orderId: dto.orderId ?? null, serviceOrderId: dto.serviceOrderId ?? null, createdByUserId: userId, idempotencyKey: `${baseKey}-referred-points`, description: 'مكافأة إحالة للمستخدم الجديد' });
      const rewards: any[] = [];
      rewards.push(await tx.referralReward.create({ data: { relationshipId: relationship.id, userId: relationship.referrerUserId, rewardType: 'LOYALTY_POINTS', status: 'GRANTED', points: referrerPoints, orderId: dto.orderId ?? null, serviceOrderId: dto.serviceOrderId ?? null, loyaltyPointTransactionId: referrerPoint.entry.id, idempotencyKey: `${baseKey}-referrer-reward`, createdByUserId: userId, grantedAt: new Date() } }));
      rewards.push(await tx.referralReward.create({ data: { relationshipId: relationship.id, userId: relationship.referredUserId, rewardType: 'LOYALTY_POINTS', status: 'GRANTED', points: referredPoints, orderId: dto.orderId ?? null, serviceOrderId: dto.serviceOrderId ?? null, loyaltyPointTransactionId: referredPoint.entry.id, idempotencyKey: `${baseKey}-referred-reward`, createdByUserId: userId, grantedAt: new Date() } }));
      if (dto.walletAmount && dto.walletAmount > 0) {
        const wallet = await this.ensureWallet(relationship.referrerUserId, tx, 'YER');
        const walletEntry = await this.createWalletEntry(tx, wallet, 'CREDIT', 'REFERRAL_REWARD', dto.walletAmount, { referenceType: 'REFERRAL', referenceId: String(relationship.id), createdByUserId: userId, idempotencyKey: `${baseKey}-wallet`, description: 'رصيد مكافأة إحالة' });
        rewards.push(await tx.referralReward.create({ data: { relationshipId: relationship.id, userId: relationship.referrerUserId, rewardType: 'WALLET_CREDIT', status: 'GRANTED', walletAmount: dto.walletAmount, currency: 'YER', orderId: dto.orderId ?? null, serviceOrderId: dto.serviceOrderId ?? null, walletLedgerEntryId: walletEntry.entry.id, idempotencyKey: `${baseKey}-wallet-reward`, createdByUserId: userId, grantedAt: new Date() } }));
      }
      await tx.referralCode.update({ where: { id: relationship.referralCodeId }, data: { rewardsCount: { increment: rewards.length } } });
      return { relationship: updated, rewards };
    });
    await this.auditWrite(userId, 'referral.rewarded', 'referral_relationship', relationshipId, { referrerPoints, referredPoints, walletAmount: dto.walletAmount ?? 0 });
    await this.notifications.createForUser(relationship.referrerUserId, 'تمت إضافة مكافأة إحالة', `حصلت على ${referrerPoints} نقطة من برنامج الإحالات.`, { referral_relationship_id: relationshipId });
    await this.notifications.createForUser(relationship.referredUserId, 'تمت إضافة مكافأة ترحيبية', `حصلت على ${referredPoints} نقطة مكافأة ترحيبية.`, { referral_relationship_id: relationshipId });
    return { success: true, message: 'Referral rewarded', data };
  }

  async manageCampaigns(userId: number) {
    await this.assertAdmin(userId);
    const data = await this.db.retentionCampaign.findMany({ include: { coupon: true, events: true }, orderBy: { createdAt: 'desc' }, take: 100 });
    return { success: true, data };
  }

  async createCampaign(userId: number, dto: CreateRetentionCampaignDto) {
    await this.assertAdmin(userId);
    const data = await this.db.retentionCampaign.create({ data: { title: dto.title, channel: dto.channel ?? 'IN_APP', audienceType: dto.audienceType, messageTitle: dto.messageTitle, messageBody: dto.messageBody, couponId: dto.couponId ?? null, startsAt: dto.startsAt ? new Date(dto.startsAt) : null, endsAt: dto.endsAt ? new Date(dto.endsAt) : null, createdByUserId: userId, status: 'DRAFT' } });
    await this.auditWrite(userId, 'retention.campaign.created', 'retention_campaign', data.id, { title: dto.title });
    return { success: true, message: 'Retention campaign created', data };
  }

  private async campaignAudience(campaign: any) {
    if (campaign.audienceType === 'ALL_CUSTOMERS' || campaign.audienceType === 'INACTIVE_CUSTOMERS') {
      return this.db.user.findMany({ where: { status: 'ACTIVE' }, take: 500 });
    }
    const tier = campaign.audienceType.replace('_CUSTOMERS', '');
    const accounts = await this.db.loyaltyAccount.findMany({ where: { tier }, include: { user: true }, take: 500 });
    return accounts.map((a: any) => a.user);
  }

  async dispatchCampaign(userId: number, campaignId: number) {
    await this.assertAdmin(userId);
    const campaign = await this.db.retentionCampaign.findUnique({ where: { id: campaignId }, include: { coupon: true } });
    if (!campaign) throw new NotFoundException({ message: 'Campaign not found', error_code: 'CAMPAIGN_NOT_FOUND' });
    if (['SENT', 'CANCELLED'].includes(campaign.status)) throw new BadRequestException({ message: 'الحملة مغلقة ولا يمكن إرسالها', error_code: 'CAMPAIGN_CLOSED' });
    const users = await this.campaignAudience(campaign);
    const data = await this.db.$transaction(async (tx: Tx) => {
      let eventsCount = 0;
      const deliveredAt = new Date();
      for (const target of users) {
        await tx.retentionCampaignEvent.upsert({
          where: { campaignId_userId: { campaignId, userId: target.id } },
          update: { status: 'SENT', deliveredAt },
          create: { campaignId, userId: target.id, status: 'SENT', deliveredAt },
        });
        eventsCount += 1;
      }
      const updated = await tx.retentionCampaign.update({ where: { id: campaignId }, data: { status: 'SENT', sentAt: new Date() } });
      return { campaign: updated, eventsCount };
    });
    for (const target of users) {
      await this.notifications.createForUser(target.id, campaign.messageTitle, campaign.messageBody, { campaign_id: campaignId, coupon_code: campaign.coupon?.code });
    }
    await this.auditWrite(userId, 'retention.campaign.dispatched', 'retention_campaign', campaignId, { eventsCount: data.eventsCount });
    return { success: true, message: 'Retention campaign dispatched', data };
  }
}
