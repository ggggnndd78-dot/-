import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/features/admin/data/admin_repository.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:ghiyarak/shared/widgets/section_title.dart';

final adminAuditProvider = FutureProvider.autoDispose<List<dynamic>>((ref) {
  return ref.watch(adminRepositoryProvider).auditLogs();
});

class AdminAuditLogsPage extends ConsumerWidget {
  const AdminAuditLogsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminAuditProvider);
    return AppScaffold(
      title: 'سجل التدقيق',
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (logs) => ListView(
          children: [
            const SectionTitle(
                title: 'الأحداث الحرجة',
                subtitle: 'كل تغيير إداري مهم يتم تسجيله هنا.'),
            const SizedBox(height: AppSpacing.lg),
            ...logs.map((log) => Card(
                    child: ListTile(
                  title: Text((log['action'] ?? '').toString()),
                  subtitle: Text(
                      '${log['entityType'] ?? '-'} #${log['entityId'] ?? '-'}\n${log['createdAt'] ?? ''}'),
                ))),
          ],
        ),
      ),
    );
  }
}
