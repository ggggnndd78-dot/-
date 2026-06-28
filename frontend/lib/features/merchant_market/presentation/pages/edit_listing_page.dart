import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/features/merchant_market/data/merchant_market_repository.dart';
import 'package:ghiyarak/features/merchant_market/data/models/merchant_listing_model.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_bottom_navigation.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_drawer.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_page_header.dart';
import 'package:ghiyarak/shared/widgets/app_tile_material.dart';
import 'package:go_router/go_router.dart';

class EditListingPage extends ConsumerStatefulWidget {
  const EditListingPage({super.key, required this.listingId});
  final String listingId;

  @override
  ConsumerState<EditListingPage> createState() => _EditListingPageState();
}

class _EditListingPageState extends ConsumerState<EditListingPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _imageUrl = TextEditingController();
  final _price = TextEditingController();
  final _salePrice = TextEditingController();
  final _quantity = TextEditingController();
  final _minOrder = TextEditingController(text: '1');
  int? _warrantyDays;
  String _condition = 'NEW';
  bool _pickup = true;
  bool _delivery = false;
  bool _saving = false;
  bool _filled = false;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _imageUrl.dispose();
    _price.dispose();
    _salePrice.dispose();
    _quantity.dispose();
    _minOrder.dispose();
    super.dispose();
  }

  void _fill(MerchantListingModel item) {
    if (_filled) return;
    _filled = true;
    _title.text = item.title;
    _description.text = item.description ?? item.compatibility ?? '';
    _imageUrl.text = item.imageUrl ?? '';
    _price.text = item.price.toStringAsFixed(2);
    _salePrice.text = item.salePrice?.toStringAsFixed(2) ?? '';
    _quantity.text = item.stock.toString();
    _minOrder.text = item.minOrderQuantity.toString();
    _warrantyDays = item.warrantyDays;
    _condition = item.condition.isEmpty ? 'NEW' : item.condition;
    _pickup = item.supportsPickup;
    _delivery = item.supportsDelivery;
  }

  @override
  Widget build(BuildContext context) {
    final listing = ref.watch(_editListingProvider(widget.listingId));
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF4F6F8),
        drawer:
            const MerchantDrawer(currentTab: MerchantNavigationTab.products),
        bottomNavigationBar: const MerchantBottomNavigation(
            currentTab: MerchantNavigationTab.products, compact: true),
        body: SafeArea(
          top: false,
          child: listing.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) =>
                Center(child: Text('تعذر تحميل المنتج: $error')),
            data: (item) {
              _fill(item);
              return Form(
                key: _formKey,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: MerchantPageHeader(
                        title: 'تعديل المنتج',
                        subtitle:
                            'عدّل السعر والمخزون والحالة دون إنشاء منتج جديد',
                        onMenu: () => _scaffoldKey.currentState?.openDrawer(),
                        notificationCount: 0,
                        onNotifications: () =>
                            context.go(RouteNames.merchantNotifications),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 104),
                      sliver: SliverList.list(children: [
                        _Card(
                          title: 'بيانات أساسية',
                          children: [
                            _ReadOnlySummary(item: item),
                            const SizedBox(height: 12),
                            _Field(
                                label: 'اسم العرض *',
                                controller: _title,
                                validator: _required),
                            _Field(
                                label: 'الوصف / التوافق',
                                controller: _description,
                                minLines: 3,
                                maxLines: 5),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _Card(
                          title: 'الصورة الرئيسية',
                          children: [
                            _ImagePreview(controller: _imageUrl),
                            const SizedBox(height: 10),
                            _Field(
                                label: 'رابط الصورة الرئيسية',
                                controller: _imageUrl,
                                keyboardType: TextInputType.url),
                            const Text(
                              'ملاحظة: رفع الصور المتعددة يتم من صفحة إضافة المنتج، وهنا تستطيع تغيير الصورة الرئيسية للعرض.',
                              style: TextStyle(
                                  color: Color(0xFF6B7C93), fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _Card(
                          title: 'السعر والمخزون',
                          children: [
                            Row(children: [
                              Expanded(
                                  child: _Field(
                                      label: 'السعر *',
                                      controller: _price,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [_money],
                                      validator: _numberRequired)),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: _Field(
                                      label: 'سعر التخفيض',
                                      controller: _salePrice,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [_money])),
                            ]),
                            Row(children: [
                              Expanded(
                                  child: _Field(
                                      label: 'الكمية *',
                                      controller: _quantity,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly
                                      ],
                                      validator: _intRequired)),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: _Field(
                                      label: 'أقل كمية طلب',
                                      controller: _minOrder,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly
                                      ],
                                      validator: _intRequired)),
                            ]),
                            DropdownButtonFormField<int?>(
                              initialValue: _warrantyDays,
                              decoration: _input('الضمان'),
                              items: const [
                                DropdownMenuItem(
                                    value: null, child: Text('بدون ضمان')),
                                DropdownMenuItem(
                                    value: 7, child: Text('7 أيام')),
                                DropdownMenuItem(
                                    value: 30, child: Text('30 يوم')),
                                DropdownMenuItem(
                                    value: 90, child: Text('90 يوم')),
                                DropdownMenuItem(
                                    value: 365, child: Text('سنة')),
                              ],
                              onChanged: (value) =>
                                  setState(() => _warrantyDays = value),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _Card(
                          title: 'خيارات البيع',
                          children: [
                            DropdownButtonFormField<String>(
                              initialValue: _condition,
                              decoration: _input('حالة القطعة'),
                              items: const [
                                DropdownMenuItem(
                                    value: 'NEW', child: Text('جديدة')),
                                DropdownMenuItem(
                                    value: 'USED', child: Text('مستعملة')),
                                DropdownMenuItem(
                                    value: 'REFURBISHED', child: Text('مجددة')),
                              ],
                              onChanged: (value) =>
                                  setState(() => _condition = value ?? 'NEW'),
                            ),
                            SwitchListTile(
                              value: _pickup,
                              onChanged: (value) =>
                                  setState(() => _pickup = value),
                              title: const Text('يدعم الاستلام من الفرع'),
                            ),
                            SwitchListTile(
                              value: _delivery,
                              onChanged: (value) =>
                                  setState(() => _delivery = value),
                              title: const Text('يدعم التوصيل'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.save_outlined),
                          label:
                              Text(_saving ? 'جاري الحفظ...' : 'حفظ التعديلات'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6500),
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(52),
                          ),
                        ),
                      ]),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(merchantMarketRepositoryProvider).updateListing(
            listingId: widget.listingId,
            title: _title.text,
            description: _description.text,
            unitPrice: double.parse(_price.text),
            salePrice: double.tryParse(_salePrice.text),
            availableQuantity: int.parse(_quantity.text),
            minOrderQuantity: int.parse(_minOrder.text),
            warrantyDays: _warrantyDays,
            condition: _condition,
            supportsPickup: _pickup,
            supportsDelivery: _delivery,
            imageUrl: _imageUrl.text,
          );
      ref.invalidate(_editListingProvider(widget.listingId));
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('تم حفظ التعديلات')));
      context.go(RouteNames.merchantListingDetails(widget.listingId));
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تعذر حفظ التعديلات: $error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

final _editListingProvider =
    FutureProvider.family<MerchantListingModel, String>((ref, id) async {
  final items =
      await ref.read(merchantMarketRepositoryProvider).getMyListings();
  return items.firstWhere((item) => item.id == id);
});

class _ReadOnlySummary extends StatelessWidget {
  const _ReadOnlySummary({required this.item});
  final MerchantListingModel item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD8A8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('بيانات مرجعية لا تتغير من هذه الصفحة',
              style: TextStyle(
                  fontWeight: FontWeight.w900, color: Color(0xFF8A4B00))),
          const SizedBox(height: 8),
          Text('رقم القطعة: ${item.partNumber ?? '-'}'),
          Text('الفئة: ${item.categoryName ?? '-'}'),
          Text('الفرع: ${item.branchName ?? '-'}'),
        ],
      ),
    );
  }
}

class _ImagePreview extends StatefulWidget {
  const _ImagePreview({required this.controller});
  final TextEditingController controller;

  @override
  State<_ImagePreview> createState() => _ImagePreviewState();
}

class _ImagePreviewState extends State<_ImagePreview> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    super.dispose();
  }

  void _changed() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final url = widget.controller.text.trim();
    return Container(
      height: 154,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFE9EEF3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE5ED)),
      ),
      child: url.isEmpty
          ? const Center(
              child: Icon(Icons.add_photo_alternate_outlined,
                  size: 46, color: Color(0xFF8291A0)))
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image_outlined,
                      size: 44, color: Color(0xFF8291A0))),
            ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E6EC)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x10071D33), blurRadius: 14, offset: Offset(0, 5))
          ],
        ),
        child: AppTileMaterial(
          borderRadius: BorderRadius.circular(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            ...children,
          ]),
        ),
      );
}

class _Field extends StatelessWidget {
  const _Field(
      {required this.label,
      required this.controller,
      this.validator,
      this.keyboardType,
      this.inputFormatters,
      this.minLines,
      this.maxLines});
  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? minLines;
  final int? maxLines;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          minLines: minLines,
          maxLines: maxLines ?? 1,
          decoration: _input(label),
        ),
      );
}

InputDecoration _input(String label) => InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDDE5ED))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDDE5ED))),
    );

String? _required(String? value) =>
    (value ?? '').trim().isEmpty ? 'هذا الحقل مطلوب' : null;
String? _numberRequired(String? value) =>
    double.tryParse((value ?? '').trim()) == null ? 'أدخل رقماً صحيحاً' : null;
String? _intRequired(String? value) =>
    int.tryParse((value ?? '').trim()) == null ? 'أدخل رقماً صحيحاً' : null;
final _money = FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'));
