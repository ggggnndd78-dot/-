import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/core/navigation/app_navigation.dart';
import 'package:ghiyarak/features/merchant_market/data/merchant_market_repository.dart';
import 'package:ghiyarak/features/merchant_market/presentation/pages/merchant_branch_edit_page.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_bottom_navigation.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_drawer.dart';

enum _BranchFilter { all, active, inactive }

class MerchantBranchesPage extends ConsumerStatefulWidget {
  const MerchantBranchesPage({super.key});

  @override
  ConsumerState<MerchantBranchesPage> createState() =>
      _MerchantBranchesPageState();
}

class _MerchantBranchesPageState extends ConsumerState<MerchantBranchesPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchController = TextEditingController();
  late Future<List<MerchantBranchManagementItem>> _future;
  _BranchFilter _filter = _BranchFilter.all;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = _loadBranches();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<MerchantBranchManagementItem>> _loadBranches() {
    return ref
        .read(merchantMarketRepositoryProvider)
        .getMerchantBranchManagement();
  }

  void _retry() {
    setState(() {
      _future = _loadBranches();
    });
  }

  List<MerchantBranchManagementItem> _filtered(
    List<MerchantBranchManagementItem> branches,
  ) {
    return branches.where((branch) {
      final matchesStatus = switch (_filter) {
        _BranchFilter.all => true,
        _BranchFilter.active => branch.isActive,
        _BranchFilter.inactive => !branch.isActive,
      };
      final matchesSearch =
          _query.isEmpty || branch.searchableText.contains(_query);
      return matchesStatus && matchesSearch;
    }).toList();
  }

  Future<void> _openLocation(MerchantBranchManagementItem branch) async {
    Uri? uri;
    if (branch.latitude != null && branch.longitude != null) {
      uri = Uri.https('www.google.com', '/maps/search/', {
        'api': '1',
        'query': '${branch.latitude},${branch.longitude}',
      });
    } else if ((branch.address ?? '').trim().isNotEmpty) {
      uri = Uri.https('www.google.com', '/maps/search/', {
        'api': '1',
        'query': branch.address!,
      });
    }

    if (uri == null) {
      _showNoLocation();
      return;
    }

    await Clipboard.setData(ClipboardData(text: uri.toString()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ رابط الموقع على الخريطة.')),
    );
  }

  void _showNoLocation() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('لا يوجد موقع محدد لهذا الفرع.')),
    );
  }

  Future<void> _showBranchDetails(MerchantBranchManagementItem branch) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _BranchDetailsSheet(
        branch: branch,
        onLocation: () {
          Navigator.of(sheetContext).pop();
          _openLocation(branch);
        },
        onEdit: () async {
          Navigator.of(sheetContext).pop();
          final updated = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => MerchantBranchEditPage(branch: branch),
            ),
          );
          if (updated == true && mounted) _retry();
        },
        onCopy: (value, message) {
          Clipboard.setData(ClipboardData(text: value));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF5F7FA),
        drawer: const MerchantDrawer(
          currentTab: MerchantNavigationTab.settings,
        ),
        bottomNavigationBar: const MerchantBottomNavigation(
          currentTab: MerchantNavigationTab.settings,
        ),
        body: Column(
          children: [
            _BranchesHeader(
              onMenu: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            Expanded(
              child: FutureBuilder<List<MerchantBranchManagementItem>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const _LoadingState();
                  }
                  if (snapshot.hasError) {
                    return _ErrorState(onRetry: _retry);
                  }

                  final branches =
                      snapshot.data ?? const <MerchantBranchManagementItem>[];
                  final visible = _filtered(branches);

                  return RefreshIndicator(
                    color: const Color(0xFFFF7900),
                    onRefresh: () async => _retry(),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                      children: [
                        _SummaryGrid(branches: branches),
                        const SizedBox(height: 14),
                        FilledButton.icon(
                          onPressed: () =>
                              context.pushPath(RouteNames.createMerchantBranch),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('إضافة فرع'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFFF7900),
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _SearchBox(controller: _searchController),
                        const SizedBox(height: 12),
                        _FilterBar(
                          value: _filter,
                          onChanged: (value) => setState(() => _filter = value),
                        ),
                        const SizedBox(height: 14),
                        if (branches.isEmpty)
                          const _EmptyState()
                        else if (visible.isEmpty)
                          const _NoResultsState()
                        else
                          for (final branch in visible) ...[
                            _BranchCard(
                              branch: branch,
                              onDetails: () => _showBranchDetails(branch),
                              onLocation: () => _openLocation(branch),
                            ),
                            const SizedBox(height: 12),
                          ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BranchesHeader extends StatelessWidget {
  const _BranchesHeader({required this.onMenu});

  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 12,
        20,
        28,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF061A2D), Color(0xFF0E3659)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onMenu,
                icon: const Icon(Icons.menu_rounded),
                color: Colors.white,
                tooltip: 'القائمة',
              ),
              const Spacer(),
              Image.asset(
                'assets/images/ghiyarak_logo_transparent.png',
                width: 120,
                height: 56,
                fit: BoxFit.contain,
              ),
              const Spacer(),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'إدارة الفروع',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'إدارة فروع متجرك',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: Color(0xFFD7E4F0),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.branches});

  final List<MerchantBranchManagementItem> branches;

  @override
  Widget build(BuildContext context) {
    final active = branches.where((branch) => branch.isActive).length;
    final inactive = branches.length - active;
    final main = branches.where((branch) => branch.isMain).length;
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.85,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _SummaryCard(
          label: 'إجمالي الفروع',
          value: '${branches.length}',
          icon: Icons.store_outlined,
        ),
        _SummaryCard(
          label: 'الفروع النشطة',
          value: '$active',
          icon: Icons.check_circle_outline,
        ),
        _SummaryCard(
          label: 'الفروع غير النشطة',
          value: '$inactive',
          icon: Icons.pause_circle_outline,
        ),
        _SummaryCard(
          label: 'الفرع الرئيسي',
          value: '$main',
          icon: Icons.star_outline_rounded,
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration,
      child: Row(
        children: [
          CircleAvatar(
            radius: 21,
            backgroundColor: const Color(0xFFFF7900).withValues(alpha: .12),
            child: Icon(icon, color: const Color(0xFFFF7900)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF0D2238),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF7A8A9A),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'ابحث باسم الفرع أو العنوان أو الهاتف',
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE4EAF0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE4EAF0)),
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.value, required this.onChanged});

  final _BranchFilter value;
  final ValueChanged<_BranchFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    const items = {
      _BranchFilter.all: 'الكل',
      _BranchFilter.active: 'نشط',
      _BranchFilter.inactive: 'غير نشط',
    };
    return DropdownButtonFormField<_BranchFilter>(
      initialValue: value,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'تصفية الفروع',
        prefixIcon: Icon(Icons.filter_list_rounded),
      ),
      items: items.entries
          .map((e) => DropdownMenuItem<_BranchFilter>(
                value: e.key,
                child: Text(e.value),
              ))
          .toList(),
      onChanged: (next) {
        if (next != null) onChanged(next);
      },
    );
  }
}

class _BranchCard extends StatelessWidget {
  const _BranchCard({
    required this.branch,
    required this.onDetails,
    required this.onLocation,
  });

  final MerchantBranchManagementItem branch;
  final VoidCallback onDetails;
  final VoidCallback onLocation;

  @override
  Widget build(BuildContext context) {
    final location = [
      branch.cityName,
      branch.districtName,
      branch.areaName,
    ].whereType<String>().join(' - ');
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onDetails,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      branch.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF0D2238),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (branch.isMain) const SizedBox(width: 8),
                  if (branch.isMain) const _Badge(label: 'الفرع الرئيسي'),
                ],
              ),
              const SizedBox(height: 10),
              _StatusBadge(isActive: branch.isActive),
              if (location.isNotEmpty) ...[
                const SizedBox(height: 12),
                _InfoLine(icon: Icons.location_city_outlined, text: location),
              ],
              if ((branch.address ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                _InfoLine(
                  icon: Icons.location_on_outlined,
                  text: branch.address!,
                ),
              ],
              if ((branch.phone ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                _InfoLine(icon: Icons.call_outlined, text: branch.phone!),
              ],
              if ((branch.managerName ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                _InfoLine(
                  icon: Icons.person_outline_rounded,
                  text: branch.managerName!,
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onDetails,
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('عرض التفاصيل'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onLocation,
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('الموقع على الخريطة'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BranchDetailsSheet extends StatelessWidget {
  const _BranchDetailsSheet({
    required this.branch,
    required this.onLocation,
    required this.onEdit,
    required this.onCopy,
  });

  final MerchantBranchManagementItem branch;
  final VoidCallback onLocation;
  final VoidCallback onEdit;
  final void Function(String value, String message) onCopy;

  @override
  Widget build(BuildContext context) {
    final location = [
      branch.cityName,
      branch.districtName,
      branch.areaName,
    ].whereType<String>().join(' - ');
    return DraggableScrollableSheet(
      initialChildSize: .78,
      minChildSize: .45,
      maxChildSize: .92,
      builder: (context, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF5F7FA),
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC8D4E0),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'تفاصيل الفرع',
                      style: TextStyle(
                        color: Color(0xFF0D2238),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: _cardDecoration,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            branch.name,
                            style: const TextStyle(
                              color: Color(0xFF0D2238),
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        _StatusBadge(isActive: branch.isActive),
                      ],
                    ),
                    if (branch.isMain) ...[
                      const SizedBox(height: 10),
                      const _Badge(label: 'الفرع الرئيسي'),
                    ],
                    const SizedBox(height: 16),
                    _DetailRow(label: 'اسم الفرع', value: branch.name),
                    _DetailRow(
                      label: 'هل هو الفرع الرئيسي',
                      value: branch.isMain ? 'نعم' : 'لا',
                    ),
                    _DetailRow(
                      label: 'الحالة',
                      value: branch.isActive ? 'نشط' : 'غير نشط',
                    ),
                    if ((branch.cityName ?? '').isNotEmpty)
                      _DetailRow(label: 'المدينة', value: branch.cityName!),
                    if ((branch.districtName ?? '').isNotEmpty)
                      _DetailRow(
                        label: 'المنطقة / الحي',
                        value: branch.districtName!,
                      ),
                    if ((branch.areaName ?? '').isNotEmpty)
                      _DetailRow(
                        label: 'الحي',
                        value: branch.areaName!,
                      ),
                    if (location.isNotEmpty)
                      _DetailRow(label: 'الموقع الإداري', value: location),
                    if ((branch.address ?? '').isNotEmpty)
                      _DetailRow(
                        label: 'العنوان',
                        value: branch.address!,
                        trailing: IconButton(
                          tooltip: 'نسخ العنوان',
                          onPressed: () => onCopy(
                            branch.address!,
                            'تم نسخ العنوان',
                          ),
                          icon: const Icon(Icons.copy_rounded),
                        ),
                      ),
                    if ((branch.phone ?? '').isNotEmpty)
                      _DetailRow(
                        label: 'رقم الهاتف',
                        value: branch.phone!,
                        trailing: IconButton(
                          tooltip: 'نسخ رقم الهاتف',
                          onPressed: () => onCopy(
                            branch.phone!,
                            'تم نسخ رقم الهاتف',
                          ),
                          icon: const Icon(Icons.copy_rounded),
                        ),
                      ),
                    if (branch.latitude != null)
                      _DetailRow(
                        label: 'خط العرض latitude',
                        value: branch.latitude!.toString(),
                      ),
                    if (branch.longitude != null)
                      _DetailRow(
                        label: 'خط الطول longitude',
                        value: branch.longitude!.toString(),
                      ),
                    if ((branch.createdAt ?? '').isNotEmpty)
                      _DetailRow(
                        label: 'تاريخ الإنشاء',
                        value: branch.createdAt!,
                      ),
                    if ((branch.updatedAt ?? '').isNotEmpty)
                      _DetailRow(
                        label: 'تاريخ آخر تحديث',
                        value: branch.updatedAt!,
                      ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onLocation,
                            icon: const Icon(Icons.map_outlined),
                            label: const Text('الموقع على الخريطة'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: onEdit,
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('تعديل'),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFFF7900),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.trailing,
  });

  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF7A8A9A),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF0D2238),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFF7900).withValues(alpha: .12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFFF7900),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? const Color(0xFFFF7900) : const Color(0xFF7A8A9A);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        isActive ? 'نشط' : 'غير نشط',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF718092)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF34475A),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: Color(0xFFFF7900)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 46),
      decoration: _cardDecoration,
      child: const Column(
        children: [
          Icon(Icons.store_outlined, size: 58, color: Color(0xFF91A0AF)),
          SizedBox(height: 14),
          Text(
            'لا توجد فروع بعد',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF0D2238),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'ابدأ بإضافة أول فرع لمتجرك.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF7A8A9A),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoResultsState extends StatelessWidget {
  const _NoResultsState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Text(
          'لا توجد نتائج مطابقة.',
          style: TextStyle(
            color: Color(0xFF7A8A9A),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 58,
              color: Color(0xFF91A0AF),
            ),
            const SizedBox(height: 14),
            const Text(
              'تعذر تحميل الفروع.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF0D2238),
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF7900),
                foregroundColor: Colors.white,
              ),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}

final _cardDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(14),
  border: Border.all(color: const Color(0xFFE4EAF0)),
  boxShadow: const [
    BoxShadow(
      color: Color(0x0F061A2D),
      blurRadius: 14,
      offset: Offset(0, 6),
    ),
  ],
);
