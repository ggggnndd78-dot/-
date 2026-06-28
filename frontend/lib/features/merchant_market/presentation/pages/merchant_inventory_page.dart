import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/features/merchant_market/data/merchant_market_repository.dart';
import 'package:ghiyarak/features/merchant_market/data/models/merchant_inventory_model.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_bottom_navigation.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_drawer.dart';

class MerchantInventoryPage extends ConsumerStatefulWidget {
  const MerchantInventoryPage({super.key});

  @override
  ConsumerState<MerchantInventoryPage> createState() =>
      _MerchantInventoryPageState();
}

class _MerchantInventoryPageState extends ConsumerState<MerchantInventoryPage>
    with SingleTickerProviderStateMixin {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _search = TextEditingController();
  String _branch = 'all';
  String _status = 'all';
  late Future<MerchantInventoryModel> _future;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _future = _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<MerchantInventoryModel> _load() {
    return ref.read(merchantMarketRepositoryProvider).getMerchantInventory(
          branchId: _branch,
          status: _status,
          query: _search.text.trim(),
        );
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  void _reload() => setState(() => _future = _load());

  Future<void> _addMovement(
      MerchantInventoryItem item, InventoryAction action) async {
    final input = await showDialog<_MovementInput>(
      context: context,
      builder: (context) => _MovementDialog(item: item, action: action),
    );
    if (input == null) return;
    try {
      await ref.read(merchantMarketRepositoryProvider).updateInventoryQuantity(
            listingId: item.listingNumericId ?? item.listingId ?? item.id,
            inventoryId: item.id,
            type: action.apiType,
            quantity: input.quantity,
            reorderLevel: input.reorderLevel,
            note: input.note,
          );
      _snack(action.successMessage);
      _reload();
    } catch (error) {
      _snack('تعذر تحديث المخزون: $error');
    }
  }

  Future<void> _setReorderLevel(MerchantInventoryItem item) async {
    final level = await showDialog<int>(
      context: context,
      builder: (context) => _ReorderLevelDialog(current: item.alertThreshold),
    );
    if (level == null) return;
    try {
      await ref.read(merchantMarketRepositoryProvider).setInventoryReorderLevel(
            inventoryId: item.id,
            reorderLevel: level,
          );
      _snack('تم تحديث حد إعادة الطلب');
      _reload();
    } catch (error) {
      _snack('تعذر تحديث حد إعادة الطلب: $error');
    }
  }

  Future<void> _showHistory(MerchantInventoryItem item) async {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _MovementsSheet(
        title: item.title,
        future: ref
            .read(merchantMarketRepositoryProvider)
            .getInventoryMovements(item.id),
      ),
    );
  }

  Future<void> _transfer(
      MerchantInventoryModel data, MerchantInventoryItem item) async {
    final input = await showDialog<_TransferInput>(
      context: context,
      builder: (context) =>
          _TransferDialog(item: item, branches: data.branches),
    );
    if (input == null) return;
    try {
      await ref.read(merchantMarketRepositoryProvider).transferInventory(
            inventoryId: item.id,
            listingId: item.listingNumericId ?? item.listingId ?? item.id,
            fromBranchId: item.branchNumericId ?? item.branchId,
            toBranchId: input.toBranchId,
            quantity: input.quantity,
            note: input.note,
          );
      _snack('تم تحويل المخزون بين الفروع');
      _reload();
    } catch (error) {
      _snack('تعذر تحويل المخزون: $error');
    }
  }

  Future<void> _stocktake(MerchantInventoryItem item) async {
    final input = await showDialog<_MovementInput>(
      context: context,
      builder: (context) => _StocktakeDialog(item: item),
    );
    if (input == null) return;
    try {
      await ref.read(merchantMarketRepositoryProvider).updateInventoryQuantity(
            listingId: item.listingNumericId ?? item.listingId ?? item.id,
            inventoryId: item.id,
            type: 'SET',
            quantity: input.quantity,
            reorderLevel: input.reorderLevel,
            note: input.note,
          );
      _snack('تم اعتماد نتيجة الجرد وتسوية الكمية');
      _reload();
    } catch (error) {
      _snack('تعذر اعتماد الجرد: $error');
    }
  }

  void _exportCsv(MerchantInventoryModel data) {
    final rows = <List<String>>[
      [
        'المنتج',
        'SKU',
        'الفرع',
        'المخزون',
        'محجوز',
        'المتاح',
        'حد الطلب',
        'الحالة',
        'آخر تحديث'
      ],
      for (final item in data.items)
        [
          item.title,
          item.sku ?? '',
          item.branchName,
          '${item.currentQuantity}',
          '${item.reservedQuantity}',
          '${item.availableQuantity}',
          '${item.alertThreshold}',
          _statusLabel(item.status),
          _dateLabel(item.updatedAt),
        ],
    ];
    final csv = rows.map((row) => row.map(_escapeCsv).join(',')).join('\n');
    Clipboard.setData(ClipboardData(text: csv));
    showDialog<void>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تم تجهيز ملف التصدير'),
          content: const Text(
              'تم نسخ بيانات المخزون بصيغة CSV. افتح Excel ثم الصق البيانات أو احفظ النص بامتداد .csv.'),
          actions: [
            FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('تم'))
          ],
        ),
      ),
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF5F7FA),
        drawer:
            const MerchantDrawer(currentTab: MerchantNavigationTab.products),
        bottomNavigationBar: const MerchantBottomNavigation(
            currentTab: MerchantNavigationTab.products),
        body: FutureBuilder<MerchantInventoryModel>(
          future: _future,
          builder: (context, snapshot) {
            final data = snapshot.data;
            return Column(
              children: [
                _Header(
                  onMenu: () => _scaffoldKey.currentState?.openDrawer(),
                  onExport: data == null ? null : () => _exportCsv(data),
                  tabController: _tabController,
                ),
                Expanded(
                  child: switch (snapshot.connectionState) {
                    ConnectionState.none ||
                    ConnectionState.waiting ||
                    ConnectionState.active =>
                      const _LoadingInventory(),
                    ConnectionState.done when snapshot.hasError => _ErrorState(
                        message: snapshot.error.toString(), onRetry: _reload),
                    _ => TabBarView(
                        controller: _tabController,
                        children: [
                          _InventoryBody(
                            data: snapshot.data!,
                            branch: _branch,
                            status: _status,
                            search: _search,
                            onSearch: _reload,
                            onBranch: (value) => setState(() {
                              _branch = value;
                              _future = _load();
                            }),
                            onStatus: (value) => setState(() {
                              _status = value;
                              _future = _load();
                            }),
                            onRefresh: _refresh,
                            onAction: _addMovement,
                            onHistory: _showHistory,
                            onReorder: _setReorderLevel,
                            onTransfer: (item) =>
                                _transfer(snapshot.data!, item),
                            onStocktake: _stocktake,
                          ),
                          _MovementsList(
                              movements: snapshot.data!.recentMovements,
                              onRefresh: _refresh),
                          _StocktakeGuide(
                              items: snapshot.data!.items,
                              onStocktake: _stocktake,
                              onExport: () => _exportCsv(snapshot.data!)),
                        ],
                      ),
                  },
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
  const _Header(
      {required this.onMenu,
      required this.onExport,
      required this.tabController});
  final VoidCallback onMenu;
  final VoidCallback? onExport;
  final TabController tabController;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.paddingOf(context).top + 10, 20, 0),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF061A2D), Color(0xFF0E3659)]),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                  onPressed: onMenu,
                  icon: const Icon(Icons.menu_rounded,
                      color: Colors.white, size: 32)),
              const Spacer(),
              Image.asset('assets/images/ghiyarak_logo_transparent.png',
                  width: 126, height: 62, fit: BoxFit.contain),
              const Spacer(),
              IconButton(
                  onPressed: onExport,
                  icon: const Icon(Icons.file_download_outlined,
                      color: Colors.white, size: 30)),
            ],
          ),
          const SizedBox(height: 8),
          const Text('إدارة المخزون',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Text('حركات، جرد، تنبيهات، تحويلات، وحدود إعادة الطلب',
              style: TextStyle(color: Color(0xFFD6E2EC), fontSize: 14)),
          const SizedBox(height: 16),
          TabBar(
            controller: tabController,
            indicatorColor: const Color(0xFFFF7900),
            labelColor: Colors.white,
            unselectedLabelColor: const Color(0xFFBFD0DD),
            labelStyle: const TextStyle(fontWeight: FontWeight.w900),
            tabs: const [
              Tab(text: 'المخزون'),
              Tab(text: 'الحركات'),
              Tab(text: 'الجرد'),
            ],
          ),
        ],
      ),
    );
  }
}

