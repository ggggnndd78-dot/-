class MerchantOrderModel {
  final String id;
  final String orderNumber;
  final String status;
  final String customerName;
  final double total;

  const MerchantOrderModel({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.customerName,
    required this.total,
  });

  factory MerchantOrderModel.fromMap(Map<String, dynamic> map) {
    return MerchantOrderModel(
      id: map['id'].toString(),
      orderNumber:
          (map['orderNumber'] ?? map['order_number'] ?? map['id']).toString(),
      status: (map['status'] ?? '').toString(),
      customerName: (map['customerName'] ??
              map['customer_name'] ??
              (map['user'] is Map
                  ? (map['user']['displayName'] ??
                      map['user']['phoneNormalized'])
                  : null) ??
              'عميل')
          .toString(),
      total: double.tryParse(
              (map['total'] ?? map['totalAmount'] ?? map['total_amount'] ?? 0)
                  .toString()) ??
          0,
    );
  }
}
