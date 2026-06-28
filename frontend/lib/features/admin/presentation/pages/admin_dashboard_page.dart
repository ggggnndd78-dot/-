import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/i18n/app_localizations.dart';
import 'package:ghiyarak/core/theme/app_colors.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/features/admin/data/admin_repository.dart';
import 'package:ghiyarak/shared/widgets/app_card.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:ghiyarak/shared/widgets/section_title.dart';

final adminDashboardProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
  return ref.watch(adminRepositoryProvider).dashboardSummary();
});

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminDashboardProvider);
    return AppScaffold(
      title: context.tr('admin.dashboard'),
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _AdminDashboardError(
          message: e.toString(),
          onRetry: () => ref.invalidate(adminDashboardProvider),
        ),
        data: (data) => LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 640;
            return ListView(
              padding: EdgeInsets.zero,
              children: [
                SectionTitle(
                  title: context.tr('admin.dashboard'),
                  subtitle: isMobile
                      ? ''
                      : 'مؤشرات مختصرة من قاعدة البيانات لمراقبة المنصة بسرعة.',
                ),
                SizedBox(height: isMobile ? AppSpacing.sm : AppSpacing.lg),
                if (data.isEmpty)
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(context.tr('common.empty')),
                  )
                else
                  _AdminSummaryGrid(
                    entries: data.entries.toList(),
                    isMobile: isMobile,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AdminSummaryGrid extends StatelessWidget {
  const _AdminSummaryGrid({required this.entries, required this.isMobile});

  final List<MapEntry<String, dynamic>> entries;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / (isMobile ? 150 : 210))
            .floor()
            .clamp(1, 4);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: entries.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: isMobile ? AppSpacing.sm : AppSpacing.md,
            mainAxisSpacing: isMobile ? AppSpacing.sm : AppSpacing.md,
            mainAxisExtent: isMobile ? 112 : 132,
          ),
          itemBuilder: (context, index) {
            final item = entries[index];
            return _MetricCard(
              label: item.key,
              value: item.value.toString(),
            );
          },
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.query_stats_rounded,
              color: AppColors.primary, size: 24),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _AdminDashboardError extends StatelessWidget {
  const _AdminDashboardError({required this.message, required this.onRetry});

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
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.tr('common.retry')),
            ),
          ],
        ),
      ),
    );
  }
}
