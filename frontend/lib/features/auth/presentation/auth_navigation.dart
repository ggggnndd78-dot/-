import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/features/auth/data/auth_repository.dart';
import 'package:ghiyarak/shared/navigation/app_route_resolver.dart';
import 'package:ghiyarak/features/auth/logic/auth_controller.dart';
import 'package:go_router/go_router.dart';

Future<void> goAfterAuth({
  required BuildContext context,
  required WidgetRef ref,
  required AuthSession session,
  String? returnTo,
}) async {
  if (!context.mounted) return;

  final authState = ref.read(authControllerProvider);
  if (authState.isAuthenticated && authState.hasAdministrativeAccess) {
    context.go(AppRouteResolver.resolvePostAuthRoute(
      authState,
      nextRoute: returnTo,
    ));
    return;
  }

  if (!session.isMerchant && !session.isProvider && !session.isEnterprise) {
    context.go(returnTo ?? RouteNames.customerCenter);
    return;
  }

  final hasOrganization =
      await ref.read(authControllerProvider.notifier).hasProviderOrganization();
  if (!context.mounted) return;

  if (session.isMerchant) {
    context
        .go(hasOrganization ? RouteNames.merchantHub : RouteNames.providerType);
    return;
  }

  if (session.isProvider) {
    context
        .go(hasOrganization ? RouteNames.merchantHub : RouteNames.providerType);
    return;
  }

  context
      .go(hasOrganization ? RouteNames.merchantHub : RouteNames.providerType);
}
