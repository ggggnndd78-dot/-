import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/i18n/app_localizations.dart';
import 'package:ghiyarak/core/theme/app_colors.dart';
import 'package:ghiyarak/core/theme/app_radius.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/core/theme/app_text_styles.dart';
import 'package:ghiyarak/features/admin/data/admin_repository.dart';
import 'package:ghiyarak/shared/navigation/app_navigation_config.dart';
import 'package:ghiyarak/shared/widgets/app_card.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:ghiyarak/shared/widgets/app_states.dart';

final adminAnalyticsSectionProvider =
    StateProvider.autoDispose<AdminAnalyticsSection>((ref) {
  return AdminAnalyticsSection.overview;
});

final adminAnalyticsSnapshotGroupProvider = StateProvider.autoDispose<String>(
  (ref) => 'all',
);

final adminAnalyticsProvider =
    FutureProvider.autoDispose<AdminAnalyticsBundle>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  final group = ref.watch(adminAnalyticsSnapshotGroupProvider);
  return AdminAnalyticsBundle.load(
    repo,
    snapshotGroup: group == 'all' ? null : group,
  );
});

enum AdminAnalyticsSection {
  overview,
  orders,
  revenue,
  support,
  merchants,
  snapshots,
}

class AdminAnalyticsBundle {
  const AdminAnalyticsBundle({
    required this.dashboard,
    required this.enterprise,
    required this.orders,
    required this.revenue,
    required this.support,
    required this.merchants,
    required this.snapshots,
    required this.generatedAt,
  });

  final AdminReportResult<Map<String, dynamic>> dashboard;
  final AdminReportResult<Map<String, dynamic>> enterprise;
  final AdminReportResult<List<dynamic>> orders;
  final AdminReportResult<List<dynamic>> revenue;
  final AdminReportResult<List<dynamic>> support;
  final AdminReportResult<List<dynamic>> merchants;
  final AdminReportResult<List<dynamic>> snapshots;
  final DateTime generatedAt;

  static Future<AdminAnalyticsBundle> load(
    AdminRepository repo, {
    String? snapshotGroup,
  }) async {
    final results = await Future.wait<AdminReportResult<dynamic>>([
      _safe<Map<String, dynamic>>(repo.dashboardSummary),
      _safe<Map<String, dynamic>>(repo.enterpriseAnalytics),
      _safe<List<dynamic>>(repo.orderMetrics),
      _safe<List<dynamic>>(repo.revenueDaily),
      _safe<List<dynamic>>(repo.supportMetrics),
      _safe<List<dynamic>>(repo.merchantMetrics),
      _safe<List<dynamic>>(
        () => repo.analyticsSnapshots(group: snapshotGroup),
      ),
    ]);

    return AdminAnalyticsBundle(
      dashboard: results[0].cast<Map<String, dynamic>>(),
      enterprise: results[1].cast<Map<String, dynamic>>(),
      orders: results[2].cast<List<dynamic>>(),
      revenue: results[3].cast<List<dynamic>>(),
      support: results[4].cast<List<dynamic>>(),
      merchants: results[5].cast<List<dynamic>>(),
      snapshots: results[6].cast<List<dynamic>>(),
      generatedAt: DateTime.now(),
    );
  }

  bool get hasPartialFailure => [
        dashboard,
        enterprise,
        orders,
        revenue,
        support,
        merchants,
        snapshots,
      ].any((result) => result.hasError);

