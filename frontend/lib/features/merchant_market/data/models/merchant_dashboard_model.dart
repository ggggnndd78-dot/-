class MerchantDashboardModel {
  final String period;
  final MerchantDashboardIdentity merchant;
  final MerchantDashboardSummary summary;
  final List<MerchantSalesPoint> salesChart;
  final List<MerchantRecentOrder> recentOrders;

  const MerchantDashboardModel({
    required this.period,
    required this.merchant,
    required this.summary,
    required this.salesChart,
    required this.recentOrders,
  });

  factory MerchantDashboardModel.fromMap(Map<String, dynamic> map) {
    return MerchantDashboardModel(
      period: (map['period'] ?? 'day').toString(),
      merchant: MerchantDashboardIdentity.fromMap(
        _map(map['merchant']),
      ),
      summary: MerchantDashboardSummary.fromMap(
        _map(map['summary']),
      ),
      salesChart: _maps(map['sales_chart'])
          .map(MerchantSalesPoint.fromMap)
          .toList(growable: false),
      recentOrders: _maps(map['recent_orders'])
          .map(MerchantRecentOrder.fromMap)
          .toList(growable: false),
    );
  }

  static Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : {};

  static List<Map<String, dynamic>> _maps(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }
}

class MerchantDashboardIdentity {
  final String id;
  final String name;
  final String? logoUrl;
  final String? profileImageUrl;
  final String memberRole;
  final List<String> roleCodes;
  final List<String> permissions;

  const MerchantDashboardIdentity({
    required this.id,
    required this.name,
    this.logoUrl,
    this.profileImageUrl,
    required this.memberRole,
    required this.roleCodes,
    required this.permissions,
  });

  factory MerchantDashboardIdentity.fromMap(Map<String, dynamic> map) {
    return MerchantDashboardIdentity(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      logoUrl: map['logo_url']?.toString(),
      profileImageUrl: map['profile_image_url']?.toString(),
      memberRole: (map['member_role'] ?? '').toString(),
      roleCodes: _strings(map['role_codes']),
      permissions: _strings(map['permissions']),
    );
  }

  static List<String> _strings(dynamic value) => value is List
      ? value.map((item) => item.toString()).toList(growable: false)
      : const [];

  bool get canManageOrganization =>
      memberRole == 'owner' ||
      roleCodes.contains('merchant_owner') ||
      permissions.contains('manage_organization');
}

class MerchantDashboardSummary {
  final double totalSales;
  final int newOrders;
  final int lowStockProducts;
  final int lowStockThreshold;
  final double salesGrowthPercentage;
  final int unreadNotifications;
  final String currency;

  const MerchantDashboardSummary({
    required this.totalSales,
    required this.newOrders,
    required this.lowStockProducts,
    required this.lowStockThreshold,
    required this.salesGrowthPercentage,
    required this.unreadNotifications,
    required this.currency,
  });

  factory MerchantDashboardSummary.fromMap(Map<String, dynamic> map) {
    return MerchantDashboardSummary(
      totalSales: _double(map['total_sales']),
      newOrders: _int(map['new_orders']),
      lowStockProducts: _int(map['low_stock_products']),
      lowStockThreshold: _int(map['low_stock_threshold']),
      salesGrowthPercentage: _double(map['sales_growth_percentage']),
      unreadNotifications: _int(map['unread_notifications']),
      currency: (map['currency'] ?? 'YER').toString(),
    );
  }

  static double _double(dynamic value) =>
      double.tryParse(value?.toString() ?? '') ?? 0;
  static int _int(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;
}

class MerchantSalesPoint {
  final DateTime? date;
  final double sales;
  final int ordersCount;

  const MerchantSalesPoint({
    this.date,
    required this.sales,
    required this.ordersCount,
  });

  factory MerchantSalesPoint.fromMap(Map<String, dynamic> map) {
    return MerchantSalesPoint(
      date: DateTime.tryParse((map['date'] ?? '').toString()),
      sales: MerchantDashboardSummary._double(map['sales']),
      ordersCount: MerchantDashboardSummary._int(map['orders_count']),
    );
  }
}

class MerchantRecentOrder {
  final String id;
  final String publicId;
  final String orderNumber;
  final String status;
  final double totalAmount;
  final String currency;
  final String paymentStatus;
  final String customerName;
  final int itemsCount;
  final DateTime? createdAt;

  const MerchantRecentOrder({
    required this.id,
    required this.publicId,
    required this.orderNumber,
    required this.status,
    required this.totalAmount,
    required this.currency,
    required this.paymentStatus,
    required this.customerName,
    required this.itemsCount,
    this.createdAt,
  });

  factory MerchantRecentOrder.fromMap(Map<String, dynamic> map) {
    return MerchantRecentOrder(
      id: (map['id'] ?? '').toString(),
      publicId: (map['public_id'] ?? '').toString(),
      orderNumber: (map['order_number'] ?? '').toString(),
      status: (map['status'] ?? '').toString(),
      totalAmount: MerchantDashboardSummary._double(map['total_amount']),
      currency: (map['currency'] ?? 'YER').toString(),
      paymentStatus: (map['payment_status'] ?? '').toString(),
      customerName: (map['customer_name'] ?? 'عميل').toString(),
      itemsCount: MerchantDashboardSummary._int(map['items_count']),
      createdAt: DateTime.tryParse((map['created_at'] ?? '').toString()),
    );
  }
}
