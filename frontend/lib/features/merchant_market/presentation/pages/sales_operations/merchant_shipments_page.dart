import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/features/merchant_market/data/merchant_market_repository.dart';
import 'package:ghiyarak/features/merchant_market/data/models/merchant_shipment_model.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_bottom_navigation.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_management_scaffold.dart';

class MerchantShipmentsPage extends ConsumerStatefulWidget {
  const MerchantShipmentsPage({super.key});

  @override
  ConsumerState<MerchantShipmentsPage> createState() =>
      _MerchantShipmentsPageState();
}

class _MerchantShipmentsPageState extends ConsumerState<MerchantShipmentsPage> {
  final _searchController = TextEditingController();
  late Future<MerchantShipmentsResponse> _future;
  String _status = 'ALL';
  String _deliveryMethod = 'ALL';

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

  Future<MerchantShipmentsResponse> _load() {
    return ref.read(merchantMarketRepositoryProvider).getMerchantShipments(
          status: _status,
          query: _searchController.text,
          deliveryMethod: _deliveryMethod,
        );
  }

  void _reload() => setState(() => _future = _load());

  Future<void> _run(Future<void> Function() action, String success) async {
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(success)));
      _reload();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _updateStatus(MerchantShipment item, String status) async {
    final note = await _noteDialog(
      title: _statusLabel(status),
      label: status == 'FAILED' ? 'سبب فشل التسليم' : 'ملاحظة اختيارية',
      requiredNote: status == 'FAILED' || status == 'CANCELLED',
    );
    if (note == null) return;
    await _run(
      () => ref
          .read(merchantMarketRepositoryProvider)
          .updateMerchantShipmentStatus(
            id: item.id,
            status: status,
            note: note,
          ),
      'تم تحديث حالة الشحنة',
    );
  }

  Future<void> _assign(
      MerchantShipment item, MerchantShipmentsResponse data) async {
    final result = await showDialog<_AssignShipmentResult>(
      context: context,
      builder: (_) => _AssignShipmentDialog(shipment: item, data: data),
    );
    if (result == null) return;
    await _run(
      () => ref.read(merchantMarketRepositoryProvider).assignMerchantShipment(
            id: item.id,
            driverId: result.driverId,
            shippingCompanyId: result.companyId,
            trackingNumber: result.trackingNumber,
          ),
      'تم إسناد الشحنة',
    );
  }

  Future<void> _createShipment(MerchantShipmentsResponse data) async {
    final result = await showDialog<_CreateShipmentResult>(
      context: context,
      builder: (_) => _CreateShipmentDialog(data: data),
    );
    if (result == null) return;
    await _run(
      () => ref.read(merchantMarketRepositoryProvider).createMerchantShipment(
            orderId: result.orderId,
            deliveryMethodId: result.deliveryMethodId,
            driverId: result.driverId,
            shippingCompanyId: result.companyId,
            trackingNumber: result.trackingNumber,
            deliveryFee: result.deliveryFee,
          ),
      'تم إنشاء الشحنة',
    );
  }

  Future<void> _reschedule(MerchantShipment item) async {
    final result = await showDialog<_RescheduleShipmentResult>(
      context: context,
      builder: (_) => const _RescheduleShipmentDialog(),
    );
    if (result == null) return;
    await _run(
      () =>
          ref.read(merchantMarketRepositoryProvider).rescheduleMerchantShipment(
                id: item.id,
                scheduledAt: result.scheduledAt,
                note: result.note,
              ),
      'تمت إعادة جدولة الشحنة',
    );
  }

  Future<void> _openDetails(MerchantShipment item) async {
    try {
      final detail = await ref
          .read(merchantMarketRepositoryProvider)
          .getMerchantShipmentDetail(item.id);
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => Directionality(
          textDirection: TextDirection.rtl,
          child: _ShipmentDetailsSheet(item: detail),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<String?> _noteDialog({
    required String title,
    required String label,
    bool requiredNote = false,
  }) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (requiredNote && text.isEmpty) return;
              Navigator.pop(context, text);
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MerchantShipmentsResponse>(
      future: _future,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final items = data?.shipments ?? const <MerchantShipment>[];
        return MerchantManagementScaffold(
          title: 'الشحن والتوصيل',
          subtitle:
              'إدارة شحنات المتجر من إنشاء الشحنة حتى التسليم أو إعادة الجدولة.',
          currentTab: MerchantNavigationTab.settings,
          onRefresh: () async => _reload(),
          children: [
            _Toolbar(
              searchController: _searchController,
              status: _status,
              deliveryMethod: _deliveryMethod,
              onStatusChanged: (value) {
                _status = value;
                _reload();
              },
              onDeliveryMethodChanged: (value) {
                _deliveryMethod = value;
                _reload();
              },
              onSearch: _reload,
              onCreate: data == null ? null : () => _createShipment(data),
            ),
            const SizedBox(height: 12),
            if (snapshot.connectionState != ConnectionState.done)
              const Center(
                  child: Padding(
                      padding: EdgeInsets.all(36),
                      child: CircularProgressIndicator()))
            else if (snapshot.hasError)
              MerchantStateCard(
                icon: Icons.local_shipping_outlined,
                title: 'تعذر تحميل الشحنات',
                message: snapshot.error.toString(),
                actionLabel: 'إعادة المحاولة',
                onAction: _reload,
              )
            else if (data == null)
              const MerchantStateCard(
                icon: Icons.local_shipping_outlined,
                title: 'لا توجد بيانات',
                message: 'لم يتم استقبال بيانات الشحن من الخادم.',
              )
            else ...[
              _SummaryGrid(summary: data.summary),
              const SizedBox(height: 14),
              if (items.isEmpty)
                const MerchantStateCard(
                  icon: Icons.local_shipping_outlined,
                  title: 'لا توجد شحنات',
                  message:
                      'أنشئ شحنة من الطلبات الجاهزة للتوصيل أو غيّر الفلاتر الحالية.',
                )
              else
                ...items.map(
                  (item) => _ShipmentCard(
                    item: item,
                    onDetails: () => _openDetails(item),
                    onAssign: () => _assign(item, data),
                    onReschedule: () => _reschedule(item),
                    onUpdate: (status) => _updateStatus(item, status),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.searchController,
    required this.status,
    required this.deliveryMethod,
    required this.onStatusChanged,
    required this.onDeliveryMethodChanged,
    required this.onSearch,
    required this.onCreate,
  });

  final TextEditingController searchController;
  final String status;
  final String deliveryMethod;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onDeliveryMethodChanged;
  final VoidCallback onSearch;
  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    return MerchantPanel(
      child: Column(
        children: [
          TextField(
            controller: searchController,
            onSubmitted: (_) => onSearch(),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'ابحث برقم الطلب، العميل، الهاتف، السائق أو رقم التتبع',
              suffixIcon: IconButton(
                  onPressed: onSearch, icon: const Icon(Icons.arrow_forward)),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _ChoiceFilter(
                value: status,
                values: const {
                  'ALL': 'كل الحالات',
                  'CREATED': 'منشأة',
                  'ASSIGNED': 'مسندة',
                  'OUT_FOR_DELIVERY': 'خارج للتوصيل',
                  'DELIVERED': 'تم التسليم',
                  'FAILED': 'فشل التسليم',
                  'CANCELLED': 'ملغاة',
                },
                onChanged: onStatusChanged,
              ),
              _ChoiceFilter(
                value: deliveryMethod,
                values: const {
                  'ALL': 'كل الطرق',
                  'DELIVERY': 'توصيل',
                  'PICKUP': 'استلام من الفرع',
                },
                onChanged: onDeliveryMethodChanged,
              ),
              FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add_road_outlined),
                label: const Text('إنشاء شحنة'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChoiceFilter extends StatelessWidget {
  const _ChoiceFilter(
      {required this.value, required this.values, required this.onChanged});
  final String value;
  final Map<String, String> values;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: value,
      items: values.entries
          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
          .toList(),
      onChanged: (v) => v == null ? null : onChanged(v),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.summary});
  final MerchantShipmentSummary summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: MerchantMetricTile(
                    icon: Icons.inventory_2_outlined,
                    label: 'إجمالي الشحنات',
                    value: '${summary.total}')),
            const SizedBox(width: 10),
            Expanded(
                child: MerchantMetricTile(
                    icon: Icons.delivery_dining_outlined,
                    label: 'خارج للتوصيل',
                    value: '${summary.outForDelivery}')),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: MerchantMetricTile(
                    icon: Icons.verified_outlined,
                    label: 'تم التسليم',
                    value: '${summary.delivered}')),
            const SizedBox(width: 10),
            Expanded(
                child: MerchantMetricTile(
                    icon: Icons.warning_amber_rounded,
                    label: 'فشل التسليم',
                    value: '${summary.failed}')),
          ],
        ),
      ],
    );
  }
}

class _ShipmentCard extends StatelessWidget {
  const _ShipmentCard({
    required this.item,
    required this.onDetails,
    required this.onAssign,
    required this.onReschedule,
    required this.onUpdate,
  });

  final MerchantShipment item;
  final VoidCallback onDetails;
  final VoidCallback onAssign;
  final VoidCallback onReschedule;
  final ValueChanged<String> onUpdate;

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
                        fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ),
                _StatusPill(status: item.status),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                if (item.trackingNumber.isNotEmpty)
                  _InfoChip(icon: Icons.qr_code, label: item.trackingNumber),
                if (item.customerName.isNotEmpty)
                  _InfoChip(
                      icon: Icons.person_outline, label: item.customerName),
                if (item.customerPhone.isNotEmpty)
                  _InfoChip(
                      icon: Icons.phone_outlined, label: item.customerPhone),
                if (item.driverName.isNotEmpty)
                  _InfoChip(
                      icon: Icons.delivery_dining, label: item.driverName),
                if (item.companyName.isNotEmpty)
                  _InfoChip(
                      icon: Icons.business_outlined, label: item.companyName),
                if (item.cityName.isNotEmpty)
                  _InfoChip(
                      icon: Icons.location_city_outlined, label: item.cityName),
              ],
            ),
            const SizedBox(height: 8),
            Text('رسوم التوصيل: ${_money(item.deliveryFee, item.currency)}',
                style: const TextStyle(color: Color(0xFF687686))),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                    onPressed: onDetails,
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text('التفاصيل')),
                OutlinedButton.icon(
                    onPressed: item.isFinal ? null : onAssign,
                    icon: const Icon(Icons.assignment_ind_outlined),
                    label: const Text('إسناد')),
                OutlinedButton.icon(
                    onPressed: item.isFinal ? null : onReschedule,
                    icon: const Icon(Icons.event_repeat_outlined),
                    label: const Text('إعادة جدولة')),
                OutlinedButton.icon(
                    onPressed: item.isFinal
                        ? null
                        : () => onUpdate('OUT_FOR_DELIVERY'),
                    icon: const Icon(Icons.delivery_dining_outlined),
                    label: const Text('خارج للتوصيل')),
                FilledButton.icon(
                    onPressed:
                        item.isFinal ? null : () => onUpdate('DELIVERED'),
                    icon: const Icon(Icons.done_all_rounded),
                    label: const Text('تم التسليم')),
                OutlinedButton.icon(
                    onPressed: item.isFinal ? null : () => onUpdate('FAILED'),
                    icon: const Icon(Icons.report_problem_outlined),
                    label: const Text('فشل')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) =>
      Chip(avatar: Icon(icon, size: 16), label: Text(label));
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: const Color(0xFFFFF4E8),
          borderRadius: BorderRadius.circular(999)),
      child: Text(_statusLabel(status),
          style: const TextStyle(
              color: Color(0xFFFF7900), fontWeight: FontWeight.w800)),
    );
  }
}