  List<AdminMetric> metrics(BuildContext context) {
    final dashboardData = dashboard.data ?? const <String, dynamic>{};
    final enterpriseData = enterprise.data ?? const <String, dynamic>{};
    final metrics = <AdminMetric>[];

    metrics.addAll(_metricsFromMap(dashboardData));
    metrics.addAll(_metricsFromMap(enterpriseData));
    metrics.addAll([
      AdminMetric(
        label: context.tr('admin.analytics.orders_records'),
        value: _countLabel(orders.data),
        icon: Icons.receipt_long_outlined,
        color: AppColors.info,
      ),
      AdminMetric(
        label: context.tr('admin.analytics.revenue_records'),
        value: _countLabel(revenue.data),
        icon: Icons.payments_outlined,
        color: AppColors.success,
      ),
      AdminMetric(
        label: context.tr('admin.analytics.support_records'),
        value: _countLabel(support.data),
        icon: Icons.support_agent_outlined,
        color: AppColors.warning,
      ),
      AdminMetric(
        label: context.tr('admin.analytics.snapshot_records'),
        value: _countLabel(snapshots.data),
        icon: Icons.query_stats_outlined,
        color: AppColors.secondary,
      ),
    ]);

    final seen = <String>{};
    return metrics.where((metric) {
      final key = '${metric.label}:${metric.value}';
      if (seen.contains(key)) return false;
      seen.add(key);
      return true;
    }).take(8).toList(growable: false);
  }

  String toCsv(BuildContext context) {
    final lines = <String>[
      'section,key,value',
      ..._mapToCsvRows('dashboard', dashboard.data),
      ..._mapToCsvRows('enterprise', enterprise.data),
      ..._rowsToCsvRows('orders', orders.data),
      ..._rowsToCsvRows('revenue', revenue.data),
      ..._rowsToCsvRows('support', support.data),
      ..._rowsToCsvRows('merchants', merchants.data),
      ..._rowsToCsvRows('snapshots', snapshots.data),
    ];
    if (lines.length == 1) {
      lines.add('message,status,${_csv(context.tr('common.empty'))}');
    }
    return lines.join('\n');
  }
}

class AdminReportResult<T> {
  const AdminReportResult._({this.data, this.error});

  const AdminReportResult.success(T data) : this._(data: data);
  const AdminReportResult.failure(Object error) : this._(error: error);

  final T? data;
  final Object? error;

  bool get hasError => error != null;

  AdminReportResult<R> cast<R>() {
    final value = data;
    if (value is R) return AdminReportResult<R>.success(value);
    if (hasError) return AdminReportResult<R>.failure(error!);
    return AdminReportResult<R>.failure('Unexpected analytics payload');
  }
}

class AdminMetric {
  const AdminMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

Future<AdminReportResult<T>> _safe<T>(Future<T> Function() loader) async {
  try {
    return AdminReportResult<T>.success(await loader());
  } catch (error) {
    return AdminReportResult<T>.failure(error);
  }
}

class AdminAnalyticsPage extends ConsumerWidget {
  const AdminAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminAnalyticsProvider);
    final selectedSection = ref.watch(adminAnalyticsSectionProvider);
    final data = async.asData?.value;

