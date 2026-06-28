class MarketplaceProviderProfile {
  final String id;
  final String name;
  final String type;
  final String typeLabel;
  final String serviceLabel;
  final String? cityName;
  final String? districtName;
  final String? phone;
  final bool supportsDelivery;
  final bool supportsInstallation;
  final bool supportsPickup;
  final bool supportsEmergencyService;
  final int? averagePreparationMinutes;
  final int? capacityPerDay;
  final List<String> businessHours;

  const MarketplaceProviderProfile({
    required this.id,
    required this.name,
    required this.type,
    required this.typeLabel,
    required this.serviceLabel,
    this.cityName,
    this.districtName,
    this.phone,
    this.supportsDelivery = false,
    this.supportsInstallation = false,
    this.supportsPickup = false,
    this.supportsEmergencyService = false,
    this.averagePreparationMinutes,
    this.capacityPerDay,
    this.businessHours = const [],
  });

  factory MarketplaceProviderProfile.fallback({
    required String id,
    required String name,
    required String typeLabel,
    required String serviceLabel,
    String? cityName,
  }) {
    final type = typeLabel.contains('ورشة') ? 'WORKSHOP' : 'MERCHANT';
    return MarketplaceProviderProfile(
      id: id,
      name: name,
      type: type,
      typeLabel: typeLabel.isEmpty ? 'مزود' : typeLabel,
      serviceLabel: serviceLabel.isEmpty ? 'خدمة غير محددة' : serviceLabel,
      cityName: cityName,
      supportsDelivery: serviceLabel.contains('توصيل'),
      supportsInstallation:
          serviceLabel.contains('تركيب') || type == 'WORKSHOP',
    );
  }

  factory MarketplaceProviderProfile.fromMaps({
    required String id,
    required Map<String, dynamic> organization,
    required List<Map<String, dynamic>> branches,
    required List<Map<String, dynamic>> businessHours,
    Map<String, dynamic>? merchantProfile,
    Map<String, dynamic>? workshopProfile,
    MarketplaceProviderProfile? fallback,
  }) {
    final firstBranch =
        branches.isNotEmpty ? branches.first : const <String, dynamic>{};
    final type = (organization['organizationType'] ??
            organization['organization_type'] ??
            fallback?.type ??
            '')
        .toString()
        .toUpperCase();
    final isWorkshop = type == 'WORKSHOP';
    final name = (organization['displayName'] ??
            organization['display_name'] ??
            organization['legalName'] ??
            organization['legal_name'] ??
            fallback?.name ??
            '')
        .toString();
    final supportsDelivery = _bool(firstBranch, [
          'supportsDelivery',
          'supports_delivery',
        ]) ||
        (fallback?.supportsDelivery ?? false);
    final supportsInstallation = isWorkshop ||
        _bool(firstBranch, [
          'supportsInstallation',
          'supports_installation',
        ]) ||
        _bool(workshopProfile ?? const {}, [
          'acceptsInstallation',
          'accepts_installation',
        ]) ||
        (fallback?.supportsInstallation ?? false);

    return MarketplaceProviderProfile(
      id: id,
      name: name.isEmpty ? 'مزود غير محدد' : name,
      type: type,
      typeLabel: isWorkshop ? 'ورشة' : 'تاجر',
      serviceLabel: supportsInstallation
          ? 'توصيل + تركيب'
          : supportsDelivery
              ? 'توصيل فقط'
              : fallback?.serviceLabel ?? 'استلام من الفرع',
      cityName:
          _string(firstBranch, ['cityName', 'city_name']) ?? fallback?.cityName,
      districtName: _string(firstBranch, ['districtName', 'district_name']),
      phone: _string(firstBranch, ['phone', 'primaryPhone', 'primary_phone']) ??
          _string(organization, ['primaryPhone', 'primary_phone']),
      supportsDelivery: supportsDelivery,
      supportsInstallation: supportsInstallation,
      supportsPickup: _bool(firstBranch, ['supportsPickup', 'supports_pickup']),
      supportsEmergencyService: _bool(workshopProfile ?? const {}, [
        'supportsEmergencyService',
        'supports_emergency_service',
      ]),
      averagePreparationMinutes: _int(merchantProfile ?? const {}, [
        'averagePreparationMinutes',
        'average_preparation_minutes',
      ]),
      capacityPerDay: _int(workshopProfile ?? const {}, [
        'capacityPerDay',
        'capacity_per_day',
      ]),
      businessHours: businessHours.map(_formatBusinessHour).toList(),
    );
  }

  bool get isWorkshop => type == 'WORKSHOP';

  static String? _string(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return null;
  }

  static bool _bool(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value == true || value == 1 || value == 'true') return true;
    }
    return false;
  }

  static int? _int(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = int.tryParse((map[key] ?? '').toString());
      if (value != null) return value;
    }
    return null;
  }

  static String _formatBusinessHour(Map<String, dynamic> map) {
    final day =
        _string(map, ['dayName', 'day_name', 'dayOfWeek', 'day_of_week']) ??
            'يوم عمل';
    final open = _string(map, ['opensAt', 'opens_at', 'openTime', 'open_time']);
    final close =
        _string(map, ['closesAt', 'closes_at', 'closeTime', 'close_time']);
    if (open == null || close == null) return day;
    return '$day: $open - $close';
  }
}
