class CheckoutPreviewModel {
  final double subtotal;
  final double discount;
  final double deliveryFee;
  final double total;
  final String currency;
  final List<CheckoutMerchantPreview> merchants;
  final CheckoutCouponModel? coupon;

  const CheckoutPreviewModel({
    required this.subtotal,
    required this.discount,
    required this.deliveryFee,
    required this.total,
    required this.currency,
    this.merchants = const [],
    this.coupon,
  });

  factory CheckoutPreviewModel.fromJson(Map<String, dynamic> json) {
    final rawMerchants =
        json['merchants'] is List ? json['merchants'] as List : const [];
    final merchants = rawMerchants
        .whereType<Map>()
        .map((item) =>
            CheckoutMerchantPreview.fromMap(Map<String, dynamic>.from(item)))
        .toList();
    final subtotal =
        merchants.fold<double>(0, (sum, merchant) => sum + merchant.subtotal);
    final deliveryFee = merchants.fold<double>(
        0, (sum, merchant) => sum + merchant.deliveryFee);
    final couponRaw =
        json['coupon'] ?? json['appliedCoupon'] ?? json['applied_coupon'];

    return CheckoutPreviewModel(
      subtotal: _number(json['subtotal'] ?? subtotal),
      discount: _number(json['discount'] ??
          json['discountAmount'] ??
          json['discount_amount']),
      deliveryFee:
          _number(json['deliveryFee'] ?? json['delivery_fee'] ?? deliveryFee),
      total: _number(json['total'] ??
          json['grand_total'] ??
          json['totalAmount'] ??
          json['total_amount']),
      currency: (json['currency'] ?? 'YER').toString(),
      merchants: merchants,
      coupon: couponRaw is Map
          ? CheckoutCouponModel.fromMap(Map<String, dynamic>.from(couponRaw))
          : null,
    );
  }

  factory CheckoutPreviewModel.fromMap(Map<String, dynamic> map) =>
      CheckoutPreviewModel.fromJson(map);

  Map<String, dynamic> toJson() => {
        'subtotal': subtotal,
        'discount': discount,
        'deliveryFee': deliveryFee,
        'total': total,
        'currency': currency,
        'merchants': merchants.map((merchant) => merchant.toJson()).toList(),
        'coupon': coupon?.toJson(),
      };

  static double _number(dynamic value) =>
      double.tryParse((value ?? 0).toString()) ?? 0;
  static int _int(dynamic value) => int.tryParse((value ?? 0).toString()) ?? 0;
}

class CheckoutMerchantPreview {
  final String organizationId;
  final String organizationName;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double total;
  final List<CheckoutItemPreview> items;

  const CheckoutMerchantPreview({
    required this.organizationId,
    required this.organizationName,
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    required this.total,
    this.items = const [],
  });

  factory CheckoutMerchantPreview.fromMap(Map<String, dynamic> map) {
    final rawItems = map['items'] is List ? map['items'] as List : const [];
    return CheckoutMerchantPreview(
      organizationId:
          (map['organizationId'] ?? map['organization_id'] ?? map['id'] ?? '')
              .toString(),
      organizationName: (map['organizationName'] ??
              map['organization_name'] ??
              map['merchantName'] ??
              map['merchant_name'] ??
              'متجر')
          .toString(),
      subtotal: CheckoutPreviewModel._number(map['subtotal']),
      deliveryFee: CheckoutPreviewModel._number(
          map['deliveryFee'] ?? map['delivery_fee']),
      discount: CheckoutPreviewModel._number(
          map['discount'] ?? map['discountAmount'] ?? map['discount_amount']),
      total: CheckoutPreviewModel._number(
          map['total'] ?? map['totalAmount'] ?? map['total_amount']),
      items: rawItems
          .whereType<Map>()
          .map((item) =>
              CheckoutItemPreview.fromMap(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'organizationId': organizationId,
        'organizationName': organizationName,
        'subtotal': subtotal,
        'deliveryFee': deliveryFee,
        'discount': discount,
        'total': total,
        'items': items.map((item) => item.toJson()).toList(),
      };
}

class CheckoutItemPreview {
  final String id;
  final String listingId;
  final String title;
  final int quantity;
  final double unitPrice;
  final double total;

  const CheckoutItemPreview({
    required this.id,
    required this.listingId,
    required this.title,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });

  factory CheckoutItemPreview.fromMap(Map<String, dynamic> map) {
    final quantity = CheckoutPreviewModel._int(map['quantity']);
    final unitPrice = CheckoutPreviewModel._number(
        map['unitPrice'] ?? map['unit_price'] ?? map['price']);
    return CheckoutItemPreview(
      id: (map['id'] ?? '').toString(),
      listingId: (map['listingId'] ?? map['listing_id'] ?? '').toString(),
      title:
          (map['title'] ?? map['productName'] ?? map['product_name'] ?? 'قطعة')
              .toString(),
      quantity: quantity,
      unitPrice: unitPrice,
      total: CheckoutPreviewModel._number(map['total'] ??
          map['totalAmount'] ??
          map['total_amount'] ??
          unitPrice * quantity),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'listingId': listingId,
        'title': title,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'total': total,
      };
}

class CheckoutCouponModel {
  final String code;
  final double discountAmount;

  const CheckoutCouponModel({required this.code, required this.discountAmount});

  factory CheckoutCouponModel.fromMap(Map<String, dynamic> map) {
    return CheckoutCouponModel(
      code: (map['code'] ?? '').toString(),
      discountAmount: CheckoutPreviewModel._number(
          map['discountAmount'] ?? map['discount_amount'] ?? map['discount']),
    );
  }

  Map<String, dynamic> toJson() =>
      {'code': code, 'discountAmount': discountAmount};
}