class _InventoryBody extends StatelessWidget {
  const _InventoryBody({
    required this.data,
    required this.branch,
    required this.status,
    required this.search,
    required this.onSearch,
    required this.onBranch,
    required this.onStatus,
    required this.onRefresh,
    required this.onAction,
    required this.onHistory,
    required this.onReorder,
    required this.onTransfer,
    required this.onStocktake,
  });

  final MerchantInventoryModel data;
  final String branch;
  final String status;
  final TextEditingController search;
  final VoidCallback onSearch;
  final ValueChanged<String> onBranch;
  final ValueChanged<String> onStatus;
  final Future<void> Function() onRefresh;
  final void Function(MerchantInventoryItem item, InventoryAction action)
      onAction;
  final ValueChanged<MerchantInventoryItem> onHistory;
  final ValueChanged<MerchantInventoryItem> onReorder;
  final ValueChanged<MerchantInventoryItem> onTransfer;
  final ValueChanged<MerchantInventoryItem> onStocktake;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: const Color(0xFFFF7900),
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 108),
        children: [
          _Stats(summary: data.summary),
          const SizedBox(height: 16),
          _SearchFilters(
            search: search,
            selectedBranch: branch,
            selectedStatus: status,
            branches: data.branches,
            onSearch: onSearch,
            onBranch: onBranch,
            onStatus: onStatus,
          ),
          const SizedBox(height: 16),
          _Alerts(items: data.alerts),
          const SizedBox(height: 16),
          if (data.items.isEmpty)
            const _EmptyState()
          else
            for (final item in data.items) ...[
              _InventoryCard(
                item: item,
                onIn: () => onAction(item, InventoryAction.inbound),
                onOut: () => onAction(item, InventoryAction.outbound),
                onDamage: () => onAction(item, InventoryAction.damage),
                onHistory: () => onHistory(item),
                onReorder: () => onReorder(item),
                onTransfer: () => onTransfer(item),
                onStocktake: () => onStocktake(item),
              ),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.summary});
  final MerchantInventorySummary summary;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _Stat('إجمالي المنتجات', '${summary.totalProducts}', 'منتج',
            Icons.inventory_2_outlined, const Color(0xFF3B82F6)),
        _Stat('المتاح للبيع', '${summary.totalAvailable}', 'قطعة',
            Icons.storefront_outlined, const Color(0xFF16A34A)),
        _Stat('محجوز للطلبات', '${summary.reservedQuantity}', 'قطعة',
            Icons.lock_clock_outlined, const Color(0xFF7C3AED)),
        _Stat('منخفض/نافد', '${summary.reorderNeeded}', 'تنبيه',
            Icons.warning_amber_rounded, const Color(0xFFFF7900)),
        _Stat('حركات اليوم', '${summary.movementsToday}', 'حركة',
            Icons.swap_vert_rounded, const Color(0xFF0EA5E9)),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.title, this.value, this.caption, this.icon, this.color);
  final String title;
  final String value;
  final String caption;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.sizeOf(context).width - 48) / 2,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: _cardDecoration,
        child: Row(
          children: [
            CircleAvatar(
                backgroundColor: color.withValues(alpha: .12),
                child: Icon(icon, color: color)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF092B4D))),
                  Text(value,
                      style: const TextStyle(
                          color: Color(0xFF092B4D),
                          fontSize: 24,
                          fontWeight: FontWeight.w900)),
                  Text(caption,
                      style: const TextStyle(
                          color: Color(0xFF718092), fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchFilters extends StatelessWidget {
  const _SearchFilters(
      {required this.search,
      required this.selectedBranch,
      required this.selectedStatus,
      required this.branches,
      required this.onSearch,
      required this.onBranch,
      required this.onStatus});
  final TextEditingController search;
  final String selectedBranch;
  final String selectedStatus;
  final List<MerchantInventoryBranch> branches;
  final VoidCallback onSearch;
  final ValueChanged<String> onBranch;
  final ValueChanged<String> onStatus;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () => _showStatusSheet(context),
              icon: const Icon(Icons.filter_alt_outlined),
              label: Text(
                  _statusLabel(selectedStatus == 'all' ? '' : selectedStatus)),
              style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 16)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: search,
                onSubmitted: (_) => onSearch(),
                decoration: InputDecoration(
                  hintText: 'ابحث باسم القطعة، SKU، الفرع',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: IconButton(
                      onPressed: onSearch,
                      icon: const Icon(Icons.arrow_back_rounded)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: selectedBranch == 'all' ||
                  branches.any((branch) => branch.id == selectedBranch)
              ? selectedBranch
              : 'all',
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'تصفية حسب الفرع',
            prefixIcon: Icon(Icons.storefront_outlined),
          ),
          items: [
            const DropdownMenuItem<String>(
              value: 'all',
              child: Text('كل الفروع'),
            ),
            ...branches.map((branch) => DropdownMenuItem<String>(
                  value: branch.id,
                  child: Text(branch.name, overflow: TextOverflow.ellipsis),
                )),
          ],
          onChanged: (value) {
            if (value != null) onBranch(value);
          },
        ),
      ],
    );
  }

  void _showStatusSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                  title: Text('تصفية حسب حالة المخزون',
                      style: TextStyle(fontWeight: FontWeight.w900))),
              for (final item in const [
                ('all', 'الكل'),
                ('available', 'متوفر'),
                ('low_stock', 'منخفض'),
                ('out_of_stock', 'نافد'),
                ('archived', 'مؤرشف')
              ])
                ListTile(
                  title: Text(item.$2),
                  selected: selectedStatus == item.$1,
                  leading: Icon(selectedStatus == item.$1
                      ? Icons.check_circle
                      : Icons.circle_outlined),
                  onTap: () {
                    Navigator.pop(context);
                    onStatus(item.$1);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}



class _Alerts extends StatelessWidget {
  const _Alerts({required this.items});
  final List<MerchantInventoryItem> items;
  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(children: [
          Icon(Icons.notifications_active_outlined, color: Color(0xFFFF7900)),
          SizedBox(width: 8),
          Text('تنبيهات المخزون',
              style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF092B4D)))
        ]),
        const SizedBox(height: 10),
        SizedBox(
          height: 116,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length > 8 ? 8 : items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) =>
                SizedBox(width: 220, child: _AlertCard(item: items[index])),
          ),
        ),
      ],
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.item});
  final MerchantInventoryItem item;
  @override
  Widget build(BuildContext context) {
    final out = item.isOutOfStock;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: out ? const Color(0xFFFFF1F1) : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: out ? const Color(0xFFFFCACA) : const Color(0xFFFFD9AD)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(item.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: out ? const Color(0xFFE53945) : const Color(0xFFFF7900),
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Text('المتاح: ${item.availableQuantity}',
            style: const TextStyle(
                color: Color(0xFF092B4D),
                fontSize: 23,
                fontWeight: FontWeight.w900)),
        Text('حد الطلب: ${item.alertThreshold} • ${item.branchName}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF718092), fontSize: 12)),
      ]),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  const _InventoryCard(
      {required this.item,
      required this.onIn,
      required this.onOut,
      required this.onDamage,
      required this.onHistory,
      required this.onReorder,
      required this.onTransfer,
      required this.onStocktake});
  final MerchantInventoryItem item;
  final VoidCallback onIn;
  final VoidCallback onOut;
  final VoidCallback onDamage;
  final VoidCallback onHistory;
  final VoidCallback onReorder;
  final VoidCallback onTransfer;
  final VoidCallback onStocktake;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(item.status);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration,
      child: Column(
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _ProductImage(url: item.imageUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                          child: Text(item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Color(0xFF092B4D),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900))),
                      _Status(label: _statusLabel(item.status), color: color),
                    ]),
                    const SizedBox(height: 5),
                    Text('فرع: ${item.branchName}  •  SKU: ${item.sku ?? '-'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFF718092))),
                    const SizedBox(height: 10),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      _MiniMetric(
                          label: 'المخزون',
                          value: '${item.currentQuantity}',
                          color: color),
                      _MiniMetric(
                          label: 'محجوز',
                          value: '${item.reservedQuantity}',
                          color: const Color(0xFF7C3AED)),
                      _MiniMetric(
                          label: 'المتاح',
                          value: '${item.availableQuantity}',
                          color: const Color(0xFF16A34A)),
                      _MiniMetric(
                          label: 'حد الطلب',
                          value: '${item.alertThreshold}',
                          color: const Color(0xFFFF7900)),
                    ]),
                    const SizedBox(height: 8),
                    Text(
                        'آخر تحديث: ${_timeLabel(item.updatedAt)}${item.categoryName == null ? '' : ' • ${item.categoryName}'}',
                        style: const TextStyle(
                            color: Color(0xFF718092), fontSize: 12)),
                  ]),
            ),
          ]),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ActionButton(
                  icon: Icons.add_circle_outline, label: 'إضافة', onTap: onIn),
              _ActionButton(
                  icon: Icons.remove_circle_outline,
                  label: 'صرف/بيع',
                  onTap: item.availableQuantity <= 0 ? null : onOut),
              _ActionButton(
                  icon: Icons.broken_image_outlined,
                  label: 'تالف',
                  onTap: item.availableQuantity <= 0 ? null : onDamage),
              _ActionButton(
                  icon: Icons.rule_folder_outlined,
                  label: 'جرد',
                  onTap: onStocktake),
              _ActionButton(
                  icon: Icons.swap_horiz_rounded,
                  label: 'تحويل',
                  onTap: item.availableQuantity <= 0 ? null : onTransfer),
              _ActionButton(
                  icon: Icons.notifications_active_outlined,
                  label: 'حد الطلب',
                  onTap: onReorder),
              _ActionButton(
                  icon: Icons.history_rounded,
                  label: 'السجل',
                  onTap: onHistory),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric(
      {required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
          color: color.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(10)),
      child: Column(children: [
        Text(label,
            style: const TextStyle(color: Color(0xFF718092), fontSize: 10)),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 16, fontWeight: FontWeight.w900)),
      ]),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9)),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({this.url});
  final String? url;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 86,
      height: 86,
      decoration: BoxDecoration(
          color: const Color(0xFFF0F3F6),
          borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: (url ?? '').isEmpty
          ? const Icon(Icons.inventory_2_outlined,
              color: Color(0xFF8291A0), size: 42)
          : Image.network(url!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                  Icons.inventory_2_outlined,
                  color: Color(0xFF8291A0),
                  size: 42)),
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(9)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        CircleAvatar(radius: 4, backgroundColor: color),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w900, fontSize: 11))
      ]),
    );
  }
}

