import 'package:flutter/material.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:ghiyarak/shared/widgets/section_title.dart';
import 'package:go_router/go_router.dart';

class MerchantFulfillmentHubPage extends StatelessWidget {
  const MerchantFulfillmentHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'عمليات التاجر',
      child: ListView(children: [
        const SectionTitle(
            title: 'الدفع والتوصيل',
            subtitle:
                'كل البيانات في هذه الواجهة تأتي من طلبات وشحنات ومدفوعات الباك إند.'),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
            text: 'مدفوعات الطلبات',
            onPressed: () => context.go(RouteNames.merchantPayments)),
        const SizedBox(height: AppSpacing.md),
        AppButton(
            text: 'شحنات التاجر',
            isOutlined: true,
            onPressed: () => context.go(RouteNames.merchantShipments)),
        const SizedBox(height: AppSpacing.md),
        AppButton(
            text: 'حملات الاحتفاظ',
            isOutlined: true,
            onPressed: () => context.go(RouteNames.merchantRetention)),
      ]),
    );
  }
}
