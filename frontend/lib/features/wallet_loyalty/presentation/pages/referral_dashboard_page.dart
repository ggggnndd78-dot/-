import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/features/wallet_loyalty/data/wallet_loyalty_repository.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:ghiyarak/shared/widgets/section_title.dart';

final referralDashboardProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) =>
        ref.watch(walletLoyaltyRepositoryProvider).referralDashboard());

class ReferralDashboardPage extends ConsumerStatefulWidget {
  const ReferralDashboardPage({super.key});

  @override
  ConsumerState<ReferralDashboardPage> createState() =>
      _ReferralDashboardPageState();
}

class _ReferralDashboardPageState extends ConsumerState<ReferralDashboardPage> {
  final _code = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    final code = _code.text.trim();
    if (code.isEmpty) return;
    setState(() => _busy = true);
    try {
      await ref.read(walletLoyaltyRepositoryProvider).applyReferralCode(code);
      ref.invalidate(referralDashboardProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تم ربط كود الإحالة')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(referralDashboardProvider);
    return AppScaffold(
      title: 'الإحالات والمكافآت',
      child: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('تعذر تحميل الإحالات: $e'),
        data: (response) {
          final data = response['data'] as Map<String, dynamic>? ?? {};
          final code = data['code'] as Map<String, dynamic>? ?? {};
          final relationships = (data['relationships'] as List?) ?? [];
          return ListView(children: [
            SectionTitle(
                title: 'كودك: ${code['code'] ?? '-'}',
                subtitle:
                    'شارك الكود مع أصدقائك. المكافأة تضاف بعد أول نشاط مؤهل.'),
            const SizedBox(height: AppSpacing.lg),
            TextField(
                controller: _code,
                decoration:
                    const InputDecoration(labelText: 'لديك كود إحالة؟')),
            const SizedBox(height: AppSpacing.md),
            AppButton(
                text: _busy ? 'جاري التنفيذ...' : 'تطبيق كود الإحالة',
                onPressed: _busy ? null : _apply),
            const SizedBox(height: AppSpacing.xl),
            const Text('الإحالات الخاصة بك',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.sm),
            if (relationships.isEmpty) const Text('لا توجد إحالات بعد.'),
            ...relationships.map((item) => Card(
                  child: ListTile(
                    title: Text('الحالة: ${item['status'] ?? '-'}'),
                    subtitle: Text(
                        'المكافآت: ${((item as Map)['rewards'] as List?)?.length ?? 0}'),
                  ),
                )),
          ]);
        },
      ),
    );
  }
}
