import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { EventBusService } from '../../common/events/event-bus.service';
import { PrismaService } from '../../prisma/prisma.service';
import { AuditService } from '../audit/audit.service';

const DEFAULT_ACCOUNTS = [
  { code: '1000', nameAr: 'النقدية', nameEn: 'Cash', accountType: 'ASSET', normalBalance: 'DEBIT' },
  { code: '1010', nameAr: 'الحسابات البنكية', nameEn: 'Bank Accounts', accountType: 'ASSET', normalBalance: 'DEBIT' },
  { code: '1100', nameAr: 'الذمم المدينة', nameEn: 'Accounts Receivable', accountType: 'ASSET', normalBalance: 'DEBIT' },
  { code: '1200', nameAr: 'أصول المحافظ', nameEn: 'Wallet Assets', accountType: 'ASSET', normalBalance: 'DEBIT' },
  { code: '2000', nameAr: 'مستحقات التجار والورش', nameEn: 'Merchant and Workshop Payables', accountType: 'LIABILITY', normalBalance: 'CREDIT' },
  { code: '2100', nameAr: 'التزامات محافظ العملاء', nameEn: 'Customer Wallet Liabilities', accountType: 'LIABILITY', normalBalance: 'CREDIT' },
  { code: '2200', nameAr: 'التزامات الاسترداد', nameEn: 'Refunds Payable', accountType: 'LIABILITY', normalBalance: 'CREDIT' },
  { code: '4000', nameAr: 'إيرادات السوق', nameEn: 'Marketplace Revenue', accountType: 'REVENUE', normalBalance: 'CREDIT' },
  { code: '4100', nameAr: 'إيرادات الخدمات', nameEn: 'Service Revenue', accountType: 'REVENUE', normalBalance: 'CREDIT' },
  { code: '4200', nameAr: 'إيرادات التوصيل', nameEn: 'Delivery Revenue', accountType: 'REVENUE', normalBalance: 'CREDIT' },
  { code: '5000', nameAr: 'مصروفات الاسترداد', nameEn: 'Refund Expenses', accountType: 'EXPENSE', normalBalance: 'DEBIT' },
  { code: '5100', nameAr: 'مصروفات تشغيلية', nameEn: 'Operational Expenses', accountType: 'EXPENSE', normalBalance: 'DEBIT' },
];

const ACCOUNT_CODES = {
  cash: '1000',
  bank: '1010',
  receivable: '1100',
  walletAsset: '1200',
  merchantPayable: '2000',
  refundPayable: '2200',
  refundExpense: '5000',
};

type JournalLineInput = {
  accountCode: string;
  debit?: number;
  credit?: number;
  memo?: string;
  organizationId?: number | null;
  orderId?: number | null;
  invoiceId?: number | null;
  paymentId?: number | null;
  refundId?: number | null;
  settlementId?: number | null;
};

type PostJournalInput = {
  idempotencyKey: string;
  sourceType: string;
  sourceId?: number | null;
  sourcePublicId?: string | null;
  description?: string;
  currency?: string;
  actorUserId?: number | null;
  lines: JournalLineInput[];
};

