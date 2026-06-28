import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/features/provider_onboarding/logic/provider_onboarding_controller.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:go_router/go_router.dart';

class ProviderTypePage extends ConsumerWidget {
  const ProviderTypePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScaffold(
      title: 'نوع المزود',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('اختر نوع حساب المؤسسة التي تريد تسجيلها.'),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            text: 'تاجر قطع غيار',
            onPressed: () {
              ref
                  .read(providerOnboardingControllerProvider.notifier)
                  .setOrganizationType('MERCHANT');
              context.go(RouteNames.providerOrganization);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            text: 'ورشة صيانة',
            onPressed: () {
              ref
                  .read(providerOnboardingControllerProvider.notifier)
                  .setOrganizationType('WORKSHOP');
              context.go(RouteNames.providerOrganization);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            text: 'مستودع قطع غيار',
            onPressed: () {
              ref
                  .read(providerOnboardingControllerProvider.notifier)
                  .setOrganizationType('WAREHOUSE');
              context.go(RouteNames.providerOrganization);
            },
          ),
        ],
      ),
    );
  }
}