class _MovementsList extends StatelessWidget {
  const _MovementsList({required this.movements, required this.onRefresh});
  final List<MerchantInventoryMovement> movements;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: movements.isEmpty
          ? const _EmptyMovements()
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 108),
              itemCount: movements.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) =>
                  _MovementTile(movement: movements[index]),
            ),
    );
  }
}

class _MovementsSheet extends StatelessWidget {
  const _MovementsSheet({required this.title, required this.future});
  final String title;
  final Future<List<MerchantInventoryMovement>> future;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: .75,
        maxChildSize: .92,
        minChildSize: .45,
        builder: (context, scrollController) =>
            FutureBuilder<List<MerchantInventoryMovement>>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done)
              return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError)
              return Center(child: Text('تعذر تحميل السجل: ${snapshot.error}'));
            final items = snapshot.data ?? const [];
            return ListView.separated(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: items.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index == 0)
                  return Text('سجل حركة: $title',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w900));
                return _MovementTile(movement: items[index - 1]);
              },
            );
          },
        ),
      ),
    );
  }
}

class _MovementTile extends StatelessWidget {
  const _MovementTile({required this.movement});
  final MerchantInventoryMovement movement;
  @override
  Widget build(BuildContext context) {
    final color = _movementColor(movement.movementType);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration,
      child: Row(children: [
        CircleAvatar(
            backgroundColor: color.withValues(alpha: .12),
            child: Icon(_movementIcon(movement.movementType), color: color)),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(movement.productName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Color(0xFF092B4D), fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(
                '${_movementLabel(movement.movementType)} • ${movement.branchName} • ${_dateLabel(movement.createdAt)}',
                style: const TextStyle(color: Color(0xFF718092), fontSize: 12)),
            if ((movement.note ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(movement.note!, maxLines: 2, overflow: TextOverflow.ellipsis)
            ],
          ]),
        ),
        Text('${movement.quantity}',
            style: TextStyle(
                color: color, fontSize: 22, fontWeight: FontWeight.w900)),
      ]),
    );
  }
}

