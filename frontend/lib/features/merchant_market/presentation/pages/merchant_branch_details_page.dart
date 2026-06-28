import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/features/merchant_market/data/merchant_market_repository.dart';
import 'package:ghiyarak/features/merchant_market/data/models/merchant_organization_model.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_bottom_navigation.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_drawer.dart';
import 'package:go_router/go_router.dart';

class MerchantBranchDetailsPage extends ConsumerStatefulWidget {
  const MerchantBranchDetailsPage({super.key, required this.branchId});
  final String branchId;

  @override
  ConsumerState<MerchantBranchDetailsPage> createState() =>
      _MerchantBranchDetailsPageState();
}

class _MerchantBranchDetailsPageState
    extends ConsumerState<MerchantBranchDetailsPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late Future<_BranchDetailsData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_BranchDetailsData> _load() async {
    final repo = ref.read(merchantMarketRepositoryProvider);
    final org = await repo.getMerchantOrganization();
    MerchantBranchModel? branch;
    for (final item in org.branches) {
      if (item.id == widget.branchId) branch = item;
    }
    branch ??=
        await repo.getBranch(organizationId: org.id, branchId: widget.branchId);
    return _BranchDetailsData(org: org, branch: branch);
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
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
        body: FutureBuilder<_BranchDetailsData>(
          future: _future,
          builder: (context, snapshot) {
            final data = snapshot.data;
            return Column(children: [
              _Header(
                  title: data?.branch.name ?? 'تفاصيل الفرع',
                  onMenu: () => _scaffoldKey.currentState?.openDrawer()),
              Expanded(
                child: snapshot.connectionState != ConnectionState.done
                    ? const Center(
                        child:
                            CircularProgressIndicator(color: Color(0xFFFF6500)))
                    : snapshot.hasError
                        ? Center(
                            child:
                                Text('تعذر تحميل التفاصيل: ${snapshot.error}'))
                        : RefreshIndicator(
                            onRefresh: _refresh,
                            child: ListView(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 16, 16, 100),
                                children: [
                                  _SummaryCard(branch: data!.branch),
                                  const SizedBox(height: 14),
                                  _Section(
                                      title: 'بيانات التواصل والموقع',
                                      icon: Icons.location_on_outlined,
                                      children: [
                                        _InfoRow(
                                            label: 'المدينة',
                                            value: data.branch.cityName ?? '-'),
                                        _InfoRow(
                                            label: 'الحي/المنطقة',
                                            value: [
                                              data.branch.districtName,
                                              data.branch.areaName
                                            ]
                                                    .where((e) =>
                                                        (e ?? '').isNotEmpty)
                                                    .join('، ')
                                                    .isEmpty
                                                ? '-'
                                                : [
                                                    data.branch.districtName,
                                                    data.branch.areaName
                                                  ]
                                                    .where((e) =>
                                                        (e ?? '').isNotEmpty)
                                                    .join('، ')),
                                        _InfoRow(
                                            label: 'العنوان',
                                            value: data.branch.address ?? '-'),
                                        _InfoRow(
                                            label: 'الهاتف',
                                            value: data.branch.phone ?? '-'),
                                        _InfoRow(
                                            label: 'البريد',
                                            value: data.branch.email ?? '-'),
                                        _InfoRow(
                                            label: 'الإحداثيات',
                                            value: data.branch.latitude == null
                                                ? '-'
                                                : '${data.branch.latitude}, ${data.branch.longitude}'),
                                      ]),
                                  const SizedBox(height: 14),
                                  _Section(
                                      title: 'الخدمات',
                                      icon:
                                          Icons.miscellaneous_services_outlined,
                                      children: [
                                        _ServiceRow(
                                            label: 'الاستلام من الفرع',
                                            enabled:
                                                data.branch.supportsPickup),
                                        _ServiceRow(
                                            label: 'التوصيل',
                                            enabled:
                                                data.branch.supportsDelivery),
                                        _ServiceRow(
                                            label: 'التركيب',
                                            enabled: data
                                                .branch.supportsInstallation),
                                        _ServiceRow(
                                            label: 'الخدمة المتنقلة',
                                            enabled: data
                                                .branch.supportsMobileService),
                                      ]),
                                  const SizedBox(height: 14),
                                  _Section(
                                      title: 'أوقات العمل',
                                      icon: Icons.access_time_rounded,
                                      children: [
                                        if (data.branch.businessHours.isEmpty)
                                          const Text(
                                              'لم يتم تحديد أوقات العمل بعد.')
                                        else
                                          for (final hour
                                              in data.branch.businessHours)
                                            _BusinessHourLine(hour: hour),
                                      ]),
                                  const SizedBox(height: 14),
                                  _Section(
                                      title: 'مؤشرات الفرع',
                                      icon: Icons.analytics_outlined,
                                      children: [
                                        _InfoRow(
                                            label: 'عدد المنتجات',
                                            value:
                                                '${data.branch.productsCount}'),
                                        _InfoRow(
                                            label: 'عدد الطلبات',
                                            value:
                                                '${data.branch.ordersCount}'),
                                        _InfoRow(
                                            label: 'كمية المخزون',
                                            value:
                                                '${data.branch.inventoryQuantity}'),
                                        _InfoRow(
                                            label: 'منخفض المخزون',
                                            value:
                                                '${data.branch.lowStockCount}'),
                                      ]),
                                  const SizedBox(height: 16),
                                  FilledButton.icon(
                                    onPressed: () => context.go(
                                        RouteNames.editMerchantBranch(
                                            data.branch.id)),
                                    icon: const Icon(Icons.edit_outlined),
                                    label: const Text('تعديل الفرع'),
                                    style: FilledButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFFFF6500),
                                        minimumSize: const Size.fromHeight(52)),
                                  ),
                                ]),
                          ),
              ),
            ]);
          },
        ),
      ),
    );
  }
}

