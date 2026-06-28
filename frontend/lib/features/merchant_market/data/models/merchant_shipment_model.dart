class MerchantShipmentSummary {
  const MerchantShipmentSummary({
    required this.total,
    required this.created,
    required this.assigned,
    required this.outForDelivery,
    required this.delivered,
    required this.failed,
    required this.cancelled,
    required this.totalDeliveryFees,
  });

  final int total;
  final int created;
  final int assigned;
  final int outForDelivery;
  final int delivered;
  final int failed;
  final int cancelled;
  final num totalDeliveryFees;

  factory MerchantShipmentSummary.fromMap(Map<String, dynamic> map) {
    return MerchantShipmentSummary(
      total: _int(map['total']),
      created: _int(map['created']),
      assigned: _int(map['assigned']),
      outForDelivery: _int(map['outForDelivery'] ?? map['out_for_delivery']),
      delivered: _int(map['delivered']),
      failed: _int(map['failed']),
      cancelled: _int(map['cancelled']),
      totalDeliveryFees:
          _num(map['totalDeliveryFees'] ?? map['total_delivery_fees']),
    );
  }

  static const empty = MerchantShipmentSummary(
    total: 0,
    created: 0,
    assigned: 0,
    outForDelivery: 0,
    delivered: 0,
    failed: 0,
    cancelled: 0,
    totalDeliveryFees: 0,
  );
}

class MerchantShipmentsResponse {
  const MerchantShipmentsResponse({
    required this.summary,
    required this.shipments,
    required this.ordersReadyForShipment,
    required this.drivers,
    required this.shippingCompanies,
    required this.deliveryMethods,
  });

  final MerchantShipmentSummary summary;
  final List<MerchantShipment> shipments;
  final List<MerchantShipmentLookup> ordersReadyForShipment;
  final List<MerchantShipmentLookup> drivers;
  final List<MerchantShipmentLookup> shippingCompanies;
  final List<MerchantShipmentLookup> deliveryMethods;

  factory MerchantShipmentsResponse.fromMap(Map<String, dynamic> map) {
    return MerchantShipmentsResponse(
      summary: MerchantShipmentSummary.fromMap(_asMap(map['summary'])),
      shipments: _list(map['shipments'] ?? map['items'] ?? map['data'])
          .map(MerchantShipment.fromMap)
          .toList(),
      ordersReadyForShipment: _list(
              map['ordersReadyForShipment'] ?? map['orders_ready_for_shipment'])
          .map(MerchantShipmentLookup.fromMap)
          .toList(),
      drivers:
          _list(map['drivers']).map(MerchantShipmentLookup.fromMap).toList(),
      shippingCompanies:
          _list(map['shippingCompanies'] ?? map['shipping_companies'])
              .map(MerchantShipmentLookup.fromMap)
              .toList(),
      deliveryMethods: _list(map['deliveryMethods'] ?? map['delivery_methods'])
          .map(MerchantShipmentLookup.fromMap)
          .toList(),
    );
  }
}

class MerchantShipmentLookup {
  const MerchantShipmentLookup({
    required this.id,
    required this.title,
    this.subtitle = '',
    this.phone = '',
  });

  final String id;
  final String title;
  final String subtitle;
  final String phone;

  factory MerchantShipmentLookup.fromMap(Map<String, dynamic> map) {
    return MerchantShipmentLookup(
      id: (map['id'] ?? map['publicId'] ?? map['public_id'] ?? '').toString(),
      title: (map['title'] ??
              map['name'] ??
              map['nameAr'] ??
              map['name_ar'] ??
              map['displayName'] ??
              map['display_name'] ??
              map['order_number'] ??
              map['orderNumber'] ??
              '')
          .toString(),
      subtitle:
          (map['subtitle'] ?? map['customer_name'] ?? map['customerName'] ?? '')
              .toString(),
      phone:
          (map['phone'] ?? map['customer_phone'] ?? map['customerPhone'] ?? '')
              .toString(),
    );
  }
}

