import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/core/theme/app_colors.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/core/theme/app_text_styles.dart';
import 'package:ghiyarak/features/provider_onboarding/logic/provider_onboarding_controller.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:go_router/go_router.dart';

class ProviderStatusPage extends ConsumerStatefulWidget {
  const ProviderStatusPage({super.key});

  @override
  ConsumerState<ProviderStatusPage> createState() => _ProviderStatusPageState();
}

class _ProviderStatusPageState extends ConsumerState<ProviderStatusPage> {
  Map<String, dynamic>? _details;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final details = await ref
        .read(providerOnboardingControllerProvider.notifier)
        .getOrganizationDetail();
    if (!context.mounted) return;
    setState(() => _details = details);
  }

  String _statusText(String status) {
    switch (status) {
      case 'APPROVED':
        return 'تم اعتماد حسابك ويمكنك الآن استخدام لوحة الأعمال.';
      case 'REJECTED':
        return 'تم رفض الطلب. راجع سبب الرفض وأعد تقديم البيانات الصحيحة.';
      case 'DOCUMENTS_REQUIRED':
        return 'الإدارة طلبت مستندات إضافية. يرجى تعديل الطلب وإرفاق المستندات المطلوبة.';
      case 'SUSPENDED':
        return 'تم تعليق الحساب مؤقتًا من الإدارة. تواصل مع الدعم أو راجع ملاحظات الإدارة.';
      case 'PENDING_REVIEW':
        return 'طلبك قيد مراجعة الإدارة. لا يمكنك البيع أو استقبال الطلبات قبل الاعتماد.';
      default:
        return 'أكمل بيانات المنشأة وأرسل طلب التوثيق للإدارة.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = (_details?['status'] ?? '-').toString();
    final type = (_details?['organization_type'] ?? '').toString();
    final approved = status == 'APPROVED';

    return AppScaffold(
      title: 'حالة الاعتماد',
      showBottomNav: false,
      child: _details == null
          ? ListView(
              children: [
                const Text('لا يوجد طلب اعتماد مرتبط بهذا الحساب حتى الآن.',
                    style: AppTextStyles.title),
                const SizedBox(height: AppSpacing.md),
                const Text(
                    'إذا كنت تريد التسجيل كتاجر أو ورشة أو مستودع، ابدأ من بيانات المنشأة ثم أكمل الفروع والحساب البنكي والمستندات.',
                    style: AppTextStyles.bodySecondary),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                    text: 'بدء تسجيل تاجر أو ورشة أو مستودع',
                    onPressed: () => context.go(RouteNames.providerType)),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                    text: 'تحديث الحالة', isOutlined: true, onPressed: _load),
              ],
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                children: [
                  Text('حالة حساب التاجر/الورشة/المستودع',
                      style: AppTextStyles.heading2),
                  const SizedBox(height: AppSpacing.sm),
                  Text(_statusText(status), style: AppTextStyles.bodySecondary),
                  const SizedBox(height: AppSpacing.lg),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'الاسم التجاري: ${_details?['display_name'] ?? '-'}'),
                          const SizedBox(height: AppSpacing.sm),
                          Text('نوع الحساب: $type'),
                          const SizedBox(height: AppSpacing.sm),
                          Text('حالة المؤسسة: $status',
                              style: TextStyle(
                                  color: approved
                                      ? AppColors.success
                                      : AppColors.warning,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                              'عدد الفروع: ${(_details?['branches'] as List?)?.length ?? 0}'),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                              'عدد الحسابات البنكية: ${(_details?['bank_accounts'] as List?)?.length ?? 0}'),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                              'طلبات التوثيق: ${(_details?['verification_requests'] as List?)?.length ?? 0}'),
                          if ((_details?['rejection_reason'] ?? '')
                              .toString()
                              .isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                                'ملاحظة الإدارة: ${_details?['rejection_reason']}'),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                      text: 'تحديث الحالة', isOutlined: true, onPressed: _load),
                  const SizedBox(height: AppSpacing.md),
                  if (approved)
                    AppButton(
                      text: type == 'WORKSHOP'
                          ? 'الدخول إلى بوابة الورشة'
                          : type == 'WAREHOUSE'
                              ? 'الدخول إلى بوابة المستودع'
                              : 'الدخول إلى بوابة التاجر',
                      onPressed: () => context.go(type == 'WORKSHOP'
                          ? RouteNames.workshopOperationsHub
                          : type == 'WAREHOUSE'
                              ? RouteNames.warehouseHub
                              : RouteNames.merchantHub),
                    )
                  else
                    const Text(
                        'بعد موافقة الإدارة، سجّل خروج ثم ادخل مرة أخرى لتحديث الصلاحيات.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySecondary),
                ],
              ),
            ),
    );
  }
}
