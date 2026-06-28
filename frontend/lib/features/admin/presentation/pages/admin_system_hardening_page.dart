import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/i18n/app_localizations.dart';
import 'package:ghiyarak/core/i18n/locale_controller.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/features/admin/data/admin_repository.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:ghiyarak/shared/widgets/enterprise_responsive.dart';
import 'package:ghiyarak/shared/widgets/section_title.dart';

final adminSystemHardeningProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  final locale = ref.watch(localeControllerProvider).languageCode;
  final overview = await repo.systemHardeningOverview();
  final naming = await repo.namingStandardReport();
  final modules = await repo.systemModules(locale: locale);
  final snapshots = await repo.analyticsSnapshots();
  final translations = await repo.translationCatalog();
  return {
    'overview': overview,
    'naming': naming,
    'modules': modules,
    'snapshots': snapshots,
    'translations': translations,
  };
});

class AdminSystemHardeningPage extends ConsumerWidget {
  const AdminSystemHardeningPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminSystemHardeningProvider);
    return AppScaffold(
      title: context.tr('admin.system_hardening'),
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(e.toString(), textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
                width: 180,
                child: AppButton(
                    text: context.tr('common.retry'),
                    onPressed: () =>
                        ref.invalidate(adminSystemHardeningProvider))),
          ]),
        ),
        data: (payload) {
          final overview =
              Map<String, dynamic>.from(payload['overview'] ?? const {});
          final naming =
              Map<String, dynamic>.from(payload['naming'] ?? const {});
          final modules = List<dynamic>.from(payload['modules'] ?? const []);
          final snapshots =
              List<dynamic>.from(payload['snapshots'] ?? const []);
          final translations =
              List<dynamic>.from(payload['translations'] ?? const []);
          final summary =
              Map<String, dynamic>.from(overview['summary'] ?? const {});
          final findings = List<dynamic>.from(overview['findings'] ?? const []);

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(adminSystemHardeningProvider),
            child: ListView(children: [
              SectionTitle(
                title: context.tr('admin.system_hardening'),
                subtitle:
                    'Architecture, naming, analytics snapshots, i18n catalog and audit integrity.',
              ),
              const SizedBox(height: AppSpacing.md),
              EnterpriseResponsiveGrid(children: [
                EnterpriseInfoCard(
                    title: 'CRITICAL',
                    value: '${summary['CRITICAL'] ?? 0}',
                    subtitle: 'Production blockers',
                    icon: Icons.dangerous_outlined),
                EnterpriseInfoCard(
                    title: 'HIGH',
                    value: '${summary['HIGH'] ?? 0}',
                    subtitle: 'Major risks',
                    icon: Icons.warning_amber_outlined),
                EnterpriseInfoCard(
                    title: 'Tables',
                    value: '${(overview['database'] ?? {})['tableCount'] ?? 0}',
                    subtitle: 'Database tables scanned',
                    icon: Icons.table_chart_outlined),
                EnterpriseInfoCard(
                    title: 'Modules',
                    value: '${modules.length}',
                    subtitle: context.tr('admin.module_registry'),
                    icon: Icons.apps_outlined),
                EnterpriseInfoCard(
                    title: 'Translations',
                    value: '${translations.length}',
                    subtitle: context.tr('admin.i18n_catalog'),
                    icon: Icons.translate_outlined),
                EnterpriseInfoCard(
                    title: 'Snapshots',
                    value: '${snapshots.length}',
                    subtitle: context.tr('admin.analytics_snapshots'),
                    icon: Icons.speed_outlined),
              ]),
              const SizedBox(height: AppSpacing.xl),
              Row(children: [
                Expanded(
                    child: SectionTitle(
                        title: context.tr('admin.analytics_snapshots'),
                        subtitle: 'Pre-aggregated metrics for dashboards.')),
                SizedBox(
                    width: 180,
                    child: AppButton(
                        text: 'Refresh',
                        onPressed: () async {
                          await ref
                              .read(adminRepositoryProvider)
                              .refreshAnalyticsSnapshots();
                          ref.invalidate(adminSystemHardeningProvider);
                        })),
              ]),
              const SizedBox(height: AppSpacing.md),
              if (snapshots.isEmpty)
                Text(context.tr('common.empty'))
              else
                ...snapshots.take(10).map((s) => Card(
                        child: ListTile(
                      leading: const Icon(Icons.analytics_outlined),
                      title: Text((s['metricLabelAr'] ??
                              s['metricLabelEn'] ??
                              s['metricKey'] ??
                              '')
                          .toString()),
                      subtitle: Text(
                          '${s['metricGroup'] ?? ''} • ${s['sourceModule'] ?? ''}'),
                      trailing: Text((s['numericValue'] ?? '0').toString()),
                    ))),
              const SizedBox(height: AppSpacing.xl),
              SectionTitle(
                  title: context.tr('admin.naming_report'),
                  subtitle:
                      'Database naming rules: snake_case, short names, no repeated context words.'),
              const SizedBox(height: AppSpacing.md),
              Card(
                  child: ListTile(
                leading: const Icon(Icons.rule_outlined),
                title: Text('Violations: ${naming['violationCount'] ?? 0}'),
                subtitle:
                    Text((naming['compatibilityPolicy'] ?? '').toString()),
              )),
              const SizedBox(height: AppSpacing.xl),
              SectionTitle(
                  title: 'Open Findings',
                  subtitle:
                      'Runtime audit findings and computed architecture risks.'),
              const SizedBox(height: AppSpacing.md),
              if (findings.isEmpty)
                Text(context.tr('common.empty'))
              else
                ...findings.take(20).map((f) => Card(
                        child: ListTile(
                      leading: Icon(
                          _iconForSeverity((f['severity'] ?? '').toString())),
                      title: Text(
                          '${f['severity'] ?? ''} • ${f['category'] ?? ''}'),
                      subtitle: Text((f['description'] ?? '').toString(),
                          maxLines: 3, overflow: TextOverflow.ellipsis),
                    ))),
              const SizedBox(height: AppSpacing.xl),
              SectionTitle(
                  title: context.tr('admin.module_registry'),
                  subtitle:
                      'Unified admin modules visible by RBAC permissions.'),
              const SizedBox(height: AppSpacing.md),
              ...modules.map((m) => Card(
                      child: ListTile(
                    leading: const Icon(Icons.apps_outlined),
                    title: Text((m['title'] ?? m['nameAr'] ?? m['code'] ?? '')
                        .toString()),
                    subtitle: Text(
                        '${m['code'] ?? ''} • ${m['permissionCode'] ?? ''}'),
                    trailing: Text((m['groupCode'] ?? '').toString()),
                  ))),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                  width: 220,
                  child: AppButton(
                      text: context.tr('admin.audit_integrity'),
                      isOutlined: true,
                      onPressed: () async {
                        await ref
                            .read(adminRepositoryProvider)
                            .createAuditIntegrityCheckpoint();
                        ref.invalidate(adminSystemHardeningProvider);
                      })),
            ]),
          );
        },
      ),
    );
  }

  IconData _iconForSeverity(String severity) {
    switch (severity) {
      case 'CRITICAL':
        return Icons.dangerous_outlined;
      case 'HIGH':
        return Icons.warning_amber_outlined;
      case 'MEDIUM':
        return Icons.info_outline;
      default:
        return Icons.check_circle_outline;
    }
  }
}
