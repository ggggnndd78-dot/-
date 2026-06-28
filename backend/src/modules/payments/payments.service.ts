import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createHmac, timingSafeEqual } from 'crypto';
import { EventBusService } from '../../common/events/event-bus.service';
import { PrismaService } from '../../prisma/prisma.service';
import { AuditService } from '../audit/audit.service';
import { NotificationsService } from '../notifications/notifications.service';
import { AccountingService } from '../accounting/accounting.service';
import {
  CreateManualServicePaymentDto,
  CreateOrderPaymentDto,
  CreateRefundDto,
  CreateSettlementDto,
  MarkPaymentDto,
  PaymentWebhookDto,
  ReviewPaymentProofDto,
  ReviewRefundDto,
  UploadPaymentProofDto,
} from './dto/payments.dto';

const ACTIVE_PAYMENT_STATUSES = ['INITIATED', 'PENDING_COD', 'WAITING_PROOF', 'PENDING_REVIEW', 'UNDER_REVIEW', 'AUTHORIZED'];
const CLOSED_PAYMENT_STATUSES = ['CONFIRMED', 'PAID', 'FAILED', 'REJECTED', 'CANCELLED', 'EXPIRED', 'REFUNDED', 'PARTIALLY_REFUNDED'];

type MethodConfigLike = {
  id?: number | null;
  code: string;
  kind: 'COD' | 'BANK_TRANSFER' | 'LOCAL_WALLET' | 'PAYMENT_GATEWAY';
  providerCode?: string | null;
  requiresProof?: boolean;
  requiresWebhook?: boolean;
  nameAr?: string;
  nameEn?: string | null;
  instructionsAr?: string | null;
  allowForOrders?: boolean;
  allowForServices?: boolean;
};

