class PaymentTransactionModel {
  final int id;
  final String reference;
  final String status;
  final String method;
  final double amount;
  final String currency;
  final String createdAt;

  const PaymentTransactionModel(
      {required this.id,
      required this.reference,
      required this.status,
      required this.method,
      required this.amount,
      required this.currency,
      required this.createdAt});

  factory PaymentTransactionModel.fromMap(Map<String, dynamic> map) {
    return PaymentTransactionModel(
      id: int.tryParse('${map['id']}') ?? 0,
      reference: (map['internalReference'] ??
              map['internal_reference'] ??
              map['publicId'] ??
              '')
          .toString(),
      status: (map['status'] ?? '').toString(),
      method:
          (map['method'] ?? map['paymentMethod'] ?? map['payment_method'] ?? '')
              .toString(),
      amount: double.tryParse('${map['amount'] ?? 0}') ?? 0,
      currency: (map['currency'] ?? 'YER').toString(),
      createdAt: (map['createdAt'] ?? map['created_at'] ?? '').toString(),
    );
  }
}

class ShipmentModel {
  final int id;
  final String shipmentNumber;
  final String status;
  final String trackingNumber;
  final String courierName;
  final String driverName;
  final String shippingCompanyName;
  final double deliveryFee;
  final String currency;
  final String createdAt;

  const ShipmentModel(
      {required this.id,
      required this.shipmentNumber,
      required this.status,
      required this.trackingNumber,
      required this.courierName,
      required this.driverName,
      required this.shippingCompanyName,
      required this.deliveryFee,
      required this.currency,
      required this.createdAt});

  factory ShipmentModel.fromMap(Map<String, dynamic> map) {
    final driver = map['driver'] is Map
        ? Map<String, dynamic>.from(map['driver'] as Map)
        : const <String, dynamic>{};
    final company = map['shippingCompany'] is Map
        ? Map<String, dynamic>.from(map['shippingCompany'] as Map)
        : const <String, dynamic>{};
    return ShipmentModel(
      id: int.tryParse('${map['id']}') ?? 0,
      shipmentNumber:
          (map['shipmentNumber'] ?? map['shipment_number'] ?? '').toString(),
      status: (map['status'] ?? '').toString(),
      trackingNumber: (map['trackingNumber'] ??
              map['tracking_number'] ??
              map['externalShipmentNumber'] ??
              '')
          .toString(),
      courierName: (map['courierName'] ?? map['courier_name'] ?? '').toString(),
      driverName: (driver['fullName'] ?? driver['full_name'] ?? '').toString(),
      shippingCompanyName:
          (company['nameAr'] ?? company['name_ar'] ?? company['nameEn'] ?? '')
              .toString(),
      deliveryFee: double.tryParse(
              '${map['deliveryFee'] ?? map['delivery_fee'] ?? 0}') ??
          0,
      currency: (map['currency'] ?? 'YER').toString(),
      createdAt: (map['createdAt'] ?? map['created_at'] ?? '').toString(),
    );
  }
}

class NotificationModel {
  final int id;
  final String title;
  final String body;
  final String status;
  final String createdAt;

  const NotificationModel(
      {required this.id,
      required this.title,
      required this.body,
      required this.status,
      required this.createdAt});

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: int.tryParse('${map['id']}') ?? 0,
      title: (map['title'] ?? '').toString(),
      body: (map['body'] ?? '').toString(),
      status: (map['status'] ?? '').toString(),
      createdAt: (map['createdAt'] ?? map['created_at'] ?? '').toString(),
    );
  }
}
