import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/features/merchant_market/data/merchant_market_repository.dart';
import 'package:ghiyarak/features/merchant_market/data/models/merchant_returns_disputes_model.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_management_scaffold.dart';

class MerchantReturnsPage extends ConsumerStatefulWidget {
  const MerchantReturnsPage({super.key});

  @override
  ConsumerState<MerchantReturnsPage> createState() =>
      _MerchantReturnsPageState();
}

class _MerchantReturnsPageState extends ConsumerState<MerchantReturnsPage> {
  late Future<MerchantReturnsResponse> _future;
  final _searchController = TextEditingController();
  String _status = 'ALL';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<MerchantReturnsResponse> _load() {
    return ref.read(merchantMarketRepositoryProvider).getMerchantReturns(
          status: _status == 'ALL' ? null : _status,
          query: _searchController.text,
        );
  }

  void _refresh() => setState(() => _future = _load());

  Future<void> _action(Future<void> Function() run, String message) async {
    try {
      await run();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<String?> _noteDialog(String title,
      {String hint = 'اكتب الملاحظة أو السبب'}) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: InputDecoration(
                border: const OutlineInputBorder(), hintText: hint),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء')),
            FilledButton(
                onPressed: () => Navigator.pop(context, controller.text.trim()),
                child: const Text('تأكيد')),
          ],
        ),
      ),
    );
  }

  Future<void> _approve(MerchantReturnRequest item) async {
    final note = await _noteDialog('قبول المرتجع',
        hint: 'ملاحظة للتوثيق، مثال: مقبول حسب سياسة الإرجاع');
    if (note == null) return;
    await _action(
      () => ref.read(merchantMarketRepositoryProvider).decideMerchantReturn(
            id: item.id,
            decision: 'APPROVED',
            note: note,
          ),
      'تم قبول المرتجع',
    );
  }

  Future<void> _reject(MerchantReturnRequest item) async {
    final note = await _noteDialog('رفض المرتجع',
        hint: 'سبب الرفض مطلوب للتوثيق وإبلاغ العميل');
    if (note == null || note.isEmpty) return;
    await _action(
      () => ref.read(merchantMarketRepositoryProvider).decideMerchantReturn(
            id: item.id,
            decision: 'REJECTED',
            note: note,
          ),
      'تم رفض المرتجع',
    );
  }

  Future<void> _receive(MerchantReturnRequest item) async {
    final note = await _noteDialog('استلام المنتج المرتجع',
        hint: 'حالة المنتج عند الاستلام');
    if (note == null) return;
    await _action(
      () => ref.read(merchantMarketRepositoryProvider).receiveMerchantReturn(
            id: item.id,
            note: note,
            restock: true,
          ),
      'تم تسجيل استلام المرتجع وإرجاعه للمخزون',
    );
  }

  Future<void> _refund(MerchantReturnRequest item) async {
    final note =
        await _noteDialog('تنفيذ الاسترداد المالي', hint: 'ملاحظة الاسترداد');
    if (note == null) return;
    await _action(
      () => ref
          .read(merchantMarketRepositoryProvider)
          .refundMerchantReturn(id: item.id, note: note),
      'تم تسجيل الاسترداد المالي',
    );
  }

  void _showDetails(MerchantReturnRequest item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: .82,
          minChildSize: .5,
          maxChildSize: .96,
          builder: (context, controller) => ListView(
            controller: controller,
            padding: const EdgeInsets.all(18),
            children: [
              _sheetHeader('تفاصيل المرتجع', item.orderNumber,
                  Icons.assignment_return_outlined),
              const SizedBox(height: 12),
              _infoPanel([
                _Info('الحالة', _returnStatusLabel(item.status)),
                _Info('العميل', item.customerName),
                _Info('الهاتف',
                    item.customerPhone.isEmpty ? '-' : item.customerPhone),
                _Info('حالة الطلب',
                    item.orderStatus.isEmpty ? '-' : item.orderStatus),
                _Info('حالة الدفع',
                    item.paymentStatus.isEmpty ? '-' : item.paymentStatus),
                _Info('المبلغ', '${item.amount} ${item.currency}'),
                _Info('السبب', item.reason),
                if (item.merchantNote.isNotEmpty)
                  _Info('ملاحظة التاجر', item.merchantNote),
              ]),
              const SizedBox(height: 12),
              _itemsPanel(item.items, item.currency),
              const SizedBox(height: 12),
              _timelinePanel(item.timeline,
                  fallbackStatus: item.status, fallbackDate: item.updatedAt),
              const SizedBox(height: 12),
              _returnActions(item),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MerchantReturnsResponse>(
      future: _future,
      builder: (context, snapshot) {
        final response = snapshot.data;
        final items = response?.items ?? const <MerchantReturnRequest>[];
        final summary = response?.summary;
        return MerchantManagementScaffold(
          title: 'المرتجعات',
          subtitle:
              'إدارة دورة الإرجاع كاملة: قبول، رفض، استلام، إرجاع للمخزون، واسترداد مالي.',
          onRefresh: () async => _refresh(),
          children: [
            if (snapshot.connectionState != ConnectionState.done)
              const Center(
                  child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator()))
            else if (snapshot.hasError)
              MerchantStateCard(
                icon: Icons.error_outline,
                title: 'تعذر تحميل المرتجعات',
                message: snapshot.error.toString(),
                actionLabel: 'إعادة المحاولة',
                onAction: _refresh,
              )
            else ...[
              if (summary != null) _summary(summary),
              const SizedBox(height: 12),
              _filters(),
              const SizedBox(height: 12),
              if (items.isEmpty)
                const MerchantStateCard(
                  icon: Icons.assignment_return_outlined,
                  title: 'لا توجد مرتجعات',
                  message:
                      'طلبات الإرجاع التي يرسلها العملاء ستظهر هنا للمراجعة والتوثيق.',
                )
              else
                ...items.map((item) => _ReturnCard(
                      item: item,
                      onDetails: () => _showDetails(item),
                      onApprove: () => _approve(item),
                      onReject: () => _reject(item),
                      onReceive: () => _receive(item),
                      onRefund: () => _refund(item),
                    )),
            ],
          ],
        );
      },
    );
  }

  Widget _summary(MerchantReturnsSummary summary) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: MerchantMetricTile(
                    icon: Icons.assignment_return_outlined,
                    label: 'الإجمالي',
                    value: '${summary.total}')),
            const SizedBox(width: 10),
            Expanded(
                child: MerchantMetricTile(
                    icon: Icons.pending_actions_outlined,
                    label: 'قيد المراجعة',
                    value: '${summary.pending}')),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: MerchantMetricTile(
                    icon: Icons.check_circle_outline,
                    label: 'مقبولة',
                    value: '${summary.approved}')),
            const SizedBox(width: 10),
            Expanded(
                child: MerchantMetricTile(
                    icon: Icons.payments_outlined,
                    label: 'مسترد',
                    value: '${summary.refundedAmount} ${summary.currency}')),
          ],
        ),
      ],
    );
  }

  Widget _filters() {
    return MerchantPanel(
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _refresh(),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'بحث برقم الطلب أو العميل أو السبب',
              suffixIcon:
                  IconButton(onPressed: _refresh, icon: const Icon(Icons.tune)),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _status,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'فلترة حالة المرتجع',
              prefixIcon: const Icon(Icons.filter_alt_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
            items: const [
              DropdownMenuItem(value: 'ALL', child: Text('الكل')),
              DropdownMenuItem(value: 'PENDING', child: Text('قيد المراجعة')),
              DropdownMenuItem(value: 'APPROVED', child: Text('مقبول')),
              DropdownMenuItem(value: 'RECEIVED', child: Text('مستلم')),
              DropdownMenuItem(value: 'PAID', child: Text('مسترد')),
              DropdownMenuItem(value: 'REJECTED', child: Text('مرفوض')),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _status = value;
                _future = _load();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _returnActions(MerchantReturnRequest item) {
    return Column(
      children: [
        if (item.status == 'PENDING')
          Row(children: [
            Expanded(
                child: OutlinedButton.icon(
                    onPressed: () => _reject(item),
                    icon: const Icon(Icons.close),
                    label: const Text('رفض'))),
            const SizedBox(width: 8),
            Expanded(
                child: FilledButton.icon(
                    onPressed: () => _approve(item),
                    icon: const Icon(Icons.check),
                    label: const Text('قبول'))),
          ]),
        if (item.status == 'APPROVED')
          FilledButton.icon(
              onPressed: () => _receive(item),
              icon: const Icon(Icons.inventory_2_outlined),
              label: const Text('تسجيل استلام المنتج المرتجع')),
        if (item.status == 'RECEIVED')
          FilledButton.icon(
              onPressed: () => _refund(item),
              icon: const Icon(Icons.payments_outlined),
              label: const Text('تنفيذ الاسترداد المالي')),
      ],
    );
  }
}

class _ReturnCard extends StatelessWidget {
  const _ReturnCard(
      {required this.item,
      required this.onDetails,
      required this.onApprove,
      required this.onReject,
      required this.onReceive,
      required this.onRefund});

  final MerchantReturnRequest item;
  final VoidCallback onDetails;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onReceive;
  final VoidCallback onRefund;

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
                Expanded(
                    child: Text(
                        'طلب ${item.orderNumber.isEmpty ? item.id : item.orderNumber}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w900))),
                _statusChip(_returnStatusLabel(item.status),
                    _returnStatusColor(item.status)),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              Chip(label: Text(item.customerName)),
              Chip(label: Text('${item.amount} ${item.currency}')),
              if (item.items.isNotEmpty)
                Chip(label: Text('${item.items.length} منتجات')),
            ]),
            const SizedBox(height: 8),
            Text(item.reason,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF687686), height: 1.45)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: OutlinedButton.icon(
                      onPressed: onDetails,
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('التفاصيل'))),
              const SizedBox(width: 8),
              if (item.status == 'PENDING')
                Expanded(
                    child: OutlinedButton.icon(
                        onPressed: onReject,
                        icon: const Icon(Icons.close),
                        label: const Text('رفض'))),
              if (item.status == 'PENDING') const SizedBox(width: 8),
              if (item.status == 'PENDING')
                Expanded(
                    child: FilledButton.icon(
                        onPressed: onApprove,
                        icon: const Icon(Icons.check),
                        label: const Text('قبول'))),
              if (item.status == 'APPROVED')
                Expanded(
                    child: FilledButton.icon(
                        onPressed: onReceive,
                        icon: const Icon(Icons.inventory),
                        label: const Text('استلام'))),
              if (item.status == 'RECEIVED')
                Expanded(
                    child: FilledButton.icon(
                        onPressed: onRefund,
                        icon: const Icon(Icons.payments),
                        label: const Text('استرداد'))),
            ]),
          ],
        ),
      ),
    );
  }
}