class _StocktakeGuide extends StatelessWidget {
  const _StocktakeGuide(
      {required this.items, required this.onStocktake, required this.onExport});
  final List<MerchantInventoryItem> items;
  final ValueChanged<MerchantInventoryItem> onStocktake;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final critical = items.where((item) => item.needsReorder).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 108),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('جلسة الجرد',
                style: TextStyle(
                    color: Color(0xFF092B4D),
                    fontSize: 20,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text(
                'اختر المنتج، أدخل الكمية الفعلية الموجودة في الرف أو المستودع، وسيتم إنشاء حركة تسوية تلقائية مع حفظ الملاحظة.'),
            const SizedBox(height: 12),
            FilledButton.icon(
                onPressed: onExport,
                icon: const Icon(Icons.file_download_outlined),
                label: const Text('تصدير كشف الجرد')),
          ]),
        ),
        const SizedBox(height: 16),
        const Text('الأولوية في الجرد',
            style: TextStyle(
                color: Color(0xFF092B4D),
                fontSize: 19,
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        if (critical.isEmpty)
          const _EmptyState(message: 'لا توجد منتجات حرجة للجرد الآن')
        else
          for (final item in critical) ...[
            _InventoryCard(
              item: item,
              onIn: () {},
              onOut: () {},
              onDamage: () {},
              onHistory: () {},
              onReorder: () {},
              onTransfer: () {},
              onStocktake: () => onStocktake(item),
            ),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _MovementDialog extends StatefulWidget {
  const _MovementDialog({required this.item, required this.action});
  final MerchantInventoryItem item;
  final InventoryAction action;
  @override
  State<_MovementDialog> createState() => _MovementDialogState();
}

class _MovementDialogState extends State<_MovementDialog> {
  final qtyController = TextEditingController();
  final noteController = TextEditingController();
  late final reorderController =
      TextEditingController(text: '${widget.item.alertThreshold}');

  @override
  void dispose() {
    qtyController.dispose();
    noteController.dispose();
    reorderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text(widget.action.title),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _DialogInfo(item: widget.item),
            const SizedBox(height: 12),
            TextField(
                controller: qtyController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    labelText: 'الكمية',
                    helperText: widget.action.isOutbound
                        ? 'المتاح: ${widget.item.availableQuantity}'
                        : null)),
            const SizedBox(height: 10),
            TextField(
                controller: reorderController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'حد إعادة الطلب')),
            const SizedBox(height: 10),
            TextField(
                controller: noteController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'ملاحظة الحركة')),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          FilledButton(onPressed: _submit, child: const Text('حفظ')),
        ],
      ),
    );
  }

  void _submit() {
    final qty = int.tryParse(qtyController.text.trim()) ?? 0;
    final reorder = int.tryParse(reorderController.text.trim()) ??
        widget.item.alertThreshold;
    if (qty <= 0) return;
    if (widget.action.isOutbound && qty > widget.item.availableQuantity) return;
    Navigator.pop(
        context,
        _MovementInput(
            quantity: qty,
            reorderLevel: reorder,
            note: noteController.text.trim()));
  }
}

