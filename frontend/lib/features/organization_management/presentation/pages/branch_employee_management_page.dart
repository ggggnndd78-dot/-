import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/features/organization_management/data/organization_management_repository.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:ghiyarak/shared/widgets/app_text_field.dart';
import 'package:ghiyarak/shared/widgets/section_title.dart';

class BranchEmployeeManagementPage extends ConsumerStatefulWidget {
  const BranchEmployeeManagementPage({super.key});
  @override
  ConsumerState<BranchEmployeeManagementPage> createState() =>
      _BranchEmployeeManagementPageState();
}

class _BranchEmployeeManagementPageState
    extends ConsumerState<BranchEmployeeManagementPage> {
  bool _loading = true;
  String? _organizationId;
  List<Map<String, dynamic>> _organizations = const [];
  List<Map<String, dynamic>> _branches = const [];
  List<Map<String, dynamic>> _employees = const [];
  List<Map<String, dynamic>> _permissions = const [];
  final _branchName = TextEditingController();
  final _branchCityId = TextEditingController(text: '1');
  final _branchAddress = TextEditingController();
  final _employeeName = TextEditingController();
  final _employeePhone = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _branchName.dispose();
    _branchCityId.dispose();
    _branchAddress.dispose();
    _employeeName.dispose();
    _employeePhone.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final repo = ref.read(organizationManagementRepositoryProvider);
    final orgs = await repo.myOrganizations();
    final approved = orgs.where((org) => org['status'] == 'APPROVED').toList();
    final selectedId = _organizationId ??
        (approved.isNotEmpty ? approved.first['id']?.toString() : null);
    List<Map<String, dynamic>> branches = const [];
    List<Map<String, dynamic>> employees = const [];
    List<Map<String, dynamic>> permissions = const [];
    if (selectedId != null) {
      branches = await repo.branches(selectedId);
      employees = await repo.employees(selectedId);
      permissions = await repo.availablePermissions(selectedId);
    }
    if (!mounted) return;
    setState(() {
      _organizations = approved;
      _organizationId = selectedId;
      _branches = branches;
      _employees = employees;
      _permissions = permissions;
      _loading = false;
    });
  }

  Future<void> _createBranch() async {
    final orgId = _organizationId;
    if (orgId == null || _branchName.text.trim().isEmpty) return;
    await ref
        .read(organizationManagementRepositoryProvider)
        .createBranch(orgId, {
      'branchName': _branchName.text.trim(),
      'cityId': int.tryParse(_branchCityId.text.trim()) ?? 1,
      'addressLine1': _branchAddress.text.trim(),
      'supportsPickup': true,
    });
    _branchName.clear();
    _branchAddress.clear();
    await _load();
  }

  Future<void> _addEmployee() async {
    final orgId = _organizationId;
    if (orgId == null || _employeePhone.text.trim().isEmpty) return;
    final selectedPermissions =
        _permissions.take(2).map((p) => p['code'].toString()).toList();
    await ref
        .read(organizationManagementRepositoryProvider)
        .addEmployee(orgId, {
      'displayName': _employeeName.text.trim().isEmpty
          ? 'موظف جديد'
          : _employeeName.text.trim(),
      'phone': _employeePhone.text.trim(),
      'allBranches': true,
      'permissions': selectedPermissions,
    });
    _employeeName.clear();
    _employeePhone.clear();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'الفروع والموظفون',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(children: [
              const SectionTitle(
                  title: 'إدارة الفروع والموظفين',
                  subtitle:
                      'إضافة الفروع، الإغلاق المؤقت، إضافة الموظفين وربطهم بالصلاحيات ضمن المؤسسة المعتمدة فقط.'),
              const SizedBox(height: AppSpacing.lg),
              if (_organizations.isNotEmpty)
                DropdownButtonFormField<String>(
                  initialValue: _organizationId,
                  decoration: const InputDecoration(labelText: 'المؤسسة'),
                  items: _organizations
                      .map((org) => DropdownMenuItem<String>(
                          value: org['id'].toString(),
                          child: Text(org['display_name']?.toString() ??
                              org['id'].toString())))
                      .toList(),
                  onChanged: (value) async {
                    setState(() => _organizationId = value);
                    await _load();
                  },
                ),
              const SizedBox(height: AppSpacing.xl),
              const SectionTitle(title: 'الفروع'),
              const SizedBox(height: AppSpacing.md),
              ..._branches.map((branch) => Card(
                      child: ListTile(
                    title: Text(branch['branch_name']?.toString() ?? '-'),
                    subtitle: Text(
                        '${branch['city_name'] ?? ''} - ${branch['address_line_1'] ?? ''}\n${branch['temporarily_closed'] == true ? 'مغلق مؤقتًا' : 'نشط'}'),
                    isThreeLine: true,
                    trailing: TextButton(
                        onPressed: () async {
                          await ref
                              .read(organizationManagementRepositoryProvider)
                              .setBranchClosure(
                                  _organizationId!,
                                  branch['id'].toString(),
                                  !(branch['temporarily_closed'] == true),
                                  reason: 'تحديث من لوحة الإدارة');
                          await _load();
                        },
                        child: Text(branch['temporarily_closed'] == true
                            ? 'إعادة فتح'
                            : 'إغلاق')),
                  ))),
              const SizedBox(height: AppSpacing.md),
              AppTextField(controller: _branchName, label: 'اسم الفرع الجديد'),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                  controller: _branchCityId,
                  label: 'رقم المدينة City ID',
                  keyboardType: TextInputType.number),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(controller: _branchAddress, label: 'العنوان'),
              const SizedBox(height: AppSpacing.sm),
              AppButton(text: 'إضافة فرع', onPressed: _createBranch),
              const SizedBox(height: AppSpacing.xl),
              const SectionTitle(title: 'الموظفون'),
              const SizedBox(height: AppSpacing.md),
              ..._employees.map((employee) => Card(
                      child: ListTile(
                    title: Text(employee['display_name']?.toString() ??
                        employee['phone']?.toString() ??
                        '-'),
                    subtitle: Text(
                        '${employee['role']} - ${employee['status']}\n${(employee['permissions'] as List<dynamic>? ?? []).join(', ')}'),
                    isThreeLine: true,
                    trailing: TextButton(
                        onPressed: () async {
                          await ref
                              .read(organizationManagementRepositoryProvider)
                              .updateEmployeeStatus(
                                  _organizationId!,
                                  int.parse(employee['id'].toString()),
                                  employee['status'] == 'SUSPENDED'
                                      ? 'ACTIVE'
                                      : 'SUSPENDED');
                          await _load();
                        },
                        child: Text(employee['status'] == 'SUSPENDED'
                            ? 'تفعيل'
                            : 'إيقاف')),
                  ))),
              const SizedBox(height: AppSpacing.md),
              AppTextField(controller: _employeeName, label: 'اسم الموظف'),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                  controller: _employeePhone,
                  label: 'جوال الموظف',
                  keyboardType: TextInputType.phone),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                  text: 'إضافة موظف بصلاحيات مبدئية', onPressed: _addEmployee),
            ]),
    );
  }
}
