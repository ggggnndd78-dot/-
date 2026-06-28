import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/features/provider_onboarding/logic/provider_onboarding_controller.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:ghiyarak/shared/widgets/app_text_field.dart';
import 'package:go_router/go_router.dart';

class ProviderDocumentsPage extends ConsumerStatefulWidget {
  const ProviderDocumentsPage({super.key});

  @override
  ConsumerState<ProviderDocumentsPage> createState() =>
      _ProviderDocumentsPageState();
}

class _ProviderDocumentsPageState extends ConsumerState<ProviderDocumentsPage> {
  final _notes = TextEditingController();
  final _doc1Name = TextEditingController();
  final _doc1Url = TextEditingController();
  final _doc2Name = TextEditingController();
  final _doc2Url = TextEditingController();

  @override
  void dispose() {
    _notes.dispose();
    _doc1Name.dispose();
    _doc1Url.dispose();
    _doc2Name.dispose();
    _doc2Url.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(providerOnboardingControllerProvider);
    final isWorkshop = state.organizationType == 'WORKSHOP';
    final doc1Type = isWorkshop ? 'SHOP_GUARANTEE' : 'COMMERCIAL_REGISTRATION';
    final doc2Type = 'BANK_PROOF';

    return AppScaffold(
      title: 'مستندات التوثيق',
      child: SingleChildScrollView(
        child: Column(
          children: [
            AppTextField(controller: _notes, label: 'ملاحظات الطلب (اختياري)'),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(controller: _doc1Name, label: 'اسم الملف الأول'),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(controller: _doc1Url, label: 'رابط الملف الأول'),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(controller: _doc2Name, label: 'اسم الملف الثاني'),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(controller: _doc2Url, label: 'رابط الملف الثاني'),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              text: 'إرسال طلب التوثيق',
              isLoading: state.loading,
              onPressed: () async {
                final ok = await ref
                    .read(providerOnboardingControllerProvider.notifier)
                    .submitVerification(
                        _notes.text.trim().isEmpty ? null : _notes.text.trim());
                if (!context.mounted) return;
                if (!ok) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(ref
                              .read(providerOnboardingControllerProvider)
                              .errorMessage ??
                          'تعذر إنشاء طلب التوثيق')));
                  return;
                }

                final add1 = await ref
                    .read(providerOnboardingControllerProvider.notifier)
                    .addVerificationDocument(
                      documentType: doc1Type,
                      fileName: _doc1Name.text.trim(),
                      fileUrl: _doc1Url.text.trim(),
                    );
                final add2 = await ref
                    .read(providerOnboardingControllerProvider.notifier)
                    .addVerificationDocument(
                      documentType: doc2Type,
                      fileName: _doc2Name.text.trim(),
                      fileUrl: _doc2Url.text.trim(),
                    );

                if (!context.mounted) return;
                if (add1 && add2) {
                  context.go(RouteNames.providerStatus);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(ref
                              .read(providerOnboardingControllerProvider)
                              .errorMessage ??
                          'تم إنشاء الطلب لكن فشل إرفاق بعض المستندات')));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
