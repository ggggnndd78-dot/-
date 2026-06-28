import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/features/logistics/data/logistics_repository.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:ghiyarak/shared/widgets/section_title.dart';

final _accountsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
        (ref) => ref.read(logisticsRepositoryProvider).accountingAccounts());
final _journalsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) =>
        ref.read(logisticsRepositoryProvider).accountingJournalEntries());
final _transactionsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) => ref
        .read(logisticsRepositoryProvider)
        .accountingFinancialTransactions());
final _balancesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) =>
        ref.read(logisticsRepositoryProvider).accountingMerchantBalances());

class FinanceAccountingPage extends ConsumerWidget {
  const FinanceAccountingPage({super.key});

  String _money(dynamic value, [String currency = 'YER']) =>
      '${value ?? 0} $currency';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(_accountsProvider);
    final journals = ref.watch(_journalsProvider);
    final transactions = ref.watch(_transactionsProvider);
    final balances = ref.watch(_balancesProvider);

    return AppScaffold(
      title: 'القيود والنزاهة المالية',
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(_accountsProvider);
          ref.invalidate(_journalsProvider);
          ref.invalidate(_transactionsProvider);
          ref.invalidate(_balancesProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            const SectionTitle(
              title: 'الدفتر المحاسبي',
              subtitle:
                  'عرض الحسابات، القيود، الحركات المالية، وأرصدة التجار والورش بدون تعديل يدوي على القيود.',
            ),
            const SizedBox(height: AppSpacing.md),
            _asyncBlock(context, 'أرصدة التجار والورش', balances, (items) {
              if (items.isEmpty) return const Text('لا توجد أرصدة مالية بعد.');
              return Column(
                  children: items.map((item) {
                final org = item['organization'] is Map
                    ? Map<String, dynamic>.from(item['organization'] as Map)
                    : <String, dynamic>{};
                return _tile(
                  context,
                  title: org['displayName'] ??
                      org['display_name'] ??
                      'مؤسسة #${item['organizationId'] ?? item['organization_id']}',
                  subtitle:
                      'قيد التحصيل: ${_money(item['pendingBalance'] ?? item['pending_balance'], item['currency'] ?? 'YER')} | متاح: ${_money(item['availableBalance'] ?? item['available_balance'], item['currency'] ?? 'YER')}',
                  trailing:
                      'مسدد: ${_money(item['settledBalance'] ?? item['settled_balance'], item['currency'] ?? 'YER')}',
                );
              }).toList());
            }),
            _asyncBlock(context, 'آخر القيود اليومية', journals, (items) {
              if (items.isEmpty) return const Text('لا توجد قيود محاسبية بعد.');
              return Column(
                  children: items
                      .take(10)
                      .map((item) => _tile(
                            context,
                            title: item['entryNumber'] ??
                                item['entry_number'] ??
                                'قيد #${item['id']}',
                            subtitle:
                                '${item['sourceType'] ?? item['source_type']} • ${item['status']}',
                            trailing:
                                'مدين ${_money(item['totalDebit'] ?? item['total_debit'], item['currency'] ?? 'YER')} / دائن ${_money(item['totalCredit'] ?? item['total_credit'], item['currency'] ?? 'YER')}',
                          ))
                      .toList());
            }),
            _asyncBlock(context, 'الحركات المالية', transactions, (items) {
              if (items.isEmpty) return const Text('لا توجد حركات مالية.');
              return Column(
                  children: items
                      .take(10)
                      .map((item) => _tile(
                            context,
                            title: item['transactionNumber'] ??
                                item['transaction_number'] ??
                                'حركة #${item['id']}',
                            subtitle:
                                '${item['sourceType'] ?? item['source_type']} • ${item['direction']}',
                            trailing: _money(
                                item['amount'], item['currency'] ?? 'YER'),
                          ))
                      .toList());
            }),
            _asyncBlock(context, 'دليل الحسابات', accounts, (items) {
              if (items.isEmpty) return const Text('دليل الحسابات غير مهيأ.');
              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: items
                    .map((item) => Chip(
                          label: Text(
                              '${item['code']} - ${item['nameAr'] ?? item['name_ar'] ?? item['nameEn'] ?? item['name_en']}'),
                        ))
                    .toList(),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _asyncBlock(
      BuildContext context,
      String title,
      AsyncValue<List<Map<String, dynamic>>> value,
      Widget Function(List<Map<String, dynamic>>) builder) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          value.when(
            loading: () => const Center(
                child: Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: CircularProgressIndicator())),
            error: (e, _) => Text('تعذر التحميل: $e'),
            data: builder,
          ),
        ]),
      ),
    );
  }

  Widget _tile(BuildContext context,
      {required dynamic title,
      required String subtitle,
      required String trailing}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text('$title', style: Theme.of(context).textTheme.bodyLarge),
      subtitle: Text(subtitle),
      trailing: Text(trailing, textAlign: TextAlign.end),
    );
  }
}
