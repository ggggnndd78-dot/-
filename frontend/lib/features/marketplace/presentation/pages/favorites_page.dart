import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/core/navigation/app_navigation.dart';
import 'package:ghiyarak/core/theme/app_colors.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/core/theme/app_text_styles.dart';
import 'package:ghiyarak/features/marketplace/data/customer_favorites_repository.dart';
import 'package:ghiyarak/features/marketplace/data/models/customer_favorites_model.dart';
import 'package:ghiyarak/features/marketplace/data/models/listing_summary.dart';
import 'package:ghiyarak/features/marketplace/presentation/widgets/marketplace_image.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:go_router/go_router.dart';

class FavoritesPage extends ConsumerStatefulWidget {
  const FavoritesPage({super.key});

  @override
  ConsumerState<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends ConsumerState<FavoritesPage> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final favorites = ref.watch(_favoritesProvider);

    return AppScaffold(
      title: 'المفضلة والمتابعة',
      child: favorites.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _StatePanel(
          icon: Icons.error_outline,
          title: 'تعذر تحميل المفضلة',
          message: error.toString(),
          actionText: 'إعادة المحاولة',
          onAction: () => ref.invalidate(_favoritesProvider),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () => ref.refresh(_favoritesProvider.future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
            children: [
              _HeaderCard(data: data),
              const SizedBox(height: AppSpacing.md),
              _SegmentedTabs(
                index: _tabIndex,
                onChanged: (index) => setState(() => _tabIndex = index),
              ),
              const SizedBox(height: AppSpacing.md),
              if (_tabIndex == 0)
                _ListingsTab(data: data)
              else if (_tabIndex == 1)
                _ProvidersTab(data: data)
              else
                _AlertsTab(data: data),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final CustomerFavoritesData data;
  const _HeaderCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadow, blurRadius: 16, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.favorite,
                  color: AppColors.headerFooterAccent, size: 30),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'كل ما حفظته في مكان واحد',
                  style: AppTextStyles.heading2.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'تابع القطع والمتاجر، واحصل على تنبيهات عند انخفاض السعر أو عودة القطعة للمخزون.',
            style: AppTextStyles.body
                .copyWith(color: Colors.white.withValues(alpha: 0.82)),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                  child: _HeaderMetric(
                      label: 'قطع محفوظة',
                      value: data.stats.listingsCount.toString())),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                  child: _HeaderMetric(
                      label: 'مزودون',
                      value: data.stats.providersCount.toString())),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                  child: _HeaderMetric(
                      label: 'تنبيهات',
                      value: (data.stats.priceDropAlerts +
                              data.stats.backInStockAlerts)
                          .toString())),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  final String label;
  final String value;
  const _HeaderMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        children: [
          Text(value,
              style: AppTextStyles.heading2
                  .copyWith(color: AppColors.headerFooterAccent)),
          Text(label,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySecondary
                  .copyWith(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  const _SegmentedTabs({required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final tabs = const [
      (Icons.inventory_2_outlined, 'القطع'),
      (Icons.storefront_outlined, 'المتابعة'),
      (Icons.notifications_active_outlined, 'التنبيهات'),
    ];
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++)
            Expanded(
              child: InkWell(
                onTap: () => onChanged(i),
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: index == i ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(tabs[i].$1,
                          size: 18,
                          color: index == i
                              ? Colors.white
                              : AppColors.textSecondary),
                      const SizedBox(width: 5),
                      Text(tabs[i].$2,
                          style: AppTextStyles.body.copyWith(
                              color: index == i
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ListingsTab extends ConsumerWidget {
  final CustomerFavoritesData data;
  const _ListingsTab({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (data.listings.isEmpty) {
      return _StatePanel(
        icon: Icons.favorite_border,
        title: 'لا توجد قطع محفوظة',
        message:
            'افتح تفاصيل أي قطعة واضغط زر القلب لحفظها ومتابعة تغير السعر والتوفر.',
        actionText: 'تصفح القطع',
        onAction: () => context.go(RouteNames.marketplaceSearch),
      );
    }
    return Column(
      children: data.listings
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _FavoriteListingCard(
                item: item,
                onRemove: () async {
                  await ref
                      .read(customerFavoritesRepositoryProvider)
                      .removeListingFavorite(item.id);
                  ref.invalidate(_favoritesProvider);
                },
                onPreferences: () => _openPreferences(context, ref, item),
              ),
            ),
          )
          .toList(),
    );
  }

  Future<void> _openPreferences(
      BuildContext context, WidgetRef ref, ListingSummary item) async {
    final targetController = TextEditingController(
        text: (item.salePrice ?? item.price).toStringAsFixed(0));
    bool notifyPrice = true;
    bool notifyStock = true;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('تنبيهات القطعة', style: AppTextStyles.title),
              const SizedBox(height: AppSpacing.md),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: notifyPrice,
                onChanged: (value) => setState(() => notifyPrice = value),
                title: const Text('تنبيه عند انخفاض السعر'),
              ),
              TextField(
                controller: targetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'السعر المستهدف'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: notifyStock,
                onChanged: (value) => setState(() => notifyStock = value),
                title: const Text('تنبيه عند عودة القطعة للمخزون'),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                  text: 'حفظ التنبيهات',
                  onPressed: () => Navigator.pop(context, true)),
            ],
          ),
        ),
      ),
    );
    if (saved == true) {
      await ref
          .read(customerFavoritesRepositoryProvider)
          .updateListingFavoritePreferences(
            listingId: item.id,
            notifyPriceDrop: notifyPrice,
            notifyBackInStock: notifyStock,
            targetPrice: double.tryParse(targetController.text),
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حفظ تنبيهات المفضلة')));
      }
    }
  }
}

class _FavoriteListingCard extends StatelessWidget {
  final ListingSummary item;
  final VoidCallback onRemove;
  final VoidCallback onPreferences;

  const _FavoriteListingCard({
    required this.item,
    required this.onRemove,
    required this.onPreferences,
  });

  @override
  Widget build(BuildContext context) {
    final displayPrice = item.salePrice ?? item.price;
    return InkWell(
      onTap: () => context.pushPath('${RouteNames.listingDetail}/${item.id}'),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: _cardDecoration(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 82,
              height: 82,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(16)),
              child: MarketplaceImage(
                  imageUrl: item.imageUrl,
                  fit: BoxFit.contain,
                  icon: Icons.inventory_2_outlined),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.title.copyWith(fontSize: 16)),
                  const SizedBox(height: AppSpacing.xs),
                  Text('${item.providerName} • ${item.cityName ?? 'غير محدد'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySecondary),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _MiniChip(
                          label: item.serviceLabel,
                          icon: Icons.local_shipping_outlined),
                      _MiniChip(
                          label: item.warrantyLabel,
                          icon: Icons.verified_outlined),
                      _MiniChip(
                          label: item.inStock
                              ? 'متوفر: ${item.availableQuantity}'
                              : 'نافد',
                          icon: item.inStock
                              ? Icons.check_circle_outline
                              : Icons.warning_amber_outlined),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text('${displayPrice.toStringAsFixed(0)} ${item.currency}',
                      style: AppTextStyles.title
                          .copyWith(color: AppColors.secondary, fontSize: 15)),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                    onPressed: onRemove,
                    icon: const Icon(Icons.favorite, color: AppColors.error),
                    tooltip: 'إزالة'),
                IconButton(
                    onPressed: onPreferences,
                    icon: const Icon(Icons.notifications_active_outlined),
                    tooltip: 'التنبيهات'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProvidersTab extends ConsumerWidget {
  final CustomerFavoritesData data;
  const _ProvidersTab({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (data.providers.isEmpty) {
      return _StatePanel(
        icon: Icons.storefront_outlined,
        title: 'لا توجد متاجر أو ورش متابَعة',
        message: 'افتح ملف أي مزود واضغط متابعة ليظهر هنا مع عروضه وتنبيهاته.',
        actionText: 'تصفح السوق',
        onAction: () => context.go(RouteNames.marketplaceSearch),
      );
    }
    return Column(
      children: data.providers
          .map(
            (provider) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _ProviderCard(
                provider: provider,
                onUnfollow: () async {
                  await ref
                      .read(customerFavoritesRepositoryProvider)
                      .toggleProviderFollow(
                        providerId: provider.id,
                        providerName: provider.name,
                        providerType: provider.type,
                      );
                  ref.invalidate(_favoritesProvider);
                },
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  final FollowedProviderSummary provider;
  final VoidCallback onUnfollow;
  const _ProviderCard({required this.provider, required this.onUnfollow});

  @override
  Widget build(BuildContext context) {
    final route =
        '${RouteNames.marketplaceProviderProfile}/${provider.id}?providerName=${Uri.encodeComponent(provider.name)}&providerTypeLabel=${Uri.encodeComponent(provider.typeLabel)}&serviceLabel=${Uri.encodeComponent(provider.serviceLabel)}';
    return InkWell(
      onTap: () => context.pushPath(route),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(18)),
              child: Icon(
                  provider.type == 'WORKSHOP'
                      ? Icons.car_repair_outlined
                      : Icons.storefront_outlined,
                  color: AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: Text(provider.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.title)),
                      if (provider.isVerified)
                        const Icon(Icons.verified,
                            color: AppColors.success, size: 18),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                      '${provider.typeLabel} • ${provider.cityName ?? 'غير محدد'} • ${provider.serviceLabel}',
                      style: AppTextStyles.bodySecondary),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                      '${provider.activeListings} عرض متاح • ${provider.followersCount} متابع',
                      style:
                          AppTextStyles.bodySecondary.copyWith(fontSize: 12)),
                ],
              ),
            ),
            IconButton(
                onPressed: onUnfollow,
                icon: const Icon(Icons.person_remove_alt_1_outlined),
                tooltip: 'إلغاء المتابعة'),
          ],
        ),
      ),
    );
  }
}

