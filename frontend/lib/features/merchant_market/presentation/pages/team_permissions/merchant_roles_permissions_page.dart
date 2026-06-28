import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/features/merchant_market/data/merchant_market_repository.dart';
import 'package:ghiyarak/features/merchant_market/data/models/merchant_team_member_model.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_management_scaffold.dart';

class MerchantRolesPermissionsPage extends ConsumerStatefulWidget {
  const MerchantRolesPermissionsPage({super.key});

  @override
  ConsumerState<MerchantRolesPermissionsPage> createState() =>
      _MerchantRolesPermissionsPageState();
}

class _MerchantRolesPermissionsPageState
    extends ConsumerState<MerchantRolesPermissionsPage> {
  late Future<_RolesState> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_RolesState> _load() async {
    final repo = ref.read(merchantMarketRepositoryProvider);
    final results = await Future.wait<dynamic>([
      repo.getOrganizationRoles(),
      repo.getOrganizationPermissions(),
    ]);
    return _RolesState(
        roles: results[0] as List<Map<String, dynamic>>,
        permissions: results[1] as List<MerchantPermissionOptionModel>);
  }

  void _reload() => setState(() => _future = _load());

  Future<void> _openRole(
      {_RolesState? state, Map<String, dynamic>? role}) async {
    if (state == null) return;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _RoleSheet(state: state, role: role),
    );
    if (saved == true && mounted) _reload();
  }

  Future<void> _deleteRole(Map<String, dynamic> role) async {
    final isSystem = role['is_system'] == true || role['isSystem'] == true;
    if (isSystem) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الدور'),
        content: Text(
            'هل تريد حذف دور ${(role['name'] ?? role['code']).toString()}؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء')),
          FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('حذف')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref
          .read(merchantMarketRepositoryProvider)
          .deleteOrganizationRole((role['id'] ?? '').toString());
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تم حذف الدور')));
        _reload();
      }
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_RolesState>(
      future: _future,
      builder: (context, snapshot) {
        final state = snapshot.data;
        return MerchantManagementScaffold(
          title: 'الأدوار والصلاحيات',
          subtitle:
              'إنشاء أدوار دقيقة وربطها بصلاحيات المنتجات والطلبات والمخزون والفروع',
          onRefresh: () async => _reload(),
          children: [
            FilledButton.icon(
                onPressed: state == null ? null : () => _openRole(state: state),
                icon: const Icon(Icons.add),
                label: const Text('إنشاء دور جديد')),
            const SizedBox(height: 14),
            if (snapshot.connectionState != ConnectionState.done &&
                state == null)
              const Center(child: CircularProgressIndicator())
            else if (snapshot.hasError)
              MerchantStateCard(
                  icon: Icons.error_outline,
                  title: 'تعذر تحميل الأدوار',
                  message: snapshot.error.toString(),
                  actionLabel: 'إعادة المحاولة',
                  onAction: _reload)
            else if (state != null) ...[
              Row(
                children: [
                  Expanded(
                      child: MerchantMetricTile(
                          icon: Icons.admin_panel_settings_outlined,
                          label: 'الأدوار',
                          value: '${state.roles.length}')),
                  const SizedBox(width: 10),
                  Expanded(
                      child: MerchantMetricTile(
                          icon: Icons.key_outlined,
                          label: 'الصلاحيات',
                          value: '${state.permissions.length}')),
                ],
              ),
              const SizedBox(height: 14),
              if (state.roles.isEmpty)
                const MerchantStateCard(
                    icon: Icons.admin_panel_settings_outlined,
                    title: 'لا توجد أدوار',
                    message:
                        'أنشئ أدواراً مخصصة مثل مسؤول طلبات أو مدير مخزون.')
              else
                ...state.roles.map((role) => _RoleCard(
                    role: role,
                    permissions: state.permissions,
                    onEdit: () => _openRole(state: state, role: role),
                    onDelete: () => _deleteRole(role))),
            ],
          ],
        );
      },
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard(
      {required this.role,
      required this.permissions,
      required this.onEdit,
      required this.onDelete});
  final Map<String, dynamic> role;
  final List<MerchantPermissionOptionModel> permissions;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final rolePermissions =
        _list(role['permissions'] ?? role['permissionCodes']);
    final isSystem = role['is_system'] == true || role['isSystem'] == true;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MerchantPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shield_outlined, color: Color(0xFFFF7900)),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(
                        (role['name'] ?? role['code'] ?? 'دور').toString(),
                        style: const TextStyle(
                            color: Color(0xFF082B51),
                            fontSize: 17,
                            fontWeight: FontWeight.w900))),
                if (isSystem) const Chip(label: Text('نظامي')),
              ],
            ),
            const SizedBox(height: 6),
            Text((role['description'] ?? role['code'] ?? '').toString(),
                style: const TextStyle(color: Color(0xFF687686))),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: rolePermissions.isEmpty
                  ? [const Chip(label: Text('لا توجد صلاحيات'))]
                  : rolePermissions
                      .map((item) =>
                          Chip(label: Text(_permissionName(item, permissions))))
                      .toList(),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                    onPressed: isSystem ? null : onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('تعديل')),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                    onPressed: isSystem ? null : onDelete,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('حذف')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleSheet extends ConsumerStatefulWidget {
  const _RoleSheet({required this.state, this.role});
  final _RolesState state;
  final Map<String, dynamic>? role;

  @override
  ConsumerState<_RoleSheet> createState() => _RoleSheetState();
}

