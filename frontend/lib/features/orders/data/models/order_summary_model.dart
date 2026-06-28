class OrderSummaryModel {
  final String id;
  final String orderNumber;
  final String status;
  final double total;
  final String currency;
  final String createdAt;

  const OrderSummaryModel({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.total,
    required this.currency,
    required this.createdAt,
  });

  factory OrderSummaryModel.fromMap(Map<String, dynamic> map) {
    return OrderSummaryModel(
      id: map['id'].toString(),
      orderNumber:
          (map['orderNumber'] ?? map['order_number'] ?? map['id']).toString(),
      status: (map['status'] ?? '').toString(),
      total: double.tryParse(
              (map['totalAmount'] ?? map['total_amount'] ?? map['total'] ?? 0)
                  .toString()) ??
          0,
      currency: (map['currency'] ?? 'YER').toString(),
      createdAt: (map['createdAt'] ?? map['created_at'] ?? '').toString(),
    );
  }

  factory OrderSummaryModel.fromJson(Map<String, dynamic> map) =>
      OrderSummaryModel.fromMap(map);

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderNumber': orderNumber,
        'status': status,
        'total': total,
        'currency': currency,
        'createdAt': createdAt,
      };
}
