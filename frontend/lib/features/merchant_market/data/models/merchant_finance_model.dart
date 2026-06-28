class MerchantFinanceSummary {
  const MerchantFinanceSummary({
    required this.availableBalance,
    required this.pendingBalance,
    required this.totalSales,
    required this.totalCommission,
    required this.netEarnings,
    required this.withdrawableBalance,
    required this.invoiceCount,
    required this.invoiceTotal,
    required this.paymentStatuses,
    required this.settlementStatuses,
    required this.wallets,
    required this.recentPayments,
    required this.recentSettlements,
    required this.recentInvoices,
    required this.ledger,
    required this.currency,
  });

  final num availableBalance;
  final num pendingBalance;
  final num totalSales;
  final num totalCommission;
  final num netEarnings;
  final num withdrawableBalance;
  final num invoiceCount;
  final num invoiceTotal;
  final List<MerchantFinanceStatusAggregate> paymentStatuses;
  final List<MerchantFinanceStatusAggregate> settlementStatuses;
  final List<MerchantWallet> wallets;
  final List<MerchantPayment> recentPayments;
  final List<MerchantSettlement> recentSettlements;
  final List<MerchantInvoice> recentInvoices;
  final List<MerchantLedgerEntry> ledger;
  final String currency;

  factory MerchantFinanceSummary.fromMap(Map<String, dynamic> map) {
    final balances = _asMap(map['balances']);
    final sales = _asMap(map['sales']);
    final invoices = _asMap(map['invoices']);
    return MerchantFinanceSummary(
      availableBalance:
          _num(balances['available_balance'] ?? balances['availableBalance']),
      pendingBalance:
          _num(balances['pending_balance'] ?? balances['pendingBalance']),
      totalSales: _num(
          sales['total_sales'] ?? sales['totalSales'] ?? invoices['total']),
      totalCommission:
          _num(sales['platform_commission'] ?? sales['platformCommission']),
      netEarnings: _num(sales['net_earnings'] ?? sales['netEarnings']),
      withdrawableBalance: _num(balances['withdrawable_balance'] ??
          balances['withdrawableBalance'] ??
          balances['available_balance']),
      invoiceCount: _num(invoices['count']),
      invoiceTotal: _num(invoices['total']),
      paymentStatuses: _list(map['payments'])
          .map(MerchantFinanceStatusAggregate.fromMap)
          .toList(),
      settlementStatuses: _list(map['settlements'])
          .map(MerchantFinanceStatusAggregate.fromMap)
          .toList(),
      wallets: _list(map['wallets']).map(MerchantWallet.fromMap).toList(),
      recentPayments: _list(map['recentPayments'] ?? map['recent_payments'])
          .map(MerchantPayment.fromMap)
          .toList(),
      recentSettlements:
          _list(map['recentSettlements'] ?? map['recent_settlements'])
              .map(MerchantSettlement.fromMap)
              .toList(),
      recentInvoices: _list(map['recentInvoices'] ?? map['recent_invoices'])
          .map(MerchantInvoice.fromMap)
          .toList(),
      ledger: _list(map['ledger']).map(MerchantLedgerEntry.fromMap).toList(),
      currency: (balances['currency'] ?? map['currency'] ?? 'YER').toString(),
    );
  }
}

class MerchantFinanceStatusAggregate {
  const MerchantFinanceStatusAggregate(
      {required this.status, required this.count, required this.total});
  final String status;
  final int count;
  final num total;
  factory MerchantFinanceStatusAggregate.fromMap(Map<String, dynamic> map) =>
      MerchantFinanceStatusAggregate(
          status: _str(map['status']),
          count: _num(map['count']).toInt(),
          total: _num(map['total']));
}

