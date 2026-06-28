import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ghiyarak/features/merchant_market/data/models/merchant_finance_model.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_management_scaffold.dart';

class FinanceSummaryGrid extends StatelessWidget {
  const FinanceSummaryGrid({required this.summary, super.key});
  final MerchantFinanceSummary summary;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        Icons.account_balance_wallet_outlined,
        'الرصيد المتاح',
        merchantMoney(summary.availableBalance, summary.currency)
      ),
      (
        Icons.pending_actions_outlined,
        'قيد التسوية',
        merchantMoney(summary.pendingBalance, summary.currency)
      ),
      (
        Icons.shopping_bag_outlined,
        'إجمالي المبيعات',
        merchantMoney(summary.totalSales, summary.currency)
      ),
      (
        Icons.percent_outlined,
        'عمولة المنصة',
        merchantMoney(summary.totalCommission, summary.currency)
      ),
      (
        Icons.savings_outlined,
        'صافي المستحقات',
        merchantMoney(summary.netEarnings, summary.currency)
      ),
      (
        Icons.request_quote_outlined,
        'قابل للسحب',
        merchantMoney(summary.withdrawableBalance, summary.currency)
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 520;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isWide ? 3 : 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: isWide ? 2.4 : 1.45,
          ),
          itemBuilder: (context, index) => MerchantMetricTile(
            icon: items[index].$1,
            label: items[index].$2,
            value: items[index].$3,
          ),
        );
      },
    );
  }
}

class FinanceStatusPanel extends StatelessWidget {
  const FinanceStatusPanel(
      {required this.title, required this.items, super.key});
  final String title;
  final List<MerchantFinanceStatusAggregate> items;

  @override
  Widget build(BuildContext context) {
    return MerchantPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF082B51))),
          const SizedBox(height: 10),
          if (items.isEmpty)
            const Text('لا توجد بيانات بعد.',
                style: TextStyle(color: Color(0xFF687686)))
          else
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                          child: Text(merchantFinanceStatusLabel(item.status))),
                      Text('${item.count} عملية'),
                      const SizedBox(width: 12),
                      Text(merchantMoney(item.total),
                          style: const TextStyle(fontWeight: FontWeight.w900)),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}

class FinanceActionBar extends StatelessWidget {
  const FinanceActionBar({super.key, this.onExport, this.onWithdraw});
  final VoidCallback? onExport;
  final VoidCallback? onWithdraw;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton.icon(
          onPressed: onWithdraw,
          icon: const Icon(Icons.output_outlined),
          label: const Text('طلب سحب'),
        ),
        OutlinedButton.icon(
          onPressed: onExport,
          icon: const Icon(Icons.file_download_outlined),
          label: const Text('تصدير كشف CSV'),
        ),
      ],
    );
  }
}

class LedgerList extends StatelessWidget {
  const LedgerList({required this.items, super.key});
  final List<MerchantLedgerEntry> items;
  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const MerchantStateCard(
          icon: Icons.receipt_long_outlined,
          title: 'لا توجد حركات مالية',
          message: 'ستظهر الحركات بعد الدفع أو التسوية أو السحب.');
    }
    return Column(
        children: items
            .take(20)
            .map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: MerchantPanel(
                    child: Row(
                      children: [
                        Icon(
                            item.amount >= 0
                                ? Icons.call_received_outlined
                                : Icons.call_made_outlined,
                            color: const Color(0xFFFF7900)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(merchantFinanceStatusLabel(item.type),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w900)),
                                if (item.description.isNotEmpty)
                                  Text(item.description,
                                      style: const TextStyle(
                                          color: Color(0xFF687686))),
                                if (item.createdAt.isNotEmpty)
                                  Text(item.createdAt,
                                      style: const TextStyle(
                                          color: Color(0xFF8A98A8),
                                          fontSize: 12)),
                              ]),
                        ),
                        Text(merchantMoney(item.amount, item.currency),
                            style:
                                const TextStyle(fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                ))
            .toList());
  }
}

Future<void> copyCsvToClipboard(BuildContext context, String csv) async {
  if (csv.trim().isEmpty) return;
  await Clipboard.setData(ClipboardData(text: csv));
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم نسخ كشف CSV ويمكن لصقه في Excel')));
  }
}
