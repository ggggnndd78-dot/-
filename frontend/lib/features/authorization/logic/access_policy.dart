import 'package:ghiyarak/features/auth/logic/auth_state.dart';

class AccessPolicy {
  const AccessPolicy._();

  static bool hasAccess(
    AuthState auth, {
    List<String> roles = const [],
    List<String> permissions = const [],
    List<String> allPermissions = const [],
    List<String> approvedOrganizationTypes = const [],
    bool allowGuest = false,
  }) {
    if (auth.isSuperAdmin) return auth.isAuthenticated;

    if (!auth.isAuthenticated) {
      return allowGuest && auth.isGuest;
    }

    final normalizedRoles =
        roles.map((value) => value.trim()).where((value) => value.isNotEmpty);
    final normalizedPermissions = permissions
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty);
    final normalizedAllPermissions = allPermissions
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty);
    final normalizedOrganizations = approvedOrganizationTypes
        .map((value) => value.trim().toUpperCase())
        .where((value) => value.isNotEmpty);

    final roleAllowed = normalizedRoles.isEmpty ||
        auth.hasAnyRole(normalizedRoles) ||
        (normalizedRoles.contains('customer') && auth.isCustomer);
    final anyPermissionAllowed =
        normalizedPermissions.isEmpty || auth.canAny(normalizedPermissions);
    final allPermissionAllowed = normalizedAllPermissions.isEmpty ||
        auth.canAll(normalizedAllPermissions);
    final organizationAllowed = normalizedOrganizations.isEmpty ||
        normalizedOrganizations.any(auth.hasApprovedOrganization);

    return roleAllowed &&
        anyPermissionAllowed &&
        allPermissionAllowed &&
        organizationAllowed;
  }
}
