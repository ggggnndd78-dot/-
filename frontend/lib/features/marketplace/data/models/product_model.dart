class ProductModel {
  final String id;
  final String name;
  final String? description;
  final String? sku;
  final String? oemNumber;
  final String? categoryId;
  final List<String> imageUrls;

  const ProductModel({
    required this.id,
    required this.name,
    this.description,
    this.sku,
    this.oemNumber,
    this.categoryId,
    this.imageUrls = const [],
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final media = json['media'] is List ? json['media'] as List : const [];
    return ProductModel(
      id: (json['id'] ?? json['publicId'] ?? '').toString(),
      name: (json['nameAr'] ?? json['nameEn'] ?? json['name'] ?? '').toString(),
      description: json['description']?.toString(),
      sku: json['sku']?.toString(),
      oemNumber: (json['oemNumber'] ?? json['oem_number'])?.toString(),
      categoryId: (json['categoryId'] ?? json['category_id'])?.toString(),
      imageUrls: media
          .whereType<Map>()
          .map((item) => item['mediaUrl'] ?? item['media_url'])
          .where((value) => value != null && value.toString().isNotEmpty)
          .map((value) => value.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'sku': sku,
        'oemNumber': oemNumber,
        'categoryId': categoryId,
        'imageUrls': imageUrls,
      };
}