class _AlertsTab extends StatelessWidget {
  final CustomerFavoritesData data;
  const _AlertsTab({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.alerts.isEmpty) {
      return _StatePanel(
        icon: Icons.notifications_none_outlined,
        title: 'لا توجد تنبيهات الآن',
        message:
            'عند انخفاض سعر قطعة محفوظة أو عودة قطعة للمخزون ستظهر التنبيهات هنا.',
        actionText: 'إدارة المفضلة',
        onAction: () {},
      );
    }
    return Column(
      children: data.alerts
          .map(
            (alert) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _AlertCard(alert: alert),
            ),
          )
          .toList(),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final FavoriteAlertItem alert;
  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if ((alert.listingId ?? '').isNotEmpty) {
          context.pushPath('${RouteNames.listingDetail}/${alert.listingId}');
        }
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: _cardDecoration(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
                alert.type.contains('PRICE')
                    ? Icons.trending_down_outlined
                    : Icons.inventory_outlined,
                color: AppColors.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(alert.title, style: AppTextStyles.title),
                  const SizedBox(height: AppSpacing.xs),
                  Text(alert.message, style: AppTextStyles.bodySecondary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _MiniChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
          color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(label,
              style: AppTextStyles.bodySecondary.copyWith(fontSize: 12)),
        ],
      ),
    );
  }
}

class _StatePanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionText;
  final VoidCallback onAction;

  const _StatePanel({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionText,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.iconAccent, size: 46),
            const SizedBox(height: AppSpacing.md),
            Text(title,
                style: AppTextStyles.title, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text(message,
                style: AppTextStyles.bodySecondary,
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            AppButton(text: actionText, onPressed: onAction),
          ],
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration() => BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.border),
      boxShadow: const [
        BoxShadow(color: AppColors.shadow, blurRadius: 12, offset: Offset(0, 7))
      ],
    );

final _favoritesProvider = FutureProvider<CustomerFavoritesData>((ref) {
  return ref.read(customerFavoritesRepositoryProvider).getFavorites();
});
