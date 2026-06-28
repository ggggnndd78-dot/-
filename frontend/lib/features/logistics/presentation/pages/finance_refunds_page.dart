import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/features/logistics/data/logistics_repository.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:ghiyarak/shared/widgets/section_title.dart';

final _refundsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
    (ref) => ref.read(logisticsRepositoryProvider).financeRefunds());

class FinanceRefundsPage extends ConsumerWidget {
  const FinanceRefundsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refunds = ref.watch(_refundsProvider);
    return AppScaffold(
      title: 'طلبات الاسترداد',
      child: refunds.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (items) => ListView.separated(
          itemCount: items.isEmpty ? 2 : items.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) {
            if (index == 0) {
              return const SectionTitle(
                  title: 'الاستردادات',
                  subtitle: 'طلبات استرداد قابلة للمراجعة المالية.');
            }
            if (items.isEmpty) {
              return const Center(
                  child: Padding(
                      padding: EdgeInsets.all(AppSpacing.xl),
                      child: Text('لا توجد طلبات استرداد.')));
            }
            final map = items[index - 1];
            return Card(
                child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              '${map['refundNumber'] ?? map['refund_number'] ?? map['id']}',
                              style: Theme.of(context).textTheme.titleMedium),
                          Text('الحالة: ${map['status']}'),
                          Text(
                              'المبلغ: ${map['amount']} ${map['currency'] ?? 'YER'}'),
                          Text('السبب: ${map['reason'] ?? '-'}'),
                          const SizedBox(height: AppSpacing.md),
                          Row(children: [
                            Expanded(
                                child: AppButton(
                                    text: 'اعتماد',
                                    onPressed: () async {
                                      await ref
                                          .read(logisticsRepositoryProvider)
                                          .approveRefund('${map['id']}');
                                      ref.invalidate(_refundsProvider);
                                    })),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                                child: AppButton(
                                    text: 'تنفيذ الاسترداد',
                                    isOutlined: true,
                                    onPressed: () async {
                                      await ref
                                          .read(logisticsRepositoryProvider)
                                          .markRefunded('${map['id']}');
                                      ref.invalidate(_refundsProvider);
                                    })),
                          ]),
                        ])));
          },
        ),
      ),
    );
  }
}
