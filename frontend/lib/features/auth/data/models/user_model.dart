class UserOrganizationModel {
  final String id;
  final String name;
  final String type;
  final String status;
  final bool isVerified;
  final String? latestVerificationStatus;

  const UserOrganizationModel({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.isVerified,
    this.latestVerificationStatus,
  });

  factory UserOrganizationModel.fromJson(Map<String, dynamic> json) {
    return UserOrganizationModel(
      id: (json['id'] ?? json['organization_id'] ?? '').toString(),
      name:
          (json['display_name'] ?? json['organization_name'] ?? '').toString(),
      type: (json['organization_type'] ?? '').toString(),
      status: (json['status'] ?? json['organization_status'] ?? '').toString(),
      isVerified: json['is_verified'] == true,
      latestVerificationStatus: json['latest_verification_status']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'display_name': name,
        'organization_type': type,
        'status': status,
        'is_verified': isVerified,
        'latest_verification_status': latestVerificationStatus,
      };

  bool get isApproved => status == 'APPROVED' || isVerified;
  bool get isPending =>
      status == 'DRAFT' ||
      status == 'PENDING_REVIEW' ||
      status == 'DOCUMENTS_REQUIRED';
}

class UserModel {
  final String id;
  final String phone;
  final String displayName;
  final List<String> roles;
  final List<String> permissions;
  final List<UserOrganizationModel> organizations;
  final String locale;
  final String dashboardRoute;

  const UserModel({
    required this.id,
    required this.phone,
    required this.displayName,
    this.roles = const [],
    this.permissions = const [],
    this.organizations = const [],
    this.locale = 'ar',
    this.dashboardRoute = '/customer/dashboard',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    List<String> strings(dynamic value) {
      if (value is List) return value.map((e) => e.toString()).toList();
      return const [];
    }

    List<UserOrganizationModel> organizations(dynamic value) {
      if (value is List) {
        return value
            .whereType<Map>()
            .map((e) =>
                UserOrganizationModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      return const [];
    }

    return UserModel(
      id: (json['id'] ?? json['publicId'] ?? '').toString(),
      phone: (json['phone'] ?? json['phoneNormalized'] ?? '').toString(),
      displayName:
          (json['display_name'] ?? json['displayName'] ?? '').toString(),
      roles: strings(json['roles'])
          .map((role) => role.trim().toLowerCase())
          .where((role) => role.isNotEmpty)
          .toList(growable: false),
      permissions: strings(json['permissions']),
      organizations: organizations(json['organizations']),
      locale: (json['locale'] ?? 'ar').toString() == 'en' ? 'en' : 'ar',
      dashboardRoute: (json['dashboard_route'] ??
              json['dashboardRoute'] ??
              '/customer/dashboard')
          .toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone': phone,
        'display_name': displayName,
        'roles': roles,
        'permissions': permissions,
        'organizations': organizations.map((e) => e.toJson()).toList(),
        'locale': locale,
        'dashboard_route': dashboardRoute,
      };

  bool hasRole(String role) => roles.contains(role);
  bool hasAnyRole(Iterable<String> values) => values.any(roles.contains);
  bool hasPermission(String permission) => permissions.contains(permission);
  bool hasAnyPermission(Iterable<String> values) =>
      values.any(permissions.contains);

  bool hasApprovedOrganization(String type) {
    return organizations.any((org) => org.type == type && org.isApproved);
  }

  bool get hasApprovedMerchantOrganization =>
      hasApprovedOrganization('MERCHANT');
  bool get hasApprovedWorkshopOrganization =>
      hasApprovedOrganization('WORKSHOP');
  bool get hasApprovedWarehouseOrganization =>
      hasApprovedOrganization('WAREHOUSE');
  bool get hasPendingProviderOrganization => organizations.any((org) =>
      org.isPending &&
      (org.type == 'MERCHANT' ||
          org.type == 'WORKSHOP' ||
          org.type == 'WAREHOUSE'));
}
