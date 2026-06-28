import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/features/provider_onboarding/logic/provider_onboarding_controller.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:ghiyarak/shared/widgets/app_text_field.dart';
import 'package:go_router/go_router.dart';

class ProviderProfilePage extends ConsumerStatefulWidget {
  const ProviderProfilePage({super.key});

  @override
  ConsumerState<ProviderProfilePage> createState() =>
      _ProviderProfilePageState();
}

class _ProviderProfilePageState extends ConsumerState<ProviderProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _field1 = TextEditingController();
  final _field2 = TextEditingController();
  bool _flag1 = true;
  bool _flag2 = true;

  @override
  void dispose() {
    _field1.dispose();
    _field2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(providerOnboardingControllerProvider);
    final isWorkshop = state.organizationType == 'WORKSHOP';
    final isWarehouse = state.organizationType == 'WAREHOUSE';

    return AppScaffold(
      title: isWorkshop
          ? 'بيانات الورشة'
          : isWarehouse
              ? 'بيانات المستودع'
              : 'بيانات التاجر',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            AppTextField(
              controller: _field1,
              label: isWorkshop
                  ? 'نمط الخدمة'
                  : isWarehouse
                      ? 'نوع المستودع'
                      : 'فئة النشاط التجاري',
              hint: isWorkshop
                  ? 'مثال: in_shop'
                  : isWarehouse
                      ? 'مثال: main-warehouse'
                      : 'مثال: auto-parts',
              validator: (v) =>
                  (v?.trim().isEmpty ?? true) ? 'الحقل مطلوب' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _field2,
              label: isWorkshop
                  ? 'رسوم التشخيص الافتراضية'
                  : isWarehouse
                      ? 'الحد الأدنى للتوريد'
                      : 'الحد الأدنى للطلب',
              keyboardType: TextInputType.number,
              validator: (v) =>
                  (v?.trim().isEmpty ?? true) ? 'الحقل مطلوب' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            if (isWorkshop) ...[
              SwitchListTile(
                title: const Text('قبول التشخيص'),
                value: _flag1,
                onChanged: (v) => setState(() => _flag1 = v),
              ),
              SwitchListTile(
                title: const Text('قبول التركيب'),
                value: _flag2,
                onChanged: (v) => setState(() => _flag2 = v),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              text: 'حفظ ومتابعة',
              isLoading: state.loading,
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                final ok = isWarehouse
                    ? true
                    : isWorkshop
                        ? await ref
                            .read(providerOnboardingControllerProvider.notifier)
                            .saveWorkshopProfile(
                              serviceModeCode: _field1.text.trim(),
                              acceptsDiagnosis: _flag1,
                              acceptsInstallation: _flag2,
                              supportsEmergencyService: false,
                              defaultDiagnosisFee:
                                  double.tryParse(_field2.text.trim()),
                            )
                        : await ref
                            .read(providerOnboardingControllerProvider.notifier)
                            .saveMerchantProfile(
                              businessCategoryCode: _field1.text.trim(),
                              minOrderAmount:
                                  double.tryParse(_field2.text.trim()),
                            );
                if (!context.mounted) return;
                if (ok) {
                  context.go(RouteNames.providerBankAccount);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(ref
                              .read(providerOnboardingControllerProvider)
                              .errorMessage ??
                          'تعذر حفظ بيانات المزود')));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
