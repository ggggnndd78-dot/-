import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/features/provider_onboarding/logic/provider_onboarding_controller.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:ghiyarak/shared/widgets/app_text_field.dart';
import 'package:go_router/go_router.dart';

class ProviderBankAccountPage extends ConsumerStatefulWidget {
  const ProviderBankAccountPage({super.key});

  @override
  ConsumerState<ProviderBankAccountPage> createState() =>
      _ProviderBankAccountPageState();
}

class _ProviderBankAccountPageState
    extends ConsumerState<ProviderBankAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _bankName = TextEditingController();
  final _accountName = TextEditingController();
  final _accountNumber = TextEditingController();
  final _iban = TextEditingController();

  @override
  void dispose() {
    _bankName.dispose();
    _accountName.dispose();
    _accountNumber.dispose();
    _iban.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(providerOnboardingControllerProvider);
    return AppScaffold(
      title: 'الحساب البنكي',
      child: Form(
        key: _formKey,
        child: Column(children: [
          AppTextField(
              controller: _bankName,
              label: 'اسم البنك',
              validator: (v) =>
                  (v?.trim().isEmpty ?? true) ? 'الحقل مطلوب' : null),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
              controller: _accountName,
              label: 'اسم صاحب الحساب',
              validator: (v) =>
                  (v?.trim().isEmpty ?? true) ? 'الحقل مطلوب' : null),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
              controller: _accountNumber,
              label: 'رقم الحساب',
              validator: (v) =>
                  (v?.trim().isEmpty ?? true) ? 'الحقل مطلوب' : null),
          const SizedBox(height: AppSpacing.md),
          AppTextField(controller: _iban, label: 'IBAN (اختياري)'),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
              text: 'حفظ ومتابعة',
              isLoading: state.loading,
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                final ok = await ref
                    .read(providerOnboardingControllerProvider.notifier)
                    .createBankAccount(
                      bankName: _bankName.text.trim(),
                      accountName: _accountName.text.trim(),
                      accountNumber: _accountNumber.text.trim(),
                      iban:
                          _iban.text.trim().isEmpty ? null : _iban.text.trim(),
                    );
                if (!context.mounted) return;
                if (ok) {
                  context.go(RouteNames.providerBusinessHours);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(ref
                              .read(providerOnboardingControllerProvider)
                              .errorMessage ??
                          'تعذر حفظ الحساب البنكي')));
                }
              })
        ]),
      ),
    );
  }
}
