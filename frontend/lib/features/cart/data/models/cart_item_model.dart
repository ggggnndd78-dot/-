class CartItemModel {
  final String id;
  final String listingId;
  final String title;
  final double unitPrice;
  final int quantity;
  final String currency;

  const CartItemModel({
    required this.id,
    required this.listingId,
    required this.title,
    required this.unitPrice,
    required this.quantity,
    required this.currency,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    final listing = json['listing'] is Map
        ? Map<String, dynamic>.from(json['listing'] as Map)
        : const <String, dynamic>{};
    final price = listing['salePrice'] ??
        listing['unitPrice'] ??
        json['unitPrice'] ??
        json['unit_price'] ??
        0;

    return CartItemModel(
      id: (json['id'] ?? '').toString(),
      listingId:
          (json['listingId'] ?? json['listing_id'] ?? listing['id'] ?? '')
              .toString(),
      title: (json['title'] ??
              listing['title'] ??
              json['listingTitle'] ??
              json['listing_title'] ??
              'Item')
          .toString(),
      unitPrice: double.tryParse(price.toString()) ?? 0,
      quantity: int.tryParse((json['quantity'] ?? 0).toString()) ?? 0,
      currency: (json['currency'] ?? listing['currency'] ?? 'YER').toString(),
    );
  }

  factory CartItemModel.fromMap(Map<String, dynamic> map) =>
      CartItemModel.fromJson(map);

  Map<String, dynamic> toJson() => {
        'id': id,
        'listingId': listingId,
        'title': title,
        'unitPrice': unitPrice,
        'quantity': quantity,
        'currency': currency,
      };
}
