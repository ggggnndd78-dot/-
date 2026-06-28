class MerchantOrganizationModel {
  final String id;
  final String name;
  final int membersCount;
  final String? phone;
  final String? commercialRegistration;
  final String? legalName;
  final String? logoUrl;
  final String? coverUrl;
  final String? contactEmail;
  final String? whatsappPhone;
  final String? vacationMessage;
  final String status;
  final bool isVerified;
  final bool isVacationMode;
  final MerchantProfileSettingsModel? merchantProfile;
  final int bankAccountsCount;
  final List<MerchantBranchModel> branches;
  final List<MerchantVerificationSummaryModel> verificationRequests;

  const MerchantOrganizationModel({
    required this.id,
    required this.name,
    required this.membersCount,
    this.phone,
    this.commercialRegistration,
    this.legalName,
    this.logoUrl,
    this.coverUrl,
    this.contactEmail,
    this.whatsappPhone,
    this.vacationMessage,
    required this.status,
    required this.isVerified,
    required this.isVacationMode,
    this.merchantProfile,
    required this.bankAccountsCount,
    required this.branches,
    this.verificationRequests = const [],
  });

  factory MerchantOrganizationModel.fromMap(Map<String, dynamic> map) {
    final rawBranches = map['branches'];
    final rawVerificationRequests =
        map['verification_requests'] ?? map['verificationRequests'];
    return MerchantOrganizationModel(
      id: (map['id'] ?? '').toString(),
      name: (map['display_name'] ?? map['displayName'] ?? '').toString(),
      membersCount: int.tryParse((map['members_count'] ?? 0).toString()) ?? 0,
      phone: map['primary_phone']?.toString(),
      commercialRegistration:
          (map['commercial_registration'] ?? map['commercialRegistration'])
              ?.toString(),
      legalName: (map['legal_name'] ?? map['legalName'])?.toString(),
      logoUrl: (map['logo_url'] ?? map['logoUrl'])?.toString(),
      coverUrl: (map['cover_url'] ?? map['coverUrl'])?.toString(),
      contactEmail: (map['contact_email'] ?? map['contactEmail'])?.toString(),
      whatsappPhone:
          (map['whatsapp_phone'] ?? map['whatsappPhone'])?.toString(),
      vacationMessage:
          (map['vacation_message'] ?? map['vacationMessage'])?.toString(),
      status: (map['status'] ?? '').toString(),
      isVerified: map['is_verified'] == true,
      isVacationMode:
          map['is_vacation_mode'] == true || map['isVacationMode'] == true,
      merchantProfile: map['merchant_profile'] is Map
          ? MerchantProfileSettingsModel.fromMap(
              Map<String, dynamic>.from(map['merchant_profile'] as Map),
            )
          : null,
      bankAccountsCount: map['bank_accounts'] is List
          ? (map['bank_accounts'] as List).length
          : 0,
      branches: rawBranches is List
          ? rawBranches
              .whereType<Map>()
              .map((item) =>
                  MerchantBranchModel.fromMap(Map<String, dynamic>.from(item)))
              .toList()
          : const [],
      verificationRequests: rawVerificationRequests is List
          ? rawVerificationRequests
              .whereType<Map>()
              .map((item) => MerchantVerificationSummaryModel.fromMap(
                  Map<String, dynamic>.from(item)))
              .toList()
          : const [],
    );
  }

  int get completionPercent {
    final checks = <bool>[
      name.trim().isNotEmpty,
      (phone ?? '').trim().isNotEmpty,
      (commercialRegistration ?? '').trim().isNotEmpty,
      isVerified,
      branches.isNotEmpty,
      branches.any((branch) => branch.businessHours.isNotEmpty),
      (merchantProfile?.returnPolicy ?? '').trim().isNotEmpty,
      (merchantProfile?.deliveryPolicy ?? '').trim().isNotEmpty,
      (merchantProfile?.warrantyPolicy ?? '').trim().isNotEmpty,
      bankAccountsCount > 0,
    ];
    return ((checks.where((value) => value).length / checks.length) * 100)
        .round();
  }
}

