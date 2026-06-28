class CustomerProfileModel {
  final String id;
  final String displayName;
  final String phone;
  final String email;
  final String status;
  final bool isPhoneVerified;
  final bool isEmailVerified;
  final String locale;
  final String avatarUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletionRequestedAt;
  final String deletionReason;
  final CustomerLocationInfo location;
  final List<CustomerOrganizationInfo> organizations;
  final List<CustomerVehicleInfo> vehicles;

  const CustomerProfileModel({
    required this.id,
    required this.displayName,
    required this.phone,
    required this.email,
    required this.status,
    required this.isPhoneVerified,
    required this.isEmailVerified,
    required this.locale,
    required this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.deletionRequestedAt,
    required this.deletionReason,
    required this.location,
    required this.organizations,
    required this.vehicles,
  });

  factory CustomerProfileModel.fromApi(Map<String, dynamic> data) {
    final user = _map(data['user']);
    final profile = _map(data['profile']);
    return CustomerProfileModel(
      id: _text(user['id']),
      displayName: _firstText([
        profile['display_name'],
        profile['displayName'],
        user['display_name'],
        user['displayName'],
      ]),
      phone: _firstText([user['phone'], user['phone_normalized']]),
      email: _firstText([user['email']]),
      status: _firstText([user['status']], fallback: 'ACTIVE'),
      isPhoneVerified: _bool(user['is_phone_verified']),
      isEmailVerified: _bool(user['is_email_verified']),
      locale: _firstText([user['locale']], fallback: 'ar'),
      avatarUrl: _firstText([profile['avatar_url'], profile['avatarUrl']]),
      createdAt: _date(user['created_at'] ?? user['createdAt']),
      updatedAt: _date(user['updated_at'] ?? user['updatedAt']),
      deletionRequestedAt: _date(
          profile['deletion_requested_at'] ?? profile['deletionRequestedAt']),
      deletionReason: _firstText([
        profile['deletion_reason'],
        profile['deletionReason'],
      ]),
      location: CustomerLocationInfo.fromApi(profile),
      organizations: _list(data['organizations'])
          .map((item) => CustomerOrganizationInfo.fromApi(_map(item)))
          .toList(),
      vehicles: _list(data['vehicles'])
          .map((item) => CustomerVehicleInfo.fromApi(_map(item)))
          .toList(),
    );
  }

  String get displayInitial {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) return 'غ';
    return trimmed.substring(0, 1);
  }

  bool get hasDeletionRequest => deletionRequestedAt != null;

  String get accountStatusLabel {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return 'نشط';
      case 'BLOCKED':
        return 'موقوف';
      default:
        return status;
    }
  }
}

class CustomerLocationInfo {
  final int? cityId;
  final int? districtId;
  final int? areaId;
  final String cityName;
  final String districtName;
  final String areaName;

  const CustomerLocationInfo({
    required this.cityId,
    required this.districtId,
    required this.areaId,
    required this.cityName,
    required this.districtName,
    required this.areaName,
  });

  factory CustomerLocationInfo.fromApi(Map<String, dynamic> data) {
    return CustomerLocationInfo(
      cityId: _int(data['city_id'] ?? data['cityId']),
      districtId: _int(data['district_id'] ?? data['districtId']),
      areaId: _int(data['area_id'] ?? data['areaId']),
      cityName: _firstText([data['city_name'], data['cityName']]),
      districtName: _firstText([data['district_name'], data['districtName']]),
      areaName: _firstText([data['area_name'], data['areaName']]),
    );
  }

  String get label {
    final parts = [cityName, districtName, areaName]
        .where((part) => part.trim().isNotEmpty)
        .toList();
    return parts.isEmpty ? 'غير محدد' : parts.join('، ');
  }
}

class CustomerOrganizationInfo {
  final String id;
  final String type;
  final String name;
  final String role;
  final String status;
  final bool isVerified;

  const CustomerOrganizationInfo({
    required this.id,
    required this.type,
    required this.name,
    required this.role,
    required this.status,
    required this.isVerified,
  });

  factory CustomerOrganizationInfo.fromApi(Map<String, dynamic> data) {
    return CustomerOrganizationInfo(
      id: _text(data['id']),
      type: _text(data['type']),
      name: _text(data['name']),
      role: _text(data['role']),
      status: _text(data['status']),
      isVerified: _bool(data['is_verified'] ?? data['isVerified']),
    );
  }
}

class CustomerVehicleInfo {
  final String id;
  final String makeName;
  final String modelName;
  final String variantName;
  final int? yearValue;
  final bool isDefault;

  const CustomerVehicleInfo({
    required this.id,
    required this.makeName,
    required this.modelName,
    required this.variantName,
    required this.yearValue,
    required this.isDefault,
  });

  factory CustomerVehicleInfo.fromApi(Map<String, dynamic> data) {
    return CustomerVehicleInfo(
      id: _text(data['id']),
      makeName: _firstText([data['make_name'], data['makeName']]),
      modelName: _firstText([data['model_name'], data['modelName']]),
      variantName: _firstText([data['variant_name'], data['variantName']]),
      yearValue: _int(data['year_value'] ?? data['yearValue']),
      isDefault: _bool(data['is_default'] ?? data['isDefault']),
    );
  }

  String get label {
    final parts = [makeName, modelName, variantName]
        .where((part) => part.trim().isNotEmpty)
        .toList();
    final base = parts.isEmpty ? 'مركبة بدون اسم' : parts.join(' ');
    return yearValue == null ? base : '$base • $yearValue';
  }
}

Map<String, dynamic> _map(Object? value) {
  return value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
}

List<dynamic> _list(Object? value) => value is List ? value : const [];

String _text(Object? value) => value?.toString().trim() ?? '';

String _firstText(List<Object?> values, {String fallback = ''}) {
  for (final value in values) {
    final text = _text(value);
    if (text.isNotEmpty) return text;
  }
  return fallback;
}

bool _bool(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value?.toString().toLowerCase().trim();
  return text == 'true' || text == '1' || text == 'yes';
}

int? _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

DateTime? _date(Object? value) {
  final text = value?.toString();
  if (text == null || text.isEmpty) return null;
  return DateTime.tryParse(text);
}
