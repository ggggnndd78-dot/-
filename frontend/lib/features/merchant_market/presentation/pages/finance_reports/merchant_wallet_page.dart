import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/features/merchant_market/data/models/merchant_finance_model.dart';
import 'package:ghiyarak/features/merchant_market/data/merchant_market_repository.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_management_scaffold.dart';

class MerchantWalletPage extends ConsumerStatefulWidget {
  const MerchantWalletPage({super.key});
  @override
  ConsumerState<MerchantWalletPage> createState() => _MerchantWalletPageState();
}

class _MerchantWalletPageState extends ConsumerState<MerchantWalletPage> {
  late Future<List<MerchantWallet>> _future;
  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<MerchantWallet>> _load() =>
      ref.read(merchantMarketRepositoryProvider).getMerchantWallets();
  void _refresh() => setState(() => _future = _load());
  @override
  Widget build(BuildContext context) => FutureBuilder<List<MerchantWallet>>(
      future: _future,
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <MerchantWallet>[];
        return MerchantManagementScaffold(
            title: 'محفظة التاجر',
            subtitle: 'رصيد المتجر وتفاصيل الحركات لكل محفظة.',
            onRefresh: () async => _refresh(),
            children: [
              if (snapshot.connectionState != ConnectionState.done &&
                  items.isEmpty)
                const Center(child: CircularProgressIndicator())
              else if (snapshot.hasError)
                MerchantStateCard(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'تعذر تحميل المحفظة',
                    message: snapshot.error.toString(),
                    actionLabel: 'إعادة المحاولة',
                    onAction: _refresh)
              else if (items.isEmpty)
                const MerchantStateCard(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'لا توجد محفظة نشطة',
                    message: 'ستظهر محفظة المتجر بعد أول عملية مالية مؤكدة.')
              else ...[
                MerchantMetricTile(
                    icon: Icons.savings_outlined,
                    label: 'إجمالي الرصيد',
                    value: merchantMoney(
                        items.fold<num>(0, (s, e) => s + e.balance),
                        items.first.currency)),
                const SizedBox(height: 14),
                ...items.map((wallet) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: MerchantPanel(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Row(children: [
                            const Icon(Icons.account_balance_wallet_outlined,
                                color: Color(0xFFFF7900)),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Text(wallet.organizationName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16))),
                            Chip(
                                label: Text(
                                    merchantFinanceStatusLabel(wallet.status)))
                          ]),
                          const SizedBox(height: 10),
                          Wrap(spacing: 8, runSpacing: 8, children: [
                            Chip(
                                label: Text(
                                    'الرصيد: ${merchantMoney(wallet.balance, wallet.currency)}')),
                            Chip(
                                label: Text(
                                    'متاح: ${merchantMoney(wallet.availableBalance, wallet.currency)}')),
                            Chip(
                                label: Text(
                                    'معلق: ${merchantMoney(wallet.pendingBalance, wallet.currency)}')),
                            if (wallet.updatedAt.isNotEmpty)
                              Chip(
                                  label: Text('آخر تحديث: ${wallet.updatedAt}'))
                          ]),
                          const SizedBox(height: 8),
                          Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: TextButton.icon(
                                  onPressed: () => _showTransactions(wallet),
                                  icon: const Icon(Icons.history_outlined),
                                  label: const Text('عرض الحركات'))),
                        ])))),
              ]
            ]);
      });
  Future<void> _showTransactions(MerchantWallet wallet) async {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => Directionality(
            textDirection: TextDirection.rtl,
            child: FutureBuilder<List<MerchantWalletTransaction>>(
                future: ref
                    .read(merchantMarketRepositoryProvider)
                    .getMerchantWalletTransactions(wallet.id),
                builder: (context, snapshot) {
                  final items =
                      snapshot.data ?? const <MerchantWalletTransaction>[];
                  return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('حركات ${wallet.organizationName}',
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 12),
                            if (snapshot.connectionState !=
                                ConnectionState.done)
                              const Center(child: CircularProgressIndicator())
                            else if (snapshot.hasError)
                              Text('تعذر التحميل: ${snapshot.error}')
                            else if (items.isEmpty)
                              const Text('لا توجد حركات لهذه المحفظة.')
                            else
                              ...items.take(30).map((tx) => ListTile(
                                  leading: Icon(tx.type == 'DEBIT'
                                      ? Icons.call_made_outlined
                                      : Icons.call_received_outlined),
                                  title:
                                      Text(merchantFinanceStatusLabel(tx.type)),
                                  subtitle: Text([tx.note, tx.createdAt]
                                      .where((e) => e.isNotEmpty)
                                      .join('\n')),
                                  trailing: Text(merchantMoney(
                                      tx.amount, wallet.currency)))),
                          ]));
                })));
  }
}
