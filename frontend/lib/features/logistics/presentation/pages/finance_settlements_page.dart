import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/features/logistics/data/logistics_repository.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:ghiyarak/shared/widgets/section_title.dart';

final _settlementsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
        (ref) => ref.read(logisticsRepositoryProvider).financeSettlements());

class FinanceSettlementsPage extends ConsumerWidget {
  const FinanceSettlementsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settlements = ref.watch(_settlementsProvider);
    return AppScaffold(
      title: 'التسويات',
      child: settlements.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (items) => ListView.separated(
          itemCount: items.isEmpty ? 2 : items.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) {
            if (index == 0) {
              return const SectionTitle(
                  title: 'تسويات التجار والورش',
                  subtitle: 'اعتماد وتعليم التسويات كمدفوعة.');
            }
            if (items.isEmpty) {
              return const Center(
                  child: Padding(
                      padding: EdgeInsets.all(AppSpacing.xl),
                      child: Text('لا توجد تسويات حالياً.')));
            }
            final map = items[index - 1];
            final org = map['organization'] is Map
                ? Map<String, dynamic>.from(map['organization'] as Map)
                : <String, dynamic>{};
            return Card(
                child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              '${map['settlementNumber'] ?? map['settlement_number'] ?? map['id']}',
                              style: Theme.of(context).textTheme.titleMedium),
                          Text(
                              'المالك: ${org['displayName'] ?? org['display_name'] ?? '-'}'),
                          Text('الحالة: ${map['status']}'),
                          Text(
                              'المبلغ: ${map['amount']} ${map['currency'] ?? 'YER'}'),
                          const SizedBox(height: AppSpacing.md),
                          Row(children: [
                            Expanded(
                                child: AppButton(
                                    text: 'اعتماد',
                                    onPressed: () async {
                                      await ref
                                          .read(logisticsRepositoryProvider)
                                          .approveSettlement('${map['id']}');
                                      ref.invalidate(_settlementsProvider);
                                    })),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                                child: AppButton(
                                    text: 'مدفوعة',
                                    isOutlined: true,
                                    onPressed: () async {
                                      await ref
                                          .read(logisticsRepositoryProvider)
                                          .markSettlementPaid('${map['id']}');
                                      ref.invalidate(_settlementsProvider);
                                    })),
                          ]),
                        ])));
          },
        ),
      ),
    );
  }
}
