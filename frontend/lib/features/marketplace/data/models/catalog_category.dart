class CatalogCategory {
  final String id;
  final String name;
  final String? nameEn;
  final String slug;
  final String group;
  final String? description;
  final String? imageUrl;
  final List<CatalogCategory> children;
  final int listingCount;
  final int productCount;
  final int deliveryCount;
  final int workshopCount;
  final bool hasCompatibleListings;

  const CatalogCategory({
    required this.id,
    required this.name,
    this.nameEn,
    this.slug = '',
    this.group = '',
    this.description,
    this.imageUrl,
    this.children = const [],
    this.listingCount = 0,
    this.productCount = 0,
    this.deliveryCount = 0,
    this.workshopCount = 0,
    this.hasCompatibleListings = false,
  });

  factory CatalogCategory.fromJson(Map<String, dynamic> json) {
    final rawChildren =
        json['children'] is List ? json['children'] as List : const [];
    return CatalogCategory(
      id: (json['id'] ?? json['publicId'] ?? json['public_id'] ?? '')
          .toString(),
      name:
          (json['nameAr'] ?? json['name_ar'] ?? json['name'] ?? '').toString(),
      nameEn: (json['nameEn'] ?? json['name_en'])?.toString(),
      slug: (json['slug'] ?? json['code'] ?? '').toString(),
      group: (json['group'] ?? json['groupCode'] ?? json['group_code'] ?? '')
          .toString(),
      description: (json['description'] ??
              json['descriptionAr'] ??
              json['description_ar'])
          ?.toString(),
      imageUrl: json['iconUrl']?.toString() ??
          json['icon_url']?.toString() ??
          json['imageUrl']?.toString() ??
          json['image_url']?.toString(),
      children: rawChildren
          .whereType<Map>()
          .map((item) =>
              CatalogCategory.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      listingCount: _int(json['listingCount'] ??
          json['listing_count'] ??
          json['totalListings'] ??
          json['total_listings']),
      productCount: _int(json['productCount'] ?? json['product_count']),
      deliveryCount: _int(json['deliveryCount'] ?? json['delivery_count']),
      workshopCount: _int(json['workshopCount'] ?? json['workshop_count']),
      hasCompatibleListings: json['hasCompatibleListings'] == true ||
          json['has_compatible_listings'] == true,
    );
  }

  factory CatalogCategory.fromMap(Map<String, dynamic> map) =>
      CatalogCategory.fromJson(map);

  int get totalChildrenListings =>
      listingCount +
      children.fold<int>(
          0,
          (sum, child) =>
              sum + child.listingCount + child.totalChildrenListings);
  bool get hasActiveListings =>
      listingCount > 0 ||
      totalChildrenListings > 0 ||
      productCount > 0 ||
      deliveryCount > 0 ||
      workshopCount > 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'nameEn': nameEn,
        'slug': slug,
        'group': group,
        'description': description,
        'imageUrl': imageUrl,
        'children': children.map((child) => child.toJson()).toList(),
        'listingCount': listingCount,
        'productCount': productCount,
        'deliveryCount': deliveryCount,
        'workshopCount': workshopCount,
        'hasCompatibleListings': hasCompatibleListings,
      };

  static int _int(dynamic value) => int.tryParse((value ?? 0).toString()) ?? 0;
}