class MerchantShipment {
  const MerchantShipment({
    required this.id,
    required this.status,
    this.orderId = '',
    this.orderNumber = '',
    this.orderStatus = '',
    this.customerName = '',
    this.customerPhone = '',
    this.customerAddress = '',
    this.cityName = '',
    this.branchName = '',
    this.deliveryMethod = '',
    this.driverName = '',
    this.driverPhone = '',
    this.companyName = '',
    this.companyPhone = '',
    this.trackingNumber = '',
    this.deliveryFee = 0,
    this.currency = 'YER',
    this.createdAt = '',
    this.updatedAt = '',
    this.tracking = const [],
  });

  final String id;
  final String status;
  final String orderId;
  final String orderNumber;
  final String orderStatus;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final String cityName;
  final String branchName;
  final String deliveryMethod;
  final String driverName;
  final String driverPhone;
  final String companyName;
  final String companyPhone;
  final String trackingNumber;
  final num deliveryFee;
  final String currency;
  final String createdAt;
  final String updatedAt;
  final List<MerchantShipmentTracking> tracking;

  bool get isFinal => status == 'DELIVERED' || status == 'CANCELLED';
  bool get isFailed => status == 'FAILED';

  factory MerchantShipment.fromMap(Map<String, dynamic> map) {
    return MerchantShipment(
      id: (map['publicId'] ?? map['public_id'] ?? map['id'] ?? '').toString(),
      status: (map['status'] ?? '').toString(),
      orderId: (map['order_id'] ?? map['orderId'] ?? '').toString(),
      orderNumber: (map['order_number'] ?? map['orderNumber'] ?? '').toString(),
      orderStatus: (map['order_status'] ?? map['orderStatus'] ?? '').toString(),
      customerName:
          (map['customer_name'] ?? map['customerName'] ?? '').toString(),
      customerPhone:
          (map['customer_phone'] ?? map['customerPhone'] ?? '').toString(),
      customerAddress: (map['customer_address'] ??
              map['customerAddress'] ??
              map['shipping_address'] ??
              '')
          .toString(),
      cityName: (map['city_name'] ?? map['cityName'] ?? '').toString(),
      branchName: (map['branch_name'] ?? map['branchName'] ?? '').toString(),
      deliveryMethod: (map['delivery_method'] ??
              map['deliveryMethod'] ??
              map['delivery_method_name'] ??
              '')
          .toString(),
      driverName: (map['driver_name'] ?? map['driverName'] ?? '').toString(),
      driverPhone: (map['driver_phone'] ?? map['driverPhone'] ?? '').toString(),
      companyName: (map['company_name'] ?? map['companyName'] ?? '').toString(),
      companyPhone:
          (map['company_phone'] ?? map['companyPhone'] ?? '').toString(),
      trackingNumber:
          (map['tracking_number'] ?? map['trackingNumber'] ?? '').toString(),
      deliveryFee: _num(map['delivery_fee'] ?? map['deliveryFee']),
      currency: (map['currency'] ?? 'YER').toString(),
      createdAt: (map['created_at'] ?? map['createdAt'] ?? '').toString(),
      updatedAt: (map['updated_at'] ?? map['updatedAt'] ?? '').toString(),
      tracking:
          _list(map['tracking']).map(MerchantShipmentTracking.fromMap).toList(),
    );
  }
}

class MerchantShipmentTracking {
  const MerchantShipmentTracking({
    required this.status,
    this.note = '',
    this.createdAt = '',
    this.latitude,
    this.longitude,
  });

  final String status;
  final String note;
  final String createdAt;
  final num? latitude;
  final num? longitude;

  factory MerchantShipmentTracking.fromMap(Map<String, dynamic> map) {
    return MerchantShipmentTracking(
      status: (map['status'] ?? '').toString(),
      note: (map['note'] ?? '').toString(),
      createdAt: (map['created_at'] ?? map['createdAt'] ?? '').toString(),
      latitude: _nullableNum(map['latitude']),
      longitude: _nullableNum(map['longitude']),
    );
  }
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const <String, dynamic>{};
}

List<Map<String, dynamic>> _list(Object? value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
  return const <Map<String, dynamic>>[];
}

int _int(Object? value) => int.tryParse(value?.toString() ?? '') ?? 0;
num _num(Object? value) => num.tryParse(value?.toString() ?? '') ?? 0;
num? _nullableNum(Object? value) =>
    value == null ? null : num.tryParse(value.toString());
