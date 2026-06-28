import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/features/merchant_market/data/merchant_market_repository.dart';
import 'package:ghiyarak/features/merchant_market/data/models/merchant_listing_model.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_bottom_navigation.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_drawer.dart';
import 'package:go_router/go_router.dart';

class MerchantListingsPage extends ConsumerStatefulWidget {
  const MerchantListingsPage({super.key});

  @override
  ConsumerState<MerchantListingsPage> createState() =>
      _MerchantListingsPageState();
}

class _MerchantListingsPageState extends ConsumerState<MerchantListingsPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _search = TextEditingController();
  String _filter = 'all';
  String _sort = 'newest';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listings = ref.watch(_merchantListingsProvider);
    final notificationCount =
        ref.watch(_notificationCountProvider).asData?.value ?? 0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF5F7FA),
        drawer:
            const MerchantDrawer(currentTab: MerchantNavigationTab.products),
        bottomNavigationBar: const MerchantBottomNavigation(
          currentTab: MerchantNavigationTab.products,
          compact: true,
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openCreateListing,
          backgroundColor: const Color(0xFFFF6500),
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded, size: 28),
          label: const Text(
            'إضافة منتج',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              _MerchantProductsHeader(
                search: _search,
                notificationCount: notificationCount,
                onMenu: () => _scaffoldKey.currentState?.openDrawer(),
                onSearch: (_) => setState(() {}),
                onBarcode: _showBarcodeMessage,
                onNotifications: () =>
                    context.go(RouteNames.merchantNotifications),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: const Color(0xFFFF7900),
                  onRefresh: _refresh,
                  child: listings.when(
                    loading: () => _ProductsScrollView(
                      tabs: _StatusTabs(
                        items: const [],
                        selected: _filter,
                        onChanged: _setFilter,
                      ),
                      filterSort: _FilterSortSection(
                        sort: _sort,
                        onSort: _setSort,
                        onFilter: _showFilters,
                      ),
                      slivers: const [_LoadingProductsSliver()],
                    ),
                    error: (error, _) => _ProductsScrollView(
                      tabs: _StatusTabs(
                        items: const [],
                        selected: _filter,
                        onChanged: _setFilter,
                      ),
                      filterSort: _FilterSortSection(
                        sort: _sort,
                        onSort: _setSort,
                        onFilter: _showFilters,
                      ),
                      slivers: [
                        _ErrorProductsSliver(
                          message: error.toString(),
                          onRetry: _reload,
                        ),
                      ],
                    ),
                    data: (items) {
                      final filtered = _filtered(items);
                      return _ProductsScrollView(
                        tabs: _StatusTabs(
                          items: items,
                          selected: _filter,
                          onChanged: _setFilter,
                        ),
                        filterSort: _FilterSortSection(
                          sort: _sort,
                          onSort: _setSort,
                          onFilter: _showFilters,
                        ),
                        slivers: [
                          if (filtered.isEmpty)
                            _EmptyProductsSliver(
                              hasFilters: items.isNotEmpty ||
                                  _search.text.trim().isNotEmpty ||
                                  _filter != 'all',
                              onAdd: _openCreateListing,
                            )
                          else
                            SliverPadding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 104),
                              sliver: SliverList.separated(
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final item = filtered[index];
                                  return _ProductCard(
                                    item: item,
                                    onDetails: () => context.go(
                                      RouteNames.merchantListingDetails(
                                          item.id),
                                    ),
                                    onEdit: () => context.go(
                                      RouteNames.editMerchantListing(item.id),
                                    ),
                                    onStatus: (status) =>
                                        _changeListingStatus(item.id, status),
                                  );
                                },
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refresh() async {
    ref.invalidate(_merchantListingsProvider);
    ref.invalidate(_notificationCountProvider);
    await ref.read(_merchantListingsProvider.future);
  }

  void _reload() {
    ref.invalidate(_merchantListingsProvider);
    ref.invalidate(_notificationCountProvider);
  }

  void _setFilter(String value) => setState(() => _filter = value);
  void _setSort(String value) => setState(() => _sort = value);
  void _openCreateListing() => context.go(RouteNames.createListing);

  Future<void> _showBarcodeMessage() async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('بحث سريع بالباركود'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'أدخل الباركود أو رقم القطعة',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('متابعة'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (!mounted || code == null || code.trim().isEmpty) return;
    context.go(
        '${RouteNames.createListing}?code=${Uri.encodeQueryComponent(code.trim())}');
  }

  Future<void> _changeListingStatus(String listingId, String status) async {
    final confirmed = await _confirmStatusChange(status);
    if (!confirmed) return;
    try {
      await ref.read(merchantMarketRepositoryProvider).updateListingStatus(
            listingId: listingId,
            status: status,
          );
      if (!mounted) return;
      _message(_statusSuccessMessage(status));
      _reload();
    } catch (error) {
      if (mounted) _message('تعذر تحديث الحالة: $error');
    }
  }

  Future<bool> _confirmStatusChange(String status) async {
    if (status != 'ARCHIVED' && status != 'OUT_OF_STOCK') return true;
    final title = status == 'ARCHIVED' ? 'أرشفة المنتج' : 'تحديد كنفد من المخزون';
    final body = status == 'ARCHIVED'
        ? 'هل تريد أرشفة هذا المنتج؟ لن يظهر للعملاء ويمكنك استعادته لاحقًا.'
        : 'هل تريد تحديد هذا المنتج كنفد من المخزون؟';
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('تأكيد'),
            ),
          ],
        ),
      ),
    );
    return result == true;
  }

  String _statusSuccessMessage(String status) => switch (status) {
        'ACTIVE' => 'تم تنشيط المنتج',
        'PAUSED' => 'تم إيقاف المنتج مؤقتًا',
        'OUT_OF_STOCK' => 'تم تحديد المنتج كنفد من المخزون',
        'ARCHIVED' => 'تمت أرشفة المنتج',
        'DRAFT' => 'تمت إعادة المنتج كمسودة',
        _ => 'تم تحديث حالة المنتج',
      };

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  List<MerchantListingModel> _filtered(List<MerchantListingModel> source) {
    final query = _search.text.trim().toLowerCase();
    final result = source.where((item) {
      final status = item.status.toUpperCase();
      final approval = item.approvalStatus.toUpperCase();
      final matchesQuery = query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          (item.sku ?? '').toLowerCase().contains(query) ||
          (item.partNumber ?? '').toLowerCase().contains(query);
      final matchesTab = switch (_filter) {
        'published' => status == 'ACTIVE',
        'draft' => status == 'DRAFT' || status == 'INACTIVE',
        'review' => approval.contains('PENDING'),
        'rejected' => approval.contains('REJECT'),
        'paused' => status == 'PAUSED',
        'archived' => status == 'ARCHIVED',
        'out' => item.stock <= 0,
        'low' => item.stock > 0 && item.stock <= 5,
        _ => true,
      };
      return matchesQuery && matchesTab;
    }).toList();

    switch (_sort) {
      case 'price':
        result.sort((a, b) => b.price.compareTo(a.price));
      case 'stock':
        result.sort((a, b) => a.stock.compareTo(b.stock));
      default:
        break;
    }
    return result;
  }

  void _showFilters() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'تصفية المنتجات',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              for (final item in const [
                ('all', 'كل المنتجات'),
                ('published', 'المنتجات المنشورة'),
                ('draft', 'المسودات'),
                ('review', 'قيد المراجعة'),
                ('rejected', 'مرفوضة'),
                ('paused', 'متوقفة'),
                ('archived', 'مؤرشفة'),
                ('out', 'نافدة'),
                ('low', 'منخفض المخزون'),
              ])
                ListTile(
                  title: Text(item.$2),
                  selected: _filter == item.$1,
                  trailing: _filter == item.$1
                      ? const Icon(Icons.check_circle_rounded)
                      : null,
                  onTap: () {
                    _setFilter(item.$1);
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

final _merchantListingsProvider = FutureProvider<List<MerchantListingModel>>(
  (ref) => ref.read(merchantMarketRepositoryProvider).getMyListings(),
);

final _notificationCountProvider = FutureProvider<int>(
  (ref) async => (await ref
          .read(merchantMarketRepositoryProvider)
          .getMerchantNotifications())
      .unreadCount,
);

class _MerchantProductsHeader extends StatelessWidget {
  const _MerchantProductsHeader({
    required this.search,
    required this.notificationCount,
    required this.onMenu,
    required this.onSearch,
    required this.onBarcode,
    required this.onNotifications,
  });

  final TextEditingController search;
  final int notificationCount;
  final VoidCallback onMenu;
  final ValueChanged<String> onSearch;
  final VoidCallback onBarcode;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF06213D), Color(0xFF00385D)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              MerchantDrawerButton(onPressed: onMenu),
              const Spacer(),
              Image.asset(
                'assets/images/ghiyarak_logo_transparent.png',
                width: 118,
                height: 56,
                fit: BoxFit.contain,
              ),
              const Spacer(),
              _NotificationButton(
                count: notificationCount,
                onTap: onNotifications,
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              'المنتجات',
              style: TextStyle(
                color: Colors.white,
                fontSize: 25,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              'إدارة منتجات متجرك',
              style: TextStyle(color: Color(0xFFD6E2EC), fontSize: 13),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: onBarcode,
                  borderRadius: BorderRadius.circular(12),
                  child: const SizedBox(
                    width: 56,
                    height: 54,
                    child: Icon(Icons.qr_code_scanner_rounded, size: 30),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: search,
                  onChanged: onSearch,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'ابحث باسم المنتج أو رقم القطعة أو SKU',
                    suffixIcon: const Icon(Icons.search_rounded, size: 27),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductsScrollView extends StatelessWidget {
  const _ProductsScrollView({
    required this.tabs,
    required this.filterSort,
    required this.slivers,
  });

  final Widget tabs;
  final Widget filterSort;
  final List<Widget> slivers;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: tabs),
        SliverToBoxAdapter(child: filterSort),
        ...slivers,
      ],
    );
  }
}

class _StatusTabs extends StatelessWidget {
  const _StatusTabs({
    required this.items,
    required this.selected,
    required this.onChanged,
  });

  final List<MerchantListingModel> items;
  final String selected;
  final ValueChanged<String> onChanged;

  int _count(String key) {
    return items.where((item) {
      final status = item.status.toUpperCase();
      final approval = item.approvalStatus.toUpperCase();
      return switch (key) {
        'published' => status == 'ACTIVE',
        'draft' => status == 'DRAFT' || status == 'INACTIVE',
        'review' => approval.contains('PENDING'),
        'rejected' => approval.contains('REJECT'),
        'paused' => status == 'PAUSED',
        'archived' => status == 'ARCHIVED',
        'out' => item.stock <= 0,
        'low' => item.stock > 0 && item.stock <= 5,
        _ => true,
      };
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    const tabs = [
      ('all', 'الكل'),
      ('published', 'منشور'),
      ('draft', 'مسودة'),
      ('review', 'قيد المراجعة'),
      ('rejected', 'مرفوض'),
      ('paused', 'متوقف'),
      ('archived', 'مؤرشف'),
      ('out', 'نافد'),
      ('low', 'منخفض'),
    ];

    return Container(
      color: const Color(0xFFF5F7FA),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: DropdownButtonFormField<String>(
        initialValue: selected,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: 'فلترة المنتجات',
          prefixIcon: const Icon(Icons.filter_alt_outlined),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        items: tabs
            .map(
              (tab) => DropdownMenuItem<String>(
                value: tab.$1,
                child: Text('${tab.$2} (${_count(tab.$1)})'),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
      ),
    );
  }
}


class _FilterSortSection extends StatelessWidget {
  const _FilterSortSection({
    required this.sort,
    required this.onSort,
    required this.onFilter,
  });

  final String sort;
  final ValueChanged<String> onSort;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F7FA),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: sort,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'ترتيب المنتجات',
                prefixIcon: const Icon(Icons.sort_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'newest', child: Text('الأحدث')),
                DropdownMenuItem(value: 'price', child: Text('الأعلى سعراً')),
                DropdownMenuItem(value: 'stock', child: Text('الأقل مخزوناً')),
              ],
              selectedItemBuilder: (context) => const [
                Text('الأحدث', overflow: TextOverflow.ellipsis),
                Text('الأعلى سعراً', overflow: TextOverflow.ellipsis),
                Text('الأقل مخزوناً', overflow: TextOverflow.ellipsis),
              ],
              onChanged: (value) {
                if (value != null) onSort(value);
              },
            ),
          ),
          const SizedBox(width: 10),
          Tooltip(
            message: 'فلترة متقدمة',
            child: OutlinedButton.icon(
              onPressed: onFilter,
              icon: const Icon(Icons.tune_rounded),
              label: const Text('فلتر'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(104, 56),
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.item,
    required this.onDetails,
    required this.onEdit,
    required this.onStatus,
  });

  final MerchantListingModel item;
  final VoidCallback onDetails;
  final VoidCallback onEdit;
  final ValueChanged<String> onStatus;

  List<PopupMenuEntry<String>> _statusActions(String status) {
    final items = <PopupMenuEntry<String>>[
      const PopupMenuItem(value: 'details', child: Text('عرض التفاصيل')),
      const PopupMenuItem(value: 'edit', child: Text('تعديل')),
      const PopupMenuDivider(),
    ];
    if (status == 'ACTIVE') {
      items.addAll(const [
        PopupMenuItem(value: 'PAUSED', child: Text('إيقاف مؤقت')),
        PopupMenuItem(value: 'OUT_OF_STOCK', child: Text('نفد المخزون')),
        PopupMenuItem(value: 'ARCHIVED', child: Text('أرشفة / حذف من الواجهة')),
      ]);
    } else if (status == 'PAUSED' || status == 'OUT_OF_STOCK') {
      items.addAll(const [
        PopupMenuItem(value: 'ACTIVE', child: Text('تنشيط')),
        PopupMenuItem(value: 'ARCHIVED', child: Text('أرشفة / حذف من الواجهة')),
      ]);
    } else if (status == 'ARCHIVED') {
      items.addAll(const [
        PopupMenuItem(value: 'DRAFT', child: Text('استعادة كمسودة')),
        PopupMenuItem(value: 'ACTIVE', child: Text('استعادة كنشط')),
      ]);
    } else {
      items.addAll(const [
        PopupMenuItem(value: 'ACTIVE', child: Text('نشر المنتج')),
        PopupMenuItem(value: 'ARCHIVED', child: Text('أرشفة / حذف من الواجهة')),
      ]);
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final low = item.stock <= 5;
    final review = item.approvalStatus.toUpperCase().contains('PENDING');
    final published = item.status.toUpperCase() == 'ACTIVE';
    final status = item.status.toUpperCase();
    final rejected = item.approvalStatus.toUpperCase().contains('REJECT');
    final label = low
        ? item.stock == 0
            ? 'نفد المخزون'
            : 'منخفض المخزون'
        : rejected
            ? 'مرفوض'
            : review
                ? 'قيد المراجعة'
                : status == 'ARCHIVED'
                    ? 'مؤرشف'
                    : status == 'PAUSED'
                        ? 'متوقف مؤقتاً'
                        : published
                            ? 'منشور'
                            : 'مسودة';
    final color = low || rejected
        ? const Color(0xFFE43B45)
        : review
            ? const Color(0xFF268FC0)
            : published
                ? const Color(0xFF16A34A)
                : status == 'PAUSED'
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProductImage(url: item.imageUrl),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF092B4D),
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'إجراءات المنتج',
                      padding: EdgeInsets.zero,
                      itemBuilder: (_) => _statusActions(status),
                      onSelected: (value) {
                        if (value == 'details') return onDetails();
                        if (value == 'edit') return onEdit();
                        onStatus(value);
                      },
                      icon: const Icon(Icons.more_vert_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  'SKU: ${item.sku ?? '-'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(color: Color(0xFF6D7D8F), fontSize: 12),
                ),
                const SizedBox(height: 3),
                Text(
                  'رقم القطعة: ${item.partNumber ?? '-'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(color: Color(0xFF6D7D8F), fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9F8EE),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'متوافق',
                        style: TextStyle(
                          color: Color(0xFF169447),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        item.compatibility ?? 'لم يحدد توافق السيارات',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF52667B),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _StatusPill(label: label, color: color),
                    _InlineMetric(
                      label: 'المخزون',
                      value: '${item.stock} قطعة',
                      color: low
                          ? const Color(0xFFE43B45)
                          : const Color(0xFF159447),
                    ),
                    Text(
                      item.hasSale
                          ? '${item.salePrice!.toStringAsFixed(2)} ${item.currency}'
                          : '${item.price.toStringAsFixed(2)} ${item.currency}',
                      style: const TextStyle(
                        color: Color(0xFF092B4D),
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (item.hasSale)
                      Text(
                        '${item.price.toStringAsFixed(2)} ${item.currency}',
                        style: const TextStyle(
                          color: Color(0xFF8A96A3),
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    OutlinedButton.icon(
                      onPressed: onDetails,
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      label: const Text('تفاصيل'),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('تعديل'),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: status == 'ARCHIVED'
                          ? () => onStatus('DRAFT')
                          : () => onStatus('ARCHIVED'),
                      icon: Icon(
                        status == 'ARCHIVED'
                            ? Icons.restore_outlined
                            : Icons.archive_outlined,
                        size: 18,
                      ),
                      label: Text(status == 'ARCHIVED' ? 'استعادة' : 'أرشفة'),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: status == 'ARCHIVED'
                            ? const Color(0xFF2563EB)
                            : const Color(0xFFE43B45),
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
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 82,
      height: 96,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F3F6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: (url ?? '').isEmpty
          ? const Icon(
              Icons.settings_outlined,
              color: Color(0xFF8291A0),
              size: 42,
            )
          : Image.network(
              url!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.settings_outlined,
                color: Color(0xFF8291A0),
                size: 42,
              ),
            ),
    );
  }
}

class _InlineMetric extends StatelessWidget {
  const _InlineMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF8A96A3), fontSize: 10),
        ),
        Text(
          value,
          style: TextStyle(color: color, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 4, backgroundColor: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingProductsSliver extends StatelessWidget {
  const _LoadingProductsSliver();

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 104),
      sliver: SliverList.separated(
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => Container(
          height: 150,
          decoration: BoxDecoration(
            color: const Color(0xFFE5EAF0),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _EmptyProductsSliver extends StatelessWidget {
  const _EmptyProductsSliver({
    required this.hasFilters,
    required this.onAdd,
  });

  final bool hasFilters;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 48, 16, 104),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                size: 56,
                color: Color(0xFF8291A0),
              ),
              const SizedBox(height: 12),
              Text(
                hasFilters ? 'لا توجد منتجات مطابقة' : 'لا توجد منتجات بعد',
                style: const TextStyle(
                  color: Color(0xFF102A43),
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                hasFilters
                    ? 'جرّب تغيير البحث أو التصفية'
                    : 'أضف أول منتج لمتجرك',
                style: const TextStyle(color: Color(0xFF6B7C93)),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded),
                label: const Text('إضافة منتج'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6500),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorProductsSliver extends StatelessWidget {
  const _ErrorProductsSliver({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 54, 24, 104),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 56,
                color: Color(0xFF8291A0),
              ),
              const SizedBox(height: 12),
              const Text(
                'تعذر تحميل المنتجات',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF6B7C93), fontSize: 12),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: onTap,
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: Colors.white,
            size: 30,
          ),
        ),
        if (count > 0)
          Positioned(
            top: 0,
            left: 0,
            child: CircleAvatar(
              radius: 11,
              backgroundColor: const Color(0xFFFF7900),
              child: Text(
                count > 99 ? '99+' : '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

final _cardDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(12),
  border: Border.all(color: const Color(0xFFE0E6EC)),
  boxShadow: const [
    BoxShadow(
      color: Color(0x10071D33),
      blurRadius: 14,
      offset: Offset(0, 5),
    ),
  ],
);