Widget _sheetHeader(String title, String subtitle, IconData icon) =>
    Row(children: [
      CircleAvatar(
          backgroundColor: const Color(0xFFFFF3E8),
          child: Icon(icon, color: const Color(0xFFFF7900))),
      const SizedBox(width: 10),
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
        Text(subtitle.isEmpty ? '-' : subtitle,
            style: const TextStyle(color: Color(0xFF687686))),
      ])),
    ]);

class _Info {
  const _Info(this.label, this.value);
  final String label;
  final String value;
}

Widget _infoPanel(List<_Info> rows) => MerchantPanel(
        child: Column(children: [
      for (final row in rows)
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(
                  width: 110,
                  child: Text(row.label,
                      style: const TextStyle(
                          color: Color(0xFF687686),
                          fontWeight: FontWeight.w700))),
              Expanded(
                  child: Text(row.value.isEmpty ? '-' : row.value,
                      style: const TextStyle(fontWeight: FontWeight.w800))),
            ])),
    ]));

Widget _itemsPanel(List<MerchantReturnItem> items, String currency) =>
    MerchantPanel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('المنتجات المرتجعة',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
      const SizedBox(height: 8),
      if (items.isEmpty)
        const Text('لم يتم تحديد منتجات مرتبطة.',
            style: TextStyle(color: Color(0xFF687686)))
      else
        for (final item in items)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(item.productName,
                style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text('الكمية: ${item.quantity}'),
            trailing: Text('${item.totalAmount} $currency',
                style: const TextStyle(fontWeight: FontWeight.w900)),
          ),
    ]));

