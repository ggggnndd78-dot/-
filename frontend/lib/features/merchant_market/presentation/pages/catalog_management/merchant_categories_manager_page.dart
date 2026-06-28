import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/features/marketplace/data/models/catalog_category.dart';
import 'package:ghiyarak/features/merchant_market/data/merchant_market_repository.dart';
import 'package:ghiyarak/features/merchant_market/data/models/merchant_listing_model.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_management_scaffold.dart';

class MerchantCategoriesManagerPage extends ConsumerStatefulWidget {
  const MerchantCategoriesManagerPage({super.key});

  @override
  ConsumerState<MerchantCategoriesManagerPage> createState() =>
      _MerchantCategoriesManagerPageState();
}

class _MerchantCategoriesManagerPageState
    extends ConsumerState<MerchantCategoriesManagerPage> {
  late Future<_CategoriesState> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_CategoriesState> _load() async {
    final repo = ref.read(merchantMarketRepositoryProvider);
    final results = await Future.wait<dynamic>([
      repo.getCategories(),
      repo.getMyListings(),
    ]);
    return _CategoriesState(
      categories: results[0] as List<CatalogCategory>,
      listings: results[1] as List<MerchantListingModel>,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_CategoriesState>(
      future: _future,
      builder: (context, snapshot) {
        return MerchantManagementScaffold(
          title: 'الأصناف والأقسام',
          subtitle: 'تنظيم منتجات المتجر حسب كتالوج غيارك الفعلي',
          onRefresh: () async => setState(() => _future = _load()),
          children: [
            if (snapshot.connectionState != ConnectionState.done)
              const Center(child: CircularProgressIndicator())
            else if (snapshot.hasError)
              MerchantStateCard(
                icon: Icons.error_outline,
                title: 'تعذر تحميل الأصناف',
                message: snapshot.error.toString(),
                actionLabel: 'إعادة المحاولة',
                onAction: () => setState(() => _future = _load()),
              )
            else
              _CategoriesContent(state: snapshot.requireData),
          ],
        );
      },
    );
  }
}

class _CategoriesContent extends StatelessWidget {
  const _CategoriesContent({required this.state});

  final _CategoriesState state;

  @override
  Widget build(BuildContext context) {
    final uncategorized =
        state.listings.where((item) => (item.categoryId ?? '').isEmpty).length;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: MerchantMetricTile(
                icon: Icons.category_outlined,
                label: 'أصناف الكتالوج',
                value: '${state.categories.length}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MerchantMetricTile(
                icon: Icons.inventory_2_outlined,
                label: 'منتجات المتجر',
                value: '${state.listings.length}',
              ),
            ),
          ],
        ),
        if (uncategorized > 0) ...[
          const SizedBox(height: 12),
          MerchantStateCard(
            icon: Icons.warning_amber_rounded,
            title: 'منتجات بدون صنف',
            message:
                'يوجد $uncategorized منتج لا يظهر له صنف من بيانات الخادم. راجع بيانات المنتج لتحسين البحث والتصفح.',
          ),
        ],
        const SizedBox(height: 14),
        if (state.categories.isEmpty)
          const MerchantStateCard(
            icon: Icons.category_outlined,
            title: 'لا توجد أصناف',
            message: 'لم يرجع الخادم أصناف الكتالوج حالياً.',
          )
        else
          ...state.categories.map((category) {
            final count = state.listings
                .where((item) => item.categoryId == category.id)
                .length;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MerchantPanel(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.folder_open_outlined,
                    color: Color(0xFFFF7900),
                  ),
                  title: Text(
                    category.name,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text('$count منتج منشور أو محفوظ ضمن هذا الصنف'),
                  trailing: Chip(label: Text('$count')),
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _CategoriesState {
  const _CategoriesState({required this.categories, required this.listings});

  final List<CatalogCategory> categories;
  final List<MerchantListingModel> listings;
}