    return AppScaffold(
      title: context.tr('admin.analytics'),
      navigationArea: AppNavigationArea.admin,
      actions: [
        IconButton(
          tooltip: context.tr('common.retry'),
          onPressed: async.isLoading
              ? null
              : () => ref.invalidate(adminAnalyticsProvider),
          icon: const Icon(Icons.refresh_rounded),
        ),
        IconButton(
          tooltip: context.tr('admin.analytics.export_csv'),
          onPressed: data == null ? null : () => _copyCsv(context, data),
          icon: const Icon(Icons.ios_share_rounded),
        ),
      ],
      child: async.when(
        loading: () => const AppLoadingState(),
        error: (error, _) => AppErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(adminAnalyticsProvider),
        ),
        data: (bundle) => RefreshIndicator(
          onRefresh: () async => ref.refresh(adminAnalyticsProvider.future),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 620;
              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _MobileAnalyticsHeader(
                      bundle: bundle,
                      compact: compact,
                      onRefresh: () => ref.invalidate(adminAnalyticsProvider),
                      onCopyCsv: () => _copyCsv(context, bundle),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.md),
                  ),
                  SliverToBoxAdapter(
                    child: _CompactMetricGrid(
                      metrics: bundle.metrics(context),
                      compact: compact,
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.md),
                  ),
                  SliverToBoxAdapter(
                    child: _AnalyticsQuickSections(
                      selected: selectedSection,
                      onChanged: (section) {
                        ref
                            .read(adminAnalyticsSectionProvider.notifier)
                            .state = section;
                      },
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.md),
                  ),
                  SliverToBoxAdapter(
                    child: _AnalyticsSectionBody(
                      bundle: bundle,
                      section: selectedSection,
                      compact: compact,
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.md),
                  ),
                  SliverToBoxAdapter(
                    child: _SnapshotGroupSelector(
                      onRefreshSnapshots: () => _refreshSnapshots(context, ref),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.xl),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _copyCsv(BuildContext context, AdminAnalyticsBundle data) async {
    await Clipboard.setData(ClipboardData(text: data.toCsv(context)));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr('admin.analytics.csv_copied'))),
    );
  }

  Future<void> _refreshSnapshots(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final successMessage = context.tr('common.success');
    try {
      await ref.read(adminRepositoryProvider).refreshAnalyticsSnapshots();
      ref.invalidate(adminAnalyticsProvider);
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
    } catch (error) {
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}

class _MobileAnalyticsHeader extends StatelessWidget {
  const _MobileAnalyticsHeader({
    required this.bundle,
    required this.compact,
    required this.onRefresh,
    required this.onCopyCsv,
  });

  final AdminAnalyticsBundle bundle;
  final bool compact;
  final VoidCallback onRefresh;
  final VoidCallback onCopyCsv;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      tone: AppCardTone.elevated,
      padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.lg),
      borderColor: AppColors.primary.withValues(alpha: 0.26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppIconContainer(
                icon: Icons.analytics_outlined,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('admin.analytics.title'),
                      maxLines: compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: compact
                          ? AppTextStyles.cardTitle
                          : AppTextStyles.pageTitle,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr('admin.analytics.subtitle'),
                      maxLines: compact ? 2 : 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _SmallIconAction(
                icon: Icons.refresh_rounded,
                tooltip: context.tr('common.retry'),
                onPressed: onRefresh,
              ),
              const SizedBox(width: 6),
              _SmallIconAction(
                icon: Icons.ios_share_rounded,
                tooltip: context.tr('admin.analytics.export_csv'),
                onPressed: onCopyCsv,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _TinyInfoPill(
                icon: Icons.schedule_rounded,
                text:
                    '${context.tr('admin.analytics.generated_at')} ${_formatDateTime(bundle.generatedAt)}',
              ),
              _TinyInfoPill(
                icon: bundle.hasPartialFailure
                    ? Icons.warning_amber_rounded
                    : Icons.cloud_done_outlined,
                text: bundle.hasPartialFailure
                    ? context.tr('admin.analytics.partial_data')
                    : context.tr('admin.analytics.live_data'),
                color: bundle.hasPartialFailure
                    ? AppColors.warning
                    : AppColors.success,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallIconAction extends StatelessWidget {
  const _SmallIconAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}

class _TinyInfoPill extends StatelessWidget {
  const _TinyInfoPill({required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: effectiveColor.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: effectiveColor),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(color: effectiveColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactMetricGrid extends StatelessWidget {
  const _CompactMetricGrid({required this.metrics, required this.compact});

  final List<AdminMetric> metrics;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) {
      return AppEmptyState(
        icon: Icons.insights_outlined,
        title: context.tr('admin.analytics'),
        message: context.tr('common.empty'),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width < 380
            ? 2
            : width < 720
                ? 2
                : width < 1040
                    ? 3
                    : 4;
        final gap = compact ? AppSpacing.sm : AppSpacing.md;
        final itemWidth = (width - (gap * (columns - 1))) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: metrics.map((metric) {
            return SizedBox(
              width: itemWidth,
              child: _SmallMetricCard(metric: metric, compact: compact),
            );
          }).toList(growable: false),
        );
      },
    );
  }
}

class _SmallMetricCard extends StatelessWidget {
  const _SmallMetricCard({required this.metric, required this.compact});

  final AdminMetric metric;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      tone: AppCardTone.accent,
      padding: EdgeInsets.all(compact ? 12 : AppSpacing.md),
      child: SizedBox(
        height: compact ? 96 : 118,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: compact ? 30 : 36,
                  height: compact ? 30 : 36,
                  decoration: BoxDecoration(
                    color: metric.color.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: metric.color.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Icon(metric.icon, color: metric.color, size: 18),
                ),
                const Spacer(),
                Icon(Icons.trending_up_rounded, size: 16, color: metric.color),
              ],
            ),
            const Spacer(),
            Text(
              metric.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: (compact ? AppTextStyles.heading2 : AppTextStyles.heading1)
                  .copyWith(color: metric.color),
            ),
            const SizedBox(height: 2),
            Text(
              metric.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsQuickSections extends StatelessWidget {
  const _AnalyticsQuickSections({required this.selected, required this.onChanged});

  final AdminAnalyticsSection selected;
  final ValueChanged<AdminAnalyticsSection> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: AdminAnalyticsSection.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final section = AdminAnalyticsSection.values[index];
          final isSelected = selected == section;
          return _SectionChip(
            label: _sectionLabel(context, section),
            icon: _sectionIcon(section),
            selected: isSelected,
            onPressed: () => onChanged(section),
          );
        },
      ),
    );
  }
}

class _SectionChip extends StatelessWidget {
  const _SectionChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textSecondary;
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.13)
          : AppColors.surfaceHigh,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: color.withValues(alpha: 0.24)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: color,
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalyticsSectionBody extends StatelessWidget {
  const _AnalyticsSectionBody({
    required this.bundle,
    required this.section,
    required this.compact,
  });

  final AdminAnalyticsBundle bundle;
  final AdminAnalyticsSection section;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    switch (section) {
      case AdminAnalyticsSection.overview:
        return _OverviewSection(bundle: bundle, compact: compact);
      case AdminAnalyticsSection.orders:
        return _ListAnalyticsSection(
          title: context.tr('admin.analytics.orders'),
          subtitle: context.tr('admin.analytics.orders_subtitle'),
          icon: Icons.receipt_long_outlined,
          color: AppColors.info,
          result: bundle.orders,
          compact: compact,
        );
      case AdminAnalyticsSection.revenue:
        return _ListAnalyticsSection(
          title: context.tr('admin.analytics.revenue'),
          subtitle: context.tr('admin.analytics.revenue_subtitle'),
          icon: Icons.payments_outlined,
          color: AppColors.success,
          result: bundle.revenue,
          compact: compact,
        );
      case AdminAnalyticsSection.support:
        return _ListAnalyticsSection(
          title: context.tr('admin.analytics.support'),
          subtitle: context.tr('admin.analytics.support_subtitle'),
          icon: Icons.support_agent_outlined,
          color: AppColors.warning,
          result: bundle.support,
          compact: compact,
        );
      case AdminAnalyticsSection.merchants:
        return _ListAnalyticsSection(
          title: context.tr('admin.analytics.merchants'),
          subtitle: context.tr('admin.analytics.merchants_subtitle'),
          icon: Icons.store_mall_directory_outlined,
          color: AppColors.primary,
          result: bundle.merchants,
          compact: compact,
        );
      case AdminAnalyticsSection.snapshots:
        return _ListAnalyticsSection(
          title: context.tr('admin.analytics.snapshots'),
          subtitle: context.tr('admin.analytics.snapshots_subtitle'),
          icon: Icons.query_stats_outlined,
          color: AppColors.secondary,
          result: bundle.snapshots,
          compact: compact,
        );
    }
  }
}

class _OverviewSection extends StatelessWidget {
  const _OverviewSection({required this.bundle, required this.compact});

  final AdminAnalyticsBundle bundle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final revenueRows = _mapRows(bundle.revenue.data);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PolicyMiniCard(bundle: bundle),
        const SizedBox(height: AppSpacing.md),
        _MapSummaryCard(
          title: context.tr('admin.analytics.dashboard_summary'),
          subtitle: context.tr('admin.analytics.dashboard_summary_subtitle'),
          icon: Icons.dashboard_customize_outlined,
          data: bundle.dashboard,
          compact: compact,
        ),
        const SizedBox(height: AppSpacing.md),
        _MapSummaryCard(
          title: context.tr('admin.analytics.enterprise_summary'),
          subtitle: context.tr('admin.analytics.enterprise_summary_subtitle'),
          icon: Icons.insights_outlined,
          data: bundle.enterprise,
          compact: compact,
        ),
        const SizedBox(height: AppSpacing.md),
        _MobileBarChartCard(
          title: context.tr('admin.analytics.revenue_trend'),
          subtitle: context.tr('admin.analytics.revenue_subtitle'),
          icon: Icons.trending_up_rounded,
          color: AppColors.success,
          rows: revenueRows,
          compact: compact,
        ),
      ],
    );
  }
}

