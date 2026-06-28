import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/features/auth/logic/auth_controller.dart';
import 'package:ghiyarak/features/authorization/logic/access_policy.dart';
import 'package:ghiyarak/features/authorization/presentation/unauthorized_page.dart';

class PermissionGuard extends ConsumerWidget {
  const PermissionGuard({
    required this.child,
    this.fallback,
    this.roles = const [],
    this.permissions = const [],
    this.allPermissions = const [],
    this.approvedOrganizationTypes = const [],
    this.allowGuest = false,
    super.key,
  });

  final Widget child;
  final Widget? fallback;
  final List<String> roles;
  final List<String> permissions;
  final List<String> allPermissions;
  final List<String> approvedOrganizationTypes;
  final bool allowGuest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final allowed = AccessPolicy.hasAccess(
      auth,
      roles: roles,
      permissions: permissions,
      allPermissions: allPermissions,
      approvedOrganizationTypes: approvedOrganizationTypes,
      allowGuest: allowGuest,
    );

    if (allowed) return child;
    return fallback ?? const UnauthorizedPage();
  }
}