class MerchantWallet {
  const MerchantWallet(
      {required this.id,
      required this.organizationName,
      required this.currency,
      required this.balance,
      required this.availableBalance,
      required this.pendingBalance,
      required this.status,
      required this.updatedAt});
  final String id;
  final String organizationName;
  final String currency;
  final num balance;
  final num availableBalance;
  final num pendingBalance;
  final String status;
  final String updatedAt;
  factory MerchantWallet.fromMap(Map<String, dynamic> map) => MerchantWallet(
        id: _str(map['publicId'] ?? map['id']),
        organizationName: _str(
            map['organization_name'] ?? map['organizationName'],
            fallback: 'محفظة المتجر'),
        currency: _str(map['currency'], fallback: 'YER'),
        balance: _num(map['balance']),
        availableBalance: _num(map['available_balance'] ??
            map['availableBalance'] ??
            map['balance']),
        pendingBalance: _num(map['pending_balance'] ?? map['pendingBalance']),
        status: _str(map['status']),
        updatedAt: _str(map['updated_at'] ?? map['updatedAt']),
      );
}

class MerchantPayment {
  const MerchantPayment(
      {required this.id,
      required this.amount,
      required this.currency,
      required this.status,
      required this.orderNumber,
      required this.customerName,
      required this.providerCode,
      required this.providerReference,
      required this.createdAt,
      required this.confirmedAt});
  final String id;
  final num amount;
  final String currency;
  final String status;
  final String orderNumber;
  final String customerName;
  final String providerCode;
  final String providerReference;
  final String createdAt;
  final String confirmedAt;
  factory MerchantPayment.fromMap(Map<String, dynamic> map) => MerchantPayment(
        id: _str(map['publicId'] ?? map['id']),
        amount: _num(map['amount']),
        currency: _str(map['currency'], fallback: 'YER'),
        status: _str(map['status']),
        orderNumber: _str(map['order_number'] ?? map['orderNumber']),
        customerName: _str(map['customer_name'] ?? map['customerName']),
        providerCode: _str(map['provider_code'] ?? map['providerCode']),
        providerReference:
            _str(map['provider_reference'] ?? map['providerReference']),
        createdAt: _str(map['created_at'] ?? map['createdAt']),
        confirmedAt: _str(map['confirmed_at'] ?? map['confirmedAt']),
      );
}

class MerchantSettlement {
  const MerchantSettlement(
      {required this.id,
      required this.organizationName,
      required this.amount,
      required this.currency,
      required this.status,
      required this.periodStart,
      required this.periodEnd,
      required this.createdAt,
      required this.paidAt});
  final String id;
  final String organizationName;
  final num amount;
  final String currency;
  final String status;
  final String periodStart;
  final String periodEnd;
  final String createdAt;
  final String paidAt;
  factory MerchantSettlement.fromMap(Map<String, dynamic> map) =>
      MerchantSettlement(
        id: _str(map['publicId'] ?? map['id']),
        organizationName:
            _str(map['organization_name'] ?? map['organizationName']),
        amount: _num(map['amount']),
        currency: _str(map['currency'], fallback: 'YER'),
        status: _str(map['status']),
        periodStart: _str(map['period_start'] ?? map['periodStart']),
        periodEnd: _str(map['period_end'] ?? map['periodEnd']),
        createdAt: _str(map['created_at'] ?? map['createdAt']),
        paidAt: _str(map['paid_at'] ?? map['paidAt']),
      );
}

class MerchantInvoice {
  const MerchantInvoice(
      {required this.id,
      required this.invoiceNumber,
      required this.orderNumber,
      required this.customerName,
      required this.status,
      required this.subtotalAmount,
      required this.discountAmount,
      required this.taxAmount,
      required this.totalAmount,
      required this.currency,
      required this.issuedAt,
      required this.createdAt});
  final String id;
  final String invoiceNumber;
  final String orderNumber;
  final String customerName;
  final String status;
  final num subtotalAmount;
  final num discountAmount;
  final num taxAmount;
  final num totalAmount;
  final String currency;
  final String issuedAt;
  final String createdAt;
  factory MerchantInvoice.fromMap(Map<String, dynamic> map) => MerchantInvoice(
        id: _str(map['publicId'] ?? map['id']),
        invoiceNumber: _str(map['invoice_number'] ?? map['invoiceNumber'],
            fallback: 'فاتورة'),
        orderNumber: _str(map['order_number'] ?? map['orderNumber']),
        customerName: _str(map['customer_name'] ?? map['customerName']),
        status: _str(map['status']),
        subtotalAmount: _num(map['subtotal_amount'] ?? map['subtotalAmount']),
        discountAmount: _num(map['discount_amount'] ?? map['discountAmount']),
        taxAmount: _num(map['tax_amount'] ?? map['taxAmount']),
        totalAmount: _num(map['total_amount'] ?? map['totalAmount']),
        currency: _str(map['currency'], fallback: 'YER'),
        issuedAt: _str(map['issued_at'] ?? map['issuedAt']),
        createdAt: _str(map['created_at'] ?? map['createdAt']),
      );
}

