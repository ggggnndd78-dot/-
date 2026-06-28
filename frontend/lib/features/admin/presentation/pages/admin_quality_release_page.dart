import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/i18n/app_localizations.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/features/admin/data/admin_repository.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:ghiyarak/shared/widgets/enterprise_responsive.dart';
import 'package:ghiyarak/shared/widgets/section_title.dart';

final adminQualityReleaseProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  final readiness = await repo.qualityReadiness();
  final runs = await repo.qualityRuns();
  final checklist = await repo.releaseChecklist();
  final deployments = await repo.deploymentRuns();
  return {
    'readiness': readiness,
    'runs': runs,
    'checklist': checklist,
    'deployments': deployments,
  };
});

class AdminQualityReleasePage extends ConsumerWidget {
  const AdminQualityReleasePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminQualityReleaseProvider);
    return AppScaffold(
      title: context.tr('admin.quality_release'),
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(error.toString(), textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
                width: 180,
                child: AppButton(
                    text: context.tr('common.retry'),
                    onPressed: () =>
                        ref.invalidate(adminQualityReleaseProvider))),
          ]),
        ),
        data: (payload) {
          final readiness =
              Map<String, dynamic>.from(payload['readiness'] ?? const {});
          final runs = List<dynamic>.from(payload['runs'] ?? const []);
          final checklist =
              List<dynamic>.from(payload['checklist'] ?? const []);
          final deployments =
              List<dynamic>.from(payload['deployments'] ?? const []);
          final missingTables =
              List<dynamic>.from(readiness['missingTables'] ?? const []);
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(adminQualityReleaseProvider),
            child: ListView(children: [
              SectionTitle(
                  title: context.tr('admin.quality_release'),
                  subtitle: context.tr('admin.quality_release.subtitle')),
              const SizedBox(height: AppSpacing.md),
              EnterpriseResponsiveGrid(children: [
                EnterpriseInfoCard(
                    title: context.tr('admin.release_status'),
                    value: (readiness['status'] ?? 'UNKNOWN').toString(),
                    subtitle: context.tr('admin.release_status.subtitle'),
                    icon: Icons.verified_outlined),
                EnterpriseInfoCard(
                    title: context.tr('admin.release_blockers'),
                    value: '${readiness['blockers'] ?? 0}',
                    subtitle: context.tr('admin.release_blockers.subtitle'),
                    icon: Icons.block_outlined),
                EnterpriseInfoCard(
                    title: context.tr('admin.qa_runs'),
                    value: '${runs.length}',
                    subtitle: context.tr('admin.qa_runs.subtitle'),
                    icon: Icons.fact_check_outlined),
                EnterpriseInfoCard(
                    title: context.tr('admin.deployments'),
                    value: '${deployments.length}',
                    subtitle: context.tr('admin.deployments.subtitle'),
                    icon: Icons.rocket_launch_outlined),
              ]),
              const SizedBox(height: AppSpacing.xl),
              SectionTitle(
                  title: context.tr('admin.release_checklist'),
                  subtitle: context.tr('admin.release_checklist.subtitle')),
              const SizedBox(height: AppSpacing.md),
              if (checklist.isEmpty)
                Text(context.tr('common.empty'))
              else
                ...checklist.map((item) => Card(
                      child: ListTile(
                        leading: Icon(
                            _iconForStatus((item['status'] ?? '').toString())),
                        title: Text((item['titleAr'] ??
                                item['titleEn'] ??
                                item['itemKey'] ??
                                '')
                            .toString()),
                        subtitle: Text(
                            '${item['moduleCode'] ?? ''} • ${item['description'] ?? ''}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        trailing: Text((item['status'] ?? '').toString()),
                      ),
                    )),
              const SizedBox(height: AppSpacing.xl),
              SectionTitle(
                  title: context.tr('admin.latest_qa_runs'),
                  subtitle: context.tr('admin.latest_qa_runs.subtitle')),
              const SizedBox(height: AppSpacing.md),
              if (runs.isEmpty)
                Text(context.tr('common.empty'))
              else
                ...runs.take(10).map((run) => Card(
                      child: ListTile(
                        leading:
                            const Icon(Icons.assignment_turned_in_outlined),
                        title: Text(
                            (run['title'] ?? run['runKey'] ?? '').toString()),
                        subtitle: Text(
                            '${run['environment'] ?? ''} • ${run['scope'] ?? ''}'),
                        trailing: Text((run['status'] ?? '').toString()),
                      ),
                    )),
              const SizedBox(height: AppSpacing.xl),
              SectionTitle(
                  title: context.tr('admin.deployments'),
                  subtitle: context.tr('admin.deployments.subtitle')),
              const SizedBox(height: AppSpacing.md),
              if (deployments.isEmpty)
                Text(context.tr('common.empty'))
              else
                ...deployments.take(10).map((deployment) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.rocket_launch_outlined),
                        title: Text(
                            '${deployment['version'] ?? ''} • ${deployment['environment'] ?? ''}'),
                        subtitle: Text(
                            (deployment['deploymentKey'] ?? '').toString()),
                        trailing: Text((deployment['status'] ?? '').toString()),
                      ),
                    )),
              if (missingTables.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
                SectionTitle(
                    title: context.tr('admin.missing_tables'),
                    subtitle: context.tr('admin.missing_tables.subtitle')),
                const SizedBox(height: AppSpacing.md),
                ...missingTables.map((table) => Card(
                    child: ListTile(
                        leading: const Icon(Icons.table_rows_outlined),
                        title: Text(table.toString())))),
              ],
            ]),
          );
        },
      ),
    );
  }

  IconData _iconForStatus(String status) {
    switch (status) {
      case 'PASSED':
        return Icons.check_circle_outline;
      case 'FAILED':
        return Icons.error_outline;
      case 'WAIVED':
        return Icons.info_outline;
      default:
        return Icons.pending_actions_outlined;
    }
  }
}