class MerchantProfileSettingsModel {
  final String? businessCategoryCode;
  final int? averagePreparationMinutes;
  final String? warrantyPolicy;
  final String? returnPolicy;
  final String? deliveryPolicy;
  final double? minOrderAmount;

  const MerchantProfileSettingsModel(
      {this.businessCategoryCode,
      this.averagePreparationMinutes,
      this.warrantyPolicy,
      this.returnPolicy,
      this.deliveryPolicy,
      this.minOrderAmount});

  factory MerchantProfileSettingsModel.fromMap(Map<String, dynamic> map) {
    return MerchantProfileSettingsModel(
      businessCategoryCode:
          (map['business_category_code'] ?? map['businessCategoryCode'])
              ?.toString(),
      averagePreparationMinutes: int.tryParse(
          (map['average_preparation_minutes'] ??
                  map['averagePreparationMinutes'] ??
                  '')
              .toString()),
      warrantyPolicy: (map['warranty_policy_text'] ?? map['warrantyPolicyText'])
          ?.toString(),
      returnPolicy:
          (map['return_policy_text'] ?? map['returnPolicyText'])?.toString(),
      deliveryPolicy: (map['delivery_policy_text'] ?? map['deliveryPolicyText'])
          ?.toString(),
      minOrderAmount: double.tryParse(
          (map['min_order_amount'] ?? map['minOrderAmount'] ?? '').toString()),
    );
  }
}

class MerchantBranchModel {
  final String id;
  final String name;
  final String? email;
  final String? cityName;
  final int? cityId;
  final String? districtName;
  final int? districtId;
  final String? areaName;
  final int? areaId;
  final String? address;
  final String? phone;
  final bool isHeadOffice;
  final bool supportsPickup;
  final bool supportsDelivery;
  final bool supportsInstallation;
  final bool supportsMobileService;
  final double? latitude;
  final double? longitude;
  final int productsCount;
  final int ordersCount;
  final int inventoryQuantity;
  final int lowStockCount;
  final String? managerName;
  final String? managerEmail;
  final List<MerchantBusinessHourModel> businessHours;

  const MerchantBranchModel({
    required this.id,
    required this.name,
    this.email,
    this.cityName,
    this.cityId,
    this.districtName,
    this.districtId,
    this.areaName,
    this.areaId,
    this.address,
    this.phone,
    required this.isHeadOffice,
    required this.supportsPickup,
    required this.supportsDelivery,
    required this.supportsInstallation,
    required this.supportsMobileService,
    this.latitude,
    this.longitude,
    required this.productsCount,
    required this.ordersCount,
    required this.inventoryQuantity,
    required this.lowStockCount,
    this.managerName,
    this.managerEmail,
    required this.businessHours,
  });

  factory MerchantBranchModel.fromMap(Map<String, dynamic> map) {
    final rawHours = map['business_hours'] ?? map['businessHours'];
    return MerchantBranchModel(
      id: (map['id'] ?? '').toString(),
      name: (map['branch_name'] ?? map['branchName'] ?? 'فرع').toString(),
      email: map['email']?.toString(),
      cityId: int.tryParse((map['city_id'] ?? map['cityId'] ?? '').toString()),
      cityName: map['city_name']?.toString(),
      districtId: int.tryParse(
          (map['district_id'] ?? map['districtId'] ?? '').toString()),
      districtName: map['district_name']?.toString(),
      areaId: int.tryParse((map['area_id'] ?? map['areaId'] ?? '').toString()),
      areaName: map['area_name']?.toString(),
      address: (map['address_line_1'] ?? map['addressLine1'])?.toString(),
      phone: map['phone']?.toString(),
      isHeadOffice:
          map['is_head_office'] == true || map['isHeadOffice'] == true,
      supportsPickup:
          map['supports_pickup'] != false && map['supportsPickup'] != false,
      supportsDelivery:
          map['supports_delivery'] == true || map['supportsDelivery'] == true,
      supportsInstallation: map['supports_installation'] == true ||
          map['supportsInstallation'] == true,
      supportsMobileService: map['supports_mobile_service'] == true ||
          map['supportsMobileService'] == true,
      latitude: double.tryParse((map['latitude'] ?? '').toString()),
      longitude: double.tryParse((map['longitude'] ?? '').toString()),
      productsCount: int.tryParse(
              (map['products_count'] ?? map['productsCount'] ?? 0)
                  .toString()) ??
          0,
      ordersCount: int.tryParse(
              (map['orders_count'] ?? map['ordersCount'] ?? 0).toString()) ??
          0,
      inventoryQuantity: int.tryParse(
              (map['inventory_quantity'] ?? map['inventoryQuantity'] ?? 0)
                  .toString()) ??
          0,
      lowStockCount: int.tryParse(
              (map['low_stock_count'] ?? map['lowStockCount'] ?? 0)
                  .toString()) ??
          0,
      managerName: (map['manager_name'] ?? map['managerName'])?.toString(),
      managerEmail: (map['manager_email'] ?? map['managerEmail'])?.toString(),
      businessHours: rawHours is List
          ? rawHours
              .whereType<Map>()
              .map((item) => MerchantBusinessHourModel.fromMap(
                  Map<String, dynamic>.from(item)))
              .toList()
          : const [],
    );
  }

