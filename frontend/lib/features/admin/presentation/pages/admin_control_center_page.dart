import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/i18n/app_localizations.dart';
import 'package:ghiyarak/core/i18n/locale_controller.dart';
import 'package:ghiyarak/core/theme/app_colors.dart';
import 'package:ghiyarak/core/theme/app_radius.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/features/admin/data/admin_repository.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_card.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:ghiyarak/shared/widgets/section_title.dart';
import 'package:go_router/go_router.dart';

final adminControlCenterProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
  final locale = ref.watch(localeControllerProvider).languageCode;
  return ref.watch(adminRepositoryProvider).controlCenter(locale: locale);
});

class AdminControlCenterPage extends ConsumerWidget {
  const AdminControlCenterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminControlCenterProvider);
    final locale = ref.watch(localeControllerProvider);

    return AppScaffold(
      title: context.tr('admin.title'),
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _AdminError(
          message: e.toString(),
          onRetry: () => ref.invalidate(adminControlCenterProvider),
        ),
        data: (data) {
          final modules =
              List<Map<String, dynamic>>.from(data['modules'] ?? const []);
          final kpis =
              List<Map<String, dynamic>>.from(data['kpis'] ?? const []);

          return LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final isMobile = width < 640;

              return ListView(
                padding: EdgeInsets.zero,
                children: [
                  _AdminControlHero(
                    isMobile: isMobile,
                    title: context.tr('admin.title'),
                    subtitle: context.tr('admin.control_center.subtitle'),
                    actionText: locale.languageCode == 'ar'
                        ? context.tr('admin.switch_to_english')
                        : context.tr('admin.switch_to_arabic'),
                    onToggleLocale: () async {
                      await ref.read(localeControllerProvider.notifier).toggle();
                      ref.invalidate(adminControlCenterProvider);
                    },
                  ),
                  SizedBox(height: isMobile ? AppSpacing.md : AppSpacing.xl),
                  _CompactSectionHeader(
                    title: context.tr('admin.kpis'),
                    subtitle: context.tr('admin.analytics'),
                    isMobile: isMobile,
                    trailing: IconButton.filledTonal(
                      tooltip: context.tr('common.refresh'),
                      onPressed: () => ref.invalidate(adminControlCenterProvider),
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ),
                  SizedBox(height: isMobile ? AppSpacing.sm : AppSpacing.md),
                  if (kpis.isEmpty)
                    _CompactEmptyCard(text: context.tr('common.empty'))
                  else
                    _ResponsiveAdminGrid(
                      minTileWidth: isMobile ? 150 : 200,
                      mobileMainAxisExtent: 118,
                      desktopMainAxisExtent: 136,
                      children: kpis.map((item) {
                        final label = locale.languageCode == 'en'
                            ? item['labelEn']
                            : item['labelAr'];
                        return _AdminKpiTile(
                          title: (label ?? item['code'] ?? '').toString(),
                          value: (item['value'] ?? 0).toString(),
                          icon: _iconFor((item['icon'] ?? 'analytics').toString()),
                        );
                      }).toList(),
                    ),
                  SizedBox(height: isMobile ? AppSpacing.lg : AppSpacing.xl),
                  _CompactSectionHeader(
                    title: context.tr('admin.modules'),
                    subtitle: context.tr('admin.control_center.subtitle'),
                    isMobile: isMobile,
                  ),
                  SizedBox(height: isMobile ? AppSpacing.sm : AppSpacing.md),
                  if (modules.isEmpty)
                    _CompactEmptyCard(text: context.tr('common.empty'))
                  else
                    _ResponsiveAdminGrid(
                      minTileWidth: isMobile ? 150 : 230,
                      mobileMainAxisExtent: 132,
                      desktopMainAxisExtent: 150,
                      children: modules.map((module) {
                        final route = (module['route'] ?? '').toString();
                        return _AdminModuleTile(
                          title: (module['title'] ?? module['code'] ?? '')
                              .toString(),
                          subtitle: (module['permission'] ?? '').toString(),
                          icon: _iconFor((module['icon'] ?? '').toString()),
                          onTap: route.isEmpty
                              ? null
                              : () {
                                  context.go(route);
                                },
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              );
            },
          );
        },
      ),
    );
  }

  static IconData _iconFor(String code) {
    switch (code) {
      case 'dashboard':
        return Icons.dashboard_outlined;
      case 'analytics':
        return Icons.analytics_outlined;
      case 'users':
        return Icons.people_alt_outlined;
      case 'verified':
        return Icons.verified_user_outlined;
      case 'map':
        return Icons.map_outlined;
      case 'orders':
        return Icons.receipt_long_outlined;
      case 'local_shipping':
        return Icons.local_shipping_outlined;
      case 'payments':
        return Icons.payments_outlined;
      case 'account_balance':
        return Icons.account_balance_outlined;
      case 'undo':
        return Icons.undo_outlined;
      case 'support_agent':
        return Icons.support_agent_outlined;
      case 'star_rate':
        return Icons.star_rate_outlined;
      case 'notifications':
        return Icons.notifications_active_outlined;
      case 'history':
        return Icons.history_outlined;
      case 'settings':
        return Icons.settings_outlined;
      default:
        return Icons.apps_outlined;
    }
  }
}

class _AdminControlHero extends StatelessWidget {
  const _AdminControlHero({
    required this.isMobile,
    required this.title,
    required this.subtitle,
    required this.actionText,
    required this.onToggleLocale,
  });

  final bool isMobile;
  final String title;
  final String subtitle;
  final String actionText;
  final VoidCallback onToggleLocale;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w900,
          color: AppColors.textPrimary,
          height: 1.12,
        );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppIconContainer(
              icon: Icons.admin_panel_settings_outlined,
              color: AppColors.primary,
              size: 44,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: titleStyle, maxLines: 2),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    maxLines: isMobile ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: isMobile ? AppSpacing.md : 0),
      ],
    );

    return AppCard(
      padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
      tone: AppCardTone.accent,
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                body,
                AppButton(
                  text: actionText,
                  isOutlined: true,
                  onPressed: onToggleLocale,
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: body),
                const SizedBox(width: AppSpacing.lg),
                SizedBox(
                  width: 170,
                  child: AppButton(
                    text: actionText,
                    isOutlined: true,
                    onPressed: onToggleLocale,
                  ),
                ),
              ],
            ),
    );
  }
}

