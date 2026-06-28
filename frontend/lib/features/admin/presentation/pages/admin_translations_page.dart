import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/i18n/app_localizations.dart';
import 'package:ghiyarak/core/i18n/locale_controller.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/features/admin/data/admin_repository.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:ghiyarak/shared/widgets/section_title.dart';

final adminTranslationsProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  return ref.watch(adminRepositoryProvider).translationCatalog();
});

class AdminTranslationsPage extends ConsumerWidget {
  const AdminTranslationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminTranslationsProvider);
    return AppScaffold(
      title: context.tr('admin.i18n_catalog'),
      child: async.when(
        loading: () => Center(child: Text(context.tr('common.loading'))),
        error: (error, _) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(error.toString(), textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            AppButton(
                text: context.tr('common.retry'),
                onPressed: () => ref.invalidate(adminTranslationsProvider)),
          ]),
        ),
        data: (rows) => ListView(
          children: [
            SectionTitle(
              title: context.tr('admin.i18n_catalog'),
              subtitle: context.tr('admin.i18n_catalog.subtitle'),
            ),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: SizedBox(
                width: 180,
                child: AppButton(
                  text: context.tr('admin.i18n.add_key'),
                  onPressed: () => _openEditor(context, ref),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (rows.isEmpty) Text(context.tr('common.empty')),
            ...rows.map((row) {
              final map = Map<String, dynamic>.from(row);
              return _TranslationCard(
                row: map,
                onEdit: () => _openEditor(context, ref, row: map),
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _openEditor(BuildContext context, WidgetRef ref,
      {Map<String, dynamic>? row}) async {
    final keyController = TextEditingController(
        text: row?['key']?.toString() ??
            row?['translationKey']?.toString() ??
            '');
    final namespaceController =
        TextEditingController(text: row?['namespace']?.toString() ?? 'app');
    final arController = TextEditingController();
    final enController = TextEditingController();
    final values = row?['values'];
    if (values is List) {
      for (final value in values) {
        if (value is! Map) continue;
        if (value['locale'] == 'ar') {
          arController.text = value['value']?.toString() ?? '';
        }
        if (value['locale'] == 'en') {
          enController.text = value['value']?.toString() ?? '';
        }
      }
    } else if (row?['locale'] == 'ar') {
      arController.text = row?['value']?.toString() ?? '';
    } else if (row?['locale'] == 'en') {
      enController.text = row?['value']?.toString() ?? '';
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(row == null
            ? context.tr('admin.i18n.add_key')
            : context.tr('common.edit')),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                  controller: keyController,
                  readOnly: row != null,
                  decoration: InputDecoration(labelText: context.tr('key'))),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                  controller: namespaceController,
                  decoration: InputDecoration(
                      labelText: context.tr('admin.i18n.namespace'))),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                  controller: arController,
                  decoration:
                      InputDecoration(labelText: context.tr('settings.arabic')),
                  maxLines: 3),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                  controller: enController,
                  decoration: InputDecoration(
                      labelText: context.tr('settings.english')),
                  maxLines: 3),
            ]),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(context.tr('common.cancel'))),
          FilledButton(
            onPressed: () async {
              final key = keyController.text.trim();
              if (key.isEmpty) return;
              final namespace = namespaceController.text.trim().isEmpty
                  ? 'app'
                  : namespaceController.text.trim();
              final repo = ref.read(adminRepositoryProvider);
              await repo.upsertTranslation(
                  key: key,
                  locale: 'ar',
                  value: arController.text,
                  namespace: namespace);
              await repo.upsertTranslation(
                  key: key,
                  locale: 'en',
                  value: enController.text,
                  namespace: namespace);
              await ref
                  .read(localeControllerProvider.notifier)
                  .refreshCatalog();
              ref.invalidate(adminTranslationsProvider);
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            },
            child: Text(context.tr('common.save')),
          ),
        ],
      ),
    );
  }
}

class _TranslationCard extends StatelessWidget {
  const _TranslationCard({required this.row, required this.onEdit});

  final Map<String, dynamic> row;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final values = row['values'] is List
        ? List<dynamic>.from(row['values'] as List)
        : const <dynamic>[];
    String valueFor(String locale) {
      if (values.isNotEmpty) {
        for (final item in values) {
          if (item is Map && item['locale'] == locale) {
            return item['value']?.toString() ?? '';
          }
        }
      }
      if (row['locale'] == locale) return row['value']?.toString() ?? '';
      return '';
    }

    return Card(
      child: ListTile(
        title: Text(
            row['key']?.toString() ?? row['translationKey']?.toString() ?? ''),
        subtitle: Text(
            "${context.tr('settings.arabic')}: ${valueFor('ar')}\n${context.tr('settings.english')}: ${valueFor('en')}"),
        isThreeLine: true,
        trailing: const Icon(Icons.edit_outlined),
        onTap: onEdit,
      ),
    );
  }
}