class _StocktakeDialog extends StatefulWidget {
  const _StocktakeDialog({required this.item});
  final MerchantInventoryItem item;
  @override
  State<_StocktakeDialog> createState() => _StocktakeDialogState();
}

class _StocktakeDialogState extends State<_StocktakeDialog> {
  late final qtyController =
      TextEditingController(text: '${widget.item.currentQuantity}');
  late final reorderController =
      TextEditingController(text: '${widget.item.alertThreshold}');
  final noteController = TextEditingController(text: 'تسوية جرد');
  @override
  void dispose() {
    qtyController.dispose();
    reorderController.dispose();
    noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('اعتماد جرد المنتج'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _DialogInfo(item: widget.item),
          const SizedBox(height: 12),
          TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'الكمية الفعلية بعد الجرد')),
          const SizedBox(height: 10),
          TextField(
              controller: reorderController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'حد إعادة الطلب')),
          const SizedBox(height: 10),
          TextField(
              controller: noteController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'ملاحظة الجرد')),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          FilledButton(onPressed: _submit, child: const Text('اعتماد'))
        ],
      ),
    );
  }

  void _submit() {
    final qty = int.tryParse(qtyController.text.trim());
    if (qty == null || qty < 0) return;
    Navigator.pop(
        context,
        _MovementInput(
            quantity: qty,
            reorderLevel: int.tryParse(reorderController.text.trim()),
            note: noteController.text.trim()));
  }
}

