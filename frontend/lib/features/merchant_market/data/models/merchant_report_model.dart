class MerchantReportsResponse {
  final MerchantReportFilters filters;
  final MerchantReportSummary summary;
  final List<MerchantSalesPoint> salesSeries;
  final List<MerchantBranchPerformance> branchPerformance;
  final List<MerchantProductPerformance> productPerformance;
  final List<MerchantCustomerPerformance> customerPerformance;
  final MerchantInventoryReport inventory;
  final MerchantFinanceReport finance;
  final Map<String, int> orderStatusCounts;
  final Map<String, int> paymentStatusCounts;
  final Map<String, int> fulfillmentCounts;
  final List<MerchantReportInsight> insights;

  const MerchantReportsResponse({
    required this.filters,
    required this.summary,
    required this.salesSeries,
    required this.branchPerformance,
    required this.productPerformance,
    required this.customerPerformance,
    required this.inventory,
    required this.finance,
    required this.orderStatusCounts,
    required this.paymentStatusCounts,
    required this.fulfillmentCounts,
    required this.insights,
  });

  factory MerchantReportsResponse.fromMap(Map<String, dynamic> map) {
    return MerchantReportsResponse(
      filters: MerchantReportFilters.fromMap(_map(map['filters'])),
      summary: MerchantReportSummary.fromMap(_map(map['summary'])),
      salesSeries:
          _maps(map['sales_series']).map(MerchantSalesPoint.fromMap).toList(),
      branchPerformance: _maps(map['branch_performance'])
          .map(MerchantBranchPerformance.fromMap)
          .toList(),
      productPerformance:
          _maps(map['product_performance'] ?? map['top_products'])
              .map(MerchantProductPerformance.fromMap)
              .toList(),
      customerPerformance: _maps(map['customer_performance'])
          .map(MerchantCustomerPerformance.fromMap)
          .toList(),
      inventory: MerchantInventoryReport.fromMap(_map(map['inventory'])),
      finance: MerchantFinanceReport.fromMap(_map(map['finance'])),
      orderStatusCounts:
          _intMap(map['order_status_counts'] ?? map['status_counts']),
      paymentStatusCounts: _intMap(map['payment_status_counts']),
      fulfillmentCounts: _intMap(map['fulfillment_counts']),
      insights:
          _maps(map['insights']).map(MerchantReportInsight.fromMap).toList(),
    );
  }

  static Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  static List<Map<String, dynamic>> _maps(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static Map<String, int> _intMap(dynamic value) {
    if (value is! Map) return const {};
    return Map<String, dynamic>.from(value)
        .map((key, value) => MapEntry(key.toString(), _integer(value)));
  }

  static double _number(dynamic value) =>
      double.tryParse(value?.toString() ?? '') ?? 0;
  static int _integer(dynamic value) =>
      int.tryParse(value?.toString() ?? '') ?? 0;
}

class MerchantReportModel extends MerchantReportsResponse {
  const MerchantReportModel({
    required super.filters,
    required super.summary,
    required super.salesSeries,
    required super.branchPerformance,
    required super.productPerformance,
    required super.customerPerformance,
    required super.inventory,
    required super.finance,
    required super.orderStatusCounts,
    required super.paymentStatusCounts,
    required super.fulfillmentCounts,
    required super.insights,
  });

  factory MerchantReportModel.fromMap(Map<String, dynamic> map) {
    final response = MerchantReportsResponse.fromMap(map);
    return MerchantReportModel(
      filters: response.filters,
      summary: response.summary,
      salesSeries: response.salesSeries,
      branchPerformance: response.branchPerformance,
      productPerformance: response.productPerformance,
      customerPerformance: response.customerPerformance,
      inventory: response.inventory,
      finance: response.finance,
      orderStatusCounts: response.orderStatusCounts,
      paymentStatusCounts: response.paymentStatusCounts,
      fulfillmentCounts: response.fulfillmentCounts,
      insights: response.insights,
    );
  }

  String get period => filters.period;
  DateTime? get dateFrom => filters.dateFrom;
  DateTime? get dateTo => filters.dateTo;
  String get currency => summary.currency;
  double get totalSales => summary.totalSales;
  int get ordersCount => summary.ordersCount;
  int get completedOrdersCount => summary.completedOrdersCount;
  double get averageOrderValue => summary.averageOrderValue;
  Map<String, int> get statusCounts => orderStatusCounts;
  List<MerchantTopProduct> get topProducts => productPerformance
      .map((item) => MerchantTopProduct(
            listingId: item.listingId,
            name: item.name,
            quantity: item.unitsSold,
            sales: item.sales,
          ))
      .toList();
}

class MerchantReportFilters {
  final String period;
  final String type;
  final String? branchId;
  final DateTime? dateFrom;
  final DateTime? dateTo;

  const MerchantReportFilters(
      {required this.period,
      required this.type,
      this.branchId,
      this.dateFrom,
      this.dateTo});

  factory MerchantReportFilters.fromMap(Map<String, dynamic> map) {
    return MerchantReportFilters(
      period: (map['period'] ?? 'month').toString(),
      type: (map['type'] ?? 'overview').toString(),
      branchId: map['branch_id']?.toString(),
      dateFrom: DateTime.tryParse(map['date_from']?.toString() ?? ''),
      dateTo: DateTime.tryParse(map['date_to']?.toString() ?? ''),
    );
  }
}

class MerchantReportSummary {
  final String currency;
  final double totalSales;
  final double netSales;
  final double commissionAmount;
  final double refundsAmount;
  final int ordersCount;
  final int completedOrdersCount;
  final int cancelledOrdersCount;
  final int returnedOrdersCount;
  final double averageOrderValue;
  final double completionRate;
  final double cancellationRate;
  final int customersCount;

  const MerchantReportSummary({
    required this.currency,
    required this.totalSales,
    required this.netSales,
    required this.commissionAmount,
    required this.refundsAmount,
    required this.ordersCount,
    required this.completedOrdersCount,
    required this.cancelledOrdersCount,
    required this.returnedOrdersCount,
    required this.averageOrderValue,
    required this.completionRate,
    required this.cancellationRate,
    required this.customersCount,
  });

  factory MerchantReportSummary.fromMap(Map<String, dynamic> map) {
    return MerchantReportSummary(
      currency: (map['currency'] ?? 'YER').toString(),
      totalSales: MerchantReportsResponse._number(map['total_sales']),
      netSales: MerchantReportsResponse._number(map['net_sales']),
      commissionAmount:
          MerchantReportsResponse._number(map['commission_amount']),
      refundsAmount: MerchantReportsResponse._number(map['refunds_amount']),
      ordersCount: MerchantReportsResponse._integer(map['orders_count']),
      completedOrdersCount:
          MerchantReportsResponse._integer(map['completed_orders_count']),
      cancelledOrdersCount:
          MerchantReportsResponse._integer(map['cancelled_orders_count']),
      returnedOrdersCount:
          MerchantReportsResponse._integer(map['returned_orders_count']),
      averageOrderValue:
          MerchantReportsResponse._number(map['average_order_value']),
      completionRate: MerchantReportsResponse._number(map['completion_rate']),
      cancellationRate:
          MerchantReportsResponse._number(map['cancellation_rate']),
      customersCount: MerchantReportsResponse._integer(map['customers_count']),
    );
  }
}

class MerchantSalesPoint {
  final DateTime? date;
  final double sales;
  final int ordersCount;
  final double netSales;

  const MerchantSalesPoint(
      {this.date,
      required this.sales,
      this.ordersCount = 0,
      this.netSales = 0});

  factory MerchantSalesPoint.fromMap(Map<String, dynamic> map) {
    return MerchantSalesPoint(
      date: DateTime.tryParse(map['date']?.toString() ?? ''),
      sales: MerchantReportsResponse._number(map['sales']),
      ordersCount: MerchantReportsResponse._integer(map['orders_count']),
      netSales: MerchantReportsResponse._number(map['net_sales']),
    );
  }
}

class MerchantBranchPerformance {
  final String? id;
  final String name;
  final double sales;
  final double netSales;
  final int ordersCount;
  final int completedOrdersCount;
  final double averageOrderValue;

  const MerchantBranchPerformance(
      {this.id,
      required this.name,
      required this.sales,
      this.netSales = 0,
      required this.ordersCount,
      this.completedOrdersCount = 0,
      this.averageOrderValue = 0});

  factory MerchantBranchPerformance.fromMap(Map<String, dynamic> map) {
    return MerchantBranchPerformance(
      id: map['branch_id']?.toString(),
      name: (map['branch_name'] ?? 'بدون فرع').toString(),
      sales: MerchantReportsResponse._number(map['sales']),
      netSales: MerchantReportsResponse._number(map['net_sales']),
      ordersCount: MerchantReportsResponse._integer(map['orders_count']),
      completedOrdersCount:
          MerchantReportsResponse._integer(map['completed_orders_count']),
      averageOrderValue:
          MerchantReportsResponse._number(map['average_order_value']),
    );
  }
}

class MerchantProductPerformance {
  final String listingId;
  final String name;
  final String? partNumber;
  final String? categoryName;
  final int unitsSold;
  final int ordersCount;
  final double sales;
  final int availableQuantity;
  final int reservedQuantity;
  final String stockStatus;

  const MerchantProductPerformance(
      {required this.listingId,
      required this.name,
      this.partNumber,
      this.categoryName,
      required this.unitsSold,
      required this.ordersCount,
      required this.sales,
      required this.availableQuantity,
      required this.reservedQuantity,
      required this.stockStatus});

  factory MerchantProductPerformance.fromMap(Map<String, dynamic> map) {
    return MerchantProductPerformance(
      listingId: (map['listing_id'] ?? '').toString(),
      name: (map['product_name'] ?? map['name'] ?? 'منتج').toString(),
      partNumber: map['part_number']?.toString(),
      categoryName: map['category_name']?.toString(),
      unitsSold: MerchantReportsResponse._integer(
          map['units_sold'] ?? map['quantity']),
      ordersCount: MerchantReportsResponse._integer(map['orders_count']),
      sales: MerchantReportsResponse._number(map['sales']),
      availableQuantity:
          MerchantReportsResponse._integer(map['available_quantity']),
      reservedQuantity:
          MerchantReportsResponse._integer(map['reserved_quantity']),
      stockStatus: (map['stock_status'] ?? 'UNKNOWN').toString(),
    );
  }
}

class MerchantTopProduct {
  final String listingId;
  final String name;
  final int quantity;
  final double sales;

  const MerchantTopProduct(
      {required this.listingId,
      required this.name,
      required this.quantity,
      required this.sales});
}

class MerchantCustomerPerformance {
  final String customerId;
  final String name;
  final String? phone;
  final int ordersCount;
  final double sales;
  final DateTime? lastOrderAt;

  const MerchantCustomerPerformance(
      {required this.customerId,
      required this.name,
      this.phone,
      required this.ordersCount,
      required this.sales,
      this.lastOrderAt});

  factory MerchantCustomerPerformance.fromMap(Map<String, dynamic> map) {
    return MerchantCustomerPerformance(
      customerId: (map['customer_id'] ?? '').toString(),
      name: (map['customer_name'] ?? 'عميل').toString(),
      phone: map['phone']?.toString(),
      ordersCount: MerchantReportsResponse._integer(map['orders_count']),
      sales: MerchantReportsResponse._number(map['sales']),
      lastOrderAt: DateTime.tryParse(map['last_order_at']?.toString() ?? ''),
    );
  }
}

class MerchantInventoryReport {
  final int totalProducts;
  final int activeProducts;
  final int lowStockProducts;
  final int outOfStockProducts;
  final int totalOnHand;
  final int totalReserved;
  final double inventoryValue;

  const MerchantInventoryReport(
      {required this.totalProducts,
      required this.activeProducts,
      required this.lowStockProducts,
      required this.outOfStockProducts,
      required this.totalOnHand,
      required this.totalReserved,
      required this.inventoryValue});

  factory MerchantInventoryReport.fromMap(Map<String, dynamic> map) {
    return MerchantInventoryReport(
      totalProducts: MerchantReportsResponse._integer(map['total_products']),
      activeProducts: MerchantReportsResponse._integer(map['active_products']),
      lowStockProducts:
          MerchantReportsResponse._integer(map['low_stock_products']),
      outOfStockProducts:
          MerchantReportsResponse._integer(map['out_of_stock_products']),
      totalOnHand: MerchantReportsResponse._integer(map['total_on_hand']),
      totalReserved: MerchantReportsResponse._integer(map['total_reserved']),
      inventoryValue: MerchantReportsResponse._number(map['inventory_value']),
    );
  }
}

class MerchantFinanceReport {
  final double grossSales;
  final double discounts;
  final double deliveryFees;
  final double commission;
  final double refunds;
  final double netReceivable;
  final double pendingAmount;
  final double paidAmount;

  const MerchantFinanceReport(
      {required this.grossSales,
      required this.discounts,
      required this.deliveryFees,
      required this.commission,
      required this.refunds,
      required this.netReceivable,
      required this.pendingAmount,
      required this.paidAmount});

  factory MerchantFinanceReport.fromMap(Map<String, dynamic> map) {
    return MerchantFinanceReport(
      grossSales: MerchantReportsResponse._number(map['gross_sales']),
      discounts: MerchantReportsResponse._number(map['discounts']),
      deliveryFees: MerchantReportsResponse._number(map['delivery_fees']),
      commission: MerchantReportsResponse._number(map['commission']),
      refunds: MerchantReportsResponse._number(map['refunds']),
      netReceivable: MerchantReportsResponse._number(map['net_receivable']),
      pendingAmount: MerchantReportsResponse._number(map['pending_amount']),
      paidAmount: MerchantReportsResponse._number(map['paid_amount']),
    );
  }
}

class MerchantReportInsight {
  final String title;
  final String message;
  final String severity;
  final String type;

  const MerchantReportInsight(
      {required this.title,
      required this.message,
      required this.severity,
      required this.type});

  factory MerchantReportInsight.fromMap(Map<String, dynamic> map) {
    return MerchantReportInsight(
      title: (map['title'] ?? '').toString(),
      message: (map['message'] ?? '').toString(),
      severity: (map['severity'] ?? 'info').toString(),
      type: (map['type'] ?? 'general').toString(),
    );
  }
}
