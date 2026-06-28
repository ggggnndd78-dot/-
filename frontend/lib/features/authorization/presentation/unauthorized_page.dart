import 'package:flutter/material.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/core/i18n/app_localizations.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:go_router/go_router.dart';

class UnauthorizedPage extends StatelessWidget {
  const UnauthorizedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: context.tr('auth.forbidden.title'),
      showBottomNav: false,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 64),
            const SizedBox(height: 16),
            Text(context.tr('auth.forbidden.message')),
            const SizedBox(height: 16),
            AppButton(
              text: context.tr('auth.forbidden.back_home'),
              onPressed: () => context.go(RouteNames.marketplaceHome),
            ),
          ],
        ),
      ),
    );
  }
}