class _TransferDialog extends StatefulWidget {
  const _TransferDialog({required this.item, required this.branches});
  final MerchantInventoryItem item;
  final List<MerchantInventoryBranch> branches;
  @override
  State<_TransferDialog> createState() => _TransferDialogState();
}

class _TransferDialogState extends State<_TransferDialog> {
  final qtyController = TextEditingController();
  final noteController = TextEditingController();
  String? branchId;

  @override
  void dispose() {
    qtyController.dispose();
    noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final branches = widget.branches
        .where((b) =>
            b.id != widget.item.branchId && b.id != widget.item.branchNumericId)
        .toList();
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('تحويل مخزون بين الفروع'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _DialogInfo(item: widget.item),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: branchId,
            items: branches
                .map((b) => DropdownMenuItem(value: b.id, child: Text(b.name)))
                .toList(),
            onChanged: (value) => setState(() => branchId = value),
            decoration: const InputDecoration(labelText: 'الفرع المستلم'),
          ),
          const SizedBox(height: 10),
          TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                  labelText: 'الكمية',
                  helperText: 'المتاح: ${widget.item.availableQuantity}')),
          const SizedBox(height: 10),
          TextField(
              controller: noteController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'ملاحظة التحويل')),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          FilledButton(onPressed: _submit, child: const Text('تحويل'))
        ],
      ),
    );
  }

  void _submit() {
    final qty = int.tryParse(qtyController.text.trim()) ?? 0;
    if (branchId == null || qty <= 0 || qty > widget.item.availableQuantity)
      return;
    Navigator.pop(
        context,
        _TransferInput(
            toBranchId: branchId!,
            quantity: qty,
            note: noteController.text.trim()));
  }
}

