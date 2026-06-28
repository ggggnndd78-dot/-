import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/features/wallet_loyalty/data/wallet_loyalty_repository.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:ghiyarak/shared/widgets/section_title.dart';

final loyaltyFutureProvider = FutureProvider.autoDispose<Map<String, dynamic>>(
    (ref) => ref.watch(walletLoyaltyRepositoryProvider).myLoyalty());
final couponsFutureProvider = FutureProvider.autoDispose<Map<String, dynamic>>(
    (ref) => ref.watch(walletLoyaltyRepositoryProvider).coupons());

class LoyaltyPage extends ConsumerStatefulWidget {
  const LoyaltyPage({super.key});
  @override
  ConsumerState<LoyaltyPage> createState() => _LoyaltyPageState();
}

class _LoyaltyPageState extends ConsumerState<LoyaltyPage> {
  final _points = TextEditingController();
  bool _busy = false;
  @override
  void dispose() {
    _points.dispose();
    super.dispose();
  }

  Future<void> _redeem() async {
    final points = int.tryParse(_points.text.trim());
    if (points == null || points <= 0) return;
    setState(() => _busy = true);
    try {
      await ref.read(walletLoyaltyRepositoryProvider).redeemPoints(points);
      ref.invalidate(loyaltyFutureProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إرسال طلب الاستبدال')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loyalty = ref.watch(loyaltyFutureProvider);
    final coupons = ref.watch(couponsFutureProvider);
    return AppScaffold(
      title: 'الولاء والكوبونات',
      child: loyalty.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('تعذر تحميل الولاء: $e'),
        data: (response) {
          final data = response['data'] as Map<String, dynamic>? ?? {};
          return ListView(children: [
            SectionTitle(
                title: '${data['pointsBalance'] ?? 0} نقطة',
                subtitle: 'المستوى: ${data['tier'] ?? 'BRONZE'}'),
            const SizedBox(height: AppSpacing.md),
            TextField(
                controller: _points,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'عدد النقاط للاستبدال')),
            const SizedBox(height: AppSpacing.md),
            AppButton(
                text: _busy ? 'جاري التنفيذ...' : 'استبدال النقاط إلى المحفظة',
                onPressed: _busy ? null : _redeem),
            const SizedBox(height: AppSpacing.xl),
            const Text('الكوبونات المتاحة',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.sm),
            coupons.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('$e'),
              data: (r) {
                final items = (r['data'] as List?) ?? [];
                if (items.isEmpty) return const Text('لا توجد كوبونات نشطة.');
                return Column(
                    children: items
                        .map((e) => Card(
                            child: ListTile(
                                title: Text('${e['code']}'),
                                subtitle: Text(e['titleAr']?.toString() ??
                                    e['title']?.toString() ??
                                    ''),
                                trailing: Text('${e['discountValue'] ?? ''}'))))
                        .toList());
              },
            ),
          ]);
        },
      ),
    );
  }
}
