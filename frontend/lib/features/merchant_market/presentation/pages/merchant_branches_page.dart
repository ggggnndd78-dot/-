import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/features/merchant_market/data/merchant_market_repository.dart';
import 'package:ghiyarak/features/merchant_market/data/models/merchant_organization_model.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_bottom_navigation.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_drawer.dart';
import 'package:go_router/go_router.dart';

class MerchantBranchesPage extends ConsumerStatefulWidget {
  const MerchantBranchesPage({super.key});

  @override
  ConsumerState<MerchantBranchesPage> createState() =>
      _MerchantBranchesPageState();
}

class _MerchantBranchesPageState extends ConsumerState<MerchantBranchesPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _search = TextEditingController();
  String _service = 'all';
  late Future<MerchantOrganizationModel> _future;

  @override
  void initState() {
    super.initState();
    _future =
        ref.read(merchantMarketRepositoryProvider).getMerchantOrganization();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _future =
        ref.read(merchantMarketRepositoryProvider).getMerchantOrganization());
    await _future;
  }

  Future<void> _closeBranch(
      MerchantOrganizationModel org, MerchantBranchModel branch) async {
    final ok = await _confirm('إغلاق الفرع مؤقتًا',
        'سيتم جعل جميع أيام العمل مغلقة لهذا الفرع. هل تريد المتابعة؟');
    if (ok != true) return;
    await ref
        .read(merchantMarketRepositoryProvider)
        .closeBranchTemporarily(organizationId: org.id, branchId: branch.id);
    if (!mounted) return;
    _toast('تم إغلاق الفرع مؤقتًا');
    _refresh();
  }

  Future<void> _deleteBranch(
      MerchantOrganizationModel org, MerchantBranchModel branch) async {
    final ok = await _confirm('حذف الفرع',
        'لا ينصح بالحذف إذا كان مرتبطًا بمنتجات أو طلبات. الأفضل إغلاقه مؤقتًا. هل تريد الحذف؟');
    if (ok != true) return;
    try {
      await ref
          .read(merchantMarketRepositoryProvider)
          .deleteBranch(organizationId: org.id, branchId: branch.id);
      if (!mounted) return;
      _toast('تم حذف الفرع');
      _refresh();
    } catch (e) {
      if (!mounted) return;
      _toast(
          'تعذر حذف الفرع لأنه مرتبط ببيانات تشغيلية. استخدم الإغلاق المؤقت.');
    }
  }

  Future<bool?> _confirm(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('تأكيد')),
        ],
      ),
    );
  }

  void _toast(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));

  List<MerchantBranchModel> _filter(List<MerchantBranchModel> branches) {
    final q = _search.text.trim().toLowerCase();
    return branches.where((b) {
      final matchesText = q.isEmpty ||
          [b.name, b.phone ?? '', b.cityName ?? '', b.address ?? '']
              .join(' ')
              .toLowerCase()
              .contains(q);
      final matchesService = _service == 'all' ||
          (_service == 'pickup' && b.supportsPickup) ||
          (_service == 'delivery' && b.supportsDelivery) ||
          (_service == 'mobile' && b.supportsMobileService) ||
          (_service == 'installation' && b.supportsInstallation);
      return matchesText && matchesService;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF5F7FA),
        drawer:
            const MerchantDrawer(currentTab: MerchantNavigationTab.settings),
        bottomNavigationBar: const MerchantBottomNavigation(
            currentTab: MerchantNavigationTab.settings),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: const Color(0xFFFF6500),
          foregroundColor: Colors.white,
          onPressed: () => context.go(RouteNames.createMerchantBranch),
          icon: const Icon(Icons.add_rounded),
          label: const Text('فرع جديد'),
        ),
        body: FutureBuilder<MerchantOrganizationModel>(
          future: _future,
          builder: (context, snapshot) {
            final org = snapshot.data;
            return Column(
              children: [
                _Header(onMenu: () => _scaffoldKey.currentState?.openDrawer()),
                Expanded(
                  child: snapshot.connectionState != ConnectionState.done
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFFFF6500)))
                      : snapshot.hasError
                          ? _ErrorState(
                              message: snapshot.error.toString(),
                              onRetry: _refresh)
                          : RefreshIndicator(
                              onRefresh: _refresh,
                              child: ListView(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 16, 16, 110),
                                children: [
                                  _Stats(branches: org!.branches),
                                  const SizedBox(height: 14),
                                  _SearchAndFilter(
                                    controller: _search,
                                    service: _service,
                                    onChanged: () => setState(() {}),
                                    onServiceChanged: (v) =>
                                        setState(() => _service = v),
                                  ),
                                  const SizedBox(height: 14),
                                  if (_filter(org.branches).isEmpty)
                                    const _EmptyState()
                                  else
                                    for (final branch
                                        in _filter(org.branches)) ...[
                                      _BranchCard(
                                        branch: branch,
                                        onDetails: () => context.go(
                                            RouteNames.merchantBranchDetails(
                                                branch.id)),
                                        onEdit: () => context.go(
                                            RouteNames.editMerchantBranch(
                                                branch.id)),
                                        onClose: () =>
                                            _closeBranch(org, branch),
                                        onDelete: () =>
                                            _deleteBranch(org, branch),
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                ],
                              ),
                            ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onMenu});
  final VoidCallback onMenu;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.paddingOf(context).top + 10, 20, 28),
      decoration: const BoxDecoration(
        gradient:
            LinearGradient(colors: [Color(0xFF061A2D), Color(0xFF0E3659)]),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Row(children: [
            IconButton(
                onPressed: onMenu,
                icon: const Icon(Icons.menu_rounded,
                    color: Colors.white, size: 30)),
            const Spacer(),
            Image.asset('assets/images/ghiyarak_logo_transparent.png',
                width: 126, height: 58, fit: BoxFit.contain),
            const Spacer(),
            IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none_rounded,
                    color: Colors.white, size: 30)),
          ]),
          const Text('إدارة الفروع',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Text('إضافة، تعديل، إغلاق، ومتابعة أداء فروع المتجر',
              style: TextStyle(color: Color(0xFFD6E2EC))),
        ],
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.branches});
  final List<MerchantBranchModel> branches;
  @override
  Widget build(BuildContext context) {
    final open = branches.where((b) => b.isOpenNow).length;
    final pickup = branches.where((b) => b.supportsPickup).length;
    final delivery = branches.where((b) => b.supportsDelivery).length;
    return Row(children: [
      Expanded(
          child: _StatCard(
              label: 'الفروع',
              value: '${branches.length}',
              icon: Icons.storefront_outlined)),
      const SizedBox(width: 8),
      Expanded(
          child: _StatCard(
              label: 'مفتوحة الآن',
              value: '$open',
              icon: Icons.lock_open_rounded)),
      const SizedBox(width: 8),
      Expanded(
          child: _StatCard(
              label: 'استلام/توصيل',
              value: '$pickup/$delivery',
              icon: Icons.delivery_dining_rounded)),
    ]);
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(
      {required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: const Color(0xFFFF6500)),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(
                color: Color(0xFF092B4D),
                fontSize: 20,
                fontWeight: FontWeight.w900)),
        Text(label,
            style: const TextStyle(color: Color(0xFF718092), fontSize: 12)),
      ]),
    );
  }
}

