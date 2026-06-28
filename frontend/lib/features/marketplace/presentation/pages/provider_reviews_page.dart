import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/config/api_endpoints.dart';
import 'package:ghiyarak/core/network/api_client.dart';
import 'package:ghiyarak/core/theme/app_colors.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/core/theme/app_text_styles.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';

final _providerReviewsProvider =
    FutureProvider.family<_ProviderReviewsBundle, _ProviderReviewsArgs>(
        (ref, args) async {
  final api = ref.watch(apiClientProvider);
  final response =
      await api.get(ApiEndpoints.reviews(args.type, args.targetId));
  final data = response.data['data'];
  final items = (data is List ? data : const <dynamic>[])
      .whereType<Map>()
      .map((e) => _Review.fromMap(Map<String, dynamic>.from(e)))
      .toList();
  return _ProviderReviewsBundle(items: items);
});

class ProviderReviewsPage extends ConsumerStatefulWidget {
  final String providerId;
  final String providerName;
  const ProviderReviewsPage(
      {super.key, required this.providerId, required this.providerName});

  @override
  ConsumerState<ProviderReviewsPage> createState() =>
      _ProviderReviewsPageState();
}

class _ProviderReviewsPageState extends ConsumerState<ProviderReviewsPage> {
  String _type = 'merchant';
  int _stars = 0;

  @override
  Widget build(BuildContext context) {
    final args = _ProviderReviewsArgs(type: _type, targetId: widget.providerId);
    final state = ref.watch(_providerReviewsProvider(args));
    return AppScaffold(
      title: 'تقييمات المزود',
      child: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _StateCard(
            title: 'تعذر تحميل التقييمات',
            message: error.toString(),
            icon: Icons.error_outline),
        data: (bundle) {
          final visible = _stars == 0
              ? bundle.items
              : bundle.items.where((r) => r.rating == _stars).toList();
          return RefreshIndicator(
            onRefresh: () => ref.refresh(_providerReviewsProvider(args).future),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _ReviewsSummary(
                    providerName: widget.providerName, bundle: bundle),
                const SizedBox(height: AppSpacing.lg),
                _TypeFilters(
                    type: _type, onChanged: (v) => setState(() => _type = v)),
                const SizedBox(height: AppSpacing.sm),
                _StarFilters(
                    stars: _stars,
                    onChanged: (v) => setState(() => _stars = v)),
                const SizedBox(height: AppSpacing.lg),
                if (visible.isEmpty)
                  const _EmptyReviewsState()
                else
                  ...visible.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _ReviewCard(review: r))),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ReviewsSummary extends StatelessWidget {
  final String providerName;
  final _ProviderReviewsBundle bundle;
  const _ReviewsSummary({required this.providerName, required this.bundle});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: AppColors.headerGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
                color: AppColors.shadow, blurRadius: 18, offset: Offset(0, 10))
          ],
        ),
        child: Row(children: [
          const Icon(Icons.star_rounded, color: AppColors.secondary, size: 44),
          const SizedBox(width: AppSpacing.md),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(providerName.isEmpty ? 'مزود غير محدد' : providerName,
                    style:
                        AppTextStyles.heading2.copyWith(color: Colors.white)),
                const SizedBox(height: AppSpacing.xs),
                Text(
                    '${bundle.average.toStringAsFixed(1)} من 5 • ${bundle.items.length} تقييم',
                    style: AppTextStyles.body.copyWith(color: Colors.white70)),
              ])),
        ]),
      );
}

class _TypeFilters extends StatelessWidget {
  final String type;
  final ValueChanged<String> onChanged;
  const _TypeFilters({required this.type, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const items = {
      'merchant': 'المتجر',
      'workshop': 'الورشة',
      'product': 'المنتج'
    };
    return DropdownButtonFormField<String>(
      initialValue: items.containsKey(type) ? type : items.keys.first,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'نوع التقييم',
        prefixIcon: Icon(Icons.filter_list_rounded),
      ),
      items: items.entries
          .map((e) => DropdownMenuItem<String>(
                value: e.key,
                child: Text(e.value, overflow: TextOverflow.ellipsis),
              ))
          .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

class _StarFilters extends StatelessWidget {
  final int stars;
  final ValueChanged<int> onChanged;
  const _StarFilters({required this.stars, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    const values = [0, 5, 4, 3, 2, 1];
    return DropdownButtonFormField<int>(
      initialValue: values.contains(stars) ? stars : 0,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'تصفية النجوم',
        prefixIcon: Icon(Icons.star_border_rounded),
      ),
      items: values
          .map((v) => DropdownMenuItem<int>(
                value: v,
                child: Text(v == 0 ? 'الكل' : '$v نجوم'),
              ))
          .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final _Review review;
  const _ReviewCard({required this.review});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
                backgroundColor: AppColors.accentSoft,
                child: Text(
                    review.userName.isEmpty
                        ? 'ع'
                        : review.userName.substring(0, 1),
                    style: const TextStyle(color: AppColors.primary))),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
                child: Text(
                    review.userName.isEmpty ? 'عميل غيارك' : review.userName,
                    style: AppTextStyles.title.copyWith(fontSize: 15))),
            Row(
                children: List.generate(
                    5,
                    (i) => Icon(
                        i < review.rating
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: AppColors.gold,
                        size: 18))),
          ]),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(review.comment, style: AppTextStyles.body),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(review.createdAt, style: AppTextStyles.caption),
        ]),
      );
}

class _EmptyReviewsState extends StatelessWidget {
  const _EmptyReviewsState();
  @override
  Widget build(BuildContext context) => const _StateCard(
      icon: Icons.rate_review_outlined,
      title: 'لا توجد تقييمات مطابقة',
      message: 'ستظهر التقييمات بعد اكتمال طلبات حقيقية ونشرها.');
}

class _StateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  const _StateCard(
      {required this.icon, required this.title, required this.message});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border)),
        child: Column(children: [
          Icon(icon, color: AppColors.iconAccent, size: 52),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.xs),
          Text(message,
              textAlign: TextAlign.center, style: AppTextStyles.bodySecondary)
        ]),
      );
}

class _ProviderReviewsArgs {
  final String type;
  final String targetId;
  const _ProviderReviewsArgs({required this.type, required this.targetId});
  @override
  bool operator ==(Object other) =>
      other is _ProviderReviewsArgs &&
      other.type == type &&
      other.targetId == targetId;
  @override
  int get hashCode => Object.hash(type, targetId);
}

class _ProviderReviewsBundle {
  final List<_Review> items;
  const _ProviderReviewsBundle({required this.items});
  double get average => items.isEmpty
      ? 0
      : items.fold<double>(0, (sum, e) => sum + e.rating) / items.length;
}

class _Review {
  final String userName;
  final int rating;
  final String comment;
  final String createdAt;
  const _Review(
      {required this.userName,
      required this.rating,
      required this.comment,
      required this.createdAt});
  factory _Review.fromMap(Map<String, dynamic> map) => _Review(
        userName: (map['user_name'] ?? map['userName'] ?? '').toString(),
        rating: _int(map['rating'], fallback: 0),
        comment: (map['comment'] ?? '').toString(),
        createdAt: (map['created_at'] ?? map['createdAt'] ?? '').toString(),
      );
}

int _int(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
