import 'package:flutter/material.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:ghiyarak/shared/widgets/section_title.dart';
import 'package:go_router/go_router.dart';

class SupportOperationsHubPage extends StatelessWidget {
  const SupportOperationsHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'مركز الدعم',
      child: ListView(children: [
        const SectionTitle(
            title: 'الدعم والشكاوى والتقييمات',
            subtitle: 'إدارة بيانات الدعم الفعلية حسب الصلاحيات.'),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
            text: 'مركز المساعدة',
            onPressed: () => context.go(RouteNames.helpCenter)),
        const SizedBox(height: AppSpacing.md),
        AppButton(
            text: 'تذاكر الدعم',
            isOutlined: true,
            onPressed: () => context.go(RouteNames.supportTickets)),
        const SizedBox(height: AppSpacing.md),
        AppButton(
            text: 'الشكاوى',
            isOutlined: true,
            onPressed: () => context.go(RouteNames.supportComplaints)),
        const SizedBox(height: AppSpacing.md),
        AppButton(
            text: 'التقييمات',
            isOutlined: true,
            onPressed: () => context.go(RouteNames.supportReviews)),
      ]),
    );
  }
}
