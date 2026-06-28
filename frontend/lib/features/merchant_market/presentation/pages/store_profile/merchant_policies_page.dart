import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/features/merchant_market/data/merchant_market_repository.dart';
import 'package:ghiyarak/features/merchant_market/data/models/merchant_organization_model.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_management_scaffold.dart';

class MerchantPoliciesPage extends ConsumerStatefulWidget {
  const MerchantPoliciesPage({super.key});

  @override
  ConsumerState<MerchantPoliciesPage> createState() =>
      _MerchantPoliciesPageState();
}

class _MerchantPoliciesPageState extends ConsumerState<MerchantPoliciesPage> {
  final _category = TextEditingController();
  final _preparation = TextEditingController();
  final _minOrder = TextEditingController();
  final _warranty = TextEditingController();
  final _returns = TextEditingController();
  final _delivery = TextEditingController();
  late Future<MerchantOrganizationModel> _future;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    for (final controller in [
      _category,
      _preparation,
      _minOrder,
      _warranty,
      _returns,
      _delivery
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<MerchantOrganizationModel> _load() async {
    final data = await ref
        .read(merchantMarketRepositoryProvider)
        .getMerchantOrganization();
    final profile = data.merchantProfile;
    _category.text = profile?.businessCategoryCode ?? 'auto-parts';
    _preparation.text = profile?.averagePreparationMinutes?.toString() ?? '60';
    _minOrder.text = profile?.minOrderAmount?.toString() ?? '0';
    _warranty.text = profile?.warrantyPolicy ??
        'ضمان القطع حسب سياسة الوكيل أو المورد، مع ضرورة إبراز الفاتورة عند المطالبة بالضمان.';
    _returns.text = profile?.returnPolicy ??
        'يمكن إرجاع المنتج خلال المدة المحددة بشرط أن يكون بحالته الأصلية وغير مستخدم، مع وجود الفاتورة.';
    _delivery.text = profile?.deliveryPolicy ??
        'تتم معالجة الطلبات حسب أوقات عمل الفرع، وتظهر تكلفة ومدة التوصيل للعميل قبل تأكيد الطلب.';
    return data;
  }

  Future<void> _save(MerchantOrganizationModel organization) async {
    setState(() => _saving = true);
    try {
      await ref.read(merchantMarketRepositoryProvider).updateMerchantPolicies(
            organizationId: organization.id,
            businessCategoryCode: _category.text,
            averagePreparationMinutes: int.tryParse(_preparation.text.trim()),
            minOrderAmount: double.tryParse(_minOrder.text.trim()),
            warrantyPolicyText: _warranty.text,
            returnPolicyText: _returns.text,
            deliveryPolicyText: _delivery.text,
          );
      if (!mounted) return;
      setState(() => _future = _load());
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ السياسات التشغيلية')));
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MerchantOrganizationModel>(
      future: _future,
      builder: (context, snapshot) {
        return MerchantManagementScaffold(
          title: 'سياسات المتجر',
          subtitle: 'سياسات الإرجاع، الضمان، الشحن، والحدود التشغيلية',
          onRefresh: () async {
            setState(() => _future = _load());
            await _future;
          },
          children: [
            if (snapshot.connectionState != ConnectionState.done)
              const Center(child: CircularProgressIndicator())
            else if (snapshot.hasError)
              MerchantStateCard(
                icon: Icons.error_outline,
                title: 'تعذر تحميل السياسات',
                message: snapshot.error.toString(),
                actionLabel: 'إعادة المحاولة',
                onAction: () => setState(() => _future = _load()),
              )
            else ...[
              MerchantPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('الإعدادات التشغيلية',
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: Color(0xFF082B51))),
                    const SizedBox(height: 12),
                    TextField(
                        controller: _category,
                        decoration: const InputDecoration(
                            labelText: 'تصنيف النشاط التجاري')),
                    const SizedBox(height: 10),
                    TextField(
                        controller: _preparation,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: const InputDecoration(
                            labelText: 'متوسط تجهيز الطلب بالدقائق')),
                    const SizedBox(height: 10),
                    TextField(
                        controller: _minOrder,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'أقل مبلغ طلب اختياري')),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _PolicyBox(
                  title: 'سياسة الضمان',
                  icon: Icons.verified_user_outlined,
                  controller: _warranty),
              const SizedBox(height: 14),
              _PolicyBox(
                  title: 'سياسة الإرجاع والاستبدال',
                  icon: Icons.assignment_return_outlined,
                  controller: _returns),
              const SizedBox(height: 14),
              _PolicyBox(
                  title: 'سياسة الشحن والتوصيل',
                  icon: Icons.local_shipping_outlined,
                  controller: _delivery),
              const SizedBox(height: 14),
              FilledButton.icon(
                  onPressed: _saving ? null : () => _save(snapshot.requireData),
                  icon: const Icon(Icons.save_outlined),
                  label: Text(_saving ? 'جارٍ الحفظ...' : 'حفظ كل السياسات')),
            ],
          ],
        );
      },
    );
  }
}

class _PolicyBox extends StatelessWidget {
  const _PolicyBox(
      {required this.title, required this.icon, required this.controller});
  final String title;
  final IconData icon;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return MerchantPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: const Color(0xFFFF7900)),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                    color: Color(0xFF082B51)))
          ]),
          const SizedBox(height: 12),
          TextField(
              controller: controller,
              minLines: 4,
              maxLines: 8,
              decoration:
                  InputDecoration(hintText: 'اكتب $title التي ستظهر للعميل')),
        ],
      ),
    );
  }
}