  String get locationLabel => [cityName, districtName, areaName, address]
      .where((value) => (value ?? '').trim().isNotEmpty)
      .join('، ');

  String get servicesLabel {
    final services = <String>[];
    if (supportsPickup) services.add('استلام');
    if (supportsDelivery) services.add('توصيل');
    if (supportsInstallation) services.add('تركيب');
    if (supportsMobileService) services.add('خدمة متنقلة');
    return services.isEmpty ? 'لا توجد خدمات مفعلة' : services.join('، ');
  }

  bool get isOpenNow {
    final now = DateTime.now();
    final day = now.weekday == DateTime.sunday ? 0 : now.weekday;
    MerchantBusinessHourModel? today;
    for (final item in businessHours) {
      if (item.dayOfWeek == day) today = item;
    }
    if (today == null || today.isClosed) return false;
    final open = _minutes(today.openTime);
    final close = _minutes(today.closeTime);
    if (open == null || close == null) return false;
    final current = now.hour * 60 + now.minute;
    return current >= open && current <= close;
  }

  static int? _minutes(String? value) {
    final parts = value?.split(':');
    if (parts == null || parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return hour * 60 + minute;
  }
}

class MerchantBusinessHourModel {
  final int dayOfWeek;
  final String? openTime;
  final String? closeTime;
  final bool isClosed;

  const MerchantBusinessHourModel({
    required this.dayOfWeek,
    this.openTime,
    this.closeTime,
    required this.isClosed,
  });

  factory MerchantBusinessHourModel.fromMap(Map<String, dynamic> map) {
    return MerchantBusinessHourModel(
      dayOfWeek: int.tryParse(
              (map['day_of_week'] ?? map['dayOfWeek'] ?? 0).toString()) ??
          0,
      openTime: (map['open_time'] ?? map['openTime'])?.toString(),
      closeTime: (map['close_time'] ?? map['closeTime'])?.toString(),
      isClosed: map['is_closed'] == true || map['isClosed'] == true,
    );
  }
}

class MerchantVerificationSummaryModel {
  const MerchantVerificationSummaryModel({
    required this.id,
    required this.status,
    this.notes,
    this.reviewSummary,
    this.submittedAt,
    this.reviewedAt,
    required this.documentsCount,
  });

  final String id;
  final String status;
  final String? notes;
  final String? reviewSummary;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final int documentsCount;

  factory MerchantVerificationSummaryModel.fromMap(Map<String, dynamic> map) {
    return MerchantVerificationSummaryModel(
      id: (map['id'] ?? '').toString(),
      status: (map['status'] ?? '').toString(),
      notes: map['notes']?.toString(),
      reviewSummary:
          (map['review_summary'] ?? map['reviewSummary'])?.toString(),
      submittedAt: DateTime.tryParse(
          (map['submitted_at'] ?? map['submittedAt'] ?? '').toString()),
      reviewedAt: DateTime.tryParse(
          (map['reviewed_at'] ?? map['reviewedAt'] ?? '').toString()),
      documentsCount: int.tryParse(
              (map['documents_count'] ?? map['documentsCount'] ?? 0)
                  .toString()) ??
          0,
    );
  }
}
