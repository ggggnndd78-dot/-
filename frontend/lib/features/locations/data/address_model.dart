class AddressModel {
  final String id;
  final String label;
  final String recipientName;
  final String phone;
  final int cityId;
  final String cityName;
  final int? districtId;
  final String? districtName;
  final String addressLine1;
  final String? addressLine2;
  final bool isDefault;

  const AddressModel({
    required this.id,
    required this.label,
    required this.recipientName,
    required this.phone,
    required this.cityId,
    required this.cityName,
    this.districtId,
    this.districtName,
    required this.addressLine1,
    this.addressLine2,
    required this.isDefault,
  });

  static int _intValue(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _nullableIntValue(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    final city = Map<String, dynamic>.from((json['city'] as Map?) ?? {});
    final district =
        Map<String, dynamic>.from((json['district'] as Map?) ?? {});
    return AddressModel(
      id: (json['publicId'] ?? json['public_id'] ?? json['id'] ?? '')
          .toString(),
      label: (json['label'] ?? '').toString(),
      recipientName:
          (json['recipientName'] ?? json['recipient_name'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      cityId: _intValue(json['cityId'] ?? json['city_id']),
      cityName: (city['nameAr'] ?? city['name_ar'] ?? '').toString(),
      districtId: _nullableIntValue(json['districtId'] ?? json['district_id']),
      districtName: (district['nameAr'] ?? district['name_ar'])?.toString(),
      addressLine1:
          (json['addressLine1'] ?? json['address_line_1'] ?? '').toString(),
      addressLine2:
          (json['addressLine2'] ?? json['address_line_2'])?.toString(),
      isDefault: json['isDefault'] == true || json['is_default'] == true,
    );
  }
}
