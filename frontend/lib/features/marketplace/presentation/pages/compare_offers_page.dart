import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/core/navigation/app_navigation.dart';
import 'package:ghiyarak/core/theme/app_colors.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/core/theme/app_text_styles.dart';
import 'package:ghiyarak/features/cart/data/cart_repository.dart';
import 'package:ghiyarak/features/marketplace/data/marketplace_repository.dart';
import 'package:ghiyarak/features/marketplace/data/models/listing_summary.dart';
import 'package:ghiyarak/features/marketplace/presentation/widgets/marketplace_image.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:go_router/go_router.dart';

class CompareOffersPage extends ConsumerWidget {
  final String query;
  final String? selectedListingId;

  const CompareOffersPage({
    super.key,
    required this.query,
    this.selectedListingId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args =
        CompareOffersArgs(query: query, selectedListingId: selectedListingId);
    final offers = ref.watch(_compareOffersProvider(args));
    return AppScaffold(
      title: 'ظ…ظ‚ط§ط±ظ†ط© ط§ظ„ط¹ط±ظˆط¶',
      child: offers.when(
        data: (items) => _CompareContent(
          query: query,
          items: items,
          selectedListingId: selectedListingId,
        ),
        loading: () => const _CompareSkeleton(),
        error: (e, _) => _StateCard(
          icon: Icons.info_outline,
          title: 'طھط¹ط°ط± طھط­ظ…ظٹظ„ ط§ظ„ط¹ط±ظˆط¶',
          message: e.toString(),
          action: OutlinedButton.icon(
            onPressed: () => ref.invalidate(_compareOffersProvider(args)),
            icon: const Icon(Icons.refresh),
            label: const Text('ط¥ط¹ط§ط¯ط© ط§ظ„ظ…ط­ط§ظˆظ„ط©'),
          ),
        ),
      ),
    );
  }
}

class CompareOffersArgs {
  final String query;
  final String? selectedListingId;
  const CompareOffersArgs({required this.query, this.selectedListingId});

  @override
  bool operator ==(Object other) =>
      other is CompareOffersArgs &&
      other.query == query &&
      other.selectedListingId == selectedListingId;

  @override
  int get hashCode => Object.hash(query, selectedListingId);
}

final _compareOffersProvider =
    FutureProvider.family<List<ListingSummary>, CompareOffersArgs>(
        (ref, args) async {
  final items = await ref.read(marketplaceRepositoryProvider).compareOffers(
        q: args.query,
        listingId: args.selectedListingId,
        limit: 16,
      );
  final ranked = [...items];
  ranked.sort((a, b) {
    if (a.id == args.selectedListingId) return -1;
    if (b.id == args.selectedListingId) return 1;
    final scoreCompare =
        _offerScore(b, ranked).compareTo(_offerScore(a, ranked));
    if (scoreCompare != 0) return scoreCompare;
    return a.price.compareTo(b.price);
  });
  return ranked;
});

class _CompareContent extends StatelessWidget {
  final String query;
  final List<ListingSummary> items;
  final String? selectedListingId;