Widget _timelinePanel(List<MerchantCaseTimelineEntry> timeline,
        {required String fallbackStatus, required String fallbackDate}) =>
    MerchantPanel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('السجل الزمني',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
      const SizedBox(height: 8),
      if (timeline.isEmpty)
        ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.history),
            title: Text(_returnStatusLabel(fallbackStatus)),
            subtitle:
                Text(fallbackDate.isEmpty ? 'لا يوجد تاريخ' : fallbackDate))
      else
        for (final e in timeline)
          ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.history),
              title: Text(e.note.isEmpty ? e.status : e.note),
              subtitle: Text('${e.actorName} • ${e.createdAt}')),
    ]));

Widget _statusChip(String text, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(20)),
      child: Text(text,
          style: TextStyle(color: color, fontWeight: FontWeight.w900)),
    );

String _returnStatusLabel(String status) => switch (status) {
      'PENDING' => 'قيد المراجعة',
      'APPROVED' => 'مقبول',
      'RECEIVED' => 'تم الاستلام',
      'REJECTED' => 'مرفوض',
      'PAID' => 'تم الاسترداد',
      'REFUNDED' => 'تم الاسترداد',
      _ => status.isEmpty ? 'غير محدد' : status,
    };

Color _returnStatusColor(String status) => switch (status) {
      'PENDING' => Colors.orange,
      'APPROVED' => Colors.blue,
      'RECEIVED' => Colors.purple,
      'PAID' || 'REFUNDED' => Colors.green,
      'REJECTED' => Colors.red,
      _ => Colors.blueGrey,
    };