class _SearchAndFilter extends StatelessWidget {
  const _SearchAndFilter(
      {required this.controller,
      required this.service,
      required this.onChanged,
      required this.onServiceChanged});
  final TextEditingController controller;
  final String service;
  final VoidCallback onChanged;
  final ValueChanged<String> onServiceChanged;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration,
      child: Column(children: [
        TextField(
          controller: controller,
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            hintText: 'ابحث باسم الفرع، الهاتف، المدينة أو العنوان...',
            prefixIcon: const Icon(Icons.search_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
          ),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: service,
          decoration: InputDecoration(
            labelText: 'فلترة حسب الخدمة',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('كل الخدمات')),
            DropdownMenuItem(value: 'pickup', child: Text('يدعم الاستلام')),
            DropdownMenuItem(value: 'delivery', child: Text('يدعم التوصيل')),
            DropdownMenuItem(
                value: 'installation', child: Text('يدعم التركيب')),
            DropdownMenuItem(value: 'mobile', child: Text('خدمة متنقلة')),
          ],
          onChanged: (v) => onServiceChanged(v ?? 'all'),
        ),
      ]),
    );
  }
}

class _BranchCard extends StatelessWidget {
  const _BranchCard(
      {required this.branch,
      required this.onDetails,
      required this.onEdit,
      required this.onClose,
      required this.onDelete});
  final MerchantBranchModel branch;
  final VoidCallback onDetails;
  final VoidCallback onEdit;
  final VoidCallback onClose;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
                color: const Color(0xFFEAF2FB),
                borderRadius: BorderRadius.circular(18)),
            child: const Icon(Icons.storefront_rounded,
                color: Color(0xFF082B51), size: 36),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(children: [
                  Expanded(
                      child: Text(branch.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF092B4D)))),
                  _Pill(
                      label: branch.isOpenNow ? 'مفتوح' : 'مغلق',
                      color: branch.isOpenNow
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFE11D48)),
                ]),
                if (branch.isHeadOffice)
                  const Padding(
                      padding: EdgeInsets.only(top: 5),
                      child: _Pill(
                          label: 'الفرع الرئيسي', color: Color(0xFF1D63C8))),
                const SizedBox(height: 8),
                _Info(
                    icon: Icons.location_on_outlined,
                    text: branch.locationLabel.isEmpty
                        ? 'العنوان غير محدد'
                        : branch.locationLabel),
                const SizedBox(height: 5),
                _Info(
                    icon: Icons.phone_outlined,
                    text: branch.phone ?? 'لا يوجد رقم هاتف'),
                const SizedBox(height: 5),
                _Info(
                    icon: Icons.miscellaneous_services_outlined,
                    text: branch.servicesLabel),
              ])),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
              child: _MiniMetric(label: 'منتجات', value: branch.productsCount)),
          const SizedBox(width: 8),
          Expanded(
              child: _MiniMetric(label: 'طلبات', value: branch.ordersCount)),
          const SizedBox(width: 8),
          Expanded(
              child:
                  _MiniMetric(label: 'مخزون', value: branch.inventoryQuantity)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
              child: OutlinedButton.icon(
                  onPressed: onDetails,
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('التفاصيل'))),
          const SizedBox(width: 8),
          Expanded(
              child: FilledButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('تعديل'),
                  style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF082B51)))),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'close') onClose();
              if (v == 'delete') onDelete();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'close', child: Text('إغلاق مؤقت')),
              PopupMenuItem(value: 'delete', child: Text('حذف الفرع')),
            ],
          ),
        ]),
      ]),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value});
  final String label;
  final int value;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          Text('$value',
              style: const TextStyle(
                  fontWeight: FontWeight.w900, color: Color(0xFF092B4D))),
          Text(label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF718092)))
        ]),
      );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
            color: color.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(999)),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w800)),
      );
}

class _Info extends StatelessWidget {
  const _Info({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 17, color: const Color(0xFF718092)),
        const SizedBox(width: 5),
        Expanded(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF607080))))
      ]);
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: _cardDecoration,
        child: const Column(children: [
          Icon(Icons.storefront_outlined, size: 56, color: Color(0xFFFF6500)),
          SizedBox(height: 10),
          Text('لا توجد فروع مطابقة',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          Text('أضف فرعًا جديدًا أو غيّر معايير البحث.')
        ]),
      );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;
  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline_rounded,
                size: 50, color: Color(0xFFE11D48)),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
                onPressed: onRetry, child: const Text('إعادة المحاولة'))
          ])));
}

final _cardDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(18),
  border: Border.all(color: const Color(0xFFE0E7EF)),
  boxShadow: const [
    BoxShadow(color: Color(0x0F051E35), blurRadius: 14, offset: Offset(0, 8))
  ],
);
