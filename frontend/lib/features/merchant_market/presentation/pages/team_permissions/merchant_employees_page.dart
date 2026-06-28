import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/features/merchant_market/data/merchant_market_repository.dart';
import 'package:ghiyarak/features/merchant_market/data/models/merchant_organization_model.dart';
import 'package:ghiyarak/features/merchant_market/data/models/merchant_team_member_model.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_management_scaffold.dart';

class MerchantEmployeesPage extends ConsumerStatefulWidget {
  const MerchantEmployeesPage({super.key});

  @override
  ConsumerState<MerchantEmployeesPage> createState() =>
      _MerchantEmployeesPageState();
}

class _MerchantEmployeesPageState extends ConsumerState<MerchantEmployeesPage> {
  late Future<_EmployeesState> _future;
  final _search = TextEditingController();
  String _status = 'ALL';
  String _role = 'ALL';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<_EmployeesState> _load() async {
    final repo = ref.read(merchantMarketRepositoryProvider);
    final results = await Future.wait<dynamic>([
      repo.getMerchantOrganization(),
      repo.getMerchantTeam(),
      repo.getEmployeeInvitations(),
      repo.getOrganizationRoles(),
      repo.getOrganizationPermissions(),
    ]);
    return _EmployeesState(
      organization: results[0] as MerchantOrganizationModel,
      members: results[1] as List<MerchantTeamMemberModel>,
      invitations: results[2] as List<Map<String, dynamic>>,
      roles: (results[3] as List<Map<String, dynamic>>),
      permissions: results[4] as List<MerchantPermissionOptionModel>,
    );
  }

  void _reload() => setState(() => _future = _load());

  List<MerchantTeamMemberModel> _filtered(
      List<MerchantTeamMemberModel> members) {
    final query = _search.text.trim().toLowerCase();
    return members.where((member) {
      final matchesSearch = query.isEmpty ||
          member.name.toLowerCase().contains(query) ||
          member.contactLabel.toLowerCase().contains(query) ||
          member.role.toLowerCase().contains(query);
      final matchesStatus = _status == 'ALL' || member.status == _status;
      final matchesRole = _role == 'ALL' || member.role == _role;
      return matchesSearch && matchesStatus && matchesRole;
    }).toList();
  }