@Injectable()
export class AccountingService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    private readonly events: EventBusService,
  ) {}

  private get db() { return this.prisma as any; }

  private round(value: number) {
    return Math.round((Number(value || 0) + Number.EPSILON) * 100) / 100;
  }

  private assertPositiveAmount(value: number, errorCode: string, message: string) {
    const amount = this.round(Number(value));
    if (!Number.isFinite(amount) || amount <= 0) {
      throw new BadRequestException({ message, error_code: errorCode });
    }
    return amount;
  }

  private normalizeCurrency(value?: string | null) {
    const currency = (value || 'YER').trim().toUpperCase();
    if (!/^[A-Z]{3}$/.test(currency)) {
      throw new BadRequestException({ message: 'رمز العملة غير صالح', error_code: 'INVALID_CURRENCY' });
    }
    return currency;
  }

  private cashAccountForProvider(provider?: string | null) {
    if (provider === 'BANK_TRANSFER') return ACCOUNT_CODES.bank;
    if (provider === 'WALLET' || provider === 'LOCAL_WALLET') return ACCOUNT_CODES.walletAsset;
    return ACCOUNT_CODES.cash;
  }

  private makeReference(prefix: string) {
    const d = new Date();
    const date = `${d.getFullYear()}${String(d.getMonth() + 1).padStart(2, '0')}${String(d.getDate()).padStart(2, '0')}`;
    return `${prefix}-${date}-${Math.floor(100000 + Math.random() * 900000)}`;
  }

  private async uniqueNumber(tx: any, model: 'journalEntry' | 'financialTransaction', prefix: string) {
    const field = model === 'journalEntry' ? 'entryNumber' : 'transactionNumber';
    for (let i = 0; i < 5; i += 1) {
      const value = this.makeReference(prefix);
      const exists = await tx[model].findFirst({ where: { [field]: value } });
      if (!exists) return value;
    }
    throw new BadRequestException({ message: 'تعذر توليد رقم محاسبي فريد', error_code: 'ACCOUNTING_NUMBER_GENERATION_FAILED' });
  }

  async initializeChartOfAccounts(actorUserId?: number) {
    const data = await this.db.$transaction(async (tx: any) => {
      const created: any[] = [];
      for (const account of DEFAULT_ACCOUNTS) {
        const item = await tx.ledgerAccount.upsert({
          where: { code: account.code },
          update: { nameAr: account.nameAr, nameEn: account.nameEn, accountType: account.accountType, normalBalance: account.normalBalance, isSystem: true, isActive: true },
          create: { ...account, isSystem: true, isActive: true },
        });
        created.push(item);
      }
      return created;
    });
    await this.audit.write({ actorUserId: actorUserId ?? null, action: 'accounting.chart.initialized', entityType: 'ledger_account', entityId: 'system', metadata: { accounts: data.length } }).catch(() => null);
    return { success: true, message: 'Chart of accounts initialized', data };
  }

  private async accountByCode(tx: any, code: string) {
    let account = await tx.ledgerAccount.findUnique({ where: { code } });
    if (!account) {
      const seed = DEFAULT_ACCOUNTS.find((item) => item.code === code);
      if (!seed) throw new BadRequestException({ message: `الحساب المحاسبي غير موجود: ${code}`, error_code: 'LEDGER_ACCOUNT_NOT_FOUND' });
      account = await tx.ledgerAccount.create({ data: { ...seed, isSystem: true, isActive: true } });
    }
    return account;
  }

  private async postJournal(tx: any, input: PostJournalInput) {
    const existing = await tx.journalEntry.findUnique({ where: { idempotencyKey: input.idempotencyKey }, include: { lines: true } }).catch(() => null);
    if (existing) return { created: false, entry: existing };

    if (!input.lines || input.lines.length < 2) {
      throw new BadRequestException({ message: 'القيد المحاسبي يحتاج طرفين على الأقل', error_code: 'JOURNAL_LINES_REQUIRED' });
    }

    const debit = this.round(input.lines.reduce((sum, line) => sum + Number(line.debit ?? 0), 0));
    const credit = this.round(input.lines.reduce((sum, line) => sum + Number(line.credit ?? 0), 0));
    if (debit <= 0 || credit <= 0 || debit !== credit) {
      throw new BadRequestException({ message: 'القيد المحاسبي غير متوازن', error_code: 'UNBALANCED_JOURNAL_ENTRY', debit, credit });
    }

    const currency = this.normalizeCurrency(input.currency);
    const lineCreates: any[] = [];
    for (const line of input.lines) {
      const lineDebit = this.round(Number(line.debit ?? 0));
      const lineCredit = this.round(Number(line.credit ?? 0));
      if (lineDebit < 0 || lineCredit < 0) {
        throw new BadRequestException({ message: 'لا يسمح بقيم سالبة داخل القيد المحاسبي', error_code: 'NEGATIVE_JOURNAL_LINE' });
      }
      if ((lineDebit > 0 && lineCredit > 0) || (lineDebit === 0 && lineCredit === 0)) {
        throw new BadRequestException({ message: 'كل سطر محاسبي يجب أن يكون مدينًا أو دائنًا فقط', error_code: 'INVALID_JOURNAL_LINE_SIDE' });
      }
      const account = await this.accountByCode(tx, line.accountCode);
      if (!account.isActive) {
        throw new BadRequestException({ message: `الحساب المحاسبي غير نشط: ${line.accountCode}`, error_code: 'LEDGER_ACCOUNT_INACTIVE' });
      }
      lineCreates.push({
        accountId: account.id,
        organizationId: line.organizationId ?? null,
        orderId: line.orderId ?? null,
        invoiceId: line.invoiceId ?? null,
        paymentId: line.paymentId ?? null,
        refundId: line.refundId ?? null,
        settlementId: line.settlementId ?? null,
        debitAmount: lineDebit,
        creditAmount: lineCredit,
        memo: line.memo ?? null,
      });
    }

    const entry = await tx.journalEntry.create({
      data: {
        entryNumber: await this.uniqueNumber(tx, 'journalEntry', 'JE'),
        sourceType: input.sourceType,
        sourceId: input.sourceId ?? null,
        sourcePublicId: input.sourcePublicId ?? null,
        idempotencyKey: input.idempotencyKey,
        description: input.description ?? null,
        currency,
        totalDebit: debit,
        totalCredit: credit,
        postedByUserId: input.actorUserId ?? null,
        lines: { create: lineCreates },
      },
      include: { lines: true },
    });

    return { created: true, entry };
  }

  private async createFinancialTransaction(tx: any, params: {
    journalEntryId: number;
    idempotencyKey: string;
    sourceType: string;
    sourceId?: number | null;
    direction: string;
    amount: number;
    currency?: string;
    organizationId?: number | null;
    customerId?: number | null;
    orderId?: number | null;
    invoiceId?: number | null;
    paymentId?: number | null;
    refundId?: number | null;
    settlementId?: number | null;
    description?: string | null;
  }) {
    const existing = await tx.financialTransaction.findUnique({ where: { idempotencyKey: params.idempotencyKey } }).catch(() => null);
    if (existing) return existing;
    const amount = this.assertPositiveAmount(params.amount, 'INVALID_FINANCIAL_TRANSACTION_AMOUNT', 'مبلغ الحركة المالية غير صالح');
    const currency = this.normalizeCurrency(params.currency);
    return tx.financialTransaction.create({
      data: {
        transactionNumber: await this.uniqueNumber(tx, 'financialTransaction', 'FT'),
        journalEntryId: params.journalEntryId,
        sourceType: params.sourceType,
        sourceId: params.sourceId ?? null,
        idempotencyKey: params.idempotencyKey,
        direction: params.direction,
        amount,
        currency,
        organizationId: params.organizationId ?? null,
        customerId: params.customerId ?? null,
        orderId: params.orderId ?? null,
        invoiceId: params.invoiceId ?? null,
        paymentId: params.paymentId ?? null,
        refundId: params.refundId ?? null,
        settlementId: params.settlementId ?? null,
        description: params.description ?? null,
      },
    });
  }

  private async incrementMerchantBalance(tx: any, organizationId: number, currency: string, data: Record<string, any>) {
    const existing = await tx.merchantBalance.findUnique({ where: { organizationId } }).catch(() => null);
    currency = this.normalizeCurrency(currency);
    if (!existing) {
      return tx.merchantBalance.create({
        data: {
          organizationId,
          currency,
          pendingBalance: data.pendingBalance?.increment ?? 0,
          availableBalance: data.availableBalance?.increment ?? 0,
          settledBalance: data.settledBalance?.increment ?? 0,
          lifetimeGross: data.lifetimeGross?.increment ?? 0,
          lifetimeRefunded: data.lifetimeRefunded?.increment ?? 0,
          lifetimeSettled: data.lifetimeSettled?.increment ?? 0,
        },
      });
    }
    if (existing.currency !== currency) {
      throw new BadRequestException({ message: 'عملة رصيد المؤسسة لا تطابق عملة العملية', error_code: 'MERCHANT_BALANCE_CURRENCY_MISMATCH' });
    }
    return tx.merchantBalance.update({ where: { organizationId }, data: { ...data, version: { increment: 1 } } });
  }

  private async debitMerchantBalance(
    tx: any,
    organizationId: number,
    currency: string,
    amount: number,
    options: { preferredBucket: 'pending' | 'available'; incrementRefunded?: boolean; incrementSettled?: boolean }
  ) {
    amount = this.assertPositiveAmount(amount, 'INVALID_MERCHANT_BALANCE_DEBIT_AMOUNT', 'مبلغ خصم رصيد المؤسسة غير صالح');
    currency = this.normalizeCurrency(currency);
    const balance = await tx.merchantBalance.findUnique({ where: { organizationId } }).catch(() => null);
    const pending = this.round(Number(balance?.pendingBalance ?? 0));
    const available = this.round(Number(balance?.availableBalance ?? 0));
    if (balance && balance.currency !== currency) {
      throw new BadRequestException({ message: 'عملة رصيد المؤسسة لا تطابق عملة العملية', error_code: 'MERCHANT_BALANCE_CURRENCY_MISMATCH' });
    }
    if (!balance || this.round(pending + available) < amount) {
      throw new BadRequestException({ message: 'رصيد المؤسسة غير كافٍ للعملية المحاسبية', error_code: 'INSUFFICIENT_MERCHANT_BALANCE' });
    }
    const firstKey = options.preferredBucket === 'available' ? 'availableBalance' : 'pendingBalance';
    const secondKey = firstKey === 'availableBalance' ? 'pendingBalance' : 'availableBalance';
    const firstValue = firstKey === 'availableBalance' ? available : pending;
    const update: any = {};
    if (firstValue >= amount) {
      update[firstKey] = { decrement: amount };
    } else {
      if (firstValue > 0) update[firstKey] = { decrement: firstValue };
      update[secondKey] = { decrement: this.round(amount - firstValue) };
    }
    if (options.incrementRefunded) update.lifetimeRefunded = { increment: amount };
    if (options.incrementSettled) {
      update.settledBalance = { increment: amount };
      update.lifetimeSettled = { increment: amount };
    }
    return this.incrementMerchantBalance(tx, organizationId, currency, update);
  }

  async postPaymentConfirmed(tx: any, payment: any, actorUserId?: number | null) {
    const amount = this.assertPositiveAmount(Number(payment.amount), 'INVALID_ACCOUNTING_AMOUNT', 'مبلغ الدفع غير صالح للمحاسبة');
    const paymentId = Number(payment.id);
    const organizationId = payment.organizationId ?? payment.order?.organizationId ?? payment.serviceOrder?.organizationId ?? null;
    const currency = this.normalizeCurrency(payment.currency);
    const cashAccount = this.cashAccountForProvider(payment.provider);
    const sourceType = payment.provider === 'CASH' && payment.method === 'CASH_ON_DELIVERY' ? 'COD_DELIVERED' : 'PAYMENT_CONFIRMED';
    const result = await this.postJournal(tx, {
      idempotencyKey: `acct:payment-confirmed:${paymentId}`,
      sourceType,
      sourceId: paymentId,
      sourcePublicId: payment.publicId ?? payment.internalReference ?? null,
      description: `Payment confirmed ${payment.internalReference ?? paymentId}`,
      currency,
      actorUserId: actorUserId ?? payment.approvedByUserId ?? null,
      lines: [
        { accountCode: cashAccount, debit: amount, memo: 'Payment received', organizationId, orderId: payment.orderId, invoiceId: payment.invoiceId, paymentId },
        { accountCode: ACCOUNT_CODES.merchantPayable, credit: amount, memo: 'Amount payable to merchant/workshop', organizationId, orderId: payment.orderId, invoiceId: payment.invoiceId, paymentId },
      ],
    });
    if (result.created) {
      await this.createFinancialTransaction(tx, {
        journalEntryId: result.entry.id,
        idempotencyKey: `ft:payment-confirmed:${paymentId}`,
        sourceType,
        sourceId: paymentId,
        direction: 'INFLOW',
        amount,
        currency,
        organizationId,
        customerId: payment.payerUserId ?? null,
        orderId: payment.orderId ?? null,
        invoiceId: payment.invoiceId ?? null,
        paymentId,
        description: 'Payment confirmed and posted to ledger',
      });
      if (organizationId) await this.incrementMerchantBalance(tx, organizationId, currency, { pendingBalance: { increment: amount }, lifetimeGross: { increment: amount } });
    }
    return result.entry;
  }

  async postCodDeliveredForOrder(tx: any, order: any, actorUserId?: number | null) {
    if (!order || !order.id) return null;
    const existingPayment = await tx.paymentTransaction.findFirst({ where: { orderId: order.id, provider: 'CASH', status: { in: ['PENDING_COD', 'INITIATED', 'WAITING_PROOF'] } }, orderBy: { id: 'desc' } }).catch(() => null);
    let payment = existingPayment;
    const invoice = await tx.invoice.findFirst({ where: { orderId: order.id }, orderBy: { id: 'asc' } }).catch(() => null);
    if (payment) {
      payment = await tx.paymentTransaction.update({ where: { id: payment.id }, data: { status: 'CONFIRMED', paidAt: new Date(), reviewedAt: new Date(), approvedByUserId: actorUserId ?? null } });
    } else {
      payment = await tx.paymentTransaction.create({
        data: {
          invoiceId: invoice?.id ?? null,
          orderId: order.id,
          payerUserId: order.userId,
          organizationId: order.organizationId,
          type: 'ORDER_PAYMENT',
          provider: 'CASH',
          method: order.paymentMethod ?? 'CASH_ON_DELIVERY',
          status: 'CONFIRMED',
          amount: order.totalAmount,
          currency: order.currency ?? 'YER',
          internalReference: this.makeReference('COD'),
          paidAt: new Date(),
          approvedByUserId: actorUserId ?? null,
        },
      });
    }
    if (invoice?.id) await tx.invoice.update({ where: { id: invoice.id }, data: { status: 'PAID', paidAt: new Date() } }).catch(() => null);
    await tx.order.update({ where: { id: order.id }, data: { paymentStatus: 'PAID' } }).catch(() => null);
    return this.postPaymentConfirmed(tx, payment, actorUserId ?? null);
  }

  async postRefundCompleted(tx: any, refund: any, actorUserId?: number | null) {
    const amount = this.assertPositiveAmount(Number(refund.amount), 'INVALID_REFUND_AMOUNT', 'مبلغ الاسترداد غير صالح');
    const organizationId = refund.payment?.organizationId ?? refund.order?.organizationId ?? refund.serviceOrder?.organizationId ?? null;
    const currency = this.normalizeCurrency(refund.currency ?? refund.payment?.currency);
    const refundAssetAccount = this.cashAccountForProvider(refund.payment?.provider);
    const result = await this.postJournal(tx, {
      idempotencyKey: `acct:refund-completed:${refund.id}`,
      sourceType: 'REFUND_COMPLETED',
      sourceId: refund.id,
      sourcePublicId: refund.publicId ?? refund.refundNumber ?? null,
      description: `Refund completed ${refund.refundNumber ?? refund.id}`,
      currency,
      actorUserId: actorUserId ?? refund.approvedByUserId ?? null,
      lines: [
        { accountCode: ACCOUNT_CODES.merchantPayable, debit: amount, memo: 'Reduce merchant payable for refund', organizationId, orderId: refund.orderId, invoiceId: refund.invoiceId, paymentId: refund.paymentId, refundId: refund.id },
        { accountCode: refundAssetAccount, credit: amount, memo: 'Cash paid back to customer', organizationId, orderId: refund.orderId, invoiceId: refund.invoiceId, paymentId: refund.paymentId, refundId: refund.id },
      ],
    });
    if (result.created) {
      await this.createFinancialTransaction(tx, {
        journalEntryId: result.entry.id,
        idempotencyKey: `ft:refund-completed:${refund.id}`,
        sourceType: 'REFUND_COMPLETED',
        sourceId: refund.id,
        direction: 'OUTFLOW',
        amount,
        currency,
        organizationId,
        customerId: refund.requestedByUserId ?? null,
        orderId: refund.orderId ?? null,
        invoiceId: refund.invoiceId ?? null,
        paymentId: refund.paymentId ?? null,
        refundId: refund.id,
        description: 'Refund completed and posted to ledger',
      });
      await tx.refundEntry.create({ data: { refundId: refund.id, journalEntryId: result.entry.id, amount, currency } }).catch(() => null);
      if (organizationId) await this.debitMerchantBalance(tx, organizationId, currency, amount, { preferredBucket: 'pending', incrementRefunded: true });
    }
    return result.entry;
  }

  async postSettlementPaid(tx: any, settlement: any, actorUserId?: number | null) {
    const amount = this.assertPositiveAmount(Number(settlement.amount), 'INVALID_SETTLEMENT_AMOUNT', 'مبلغ التسوية غير صالح');
    const organizationId = settlement.organizationId;
    const currency = this.normalizeCurrency(settlement.currency);
    const result = await this.postJournal(tx, {
      idempotencyKey: `acct:settlement-paid:${settlement.id}`,
      sourceType: 'SETTLEMENT_PAID',
      sourceId: settlement.id,
      sourcePublicId: settlement.publicId ?? settlement.settlementNumber ?? null,
      description: `Settlement paid ${settlement.settlementNumber ?? settlement.id}`,
      currency,
      actorUserId: actorUserId ?? settlement.approvedByUserId ?? null,
      lines: [
        { accountCode: ACCOUNT_CODES.merchantPayable, debit: amount, memo: 'Pay merchant/workshop liability', organizationId, settlementId: settlement.id },
        { accountCode: ACCOUNT_CODES.bank, credit: amount, memo: 'Bank payment to merchant/workshop', organizationId, settlementId: settlement.id },
      ],
    });
    if (result.created) {
      await this.createFinancialTransaction(tx, {
        journalEntryId: result.entry.id,
        idempotencyKey: `ft:settlement-paid:${settlement.id}`,
        sourceType: 'SETTLEMENT_PAID',
        sourceId: settlement.id,
        direction: 'OUTFLOW',
        amount,
        currency,
        organizationId,
        settlementId: settlement.id,
        description: 'Settlement paid and posted to ledger',
      });
      if (organizationId) await this.debitMerchantBalance(tx, organizationId, currency, amount, { preferredBucket: 'available', incrementSettled: true });
    }
    return result.entry;
  }

  async listAccounts() {
    const data = await this.db.ledgerAccount.findMany({ orderBy: [{ code: 'asc' }] });
    return { success: true, data };
  }

  async journalEntries(params: { status?: string; sourceType?: string; take?: number; skip?: number }) {
    const take = Math.min(Math.max(params.take ?? 50, 1), 200);
    const data = await this.db.journalEntry.findMany({
      where: { status: params.status as any, sourceType: params.sourceType as any },
      include: { postedBy: { select: { id: true, displayName: true, email: true } }, lines: { include: { account: true, organization: true }, take: 20 } },
      orderBy: { entryDate: 'desc' },
      take,
      skip: params.skip ?? 0,
    });
    return { success: true, data };
  }

  async journalEntryDetails(id: number) {
    const data = await this.db.journalEntry.findUnique({
      where: { id },
      include: { postedBy: { select: { id: true, displayName: true, email: true } }, lines: { include: { account: true, organization: true, order: true, invoice: true, payment: true, refund: true, settlement: true } }, financialTransactions: true },
    });
    if (!data) throw new NotFoundException({ message: 'Journal entry not found', error_code: 'JOURNAL_ENTRY_NOT_FOUND' });
    return { success: true, data };
  }

  async accountLedger(accountId: number, params: { take?: number; skip?: number }) {
    const account = await this.db.ledgerAccount.findUnique({ where: { id: accountId } });
    if (!account) throw new NotFoundException({ message: 'Ledger account not found', error_code: 'LEDGER_ACCOUNT_NOT_FOUND' });
    const take = Math.min(Math.max(params.take ?? 100, 1), 300);
    const lines = await this.db.journalEntryLine.findMany({
      where: { accountId },
      include: { entry: true, organization: true },
      orderBy: { createdAt: 'desc' },
      take,
      skip: params.skip ?? 0,
    });
    return { success: true, data: { account, lines } };
  }

  async financialTransactions(params: { organizationId?: number; take?: number; skip?: number }) {
    const take = Math.min(Math.max(params.take ?? 50, 1), 200);
    const data = await this.db.financialTransaction.findMany({
      where: { organizationId: params.organizationId },
      include: { organization: true, customer: { select: { id: true, displayName: true, email: true } }, journalEntry: true },
      orderBy: { createdAt: 'desc' },
      take,
      skip: params.skip ?? 0,
    });
    return { success: true, data };
  }

  async merchantBalances(params: { organizationId?: number; take?: number; skip?: number }) {
    const take = Math.min(Math.max(params.take ?? 50, 1), 200);
    const data = await this.db.merchantBalance.findMany({
      where: { organizationId: params.organizationId },
      include: { organization: true },
      orderBy: { updatedAt: 'desc' },
      take,
      skip: params.skip ?? 0,
    });
    return { success: true, data };
  }
}
