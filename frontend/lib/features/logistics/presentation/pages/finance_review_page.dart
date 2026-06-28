import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/features/logistics/data/logistics_repository.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:ghiyarak/shared/widgets/section_title.dart';

final _financeProofsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) => ref
        .read(logisticsRepositoryProvider)
        .financePaymentProofs(status: 'PENDING_REVIEW'));

class FinanceReviewPage extends ConsumerWidget {
  const FinanceReviewPage({super.key});

  Future<void> _approve(WidgetRef ref, BuildContext context, String id) async {
    await ref
        .read(logisticsRepositoryProvider)
        .approvePaymentProof(id, note: 'تمت الموافقة من المالية');
    ref.invalidate(_financeProofsProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('تم اعتماد الإثبات')));
    }
  }

  Future<void> _reject(WidgetRef ref, BuildContext context, String id) async {
    await ref
        .read(logisticsRepositoryProvider)
        .rejectPaymentProof(id, note: 'الإثبات غير واضح أو غير مطابق');
    ref.invalidate(_financeProofsProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('تم رفض الإثبات')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proofs = ref.watch(_financeProofsProvider);
    return AppScaffold(
      title: 'مراجعة المدفوعات',
      child: proofs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (items) => ListView.separated(
          itemCount: items.isEmpty ? 2 : items.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) {
            if (index == 0) {
              return const SectionTitle(
                  title: 'إثباتات التحويل',
                  subtitle:
                      'اعتماد أو رفض إثباتات الدفع البنكي والمحافظ المحلية.');
            }
            if (items.isEmpty) {
              return const Center(
                  child: Padding(
                      padding: EdgeInsets.all(AppSpacing.xl),
                      child: Text('لا توجد إثباتات بانتظار المراجعة.')));
            }
            final map = items[index - 1];
            final payment = map['payment'] is Map
                ? Map<String, dynamic>.from(map['payment'] as Map)
                : <String, dynamic>{};
            return Card(
                child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('إثبات #${map['id']}',
                              style: Theme.of(context).textTheme.titleMedium),
                          Text('الحالة: ${map['status']}'),
                          Text(
                              'المبلغ: ${payment['amount'] ?? map['amount'] ?? '-'} ${payment['currency'] ?? 'YER'}'),
                          Text(
                              'الملف: ${map['fileUrl'] ?? map['file_url'] ?? '-'}'),
                          const SizedBox(height: AppSpacing.md),
                          Row(children: [
                            Expanded(
                                child: AppButton(
                                    text: 'اعتماد',
                                    onPressed: () => _approve(
                                        ref, context, '${map['id']}'))),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                                child: AppButton(
                                    text: 'رفض',
                                    isOutlined: true,
                                    onPressed: () =>
                                        _reject(ref, context, '${map['id']}'))),
                          ]),
                        ])));
          },
        ),
      ),
    );
  }
}
