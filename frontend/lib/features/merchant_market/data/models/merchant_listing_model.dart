class MerchantListingModel {
  final String id;
  final String title;
  final String status;
  final String approvalStatus;
  final String? approvalRejectionReason;
  final String? description;
  final double price;
  final double? salePrice;
  final String currency;
  final int stock;
  final int reservedStock;
  final int minOrderQuantity;
  final int? warrantyDays;
  final String condition;
  final bool supportsPickup;
  final bool supportsDelivery;
  final String? sku;
  final String? productId;
  final String? categoryId;
  final String? categoryName;
  final String? partBrandName;
  final String? branchId;
  final String? branchName;
  final String? cityName;
  final String? partNumber;
  final String? compatibility;
  final String? imageUrl;
  final List<String> imageUrls;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? publishedAt;

  const MerchantListingModel({
    required this.id,
    required this.title,
    required this.status,
    required this.price,
    required this.stock,
    this.salePrice,
    this.currency = 'YER',
    this.reservedStock = 0,
    this.minOrderQuantity = 1,
    this.warrantyDays,
    this.condition = 'NEW',
    this.supportsPickup = true,
    this.supportsDelivery = false,
    this.sku,
    this.productId,
    this.categoryId,
    this.categoryName,
    this.partBrandName,
    this.branchId,
    this.branchName,
    this.cityName,
    this.partNumber,
    this.compatibility,
    this.imageUrl,
    this.imageUrls = const [],
    this.approvalStatus = '',
    this.approvalRejectionReason,
    this.description,
    this.createdAt,
    this.updatedAt,
    this.publishedAt,
  });

  factory MerchantListingModel.fromMap(Map<String, dynamic> map) {
    final product = map['product'];
    final productMap = product is Map ? product : const <String, dynamic>{};
    final category = productMap['category'];
    final categoryMap = category is Map ? category : const <String, dynamic>{};
    final partBrand = productMap['partBrand'];
    final partBrandMap =
        partBrand is Map ? partBrand : const <String, dynamic>{};
    final branch = map['branch'];
    final branchMap = branch is Map ? branch : const <String, dynamic>{};
    final city = map['city'];
    final cityMap = city is Map ? city : const <String, dynamic>{};
    final images = _imageUrls(map);

    return MerchantListingModel(
      id: (map['id'] ?? map['publicId'] ?? '').toString(),
      title: (map['title'] ??
              map['productName'] ??
              productMap['nameAr'] ??
              productMap['name_ar'] ??
              productMap['name'] ??
              'عرض')
          .toString(),
      status: (map['status'] ?? '').toString(),
      approvalStatus:
          (map['approvalStatus'] ?? map['approval_status'] ?? '').toString(),
      approvalRejectionReason: (map['approvalRejectionReason'] ??
              map['approval_rejection_reason'] ??
              map['rejectionReason'] ??
              map['rejection_reason'])
          ?.toString(),
      description:
          (map['description'] ?? productMap['description'])?.toString(),
      price: double.tryParse(
              (map['unitPrice'] ?? map['unit_price'] ?? map['price'] ?? 0)
                  .toString()) ??
          0,
      salePrice: _nullableDouble(map['salePrice'] ?? map['sale_price']),
      currency: (map['currency'] ?? 'YER').toString(),
      stock: int.tryParse((map['availableQuantity'] ??
                  map['available_quantity'] ??
                  map['availableStock'] ??
                  map['stock'] ??
                  0)
              .toString()) ??
          0,
      reservedStock: int.tryParse((map['reservedQuantity'] ??
                  map['reserved_quantity'] ??
                  map['reservedStock'] ??
                  0)
              .toString()) ??
          0,
      minOrderQuantity: int.tryParse(
              (map['minOrderQuantity'] ?? map['min_order_quantity'] ?? 1)
                  .toString()) ??
          1,
      warrantyDays: int.tryParse(
          (map['warrantyDays'] ?? map['warranty_days'] ?? '').toString()),
      condition: (map['condition'] ?? 'NEW').toString(),
      supportsPickup: _bool(map['supportsPickup'] ?? map['supports_pickup'],
          fallback: true),
      supportsDelivery:
          _bool(map['supportsDelivery'] ?? map['supports_delivery']),
      sku: (map['sku'] ?? productMap['sku'])?.toString(),
      productId: (map['productId'] ?? map['product_id'] ?? productMap['id'])
          ?.toString(),
      categoryId: (map['categoryId'] ?? map['category_id'] ?? categoryMap['id'])
          ?.toString(),
      categoryName: (map['categoryName'] ??
              map['category_name'] ??
              categoryMap['nameAr'] ??
              categoryMap['name_ar'] ??
              categoryMap['name'])
          ?.toString(),
      partBrandName: (map['partBrandName'] ??
              map['part_brand_name'] ??
              partBrandMap['nameAr'] ??
              partBrandMap['name_ar'] ??
              partBrandMap['name'])
          ?.toString(),
      branchId:
          (map['branchId'] ?? map['branch_id'] ?? branchMap['id'])?.toString(),
      branchName: (map['branchName'] ??
              map['branch_name'] ??
              branchMap['name'] ??
              branchMap['branchName'] ??
              branchMap['branch_name'])
          ?.toString(),
      cityName: (map['cityName'] ??
              map['city_name'] ??
              cityMap['nameAr'] ??
              cityMap['name_ar'] ??
              cityMap['name'])
          ?.toString(),
      partNumber: (map['partNumber'] ??
              map['part_number'] ??
              productMap['oemNumber'] ??
              productMap['oem_number'] ??
              productMap['aftermarketCode'] ??
              productMap['aftermarket_code'])
          ?.toString(),
      compatibility: (map['compatibility'] ??
              map['compatibility_text'] ??
              productMap['compatibility'] ??
              productMap['compatibilityText'] ??
              productMap['compatibility_text'])
          ?.toString(),
      imageUrl: images.isNotEmpty ? images.first : null,
      imageUrls: images,
      createdAt: _date(map['createdAt'] ?? map['created_at']),
      updatedAt: _date(map['updatedAt'] ?? map['updated_at']),
      publishedAt: _date(map['publishedAt'] ?? map['published_at']),
    );
  }

  bool get isPublished => status.toUpperCase() == 'ACTIVE';
  bool get isLowStock => stock <= 5;
  bool get hasSale => salePrice != null && salePrice! > 0 && salePrice! < price;
  int get availableAfterReservation => stock - reservedStock;

  static double? _nullableDouble(Object? value) {
    if (value == null || value.toString().trim().isEmpty) return null;
    return double.tryParse(value.toString());
  }

  static bool _bool(Object? value, {bool fallback = false}) {
    if (value == null) return fallback;
    final text = value.toString().toLowerCase();
    return text == 'true' || text == '1' || text == 'yes';
  }

  static DateTime? _date(Object? value) {
    if (value == null || value.toString().isEmpty) return null;
    return DateTime.tryParse(value.toString());
  }

  static List<String> _imageUrls(Map<String, dynamic> map) {
    final result = <String>[];
    void add(Object? value) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty && !result.contains(text)) result.add(text);
    }

    add(map['imageUrl'] ?? map['image_url']);
    final product = map['product'];
    if (product is Map) {
      final media = product['media'];
      if (media is List) {
        final sorted = media.whereType<Map>().toList()
          ..sort((a, b) => (int.tryParse(
                      (a['sortOrder'] ?? a['sort_order'] ?? 0).toString()) ??
                  0)
              .compareTo(int.tryParse(
                      (b['sortOrder'] ?? b['sort_order'] ?? 0).toString()) ??
                  0));
        for (final item in sorted) {
          add(item['mediaUrl'] ??
              item['media_url'] ??
              item['url'] ??
              item['fileUrl'] ??
              item['file_url']);
        }
      }
    }
    final imageUrls = map['imageUrls'] ?? map['image_urls'];
    if (imageUrls is List) {
      for (final value in imageUrls) {
        add(value);
      }
    }
    return result;
  }
}