class _ReorderLevelDialog extends StatefulWidget {
  const _ReorderLevelDialog({required this.current});
  final int current;
  @override
  State<_ReorderLevelDialog> createState() => _ReorderLevelDialogState();
}

class _ReorderLevelDialogState extends State<_ReorderLevelDialog> {
  late final controller = TextEditingController(text: '${widget.current}');
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('حد إعادة الطلب'),
        content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                labelText: 'أرسل تنبيهًا عندما تصل الكمية إلى')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          FilledButton(
              onPressed: () =>
                  Navigator.pop(context, int.tryParse(controller.text.trim())),
              child: const Text('حفظ'))
        ],
      ),
    );
  }
}

class _DialogInfo extends StatelessWidget {
  const _DialogInfo({required this.item});
  final MerchantInventoryItem item;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(item.title,
            style: const TextStyle(
                fontWeight: FontWeight.w900, color: Color(0xFF092B4D))),
        const SizedBox(height: 4),
        Text(
            'المخزون: ${item.currentQuantity} • المتاح: ${item.availableQuantity} • الفرع: ${item.branchName}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF718092))),
      ]),
    );
  }
}

class _LoadingInventory extends StatelessWidget {
  const _LoadingInventory();
  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: const [
      _Skeleton(height: 126),
      SizedBox(height: 14),
      _Skeleton(height: 68),
      SizedBox(height: 14),
      _Skeleton(height: 150),
      SizedBox(height: 14),
      _Skeleton(height: 190)
    ]);
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.height});
  final double height;
  @override
  Widget build(BuildContext context) => Container(
      height: height,
      decoration: BoxDecoration(
          color: const Color(0xFFE6ECF2),
          borderRadius: BorderRadius.circular(16)));
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({this.message = 'لا توجد بيانات مخزون بعد'});
  final String message;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 16),
      decoration: _cardDecoration,
      child: Column(children: [
        const Icon(Icons.inventory_2_outlined,
            size: 54, color: Color(0xFF8291A0)),
        const SizedBox(height: 10),
        Text(message,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Color(0xFF092B4D), fontWeight: FontWeight.w900))
      ]),
    );
  }
}

