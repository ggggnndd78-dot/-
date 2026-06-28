class CustomerAddressModel {
  final String id;
  final String label;
  final String recipientName;
  final String phone;
  final String alternativePhone;
  final int? cityId;
  final int? districtId;
  final int? areaId;
  final String cityName;
  final String districtName;
  final String areaName;
  final String addressLine1;
  final String addressLine2;
  final String landmark;
  final String deliveryNotes;
  final double? latitude;
  final double? longitude;
  final bool isDefault;
  final bool isDeliveryAvailable;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CustomerAddressModel({
    required this.id,
    required this.label,
    required this.recipientName,
    required this.phone,
    this.alternativePhone = '',
    this.cityId,
    this.districtId,
    this.areaId,
    this.cityName = '',
    this.districtName = '',
    this.areaName = '',
    required this.addressLine1,
    this.addressLine2 = '',
    this.landmark = '',
    this.deliveryNotes = '',
    this.latitude,
    this.longitude,
    this.isDefault = false,
    this.isDeliveryAvailable = true,
    this.createdAt,
    this.updatedAt,
  });

  factory CustomerAddressModel.empty() => const CustomerAddressModel(
        id: '',
        label: 'المنزل',
        recipientName: '',
        phone: '',
        addressLine1: '',
      );

  factory CustomerAddressModel.fromApi(Map<String, dynamic> json) {
    return CustomerAddressModel(
      id: _text(json['id'] ?? json['public_id'] ?? json['publicId']),
      label: _text(json['label'], fallback: 'عنوان'),
      recipientName: _text(json['recipient_name'] ?? json['recipientName']),
      phone: _text(json['phone']),
      alternativePhone:
          _text(json['alternative_phone'] ?? json['alternativePhone']),
      cityId: _int(json['city_id'] ?? json['cityId']),
      districtId: _int(json['district_id'] ?? json['districtId']),
      areaId: _int(json['area_id'] ?? json['areaId']),
      cityName: _text(json['city_name'] ?? json['cityName']),
      districtName: _text(json['district_name'] ?? json['districtName']),
      areaName: _text(json['area_name'] ?? json['areaName']),
      addressLine1: _text(json['address_line_1'] ?? json['addressLine1']),
      addressLine2: _text(json['address_line_2'] ?? json['addressLine2']),
      landmark: _text(json['landmark']),
      deliveryNotes: _text(json['delivery_notes'] ?? json['deliveryNotes']),
      latitude: _double(json['latitude']),
      longitude: _double(json['longitude']),
      isDefault: _bool(json['is_default'] ?? json['isDefault']),
      isDeliveryAvailable: _bool(
          json['is_delivery_available'] ?? json['isDeliveryAvailable'],
          fallback: true),
      createdAt: _date(json['created_at'] ?? json['createdAt']),
      updatedAt: _date(json['updated_at'] ?? json['updatedAt']),
    );
  }

  String get locationLabel => [cityName, districtName, areaName]
      .where((e) => e.trim().isNotEmpty)
      .join(' - ');

  String get fullAddress => [addressLine1, addressLine2, landmark]
      .where((e) => e.trim().isNotEmpty)
      .join('، ');

  bool get hasCoordinates => latitude != null && longitude != null;

  static String _text(Object? value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static int? _int(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static double? _double(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static bool _bool(Object? value, {bool fallback = false}) {
    if (value == null) return fallback;
    if (value is bool) return value;
    final text = value.toString().toLowerCase();
    return text == '1' || text == 'true' || text == 'yes';
  }

  static DateTime? _date(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}

class CustomerAddressPayload {
  final String label;
  final String recipientName;
  final String phone;
  final String alternativePhone;
  final int cityId;
  final int? districtId;
  final int? areaId;
  final String addressLine1;
  final String addressLine2;
  final String landmark;
  final String deliveryNotes;
  final double? latitude;
  final double? longitude;
  final bool isDefault;

  const CustomerAddressPayload({
    required this.label,
    required this.recipientName,
    required this.phone,
    this.alternativePhone = '',
    required this.cityId,
    this.districtId,
    this.areaId,
    required this.addressLine1,
    this.addressLine2 = '',
    this.landmark = '',
    this.deliveryNotes = '',
    this.latitude,
    this.longitude,
    this.isDefault = false,
  });

  Map<String, dynamic> toApi() => {
        'label': label.trim(),
        'recipientName': recipientName.trim(),
        'phone': phone.trim(),
        'alternativePhone':
            alternativePhone.trim().isEmpty ? null : alternativePhone.trim(),
        'cityId': cityId,
        'districtId': districtId,
        'areaId': areaId,
        'addressLine1': addressLine1.trim(),
        'addressLine2':
            addressLine2.trim().isEmpty ? null : addressLine2.trim(),
        'landmark': landmark.trim().isEmpty ? null : landmark.trim(),
        'deliveryNotes':
            deliveryNotes.trim().isEmpty ? null : deliveryNotes.trim(),
        'latitude': latitude,
        'longitude': longitude,
        'isDefault': isDefault,
      };
}