class _BranchDetailsData {
  const _BranchDetailsData({required this.org, required this.branch});
  final MerchantOrganizationModel org;
  final MerchantBranchModel branch;
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onMenu});
  final String title;
  final VoidCallback onMenu;
  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.fromLTRB(
            20, MediaQuery.paddingOf(context).top + 10, 20, 28),
        decoration: const BoxDecoration(
            gradient:
                LinearGradient(colors: [Color(0xFF061A2D), Color(0xFF0E3659)]),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24))),
        child: Column(children: [
          Row(children: [
            IconButton(
                onPressed: onMenu,
                icon: const Icon(Icons.menu_rounded,
                    color: Colors.white, size: 30)),
            const Spacer(),
            Image.asset('assets/images/ghiyarak_logo_transparent.png',
                width: 126, height: 58),
            const Spacer(),
            IconButton(
                onPressed: () => context.go(RouteNames.merchantBranches),
                icon: const Icon(Icons.arrow_forward_rounded,
                    color: Colors.white, size: 30))
          ]),
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Text('تفاصيل تشغيل الفرع ومؤشراته',
              style: TextStyle(color: Color(0xFFD6E2EC))),
        ]),
      );
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.branch});
  final MerchantBranchModel branch;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                    color: const Color(0xFFEAF2FB),
                    borderRadius: BorderRadius.circular(18)),
                child: const Icon(Icons.storefront_rounded,
                    size: 36, color: Color(0xFF082B51))),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(branch.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 21,
                          color: Color(0xFF092B4D))),
                  const SizedBox(height: 5),
                  Text(
                      branch.locationLabel.isEmpty
                          ? 'العنوان غير محدد'
                          : branch.locationLabel,
                      style: const TextStyle(color: Color(0xFF607080))),
                ])),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
                child: _Badge(
                    label: branch.isOpenNow ? 'مفتوح الآن' : 'مغلق الآن',
                    color: branch.isOpenNow
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFE11D48))),
            const SizedBox(width: 8),
            if (branch.isHeadOffice)
              const Expanded(
                  child: _Badge(label: 'فرع رئيسي', color: Color(0xFF1D63C8))),
          ]),
        ]),
      );
}

class _Section extends StatelessWidget {
  const _Section(
      {required this.title, required this.icon, required this.children});
  final String title;
  final IconData icon;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Icon(icon, color: const Color(0xFF082B51)),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF092B4D)))
          ]),
          const SizedBox(height: 12),
          ...children
        ]),
      );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(
                    color: Color(0xFF718092), fontWeight: FontWeight.w700))),
        Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: Color(0xFF092B4D), fontWeight: FontWeight.w800)))
      ]));
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({required this.label, required this.enabled});
  final String label;
  final bool enabled;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Icon(enabled ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: enabled ? const Color(0xFF16A34A) : const Color(0xFFE11D48)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w800))
      ]));
}

class _BusinessHourLine extends StatelessWidget {
  const _BusinessHourLine({required this.hour});
  final MerchantBusinessHourModel hour;
  static const days = [
    'الأحد',
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت'
  ];
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        SizedBox(
            width: 85,
            child: Text(days[hour.dayOfWeek.clamp(0, 6).toInt()],
                style: const TextStyle(fontWeight: FontWeight.w900))),
        Expanded(
            child: Text(
                hour.isClosed
                    ? 'مغلق'
                    : '${hour.openTime ?? '--'} - ${hour.closeTime ?? '--'}',
                style: TextStyle(
                    color: hour.isClosed
                        ? const Color(0xFFE11D48)
                        : const Color(0xFF092B4D),
                    fontWeight: FontWeight.w800)))
      ]));
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
      decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(12)),
      child: Center(
          child: Text(label,
              style: TextStyle(color: color, fontWeight: FontWeight.w900))));
}

final _cardDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(18),
  border: Border.all(color: const Color(0xFFE0E7EF)),
  boxShadow: const [
    BoxShadow(color: Color(0x0F051E35), blurRadius: 14, offset: Offset(0, 8))
  ],
);