class _RoleSheetState extends ConsumerState<_RoleSheet> {
  final _name = TextEditingController();
  final _code = TextEditingController();
  final _description = TextEditingController();
  final _selected = <String>{};
  bool _saving = false;

  bool get isEditing => widget.role != null;

  @override
  void initState() {
    super.initState();
    final role = widget.role;
    if (role != null) {
      _name.text = (role['name'] ?? '').toString();
      _code.text = (role['code'] ?? '').toString();
      _description.text = (role['description'] ?? '').toString();
      _selected.addAll(_list(role['permissions'] ?? role['permissionCodes']));
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().length < 2 || _code.text.trim().length < 2) return;
    setState(() => _saving = true);
    final repo = ref.read(merchantMarketRepositoryProvider);
    try {
      if (isEditing) {
        await repo.updateOrganizationRole(
            roleId: (widget.role!['id'] ?? '').toString(),
            code: _code.text,
            name: _name.text,
            description: _description.text,
            permissionCodes: _selected.toList());
      } else {
        await repo.createOrganizationRole(
            code: _code.text,
            name: _name.text,
            description: _description.text,
            permissionCodes: _selected.toList());
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<MerchantPermissionOptionModel>>{};
    for (final permission in widget.state.permissions) {
      grouped
          .putIfAbsent(
              permission.module.isEmpty ? 'عام' : permission.module, () => [])
          .add(permission);
    }
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.only(
            left: 18,
            right: 18,
            bottom: MediaQuery.viewInsetsOf(context).bottom + 18),
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(isEditing ? 'تعديل دور' : 'إنشاء دور',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'اسم الدور')),
            const SizedBox(height: 10),
            TextField(
                controller: _code,
                decoration: const InputDecoration(
                    labelText: 'كود الدور', hintText: 'inventory_manager')),
            const SizedBox(height: 10),
            TextField(
                controller: _description,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'الوصف')),
            const SizedBox(height: 14),
            const Text('الصلاحيات',
                style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            for (final entry in grouped.entries) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Text(entry.key,
                    style: const TextStyle(
                        color: Color(0xFFFF7900), fontWeight: FontWeight.w900)),
              ),
              for (final permission in entry.value)
                CheckboxListTile(
                  value: _selected.contains(permission.code),
                  title: Text(permission.name.isEmpty
                      ? permission.code
                      : permission.name),
                  subtitle: Text(permission.code),
                  onChanged: (value) => setState(() {
                    if (value == true) {
                      _selected.add(permission.code);
                    } else {
                      _selected.remove(permission.code);
                    }
                  }),
                ),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save_outlined),
              label: Text(isEditing ? 'حفظ التعديل' : 'حفظ الدور'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RolesState {
  const _RolesState({required this.roles, required this.permissions});
  final List<Map<String, dynamic>> roles;
  final List<MerchantPermissionOptionModel> permissions;
}

List<String> _list(Object? value) {
  if (value is List) {
    return value
        .map((item) {
          if (item is Map)
            return (item['code'] ?? item['permissionCode'] ?? '').toString();
          return item.toString();
        })
        .where((item) => item.trim().isNotEmpty)
        .toList();
  }
  return const [];
}

String _permissionName(
    String code, List<MerchantPermissionOptionModel> permissions) {
  for (final permission in permissions) {
    if (permission.code == code)
      return permission.name.isEmpty ? code : permission.name;
  }
  return code;
}
