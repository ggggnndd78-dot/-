import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/core/navigation/app_navigation.dart';
import 'package:ghiyarak/core/theme/app_colors.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/core/theme/app_text_styles.dart';
import 'package:ghiyarak/features/cart/data/cart_repository.dart';
import 'package:ghiyarak/features/marketplace/data/marketplace_repository.dart';
import 'package:ghiyarak/features/marketplace/data/models/listing_summary.dart';
import 'package:ghiyarak/shared/navigation/navigation_context.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:go_router/go_router.dart';

final _customerListingsProvider = FutureProvider.autoDispose
    .family<List<ListingSummary>, String?>((ref, vehicleId) {
  return ref
      .watch(marketplaceRepositoryProvider)
      .searchListings(vehicleId: vehicleId);
});

class CustomerPartsPage extends ConsumerWidget {
  const CustomerPartsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicleId = currentQueryParametersOf(context)['vehicleId'];
    final listings = ref.watch(_customerListingsProvider(vehicleId));
    return AppScaffold(
      title: 'ظ‚ط·ط¹ ط§ظ„ط؛ظٹط§ط±',
      child: RefreshIndicator(
        onRefresh: () async =>
            ref.invalidate(_customerListingsProvider(vehicleId)),
        child: listings.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(children: [_EmptyCard(text: e.toString())]),
          data: (items) => ListView.separated(
            itemCount: items.isEmpty ? 2 : items.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _Header(vehicleId: vehicleId);
              }
              if (items.isEmpty) {
                return const _EmptyCard(
                    text:
                        'ظ„ط§ طھظˆط¬ط¯ ط¹ط±ظˆط¶ ظ…طھط§ط­ط© ط­ط§ظ„ظٹظ‹ط§ ظ…ظ† ط§ظ„ط¨ط§ظƒ ط¥ظ†ط¯.');
              }
              return _ListingCard(item: items[index - 1]);
            },
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String? vehicleId;
  const _Header({this.vehicleId});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
            vehicleId == null
                ? 'ظƒظ„ ط§ظ„ط¹ط±ظˆط¶ ط§ظ„ظ…طھط§ط­ط©'
                : 'ط¹ط±ظˆط¶ ظ…ظ†ط§ط³ط¨ط© ظ„ظ„ظ…ط±ظƒط¨ط© ط§ظ„ظ…ط­ط¯ط¯ط©',
            style: AppTextStyles.heading2),
        const SizedBox(height: AppSpacing.sm),
        Text(
            'ط§ظ„ظ†طھط§ط¦ط¬ ظٹطھظ… طھط­ظ…ظٹظ„ظ‡ط§ ظ…ط¨ط§ط´ط±ط© ظ…ظ† /listings ظپظٹ ط§ظ„ط¨ط§ظƒ ط¥ظ†ط¯.',
            style: AppTextStyles.bodySecondary),
        const SizedBox(height: AppSpacing.md),
        AppButton(
            text: 'ط¨ط­ط« ظ…طھظ‚ط¯ظ…',
            isOutlined: true,
            onPressed: () => context.go(RouteNames.marketplaceSearch)),
      ]),
    );
  }
}

class _ListingCard extends ConsumerWidget {
  final ListingSummary item;
  const _ListingCard({required this.item});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(item.title, style: AppTextStyles.title),
        const SizedBox(height: AppSpacing.xs),
        Text(item.providerName, style: AppTextStyles.bodySecondary),
        if ((item.cityName ?? '').isNotEmpty)
          Text(item.cityName!, style: AppTextStyles.bodySecondary),
        const SizedBox(height: AppSpacing.md),
        Text('${item.price.toStringAsFixed(0)} ${item.currency}',
            style: AppTextStyles.heading2.copyWith(color: AppColors.primary)),
        const SizedBox(height: AppSpacing.md),
        Row(children: [
          Expanded(
              child: AppButton(
                  text: 'ط§ظ„طھظپط§طµظٹظ„',
                  isOutlined: true,
                  onPressed: () => context
                      .pushPath('${RouteNames.listingDetail}/${item.id}'))),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
              child: AppButton(
                  text: 'ط¥ط¶ط§ظپط© ظ„ظ„ط³ظ„ط©',
                  onPressed: () async {
                    try {
                      await ref
                          .read(cartRepositoryProvider)
                          .addItem(listingId: item.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('طھظ…طھ ط§ظ„ط¥ط¶ط§ظپط© ظ„ظ„ط³ظ„ط©')));
                      }
                    } catch (error) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(error.toString())),
                        );
                      }
                    }
                  })),
        ]),
      ]),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String text;
  const _EmptyCard({required this.text});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border)),
      child: Text(text, style: AppTextStyles.bodySecondary));
}
