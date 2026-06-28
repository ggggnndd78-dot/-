import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/core/navigation/app_navigation.dart';
import 'package:ghiyarak/core/theme/app_colors.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/core/theme/app_text_styles.dart';
import 'package:ghiyarak/features/marketplace/data/customer_favorites_repository.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';

final _providerFollowStatusProvider =
    FutureProvider.family<bool, String>((ref, providerId) {
  return ref
      .watch(customerFavoritesRepositoryProvider)
      .isProviderFollowed(providerId);
});

class MarketplaceProviderProfilePage extends StatelessWidget {
  final String providerId;
  final String providerName;
  final String providerTypeLabel;
  final String serviceLabel;
  final String? cityName;
  final String? listingTitle;
  final String? listingId;

  const MarketplaceProviderProfilePage({
    super.key,
    required this.providerId,
    required this.providerName,
    required this.providerTypeLabel,
    required this.serviceLabel,
    this.cityName,
    this.listingTitle,
    this.listingId,
  });

  @override
  Widget build(BuildContext context) {
    final isWorkshop = providerTypeLabel.contains('ورشة');
    return AppScaffold(
      title: providerName.isEmpty ? 'ملف المزود' : providerName,
      child: ListView(
        children: [
          _ProviderHero(
            providerName: providerName,
            providerTypeLabel: providerTypeLabel,
            serviceLabel: serviceLabel,
            cityName: cityName,
          ),
          const SizedBox(height: AppSpacing.lg),
          _TrustSection(isWorkshop: isWorkshop),
          const SizedBox(height: AppSpacing.lg),
          _ProviderActions(
            providerId: providerId,
            providerName: providerName,
            providerTypeLabel: providerTypeLabel,
            listingTitle: listingTitle,
            listingId: listingId,
            isWorkshop: isWorkshop,
          ),
          const SizedBox(height: AppSpacing.lg),
          _InfoCard(
            title: 'القطع والخدمات',
            icon: Icons.inventory_2_outlined,
            lines: [
              if ((listingTitle ?? '').isNotEmpty) 'دخلت من عرض: $listingTitle',
              serviceLabel,
              'سيتم عرض قطع هذا المزود عند توفر واجهة المزود في الباك اند.',
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _InfoCard(
            title: 'سياسة الثقة',
            icon: Icons.verified_user_outlined,
            lines: const [
              'التواصل يتم من داخل التطبيق لحفظ سجل الطلب.',
              'لا يظهر زر الحجز إلا للورش أو العروض التي تدعم التركيب.',
              'التقييمات تعتمد على طلبات مكتملة فقط.',
            ],
          ),
        ],
      ),
    );
  }
}

class _ProviderHero extends StatelessWidget {
  final String providerName;
  final String providerTypeLabel;
  final String serviceLabel;
  final String? cityName;

  const _ProviderHero({
    required this.providerName,
    required this.providerTypeLabel,
    required this.serviceLabel,
    this.cityName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24),
            ),
            child: Icon(
              providerTypeLabel.contains('ورشة')
                  ? Icons.car_repair_outlined
                  : Icons.storefront_outlined,
              color: AppColors.headerFooterAccent,
              size: 32,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  providerName.isEmpty ? 'مزود غير محدد' : providerName,
                  style: AppTextStyles.heading2.copyWith(color: Colors.white),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  [
                    providerTypeLabel,
                    if ((cityName ?? '').isNotEmpty) cityName,
                  ].join(' • '),
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textOnDark.withValues(alpha: 0.78),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _HeroBadge(label: serviceLabel),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  final String label;

  const _HeroBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.headerFooterAccent,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _TrustSection extends StatelessWidget {
  final bool isWorkshop;

  const _TrustSection({required this.isWorkshop});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricTile(
            icon: Icons.star_rounded,
            label: 'التقييم',
            value: 'جديد',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _MetricTile(
            icon: isWorkshop
                ? Icons.build_circle_outlined
                : Icons.local_shipping_outlined,
            label: isWorkshop ? 'التركيب' : 'التوصيل',
            value: isWorkshop ? 'متاح' : 'حسب العرض',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        const Expanded(
          child: _MetricTile(
            icon: Icons.schedule_outlined,
            label: 'الحالة',
            value: 'يتطلب تأكيد',
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 104),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary.copyWith(fontSize: 11),
          ),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _ProviderActions extends ConsumerWidget {
  final String providerId;
  final String providerName;
  final String providerTypeLabel;
  final String? listingTitle;
  final String? listingId;
  final bool isWorkshop;

  const _ProviderActions({
    required this.providerId,
    required this.providerName,
    required this.providerTypeLabel,
    this.listingTitle,
    this.listingId,
    required this.isWorkshop,
  });

  Future<void> _toggleFollow(BuildContext context, WidgetRef ref) async {
    try {
      final followed = await ref
          .read(customerFavoritesRepositoryProvider)
          .toggleProviderFollow(
            providerId: providerId,
            providerName: providerName,
            providerType: isWorkshop ? 'WORKSHOP' : 'MERCHANT',
          );
      ref.invalidate(_providerFollowStatusProvider(providerId));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                followed ? 'تمت متابعة المزود' : 'تم إلغاء متابعة المزود')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followStatus = ref.watch(_providerFollowStatusProvider(providerId));
    final chatQuery = Uri(
      queryParameters: {
        'listingId': listingId ?? '',
        'listingTitle': listingTitle ?? 'استفسار عن مزود',
        'providerName': providerName,
        'providerTypeLabel': providerTypeLabel,
        'serviceLabel': isWorkshop ? 'تركيب وفحص' : 'بيع وتوصيل',
      },
    ).query;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        FilledButton.icon(
          onPressed: () =>
              context.pushPath('${RouteNames.customerChat}?$chatQuery'),
          icon: const Icon(Icons.chat_outlined),
          label: const Text('تواصل'),
        ),
        followStatus.when(
          loading: () => OutlinedButton.icon(
            onPressed: null,
            icon: const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2)),
            label: Text('متابعة'),
          ),
          error: (_, __) => OutlinedButton.icon(
            onPressed: () async {
              await _toggleFollow(context, ref);
            },
            icon: const Icon(Icons.person_add_alt_1_outlined),
            label: const Text('متابعة'),
          ),
          data: (isFollowed) => OutlinedButton.icon(
            onPressed: () async {
              await _toggleFollow(context, ref);
            },
            icon: Icon(isFollowed
                ? Icons.person_remove_alt_1_outlined
                : Icons.person_add_alt_1_outlined),
            label: Text(isFollowed ? 'إلغاء المتابعة' : 'متابعة'),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => context.pushPath(
            '${RouteNames.providerReviews}/$providerId?providerName=${Uri.encodeComponent(providerName)}',
          ),
          icon: const Icon(Icons.rate_review_outlined),
          label: const Text('التقييمات'),
        ),
        if (isWorkshop)
          OutlinedButton.icon(
            onPressed: () => context.pushPath(RouteNames.customerMaintenance),
            icon: const Icon(Icons.event_available_outlined),
            label: const Text('حجز تركيب'),
          ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> lines;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.lines,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(title, style: AppTextStyles.title),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 18,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(line, style: AppTextStyles.body)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