  const _CompareContent({
    required this.query,
    required this.items,
    this.selectedListingId,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _StateCard(
        icon: Icons.compare_arrows_outlined,
        title: 'ظ„ط§ طھظˆط¬ط¯ ط¹ط±ظˆط¶ ظ…ط´ط§ط¨ظ‡ط©',
        message:
            'ظ„ظ… ظ†ط¬ط¯ ط¹ط±ظˆط¶ظ‹ط§ ط£ط®ط±ظ‰ ظ„ظ„ظ…ظ‚ط§ط±ظ†ط©. ط¬ط±ظ‘ط¨ ط§ظ„ط¨ط­ط« ط¨ط§ط³ظ… ط£ط¨ط³ط· ظ„ظ„ظ‚ط·ط¹ط© ط£ظˆ ط±ظ‚ظ…ظ‡ط§.',
        action: OutlinedButton.icon(
          onPressed: () => context.go(RouteNames.marketplaceSearch),
          icon: const Icon(Icons.search_outlined),
          label: const Text('ظپطھط­ ط§ظ„ط¨ط­ط«'),
        ),
      );
    }

    final cheapest = items.reduce((a, b) => a.price <= b.price ? a : b);
    final bestWarranty = items.reduce(
        (a, b) => (a.warrantyDays ?? 0) >= (b.warrantyDays ?? 0) ? a : b);
    final bestStock = items
        .reduce((a, b) => a.availableQuantity >= b.availableQuantity ? a : b);
    final recommendedItem = _recommendedOffer(items);

    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        children: [
          _CompareHeader(
            query: query,
            count: items.length,
            cheapest: cheapest,
            bestWarranty: bestWarranty,
            recommended: recommendedItem,
          ),
          if (recommendedItem != null) ...[
            const SizedBox(height: AppSpacing.lg),
            _BestChoicePanel(
              item: recommendedItem,
              cheapest: recommendedItem.id == cheapest.id,
              bestWarranty: recommendedItem.id == bestWarranty.id,
              bestStock: recommendedItem.id == bestStock.id,
              score: _offerScore(recommendedItem, items),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          _ComparisonMatrix(
            items: items.take(4).toList(),
            cheapestId: cheapest.id,
            bestWarrantyId: bestWarranty.id,
            bestStockId: bestStock.id,
          ),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text('ظƒظ„ ط§ظ„ط¹ط±ظˆط¶', style: AppTextStyles.title),
          ),
          const SizedBox(height: AppSpacing.md),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
              child: _OfferComparisonCard(
                item: item,
                selected: item.id == selectedListingId,
                cheapest: item.id == cheapest.id,
                bestWarranty: item.id == bestWarranty.id,
                bestStock: item.id == bestStock.id,
                score: _offerScore(item, items),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompareHeader extends StatelessWidget {
  final String query;
  final int count;
  final ListingSummary cheapest;
  final ListingSummary bestWarranty;
  final ListingSummary? recommended;

  const _CompareHeader({
    required this.query,
    required this.count,
    required this.cheapest,
    required this.bestWarranty,
    this.recommended,
  });

  @override
  Widget build(BuildContext context) {
    final pills = <Widget>[
      if (recommended != null)
        _HeaderPill(
          icon: Icons.recommend_outlined,
          label: "المقترح: ${recommended!.providerName}",
        ),
      _HeaderPill(
        icon: Icons.sell_outlined,
        label: "الأرخص: ${_money(cheapest)}",
      ),
      _HeaderPill(
        icon: Icons.verified_user_outlined,
        label: "الضمان: ${bestWarranty.warrantyLabel}",
      ),
    ];
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadow, blurRadius: 18, offset: Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.compare_arrows_outlined,
                  color: Colors.white, size: 30),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  query.trim().isEmpty
                      ? 'ظ…ظ‚ط§ط±ظ†ط© ط§ظ„ط¹ط±ظˆط¶'
                      : query.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.heading2.copyWith(color: Colors.white),
                ),
              ),
              IconButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: 'ظ…ظ‚ط§ط±ظ†ط© $query'));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('طھظ… ظ†ط³ط® ظ…ظ„ط®طµ ط§ظ„ظ…ظ‚ط§ط±ظ†ط©')));
                },
                icon: const Icon(Icons.share_outlined, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '$count ط¹ط±ط¶ ظ…طھط§ط­ â€¢ ط§ظ„ط£ط±ط®طµ ${_money(cheapest)} â€¢ ط£ط·ظˆظ„ ط¶ظ…ط§ظ† ${bestWarranty.warrantyLabel}',
            style: AppTextStyles.body
                .copyWith(color: AppColors.textOnDark.withValues(alpha: 0.82)),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: pills,
          ),
        ],
      ),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _HeaderPill({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 6),
        Text(label,
            style: AppTextStyles.body.copyWith(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800)),
      ]),
    );
  }
}