class _EmptyMovements extends StatelessWidget {
  const _EmptyMovements();
  @override
  Widget build(BuildContext context) => ListView(
      padding: const EdgeInsets.all(16),
      children: const [_EmptyState(message: 'لا توجد حركات مخزون بعد')]);
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    return ListView(
        padding: const EdgeInsets.fromLTRB(24, 80, 24, 96),
        children: [
          const Icon(Icons.cloud_off_outlined,
              size: 58, color: Color(0xFF8291A0)),
          const SizedBox(height: 12),
          const Center(
              child: Text('تعذر تحميل المخزون',
                  style: TextStyle(fontWeight: FontWeight.w900))),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Center(
              child: FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة المحاولة'))),
        ]);
  }
}

class _MovementInput {
  const _MovementInput({required this.quantity, this.reorderLevel, this.note});
  final int quantity;
  final int? reorderLevel;
  final String? note;
}

class _TransferInput {
  const _TransferInput(
      {required this.toBranchId, required this.quantity, this.note});
  final String toBranchId;
  final int quantity;
  final String? note;
}

enum InventoryAction {
  inbound,
  outbound,
  damage;

  String get title => switch (this) {
        InventoryAction.inbound => 'إضافة كمية للمخزون',
        InventoryAction.outbound => 'صرف/بيع من المخزون',
        InventoryAction.damage => 'تسجيل كمية تالفة',
      };

  String get apiType => switch (this) {
        InventoryAction.inbound => 'IN',
        InventoryAction.outbound => 'OUT',
        InventoryAction.damage => 'DAMAGE',
      };

  bool get isOutbound =>
      this == InventoryAction.outbound || this == InventoryAction.damage;

  String get successMessage => switch (this) {
        InventoryAction.inbound => 'تمت إضافة الكمية بنجاح',
        InventoryAction.outbound => 'تم صرف الكمية من المخزون',
        InventoryAction.damage => 'تم تسجيل الكمية التالفة',
      };
}

Color _statusColor(String status) => switch (status) {
      'out_of_stock' => const Color(0xFFE53945),
      'low_stock' => const Color(0xFFFF7900),
      'archived' => const Color(0xFF718092),
      _ => const Color(0xFF16A34A),
    };

String _statusLabel(String status) => switch (status) {
      'out_of_stock' => 'نافد',
      'low_stock' => 'منخفض',
      'archived' => 'مؤرشف',
      'available' => 'متوفر',
      _ => 'الكل',
    };

String _movementLabel(String type) => switch (type.toUpperCase()) {
      'IN' => 'إدخال',
      'OUT' => 'إخراج',
      'RESERVE' => 'حجز',
      'RELEASE' => 'فك حجز',
      'ADJUSTMENT' => 'تسوية',
      _ => type,
    };

Color _movementColor(String type) => switch (type.toUpperCase()) {
      'IN' || 'RELEASE' => const Color(0xFF16A34A),
      'OUT' => const Color(0xFFE53945),
      'RESERVE' => const Color(0xFF7C3AED),
      'ADJUSTMENT' => const Color(0xFFFF7900),
      _ => const Color(0xFF718092),
    };

IconData _movementIcon(String type) => switch (type.toUpperCase()) {
      'IN' => Icons.call_received_rounded,
      'OUT' => Icons.call_made_rounded,
      'RESERVE' => Icons.lock_clock_outlined,
      'RELEASE' => Icons.lock_open_rounded,
      'ADJUSTMENT' => Icons.tune_rounded,
      _ => Icons.swap_vert_rounded,
    };

String _timeLabel(DateTime? value) {
  if (value == null) return '-';
  final now = DateTime.now();
  final diff = now.difference(value);
  if (diff.inMinutes < 60) return 'قبل ${diff.inMinutes.clamp(1, 59)} د';
  if (diff.inHours < 24) return 'قبل ${diff.inHours} س';
  if (diff.inDays == 1) return 'أمس';
  return _dateLabel(value);
}

String _dateLabel(DateTime? value) {
  if (value == null) return '-';
  return '${value.year}/${value.month.toString().padLeft(2, '0')}/${value.day.toString().padLeft(2, '0')}';
}

String _escapeCsv(String value) => '"${value.replaceAll('"', '""')}"';

final _cardDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(18),
  border: Border.all(color: const Color(0xFFE0E7EF)),
  boxShadow: const [
    BoxShadow(color: Color(0x10051E35), blurRadius: 16, offset: Offset(0, 8))
  ],
);
