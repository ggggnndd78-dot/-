import 'package:flutter/material.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:ghiyarak/shared/widgets/section_title.dart';
import 'package:go_router/go_router.dart';

class WorkshopOperationsHubPage extends StatelessWidget {
  const WorkshopOperationsHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'عمليات الورشة',
      child: ListView(
        children: [
          const SectionTitle(
            title: 'بوابة الورشة والصيانة',
            subtitle:
                'إدارة خدمات الورشة، الحجوزات، أوامر الصيانة، التشخيص، وسجل الصيانة.',
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            text: 'خدمات الورشة',
            onPressed: () => context.go(RouteNames.workshopOperationsServices),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            text: 'حجوزات الورشة',
            isOutlined: true,
            onPressed: () => context.go(RouteNames.workshopOperationsBookings),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            text: 'أوامر الصيانة',
            isOutlined: true,
            onPressed: () =>
                context.go(RouteNames.workshopOperationsServiceOrders),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            text: 'استيراد المنتجات من Excel',
            isOutlined: true,
            onPressed: () => context.go(RouteNames.productImports),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            text: 'الفروع والموظفون',
            isOutlined: true,
            onPressed: () => context.go(RouteNames.branchEmployeeManagement),
          ),
        ],
      ),
    );
  }
}
