import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/features/auth/logic/auth_controller.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:ghiyarak/shared/widgets/section_title.dart';
import 'package:go_router/go_router.dart';

class MerchantHubPage extends ConsumerWidget {
  const MerchantHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final isMerchant =
        auth.hasApprovedMerchantOrganization || auth.hasRole('admin_super');
    final isWorkshop =
        auth.hasApprovedWorkshopOrganization || auth.hasRole('admin_super');

    return AppScaffold(
      title: isWorkshop && !isMerchant ? 'بوابة الورشة' : 'بوابة التاجر',
      child: ListView(children: [
        SectionTitle(
          title: isWorkshop && !isMerchant
              ? 'إدارة خدمات الورشة'
              : 'إدارة متجر قطع الغيار',
          subtitle:
              'لا تظهر هنا إلا العمليات المسموحة حسب نوع الحساب وحالة اعتماد الإدارة.',
        ),
        const SizedBox(height: AppSpacing.xl),
        if (isMerchant) ...[
          AppButton(
              text: 'عروضي ومنتجاتي',
              onPressed: () => context.go(RouteNames.merchantListings)),
          const SizedBox(height: AppSpacing.md),
          AppButton(
              text: 'إنشاء عرض جديد',
              isOutlined: true,
              onPressed: () => context.go(RouteNames.createListing)),
          const SizedBox(height: AppSpacing.md),
          AppButton(
              text: 'استيراد المنتجات من Excel',
              isOutlined: true,
              onPressed: () => context.go(RouteNames.productImports)),
          const SizedBox(height: AppSpacing.md),
          AppButton(
              text: 'الفروع والموظفون',
              isOutlined: true,
              onPressed: () => context.go(RouteNames.branchEmployeeManagement)),
          const SizedBox(height: AppSpacing.md),
          AppButton(
              text: 'طلبات المتجر',
              isOutlined: true,
              onPressed: () => context.go(RouteNames.merchantOrders)),
          const SizedBox(height: AppSpacing.md),
          AppButton(
              text: 'الدفع والتوصيل',
              isOutlined: true,
              onPressed: () => context.go(RouteNames.merchantFulfillment)),
        ],
        if (isWorkshop) ...[
          const SizedBox(height: AppSpacing.md),
          AppButton(
              text: 'عمليات الورشة والصيانة',
              isOutlined: !isMerchant,
              onPressed: () => context.go(RouteNames.workshopOperationsHub)),
        ],
      ]),
    );
  }
}