@Injectable()
export class PaymentsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notifications: NotificationsService,
    private readonly audit: AuditService,
    private readonly events: EventBusService,
    private readonly config: ConfigService,
    private readonly accounting: AccountingService,
  ) {}

  private get db() { return this.prisma as any; }

  private fallbackMethods(): MethodConfigLike[] {
    return [
      { code: 'CASH_ON_PICKUP', kind: 'COD', providerCode: 'CASH', nameAr: 'الدفع عند الاستلام من الفرع', requiresProof: false, requiresWebhook: false },
      { code: 'CASH_ON_DELIVERY', kind: 'COD', providerCode: 'CASH', nameAr: 'الدفع عند التوصيل', requiresProof: false, requiresWebhook: false },
      { code: 'BANK_TRANSFER', kind: 'BANK_TRANSFER', providerCode: 'BANK_TRANSFER', nameAr: 'تحويل بنكي', requiresProof: true, requiresWebhook: false, instructionsAr: 'حوّل المبلغ ثم ارفع إثبات التحويل للمراجعة المالية.' },
      { code: 'LOCAL_WALLET', kind: 'LOCAL_WALLET', providerCode: 'LOCAL_WALLET', nameAr: 'محفظة محلية', requiresProof: true, requiresWebhook: false },
      { code: 'PAYMENT_GATEWAY', kind: 'PAYMENT_GATEWAY', providerCode: 'PAYMENT_GATEWAY', nameAr: 'بوابة دفع مستقبلية', requiresProof: false, requiresWebhook: true },
    ];
  }

  private async getMethod(code?: string | null): Promise<MethodConfigLike> {
    const normalized = (code || 'CASH_ON_DELIVERY').trim().toUpperCase();
    const method = await this.db.paymentMethodConfig.findFirst({ where: { code: normalized, status: 'ACTIVE' } }).catch(() => null);
    if (method) return method;
    const fallback = this.fallbackMethods().find((item) => item.code === normalized);
    if (fallback) return fallback;
    throw new BadRequestException({ message: 'طريقة الدفع غير مفعلة', error_code: 'PAYMENT_METHOD_NOT_AVAILABLE' });
  }

  private methodToOrderPaymentStatus(method: MethodConfigLike) {
    if (method.kind === 'COD') return 'PENDING_COD';
    if (method.kind === 'BANK_TRANSFER' || method.kind === 'LOCAL_WALLET') return 'WAITING_PROOF';
    return 'PENDING_REVIEW';
  }

  private methodToTransactionStatus(method: MethodConfigLike) {
    if (method.kind === 'COD') return 'PENDING_COD';
    if (method.kind === 'BANK_TRANSFER' || method.kind === 'LOCAL_WALLET') return 'WAITING_PROOF';
    return 'INITIATED';
  }

  private methodToPrismaMethod(method: MethodConfigLike) {
    if (method.code === 'LOCAL_WALLET') return 'LOCAL_WALLET';
    if (method.kind === 'PAYMENT_GATEWAY') return 'PAYMENT_GATEWAY';
    return method.code;
  }

  private methodToProvider(method: MethodConfigLike) {
    if (method.kind === 'COD') return 'CASH';
    if (method.kind === 'BANK_TRANSFER') return 'BANK_TRANSFER';
    if (method.kind === 'LOCAL_WALLET') return 'LOCAL_WALLET';
    if (method.kind === 'PAYMENT_GATEWAY') return 'PAYMENT_GATEWAY';
    return 'MANUAL';
  }

  private makeReference(prefix: string) {
    const d = new Date();
    const date = `${d.getFullYear()}${String(d.getMonth() + 1).padStart(2, '0')}${String(d.getDate()).padStart(2, '0')}`;
    return `${prefix}-${date}-${Math.floor(100000 + Math.random() * 900000)}`;
  }

  private async createUniqueReference(tx: any, prefix: string, model: 'paymentTransaction' | 'refundRequest' | 'settlement') {
    const field = model === 'paymentTransaction' ? 'internalReference' : model === 'refundRequest' ? 'refundNumber' : 'settlementNumber';
    for (let attempt = 0; attempt < 5; attempt += 1) {
      const value = this.makeReference(prefix);
      const existing = await tx[model].findFirst({ where: { [field]: value } });
      if (!existing) return value;
    }
    throw new BadRequestException({ message: 'تعذر توليد مرجع مالي فريد', error_code: 'FINANCIAL_REFERENCE_GENERATION_FAILED' });
  }

  private async assertOrganizationAccess(userId: number, organizationId: number) {
    const member = await this.db.organizationMember.findFirst({ where: { userId, organizationId, status: 'ACTIVE' } });
    if (!member) throw new ForbiddenException({ message: 'ليس لديك صلاحية على هذه المؤسسة', error_code: 'ORGANIZATION_ACCESS_DENIED' });
    return member;
  }

  async paymentMethods() {
    const fromDb = await this.db.paymentMethodConfig.findMany({
      where: { status: 'ACTIVE' },
      orderBy: [{ sortOrder: 'asc' }, { id: 'asc' }],
    }).catch(() => []);

    const data = fromDb.length ? fromDb : this.fallbackMethods().map((method, index) => ({
      ...method,
      id: null,
      status: 'ACTIVE',
      sortOrder: index + 1,
    }));

    return { success: true, data };
  }

  private async findPrimaryInvoiceForOrder(tx: any, order: any) {
    const existing = await tx.invoice.findFirst({ where: { orderId: order.id }, orderBy: { id: 'asc' } });
    if (existing) return existing;
    return tx.invoice.create({
      data: {
        orderId: order.id,
        customerId: order.userId,
        invoiceType: 'ORDER',
        invoiceNumber: `INV-${order.orderNumber}`,
        subtotalAmount: order.subtotalAmount,
        deliveryFee: order.deliveryFee,
        discountAmount: order.discountAmount,
        totalAmount: order.totalAmount,
        currency: order.currency,
        status: 'ISSUED',
      },
    });
  }

  async createOrderPayment(userId: number, orderId: number, dto: CreateOrderPaymentDto) {
    const order = await this.db.order.findFirst({
      where: { id: orderId, userId },
      include: { invoices: { orderBy: { id: 'asc' }, take: 1 } },
    });
    if (!order) throw new NotFoundException({ message: 'Order not found', error_code: 'ORDER_NOT_FOUND' });
    if (['CANCELLED', 'REFUNDED'].includes(order.status)) {
      throw new BadRequestException({ message: 'لا يمكن إنشاء دفع لطلب مغلق', error_code: 'ORDER_NOT_PAYABLE' });
    }
    if (['PAID', 'CONFIRMED', 'REFUNDED'].includes(order.paymentStatus)) {
      throw new BadRequestException({ message: 'الطلب مدفوع مسبقاً', error_code: 'ORDER_ALREADY_PAID' });
    }

    const methodCode = dto.paymentMethodCode ?? dto.paymentMethod ?? order.paymentMethod;
    const method = await this.getMethod(methodCode);
    if (method.allowForOrders === false) throw new BadRequestException({ message: 'طريقة الدفع غير متاحة للطلبات', error_code: 'PAYMENT_METHOD_NOT_ALLOWED_FOR_ORDERS' });

    if (dto.idempotencyKey) {
      const existing = await this.db.paymentTransaction.findUnique({ where: { idempotencyKey: dto.idempotencyKey } }).catch(() => null);
      if (existing) return { success: true, message: 'Payment intent already exists', data: existing };
    }

    const duplicate = await this.db.paymentTransaction.findFirst({
      where: {
        orderId: order.id,
        amount: order.totalAmount,
        status: { in: ACTIVE_PAYMENT_STATUSES },
        method: this.methodToPrismaMethod(method),
      },
      orderBy: { createdAt: 'desc' },
    });
    if (duplicate) return { success: true, message: 'Active payment intent exists', data: duplicate };

    const data = await this.db.$transaction(async (tx: any) => {
      const invoice = await this.findPrimaryInvoiceForOrder(tx, order);
      const reference = await this.createUniqueReference(tx, 'PAY', 'paymentTransaction');
      const status = this.methodToTransactionStatus(method);
      const transaction = await tx.paymentTransaction.create({
        data: {
          invoiceId: invoice.id,
          orderId: order.id,
          payerUserId: userId,
          organizationId: order.organizationId,
          paymentMethodConfigId: method.id ?? null,
          type: 'ORDER_PAYMENT',
          provider: dto.provider ?? this.methodToProvider(method),
          method: this.methodToPrismaMethod(method),
          status,
          amount: order.totalAmount,
          currency: order.currency,
          internalReference: reference,
          externalReference: dto.externalReference ?? null,
          idempotencyKey: dto.idempotencyKey ?? null,
          receiptUrl: dto.receiptUrl ?? null,
          reviewNote: dto.note ?? null,
          meta: {
            payment_method_code: method.code,
            requires_proof: method.requiresProof ?? false,
            requires_webhook: method.requiresWebhook ?? false,
          },
        },
      });

      await tx.paymentAttempt.create({
        data: {
          paymentId: transaction.id,
          attemptNumber: 1,
          provider: dto.provider ?? this.methodToProvider(method),
          status: method.kind === 'PAYMENT_GATEWAY' ? 'CREATED' : 'PENDING',
          providerReference: dto.externalReference ?? null,
          requestPayload: { order_id: order.id, invoice_id: invoice.id, method_code: method.code, amount: Number(order.totalAmount), currency: order.currency },
        },
      }).catch(() => null);

      await tx.order.update({
        where: { id: order.id },
        data: { paymentMethod: this.methodToPrismaMethod(method), paymentStatus: this.methodToOrderPaymentStatus(method) },
      });

      return transaction;
    });

    await this.audit.write({ actorUserId: userId, action: 'payments.intent.created', entityType: 'payment', entityId: data.id, metadata: { order_id: order.id, method_code: method.code } }).catch(() => null);
    await this.events.publish({ name: 'PaymentInitiated', aggregateType: 'payment', aggregateId: data.id, actorUserId: userId, source: 'payments', idempotencyKey: `payment-initiated-${data.id}`, payload: { order_id: order.id, amount: Number(data.amount), currency: data.currency, method_code: method.code } }).catch(() => null);
    await this.notifications.createForUser(userId, 'تم إنشاء عملية دفع', `مرجع الدفع: ${data.internalReference}`, { payment_id: data.id, order_id: order.id }).catch(() => null);
    return { success: true, message: 'Payment intent created', data };
  }

  async orderTransactions(userId: number, orderId: number) {
    const order = await this.db.order.findFirst({ where: { id: orderId } });
    if (!order) throw new NotFoundException({ message: 'Order not found', error_code: 'ORDER_NOT_FOUND' });
    if (order.userId !== userId) await this.assertOrganizationAccess(userId, order.organizationId);
    const data = await this.db.paymentTransaction.findMany({
      where: { orderId },
      include: { attempts: { orderBy: { createdAt: 'desc' }, take: 3 }, proofs: { orderBy: { createdAt: 'desc' }, take: 3 }, invoice: true, methodConfig: true },
      orderBy: { createdAt: 'desc' },
    });
    return { success: true, data };
  }

  async myPayments(userId: number) {
    const data = await this.db.paymentTransaction.findMany({
      where: { payerUserId: userId },
      include: { order: true, serviceOrder: true, invoice: true, proofs: { orderBy: { createdAt: 'desc' }, take: 1 } },
      orderBy: { createdAt: 'desc' },
      take: 100,
    });
    return { success: true, data };
  }

  private async assertPaymentOwner(userId: number, paymentId: number) {
    const payment = await this.db.paymentTransaction.findUnique({ where: { id: paymentId }, include: { order: true, serviceOrder: true, invoice: true, methodConfig: true } });
    if (!payment) throw new NotFoundException({ message: 'Payment not found', error_code: 'PAYMENT_NOT_FOUND' });
    if (payment.payerUserId !== userId) throw new ForbiddenException({ message: 'لا يمكنك الوصول لهذه الدفعة', error_code: 'PAYMENT_ACCESS_DENIED' });
    return payment;
  }

  async uploadProof(userId: number, paymentId: number, dto: UploadPaymentProofDto) {
    const payment = await this.assertPaymentOwner(userId, paymentId);
    const requiresProof = payment.methodConfig?.requiresProof || ['BANK_TRANSFER', 'LOCAL_WALLET'].includes(payment.provider);
    if (!requiresProof) throw new BadRequestException({ message: 'طريقة الدفع لا تحتاج إثبات تحويل', error_code: 'PAYMENT_PROOF_NOT_REQUIRED' });
    if (!['WAITING_PROOF', 'UNDER_REVIEW', 'PENDING_REVIEW'].includes(payment.status)) {
      throw new BadRequestException({ message: 'لا يمكن رفع إثبات لهذه العملية', error_code: 'PAYMENT_PROOF_NOT_ALLOWED' });
    }

    const data = await this.db.$transaction(async (tx: any) => {
      const proof = await tx.paymentProof.create({
        data: {
          paymentId: payment.id,
          uploadedByUserId: userId,
          fileUrl: dto.fileUrl,
          fileName: dto.fileName ?? null,
          fileType: dto.fileType ?? null,
          amount: dto.amount ?? null,
          referenceNumber: dto.referenceNumber ?? null,
          status: 'PENDING_REVIEW',
          reviewNotes: dto.note ?? null,
        },
      });
      await tx.paymentTransaction.update({ where: { id: payment.id }, data: { status: 'UNDER_REVIEW', reviewNote: dto.note ?? payment.reviewNote } });
      if (payment.orderId) await tx.order.update({ where: { id: payment.orderId }, data: { paymentStatus: 'UNDER_REVIEW' } });
      return proof;
    });

    await this.audit.write({ actorUserId: userId, action: 'payments.proof.uploaded', entityType: 'payment_proof', entityId: data.id, metadata: { payment_id: payment.id } }).catch(() => null);
    return { success: true, message: 'Payment proof uploaded', data };
  }

  private async confirmPayment(tx: any, payment: any, actorUserId: number | null, note?: string, externalReference?: string) {
    const updated = await tx.paymentTransaction.update({
      where: { id: payment.id },
      data: {
        status: 'CONFIRMED',
        paidAt: payment.paidAt ?? new Date(),
        reviewedAt: new Date(),
        approvedByUserId: actorUserId ?? payment.approvedByUserId ?? null,
        externalReference: externalReference ?? payment.externalReference,
        reviewNote: note ?? payment.reviewNote,
      },
    });

    if (payment.invoiceId) await tx.invoice.update({ where: { id: payment.invoiceId }, data: { status: 'PAID', paidAt: new Date() } }).catch(() => null);
    if (payment.orderId) await tx.order.update({ where: { id: payment.orderId }, data: { paymentStatus: 'PAID' } }).catch(() => null);
    await this.accounting.postPaymentConfirmed(tx, updated, actorUserId ?? null);
    return updated;
  }

  async approveProof(userId: number, proofId: number, dto: ReviewPaymentProofDto) {
    const proof = await this.db.paymentProof.findUnique({ where: { id: proofId }, include: { payment: true } });
    if (!proof) throw new NotFoundException({ message: 'Payment proof not found', error_code: 'PAYMENT_PROOF_NOT_FOUND' });
    if (proof.status !== 'PENDING_REVIEW') throw new BadRequestException({ message: 'تمت مراجعة الإثبات مسبقاً', error_code: 'PAYMENT_PROOF_ALREADY_REVIEWED' });

    const data = await this.db.$transaction(async (tx: any) => {
      await tx.paymentProof.update({ where: { id: proofId }, data: { status: 'APPROVED', reviewedByUserId: userId, reviewedAt: new Date(), reviewNotes: dto.note ?? null } });
      return this.confirmPayment(tx, proof.payment, userId, dto.note, proof.referenceNumber ?? undefined);
    });

    await this.audit.write({ actorUserId: userId, action: 'payments.proof.approved', entityType: 'payment', entityId: proof.paymentId, metadata: { proof_id: proof.id } }).catch(() => null);
    if (data.payerUserId) await this.notifications.createForUser(data.payerUserId, 'تم تأكيد الدفع', 'تم اعتماد إثبات الدفع بنجاح.', { payment_id: data.id, order_id: data.orderId }).catch(() => null);
    await this.events.publish({ name: 'PaymentConfirmed', aggregateType: 'payment', aggregateId: data.id, actorUserId: userId, source: 'payments', idempotencyKey: `payment-confirmed-${data.id}`, payload: { order_id: data.orderId, service_order_id: data.serviceOrderId, amount: Number(data.amount), currency: data.currency } }).catch(() => null);
    return { success: true, message: 'Payment proof approved', data };
  }

  async rejectProof(userId: number, proofId: number, dto: ReviewPaymentProofDto) {
    const proof = await this.db.paymentProof.findUnique({ where: { id: proofId }, include: { payment: true } });
    if (!proof) throw new NotFoundException({ message: 'Payment proof not found', error_code: 'PAYMENT_PROOF_NOT_FOUND' });
    if (proof.status !== 'PENDING_REVIEW') throw new BadRequestException({ message: 'تمت مراجعة الإثبات مسبقاً', error_code: 'PAYMENT_PROOF_ALREADY_REVIEWED' });

    const data = await this.db.$transaction(async (tx: any) => {
      await tx.paymentProof.update({ where: { id: proofId }, data: { status: 'REJECTED', reviewedByUserId: userId, reviewedAt: new Date(), reviewNotes: dto.note ?? null } });
      const updated = await tx.paymentTransaction.update({ where: { id: proof.paymentId }, data: { status: 'REJECTED', failedAt: new Date(), reviewedAt: new Date(), approvedByUserId: userId, reviewNote: dto.note ?? proof.payment.reviewNote } });
      if (proof.payment.orderId) await tx.order.update({ where: { id: proof.payment.orderId }, data: { paymentStatus: 'REJECTED' } });
      return updated;
    });

    await this.audit.write({ actorUserId: userId, action: 'payments.proof.rejected', entityType: 'payment', entityId: proof.paymentId, metadata: { proof_id: proof.id } }).catch(() => null);
    if (data.payerUserId) await this.notifications.createForUser(data.payerUserId, 'تم رفض إثبات الدفع', dto.note ?? 'يرجى رفع إثبات صحيح.', { payment_id: data.id, order_id: data.orderId }).catch(() => null);
    return { success: true, message: 'Payment proof rejected', data };
  }

  async markTransactionPaid(userId: number, transactionId: number, dto: MarkPaymentDto) {
    const transaction = await this.db.paymentTransaction.findUnique({ where: { id: transactionId } });
    if (!transaction) throw new NotFoundException({ message: 'Transaction not found', error_code: 'PAYMENT_TRANSACTION_NOT_FOUND' });
    if (CLOSED_PAYMENT_STATUSES.includes(transaction.status) && ['CONFIRMED', 'PAID'].includes(transaction.status)) return { success: true, data: transaction };

    const data = await this.db.$transaction(async (tx: any) => this.confirmPayment(tx, transaction, userId, dto.note, dto.externalReference));
    await this.audit.write({ actorUserId: userId, action: 'payments.confirmed.manual', entityType: 'payment', entityId: data.id, metadata: { order_id: data.orderId, service_order_id: data.serviceOrderId } }).catch(() => null);
    if (data.payerUserId) await this.notifications.createForUser(data.payerUserId, 'تم تأكيد الدفع', 'تم اعتماد عملية الدفع بنجاح.', { payment_id: data.id, order_id: data.orderId }).catch(() => null);
    return { success: true, message: 'Payment confirmed', data };
  }

  async markTransactionFailed(userId: number, transactionId: number, dto: MarkPaymentDto) {
    const transaction = await this.db.paymentTransaction.findUnique({ where: { id: transactionId } });
    if (!transaction) throw new NotFoundException({ message: 'Transaction not found', error_code: 'PAYMENT_TRANSACTION_NOT_FOUND' });
    if (['CONFIRMED', 'PAID', 'REFUNDED'].includes(transaction.status)) throw new BadRequestException({ message: 'لا يمكن رفض عملية مؤكدة أو مستردة', error_code: 'PAYMENT_ALREADY_CLOSED' });

    const data = await this.db.$transaction(async (tx: any) => {
      const updated = await tx.paymentTransaction.update({ where: { id: transactionId }, data: { status: 'FAILED', failedAt: new Date(), reviewedAt: new Date(), approvedByUserId: userId, reviewNote: dto.note ?? transaction.reviewNote } });
      if (transaction.orderId) await tx.order.update({ where: { id: transaction.orderId }, data: { paymentStatus: 'FAILED' } });
      return updated;
    });

    await this.audit.write({ actorUserId: userId, action: 'payments.failed.manual', entityType: 'payment', entityId: data.id, metadata: { order_id: data.orderId } }).catch(() => null);
    if (data.payerUserId) await this.notifications.createForUser(data.payerUserId, 'تعذر تأكيد الدفع', dto.note ?? 'تم رفض أو فشل عملية الدفع.', { payment_id: data.id, order_id: data.orderId }).catch(() => null);
    return { success: true, message: 'Payment marked as failed', data };
  }

  async financePayments(params: { status?: string; take?: number; skip?: number }) {
    const take = Math.min(Math.max(params.take ?? 50, 1), 200);
    const data = await this.db.paymentTransaction.findMany({
      where: { status: params.status as any },
      include: { payer: { select: { id: true, displayName: true, phoneNormalized: true, email: true } }, organization: true, order: true, serviceOrder: true, invoice: true, proofs: { orderBy: { createdAt: 'desc' }, take: 1 } },
      orderBy: { createdAt: 'desc' },
      take,
      skip: params.skip ?? 0,
    });
    return { success: true, data };
  }

  async financeProofs(params: { status?: string; take?: number; skip?: number }) {
    const take = Math.min(Math.max(params.take ?? 50, 1), 200);
    const data = await this.db.paymentProof.findMany({
      where: { status: params.status as any },
      include: { payment: { include: { order: true, serviceOrder: true, invoice: true, payer: true } }, uploadedBy: { select: { id: true, displayName: true, phoneNormalized: true, email: true } } },
      orderBy: { createdAt: 'desc' },
      take,
      skip: params.skip ?? 0,
    });
    return { success: true, data };
  }

  async createServiceOrderPayment(userId: number, serviceOrderId: number, dto: CreateManualServicePaymentDto) {
    const serviceOrder = await this.db.serviceOrder.findUnique({ where: { id: serviceOrderId }, include: { invoices: { orderBy: { id: 'asc' }, take: 1 } } });
    if (!serviceOrder) throw new NotFoundException({ message: 'Service order not found', error_code: 'SERVICE_ORDER_NOT_FOUND' });
    await this.assertOrganizationAccess(userId, serviceOrder.organizationId);
    const method = await this.getMethod(dto.paymentMethodCode ?? dto.paymentMethod ?? 'CASH_ON_PICKUP');
    if (method.allowForServices === false) throw new BadRequestException({ message: 'طريقة الدفع غير متاحة للخدمات', error_code: 'PAYMENT_METHOD_NOT_ALLOWED_FOR_SERVICES' });

    const data = await this.db.$transaction(async (tx: any) => {
      let invoice = serviceOrder.invoices?.[0];
      if (!invoice) {
        invoice = await tx.invoice.create({
          data: {
            invoiceType: 'SERVICE_ORDER',
            serviceOrderId,
            customerId: serviceOrder.userId,
            invoiceNumber: this.makeReference('SINV'),
            subtotalAmount: dto.amount,
            totalAmount: dto.amount,
            currency: dto.currency ?? serviceOrder.currency ?? 'YER',
            status: 'ISSUED',
          },
        });
      }
      const payment = await tx.paymentTransaction.create({
        data: {
          invoiceId: invoice.id,
          serviceOrderId,
          payerUserId: serviceOrder.userId,
          organizationId: serviceOrder.organizationId,
          paymentMethodConfigId: method.id ?? null,
          type: 'SERVICE_ORDER_PAYMENT',
          provider: this.methodToProvider(method),
          method: this.methodToPrismaMethod(method),
          status: method.kind === 'COD' ? 'PENDING_COD' : this.methodToTransactionStatus(method),
          amount: dto.amount,
          currency: dto.currency ?? serviceOrder.currency ?? 'YER',
          internalReference: await this.createUniqueReference(tx, 'PAY', 'paymentTransaction'),
          reviewNote: dto.note ?? null,
        },
      });
      await tx.paymentAttempt.create({ data: { paymentId: payment.id, attemptNumber: 1, provider: this.methodToProvider(method), status: 'PENDING' } }).catch(() => null);
      return payment;
    });

    await this.audit.write({ actorUserId: userId, action: 'payments.service_order.intent.created', entityType: 'payment', entityId: data.id, metadata: { service_order_id: serviceOrderId } }).catch(() => null);
    await this.notifications.createForUser(serviceOrder.userId, 'تم إنشاء دفع خدمة صيانة', `مرجع الدفع: ${data.internalReference}`, { service_order_id: serviceOrderId, payment_id: data.id }).catch(() => null);
    return { success: true, message: 'Service order payment intent created', data };
  }

  private verifyWebhookSignature(provider: string, payload: unknown, signature?: string | null) {
    const envKey = `PAYMENT_WEBHOOK_SECRET_${provider.toUpperCase().replace(/[^A-Z0-9]/g, '_')}`;
    const secret = this.config.get<string>(envKey) || this.config.get<string>('PAYMENT_WEBHOOK_SECRET');
    if (!secret || !signature) return false;
    const expected = createHmac('sha256', secret).update(JSON.stringify(payload ?? {})).digest('hex');
    const left = Buffer.from(expected);
    const right = Buffer.from(signature.replace(/^sha256=/, ''));
    return left.length === right.length && timingSafeEqual(left, right);
  }

  async receiveWebhook(provider: string, dto: PaymentWebhookDto, signature?: string) {
    const providerCode = provider.toUpperCase();
    const payload = dto.payload ?? { ...dto };
    const existing = await this.db.paymentWebhook.findUnique({ where: { idempotencyKey: dto.idempotencyKey } }).catch(() => null);
    if (existing?.status === 'PROCESSED') return { success: true, message: 'Webhook already processed', data: existing };

    const verified = this.verifyWebhookSignature(providerCode, payload, signature);
    const webhook = await this.db.paymentWebhook.create({
      data: {
        providerCode,
        eventType: dto.eventType,
        providerReference: dto.providerReference ?? null,
        idempotencyKey: dto.idempotencyKey,
        signature: signature ?? null,
        payload,
        isVerified: verified,
        status: verified ? 'VERIFIED' : 'REJECTED',
        errorMessage: verified ? null : 'Webhook signature verification failed or secret is missing',
      },
    }).catch(async () => this.db.paymentWebhook.findUnique({ where: { idempotencyKey: dto.idempotencyKey } }));

    if (!verified) return { success: false, message: 'Webhook rejected', data: webhook };

    const isSuccess = ['PAID', 'CONFIRMED', 'SUCCESS', 'SUCCEEDED', 'CAPTURED'].includes((dto.status ?? dto.eventType).toUpperCase());
    const isFailed = ['FAILED', 'CANCELLED', 'EXPIRED', 'REJECTED'].includes((dto.status ?? dto.eventType).toUpperCase());
    const reference = dto.paymentReference ?? dto.providerReference;
    const payment = reference ? await this.db.paymentTransaction.findFirst({
      where: { OR: [{ internalReference: reference }, { externalReference: reference }] },
    }) : null;
    if (!payment) {
      const updated = await this.db.paymentWebhook.update({ where: { id: webhook.id }, data: { status: 'FAILED', errorMessage: 'Payment reference not found' } });
      return { success: false, message: 'Payment reference not found', data: updated };
    }
    if (dto.amount && Number(payment.amount) !== Number(dto.amount)) {
      const updated = await this.db.paymentWebhook.update({ where: { id: webhook.id }, data: { status: 'FAILED', errorMessage: 'Payment amount mismatch' } });
      return { success: false, message: 'Payment amount mismatch', data: updated };
    }
    if (dto.currency && payment.currency !== dto.currency) {
      const updated = await this.db.paymentWebhook.update({ where: { id: webhook.id }, data: { status: 'FAILED', errorMessage: 'Payment currency mismatch' } });
      return { success: false, message: 'Payment currency mismatch', data: updated };
    }

    const result = await this.db.$transaction(async (tx: any) => {
      let updatedPayment = payment;
      if (isSuccess && !['CONFIRMED', 'PAID'].includes(payment.status)) updatedPayment = await this.confirmPayment(tx, payment, null, 'Confirmed by verified webhook', dto.providerReference);
      if (isFailed && !CLOSED_PAYMENT_STATUSES.includes(payment.status)) {
        updatedPayment = await tx.paymentTransaction.update({ where: { id: payment.id }, data: { status: 'FAILED', failedAt: new Date(), externalReference: dto.providerReference ?? payment.externalReference } });
        if (payment.orderId) await tx.order.update({ where: { id: payment.orderId }, data: { paymentStatus: 'FAILED' } });
      }
      await tx.paymentWebhook.update({ where: { id: webhook.id }, data: { status: 'PROCESSED', processedAt: new Date() } });
      return updatedPayment;
    });

    await this.audit.write({ action: 'payments.webhook.processed', entityType: 'payment', entityId: result.id, metadata: { provider: providerCode, webhook_id: webhook.id } }).catch(() => null);
    return { success: true, message: 'Webhook processed', data: result };
  }

  async createRefund(userId: number, dto: CreateRefundDto) {
    const payment = dto.paymentId
      ? await this.db.paymentTransaction.findUnique({ where: { id: dto.paymentId }, include: { order: true, serviceOrder: true, invoice: true } })
      : dto.orderId
        ? await this.db.paymentTransaction.findFirst({ where: { orderId: dto.orderId, status: { in: ['CONFIRMED', 'PAID'] } }, include: { order: true, serviceOrder: true, invoice: true }, orderBy: { createdAt: 'desc' } })
        : dto.serviceOrderId
          ? await this.db.paymentTransaction.findFirst({ where: { serviceOrderId: dto.serviceOrderId, status: { in: ['CONFIRMED', 'PAID'] } }, include: { order: true, serviceOrder: true, invoice: true }, orderBy: { createdAt: 'desc' } })
          : null;
    if (!payment) throw new NotFoundException({ message: 'Paid transaction not found', error_code: 'PAID_TRANSACTION_NOT_FOUND' });
    if (payment.payerUserId !== userId) throw new ForbiddenException({ message: 'لا يمكنك طلب استرداد لهذه العملية', error_code: 'REFUND_ACCESS_DENIED' });
    if (!['CONFIRMED', 'PAID'].includes(payment.status)) throw new BadRequestException({ message: 'لا يمكن طلب استرداد لدفع غير مؤكد', error_code: 'PAYMENT_NOT_CONFIRMED' });
    if (Number(dto.amount) > Number(payment.amount)) throw new BadRequestException({ message: 'مبلغ الاسترداد أكبر من مبلغ الدفع', error_code: 'REFUND_AMOUNT_EXCEEDED' });

    const data = await this.db.$transaction(async (tx: any) => tx.refundRequest.create({
      data: {
        refundNumber: await this.createUniqueReference(tx, 'REF', 'refundRequest'),
        paymentId: payment.id,
        invoiceId: payment.invoiceId,
        orderId: payment.orderId,
        serviceOrderId: payment.serviceOrderId,
        amount: dto.amount,
        currency: payment.currency,
        reason: dto.reason,
        status: 'REQUESTED',
        requestedByUserId: userId,
      },
    }));
    await this.audit.write({ actorUserId: userId, action: 'payments.refund.requested', entityType: 'refund', entityId: data.id, metadata: { payment_id: payment.id } }).catch(() => null);
    return { success: true, message: 'Refund requested', data };
  }

  async financeRefunds(params: { status?: string; take?: number; skip?: number }) {
    const take = Math.min(Math.max(params.take ?? 50, 1), 200);
    const data = await this.db.refundRequest.findMany({
      where: { status: params.status as any },
      include: { payment: true, order: true, serviceOrder: true, requestedBy: { select: { id: true, displayName: true, phoneNormalized: true, email: true } } },
      orderBy: { createdAt: 'desc' },
      take,
      skip: params.skip ?? 0,
    });
    return { success: true, data };
  }

  async approveRefund(userId: number, refundId: number, dto: ReviewRefundDto) {
    const refund = await this.db.refundRequest.findUnique({ where: { id: refundId }, include: { payment: true } });
    if (!refund) throw new NotFoundException({ message: 'Refund not found', error_code: 'REFUND_NOT_FOUND' });
    if (refund.status !== 'REQUESTED') throw new BadRequestException({ message: 'تمت مراجعة طلب الاسترداد مسبقاً', error_code: 'REFUND_ALREADY_REVIEWED' });
    const data = await this.db.refundRequest.update({ where: { id: refundId }, data: { status: 'APPROVED', approvedByUserId: userId, providerReference: dto.providerReference ?? null } });
    await this.audit.write({ actorUserId: userId, action: 'payments.refund.approved', entityType: 'refund', entityId: refundId, metadata: { payment_id: refund.paymentId } }).catch(() => null);
    if (refund.requestedByUserId) await this.notifications.createForUser(refund.requestedByUserId, 'تمت الموافقة على طلب الاسترداد', dto.note ?? 'سيتم معالجة الاسترداد من المالية.', { refund_id: refundId }).catch(() => null);
    return { success: true, message: 'Refund approved', data };
  }

  async rejectRefund(userId: number, refundId: number, dto: ReviewRefundDto) {
    const refund = await this.db.refundRequest.findUnique({ where: { id: refundId } });
    if (!refund) throw new NotFoundException({ message: 'Refund not found', error_code: 'REFUND_NOT_FOUND' });
    if (refund.status !== 'REQUESTED') throw new BadRequestException({ message: 'تمت مراجعة طلب الاسترداد مسبقاً', error_code: 'REFUND_ALREADY_REVIEWED' });
    const data = await this.db.refundRequest.update({ where: { id: refundId }, data: { status: 'REJECTED', approvedByUserId: userId } });
    await this.audit.write({ actorUserId: userId, action: 'payments.refund.rejected', entityType: 'refund', entityId: refundId, metadata: { note: dto.note ?? null } }).catch(() => null);
    if (refund.requestedByUserId) await this.notifications.createForUser(refund.requestedByUserId, 'تم رفض طلب الاسترداد', dto.note ?? 'تم رفض طلب الاسترداد.', { refund_id: refundId }).catch(() => null);
    return { success: true, message: 'Refund rejected', data };
  }

  async markRefunded(userId: number, refundId: number, dto: ReviewRefundDto) {
    const refund = await this.db.refundRequest.findUnique({ where: { id: refundId }, include: { payment: true } });
    if (!refund) throw new NotFoundException({ message: 'Refund not found', error_code: 'REFUND_NOT_FOUND' });
    if (!['APPROVED', 'PROCESSING'].includes(refund.status)) throw new BadRequestException({ message: 'طلب الاسترداد غير معتمد', error_code: 'REFUND_NOT_APPROVED' });
    const data = await this.db.$transaction(async (tx: any) => {
      const updatedRefund = await tx.refundRequest.update({ where: { id: refundId }, data: { status: 'REFUNDED', processedAt: new Date(), providerReference: dto.providerReference ?? refund.providerReference } });
      await tx.paymentTransaction.update({ where: { id: refund.paymentId }, data: { status: Number(refund.amount) >= Number(refund.payment.amount) ? 'REFUNDED' : 'PARTIALLY_REFUNDED' } }).catch(() => null);
      if (refund.invoiceId) await tx.invoice.update({ where: { id: refund.invoiceId }, data: { status: 'REFUNDED' } }).catch(() => null);
      if (refund.orderId) await tx.order.update({ where: { id: refund.orderId }, data: { paymentStatus: Number(refund.amount) >= Number(refund.payment.amount) ? 'REFUNDED' : 'PARTIALLY_REFUNDED' } }).catch(() => null);
      await this.accounting.postRefundCompleted(tx, { ...updatedRefund, payment: refund.payment }, userId);
      return updatedRefund;
    });
    await this.audit.write({ actorUserId: userId, action: 'payments.refund.completed', entityType: 'refund', entityId: refundId }).catch(() => null);
    if (refund.requestedByUserId) await this.notifications.createForUser(refund.requestedByUserId, 'تم تنفيذ الاسترداد', 'تم تنفيذ عملية الاسترداد بنجاح.', { refund_id: refundId }).catch(() => null);
    return { success: true, message: 'Refund completed', data };
  }

  async settlements(params: { status?: string; organizationId?: number; take?: number; skip?: number }) {
    const take = Math.min(Math.max(params.take ?? 50, 1), 200);
    const data = await this.db.settlement.findMany({
      where: { status: params.status as any, organizationId: params.organizationId },
      include: { organization: true, approvedBy: { select: { id: true, displayName: true, email: true } } },
      orderBy: { createdAt: 'desc' },
      take,
      skip: params.skip ?? 0,
    });
    return { success: true, data };
  }

  async createSettlement(userId: number, dto: CreateSettlementDto) {
    const organization = await this.db.organization.findUnique({ where: { id: dto.organizationId } });
    if (!organization) throw new NotFoundException({ message: 'Organization not found', error_code: 'ORGANIZATION_NOT_FOUND' });
    const balance = await this.db.merchantBalance.findUnique({ where: { organizationId: dto.organizationId } }).catch(() => null);
    const payable = Number(balance?.availableBalance ?? 0) + Number(balance?.pendingBalance ?? 0);
    if (payable < Number(dto.amount)) {
      throw new BadRequestException({ message: 'رصيد المؤسسة غير كافٍ لإنشاء التسوية', error_code: 'INSUFFICIENT_MERCHANT_BALANCE' });
    }
    const data = await this.db.$transaction(async (tx: any) => tx.settlement.create({
      data: {
        settlementNumber: await this.createUniqueReference(tx, 'SET', 'settlement'),
        organizationId: dto.organizationId,
        amount: dto.amount,
        currency: dto.currency ?? 'YER',
        periodStart: new Date(dto.periodStart),
        periodEnd: new Date(dto.periodEnd),
        notes: dto.notes ?? null,
        status: 'PENDING',
      },
    }));
    await this.audit.write({ actorUserId: userId, action: 'payments.settlement.created', entityType: 'settlement', entityId: data.id, metadata: { organization_id: dto.organizationId } }).catch(() => null);
    return { success: true, message: 'Settlement created', data };
  }

  async approveSettlement(userId: number, settlementId: number) {
    const settlement = await this.db.settlement.findUnique({ where: { id: settlementId } });
    if (!settlement) throw new NotFoundException({ message: 'Settlement not found', error_code: 'SETTLEMENT_NOT_FOUND' });
    if (settlement.status !== 'PENDING') throw new BadRequestException({ message: 'لا يمكن اعتماد هذه التسوية', error_code: 'SETTLEMENT_NOT_PENDING' });
    const data = await this.db.settlement.update({ where: { id: settlementId }, data: { status: 'APPROVED', approvedByUserId: userId } });
    await this.audit.write({ actorUserId: userId, action: 'payments.settlement.approved', entityType: 'settlement', entityId: settlementId }).catch(() => null);
    return { success: true, message: 'Settlement approved', data };
  }

  async markSettlementPaid(userId: number, settlementId: number) {
    const settlement = await this.db.settlement.findUnique({ where: { id: settlementId } });
    if (!settlement) throw new NotFoundException({ message: 'Settlement not found', error_code: 'SETTLEMENT_NOT_FOUND' });
    if (!['APPROVED', 'PENDING'].includes(settlement.status)) throw new BadRequestException({ message: 'لا يمكن تعليم هذه التسوية كمدفوعة', error_code: 'SETTLEMENT_NOT_PAYABLE' });
    const data = await this.db.$transaction(async (tx: any) => {
      const updated = await tx.settlement.update({ where: { id: settlementId }, data: { status: 'PAID', paidAt: new Date(), approvedByUserId: settlement.approvedByUserId ?? userId } });
      await this.accounting.postSettlementPaid(tx, updated, userId);
      return updated;
    });
    await this.audit.write({ actorUserId: userId, action: 'payments.settlement.paid', entityType: 'settlement', entityId: settlementId }).catch(() => null);
    return { success: true, message: 'Settlement marked as paid', data };
  }
}