class _BestChoicePanel extends StatelessWidget {
  final ListingSummary item;
  final bool cheapest;
  final bool bestWarranty;
  final bool bestStock;
  final int score;
  const _BestChoicePanel({
    required this.item,
    required this.cheapest,
    required this.bestWarranty,
    required this.bestStock,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.28)),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadow, blurRadius: 16, offset: Offset(0, 8))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.auto_awesome_outlined,
                color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
              child: Text('ط£ظپط¶ظ„ ط§ط®طھظٹط§ط± ظ…ظ‚طھط±ط­',
                  style: AppTextStyles.title)),
          Text('$score%',
              style: AppTextStyles.heading2.copyWith(color: AppColors.success)),
        ]),
        const SizedBox(height: AppSpacing.sm),
        Text(item.title,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: AppSpacing.xs),
        Text(
            '${item.providerName} â€¢ ${item.conditionLabel} â€¢ ${item.serviceLabel}',
            style: AppTextStyles.bodySecondary),
        const SizedBox(height: AppSpacing.md),
        Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: [
          if (cheapest)
            const _Badge(icon: Icons.sell_outlined, label: 'ط£ظپط¶ظ„ ط³ط¹ط±'),
          if (bestWarranty)
            const _Badge(
                icon: Icons.verified_user_outlined, label: 'ط£ظپط¶ظ„ ط¶ظ…ط§ظ†'),
          if (bestStock)
            const _Badge(
                icon: Icons.inventory_2_outlined, label: 'ط£ط¹ظ„ظ‰ طھظˆظپط±'),
          if (item.supportsDelivery)
            const _Badge(
                icon: Icons.local_shipping_outlined,
                label: 'ظٹط¯ط¹ظ… ط§ظ„طھظˆطµظٹظ„'),
          if (item.supportsInstallation)
            const _Badge(
                icon: Icons.build_circle_outlined,
                label: 'ظٹط¯ط¹ظ… ط§ظ„طھط±ظƒظٹط¨'),
        ]),
        const SizedBox(height: AppSpacing.md),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () =>
                  context.pushPath('${RouteNames.listingDetail}/${item.id}'),
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('ط¹ط±ط¶ ط§ظ„طھظپط§طµظٹظ„'),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: _AddToCartButton(item: item, filled: true)),
        ]),
      ]),
    );
  }
}

class _ComparisonMatrix extends StatelessWidget {
  final List<ListingSummary> items;
  final String cheapestId;
  final String bestWarrantyId;
  final String bestStockId;
  const _ComparisonMatrix({
    required this.items,
    required this.cheapestId,
    required this.bestWarrantyId,
    required this.bestStockId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('ظ…ظ‚ط§ط±ظ†ط© ط³ط±ظٹط¹ط©', style: AppTextStyles.title),
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 42,
            dataRowMinHeight: 46,
            dataRowMaxHeight: 58,
            columns: const [
              DataColumn(label: Text('ط§ظ„ط¹ط±ط¶')),
              DataColumn(label: Text('ط§ظ„ط³ط¹ط±')),
              DataColumn(label: Text('ط§ظ„ط¶ظ…ط§ظ†')),
              DataColumn(label: Text('ط§ظ„ط®ط¯ظ…ط©')),
              DataColumn(label: Text('ط§ظ„ظ…ط®ط²ظˆظ†')),
            ],
            rows: items.map((item) {
              return DataRow(cells: [
                DataCell(SizedBox(
                    width: 150,
                    child: Text(item.providerName,
                        maxLines: 1, overflow: TextOverflow.ellipsis))),
                DataCell(_CellValue(
                    text: _money(item), highlight: item.id == cheapestId)),
                DataCell(_CellValue(
                    text: item.warrantyLabel,
                    highlight: item.id == bestWarrantyId)),
                DataCell(Text(item.serviceLabel)),
                DataCell(_CellValue(
                    text: '${item.availableQuantity}',
                    highlight: item.id == bestStockId)),
              ]);
            }).toList(),
          ),
        ),
      ]),
    );
  }
}

