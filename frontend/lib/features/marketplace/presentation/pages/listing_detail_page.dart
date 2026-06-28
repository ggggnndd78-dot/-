import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/theme/app_colors.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/core/theme/app_text_styles.dart';
import 'package:ghiyarak/features/cart/data/cart_repository.dart';
import 'package:ghiyarak/features/marketplace/data/marketplace_repository.dart';
import 'package:ghiyarak/features/marketplace/data/models/listing_detail.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';

class ListingDetailPage extends ConsumerStatefulWidget {
  final String listingId;
  const ListingDetailPage({super.key, required this.listingId});

  @override
  ConsumerState<ListingDetailPage> createState() => _ListingDetailPageState();
}

class _ListingDetailPageState extends ConsumerState<ListingDetailPage> {
  bool _adding = false;

  Future<void> _addToCart() async {
    setState(() => _adding = true);
    try {
      await ref
          .read(cartRepositoryProvider)
          .addItem(listingId: widget.listingId, quantity: 1);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تمت الإضافة إلى السلة')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final future = ref.watch(_detailProvider(widget.listingId));
    return AppScaffold(
      title: 'تفاصيل العرض',
      child: future.when(
        data: (detail) => ListView(
          children: [
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 18,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: detail.imageUrls.isEmpty
                    ? const _ProductPlaceholder()
                    : PageView(
                        children: detail.imageUrls
                            .map(
                              (url) => Container(
                                color: AppColors.surfaceAlt,
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                child: Center(
                                  child: Text(
                                    url,
                                    style: AppTextStyles.bodySecondary,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(detail.summary.title, style: AppTextStyles.heading2),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    detail.description.isEmpty
                        ? 'لا يوجد وصف إضافي'
                        : detail.description,
                    style: AppTextStyles.bodySecondary,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: _InfoPill(
                          icon: Icons.storefront_outlined,
                          label: 'المزود',
                          value: detail.summary.providerName,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _InfoPill(
                          icon: Icons.inventory_2_outlined,
                          label: 'المخزون',
                          value: detail.availableStock.toString(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (detail.partNumbers.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('أرقام القطعة', style: AppTextStyles.title),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: detail.partNumbers
                          .map(
                            (number) => Chip(
                              label: Text(number),
                              avatar: const Icon(
                                Icons.tag,
                                size: 16,
                                color: AppColors.iconAccent,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: AppColors.headerGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'السعر',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textOnDark.withValues(alpha: 0.78),
                          ),
                        ),
                        Text(
                          '${detail.summary.price.toStringAsFixed(0)} ${detail.summary.currency}',
                          style: AppTextStyles.heading2.copyWith(
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 148,
                    child: AppButton(
                      text: 'إضافة للسلة',
                      isLoading: _adding,
                      onPressed: _addToCart,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _StateMessage(
          icon: Icons.info_outline,
          title: 'تعذر تحميل التفاصيل',
          message: e.toString(),
        ),
      ),
    );
  }
}

class _ProductPlaceholder extends StatelessWidget {
  const _ProductPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceAlt,
      child: const Center(
        child: Icon(
          Icons.car_repair_outlined,
          color: AppColors.iconAccent,
          size: 64,
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.iconAccent),
          const SizedBox(height: AppSpacing.sm),
          Text(label, style: AppTextStyles.bodySecondary),
          Text(
            value,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w800),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _StateMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.iconAccent, size: 42),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

final FutureProviderFamily<ListingDetail, String> _detailProvider =
    FutureProvider.family<ListingDetail, String>((ref, String id) =>
        ref.read(marketplaceRepositoryProvider).getListingDetail(id));