class _PolicyMiniCard extends StatelessWidget {
  const _PolicyMiniCard({required this.bundle});

  final AdminAnalyticsBundle bundle;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      tone: AppCardTone.accent,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitleRow(
            title: context.tr('admin.analytics.policy_title'),
            subtitle: context.tr('admin.analytics.policy_subtitle'),
            icon: Icons.verified_user_outlined,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AppStatusBadge(
                label: context.tr('admin.analytics.permission_view_reports'),
                icon: Icons.lock_open_outlined,
                color: AppColors.primary,
              ),
              AppStatusBadge(
                label: bundle.hasPartialFailure
                    ? context.tr('admin.analytics.partial_data')
                    : context.tr('admin.analytics.live_data'),
                icon: bundle.hasPartialFailure
                    ? Icons.warning_amber_rounded
                    : Icons.cloud_done_outlined,
                color: bundle.hasPartialFailure
                    ? AppColors.warning
                    : AppColors.success,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MapSummaryCard extends StatelessWidget {
  const _MapSummaryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.data,
    required this.compact,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final AdminReportResult<Map<String, dynamic>> data;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (data.hasError) return AppErrorState(message: data.error.toString());
    final entries = (data.data ?? const <String, dynamic>{})
        .entries
        .where((entry) => _isDisplayableSummaryValue(entry.value))
        .take(compact ? 6 : 10)
        .toList(growable: false);

    if (entries.isEmpty) {
      return AppEmptyState(
        icon: icon,
        title: title,
        message: context.tr('common.empty'),
      );
    }

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitleRow(title: title, subtitle: subtitle, icon: icon),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: entries.map((entry) {
              return _MiniSummaryTile(
                label: _humanizeKey(entry.key),
                value: _valueToDisplay(entry.value),
              );
            }).toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _MiniSummaryTile extends StatelessWidget {
  const _MiniSummaryTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 120, maxWidth: 165),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body.copyWith(
              color: AppColors.secondary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

class _ListAnalyticsSection extends StatelessWidget {
  const _ListAnalyticsSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.result,
    required this.compact,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final AdminReportResult<List<dynamic>> result;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (result.hasError) return AppErrorState(message: result.error.toString());
    final rows = _mapRows(result.data);
    if (rows.isEmpty) {
      return AppEmptyState(
        icon: icon,
        title: title,
        message: context.tr('common.empty'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MobileBarChartCard(
          title: title,
          subtitle: subtitle,
          icon: icon,
          color: color,
          rows: rows,
          compact: compact,
        ),
        const SizedBox(height: AppSpacing.md),
        _MobileRowsCard(
          title: context.tr('admin.analytics.latest_rows'),
          subtitle: subtitle,
          rows: rows,
          compact: compact,
        ),
      ],
    );
  }
}

class _MobileBarChartCard extends StatelessWidget {
  const _MobileBarChartCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.rows,
    required this.compact,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<Map<String, dynamic>> rows;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final bars = rows.take(compact ? 6 : 10).map(_ChartPoint.fromMap).toList();
    final maxValue = bars.fold<num>(0, (max, point) {
      return point.value > max ? point.value : max;
    });

    return AppCard(
      tone: AppCardTone.elevated,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitleRow(title: title, subtitle: subtitle, icon: icon),
          const SizedBox(height: AppSpacing.md),
          if (bars.isEmpty || maxValue <= 0)
            AppEmptyState(
              icon: icon,
              title: context.tr('common.empty'),
              message: context.tr('admin.analytics.no_numeric_data'),
            )
          else
            Column(
              children: bars.map((point) {
                final ratio = (point.value / maxValue).clamp(0.05, 1.0);
                return _CompactBarRow(
                  point: point,
                  ratio: ratio.toDouble(),
                  color: color,
                  compact: compact,
                );
              }).toList(growable: false),
            ),
        ],
      ),
    );
  }
}

class _CompactBarRow extends StatelessWidget {
  const _CompactBarRow({
    required this.point,
    required this.ratio,
    required this.color,
    required this.compact,
  });

  final _ChartPoint point;
  final double ratio;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  point.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                _formatNumber(point.value),
                style: AppTextStyles.caption.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Stack(
              children: [
                Container(height: compact ? 10 : 14, color: AppColors.surfaceHigh),
                FractionallySizedBox(
                  widthFactor: ratio,
                  child: Container(
                    height: compact ? 10 : 14,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color.withValues(alpha: 0.52),
                          color,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileRowsCard extends StatelessWidget {
  const _MobileRowsCard({
    required this.title,
    required this.subtitle,
    required this.rows,
    required this.compact,
  });

  final String title;
  final String subtitle;
  final List<Map<String, dynamic>> rows;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final columns = _tableColumns(rows).take(compact ? 3 : 5).toList();
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitleRow(
            title: title,
            subtitle: subtitle,
            icon: Icons.table_rows_outlined,
          ),
          const SizedBox(height: AppSpacing.md),
          for (final row in rows.take(compact ? 6 : 10)) ...[
            _ReportRowTile(row: row, columns: columns),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _ReportRowTile extends StatelessWidget {
  const _ReportRowTile({required this.row, required this.columns});

  final Map<String, dynamic> row;
  final List<String> columns;

  @override
  Widget build(BuildContext context) {
    final titleKey = columns.isNotEmpty ? columns.first : 'value';
    final title = _valueToDisplay(row[titleKey] ?? _bestLabel(row));
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh.withValues(alpha: 0.66),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: 6,
            children: columns.skip(1).map((column) {
              return _TinyInfoPill(
                icon: _iconForKey(column),
                text: '${_humanizeKey(column)}: ${_valueToDisplay(row[column])}',
              );
            }).toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _SnapshotGroupSelector extends ConsumerWidget {
  const _SnapshotGroupSelector({required this.onRefreshSnapshots});

  final VoidCallback onRefreshSnapshots;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(adminAnalyticsSnapshotGroupProvider);
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitleRow(
            title: context.tr('admin.analytics.snapshot_group'),
            subtitle: context.tr('admin.analytics.snapshots_subtitle'),
            icon: Icons.history_edu_outlined,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final item in const ['all', 'daily', 'weekly', 'monthly'])
                _SectionChip(
                  label: context.tr('admin.analytics.group.$item'),
                  icon: item == 'all'
                      ? Icons.all_inclusive_rounded
                      : Icons.calendar_month_outlined,
                  selected: group == item,
                  onPressed: () {
                    ref.read(adminAnalyticsSnapshotGroupProvider.notifier).state =
                        item;
                  },
                ),
              _SectionChip(
                label: context.tr('admin.analytics.refresh_snapshots'),
                icon: Icons.sync_rounded,
                selected: false,
                onPressed: onRefreshSnapshots,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitleRow extends StatelessWidget {
  const _SectionTitleRow({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppIconContainer(icon: icon, color: AppColors.primary),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.cardTitle,
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChartPoint {
  const _ChartPoint({required this.label, required this.value});

  final String label;
  final num value;

  factory _ChartPoint.fromMap(Map<String, dynamic> row) {
    return _ChartPoint(label: _bestLabel(row), value: _bestNumber(row));
  }
}

List<AdminMetric> _metricsFromMap(Map<String, dynamic> map) {
  final metrics = <AdminMetric>[];
  for (final entry in map.entries) {
    if (metrics.length >= 6) break;
    final value = entry.value;
    if (value is num || value is String || value is bool) {
      metrics.add(
        AdminMetric(
          label: _humanizeKey(entry.key),
          value: _valueToDisplay(value),
          icon: _iconForKey(entry.key),
          color: _colorForKey(entry.key),
        ),
      );
    }
  }
  return metrics;
}

bool _isDisplayableSummaryValue(Object? value) {
  return value is num || value is String || value is bool;
}

List<Map<String, dynamic>> _mapRows(List<dynamic>? data) {
  if (data == null) return const <Map<String, dynamic>>[];
  return data.map((item) {
    if (item is Map<String, dynamic>) return item;
    if (item is Map) return Map<String, dynamic>.from(item);
    return <String, dynamic>{'value': item};
  }).toList(growable: false);
}

List<String> _tableColumns(List<Map<String, dynamic>> rows) {
  final ordered = <String>[];
  const priority = [
    'date',
    'day',
    'month',
    'status',
    'count',
    'total',
    'amount',
    'revenue',
    'value',
  ];
  for (final key in priority) {
    if (rows.any((row) => row.containsKey(key))) ordered.add(key);
  }
  for (final row in rows.take(5)) {
    for (final key in row.keys) {
      if (!ordered.contains(key)) ordered.add(key);
      if (ordered.length >= 6) return ordered;
    }
  }
  return ordered.isEmpty ? ['value'] : ordered.take(6).toList(growable: false);
}

String _bestLabel(Map<String, dynamic> row) {
  const keys = [
    'label',
    'name',
    'title',
    'date',
    'day',
    'month',
    'status',
    'type',
    'category',
    'code',
  ];
  for (final key in keys) {
    final value = row[key];
    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString();
    }
  }
  if (row.keys.isNotEmpty) return _humanizeKey(row.keys.first);
  return '-';
}

num _bestNumber(Map<String, dynamic> row) {
  const keys = [
    'value',
    'total',
    'amount',
    'revenue',
    'count',
    'orders',
    'users',
    'tickets',
    'score',
  ];
  for (final key in keys) {
    final parsed = _tryParseNumber(row[key]);
    if (parsed != null) return parsed;
  }
  for (final value in row.values) {
    final parsed = _tryParseNumber(value);
    if (parsed != null) return parsed;
  }
  return 0;
}

num? _tryParseNumber(Object? value) {
  if (value is num) return value;
  if (value is String) return num.tryParse(value.replaceAll(',', '').trim());
  return null;
}

String _countLabel(List<dynamic>? rows) => (rows?.length ?? 0).toString();

String _formatNumber(num value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(2);
}

String _formatDateTime(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')} $hour:$minute';
}

String _valueToDisplay(Object? value) {
  if (value == null) return '-';
  if (value is num) return _formatNumber(value);
  if (value is bool) return value ? 'Yes' : 'No';
  if (value is List) return value.length.toString();
  if (value is Map) return value.length.toString();
  final text = value.toString();
  return text.length > 80 ? '${text.substring(0, 77)}...' : text;
}

String _humanizeKey(String key) {
  final spaced = key
      .replaceAll(RegExp(r'[_\-]+'), ' ')
      .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (match) {
    return '${match.group(1)} ${match.group(2)}';
  });
  if (spaced.isEmpty) return key;
  return spaced[0].toUpperCase() + spaced.substring(1);
}

IconData _iconForKey(String key) {
  final lower = key.toLowerCase();
  if (lower.contains('user') || lower.contains('customer')) {
    return Icons.people_alt_outlined;
  }
  if (lower.contains('merchant') || lower.contains('store')) {
    return Icons.storefront_outlined;
  }
  if (lower.contains('workshop')) return Icons.car_repair_outlined;
  if (lower.contains('order')) return Icons.receipt_long_outlined;
  if (lower.contains('payment') || lower.contains('revenue')) {
    return Icons.payments_outlined;
  }
  if (lower.contains('ticket') || lower.contains('support')) {
    return Icons.support_agent_outlined;
  }
  if (lower.contains('risk') || lower.contains('security')) {
    return Icons.security_outlined;
  }
  return Icons.insights_outlined;
}

Color _colorForKey(String key) {
  final lower = key.toLowerCase();
  if (lower.contains('revenue') || lower.contains('payment')) {
    return AppColors.success;
  }
  if (lower.contains('risk') || lower.contains('pending')) {
    return AppColors.warning;
  }
  if (lower.contains('error') || lower.contains('failed')) {
    return AppColors.error;
  }
  if (lower.contains('merchant') || lower.contains('workshop')) {
    return AppColors.primary;
  }
  return AppColors.info;
}

IconData _sectionIcon(AdminAnalyticsSection section) {
  switch (section) {
    case AdminAnalyticsSection.overview:
      return Icons.dashboard_customize_outlined;
    case AdminAnalyticsSection.orders:
      return Icons.receipt_long_outlined;
    case AdminAnalyticsSection.revenue:
      return Icons.payments_outlined;
    case AdminAnalyticsSection.support:
      return Icons.support_agent_outlined;
    case AdminAnalyticsSection.merchants:
      return Icons.store_mall_directory_outlined;
    case AdminAnalyticsSection.snapshots:
      return Icons.query_stats_outlined;
  }
}

String _sectionLabel(BuildContext context, AdminAnalyticsSection section) {
  switch (section) {
    case AdminAnalyticsSection.overview:
      return context.tr('admin.analytics.overview');
    case AdminAnalyticsSection.orders:
      return context.tr('admin.analytics.orders');
    case AdminAnalyticsSection.revenue:
      return context.tr('admin.analytics.revenue');
    case AdminAnalyticsSection.support:
      return context.tr('admin.analytics.support');
    case AdminAnalyticsSection.merchants:
      return context.tr('admin.analytics.merchants');
    case AdminAnalyticsSection.snapshots:
      return context.tr('admin.analytics.snapshots');
  }
}

List<String> _mapToCsvRows(String section, Map<String, dynamic>? map) {
  if (map == null) return const <String>[];
  return map.entries.map((entry) {
    return '${_csv(section)},${_csv(entry.key)},${_csv(_valueToDisplay(entry.value))}';
  }).toList(growable: false);
}

List<String> _rowsToCsvRows(String section, List<dynamic>? rows) {
  if (rows == null) return const <String>[];
  final lines = <String>[];
  for (var i = 0; i < rows.length; i++) {
    final row = rows[i];
    if (row is Map) {
      for (final entry in row.entries) {
        lines.add(
          '${_csv(section)},${_csv('row_$i.${entry.key}')},${_csv(_valueToDisplay(entry.value))}',
        );
      }
    } else {
      lines.add('${_csv(section)},row_$i,${_csv(_valueToDisplay(row))}');
    }
  }
  return lines;
}

String _csv(String value) => '"${value.replaceAll('"', '""')}"';