class _CellValue extends StatelessWidget {
  final String text;
  final bool highlight;
  const _CellValue({required this.text, this.highlight = false});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: highlight
          ? BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(10))
          : null,
      child: Text(text,
          style: AppTextStyles.body.copyWith(
              fontWeight: highlight ? FontWeight.w800 : FontWeight.w500,
              color: highlight ? AppColors.primary : AppColors.textPrimary)),
    );
  }
}

class _OfferComparisonCard extends StatelessWidget {
  final ListingSummary item;
  final bool selected;
  final bool cheapest;
  final bool bestWarranty;
  final bool bestStock;
  final int score;

  const _OfferComparisonCard({
    required this.item,
    required this.selected,
    required this.cheapest,
    required this.bestWarranty,
    required this.bestStock,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: selected ? AppColors.accentSoft : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: selected ? AppColors.primary : AppColors.border),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadow, blurRadius: 10, offset: Offset(0, 5))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 82,
            height: 82,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(18)),
            child: MarketplaceImage(
                imageUrl: item.imageUrl,
                fit: BoxFit.contain,
                icon: Icons.car_repair_outlined,
                iconSize: 34),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                    child: Text(item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.title.copyWith(fontSize: 16))),
                if (selected)
                  const Icon(Icons.check_circle,
                      color: AppColors.success, size: 20),
              ]),
              const SizedBox(height: AppSpacing.xs),
              Text(
                  [
                    item.providerName,
                    item.providerTypeLabel,
                    if ((item.cityName ?? '').isNotEmpty) item.cityName
                  ].join(' â€¢ '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySecondary),
              const SizedBox(height: AppSpacing.xs),
              Text(_money(item),
                  style: AppTextStyles.heading2
                      .copyWith(color: AppColors.secondary)),
            ]),
          ),
        ]),
        const SizedBox(height: AppSpacing.md),
        _ScoreBar(score: score),
        const SizedBox(height: AppSpacing.md),
        Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: [
          if (cheapest)
            const _Badge(icon: Icons.sell_outlined, label: 'ط§ظ„ط£ط±ط®طµ'),
          if (bestWarranty)
            const _Badge(
                icon: Icons.verified_user_outlined, label: 'ط£ظپط¶ظ„ ط¶ظ…ط§ظ†'),
          if (bestStock)
            const _Badge(
                icon: Icons.inventory_2_outlined, label: 'ط£ط¹ظ„ظ‰ ظ…ط®ط²ظˆظ†'),
          _Badge(icon: Icons.category_outlined, label: item.conditionLabel),
          _Badge(icon: Icons.shield_outlined, label: item.warrantyLabel),
          _Badge(
              icon: Icons.miscellaneous_services_outlined,
              label: item.serviceLabel),
          if ((item.brandName ?? '').isNotEmpty)
            _Badge(icon: Icons.sell_outlined, label: item.brandName!),
          if ((item.oemNumber ?? '').isNotEmpty)
            _Badge(
                icon: Icons.numbers_outlined, label: 'OEM: ${item.oemNumber}'),
        ]),
        const SizedBox(height: AppSpacing.md),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () =>
                  context.pushPath('${RouteNames.listingDetail}/${item.id}'),
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('ط§ظ„طھظپط§طµظٹظ„'),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: _AddToCartButton(item: item)),
        ]),
      ]),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  final int score;
  const _ScoreBar({required this.score});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('ط¯ط±ط¬ط© ط§ظ„ط§ط®طھظٹط§ط±', style: AppTextStyles.bodySecondary),
        const Spacer(),
        Text('$score%',
            style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w800, color: AppColors.primary)),
      ]),
      const SizedBox(height: AppSpacing.xs),
      ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: LinearProgressIndicator(
          value: score / 100,
          minHeight: 8,
          backgroundColor: AppColors.surfaceAlt,
          color: score >= 75 ? AppColors.success : AppColors.primary,
        ),
      ),
    ]);
  }
}

class _AddToCartButton extends ConsumerStatefulWidget {
  final ListingSummary item;
  final bool filled;
  const _AddToCartButton({required this.item, this.filled = false});

