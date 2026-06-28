import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/core/navigation/app_navigation.dart';
import 'package:ghiyarak/core/theme/app_colors.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/core/theme/app_text_styles.dart';
import 'package:ghiyarak/features/marketplace/data/marketplace_repository.dart';
import 'package:ghiyarak/features/marketplace/data/models/listing_summary.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';

class MarketplaceSearchPage extends ConsumerStatefulWidget {
  final String? initialCategoryId;
  final String? initialCategoryName;

  const MarketplaceSearchPage({
    super.key,
    this.initialCategoryId,
    this.initialCategoryName,
  });

  @override
  ConsumerState<MarketplaceSearchPage> createState() =>
      _MarketplaceSearchPageState();
}

class _MarketplaceSearchPageState extends ConsumerState<MarketplaceSearchPage> {
  final _queryController = TextEditingController();
  List<ListingSummary> _results = const [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _search());
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() => _loading = true);
    try {
      final items =
          await ref.read(marketplaceRepositoryProvider).searchListings(
                q: _queryController.text.trim(),
                categoryId: widget.initialCategoryId,
              );
      if (!mounted) return;
      setState(() => _results = items);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: widget.initialCategoryName == null
          ? 'البحث'
          : 'بحث: ${widget.initialCategoryName}',
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _queryController,
                  cursorColor: AppColors.primary,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    labelText: 'ابحث عن قطعة أو رقم',
                  ),
                  onSubmitted: (_) => _search(),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  text: 'بحث',
                  isLoading: _loading,
                  onPressed: _search,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? const _SearchStateMessage(
                        icon: Icons.search_off,
                        title: 'لا توجد نتائج حاليًا',
                        message: 'جرّب كلمة مختلفة أو اختر تصنيفًا آخر.',
                      )
                    : ListView.separated(
                        itemBuilder: (context, index) {
                          final item = _results[index];
                          return _SearchResultCard(item: item);
                        },
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.md),
                        itemCount: _results.length,
                      ),
          ),
        ],
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final ListingSummary item;

  const _SearchResultCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.pushPath('${RouteNames.listingDetail}/${item.id}'),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.car_repair_outlined,
                color: AppColors.iconAccent,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: AppTextStyles.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${item.providerName} • ${item.cityName ?? '-'}',
                    style: AppTextStyles.bodySecondary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.supportsInstallation) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'مع تركيب',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.price.toStringAsFixed(0),
                  style: AppTextStyles.title.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
                Text(item.currency, style: AppTextStyles.bodySecondary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchStateMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _SearchStateMessage({
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
            Icon(icon, color: AppColors.iconAccent, size: 44),
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
