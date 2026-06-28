class CustomerShipmentTrackingModel {
  final String orderId;
  final String orderNumber;
  final String orderStatus;
  final String fulfillmentMethod;
  final String paymentStatus;
  final String merchantName;
  final String branchName;
  final String branchPhone;
  final CustomerShipmentModel? shipment;
  final List<CustomerShipmentTimelineItem> timeline;
  final CustomerDeliveryAddress? address;
  final List<String> actions;

  const CustomerShipmentTrackingModel({
    required this.orderId,
    required this.orderNumber,
    required this.orderStatus,
    required this.fulfillmentMethod,
    required this.paymentStatus,
    required this.merchantName,
    required this.branchName,
    required this.branchPhone,
    required this.shipment,
    required this.timeline,
    required this.address,
    required this.actions,
  });

  bool get hasShipment => shipment != null;
  bool get isPickup => fulfillmentMethod.toUpperCase() == 'PICKUP';
  bool get canReschedule => actions.contains('RESCHEDULE_DELIVERY');
  bool get canContactDriver => (shipment?.driverPhone ?? '').isNotEmpty;
  bool get isDelivered =>
      (shipment?.status ?? orderStatus).toUpperCase() == 'DELIVERED' ||
      orderStatus.toUpperCase() == 'COMPLETED';

  factory CustomerShipmentTrackingModel.fromMap(Map<String, dynamic> map) {
    final shipmentMap = _map(map['shipment']);
    return CustomerShipmentTrackingModel(
      orderId: (map['orderId'] ?? map['order_id'] ?? '').toString(),
      orderNumber: (map['orderNumber'] ?? map['order_number'] ?? '').toString(),
      orderStatus: (map['orderStatus'] ?? map['order_status'] ?? '').toString(),
      fulfillmentMethod:
          (map['fulfillmentMethod'] ?? map['fulfillment_method'] ?? '')
              .toString(),
      paymentStatus:
          (map['paymentStatus'] ?? map['payment_status'] ?? '').toString(),
      merchantName:
          (map['merchantName'] ?? map['merchant_name'] ?? '').toString(),
      branchName: (map['branchName'] ?? map['branch_name'] ?? '').toString(),
      branchPhone: (map['branchPhone'] ?? map['branch_phone'] ?? '').toString(),
      shipment: shipmentMap.isEmpty
          ? null
          : CustomerShipmentModel.fromMap(shipmentMap),
      timeline: _list(map['timeline'])
          .map(CustomerShipmentTimelineItem.fromMap)
          .toList(),
      address: _map(map['address']).isEmpty
          ? null
          : CustomerDeliveryAddress.fromMap(_map(map['address'])),
      actions: (map['actions'] is List ? map['actions'] as List : const [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

class CustomerShipmentModel {
  final String id;
  final String trackingNumber;
  final String status;
  final String deliveryMethod;
  final String shippingCompanyName;
  final String driverName;
  final String driverPhone;
  final double deliveryFee;
  final String currency;
  final String scheduledDeliveryAt;
  final String estimatedDeliveryAt;
  final String proofNote;
  final String createdAt;
  final String updatedAt;

  const CustomerShipmentModel({
    required this.id,
    required this.trackingNumber,
    required this.status,
    required this.deliveryMethod,
    required this.shippingCompanyName,
    required this.driverName,
    required this.driverPhone,
    required this.deliveryFee,
    required this.currency,
    required this.scheduledDeliveryAt,
    required this.estimatedDeliveryAt,
    required this.proofNote,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CustomerShipmentModel.fromMap(Map<String, dynamic> map) {
    return CustomerShipmentModel(
      id: (map['id'] ?? map['publicId'] ?? map['public_id'] ?? '').toString(),
      trackingNumber:
          (map['trackingNumber'] ?? map['tracking_number'] ?? '').toString(),
      status: (map['status'] ?? '').toString(),
      deliveryMethod:
          (map['deliveryMethod'] ?? map['delivery_method'] ?? '').toString(),
      shippingCompanyName:
          (map['shippingCompanyName'] ?? map['shipping_company_name'] ?? '')
              .toString(),
      driverName: (map['driverName'] ?? map['driver_name'] ?? '').toString(),
      driverPhone: (map['driverPhone'] ?? map['driver_phone'] ?? '').toString(),
      deliveryFee: _double(map['deliveryFee'] ?? map['delivery_fee']),
      currency: (map['currency'] ?? 'YER').toString(),
      scheduledDeliveryAt:
          (map['scheduledDeliveryAt'] ?? map['scheduled_delivery_at'] ?? '')
              .toString(),
      estimatedDeliveryAt:
          (map['estimatedDeliveryAt'] ?? map['estimated_delivery_at'] ?? '')
              .toString(),
      proofNote: (map['proofNote'] ?? map['proof_note'] ?? '').toString(),
      createdAt: (map['createdAt'] ?? map['created_at'] ?? '').toString(),
      updatedAt: (map['updatedAt'] ?? map['updated_at'] ?? '').toString(),
    );
  }
}

class CustomerShipmentTimelineItem {
  final String status;
  final String label;
  final String note;
  final String createdAt;
  final double? latitude;
  final double? longitude;

  const CustomerShipmentTimelineItem({
    required this.status,
    required this.label,
    required this.note,
    required this.createdAt,
    this.latitude,
    this.longitude,
  });

  factory CustomerShipmentTimelineItem.fromMap(Map<String, dynamic> map) {
    return CustomerShipmentTimelineItem(
      status: (map['status'] ?? '').toString(),
      label: (map['label'] ?? _statusLabel((map['status'] ?? '').toString()))
          .toString(),
      note: (map['note'] ?? '').toString(),
      createdAt: (map['createdAt'] ?? map['created_at'] ?? '').toString(),
      latitude: _nullableDouble(map['latitude']),
      longitude: _nullableDouble(map['longitude']),
    );
  }
}

class CustomerDeliveryAddress {
  final String recipientName;
  final String phone;
  final String city;
  final String district;
  final String addressLine;
  final String landmark;
  final String driverNote;

  const CustomerDeliveryAddress({
    required this.recipientName,
    required this.phone,
    required this.city,
    required this.district,
    required this.addressLine,
    required this.landmark,
    required this.driverNote,
  });

  factory CustomerDeliveryAddress.fromMap(Map<String, dynamic> map) {
    return CustomerDeliveryAddress(
      recipientName:
          (map['recipientName'] ?? map['recipient_name'] ?? '').toString(),
      phone: (map['phone'] ?? '').toString(),
      city: (map['city'] ?? '').toString(),
      district: (map['district'] ?? '').toString(),
      addressLine: (map['addressLine'] ?? map['address_line'] ?? '').toString(),
      landmark: (map['landmark'] ?? '').toString(),
      driverNote: (map['driverNote'] ?? map['driver_note'] ?? '').toString(),
    );
  }
}

String _statusLabel(String status) {
  switch (status.toUpperCase()) {
    case 'CREATED':
      return 'تم إنشاء الشحنة';
    case 'ASSIGNED':
      return 'تم إسناد الشحنة';
    case 'OUT_FOR_DELIVERY':
      return 'خرجت للتوصيل';
    case 'DELIVERED':
      return 'تم التسليم';
    case 'FAILED':
      return 'فشل التسليم';
    case 'RESCHEDULED':
      return 'تمت إعادة الجدولة';
    case 'CANCELLED':
      return 'ألغيت الشحنة';
    default:
      return status.isEmpty ? 'تحديث' : status;
  }
}

Map<String, dynamic> _map(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : {};
List<Map<String, dynamic>> _list(Object? value) => value is List
    ? value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
    : const [];
double _double(Object? value) => double.tryParse((value ?? 0).toString()) ?? 0;
double? _nullableDouble(Object? value) =>
    value == null ? null : double.tryParse(value.toString());