class _CreateShipmentDialog extends StatefulWidget {
  const _CreateShipmentDialog({required this.data});
  final MerchantShipmentsResponse data;

  @override
  State<_CreateShipmentDialog> createState() => _CreateShipmentDialogState();
}

class _CreateShipmentDialogState extends State<_CreateShipmentDialog> {
  String? orderId;
  String? deliveryMethodId;
  String? driverId;
  String? companyId;
  final tracking = TextEditingController();
  final fee = TextEditingController();

  @override
  void dispose() {
    tracking.dispose();
    fee.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إنشاء شحنة جديدة'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LookupDropdown(
                label: 'الطلب الجاهز للشحن',
                value: orderId,
                items: widget.data.ordersReadyForShipment,
                onChanged: (v) => setState(() => orderId = v)),
            _LookupDropdown(
                label: 'طريقة التسليم',
                value: deliveryMethodId,
                items: widget.data.deliveryMethods,
                onChanged: (v) => setState(() => deliveryMethodId = v)),
            _LookupDropdown(
                label: 'السائق',
                value: driverId,
                items: widget.data.drivers,
                onChanged: (v) => setState(() => driverId = v)),
            _LookupDropdown(
                label: 'شركة الشحن',
                value: companyId,
                items: widget.data.shippingCompanies,
                onChanged: (v) => setState(() => companyId = v)),
            TextField(
                controller: tracking,
                decoration: const InputDecoration(labelText: 'رقم التتبع')),
            TextField(
                controller: fee,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'رسوم التوصيل')),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء')),
        FilledButton(
          onPressed: orderId == null
              ? null
              : () => Navigator.pop(
                  context,
                  _CreateShipmentResult(
                      orderId: orderId!,
                      deliveryMethodId: deliveryMethodId,
                      driverId: driverId,
                      companyId: companyId,
                      trackingNumber: tracking.text.trim(),
                      deliveryFee: num.tryParse(fee.text.trim()))),
          child: const Text('إنشاء'),
        ),
      ],
    );
  }
}

