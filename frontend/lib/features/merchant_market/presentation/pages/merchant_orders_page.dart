import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/features/merchant_market/data/merchant_market_repository.dart';
import 'package:ghiyarak/features/merchant_market/data/models/merchant_order_model.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_bottom_navigation.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_drawer.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_page_header.dart';
import 'package:go_router/go_router.dart';

class MerchantOrdersPage extends ConsumerStatefulWidget {
  const MerchantOrdersPage({super.key});

  @override
  ConsumerState<MerchantOrdersPage> createState() => _MerchantOrdersPageState();
}

class _MerchantOrdersPageState extends ConsumerState<MerchantOrdersPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _search = TextEditingController();
  late Future<List<MerchantOrderModel>> _future;
  String _filter = 'ALL';
  String _paymentFilter = 'ALL';
  String _fulfillmentFilter = 'ALL';
  String? _updatingId;

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

  Future<List<MerchantOrderModel>> _load() =>
      ref.read(merchantMarketRepositoryProvider).getMerchantOrders();

  Future<void> _refresh() async {
    final next = _load();
    setState(() => _future = next);
    await next;
  }

  Future<void> _updateStatus(
    MerchantOrderModel order,
    String status, {
    String? note,
  }) async {
    if (_updatingId != null) return;
    setState(() => _updatingId = order.id);
    try {
      await ref.read(merchantMarketRepositoryProvider).updateOrderStatus(
            orderId: order.id,
            status: status,
            note: note,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('تم تحويل الطلب إلى ${orderStatusLabel(status)}')),
      );
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تحديث الطلب: $error')),
      );
    } finally {
      if (mounted) setState(() => _updatingId = null);
    }
  }

  Future<void> _reject(MerchantOrderModel order) async {
    final reason = await _showRejectSheet(order);
    if (reason == null || reason.trim().isEmpty) return;
    await _updateStatus(order, 'REJECTED', note: reason.trim());
  }

  Future<String?> _showRejectSheet(MerchantOrderModel order) {
    final controller = TextEditingController();
    final reasons = [
      'الكمية غير متوفرة',
      'السعر يحتاج مراجعة',
      'الفرع مغلق حاليًا',
      'المنتج غير متاح',
    ];
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'رفض الطلب ${order.orderNumber}',
                style:
                    const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              const Text('اكتب سببًا واضحًا ليظهر في سجل الطلب ويصل للعميل.'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final reason in reasons)
                    ActionChip(
                      label: Text(reason),
                      onPressed: () => controller.text = reason,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'سبب الرفض',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, controller.text),
                      child: const Text('تأكيد الرفض'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(controller.dispose);
  }

  List<MerchantOrderModel> _filtered(List<MerchantOrderModel> orders) {
    final query = _search.text.trim().toLowerCase();
    return orders.where((order) {
      final statusOk = _filter == 'ALL' || statusGroup(order.status) == _filter;
      final paymentOk =
          _paymentFilter == 'ALL' || order.paymentStatus == _paymentFilter;
      final fulfillmentOk = _fulfillmentFilter == 'ALL' ||
          order.fulfillmentMethod == _fulfillmentFilter;
      final searchOk = query.isEmpty ||
          order.orderNumber.toLowerCase().contains(query) ||
          order.customerName.toLowerCase().contains(query) ||
          (order.customerPhone ?? '').contains(query) ||
          order.itemNames.any((name) => name.toLowerCase().contains(query));
      return statusOk && paymentOk && fulfillmentOk && searchOk;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF5F7FA),
        drawer: const MerchantDrawer(currentTab: MerchantNavigationTab.orders),
        bottomNavigationBar: const MerchantBottomNavigation(
          currentTab: MerchantNavigationTab.orders,
          compact: true,
        ),
        body: FutureBuilder<List<MerchantOrderModel>>(
          future: _future,
          builder: (context, snapshot) {
            final orders = snapshot.data ?? const <MerchantOrderModel>[];
            return Column(
              children: [
                MerchantPageHeader(
                  title: 'إدارة الطلبات',
                  subtitle: 'قبول، تجهيز، تسليم، رفض، وفوترة الطلبات',
                  onMenu: () => _scaffoldKey.currentState?.openDrawer(),
                  notificationCount:
                      orders.where((order) => order.status == 'PENDING').length,
                  onNotifications: () =>
                      context.go(RouteNames.merchantNotifications),
                ),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Expanded(
                      child: Center(child: CircularProgressIndicator()))
                else if (snapshot.hasError)
                  Expanded(
                      child:
                          _ErrorState(onRetry: _refresh, error: snapshot.error))
                else
                  Expanded(child: _content(orders)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _content(List<MerchantOrderModel> orders) {
    final filtered = _filtered(orders);
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _StatsPanel(orders: orders),
          const SizedBox(height: 12),
          _StageTabs(
            selected: _filter,
            orders: orders,
            onChanged: (value) => setState(() => _filter = value),
          ),
          const SizedBox(height: 12),
          _FiltersBar(
            search: _search,
            paymentFilter: _paymentFilter,
            fulfillmentFilter: _fulfillmentFilter,
            onSearch: (_) => setState(() {}),
            onPayment: (value) =>
                setState(() => _paymentFilter = value ?? 'ALL'),
            onFulfillment: (value) =>
                setState(() => _fulfillmentFilter = value ?? 'ALL'),
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            const _EmptyOrders()
          else
            for (final order in filtered) ...[
              _OrderCard(
                order: order,
                updating: _updatingId == order.id,
                onOpen: () async {
                  final changed = await context.push<bool>(
                    RouteNames.merchantOrderDetails(order.id),
                  );
                  if (changed == true) _refresh();
                },
                onNext: nextOrderStatus(order) == null
                    ? null
                    : () => _updateStatus(order, nextOrderStatus(order)!),
                onReject: order.canReject ? () => _reject(order) : null,
                onCopyInvoice: () => _copyInvoice(order),
              ),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }

  Future<void> _copyInvoice(MerchantOrderModel order) async {
    final text = buildInvoiceText(order);
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ ملخص الفاتورة')),
    );
  }
}

class _StatsPanel extends StatelessWidget {
  const _StatsPanel({required this.orders});
  final List<MerchantOrderModel> orders;

  @override
  Widget build(BuildContext context) {
    final totalSales = orders
        .where((order) => order.status == 'COMPLETED')
        .fold<double>(0, (sum, order) => sum + order.total);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _StatTile('جديدة', _countGroup(orders, 'NEW').toString(),
              Icons.fiber_new_rounded),
          _StatTile('قيد التنفيذ', _countGroup(orders, 'PROCESSING').toString(),
              Icons.settings_suggest_rounded),
          _StatTile('جاهزة/توصيل', _countGroup(orders, 'READY').toString(),
              Icons.local_shipping_outlined),
          _StatTile('مكتملة', _countGroup(orders, 'COMPLETED').toString(),
              Icons.verified_rounded),
          _StatTile('مبيعات مكتملة', '${totalSales.toStringAsFixed(0)} YER',
              Icons.payments_outlined),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile(this.title, this.value, this.icon);
  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5EAF0)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFF6417)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                Text(title,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StageTabs extends StatelessWidget {
  const _StageTabs(
      {required this.selected, required this.orders, required this.onChanged});
  final String selected;
  final List<MerchantOrderModel> orders;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      ('ALL', 'الكل', orders.length),
      ('NEW', 'جديدة', _countGroup(orders, 'NEW')),
      ('PROCESSING', 'قيد التنفيذ', _countGroup(orders, 'PROCESSING')),
      ('READY', 'جاهزة', _countGroup(orders, 'READY')),
      ('COMPLETED', 'مكتملة', _countGroup(orders, 'COMPLETED')),
      ('CANCELLED', 'ملغية/مرفوضة', _countGroup(orders, 'CANCELLED')),
    ];
    return DropdownButtonFormField<String>(
      initialValue: selected,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'فلترة الطلبات حسب المرحلة',
        prefixIcon: const Icon(Icons.filter_alt_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      items: tabs
          .map(
            (tab) => DropdownMenuItem<String>(
              value: tab.$1,
              child: Text('${tab.$2} (${tab.$3})'),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

class _FiltersBar extends StatelessWidget {
  const _FiltersBar({
    required this.search,
    required this.paymentFilter,
    required this.fulfillmentFilter,
    required this.onSearch,
    required this.onPayment,
    required this.onFulfillment,
  });
  final TextEditingController search;
  final String paymentFilter;
  final String fulfillmentFilter;
  final ValueChanged<String> onSearch;
  final ValueChanged<String?> onPayment;
  final ValueChanged<String?> onFulfillment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          TextField(
            controller: search,
            onChanged: onSearch,
            decoration: const InputDecoration(
              hintText: 'بحث برقم الطلب، العميل، الهاتف، أو المنتج',
              prefixIcon: Icon(Icons.search_rounded),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: paymentFilter,
                  decoration: const InputDecoration(
                    labelText: 'الدفع',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'ALL', child: Text('كل حالات الدفع')),
                    DropdownMenuItem(value: 'UNPAID', child: Text('غير مدفوع')),
                    DropdownMenuItem(
                        value: 'PENDING_REVIEW',
                        child: Text('بانتظار المراجعة')),
                    DropdownMenuItem(value: 'PAID', child: Text('مدفوع')),
                    DropdownMenuItem(value: 'REFUNDED', child: Text('مسترد')),
                  ],
                  onChanged: onPayment,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: fulfillmentFilter,
                  decoration: const InputDecoration(
                    labelText: 'التسليم',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'ALL', child: Text('كل طرق التسليم')),
                    DropdownMenuItem(
                        value: 'PICKUP', child: Text('استلام من الفرع')),
                    DropdownMenuItem(value: 'DELIVERY', child: Text('توصيل')),
                  ],
                  onChanged: onFulfillment,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.updating,
    required this.onOpen,
    required this.onNext,
    required this.onReject,
    required this.onCopyInvoice,
  });
  final MerchantOrderModel order;
  final bool updating;
  final VoidCallback onOpen;
  final VoidCallback? onNext;
  final VoidCallback? onReject;
  final VoidCallback onCopyInvoice;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.orderNumber,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w900),
                  ),
                ),
                _StatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: 8),
            Text('العميل: ${order.customerName}',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              '${order.itemsCount} قطعة • ${fulfillmentLabel(order.fulfillmentMethod)} • ${paymentStatusLabel(order.paymentStatus)}',
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: order.items
                  .take(3)
                  .map((item) => Chip(
                        label: Text('${item.name} ×${item.quantity}'),
                        visualDensity: VisualDensity.compact,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  '${order.total.toStringAsFixed(0)} ${order.currency}',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFF6417)),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'نسخ الفاتورة',
                  onPressed: onCopyInvoice,
                  icon: const Icon(Icons.receipt_long_outlined),
                ),
                if (onReject != null)
                  TextButton(
                    onPressed: updating ? null : onReject,
                    child: const Text('رفض'),
                  ),
                FilledButton.icon(
                  onPressed: updating ? null : onNext,
                  icon: updating
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.arrow_back_rounded),
                  label: Text(nextOrderStatus(order) == null
                      ? 'مكتمل'
                      : orderStatusLabel(nextOrderStatus(order)!)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (statusGroup(status)) {
      'NEW' => const Color(0xFF2563EB),
      'PROCESSING' => const Color(0xFFF59E0B),
      'READY' => const Color(0xFF7C3AED),
      'COMPLETED' => const Color(0xFF059669),
      'CANCELLED' => const Color(0xFFDC2626),
      _ => const Color(0xFF64748B),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        orderStatusLabel(status),
        style:
            TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12),
      ),
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: _cardDecoration(),
      child: const Column(
        children: [
          Icon(Icons.assignment_outlined, size: 54, color: Color(0xFF94A3B8)),
          SizedBox(height: 10),
          Text('لا توجد طلبات مطابقة',
              style: TextStyle(fontWeight: FontWeight.w900)),
          SizedBox(height: 4),
          Text('غيّر الفلاتر أو اسحب لتحديث القائمة.'),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry, this.error});
  final Future<void> Function() onRetry;
  final Object? error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 52, color: Color(0xFFDC2626)),
            const SizedBox(height: 10),
            const Text('تعذر تحميل الطلبات',
                style: TextStyle(fontWeight: FontWeight.w900)),
            if (error != null) ...[
              const SizedBox(height: 6),
              Text('$error', textAlign: TextAlign.center),
            ],
            const SizedBox(height: 14),
            FilledButton(
                onPressed: onRetry, child: const Text('إعادة المحاولة')),
          ],
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFE5EAF0)),
      boxShadow: const [
        BoxShadow(
            color: Color(0x0F000000), blurRadius: 18, offset: Offset(0, 8)),
      ],
    );

int _countGroup(List<MerchantOrderModel> orders, String group) =>
    orders.where((order) => statusGroup(order.status) == group).length;

String? nextOrderStatus(MerchantOrderModel order) => switch (order.status) {
      'PENDING' => 'CONFIRMED',
      'CONFIRMED' => 'PREPARING',
      'PREPARING' =>
        order.needsDelivery ? 'OUT_FOR_DELIVERY' : 'READY_FOR_PICKUP',
      'READY_FOR_PICKUP' || 'OUT_FOR_DELIVERY' => 'COMPLETED',
      _ => null,
    };

String statusGroup(String status) => switch (status) {
      'PENDING' => 'NEW',
      'CONFIRMED' || 'PREPARING' => 'PROCESSING',
      'READY_FOR_PICKUP' || 'OUT_FOR_DELIVERY' => 'READY',
      'COMPLETED' => 'COMPLETED',
      'CANCELLED' || 'REJECTED' => 'CANCELLED',
      _ => 'ALL',
    };

String orderStatusLabel(String status) => switch (status) {
      'PENDING' => 'طلب جديد',
      'CONFIRMED' => 'مقبول',
      'PREPARING' => 'قيد التجهيز',
      'READY_FOR_PICKUP' => 'جاهز للاستلام',
      'OUT_FOR_DELIVERY' => 'قيد التوصيل',
      'COMPLETED' => 'تم التسليم',
      'CANCELLED' => 'ملغي',
      'REJECTED' => 'مرفوض',
      _ => status,
    };

String fulfillmentLabel(String value) => switch (value) {
      'DELIVERY' => 'توصيل',
      'PICKUP' => 'استلام من الفرع',
      _ => value,
    };

String paymentStatusLabel(String value) => switch (value) {
      'UNPAID' => 'غير مدفوع',
      'PENDING_REVIEW' => 'بانتظار المراجعة',
      'PAID' => 'مدفوع',
      'FAILED' => 'فشل الدفع',
      'REFUNDED' => 'مسترد',
      _ => value,
    };

String paymentMethodLabel(String value) => switch (value) {
      'CASH_ON_DELIVERY' => 'الدفع عند التوصيل',
      'CASH_ON_PICKUP' => 'الدفع عند الاستلام',
      'BANK_TRANSFER' => 'تحويل بنكي',
      'WALLET' => 'محفظة إلكترونية',
      _ => value,
    };

String buildInvoiceText(MerchantOrderModel order) {
  final buffer = StringBuffer()
    ..writeln('فاتورة طلب ${order.orderNumber}')
    ..writeln('العميل: ${order.customerName}')
    ..writeln('الحالة: ${orderStatusLabel(order.status)}')
    ..writeln('طريقة التسليم: ${fulfillmentLabel(order.fulfillmentMethod)}')
    ..writeln('طريقة الدفع: ${paymentMethodLabel(order.paymentMethod)}')
    ..writeln('---------------------');
  for (final item in order.items) {
    buffer.writeln(
        '${item.name} ×${item.quantity} = ${item.total.toStringAsFixed(0)} ${order.currency}');
  }
  buffer
    ..writeln('---------------------')
    ..writeln('الإجمالي: ${order.total.toStringAsFixed(0)} ${order.currency}');
  return buffer.toString();
}
