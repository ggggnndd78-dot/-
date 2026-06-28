import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/features/wallet_loyalty/data/wallet_loyalty_repository.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:ghiyarak/shared/widgets/section_title.dart';

final adminCouponsProvider = FutureProvider.autoDispose<Map<String, dynamic>>(
    (ref) => ref.watch(walletLoyaltyRepositoryProvider).adminCoupons());

class AdminCouponsPage extends ConsumerStatefulWidget {
  const AdminCouponsPage({super.key});

  @override
  ConsumerState<AdminCouponsPage> createState() => _AdminCouponsPageState();
}

class _AdminCouponsPageState extends ConsumerState<AdminCouponsPage> {
  final _code = TextEditingController();
  final _title = TextEditingController();
  final _value = TextEditingController(text: '10');
  String _type = 'PERCENTAGE';
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    _title.dispose();
    _value.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final code = _code.text.trim();
    final title = _title.text.trim();
    final value = double.tryParse(_value.text.trim()) ?? 0;
    if (code.isEmpty || title.isEmpty) return;
    setState(() => _busy = true);
    try {
      await ref.read(walletLoyaltyRepositoryProvider).createCoupon(
          code: code,
          titleAr: title,
          discountType: _type,
          discountValue: _type == 'FREE_DELIVERY' ? 0 : value);
      _code.clear();
      _title.clear();
      ref.invalidate(adminCouponsProvider);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminCouponsProvider);
    return AppScaffold(
      title: 'إدارة الكوبونات',
      child: ListView(children: [
        const SectionTitle(
            title: 'الكوبونات والحملات',
            subtitle: 'أنشئ كوبونات خصم أو توصيل مجاني مع حدود استخدام واضحة.'),
        const SizedBox(height: AppSpacing.md),
        TextField(
            controller: _code,
            decoration: const InputDecoration(labelText: 'الكود')),
        const SizedBox(height: AppSpacing.sm),
        TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'عنوان الكوبون')),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<String>(
            initialValue: _type,
            items: const [
              DropdownMenuItem(value: 'PERCENTAGE', child: Text('نسبة مئوية')),
              DropdownMenuItem(value: 'FIXED_AMOUNT', child: Text('مبلغ ثابت')),
              DropdownMenuItem(
                  value: 'FREE_DELIVERY', child: Text('توصيل مجاني')),
            ],
            onChanged: (value) =>
                setState(() => _type = value ?? 'PERCENTAGE')),
        const SizedBox(height: AppSpacing.sm),
        if (_type != 'FREE_DELIVERY')
          TextField(
              controller: _value,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'قيمة الخصم')),
        const SizedBox(height: AppSpacing.md),
        AppButton(
            text: _busy ? 'جاري الحفظ...' : 'إنشاء كوبون',
            onPressed: _busy ? null : _create),
        const SizedBox(height: AppSpacing.xl),
        state.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('تعذر تحميل الكوبونات: $e'),
          data: (response) {
            final items = (response['data'] as List?) ?? [];
            if (items.isEmpty) return const Text('لا توجد كوبونات.');
            return Column(
                children: items
                    .map((item) => Card(
                        child: ListTile(
                            title: Text('${item['code']}'),
                            subtitle: Text(
                                '${item['titleAr'] ?? ''} — ${item['status']}'),
                            trailing:
                                Text('${item['usedCount'] ?? 0} استخدام'))))
                    .toList());
          },
        ),
      ]),
    );
  }
}