  Future<void> _invite(_EmployeesState state) async {
    final done = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _InviteEmployeeSheet(roles: state.roles),
    );
    if (done == true && mounted) _reload();
  }

  Future<void> _editMember(
      _EmployeesState state, MerchantTeamMemberModel member) async {
    final done = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _EditMemberSheet(state: state, member: member),
    );
    if (done == true && mounted) _reload();
  }

  Future<void> _cancelInvitation(Map<String, dynamic> invitation) async {
    final id = (invitation['id'] ?? '').toString();
    if (id.isEmpty) return;
    try {
      await ref
          .read(merchantMarketRepositoryProvider)
          .cancelEmployeeInvitation(id);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تم إلغاء الدعوة')));
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
    return FutureBuilder<_EmployeesState>(
      future: _future,
      builder: (context, snapshot) {
        final state = snapshot.data;
        final members = state == null
            ? const <MerchantTeamMemberModel>[]
            : _filtered(state.members);
        return MerchantManagementScaffold(
          title: 'الموظفون',
          subtitle: 'دعوة الموظفين وتحديد أدوارهم وصلاحياتهم وفروعهم',
          onRefresh: () async => _reload(),
          children: [
            if (snapshot.connectionState != ConnectionState.done &&
                state == null)
              const Center(child: CircularProgressIndicator())
            else if (snapshot.hasError)
              MerchantStateCard(
                icon: Icons.error_outline,
                title: 'تعذر تحميل الموظفين',
                message: snapshot.error.toString(),
                actionLabel: 'إعادة المحاولة',
                onAction: _reload,
              )
            else if (state != null) ...[
              FilledButton.icon(
                onPressed: () => _invite(state),
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('دعوة موظف'),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                      child: MerchantMetricTile(
                          icon: Icons.groups_2_outlined,
                          label: 'الأعضاء',
                          value: '${state.members.length}')),
                  const SizedBox(width: 10),
                  Expanded(
                      child: MerchantMetricTile(
                          icon: Icons.mail_outline,
                          label: 'الدعوات',
                          value: '${state.invitations.length}')),
                ],
              ),
              const SizedBox(height: 14),
              _Filters(
                search: _search,
                status: _status,
                role: _role,
                roles:
                    state.members.map((member) => member.role).toSet().toList()
                      ..sort(),
                onChanged: () => setState(() {}),
                onStatus: (value) => setState(() => _status = value ?? 'ALL'),
                onRole: (value) => setState(() => _role = value ?? 'ALL'),
              ),
              const SizedBox(height: 14),
              if (members.isEmpty)
                const MerchantStateCard(
                  icon: Icons.groups_outlined,
                  title: 'لا توجد نتائج',
                  message: 'غيّر البحث أو الفلاتر، أو أرسل دعوة لموظف جديد.',
                )
              else
                ...members.map((member) => _MemberCard(
                    member: member, onEdit: () => _editMember(state, member))),
              const SizedBox(height: 16),
              _InvitationsPanel(
                  invitations: state.invitations, onCancel: _cancelInvitation),
            ],
          ],
        );
      },
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters(
      {required this.search,
      required this.status,
      required this.role,
      required this.roles,
      required this.onChanged,
      required this.onStatus,
      required this.onRole});
  final TextEditingController search;
  final String status;
  final String role;
  final List<String> roles;
  final VoidCallback onChanged;
  final ValueChanged<String?> onStatus;
  final ValueChanged<String?> onRole;

  @override
  Widget build(BuildContext context) {
    return MerchantPanel(
      child: Column(
        children: [
          TextField(
            controller: search,
            onChanged: (_) => onChanged(),
            decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'بحث بالاسم أو الهاتف أو الدور'),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'الحالة'),
                  items: const [
                    DropdownMenuItem(value: 'ALL', child: Text('كل الحالات')),
                    DropdownMenuItem(value: 'ACTIVE', child: Text('نشط')),
                    DropdownMenuItem(value: 'SUSPENDED', child: Text('موقوف')),
                  ],
                  onChanged: onStatus,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: role,
                  decoration: const InputDecoration(labelText: 'الدور'),
                  items: [
                    const DropdownMenuItem(
                        value: 'ALL', child: Text('كل الأدوار')),
                    ...roles.map((item) => DropdownMenuItem(
                        value: item, child: Text(_roleLabel(item)))),
                  ],
                  onChanged: onRole,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.member, required this.onEdit});
  final MerchantTeamMemberModel member;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MerchantPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      const Color(0xFFFF7900).withValues(alpha: .12),
                  child: Text(
                      member.name.trim().isEmpty
                          ? 'م'
                          : member.name.trim().substring(0, 1),
                      style: const TextStyle(
                          color: Color(0xFFFF7900),
                          fontWeight: FontWeight.w900)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(member.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 16)),
                      Text(
                          '${_roleLabel(member.role)} • ${member.contactLabel}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xFF687686))),
                    ],
                  ),
                ),
                Chip(label: Text(_statusLabel(member.status))),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (member.permissions.isEmpty)
                  const Chip(label: Text('بدون صلاحيات مباشرة')),
                ...member.permissions.take(6).map((permission) =>
                    Chip(label: Text(_permissionLabel(permission)))),
              ],
            ),
            const SizedBox(height: 8),
            Text(
                'الفروع: ${member.branchAccess.isEmpty ? 'كل/غير محدد' : member.branchAccess.map((item) => '${item.branchName}${item.canManage ? ' إدارة' : ' مشاهدة'}').join('، ')}',
                style: const TextStyle(color: Color(0xFF687686))),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                  onPressed: member.isOwner ? null : onEdit,
                  icon: const Icon(Icons.tune),
                  label: const Text('إدارة الموظف')),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvitationsPanel extends StatelessWidget {
  const _InvitationsPanel({required this.invitations, required this.onCancel});
  final List<Map<String, dynamic>> invitations;
  final ValueChanged<Map<String, dynamic>> onCancel;

  @override
  Widget build(BuildContext context) {
    return MerchantPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('الدعوات المفتوحة',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          if (invitations.isEmpty)
            const Text('لا توجد دعوات حالية')
          else
            for (final invitation in invitations)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.mark_email_unread_outlined,
                    color: Color(0xFFFF7900)),
                title: Text(
                    (invitation['email'] ?? invitation['phone'] ?? 'دعوة')
                        .toString()),
                subtitle: Text(
                    '${_roleLabel((invitation['member_role'] ?? '').toString())} • ${_invitationStatus((invitation['status'] ?? '').toString())}'),
                trailing:
                    ((invitation['status'] ?? '').toString().toUpperCase() ==
                            'PENDING')
                        ? IconButton(
                            onPressed: () => onCancel(invitation),
                            icon: const Icon(Icons.close),
                            tooltip: 'إلغاء الدعوة')
                        : null,
              ),
        ],
      ),
    );
  }
}

