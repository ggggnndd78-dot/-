import 'package:equatable/equatable.dart';
import 'package:ghiyarak/features/auth/data/models/user_model.dart';

enum AuthStatus { initial, loading, otpSent, authenticated, guest, error }

class AuthState extends Equatable {
  static const List<String> adminConsolePermissions = <String>[
    'view_admin_panel',
    'manage_system',
  ];
  static const List<String> supportConsolePermissions = <String>[
    'support.tickets.manage',
    'support.content.manage',
    'support.whatsapp.manage',
    'manage_support',
    'manage_complaints',
    'manage_reviews',
    'manage_system',
  ];

  final AuthStatus status;
  final String phone;
  final String? errorMessage;
  final UserModel? user;

  const AuthState({
    this.status = AuthStatus.initial,
    this.phone = '',
    this.errorMessage,
    this.user,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? phone,
    String? errorMessage,
    UserModel? user,
    bool clearUser = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      phone: phone ?? this.phone,
      errorMessage: errorMessage,
      user: clearUser ? null : user ?? this.user,
    );
  }

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isGuest => status == AuthStatus.guest;
  List<String> get roles => user?.roles ?? const [];
  List<String> get permissions => user?.permissions ?? const [];
  bool hasRole(String role) => roles.contains(role);
  bool hasAnyRole(Iterable<String> values) => values.any(roles.contains);
  bool hasPermission(String permission) => permissions.contains(permission);
  bool hasAnyPermission(Iterable<String> values) =>
      values.any(permissions.contains);
  bool can(String permission) => isSuperAdmin || hasPermission(permission);
  bool canAny(Iterable<String> values) {
    final candidates =
        values.map((value) => value.trim()).where((value) => value.isNotEmpty);
    if (isSuperAdmin) return true;
    return candidates.any(hasPermission);
  }

  bool canAll(Iterable<String> values) {
    final candidates =
        values.map((value) => value.trim()).where((value) => value.isNotEmpty);
    final required = candidates.toList(growable: false);
    if (required.isEmpty) return true;
    if (isSuperAdmin) return true;
    return required.every(hasPermission);
  }

  bool get isSuperAdmin => hasRole('admin_super');
  bool get isAdminOperations => hasRole('admin_operations');
  bool get isSupportAgent => hasRole('support_agent');
  bool get canAccessAdminConsole =>
      isSuperAdmin || isAdminOperations || canAny(adminConsolePermissions);
  bool get isAdmin => canAccessAdminConsole;
  bool get isSupport =>
      isSupportAgent ||
      isSuperAdmin ||
      isAdminOperations ||
      canAny(supportConsolePermissions);
  bool get hasApprovedMerchantOrganization =>
      user?.hasApprovedMerchantOrganization ?? false;
  bool get hasApprovedWorkshopOrganization =>
      user?.hasApprovedWorkshopOrganization ?? false;
  bool get hasApprovedWarehouseOrganization =>
      user?.hasApprovedWarehouseOrganization ?? false;
  bool get hasPendingProviderOrganization =>
      user?.hasPendingProviderOrganization ?? false;
  bool get isMerchant =>
      hasRole('merchant_owner') || hasApprovedMerchantOrganization;
  bool get isWorkshop =>
      hasRole('workshop_owner') || hasApprovedWorkshopOrganization;
  bool get isWarehouse =>
      hasRole('warehouse_owner') || hasApprovedWarehouseOrganization;
  bool get isProvider =>
      isMerchant || isWorkshop || isWarehouse || hasRole('provider');
  bool get isCustomer =>
      isAuthenticated &&
      user != null &&
      (hasRole('customer') ||
          (!canAccessAdminConsole &&
              !isProvider &&
              !hasPendingProviderOrganization &&
              !isSupport));
  String get merchantStatus => _organizationStatus('MERCHANT');
  String get workshopStatus => _organizationStatus('WORKSHOP');
  String get warehouseStatus => _organizationStatus('WAREHOUSE');

  String _organizationStatus(String type) {
    final orgs = user?.organizations ?? const [];
    for (final org in orgs) {
      if (org.type.toUpperCase() == type.toUpperCase()) {
        if (org.status.trim().isNotEmpty) return org.status;
        if (org.latestVerificationStatus?.trim().isNotEmpty == true) {
          return org.latestVerificationStatus!;
        }
      }
    }
    return hasRole('admin_super') || hasRole('admin_operations')
        ? 'APPROVED'
        : 'NOT_REGISTERED';
  }

  bool hasApprovedOrganization(String type) =>
      user?.hasApprovedOrganization(type) ?? false;

  bool get hasAdministrativeAccess => canAccessAdminConsole || isSupport;
  bool get canOpenProviderOnboarding =>
      isAuthenticated && !hasAdministrativeAccess;
  bool get canOpenMerchantConsole =>
      isSuperAdmin ||
      isAdminOperations ||
      (hasRole('merchant_owner') && hasApprovedMerchantOrganization);
  bool get canOpenWorkshopConsole =>
      isSuperAdmin ||
      isAdminOperations ||
      (hasRole('workshop_owner') && hasApprovedWorkshopOrganization);
  bool get canOpenWarehouseConsole =>
      isSuperAdmin ||
      isAdminOperations ||
      (hasRole('warehouse_owner') && hasApprovedWarehouseOrganization);
  bool get canOpenSupportConsole => isSupport;

  @override
  List<Object?> get props => [status, phone, errorMessage, user];
}