class _AssignShipmentDialog extends StatefulWidget {
  const _AssignShipmentDialog({required this.shipment, required this.data});
  final MerchantShipment shipment;
  final MerchantShipmentsResponse data;

  @override
  State<_AssignShipmentDialog> createState() => _AssignShipmentDialogState();
}

class _AssignShipmentDialogState extends State<_AssignShipmentDialog> {
  String? driverId;
  String? companyId;
  late final TextEditingController tracking;

  @override
  void initState() {
    super.initState();
    tracking = TextEditingController(text: widget.shipment.trackingNumber);
  }

  @override
  void dispose() {
    tracking.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إسناد الشحنة'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LookupDropdown(
              label: 'السائق',
              value: driverId,
              items: widget.data.drivers,
              onChanged: (v) => setState(() => driverId = v)),
          _LookupDropdown(
              label: 'شركة الشحن',
              value: companyId,
              items: widget.data.shippingCompanies,
              onChanged: (v) => setState(() => companyId = v)),
          TextField(
              controller: tracking,
              decoration: const InputDecoration(labelText: 'رقم التتبع')),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء')),
        FilledButton(
            onPressed: () => Navigator.pop(
                context,
                _AssignShipmentResult(
                    driverId: driverId,
                    companyId: companyId,
                    trackingNumber: tracking.text.trim())),
            child: const Text('حفظ')),
      ],
    );
  }
}