class _InviteEmployeeSheet extends ConsumerStatefulWidget {
  const _InviteEmployeeSheet({required this.roles});
  final List<Map<String, dynamic>> roles;

  @override
  ConsumerState<_InviteEmployeeSheet> createState() =>
      _InviteEmployeeSheetState();
}

class _InviteEmployeeSheetState extends ConsumerState<_InviteEmployeeSheet> {
  final _phone = TextEditingController();
  final _email = TextEditingController();
  String _role = 'staff';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.roles.isNotEmpty)
      _role = (widget.roles.first['code'] ?? 'staff').toString();
  }

  @override
  void dispose() {
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_phone.text.trim().isEmpty && _email.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await ref.read(merchantMarketRepositoryProvider).inviteEmployee(
          phone: _phone.text, email: _email.text, memberRole: _role);
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
            const Text('دعوة موظف',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'رقم الجوال')),
            const SizedBox(height: 10),
            TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration:
                    const InputDecoration(labelText: 'البريد الإلكتروني')),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: const InputDecoration(labelText: 'الدور'),
              items: [
                if (widget.roles.isEmpty)
                  const DropdownMenuItem(value: 'staff', child: Text('موظف')),
                ...widget.roles.map((role) => DropdownMenuItem(
                    value: (role['code'] ?? 'staff').toString(),
                    child: Text((role['name'] ?? role['code']).toString()))),
              ],
              onChanged: (value) => setState(() => _role = value ?? 'staff'),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send_outlined),
              label: const Text('إرسال الدعوة'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditMemberSheet extends ConsumerStatefulWidget {
  const _EditMemberSheet({required this.state, required this.member});
  final _EmployeesState state;
  final MerchantTeamMemberModel member;

  @override
  ConsumerState<_EditMemberSheet> createState() => _EditMemberSheetState();
}

class _EditMemberSheetState extends ConsumerState<_EditMemberSheet> {
  late String _role;
  late String _status;
  late Set<String> _permissions;
  late Map<String, _BranchAccessValue> _branches;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _role = widget.member.role;
    _status = widget.member.status;
    _permissions = widget.member.permissions.toSet();
    _branches = {
      for (final branch in widget.state.organization.branches)
        branch.id: _BranchAccessValue(
          canView: widget.member.branchAccess
              .any((item) => item.branchId == branch.id && item.canView),
          canManage: widget.member.branchAccess
              .any((item) => item.branchId == branch.id && item.canManage),
        ),
    };
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final repo = ref.read(merchantMarketRepositoryProvider);
    try {
      await repo.updateMemberStatus(
          memberId: widget.member.id, status: _status, memberRole: _role);
      await repo.updateMemberPermissions(
          memberId: widget.member.id, permissionCodes: _permissions.toList());
      await repo.updateMemberBranchAccess(
        memberId: widget.member.id,
        items: _branches.entries
            .where((entry) => entry.value.canView || entry.value.canManage)
            .map((entry) => {
                  'branchId': entry.key,
                  'canView': entry.value.canView || entry.value.canManage,
                  'canManage': entry.value.canManage
                })
            .toList(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _remove() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الموظف'),
        content: Text('هل تريد حذف ${widget.member.name} من فريق المتجر؟'),
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
          .removeMember(widget.member.id);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
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
            Text('إدارة ${widget.member.name}',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'الحالة'),
              items: const [
                DropdownMenuItem(value: 'ACTIVE', child: Text('نشط')),
                DropdownMenuItem(value: 'SUSPENDED', child: Text('موقوف')),
              ],
              onChanged: (value) => setState(() => _status = value ?? 'ACTIVE'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: widget.state.roles
                      .any((item) => (item['code'] ?? '').toString() == _role)
                  ? _role
                  : null,
              decoration: const InputDecoration(labelText: 'الدور'),
              items: widget.state.roles
                  .map((role) => DropdownMenuItem(
                      value: (role['code'] ?? '').toString(),
                      child: Text((role['name'] ?? role['code']).toString())))
                  .toList(),
              onChanged: (value) => setState(() => _role = value ?? _role),
            ),
            const SizedBox(height: 14),
            const Text('الصلاحيات المباشرة',
                style: TextStyle(fontWeight: FontWeight.w900)),
            for (final permission in widget.state.permissions)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _permissions.contains(permission.code),
                title: Text(permission.name.isEmpty
                    ? _permissionLabel(permission.code)
                    : permission.name),
                subtitle: Text(permission.code),
                onChanged: (value) => setState(() {
                  if (value == true) {
                    _permissions.add(permission.code);
                  } else {
                    _permissions.remove(permission.code);
                  }
                }),
              ),
            const SizedBox(height: 12),
            const Text('صلاحيات الفروع',
                style: TextStyle(fontWeight: FontWeight.w900)),
            for (final branch in widget.state.organization.branches)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(branch.name,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  Row(
                    children: [
                      Expanded(
                        child: CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _branches[branch.id]?.canView ?? false,
                          title: const Text('مشاهدة'),
                          onChanged: (value) => setState(() =>
                              _branches[branch.id] = (_branches[branch.id] ??
                                      const _BranchAccessValue())
                                  .copyWith(canView: value == true)),
                        ),
                      ),
                      Expanded(
                        child: CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _branches[branch.id]?.canManage ?? false,
                          title: const Text('إدارة'),
                          onChanged: (value) => setState(() =>
                              _branches[branch.id] = (_branches[branch.id] ??
                                      const _BranchAccessValue())
                                  .copyWith(
                                      canManage: value == true,
                                      canView: value == true ? true : null)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save_outlined),
              label: const Text('حفظ التعديلات'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
                onPressed: _saving ? null : _remove,
                icon: const Icon(Icons.delete_outline),
                label: const Text('حذف الموظف')),
          ],
        ),
      ),
    );
  }
}

class _BranchAccessValue {
  const _BranchAccessValue({this.canView = false, this.canManage = false});
  final bool canView;
  final bool canManage;

  _BranchAccessValue copyWith({bool? canView, bool? canManage}) =>
      _BranchAccessValue(
          canView: canView ?? this.canView,
          canManage: canManage ?? this.canManage);
}

class _EmployeesState {
  const _EmployeesState(
      {required this.organization,
      required this.members,
      required this.invitations,
      required this.roles,
      required this.permissions});
  final MerchantOrganizationModel organization;
  final List<MerchantTeamMemberModel> members;
  final List<Map<String, dynamic>> invitations;
  final List<Map<String, dynamic>> roles;
  final List<MerchantPermissionOptionModel> permissions;
}

String _statusLabel(String status) => switch (status.toUpperCase()) {
      'ACTIVE' => 'نشط',
      'SUSPENDED' => 'موقوف',
      'PENDING' => 'بانتظار',
      _ => status.isEmpty ? 'غير محدد' : status,
    };

String _invitationStatus(String status) => switch (status.toUpperCase()) {
      'PENDING' => 'بانتظار القبول',
      'ACCEPTED' => 'مقبولة',
      'EXPIRED' => 'منتهية',
      'CANCELLED' => 'ملغية',
      _ => status,
    };

String _roleLabel(String role) => switch (role.toLowerCase()) {
      'owner' => 'مالك',
      'admin' => 'مدير عام',
      'manager' => 'مدير',
      'branch_manager' => 'مدير فرع',
      'inventory_manager' => 'مسؤول مخزون',
      'orders_agent' => 'موظف طلبات',
      'staff' => 'موظف',
      'suspended' => 'موقوف',
      _ => role,
    };

String _permissionLabel(String code) => switch (code) {
      'manage_products' => 'إدارة المنتجات',
      'publish_products' => 'نشر المنتجات',
      'manage_inventory' => 'إدارة المخزون',
      'view_orders' => 'مشاهدة الطلبات',
      'update_orders' => 'تحديث الطلبات',
      'manage_branches' => 'إدارة الفروع',
      'manage_organization' => 'إدارة المؤسسة',
      'manage_team' => 'إدارة الفريق',
      'view_reports' => 'التقارير',
      'manage_settings' => 'الإعدادات',
      _ => code,
    };
