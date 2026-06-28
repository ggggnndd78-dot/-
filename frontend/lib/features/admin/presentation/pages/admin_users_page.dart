import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/i18n/app_localizations.dart';
import 'package:ghiyarak/core/theme/app_colors.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/features/admin/data/admin_repository.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:ghiyarak/shared/widgets/section_title.dart';

final adminUsersSearchProvider = StateProvider.autoDispose<String>((ref) => '');

final adminUsersProvider = FutureProvider.autoDispose<List<dynamic>>((ref) {
  final q = ref.watch(adminUsersSearchProvider);
  return ref
      .watch(adminRepositoryProvider)
      .users(q: q.trim().isEmpty ? null : q.trim());
});

final adminRolesProvider = FutureProvider.autoDispose<List<dynamic>>((ref) {
  return ref.watch(adminRepositoryProvider).roles();
});

class AdminUsersPage extends ConsumerWidget {
  const AdminUsersPage({super.key});

  List<String> _roleCodesFromUser(Map<String, dynamic> user) {
    return List<dynamic>.from(user['userRoles'] ?? [])
        .map((roleItem) => (roleItem['role']?['code'] ?? '').toString())
        .where((code) => code.isNotEmpty)
        .toList();
  }

  Future<void> _showUserDialog(BuildContext context, WidgetRef ref,
      {Map<String, dynamic>? user}) async {
    final roles = await ref
        .read(adminRolesProvider.future)
        .catchError((_) => <dynamic>[]);
    if (!context.mounted) return;
    final isEdit = user != null;
    final phoneController = TextEditingController(
        text: (user?['phoneNormalized'] ?? '').toString());
    final nameController =
        TextEditingController(text: (user?['displayName'] ?? '').toString());
    final emailController =
        TextEditingController(text: (user?['email'] ?? '').toString());
    String status = (user?['status'] ?? 'ACTIVE').toString();
    String locale = (user?['locale'] ?? 'ar').toString();
    final selectedRoles = <String>{..._roleCodesFromUser(user ?? const {})};
    if (selectedRoles.isEmpty && !isEdit) selectedRoles.add('customer');
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEdit
              ? context.tr('admin.users.edit')
              : context.tr('admin.users.add')),
          content: SizedBox(
            width: 620,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s-]'))
                      ],
                      decoration: InputDecoration(
                          labelText: context.tr('auth.phone'),
                          helperText: context.tr('auth.phone.carriers_yemen')),
                      validator: (value) => (value ?? '').trim().isEmpty
                          ? context.tr('validation.required')
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                            labelText: context.tr('auth.full_name'))),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                            labelText: context.tr('auth.email'))),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<String>(
                      initialValue: status,
                      decoration: InputDecoration(
                          labelText: context.tr('common.status')),
                      items: [
                        DropdownMenuItem(
                            value: 'ACTIVE',
                            child: Text(context.tr('status.active'))),
                        DropdownMenuItem(
                            value: 'BLOCKED',
                            child: Text(context.tr('status.blocked'))),
                      ],
                      onChanged: (value) =>
                          setState(() => status = value ?? 'ACTIVE'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<String>(
                      initialValue: locale == 'en' ? 'en' : 'ar',
                      decoration: InputDecoration(
                          labelText: context.tr('settings.language')),
                      items: [
                        DropdownMenuItem(
                            value: 'ar',
                            child: Text(context.tr('settings.arabic'))),
                        DropdownMenuItem(
                            value: 'en',
                            child: Text(context.tr('settings.english'))),
                      ],
                      onChanged: (value) =>
                          setState(() => locale = value ?? 'ar'),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(context.tr('admin.users.roles'),
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List<dynamic>.from(roles).map((role) {
                        final code = (role['code'] ?? '').toString();
                        final label = (role['name'] ?? code).toString();
                        return FilterChip(
                          label: Text(label),
                          selected: selectedRoles.contains(code),
                          onSelected: (selected) => setState(() {
                            if (selected) {
                              selectedRoles.add(code);
                            } else {
                              selectedRoles.remove(code);
                            }
                          }),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(context.tr('common.cancel'))),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final data = {
                  'phone': phoneController.text.trim(),
                  'displayName': nameController.text.trim(),
                  'email': emailController.text.trim(),
                  'status': status,
                  'locale': locale,
                  'roleCodes': selectedRoles.toList(),
                };
                try {
                  if (isEdit) {
                    await ref
                        .read(adminRepositoryProvider)
                        .updateUser(user['id'].toString(), data);
                  } else {
                    await ref.read(adminRepositoryProvider).createUser(data);
                  }
                  ref.invalidate(adminUsersProvider);
                  if (context.mounted) Navigator.of(context).pop();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(context.tr('common.success'))));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                }
              },
              child: Text(context.tr('common.save')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteUser(
      BuildContext context, WidgetRef ref, Map<String, dynamic> user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('admin.users.delete')),
        content: Text(context.tr('admin.users.delete_confirm')),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(context.tr('common.cancel'))),
          FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(context.tr('common.confirm'))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(adminRepositoryProvider).deleteUser(user['id'].toString());
      ref.invalidate(adminUsersProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr('common.success'))));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _toggleStatus(
      BuildContext context, WidgetRef ref, Map<String, dynamic> user) async {
    final id = user['id'].toString();
    final next = user['status'] == 'ACTIVE' ? 'BLOCKED' : 'ACTIVE';
    try {
      await ref.read(adminRepositoryProvider).updateUserStatus(id, next);
      ref.invalidate(adminUsersProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr('common.success'))));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminUsersProvider);
    final searchController =
        TextEditingController(text: ref.watch(adminUsersSearchProvider));
    return AppScaffold(
      title: context.tr('admin.users'),
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (users) => ListView(
          children: [
            SectionTitle(
                title: context.tr('admin.users'),
                subtitle: context.tr('admin.users.subtitle')),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 360,
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                        labelText: context.tr('common.search'),
                        prefixIcon: const Icon(Icons.search)),
                    onSubmitted: (value) => ref
                        .read(adminUsersSearchProvider.notifier)
                        .state = value,
                  ),
                ),
                SizedBox(
                    width: 150,
                    child: AppButton(
                        text: context.tr('common.search'),
                        onPressed: () => ref
                            .read(adminUsersSearchProvider.notifier)
                            .state = searchController.text)),
                SizedBox(
                    width: 180,
                    child: AppButton(
                        text: context.tr('admin.users.add'),
                        onPressed: () => _showUserDialog(context, ref))),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            if (users.isEmpty)
              Card(
                  child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Text(context.tr('common.empty')))),
            ...users.map((raw) {
              final user = Map<String, dynamic>.from(raw as Map);
              final roles = _roleCodesFromUser(user).join(', ');
              final active = user['status'] == 'ACTIVE';
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                              child: Text(((user['displayName'] ??
                                              user['phoneNormalized'] ??
                                              '?')
                                          .toString())
                                      .isNotEmpty
                                  ? ((user['displayName'] ??
                                              user['phoneNormalized'] ??
                                              '?')
                                          .toString())
                                      .substring(0, 1)
                                      .toUpperCase()
                                  : '?')),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    (user['displayName'] ??
                                            user['phoneNormalized'] ??
                                            'User')
                                        .toString(),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16)),
                                Text(
                                    '${user['phoneNormalized'] ?? '-'} • ${user['email'] ?? '-'}'),
                                Text(
                                    '${context.tr('admin.users.roles')}: ${roles.isEmpty ? '-' : roles}'),
                              ],
                            ),
                          ),
                          Chip(
                            backgroundColor: active
                                ? AppColors.success.withValues(alpha: 0.12)
                                : AppColors.error.withValues(alpha: 0.10),
                            label: Text(active
                                ? context.tr('status.active')
                                : context.tr('status.blocked')),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          SizedBox(
                              width: 130,
                              child: AppButton(
                                  text: context.tr('common.edit'),
                                  isOutlined: true,
                                  onPressed: () => _showUserDialog(context, ref,
                                      user: user))),
                          SizedBox(
                              width: 150,
                              child: OutlinedButton(
                                  onPressed: () =>
                                      _toggleStatus(context, ref, user),
                                  child: Text(active
                                      ? context.tr('admin.users.block')
                                      : context.tr('admin.users.activate')))),
                          SizedBox(
                              width: 130,
                              child: OutlinedButton(
                                  onPressed: () =>
                                      _deleteUser(context, ref, user),
                                  child: Text(context.tr('common.delete')))),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
