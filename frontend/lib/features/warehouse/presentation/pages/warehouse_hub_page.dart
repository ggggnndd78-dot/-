import 'package:flutter/material.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/core/theme/app_text_styles.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:go_router/go_router.dart';

class WarehouseHubPage extends StatelessWidget {
  const WarehouseHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'بوابة المستودع',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('بوابة المستودع', style: AppTextStyles.heading2),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'تم اعتماد حساب المستودع. يمكنك الآن استيراد منتجات الجملة والمخزون من ملف Excel ضمن الصلاحيات المسموحة.',
            style: AppTextStyles.bodySecondary,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            text: 'استيراد المنتجات من Excel',
            onPressed: () => context.go(RouteNames.productImports),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            text: 'الفروع والموظفون',
            isOutlined: true,
            onPressed: () => context.go(RouteNames.branchEmployeeManagement),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('الحالة: معتمد'),
                  SizedBox(height: AppSpacing.sm),
                  Text('الصلاحية: warehouse_owner'),
                  SizedBox(height: AppSpacing.sm),
                  Text('النطاق الحالي: استيراد المنتجات والمخزون'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
