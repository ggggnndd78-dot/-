class MerchantListingModel {
  final String id;
  final String title;
  final String status;
  final double price;
  final int stock;

  const MerchantListingModel({
    required this.id,
    required this.title,
    required this.status,
    required this.price,
    required this.stock,
  });

  factory MerchantListingModel.fromMap(Map<String, dynamic> map) {
    return MerchantListingModel(
      id: map['id'].toString(),
      title: (map['title'] ?? map['productName'] ?? 'عرض').toString(),
      status: (map['status'] ?? '').toString(),
      price:
          double.tryParse((map['price'] ?? map['unitPrice'] ?? 0).toString()) ??
              0,
      stock: int.tryParse(
              (map['stock'] ?? map['availableStock'] ?? 0).toString()) ??
          0,
    );
  }
}
