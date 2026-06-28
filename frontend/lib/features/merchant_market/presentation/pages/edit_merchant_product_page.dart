import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/core/network/api_exception.dart';
import 'package:ghiyarak/features/merchant_market/data/merchant_market_repository.dart';
import 'package:ghiyarak/features/merchant_market/data/models/merchant_listing_model.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_bottom_navigation.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_drawer.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_page_header.dart';
import 'package:go_router/go_router.dart';

class EditMerchantProductPage extends ConsumerStatefulWidget {
  const EditMerchantProductPage({
    required this.listingId,
    this.initialListing,
    super.key,
  });

  final String listingId;
  final MerchantListingModel? initialListing;

  @override
  ConsumerState<EditMerchantProductPage> createState() =>
      _EditMerchantProductPageState();
}

class _EditMerchantProductPageState
    extends ConsumerState<EditMerchantProductPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _sku = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _quantity = TextEditingController();

  String _condition = 'NEW';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final listing = widget.initialListing;
    if (listing != null) {
      _name.text = listing.title;
      _sku.text = listing.partNumber == '-'
          ? (listing.sku ?? '')
          : (listing.partNumber ?? '');
      _description.text = listing.description ?? '';
      _price.text = listing.price.toStringAsFixed(2);
      _quantity.text = listing.stock.toString();
      _condition = _normalizeCondition(listing.condition);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _sku.dispose();
    _description.dispose();
    _price.dispose();
    _quantity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notificationCount =
        ref.watch(_notificationCountProvider).asData?.value ?? 0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF5F7FA),
        drawer:
            const MerchantDrawer(currentTab: MerchantNavigationTab.products),
        bottomNavigationBar: const MerchantBottomNavigation(
          currentTab: MerchantNavigationTab.products,
          compact: true,
        ),
        body: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: MerchantPageHeader(
                    title: 'تعديل المنتج',
                    subtitle: 'عدّل بيانات المنتج واحفظ التغييرات',
                    onMenu: () => _scaffoldKey.currentState?.openDrawer(),
                    notificationCount: notificationCount,
                    onNotifications: () =>
                        context.go(RouteNames.merchantNotifications),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                  sliver: SliverList.list(
                    children: [
                      _EditCard(
                        title: 'بيانات المنتج',
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _name,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'اسم المنتج',
                                prefixIcon: Icon(Icons.inventory_2_outlined),
                              ),
                              validator: _required,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _sku,
                              readOnly: true,
                              decoration: const InputDecoration(
                                labelText: 'رقم القطعة / SKU',
                                prefixIcon: Icon(Icons.tag_rounded),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              initialValue: 'غير قابل للتعديل من هذه الشاشة',
                              readOnly: true,
                              decoration: const InputDecoration(
                                labelText: 'الفئة',
                                prefixIcon: Icon(Icons.category_outlined),
                              ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: _condition,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'حالة المنتج',
                                prefixIcon: Icon(Icons.verified_outlined),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'NEW',
                                  child: Text('NEW'),
                                ),
                                DropdownMenuItem(
                                  value: 'USED',
                                  child: Text('USED'),
                                ),
                                DropdownMenuItem(
                                  value: 'REFURBISHED',
                                  child: Text('REFURBISHED'),
                                ),
                              ],
                              onChanged: _saving
                                  ? null
                                  : (value) => setState(
                                        () => _condition = value ?? 'NEW',
                                      ),
                              validator: (value) => (value ?? '').isEmpty
                                  ? 'اختر حالة المنتج'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _description,
                              minLines: 3,
                              maxLines: 5,
                              decoration: const InputDecoration(
                                labelText: 'الوصف',
                                alignLabelWithHint: true,
                                prefixIcon: Icon(Icons.description_outlined),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _EditCard(
                        title: 'السعر والمخزون',
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _price,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'السعر بالريال اليمني',
                                  prefixIcon: Icon(Icons.payments_outlined),
                                ),
                                validator: _nonNegativePrice,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _quantity,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'الكمية المتوفرة',
                                  prefixIcon: Icon(Icons.inventory_outlined),
                                ),
                                validator: _nonNegativeQuantity,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _EditCard(
                        title: 'التوافق مع السيارات - اختياري',
                        child: const Text(
                          'التوافق اختياري. لا يتم تعديله من هذه الشاشة إلا إذا كان مدعوماً من الخادم.',
                          style: TextStyle(color: Color(0xFF6C7A89)),
                        ),
                      ),
                      SizedBox(
                        height: 48,
                        child: FilledButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: _saving
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: const Text('حفظ التغييرات'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    try {
      await ref.read(merchantMarketRepositoryProvider).updateMerchantListing(
            listingId: widget.listingId,
            title: _name.text.trim(),
            description: _description.text.trim(),
            condition: _condition,
            unitPrice: double.parse(_price.text.trim()),
            availableQuantity: int.parse(_quantity.text.trim()),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث المنتج بنجاح')),
      );
      context.go(RouteNames.merchantListings);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Update merchant product failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyError(error))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _normalizeCondition(String value) {
    final normalized = value.trim().toUpperCase();
    return switch (normalized) {
      'USED' => 'USED',
      'REFURBISHED' => 'REFURBISHED',
      _ => 'NEW',
    };
  }

  String? _required(String? value) {
    return (value ?? '').trim().isEmpty ? 'هذا الحقل مطلوب' : null;
  }

  String? _nonNegativePrice(String? value) {
    final parsed = double.tryParse((value ?? '').trim());
    if (parsed == null) return 'أدخل السعر';
    if (parsed < 0) return 'يجب أن يكون السعر 0 أو أكثر';
    return null;
  }

  String? _nonNegativeQuantity(String? value) {
    final parsed = int.tryParse((value ?? '').trim());
    if (parsed == null) return 'أدخل الكمية';
    if (parsed < 0) return 'يجب أن تكون الكمية 0 أو أكثر';
    return null;
  }

  String _friendlyError(Object error) {
    if (error is ApiException) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        return 'غير مصرح لك بتعديل هذا المنتج';
      }
      return error.message;
    }
    return 'تعذر تحديث المنتج';
  }
}

class _EditCard extends StatelessWidget {
  const _EditCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE4EBF1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

final _notificationCountProvider = FutureProvider<int>((ref) async {
  try {
    final result = await ref
        .read(merchantMarketRepositoryProvider)
        .getMerchantNotifications();
    return result.unreadCount;
  } catch (_) {
    return 0;
  }
});
