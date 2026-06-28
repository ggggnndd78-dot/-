import 'cart_item_model.dart';

class CartModel {
  final List<CartItemModel> items;
  final double subtotal;
  final String currency;

  const CartModel({
    this.items = const [],
    this.subtotal = 0,
    this.currency = 'YER',
  });

  factory CartModel.fromMap(Map<String, dynamic> map) {
    final items = (map['items'] as List<dynamic>? ?? [])
        .map((e) => CartItemModel.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
    return CartModel(
      items: items,
      subtotal: double.tryParse(
              (map['subtotal'] ?? map['subTotal'] ?? 0).toString()) ??
          0,
      currency: (map['currency'] ?? 'YER').toString(),
    );
  }

  factory CartModel.fromJson(Map<String, dynamic> map) =>
      CartModel.fromMap(map);

  Map<String, dynamic> toJson() => {
        'items': items.map((item) => item.toJson()).toList(),
        'subtotal': subtotal,
        'currency': currency,
      };
}
