import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/features/wallet_loyalty/data/wallet_loyalty_repository.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:ghiyarak/shared/widgets/section_title.dart';

final walletFutureProvider = FutureProvider.autoDispose<Map<String, dynamic>>(
    (ref) => ref.watch(walletLoyaltyRepositoryProvider).myWallet());
final walletLedgerFutureProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>(
        (ref) => ref.watch(walletLoyaltyRepositoryProvider).walletLedger());

class WalletPage extends ConsumerStatefulWidget {
  const WalletPage({super.key});
  @override
  ConsumerState<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends ConsumerState<WalletPage> {
  final _amount = TextEditingController();
  bool _busy = false;
  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _topUp() async {
    final amount = double.tryParse(_amount.text.trim());
    if (amount == null || amount <= 0) return;
    setState(() => _busy = true);
    try {
      await ref.read(walletLoyaltyRepositoryProvider).topUpWallet(amount);
      ref.invalidate(walletFutureProvider);
      ref.invalidate(walletLedgerFutureProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إرسال طلب الشحن للمراجعة')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(walletFutureProvider);
    final ledger = ref.watch(walletLedgerFutureProvider);
    return AppScaffold(
      title: 'محفظتي',
      child: wallet.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('تعذر تحميل المحفظة: $e'),
        data: (response) {
          final data = response['data'] as Map<String, dynamic>? ?? {};
          return ListView(children: [
            SectionTitle(
                title: '${data['balance'] ?? 0} ${data['currency'] ?? 'YER'}',
                subtitle: 'الرصيد المتاح في المحفظة'),
            const SizedBox(height: AppSpacing.md),
            TextField(
                controller: _amount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'مبلغ الشحن')),
            const SizedBox(height: AppSpacing.md),
            AppButton(
                text: _busy ? 'جاري الإرسال...' : 'طلب شحن المحفظة',
                onPressed: _busy ? null : _topUp),
            const SizedBox(height: AppSpacing.xl),
            const Text('آخر العمليات',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.sm),
            ledger.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('$e'),
              data: (r) {
                final items = (r['data'] as List?) ?? [];
                if (items.isEmpty) {
                  return const Text('لا توجد عمليات حتى الآن.');
                }
                return Column(
                    children: items
                        .map((e) => Card(
                            child: ListTile(
                                title:
                                    Text('${e['entryType']} - ${e['amount']}'),
                                subtitle:
                                    Text(e['description']?.toString() ?? ''),
                                trailing:
                                    Text(e['direction']?.toString() ?? ''))))
                        .toList());
              },
            ),
          ]);
        },
      ),
    );
  }
}
