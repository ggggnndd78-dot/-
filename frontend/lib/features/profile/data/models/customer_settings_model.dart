class CustomerSettingsModel {
  final String locale;
  final String themeMode;
  final String privacyLevel;
  final bool pushEnabled;
  final bool emailEnabled;
  final bool smsEnabled;
  final bool orderUpdates;
  final bool chatMessages;
  final bool promotions;
  final bool walletUpdates;
  final bool returnsDisputes;
  final bool showPhoneToMerchants;
  final bool allowPersonalizedOffers;
  final bool requireLoginConfirmation;
  final DateTime? updatedAt;
  final List<CustomerSessionModel> sessions;

  const CustomerSettingsModel({
    required this.locale,
    required this.themeMode,
    required this.privacyLevel,
    required this.pushEnabled,
    required this.emailEnabled,
    required this.smsEnabled,
    required this.orderUpdates,
    required this.chatMessages,
    required this.promotions,
    required this.walletUpdates,
    required this.returnsDisputes,
    required this.showPhoneToMerchants,
    required this.allowPersonalizedOffers,
    required this.requireLoginConfirmation,
    required this.updatedAt,
    required this.sessions,
  });

  factory CustomerSettingsModel.fromApi(Map<String, dynamic> data) {
    final settings = _map(data['settings'] ?? data);
    final list = data['sessions'] is List ? data['sessions'] as List : const [];
    return CustomerSettingsModel(
      locale: _text(settings['locale'], fallback: 'ar'),
      themeMode: _text(settings['theme_mode'] ?? settings['themeMode'],
          fallback: 'system'),
      privacyLevel: _text(settings['privacy_level'] ?? settings['privacyLevel'],
          fallback: 'balanced'),
      pushEnabled: _bool(settings['push_enabled'] ?? settings['pushEnabled'],
          fallback: true),
      emailEnabled: _bool(settings['email_enabled'] ?? settings['emailEnabled'],
          fallback: true),
      smsEnabled: _bool(settings['sms_enabled'] ?? settings['smsEnabled'],
          fallback: false),
      orderUpdates: _bool(settings['order_updates'] ?? settings['orderUpdates'],
          fallback: true),
      chatMessages: _bool(settings['chat_messages'] ?? settings['chatMessages'],
          fallback: true),
      promotions: _bool(settings['promotions'], fallback: true),
      walletUpdates: _bool(
          settings['wallet_updates'] ?? settings['walletUpdates'],
          fallback: true),
      returnsDisputes: _bool(
          settings['returns_disputes'] ?? settings['returnsDisputes'],
          fallback: true),
      showPhoneToMerchants: _bool(
          settings['show_phone_to_merchants'] ??
              settings['showPhoneToMerchants'],
          fallback: true),
      allowPersonalizedOffers: _bool(
          settings['allow_personalized_offers'] ??
              settings['allowPersonalizedOffers'],
          fallback: true),
      requireLoginConfirmation: _bool(
          settings['require_login_confirmation'] ??
              settings['requireLoginConfirmation'],
          fallback: false),
      updatedAt: _date(settings['updated_at'] ?? settings['updatedAt']),
      sessions: list
          .whereType<Map>()
          .map((item) =>
              CustomerSessionModel.fromApi(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }

  Map<String, dynamic> toApi() => {
        'locale': locale,
        'themeMode': themeMode,
        'privacyLevel': privacyLevel,
        'pushEnabled': pushEnabled,
        'emailEnabled': emailEnabled,
        'smsEnabled': smsEnabled,
        'orderUpdates': orderUpdates,
        'chatMessages': chatMessages,
        'promotions': promotions,
        'walletUpdates': walletUpdates,
        'returnsDisputes': returnsDisputes,
        'showPhoneToMerchants': showPhoneToMerchants,
        'allowPersonalizedOffers': allowPersonalizedOffers,
        'requireLoginConfirmation': requireLoginConfirmation,
      };

  CustomerSettingsModel copyWith({
    String? locale,
    String? themeMode,
    String? privacyLevel,
    bool? pushEnabled,
    bool? emailEnabled,
    bool? smsEnabled,
    bool? orderUpdates,
    bool? chatMessages,
    bool? promotions,
    bool? walletUpdates,
    bool? returnsDisputes,
    bool? showPhoneToMerchants,
    bool? allowPersonalizedOffers,
    bool? requireLoginConfirmation,
    DateTime? updatedAt,
    List<CustomerSessionModel>? sessions,
  }) {
    return CustomerSettingsModel(
      locale: locale ?? this.locale,
      themeMode: themeMode ?? this.themeMode,
      privacyLevel: privacyLevel ?? this.privacyLevel,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      smsEnabled: smsEnabled ?? this.smsEnabled,
      orderUpdates: orderUpdates ?? this.orderUpdates,
      chatMessages: chatMessages ?? this.chatMessages,
      promotions: promotions ?? this.promotions,
      walletUpdates: walletUpdates ?? this.walletUpdates,
      returnsDisputes: returnsDisputes ?? this.returnsDisputes,
      showPhoneToMerchants: showPhoneToMerchants ?? this.showPhoneToMerchants,
      allowPersonalizedOffers:
          allowPersonalizedOffers ?? this.allowPersonalizedOffers,
      requireLoginConfirmation:
          requireLoginConfirmation ?? this.requireLoginConfirmation,
      updatedAt: updatedAt ?? this.updatedAt,
      sessions: sessions ?? this.sessions,
    );
  }
}

class CustomerSessionModel {
  final String id;
  final String deviceName;
  final String platform;
  final String ipAddress;
  final String userAgent;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final DateTime? revokedAt;
  final bool isActive;

  const CustomerSessionModel({
    required this.id,
    required this.deviceName,
    required this.platform,
    required this.ipAddress,
    required this.userAgent,
    required this.createdAt,
    required this.expiresAt,
    required this.revokedAt,
    required this.isActive,
  });

  factory CustomerSessionModel.fromApi(Map<String, dynamic> data) {
    return CustomerSessionModel(
      id: _text(data['id']),
      deviceName: _text(data['device_name'] ?? data['deviceName'],
          fallback: 'جهاز غير معروف'),
      platform: _text(data['platform'], fallback: 'UNKNOWN'),
      ipAddress: _text(data['ip_address'] ?? data['ipAddress'], fallback: '-'),
      userAgent: _text(data['user_agent'] ?? data['userAgent'], fallback: '-'),
      createdAt: _date(data['created_at'] ?? data['createdAt']),
      expiresAt: _date(data['expires_at'] ?? data['expiresAt']),
      revokedAt: _date(data['revoked_at'] ?? data['revokedAt']),
      isActive: _bool(data['is_active'] ?? data['isActive'], fallback: true),
    );
  }
}

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

String _text(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  final text = value.toString();
  return text.isEmpty ? fallback : text;
}

bool _bool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    return ['true', '1', 'yes', 'y'].contains(value.toLowerCase());
  }
  return fallback;
}

DateTime? _date(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
