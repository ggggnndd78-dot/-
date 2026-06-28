class OrderDetailModel {
  final String id;
  final String orderNumber;
  final String status;
  final String organizationName;
  final String fulfillmentMethod;
  final String paymentMethod;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final String currency;
  final List<OrderItemModel> items;

  const OrderDetailModel({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.organizationName,
    required this.fulfillmentMethod,
    required this.paymentMethod,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.currency,
    required this.items,
  });

  factory OrderDetailModel.fromJson(Map<String, dynamic> json) {
    final organization = json['organization'] is Map
        ? Map<String, dynamic>.from(json['organization'] as Map)
        : const <String, dynamic>{};
    final rawItems = json['items'] is List ? json['items'] as List : const [];
    return OrderDetailModel(
      id: (json['id'] ?? '').toString(),
      orderNumber:
          (json['orderNumber'] ?? json['order_number'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      organizationName: (organization['displayName'] ?? 'المورد').toString(),
      fulfillmentMethod: (json['fulfillmentMethod'] ?? '').toString(),
      paymentMethod: (json['paymentMethod'] ?? '').toString(),
      subtotal: _number(json['subtotalAmount']),
      deliveryFee: _number(json['deliveryFee']),
      total: _number(json['totalAmount']),
      currency: (json['currency'] ?? 'YER').toString(),
      items: rawItems
          .whereType<Map>()
          .map((item) =>
              OrderItemModel.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }

  static double _number(dynamic value) =>
      double.tryParse((value ?? 0).toString()) ?? 0;
}

class OrderItemModel {
  final String name;
  final int quantity;
  final double unitPrice;

  const OrderItemModel({
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      name: (json['productName'] ?? '').toString(),
      quantity: int.tryParse((json['quantity'] ?? 0).toString()) ?? 0,
      unitPrice: double.tryParse((json['unitPrice'] ?? 0).toString()) ?? 0,
    );
  }
}
