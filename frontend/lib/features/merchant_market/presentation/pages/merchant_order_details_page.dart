import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/features/merchant_market/data/merchant_market_repository.dart';
import 'package:ghiyarak/features/merchant_market/data/models/merchant_order_model.dart';
import 'package:ghiyarak/features/merchant_market/presentation/pages/merchant_orders_page.dart';

class MerchantOrderDetailsPage extends ConsumerStatefulWidget {
  const MerchantOrderDetailsPage({
    super.key,
    this.order,
    this.orderId,
  }) : assert(order != null || orderId != null);

  final MerchantOrderModel? order;
  final String? orderId;

  @override
  ConsumerState<MerchantOrderDetailsPage> createState() =>
      _MerchantOrderDetailsPageState();
}

class _MerchantOrderDetailsPageState
    extends ConsumerState<MerchantOrderDetailsPage> {
  Future<MerchantOrderModel>? _future;
  MerchantOrderModel? _order;
  bool _updating = false;

  MerchantOrderModel get order {
    final current = _order ?? widget.order;
    if (current == null) {
      throw StateError('Merchant order details are not loaded yet.');
    }
    return current;
  }

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    final id = widget.orderId ?? widget.order?.id;
    if (id != null) _future = _load(id);
  }

  Future<MerchantOrderModel> _load(String id) async {
    final result = await ref
        .read(merchantMarketRepositoryProvider)
        .getMerchantOrderDetail(id);
    _order = result;
    return result;
  }

  Future<void> _refresh() async {
    final id = widget.orderId ?? _order?.id ?? widget.order?.id;
    if (id == null) return;
    final next = _load(id);
    setState(() => _future = next);
    await next;
  }

  Future<void> _updateStatus(String status, {String? note}) async {
    setState(() => _updating = true);
    try {
      await ref.read(merchantMarketRepositoryProvider).updateOrderStatus(
            orderId: order.id,
            status: status,
            note: note,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('تم تحديث الحالة إلى ${orderStatusLabel(status)}')),
      );
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تحديث الطلب: $error')),
      );
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _reject() async {
    final controller = TextEditingController();
    final reason = await showModalBottomSheet<String>(
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
              const Text('رفض الطلب',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'سبب الرفض',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                      child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('إلغاء'))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: FilledButton(
                          onPressed: () =>
                              Navigator.pop(context, controller.text),
                          child: const Text('تأكيد الرفض'))),
                ],
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(controller.dispose);
    if ((reason ?? '').trim().isEmpty) return;
    await _updateStatus('REJECTED', note: reason!.trim());
  }

  Future<void> _copyInvoice() async {
    await Clipboard.setData(ClipboardData(text: buildInvoiceText(order)));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ الفاتورة كنص')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final future = _future;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          toolbarHeight: 86,
          foregroundColor: Colors.white,
          backgroundColor: const Color(0xFF082B51),
          title: Text(
            _order == null ? 'تفاصيل الطلب' : 'طلب ${order.orderNumber}',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          actions: [
            IconButton(
              onPressed: _order == null ? null : _copyInvoice,
              icon: const Icon(Icons.receipt_long_outlined),
            ),
          ],
        ),
        body: future == null
            ? _body(order)
            : FutureBuilder<MerchantOrderModel>(
                future: future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done &&
                      _order == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError && _order == null) {
                    return _ErrorState(
                        error: snapshot.error, onRetry: _refresh);
                  }
                  final data = snapshot.data ?? _order;
                  if (data == null) return _ErrorState(onRetry: _refresh);
                  _order = data;
                  return _body(data);
                },
              ),
      ),
    );
  }

  Widget _body(MerchantOrderModel order) {
    final next = nextOrderStatus(order);
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _StatusHeader(order: order),
                const SizedBox(height: 12),
                _StatusTimeline(order: order),
                const SizedBox(height: 12),
                _InfoGrid(order: order),
                const SizedBox(height: 12),
                _ItemsCard(order: order),
                const SizedBox(height: 12),
                _SummaryCard(order: order),
                const SizedBox(height: 12),
                _InvoiceCard(order: order, onCopy: _copyInvoice),
                const SizedBox(height: 12),
                _HistoryCard(order: order),
                const SizedBox(height: 12),
                _NotesCard(order: order),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                  color: Color(0x16000000),
                  blurRadius: 18,
                  offset: Offset(0, -6))
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: order.customerPhone == null ? null : _showContact,
                  icon: const Icon(Icons.phone_outlined),
                  label: const Text('بيانات العميل'),
                ),
              ),
              const SizedBox(width: 10),
              if (order.canReject) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _updating ? null : _reject,
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('رفض'),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: FilledButton.icon(
                  onPressed: _updating || next == null
                      ? null
                      : () => _updateStatus(next),
                  icon: _updating
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.sync_rounded),
                  label:
                      Text(next == null ? 'لا إجراء' : orderStatusLabel(next)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showContact() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('بيانات العميل',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              _Line('الاسم', order.customerName),
              _Line('الهاتف', order.customerPhone ?? 'غير متوفر'),
              _Line('البريد', order.customerEmail ?? 'غير متوفر'),
              if (order.addressText != null)
                _Line('العنوان', order.addressText!),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({required this.order});
  final MerchantOrderModel order;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6417).withValues(alpha: .12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.assignment_turned_in_outlined,
                color: Color(0xFFFF6417)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.orderNumber,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(
                    '${order.itemsCount} قطعة • ${order.total.toStringAsFixed(0)} ${order.currency}'),
              ],
            ),
          ),
          Chip(label: Text(orderStatusLabel(order.status))),
        ],
      ),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline({required this.order});
  final MerchantOrderModel order;

  @override
  Widget build(BuildContext context) {
    final steps = order.needsDelivery
        ? ['PENDING', 'CONFIRMED', 'PREPARING', 'OUT_FOR_DELIVERY', 'COMPLETED']
        : [
            'PENDING',
            'CONFIRMED',
            'PREPARING',
            'READY_FOR_PICKUP',
            'COMPLETED'
          ];
    final current = steps.indexOf(order.status);
    return _SectionCard(
      title: 'مسار الطلب',
      icon: Icons.timeline_rounded,
      child: Row(
        children: List.generate(steps.length, (index) {
          final active = current >= index && current != -1;
          return Expanded(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: active
                      ? const Color(0xFFFF6417)
                      : const Color(0xFFE2E8F0),
                  child: Icon(active ? Icons.check : Icons.circle,
                      size: 15, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  orderStatusLabel(steps[index]),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.order});
  final MerchantOrderModel order;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'معلومات الطلب',
      icon: Icons.info_outline_rounded,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _InfoTile('العميل', order.customerName),
          _InfoTile('الهاتف', order.customerPhone ?? 'غير متوفر'),
          _InfoTile('طريقة التسليم', fulfillmentLabel(order.fulfillmentMethod)),
          _InfoTile('الفرع', order.branchName ?? 'غير محدد'),
          _InfoTile('المدينة', order.cityName ?? 'غير محددة'),
          _InfoTile('الدفع', paymentMethodLabel(order.paymentMethod)),
          _InfoTile('حالة الدفع', paymentStatusLabel(order.paymentStatus)),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile(this.title, this.value);
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  const _ItemsCard({required this.order});
  final MerchantOrderModel order;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'منتجات الطلب',
      icon: Icons.inventory_2_outlined,
      child: Column(
        children: [
          for (final item in order.items) ...[
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.build_circle_outlined),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name,
                          style: const TextStyle(fontWeight: FontWeight.w900)),
                      if (item.partNumber != null)
                        Text('رقم القطعة: ${item.partNumber}',
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                Text('×${item.quantity}',
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(width: 12),
                Text(item.total.toStringAsFixed(0),
                    style: const TextStyle(fontWeight: FontWeight.w900)),
              ],
            ),
            const Divider(height: 20),
          ],
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.order});
  final MerchantOrderModel order;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'ملخص المبلغ',
      icon: Icons.payments_outlined,
      child: Column(
        children: [
          _Line('المجموع الفرعي',
              '${order.subtotal.toStringAsFixed(0)} ${order.currency}'),
          _Line('الخصم',
              '${order.discount.toStringAsFixed(0)} ${order.currency}'),
          _Line('التوصيل',
              '${order.deliveryFee.toStringAsFixed(0)} ${order.currency}'),
          const Divider(),
          _Line(
              'الإجمالي', '${order.total.toStringAsFixed(0)} ${order.currency}',
              bold: true),
        ],
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({required this.order, required this.onCopy});
  final MerchantOrderModel order;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'الفاتورة',
      icon: Icons.receipt_long_outlined,
      trailing: TextButton.icon(
        onPressed: onCopy,
        icon: const Icon(Icons.copy_rounded),
        label: const Text('نسخ'),
      ),
      child: Column(
        children: [
          if (order.invoices.isEmpty)
            const Text(
                'سيتم إنشاء الفاتورة تلقائيًا عند إكمال الطلب، ويمكن نسخ فاتورة نصية مؤقتة من هذه الصفحة.'),
          for (final invoice in order.invoices) ...[
            _Line('رقم الفاتورة', invoice.invoiceNumber),
            _Line('الحالة', invoice.status),
            _Line('المبلغ',
                '${invoice.total.toStringAsFixed(0)} ${invoice.currency}'),
          ],
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.order});
  final MerchantOrderModel order;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'سجل حالة الطلب',
      icon: Icons.history_rounded,
      child: order.statusHistory.isEmpty
          ? const Text('لا يوجد سجل حالات حتى الآن.')
          : Column(
              children: [
                for (final history in order.statusHistory) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading:
                        const CircleAvatar(child: Icon(Icons.check_rounded)),
                    title: Text(orderStatusLabel(history.status),
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                    subtitle: Text([
                      if (history.changedByName != null)
                        'بواسطة: ${history.changedByName}',
                      if (history.note != null) history.note!,
                      if (history.createdAt != null)
                        history.createdAt!.toLocal().toString(),
                    ].join('\n')),
                  ),
                  const Divider(height: 8),
                ],
              ],
            ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.order});
  final MerchantOrderModel order;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'ملاحظات',
      icon: Icons.sticky_note_2_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Line('ملاحظة العميل', order.customerNote ?? 'لا توجد'),
          if (order.cancellationReason != null)
            _Line('سبب الإلغاء/الرفض', order.cancellationReason!, bold: true),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard(
      {required this.title,
      required this.icon,
      required this.child,
      this.trailing});
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFFF6417)),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w900))),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.title, this.value, {this.bold = false});
  final String title;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 130,
              child: Text(title,
                  style: const TextStyle(color: Color(0xFF64748B)))),
          Expanded(
              child: Text(value,
                  style: TextStyle(
                      fontWeight: bold ? FontWeight.w900 : FontWeight.w600))),
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
            const Text('تعذر تحميل تفاصيل الطلب',
                style: TextStyle(fontWeight: FontWeight.w900)),
            if (error != null) Text('$error', textAlign: TextAlign.center),
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