class _CompactSectionHeader extends StatelessWidget {
  const _CompactSectionHeader({
    required this.title,
    required this.subtitle,
    required this.isMobile,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final bool isMobile;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final header = SectionTitle(
      title: title,
      subtitle: isMobile ? '' : subtitle,
    );

    if (trailing == null) return header;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: header),
        const SizedBox(width: AppSpacing.sm),
        trailing!,
      ],
    );
  }
}

class _ResponsiveAdminGrid extends StatelessWidget {
  const _ResponsiveAdminGrid({
    required this.children,
    required this.minTileWidth,
    required this.mobileMainAxisExtent,
    required this.desktopMainAxisExtent,
  });

  final List<Widget> children;
  final double minTileWidth;
  final double mobileMainAxisExtent;
  final double desktopMainAxisExtent;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isMobile = width < 640;
        final columns = (width / minTileWidth).floor().clamp(1, 4);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: children.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: isMobile ? AppSpacing.sm : AppSpacing.md,
            mainAxisSpacing: isMobile ? AppSpacing.sm : AppSpacing.md,
            mainAxisExtent:
                isMobile ? mobileMainAxisExtent : desktopMainAxisExtent,
          ),
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}

class _AdminKpiTile extends StatelessWidget {
  const _AdminKpiTile({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIconContainer(
                icon: icon,
                color: AppColors.primary,
                size: 34,
                iconSize: 18,
              ),
              const Spacer(),
              const Icon(Icons.trending_up_rounded,
                  color: AppColors.success, size: 17),
            ],
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
          ),
        ],
      ),
    );
  }
}

class _AdminModuleTile extends StatelessWidget {
  const _AdminModuleTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIconContainer(
                icon: icon,
                color: AppColors.secondary,
                size: 36,
                iconSize: 19,
              ),
              const Spacer(),
              if (onTap != null)
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: AppColors.textMuted),
            ],
          ),
          const Spacer(),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  height: 1.15,
                ),
          ),
          if (subtitle.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CompactEmptyCard extends StatelessWidget {
  const _CompactEmptyCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.textMuted),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _AdminError extends StatelessWidget {
  const _AdminError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.error, size: 34),
            const SizedBox(height: AppSpacing.sm),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: 180,
              child: AppButton(
                text: context.tr('common.retry'),
                onPressed: onRetry,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
