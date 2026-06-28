import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/features/merchant_market/data/models/merchant_finance_model.dart';
import 'package:ghiyarak/features/merchant_market/data/merchant_market_repository.dart';
import 'package:ghiyarak/features/merchant_market/presentation/pages/finance_reports/merchant_finance_helpers.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_management_scaffold.dart';

class MerchantFinanceOverviewPage extends ConsumerStatefulWidget {
  const MerchantFinanceOverviewPage({super.key});

  @override
  ConsumerState<MerchantFinanceOverviewPage> createState() =>
      _MerchantFinanceOverviewPageState();
}

class _MerchantFinanceOverviewPageState
    extends ConsumerState<MerchantFinanceOverviewPage> {
  late Future<MerchantFinanceSummary> _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<MerchantFinanceSummary> _load() =>
      ref.read(merchantMarketRepositoryProvider).getMerchantFinanceSummary();
  void _refresh() => setState(() => _future = _load());

  Future<void> _export() async {
    final csv = await ref
        .read(merchantMarketRepositoryProvider)
        .getMerchantFinanceStatementCsv();
    if (mounted) await copyCsvToClipboard(context, csv);
  }

  Future<void> _withdraw(MerchantFinanceSummary summary) async {
    final amountController = TextEditingController(
        text: summary.withdrawableBalance > 0
            ? summary.withdrawableBalance.toStringAsFixed(0)
            : '');
    final noteController = TextEditingController();
    final result = await showDialog<num>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('طلب سحب رصيد'),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(
                    'الرصيد القابل للسحب: ${merchantMoney(summary.withdrawableBalance, summary.currency)}'),
                const SizedBox(height: 12),
                TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'المبلغ', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(
                    controller: noteController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                        labelText: 'ملاحظة اختيارية',
                        border: OutlineInputBorder())),
              ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء')),
                FilledButton(
                    onPressed: () => Navigator.pop(context,
                        num.tryParse(amountController.text.trim()) ?? 0),
                    child: const Text('إرسال الطلب')),
              ],
            ));
    if (result == null || result <= 0) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(merchantMarketRepositoryProvider)
          .requestMerchantWithdrawal(
              amount: result,
              currency: summary.currency,
              note: noteController.text);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إرسال طلب السحب للإدارة')));
      _refresh();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('تعذر إرسال طلب السحب: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MerchantFinanceSummary>(
        future: _future,
        builder: (context, snapshot) {
          final summary = snapshot.data;
          return MerchantManagementScaffold(
            title: 'المالية والمحفظة',
            subtitle:
                'إدارة الرصيد، المدفوعات، الفواتير، التسويات، وكشف حساب التاجر.',
            onRefresh: () async => _refresh(),
            children: [
              if (snapshot.connectionState != ConnectionState.done &&
                  summary == null)
                const Center(child: CircularProgressIndicator())
              else if (snapshot.hasError)
                MerchantStateCard(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'تعذر تحميل البيانات المالية',
                    message: snapshot.error.toString(),
                    actionLabel: 'إعادة المحاولة',
                    onAction: _refresh)
              else if (summary != null) ...[
                FinanceActionBar(
                    onExport: _busy ? null : _export,
                    onWithdraw: _busy ? null : () => _withdraw(summary)),
                const SizedBox(height: 12),
                FinanceSummaryGrid(summary: summary),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                      child: MerchantMetricTile(
                          icon: Icons.receipt_long_outlined,
                          label: 'عدد الفواتير',
                          value: summary.invoiceCount.toStringAsFixed(0))),
                  const SizedBox(width: 10),
                  Expanded(
                      child: MerchantMetricTile(
                          icon: Icons.request_quote_outlined,
                          label: 'قيمة الفواتير',
                          value: merchantMoney(
                              summary.invoiceTotal, summary.currency))),
                ]),
                const SizedBox(height: 14),
                FinanceStatusPanel(
                    title: 'حالة المدفوعات', items: summary.paymentStatuses),
                const SizedBox(height: 12),
                FinanceStatusPanel(
                    title: 'حالة التسويات والسحوبات',
                    items: summary.settlementStatuses),
                const SizedBox(height: 12),
                MerchantPanel(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      const Text('أحدث الحركات المالية',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 10),
                      LedgerList(items: summary.ledger),
                    ])),
              ],
            ],
          );
        });
  }
}