class _RescheduleShipmentDialog extends StatefulWidget {
  const _RescheduleShipmentDialog();
  @override
  State<_RescheduleShipmentDialog> createState() =>
      _RescheduleShipmentDialogState();
}

class _RescheduleShipmentDialogState extends State<_RescheduleShipmentDialog> {
  final scheduledAt = TextEditingController();
  final note = TextEditingController();
  @override
  void dispose() {
    scheduledAt.dispose();
    note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إعادة جدولة التسليم'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(
            controller: scheduledAt,
            decoration: const InputDecoration(
                labelText: 'موعد التسليم الجديد مثال 2026-06-25 10:00')),
        TextField(
            controller: note,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'ملاحظة')),
      ]),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء')),
        FilledButton(
            onPressed: () {
              final value = scheduledAt.text.trim();
              if (value.isEmpty) return;
              Navigator.pop(
                  context,
                  _RescheduleShipmentResult(
                      scheduledAt: value, note: note.text.trim()));
            },
            child: const Text('حفظ')),
      ],
    );
  }
}

class _LookupDropdown extends StatelessWidget {
  const _LookupDropdown(
      {required this.label,
      required this.value,
      required this.items,
      required this.onChanged});
  final String label;
  final String? value;
  final List<MerchantShipmentLookup> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      isExpanded: true,
      items: items
          .map((item) => DropdownMenuItem(
              value: item.id,
              child: Text(item.subtitle.isEmpty
                  ? item.title
                  : '${item.title} - ${item.subtitle}')))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _ShipmentDetailsSheet extends StatelessWidget {
  const _ShipmentDetailsSheet({required this.item});
  final MerchantShipment item;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.45,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(16),
          children: [
            Row(children: [
              Expanded(
                  child: Text(
                      'تفاصيل الشحنة ${item.trackingNumber.isEmpty ? item.id : item.trackingNumber}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w900))),
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close))
            ]),
            const SizedBox(height: 10),
            _DetailsLine(label: 'الحالة', value: _statusLabel(item.status)),
            _DetailsLine(label: 'رقم الطلب', value: item.orderNumber),
            _DetailsLine(label: 'العميل', value: item.customerName),
            _DetailsLine(label: 'الهاتف', value: item.customerPhone),
            _DetailsLine(label: 'العنوان', value: item.customerAddress),
            _DetailsLine(label: 'المدينة', value: item.cityName),
            _DetailsLine(label: 'الفرع', value: item.branchName),
            _DetailsLine(label: 'طريقة التسليم', value: item.deliveryMethod),
            _DetailsLine(label: 'السائق', value: item.driverName),
            _DetailsLine(label: 'شركة الشحن', value: item.companyName),
            _DetailsLine(
                label: 'رسوم التوصيل',
                value: _money(item.deliveryFee, item.currency)),
            const SizedBox(height: 14),
            const Text('مسار التتبع',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 8),
            if (item.tracking.isEmpty)
              const Text('لا يوجد سجل تتبع بعد.',
                  style: TextStyle(color: Color(0xFF687686)))
            else
              ...item.tracking.map((track) => ListTile(
                    leading: const Icon(Icons.radio_button_checked,
                        color: Color(0xFFFF7900)),
                    title: Text(_statusLabel(track.status),
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text([track.note, track.createdAt]
                        .where((e) => e.isNotEmpty)
                        .join('\n')),
                  )),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(
                    text:
                        'الشحنة: ${item.trackingNumber}\nالطلب: ${item.orderNumber}\nالحالة: ${_statusLabel(item.status)}\nالعميل: ${item.customerName}\nالهاتف: ${item.customerPhone}\nالعنوان: ${item.customerAddress}'));
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم نسخ بيانات الشحنة')));
              },
              icon: const Icon(Icons.copy_all_outlined),
              label: const Text('نسخ بيانات الشحنة'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailsLine extends StatelessWidget {
  const _DetailsLine({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
              width: 105,
              child: Text(label,
                  style: const TextStyle(
                      color: Color(0xFF687686), fontWeight: FontWeight.w700))),
          Expanded(
              child: Text(value.isEmpty ? '-' : value,
                  style: const TextStyle(fontWeight: FontWeight.w800))),
        ]),
      );
}

class _CreateShipmentResult {
  const _CreateShipmentResult(
      {required this.orderId,
      this.deliveryMethodId,
      this.driverId,
      this.companyId,
      this.trackingNumber,
      this.deliveryFee});
  final String orderId;
  final String? deliveryMethodId;
  final String? driverId;
  final String? companyId;
  final String? trackingNumber;
  final num? deliveryFee;
}

class _AssignShipmentResult {
  const _AssignShipmentResult(
      {this.driverId, this.companyId, this.trackingNumber});
  final String? driverId;
  final String? companyId;
  final String? trackingNumber;
}

class _RescheduleShipmentResult {
  const _RescheduleShipmentResult({required this.scheduledAt, this.note});
  final String scheduledAt;
  final String? note;
}

String _money(num value, String currency) =>
    '${value.toStringAsFixed(0)} $currency';

String _statusLabel(String status) {
  return switch (status) {
    'CREATED' => 'منشأة',
    'ASSIGNED' => 'مسندة',
    'PICKED_UP' => 'تم الاستلام من المتجر',
    'OUT_FOR_DELIVERY' => 'خارج للتوصيل',
    'DELIVERED' => 'تم التسليم',
    'FAILED' => 'فشل التسليم',
    'CANCELLED' => 'ملغاة',
    _ => status.isEmpty ? 'غير محددة' : status,
  };
}
