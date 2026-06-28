import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/core/i18n/app_localizations.dart';
import 'package:ghiyarak/core/i18n/locale_controller.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/features/admin/data/admin_repository.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:ghiyarak/shared/widgets/section_title.dart';

final adminSettingsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  final settings = await repo.settings();
  final localization = await repo.localization();
  final flags = await repo.featureFlags();
  return {'settings': settings, 'localization': localization, 'flags': flags};
});

class AdminSettingsPage extends ConsumerWidget {
  const AdminSettingsPage({super.key});

  bool _flagEnabled(Map<String, dynamic> flag) {
    final value = flag['value'];
    if (value is Map && value['enabled'] is bool) {
      return value['enabled'] as bool;
    }
    final text = (flag['valueText'] ?? '').toString().toLowerCase();
    return text == 'enabled' || text == 'true' || text == '1';
  }

  Future<void> _editSetting(
      BuildContext context, WidgetRef ref, Map<String, dynamic> setting) async {
    final key = (setting['key'] ?? '').toString();
    final valueController =
        TextEditingController(text: (setting['valueText'] ?? '').toString());
    final descriptionController =
        TextEditingController(text: (setting['description'] ?? '').toString());
    var isPublic = setting['isPublic'] == true;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text("${context.tr('common.edit')} $key"),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: valueController,
                    decoration: InputDecoration(
                        labelText: context.tr('admin.settings.value'))),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                        labelText: context.tr('admin.settings.description')),
                    maxLines: 2),
                const SizedBox(height: AppSpacing.sm),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.tr('admin.settings.public')),
                  value: isPublic,
                  onChanged: (value) => setState(() => isPublic = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(context.tr('common.cancel'))),
            FilledButton(
              onPressed: () async {
                await ref.read(adminRepositoryProvider).upsertSetting(key, {
                  'valueText': valueController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'isPublic': isPublic,
                });
                ref.invalidate(adminSettingsProvider);
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              },
              child: Text(context.tr('common.save')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleFlag(BuildContext context, WidgetRef ref,
      Map<String, dynamic> flag, bool enabled) async {
    final key = (flag['key'] ?? '').toString();
    if (key.isEmpty) return;
    await ref.read(adminRepositoryProvider).upsertFeatureFlag(key,
        enabled: enabled, description: (flag['description'] ?? '').toString());
    ref.invalidate(adminSettingsProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.tr('common.success'))));
    }
  }

  Future<void> _addSetting(BuildContext context, WidgetRef ref) async {
    final keyController = TextEditingController();
    final valueController = TextEditingController();
    final descriptionController = TextEditingController();
    var isPublic = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(context.tr('admin.settings.add')),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: keyController,
                    decoration: InputDecoration(labelText: context.tr('key'))),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                    controller: valueController,
                    decoration: InputDecoration(
                        labelText: context.tr('admin.settings.value'))),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                        labelText: context.tr('admin.settings.description')),
                    maxLines: 2),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.tr('admin.settings.public')),
                  value: isPublic,
                  onChanged: (value) => setState(() => isPublic = value),
                ),
              ],
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
                await ref.read(adminRepositoryProvider).upsertSetting(key, {
                  'valueText': valueController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'isPublic': isPublic,
                });
                ref.invalidate(adminSettingsProvider);
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              },
              child: Text(context.tr('common.save')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminSettingsProvider);
    final locale = ref.watch(localeControllerProvider);
    return AppScaffold(
      title: context.tr('admin.settings.localization'),
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
                  onPressed: () => ref.invalidate(adminSettingsProvider))),
        ])),
        data: (payload) {
          final settings = List<dynamic>.from(payload['settings'] ?? const []);
          final flags = List<dynamic>.from(payload['flags'] ?? const []);
          return ListView(
            children: [
              SectionTitle(
                  title: context.tr('admin.settings.localization'),
                  subtitle: context.tr('settings.language_changed')),
              const SizedBox(height: AppSpacing.md),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.tr('admin.language'),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                            "${context.tr('settings.language')}: ${locale.languageCode.toUpperCase()}"),
                        const SizedBox(height: AppSpacing.md),
                        Wrap(spacing: AppSpacing.md, children: [
                          SizedBox(
                              width: 140,
                              child: AppButton(
                                  text: context.tr('settings.arabic'),
                                  onPressed: () => ref
                                      .read(localeControllerProvider.notifier)
                                      .setLocale(const Locale('ar')))),
                          SizedBox(
                              width: 140,
                              child: AppButton(
                                  text: context.tr('settings.english'),
                                  isOutlined: true,
                                  onPressed: () => ref
                                      .read(localeControllerProvider.notifier)
                                      .setLocale(const Locale('en')))),
                        ]),
                      ]),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Card(
                  child: ListTile(
                      leading: const Icon(Icons.security_outlined),
                      title: Text(context.tr('admin.system_hardening')),
                      subtitle: Text(context.tr('admin.i18n_catalog')),
                      onTap: () =>
                          context.go(RouteNames.adminSystemHardening))),
              const SizedBox(height: AppSpacing.md),
              Card(
                  child: ListTile(
                      leading: const Icon(Icons.translate),
                      title: Text(context.tr('admin.i18n_catalog')),
                      subtitle: Text(context.tr('settings.language_changed')),
                      onTap: () => context.go(RouteNames.adminTranslations))),
              const SizedBox(height: AppSpacing.xl),
              SectionTitle(
                  title: context.tr('admin.feature_flags'),
                  subtitle: context.tr('admin.feature_flags.subtitle')),
              const SizedBox(height: AppSpacing.md),
              if (flags.isEmpty)
                Text(context.tr('common.empty'))
              else
                ...flags.map((raw) {
                  final flag = Map<String, dynamic>.from(raw as Map);
                  final enabled = _flagEnabled(flag);
                  return Card(
                      child: SwitchListTile(
                    title: Text((flag['key'] ?? '').toString()),
                    subtitle: Text(
                        (flag['description'] ?? flag['valueText'] ?? '')
                            .toString()),
                    value: enabled,
                    onChanged: (value) =>
                        _toggleFlag(context, ref, flag, value),
                  ));
                }),
              const SizedBox(height: AppSpacing.xl),
              Row(children: [
                Expanded(
                    child: SectionTitle(
                        title: context.tr('admin.settings'),
                        subtitle: context.tr('admin.settings.subtitle'))),
                SizedBox(
                    width: 150,
                    child: AppButton(
                        text: context.tr('admin.settings.add'),
                        onPressed: () => _addSetting(context, ref))),
              ]),
              const SizedBox(height: AppSpacing.md),
              if (settings.isEmpty) Text(context.tr('common.empty')),
              ...settings.map((raw) {
                final s = Map<String, dynamic>.from(raw as Map);
                return Card(
                    child: ListTile(
                  title: Text((s['key'] ?? '').toString()),
                  subtitle: Text(
                      (s['description'] ?? s['valueText'] ?? s['value'] ?? '')
                          .toString()),
                  leading: SizedBox(
                    width: 40,
                    child: Icon(s['isPublic'] == true
                        ? Icons.public
                        : Icons.lock_outline),
                  ),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: () => _editSetting(context, ref, s),
                ));
              }),
            ],
          );
        },
      ),
    );
  }
}
