import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/features/merchant_market/data/merchant_market_repository.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_management_scaffold.dart';

class MerchantPromotionsPage extends ConsumerStatefulWidget {
  const MerchantPromotionsPage({super.key});

  @override
  ConsumerState<MerchantPromotionsPage> createState() =>
      _MerchantPromotionsPageState();
}

class _MerchantPromotionsPageState
    extends ConsumerState<MerchantPromotionsPage> {
  final _code = TextEditingController();
  final _description = TextEditingController();
  final _value = TextEditingController();
  String _type = 'PERCENT';
  late Future<List<Map<String, dynamic>>> _future;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _code.dispose();
    _description.dispose();
    _value.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _load() {
    return ref.read(merchantMarketRepositoryProvider).getCoupons();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_value.text.trim());
    if (_code.text.trim().isEmpty || amount == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(merchantMarketRepositoryProvider).createCoupon(
            code: _code.text,
            discountType: _type,
            discountValue: amount,
            description: _description.text,
          );
      _code.clear();
      _description.clear();
      _value.clear();
      if (mounted) setState(() => _future = _load());
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        return MerchantManagementScaffold(
          title: 'العروض والتسعير',
          subtitle: 'إدارة كوبونات الخصم المتاحة من الخادم',
          onRefresh: () async => setState(() => _future = _load()),
          children: [
            MerchantPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _code,
                    decoration: const InputDecoration(labelText: 'كود الخصم'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _description,
                    decoration: const InputDecoration(labelText: 'الوصف'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: _type,
                    decoration: const InputDecoration(labelText: 'نوع الخصم'),
                    items: const [
                      DropdownMenuItem(value: 'PERCENT', child: Text('نسبة')),
                      DropdownMenuItem(
                          value: 'FIXED', child: Text('مبلغ ثابت')),
                    ],
                    onChanged: (value) =>
                        setState(() => _type = value ?? _type),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _value,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'قيمة الخصم'),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.local_offer_outlined),
                    label: const Text('حفظ العرض'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (snapshot.connectionState != ConnectionState.done)
              const Center(child: CircularProgressIndicator())
            else if (snapshot.hasError)
              MerchantStateCard(
                icon: Icons.lock_outline,
                title: 'تعذر تحميل العروض',
                message:
                    'قد تكون إدارة الكوبونات محصورة بدور إداري. التفاصيل: ${snapshot.error}',
                actionLabel: 'إعادة المحاولة',
                onAction: () => setState(() => _future = _load()),
              )
            else if (snapshot.requireData.isEmpty)
              const MerchantStateCard(
                icon: Icons.local_offer_outlined,
                title: 'لا توجد عروض',
                message: 'لم يرجع الخادم أي كوبونات أو عروض حالياً.',
              )
            else
              ...snapshot.requireData.map(_CouponCard.new),
          ],
        );
      },
    );
  }
}

class _CouponCard extends StatelessWidget {
  const _CouponCard(this.coupon);

  final Map<String, dynamic> coupon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MerchantPanel(
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.local_offer, color: Color(0xFFFF7900)),
          title: Text(
            (coupon['code'] ?? 'كوبون').toString(),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          subtitle: Text(
            [
              (coupon['description'] ?? '').toString(),
              'الخصم: ${coupon['discountValue'] ?? coupon['discount_value'] ?? 0}',
              'الاستخدام: ${coupon['usedCount'] ?? coupon['used_count'] ?? 0}',
            ].where((line) => line.trim().isNotEmpty).join('\n'),
          ),
          trailing: Chip(
            label: Text((coupon['isActive'] ?? coupon['is_active']) == false
                ? 'متوقف'
                : 'نشط'),
          ),
        ),
      ),
    );
  }
}
