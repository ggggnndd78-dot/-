import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/features/provider_onboarding/logic/provider_onboarding_controller.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:ghiyarak/shared/widgets/app_text_field.dart';
import 'package:go_router/go_router.dart';

class ProviderOrganizationPage extends ConsumerStatefulWidget {
  const ProviderOrganizationPage({super.key});

  @override
  ConsumerState<ProviderOrganizationPage> createState() =>
      _ProviderOrganizationPageState();
}

class _ProviderOrganizationPageState
    extends ConsumerState<ProviderOrganizationPage> {
  final _formKey = GlobalKey<FormState>();
  final _displayName = TextEditingController();
  final _legalName = TextEditingController();
  final _phone = TextEditingController();

  @override
  void dispose() {
    _displayName.dispose();
    _legalName.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(providerOnboardingControllerProvider);
    final type = state.organizationType == 'WORKSHOP'
        ? 'ورشة'
        : state.organizationType == 'WAREHOUSE'
            ? 'مستودع'
            : 'تاجر';

    return AppScaffold(
      title: 'بيانات المؤسسة',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Text('إعداد حساب $type'),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
                controller: _displayName,
                label: 'الاسم التجاري',
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? 'الحقل مطلوب' : null),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
                controller: _legalName,
                label: 'الاسم القانوني',
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? 'الحقل مطلوب' : null),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
                controller: _phone,
                label: 'رقم الجوال',
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    (v?.trim().length ?? 0) < 9 ? 'رقم غير صالح' : null),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              text: 'حفظ ومتابعة',
              isLoading: state.loading,
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                final ok = await ref
                    .read(providerOnboardingControllerProvider.notifier)
                    .createOrganization(
                      displayName: _displayName.text.trim(),
                      legalName: _legalName.text.trim(),
                      primaryPhone: _phone.text.trim(),
                    );
                if (!context.mounted) return;
                if (ok) {
                  context.go(RouteNames.providerBranch);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(state.errorMessage ?? 'تعذر الحفظ')));
                }
              },
            )
          ],
        ),
      ),
    );
  }
}
