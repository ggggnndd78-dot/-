import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/features/merchant_market/data/merchant_market_repository.dart';
import 'package:ghiyarak/features/merchant_market/data/models/merchant_team_member_model.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_management_scaffold.dart';
import 'package:go_router/go_router.dart';

class MerchantTeamPage extends ConsumerStatefulWidget {
  const MerchantTeamPage({super.key});

  @override
  ConsumerState<MerchantTeamPage> createState() => _MerchantTeamPageState();
}

class _MerchantTeamPageState extends ConsumerState<MerchantTeamPage> {
  late Future<List<MerchantTeamMemberModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(merchantMarketRepositoryProvider).getMerchantTeam();
  }

  void _reload() => setState(() {
        _future = ref.read(merchantMarketRepositoryProvider).getMerchantTeam();
      });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MerchantTeamMemberModel>>(
      future: _future,
      builder: (context, snapshot) {
        final members = snapshot.data ?? const <MerchantTeamMemberModel>[];
        final active = members.where((member) => member.isActive).length;
        final suspended = members.where((member) => member.isSuspended).length;
        final withPermissions =
            members.where((member) => member.permissions.isNotEmpty).length;
        return MerchantManagementScaffold(
          title: 'الفريق والصلاحيات',
          subtitle: 'مركز إدارة الموظفين والأدوار وصلاحيات الوصول داخل المتجر',
          onRefresh: () async => _reload(),
          children: [
            if (snapshot.connectionState != ConnectionState.done &&
                members.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (snapshot.hasError)
              MerchantStateCard(
                icon: Icons.error_outline,
                title: 'تعذر تحميل الفريق',
                message: snapshot.error.toString(),
                actionLabel: 'إعادة المحاولة',
                onAction: _reload,
              )
            else ...[
              Row(
                children: [
                  Expanded(
                      child: MerchantMetricTile(
                          icon: Icons.groups_2_outlined,
                          label: 'إجمالي الأعضاء',
                          value: '${members.length}')),
                  const SizedBox(width: 10),
                  Expanded(
                      child: MerchantMetricTile(
                          icon: Icons.verified_user_outlined,
                          label: 'نشطون',
                          value: '$active')),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                      child: MerchantMetricTile(
                          icon: Icons.block_outlined,
                          label: 'موقوفون',
                          value: '$suspended')),
                  const SizedBox(width: 10),
                  Expanded(
                      child: MerchantMetricTile(
                          icon: Icons.key_outlined,
                          label: 'لديهم صلاحيات',
                          value: '$withPermissions')),
                ],
              ),
              const SizedBox(height: 16),
              _ActionCard(
                icon: Icons.badge_outlined,
                title: 'الموظفون والدعوات',
                subtitle:
                    'دعوة موظف، تعديل دوره، إيقافه أو حذفه، وتحديد فروعه وصلاحياته.',
                onTap: () => context.go(RouteNames.merchantEmployees),
              ),
              const SizedBox(height: 12),
              _ActionCard(
                icon: Icons.admin_panel_settings_outlined,
                title: 'الأدوار والصلاحيات',
                subtitle:
                    'إنشاء أدوار مثل مدير فرع أو مسؤول مخزون وربطها بالصلاحيات.',
                onTap: () => context.go(RouteNames.merchantRolesPermissions),
              ),
              const SizedBox(height: 12),
              _ActionCard(
                icon: Icons.manage_history_outlined,
                title: 'سجل النشاط',
                subtitle: 'مراجعة العمليات الحساسة التي نفذها فريق المتجر.',
                onTap: () => context.go(RouteNames.merchantAuditLog),
              ),
              const SizedBox(height: 16),
              const Text('آخر أعضاء الفريق',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF082B51))),
              const SizedBox(height: 10),
              if (members.isEmpty)
                const MerchantStateCard(
                  icon: Icons.groups_outlined,
                  title: 'لا يوجد أعضاء بعد',
                  message:
                      'ابدأ بدعوة الموظفين وتوزيع صلاحياتهم حسب المسؤوليات.',
                )
              else
                ...members.take(5).map((member) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: MerchantPanel(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                              child: Text(member.name.isEmpty
                                  ? 'م'
                                  : member.name.trim().substring(0, 1))),
                          title: Text(member.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w900)),
                          subtitle: Text(
                              '${_roleLabel(member.role)}\n${member.contactLabel}'),
                          isThreeLine: true,
                          trailing:
                              Chip(label: Text(_statusLabel(member.status))),
                        ),
                      ),
                    )),
            ],
          ],
        );
      },
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MerchantPanel(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: const Color(0xFFFF7900), size: 32),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        onTap: onTap,
      ),
    );
  }
}

String _statusLabel(String status) {
  return switch (status.toUpperCase()) {
    'ACTIVE' => 'نشط',
    'SUSPENDED' => 'موقوف',
    'PENDING' => 'بانتظار',
    _ => status.isEmpty ? 'غير محدد' : status,
  };
}

String _roleLabel(String role) {
  return switch (role.toLowerCase()) {
    'owner' => 'مالك المتجر',
    'admin' => 'مدير عام',
    'manager' => 'مدير',
    'branch_manager' => 'مدير فرع',
    'inventory_manager' => 'مسؤول مخزون',
    'orders_agent' => 'موظف طلبات',
    'suspended' => 'موقوف',
    _ => role,
  };
}
