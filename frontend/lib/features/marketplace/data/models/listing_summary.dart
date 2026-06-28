class ListingSummary {
  final String id;
  final String title;
  final String providerName;
  final String providerId;
  final String providerType;
  final double price;
  final double? salePrice;
  final String currency;
  final String? qualityLevel;
  final String? condition;
  final bool supportsInstallation;
  final bool supportsDelivery;
  final bool supportsPickup;
  final String? cityName;
  final String? imageUrl;
  final int availableQuantity;
  final int? warrantyDays;
  final int minOrderQuantity;
  final String? brandName;
  final String? oemNumber;
  final bool? isFavorite;

  const ListingSummary({
    required this.id,
    required this.title,
    required this.providerName,
    this.providerId = '',
    this.providerType = 'MERCHANT',
    required this.price,
    this.salePrice,
    required this.currency,
    this.qualityLevel,
    this.condition,
    this.supportsInstallation = false,
    this.supportsDelivery = false,
    this.supportsPickup = true,
    this.cityName,
    this.imageUrl,
    this.availableQuantity = 0,
    this.warrantyDays,
    this.minOrderQuantity = 1,
    this.brandName,
    this.oemNumber,
    this.isFavorite,
  });

  factory ListingSummary.fromJson(Map<String, dynamic> json) {
    final organization = _map(json['organization']);
    final city = _map(json['city']);
    final product = _map(json['product']);
    final brand = _map(product['brand'] ?? json['brand'] ?? json['partBrand']);
    final media =
        product['media'] is List ? product['media'] as List : const [];
    final mediaMaps = media.whereType<Map>();
    final firstMedia = mediaMaps.isEmpty ? null : mediaMaps.first;
    final unitPriceValue = json['unitPrice'] ??
        json['unit_price'] ??
        json['price'] ??
        json['selling_price'] ??
        0;
    final salePriceValue = json['salePrice'] ?? json['sale_price'];
    final providerTypeValue = (json['providerType'] ??
            json['provider_type'] ??
            organization['organization_type'] ??
            organization['type'] ??
            'MERCHANT')
        .toString()
        .toUpperCase();

    return ListingSummary(
      id: (json['id'] ?? json['publicId'] ?? json['public_id'] ?? '')
          .toString(),
      title: (json['title'] ??
              product['nameAr'] ??
              product['name_ar'] ??
              product['name'] ??
              json['productName'] ??
              json['product_name'] ??
              'Listing')
          .toString(),
      providerName: (json['providerName'] ??
              organization['displayName'] ??
              organization['display_name'] ??
              json['organizationName'] ??
              json['organization_name'] ??
              json['seller'] ??
              'Provider')
          .toString(),
      providerId: (json['providerId'] ??
              json['provider_id'] ??
              organization['id'] ??
              organization['publicId'] ??
              organization['public_id'] ??
              '')
          .toString(),
      providerType: providerTypeValue,
      price: double.tryParse(unitPriceValue.toString()) ?? 0,
      salePrice: salePriceValue == null
          ? null
          : double.tryParse(salePriceValue.toString()),
      currency: (json['currency'] ?? 'YER').toString(),
      qualityLevel: (json['qualityLevelName'] ??
              json['quality_level_name'] ??
              json['qualityLevel'] ??
              json['quality_type'])
          ?.toString(),
      condition: (json['condition'] ?? product['condition'])?.toString(),
      supportsInstallation: json['supportsInstallation'] == true ||
          json['supports_installation'] == true,
      supportsDelivery:
          json['supportsDelivery'] == true || json['supports_delivery'] == true,
      supportsPickup:
          json['supportsPickup'] != false && json['supports_pickup'] != false,
      cityName: json['cityName']?.toString() ??
          json['city_name']?.toString() ??
          (json['city'] is String ? json['city']?.toString() : null) ??
          city['nameAr']?.toString() ??
          city['name_ar']?.toString(),
      imageUrl: json['imageUrl']?.toString() ??
          json['image_url']?.toString() ??
          json['media_url']?.toString() ??
          firstMedia?['mediaUrl']?.toString() ??
          firstMedia?['media_url']?.toString(),
      availableQuantity: _int(json['availableQuantity'] ??
          json['available_quantity'] ??
          json['quantity'] ??
          json['stockQuantity']),
      warrantyDays: _nullableInt(json['warrantyDays'] ?? json['warranty_days']),
      minOrderQuantity: _int(
          json['minOrderQuantity'] ?? json['min_order_quantity'] ?? 1,
          fallback: 1),
      brandName: (json['brandName'] ??
              json['brand_name'] ??
              brand['nameAr'] ??
              brand['name_ar'] ??
              brand['name'])
          ?.toString(),
      oemNumber: (json['oemNumber'] ??
              json['oem_number'] ??
              product['oemNumber'] ??
              product['oem_number'] ??
              product['partNumber'] ??
              product['part_number'])
          ?.toString(),
      isFavorite: json['isFavorite'] == null && json['is_favorite'] == null
          ? null
          : (json['isFavorite'] == true || json['is_favorite'] == true),
    );
  }

  factory ListingSummary.fromMap(Map<String, dynamic> map) =>
      ListingSummary.fromJson(map);

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'providerName': providerName,
        'providerId': providerId,
        'providerType': providerType,
        'price': price,
        'salePrice': salePrice,
        'currency': currency,
        'qualityLevel': qualityLevel,
        'condition': condition,
        'supportsInstallation': supportsInstallation,
        'supportsDelivery': supportsDelivery,
        'supportsPickup': supportsPickup,
        'cityName': cityName,
        'imageUrl': imageUrl,
        'availableQuantity': availableQuantity,
        'warrantyDays': warrantyDays,
        'minOrderQuantity': minOrderQuantity,
        'brandName': brandName,
        'oemNumber': oemNumber,
        'isFavorite': isFavorite,
      };

  bool get hasSale => salePrice != null && salePrice! > 0 && salePrice! < price;
  double get effectivePrice => hasSale ? salePrice! : price;
  bool get inStock => availableQuantity > 0;
  bool get hasWarranty => (warrantyDays ?? 0) > 0;
  String get providerTypeLabel => providerType == 'WORKSHOP'
      ? 'ورشة'
      : providerType == 'DELIVERY'
          ? 'توصيل'
          : 'تاجر';
  String get serviceLabel {
    final services = <String>[];
    if (supportsPickup) services.add('استلام');
    if (supportsDelivery) services.add('توصيل');
    if (supportsInstallation) services.add('تركيب');
    return services.isEmpty ? providerTypeLabel : services.join(' / ');
  }

  String get warrantyLabel =>
      hasWarranty ? '${warrantyDays!} يوم ضمان' : 'بدون ضمان معلن';
  String get conditionLabel {
    switch ((condition ?? '').toUpperCase()) {
      case 'NEW':
        return 'جديد';
      case 'USED':
        return 'مستخدم';
      case 'REFURBISHED':
        return 'مجدد';
      default:
        return (condition ?? '').isEmpty ? 'غير محدد' : condition!;
    }
  }

  static int _int(dynamic value, {int fallback = 0}) =>
      int.tryParse((value ?? fallback).toString()) ?? fallback;
  static int? _nullableInt(dynamic value) =>
      value == null ? null : int.tryParse(value.toString());
  static Map<String, dynamic> _map(dynamic value) => value is Map
      ? Map<String, dynamic>.from(value)
      : const <String, dynamic>{};
}
