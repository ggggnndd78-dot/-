import 'package:flutter/material.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:ghiyarak/shared/widgets/section_title.dart';
import 'package:go_router/go_router.dart';

class WalletLoyaltyHubPage extends StatelessWidget {
  const WalletLoyaltyHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'المحفظة والولاء',
      child: ListView(children: [
        const SectionTitle(
            title: 'المحفظة والولاء والاحتفاظ',
            subtitle:
                'إدارة الرصيد والنقاط والكوبونات والحملات من بيانات الباك إند.'),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
            text: 'محفظتي',
            onPressed: () => context.go(RouteNames.customerWallet)),
        const SizedBox(height: AppSpacing.md),
        AppButton(
            text: 'نقاط الولاء والكوبونات',
            isOutlined: true,
            onPressed: () => context.go(RouteNames.customerLoyalty)),
        const SizedBox(height: AppSpacing.md),
        AppButton(
            text: 'إحالاتي ومكافآتي',
            isOutlined: true,
            onPressed: () => context.go(RouteNames.customerReferrals)),
        const SizedBox(height: AppSpacing.md),
        AppButton(
            text: 'إدارة الكوبونات',
            isOutlined: true,
            onPressed: () => context.go(RouteNames.adminCoupons)),
        const SizedBox(height: AppSpacing.md),
        AppButton(
            text: 'حملات الاحتفاظ',
            isOutlined: true,
            onPressed: () => context.go(RouteNames.merchantRetention)),
      ]),
    );
  }
}