class MerchantLedgerEntry {
  const MerchantLedgerEntry(
      {required this.id,
      required this.type,
      required this.amount,
      required this.currency,
      required this.reference,
      required this.description,
      required this.createdAt});
  final String id;
  final String type;
  final num amount;
  final String currency;
  final String reference;
  final String description;
  final String createdAt;
  factory MerchantLedgerEntry.fromMap(Map<String, dynamic> map) =>
      MerchantLedgerEntry(
        id: _str(map['publicId'] ?? map['id']),
        type: _str(
            map['transaction_type'] ?? map['transactionType'] ?? map['type']),
        amount: _num(map['amount']),
        currency: _str(map['currency'], fallback: 'YER'),
        reference:
            _str(map['reference'] ?? map['reference_id'] ?? map['referenceId']),
        description:
            _str(map['description'] ?? map['note'] ?? map['transaction_type']),
        createdAt: _str(map['created_at'] ?? map['createdAt']),
      );
}

class MerchantWalletTransaction {
  const MerchantWalletTransaction(
      {required this.type,
      required this.amount,
      required this.balanceAfter,
      required this.referenceType,
      required this.referenceId,
      required this.note,
      required this.createdAt});
  final String type;
  final num amount;
  final num balanceAfter;
  final String referenceType;
  final String referenceId;
  final String note;
  final String createdAt;
  factory MerchantWalletTransaction.fromMap(Map<String, dynamic> map) =>
      MerchantWalletTransaction(
          type: _str(map['transaction_type'] ?? map['transactionType']),
          amount: _num(map['amount']),
          balanceAfter: _num(map['balance_after'] ?? map['balanceAfter']),
          referenceType: _str(map['reference_type'] ?? map['referenceType']),
          referenceId: _str(map['reference_id'] ?? map['referenceId']),
          note: _str(map['note']),
          createdAt: _str(map['created_at'] ?? map['createdAt']));
}

num _num(Object? value) =>
    value is num ? value : num.tryParse(value?.toString() ?? '') ?? 0;
String _str(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

Map<String, dynamic> _asMap(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
List<Map<String, dynamic>> _list(Object? value) => value is List
    ? value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
    : <Map<String, dynamic>>[];

String merchantMoney(num value, [String currency = 'YER']) =>
    '${value.toStringAsFixed(0)} $currency';
String merchantFinanceStatusLabel(String status) => switch (status) {
      'PENDING' => 'قيد الانتظار',
      'PENDING_REVIEW' => 'بانتظار المراجعة',
      'CONFIRMED' => 'مؤكد',
      'PAID' => 'مدفوع',
      'APPROVED' => 'معتمد',
      'FAILED' => 'فشل',
      'CANCELLED' => 'ملغي',
      'REFUNDED' => 'مسترد',
      'REJECTED' => 'مرفوض',
      'ISSUED' => 'صادرة',
      'ACTIVE' => 'نشطة',
      'FROZEN' => 'مجمدة',
      'CLOSED' => 'مغلقة',
      'CREDIT' => 'إضافة',
      'DEBIT' => 'خصم',
      'HOLD' => 'حجز',
      'RELEASE' => 'تحرير',
      _ => status.isEmpty ? 'غير محدد' : status,
    };
