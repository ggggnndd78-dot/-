import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/core/navigation/app_navigation.dart';
import 'package:ghiyarak/core/theme/app_colors.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/core/theme/app_text_styles.dart';
import 'package:ghiyarak/features/marketplace/data/marketplace_repository.dart';
import 'package:ghiyarak/features/marketplace/data/models/catalog_category.dart';
import 'package:ghiyarak/features/marketplace/data/models/listing_summary.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';

final _homeListingsProvider = FutureProvider.autoDispose<List<ListingSummary>>(
    (ref) => ref.watch(marketplaceRepositoryProvider).searchListings());

class MarketplaceHomePage extends ConsumerWidget {
  const MarketplaceHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(catalogCategoriesProvider);
    final listings = ref.watch(_homeListingsProvider);
    return AppScaffold(
      title: 'غيارك',
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(catalogCategoriesProvider);
          ref.invalidate(_homeListingsProvider);
        },
        child: ListView(children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
                gradient: AppColors.headerGradient,
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 18,
                      offset: Offset(0, 10))
                ]),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('منصة غيارك',
                  style: AppTextStyles.heading1
                      .copyWith(color: AppColors.textOnDark)),
              const SizedBox(height: AppSpacing.sm),
              Text('تصفح قطع الغيار والخدمات من بيانات الباك إند مباشرة.',
                  style: AppTextStyles.body.copyWith(
                      color: AppColors.textOnDark.withValues(alpha: 0.78))),
              const SizedBox(height: AppSpacing.md),
              TextField(
                readOnly: true,
                onTap: () => context.pushPath(RouteNames.marketplaceSearch),
                decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'ابحث عن قطعة أو رقم'),
              ),
            ]),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('التصنيفات', style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.md),
          categories.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _MessageCard(text: e.toString()),
            data: (items) => items.isEmpty
                ? const _MessageCard(text: 'لا توجد تصنيفات متاحة حاليًا')
                : _CategoriesRow(items: items),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('أحدث العروض', style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.md),
          listings.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _MessageCard(text: e.toString()),
            data: (items) => items.isEmpty
                ? const _MessageCard(text: 'لا توجد عروض منشورة حاليًا')
                : Column(
                    children: items
                        .take(10)
                        .map((item) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.md),
                            child: _ListingTile(item: item)))
                        .toList()),
          ),
        ]),
      ),
    );
  }
}

class _CategoriesRow extends StatelessWidget {
  final List<CatalogCategory> items;
  const _CategoriesRow({required this.items});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final item = items[index];
          return InkWell(
            onTap: () => context.pushPath(
                '${RouteNames.marketplaceSearch}?categoryId=${Uri.encodeComponent(item.id)}&categoryName=${Uri.encodeComponent(item.name)}'),
            child: Container(
              width: 142,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.category_outlined,
                        color: AppColors.iconAccent),
                    const Spacer(),
                    Text(item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.title),
                  ]),
            ),
          );
        },
      ),
    );
  }
}

class _ListingTile extends StatelessWidget {
  final ListingSummary item;
  const _ListingTile({required this.item});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.pushPath('${RouteNames.listingDetail}/${item.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: AppTextStyles.title),
                    const SizedBox(height: 4),
                    Text(
                      '${item.providerName}${(item.cityName ?? '').isEmpty ? '' : ' • ${item.cityName}'}',
                      style: AppTextStyles.bodySecondary,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                '${item.price.toStringAsFixed(0)} ${item.currency}',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final String text;
  const _MessageCard({required this.text});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border)),
      child: Text(text, style: AppTextStyles.bodySecondary));
}