  @override
  ConsumerState<_AddToCartButton> createState() => _AddToCartButtonState();
}

class _AddToCartButtonState extends ConsumerState<_AddToCartButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final canOrder = widget.item.inStock;
    final child = _loading
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2))
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
                Icon(Icons.add_shopping_cart_outlined, size: 18),
                SizedBox(width: 6),
                Text('ط£ط¶ظپ ظ„ظ„ط³ظ„ط©'),
              ]);
    final onPressed = !canOrder || _loading
        ? null
        : () async {
            setState(() => _loading = true);
            try {
              await ref.read(cartRepositoryProvider).addItem(
                  listingId: widget.item.id,
                  quantity: widget.item.minOrderQuantity);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        'طھظ…طھ ط¥ط¶ط§ظپط© ${widget.item.title} ظ„ظ„ط³ظ„ط©')));
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('طھط¹ط°ط± ط§ظ„ط¥ط¶ط§ظپط© ظ„ظ„ط³ظ„ط©: $e')));
              }
            } finally {
              if (mounted) setState(() => _loading = false);
            }
          };
    if (widget.filled) {
      return FilledButton(onPressed: onPressed, child: child);
    }
    return FilledButton.tonal(onPressed: onPressed, child: child);
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Badge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
          color: AppColors.accentSoft, borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 4),
        Text(label,
            style: AppTextStyles.body.copyWith(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w800)),
      ]),
    );
  }
}

class _StateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  const _StateCard(
      {required this.icon,
      required this.title,
      required this.message,
      this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.all(AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: AppColors.iconAccent, size: 48),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.xs),
          Text(message,
              textAlign: TextAlign.center, style: AppTextStyles.bodySecondary),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.lg),
            action!
          ],
        ]),
      ),
    );
  }
}

class _CompareSkeleton extends StatelessWidget {
  const _CompareSkeleton();
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: 5,
      itemBuilder: (_, index) => Container(
        height: index == 0 ? 150 : 180,
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border)),
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

String _money(ListingSummary item) =>
    '${item.price.toStringAsFixed(0)} ${item.currency}';

int _offerScore(ListingSummary item, List<ListingSummary> all) {
  if (all.isEmpty) return 0;
  final maxPrice = all.map((e) => e.price).reduce((a, b) => a > b ? a : b);
  final minPrice = all.map((e) => e.price).reduce((a, b) => a < b ? a : b);
  final priceRange = (maxPrice - minPrice).abs();
  final priceScore = priceRange == 0
      ? 25
      : ((maxPrice - item.price) / priceRange * 25).clamp(0, 25).round();
  final maxWarranty =
      all.map((e) => e.warrantyDays ?? 0).reduce((a, b) => a > b ? a : b);
  final warrantyScore = maxWarranty <= 0
      ? 0
      : (((item.warrantyDays ?? 0) / maxWarranty) * 20).clamp(0, 20).round();
  final serviceScore = (item.supportsDelivery ? 10 : 0) +
      (item.supportsInstallation ? 10 : 0) +
      (item.supportsPickup ? 5 : 0);
  final stockScore = item.availableQuantity > 10
      ? 15
      : item.availableQuantity > 0
          ? 8
          : 0;
  final trustScore = item.hasWarranty ? 10 : 0;
  final total =
      priceScore + warrantyScore + serviceScore + stockScore + trustScore;
  return total.clamp(0, 100).toInt();
}

ListingSummary? _recommendedOffer(List<ListingSummary> items) {
  if (items.isEmpty) return null;
  final ranked = [...items]..sort((a, b) {
      final scoreCompare =
          _offerScore(b, items).compareTo(_offerScore(a, items));
      if (scoreCompare != 0) return scoreCompare;
      final priceCompare = a.price.compareTo(b.price);
      if (priceCompare != 0) return priceCompare;
      return b.availableQuantity.compareTo(a.availableQuantity);
    });
  final best = ranked.first;
  if (ranked.length == 1) return best;
  final nextBest = ranked[1];
  return _offerScore(best, items) > _offerScore(nextBest, items) ? best : null;
}
