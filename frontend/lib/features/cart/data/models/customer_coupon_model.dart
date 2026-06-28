class CustomerCouponResponse {
  final List<CustomerCouponModel> coupons;
  final CustomerCouponStats stats;
  final String currency;

  const CustomerCouponResponse({
    this.coupons = const [],
    this.stats = const CustomerCouponStats(),
    this.currency = 'YER',
  });

  factory CustomerCouponResponse.fromMap(Map<String, dynamic> map) {
    final list =
        (map['coupons'] ?? map['items'] ?? map['data']) as List<dynamic>? ??
            const [];
    return CustomerCouponResponse(
      coupons: list
          .whereType<Map>()
          .map((item) =>
              CustomerCouponModel.fromMap(Map<String, dynamic>.from(item)))
          .toList(),
      stats: map['stats'] is Map
          ? CustomerCouponStats.fromMap(
              Map<String, dynamic>.from(map['stats'] as Map))
          : const CustomerCouponStats(),
      currency: (map['currency'] ?? 'YER').toString(),
    );
  }
}

class CustomerCouponStats {
  final int total;
  final int available;
  final int expiringSoon;
  final int bestSavings;

  const CustomerCouponStats({
    this.total = 0,
    this.available = 0,
    this.expiringSoon = 0,
    this.bestSavings = 0,
  });

  factory CustomerCouponStats.fromMap(Map<String, dynamic> map) {
    return CustomerCouponStats(
      total: _int(map['total']),
      available: _int(map['available']),
      expiringSoon: _int(map['expiringSoon'] ?? map['expiring_soon']),
      bestSavings: _int(map['bestSavings'] ?? map['best_savings']),
    );
  }
}

class CustomerCouponModel {
  final String id;
  final String code;
  final String title;
  final String description;
  final String discountType;
  final double discountValue;
  final double? maxDiscountAmount;
  final double estimatedDiscount;
  final double minimumOrderAmount;
  final int? usageLimit;
  final int usedCount;
  final bool isActive;
  final bool isApplicable;
  final String statusLabel;
  final String validityMessage;
  final DateTime? startsAt;
  final DateTime? expiresAt;

  const CustomerCouponModel({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.discountType,
    required this.discountValue,
    this.maxDiscountAmount,
    this.estimatedDiscount = 0,
    this.minimumOrderAmount = 0,
    this.usageLimit,
    this.usedCount = 0,
    this.isActive = true,
    this.isApplicable = true,
    this.statusLabel = 'متاح',
    this.validityMessage = '',
    this.startsAt,
    this.expiresAt,
  });

  factory CustomerCouponModel.fromMap(Map<String, dynamic> map) {
    final code = (map['code'] ?? '').toString();
    final type =
        (map['discountType'] ?? map['discount_type'] ?? 'FIXED').toString();
    final value = _double(map['discountValue'] ?? map['discount_value']);
    return CustomerCouponModel(
      id: (map['publicId'] ?? map['public_id'] ?? map['id'] ?? code).toString(),
      code: code,
      title: (map['title'] ?? _titleFor(type, value)).toString(),
      description: (map['description'] ?? '').toString(),
      discountType: type,
      discountValue: value,
      maxDiscountAmount: _nullableDouble(
          map['maxDiscountAmount'] ?? map['max_discount_amount']),
      estimatedDiscount:
          _double(map['estimatedDiscount'] ?? map['estimated_discount']),
      minimumOrderAmount:
          _double(map['minimumOrderAmount'] ?? map['minimum_order_amount']),
      usageLimit: _nullableInt(map['usageLimit'] ?? map['usage_limit']),
      usedCount: _int(map['usedCount'] ?? map['used_count']),
      isActive: map['isActive'] ?? map['is_active'] ?? true,
      isApplicable: map['isApplicable'] ?? map['is_applicable'] ?? true,
      statusLabel:
          (map['statusLabel'] ?? map['status_label'] ?? 'متاح').toString(),
      validityMessage:
          (map['validityMessage'] ?? map['validity_message'] ?? '').toString(),
      startsAt: _date(map['startsAt'] ?? map['starts_at']),
      expiresAt: _date(map['expiresAt'] ?? map['expires_at']),
    );
  }

  bool get isPercent => discountType.toUpperCase() == 'PERCENT';
  String get discountLabel => isPercent
      ? '${discountValue.toStringAsFixed(discountValue.truncateToDouble() == discountValue ? 0 : 1)}%'
      : '${discountValue.toStringAsFixed(0)} ر.ي';
  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());
}

class CouponValidationResult {
  final bool valid;
  final String code;
  final String message;
  final double subtotal;
  final double discount;
  final double total;
  final String currency;

  const CouponValidationResult({
    required this.valid,
    required this.code,
    required this.message,
    this.subtotal = 0,
    this.discount = 0,
    this.total = 0,
    this.currency = 'YER',
  });

  factory CouponValidationResult.fromMap(Map<String, dynamic> map) {
    return CouponValidationResult(
      valid: map['valid'] ?? map['isValid'] ?? true,
      code: (map['code'] ?? '').toString(),
      message: (map['message'] ?? 'تم التحقق من الكوبون').toString(),
      subtotal: _double(map['subtotal']),
      discount: _double(
          map['discount'] ?? map['discountAmount'] ?? map['discount_amount']),
      total: _double(map['total']),
      currency: (map['currency'] ?? 'YER').toString(),
    );
  }
}

String _titleFor(String type, double value) => type.toUpperCase() == 'PERCENT'
    ? 'خصم ${value.toStringAsFixed(0)}%'
    : 'خصم ${value.toStringAsFixed(0)} ر.ي';

int _int(dynamic value) => int.tryParse((value ?? 0).toString()) ?? 0;
int? _nullableInt(dynamic value) =>
    value == null ? null : int.tryParse(value.toString());
double _double(dynamic value) => double.tryParse((value ?? 0).toString()) ?? 0;
double? _nullableDouble(dynamic value) =>
    value == null ? null : double.tryParse(value.toString());
DateTime? _date(dynamic value) =>
    value == null ? null : DateTime.tryParse(value.toString());
