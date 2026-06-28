import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/features/merchant_market/data/merchant_market_repository.dart';
import 'package:ghiyarak/features/merchant_market/data/models/merchant_returns_disputes_model.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_management_scaffold.dart';

class MerchantDisputesPage extends ConsumerStatefulWidget {
  const MerchantDisputesPage({super.key});

  @override
  ConsumerState<MerchantDisputesPage> createState() =>
      _MerchantDisputesPageState();
}

class _MerchantDisputesPageState extends ConsumerState<MerchantDisputesPage> {
  late Future<MerchantDisputesResponse> _future;
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

  Future<MerchantDisputesResponse> _load() {
    return ref.read(merchantMarketRepositoryProvider).getMerchantDisputes(
          status: _status == 'ALL' ? null : _status,
          query: _searchController.text,
        );
  }

  void _refresh() => setState(() => _future = _load());

  Future<void> _run(Future<void> Function() action, String message) async {
    try {
      await action();
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
      {String hint = 'اكتب الملاحظة'}) async {
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
                child: const Text('حفظ')),
          ],
        ),
      ),
    );
  }

  Future<void> _statusAction(MerchantDisputeCase item, String status) async {
    final note = await _noteDialog(_disputeStatusLabel(status),
        hint: 'ملاحظة داخلية أو رد مختصر');
    if (note == null) return;
    await _run(
      () => ref
          .read(merchantMarketRepositoryProvider)
          .updateMerchantDisputeStatus(id: item.id, status: status, note: note),
      'تم تحديث حالة النزاع',
    );
  }

  Future<void> _addMessage(MerchantDisputeCase item) async {
    final message = await _noteDialog('إضافة رد على النزاع',
        hint: 'اكتب رد التاجر للعميل أو للدعم');
    if (message == null || message.isEmpty) return;
    await _run(
      () => ref
          .read(merchantMarketRepositoryProvider)
          .addMerchantDisputeMessage(id: item.id, message: message),
      'تمت إضافة الرد',
    );
  }

  Future<void> _resolve(MerchantDisputeCase item, String resolution) async {
    final note = await _noteDialog(
      resolution == 'MERCHANT_ACCEPTED'
          ? 'حل النزاع لصالح العميل'
          : 'رفض مطالبة العميل',
      hint: 'اكتب قرار النزاع النهائي بوضوح',
    );
    if (note == null || note.isEmpty) return;
    await _run(
      () => ref.read(merchantMarketRepositoryProvider).resolveMerchantDispute(
          id: item.id, resolution: resolution, note: note),
      'تم إغلاق النزاع بالقرار',
    );
  }

  void _details(MerchantDisputeCase item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: .86,
          maxChildSize: .96,
          minChildSize: .5,
          builder: (context, controller) => ListView(
            controller: controller,
            padding: const EdgeInsets.all(18),
            children: [
              _sheetHeader(
                  'تفاصيل النزاع', item.reasonCode, Icons.gavel_outlined),
              const SizedBox(height: 12),
              _infoPanel([
                _Info('الحالة', _disputeStatusLabel(item.status)),
                _Info('الأولوية', _priorityLabel(item.priority)),
                _Info('العميل', item.customerName),
                _Info('الهاتف',
                    item.customerPhone.isEmpty ? '-' : item.customerPhone),
                _Info('رقم الطلب',
                    item.orderNumber.isEmpty ? '-' : item.orderNumber),
                _Info('الوصف', item.description),
                if (item.resolutionNote.isNotEmpty)
                  _Info('قرار النزاع', item.resolutionNote),
              ]),
              const SizedBox(height: 12),
              _messagesPanel(item.messages),
              const SizedBox(height: 12),
              _timelinePanel(item.timeline,
                  fallbackStatus: item.status, fallbackDate: item.updatedAt),
              const SizedBox(height: 12),
              _actions(item),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MerchantDisputesResponse>(
      future: _future,
      builder: (context, snapshot) {
        final response = snapshot.data;
        final items = response?.items ?? const <MerchantDisputeCase>[];
        return MerchantManagementScaffold(
          title: 'الشكاوى والنزاعات',
          subtitle:
              'متابعة النزاعات، الرد عليها، توثيق القرار، وإغلاقها بشكل منظم.',
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
                title: 'تعذر تحميل النزاعات',
                message: snapshot.error.toString(),
                actionLabel: 'إعادة المحاولة',
                onAction: _refresh,
              )
            else ...[
              if (response != null) _summary(response.summary),
              const SizedBox(height: 12),
              _filters(),
              const SizedBox(height: 12),
              if (items.isEmpty)
                const MerchantStateCard(
                  icon: Icons.gavel_outlined,
                  title: 'لا توجد نزاعات',
                  message:
                      'الشكاوى المرتبطة بمتجرك ستظهر هنا لمراجعتها ومعالجتها من مكان واحد.',
                )
              else
                ...items.map((item) => _DisputeCard(
                      item: item,
                      onDetails: () => _details(item),
                      onMessage: () => _addMessage(item),
                    )),
            ],
          ],
        );
      },
    );
  }

  Widget _summary(MerchantDisputesSummary summary) => Column(children: [
        Row(children: [
          Expanded(
              child: MerchantMetricTile(
                  icon: Icons.report_problem_outlined,
                  label: 'مفتوحة',
                  value: '${summary.open}')),
          const SizedBox(width: 10),
          Expanded(
              child: MerchantMetricTile(
                  icon: Icons.manage_search_outlined,
                  label: 'قيد المراجعة',
                  value: '${summary.underReview}')),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: MerchantMetricTile(
                  icon: Icons.verified_outlined,
                  label: 'محلولة',
                  value: '${summary.resolved}')),
          const SizedBox(width: 10),
          Expanded(
              child: MerchantMetricTile(
                  icon: Icons.gavel_outlined,
                  label: 'الإجمالي',
                  value: '${summary.total}')),
        ]),
      ]);

  Widget _filters() => MerchantPanel(
          child: Column(children: [
        TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _refresh(),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: 'بحث برقم الطلب أو العميل أو موضوع النزاع',
            suffixIcon:
                IconButton(onPressed: _refresh, icon: const Icon(Icons.tune)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: _status,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'فلترة حالة النزاع',
            prefixIcon: const Icon(Icons.filter_alt_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
          items: const [
            DropdownMenuItem(value: 'ALL', child: Text('الكل')),
            DropdownMenuItem(value: 'OPEN', child: Text('مفتوحة')),
            DropdownMenuItem(value: 'UNDER_REVIEW', child: Text('قيد المراجعة')),
            DropdownMenuItem(value: 'RESOLVED', child: Text('محلولة')),
            DropdownMenuItem(value: 'REJECTED', child: Text('مرفوضة')),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _status = value;
              _future = _load();
            });
          },
        ),
      ]));

  Widget _actions(MerchantDisputeCase item) => Column(children: [
        Row(children: [
          Expanded(
              child: OutlinedButton.icon(
                  onPressed: () => _addMessage(item),
                  icon: const Icon(Icons.reply),
                  label: const Text('إضافة رد'))),
          const SizedBox(width: 8),
          Expanded(
              child: FilledButton.icon(
                  onPressed: () => _statusAction(item, 'UNDER_REVIEW'),
                  icon: const Icon(Icons.manage_search),
                  label: const Text('مراجعة'))),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
              child: OutlinedButton.icon(
                  onPressed: () => _resolve(item, 'MERCHANT_REJECTED'),
                  icon: const Icon(Icons.close),
                  label: const Text('رفض المطالبة'))),
          const SizedBox(width: 8),
          Expanded(
              child: FilledButton.icon(
                  onPressed: () => _resolve(item, 'MERCHANT_ACCEPTED'),
                  icon: const Icon(Icons.done_all),
                  label: const Text('حل لصالح العميل'))),
        ]),
      ]);
}

class _DisputeCard extends StatelessWidget {
  const _DisputeCard(
      {required this.item, required this.onDetails, required this.onMessage});

  final MerchantDisputeCase item;
  final VoidCallback onDetails;
  final VoidCallback onMessage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MerchantPanel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
                child: Text(item.reasonCode,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w900))),
            _statusChip(_disputeStatusLabel(item.status),
                _disputeStatusColor(item.status)),
          ]),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            Chip(label: Text(item.customerName)),
            if (item.orderNumber.isNotEmpty)
              Chip(label: Text('طلب ${item.orderNumber}')),
            Chip(label: Text(_priorityLabel(item.priority))),
          ]),
          const SizedBox(height: 8),
          Text(item.description,
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
            Expanded(
                child: FilledButton.icon(
                    onPressed: onMessage,
                    icon: const Icon(Icons.reply),
                    label: const Text('رد'))),
          ]),
        ]),
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

Widget _messagesPanel(List<MerchantCaseMessage> messages) => MerchantPanel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('المحادثة والمرفقات',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
      const SizedBox(height: 8),
      if (messages.isEmpty)
        const Text('لا توجد رسائل مرتبطة بهذا النزاع.',
            style: TextStyle(color: Color(0xFF687686)))
      else
        for (final message in messages)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(12)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(message.senderName,
                  style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(message.message),
              const SizedBox(height: 4),
              Row(children: [
                Expanded(
                    child: Text(message.createdAt,
                        style: const TextStyle(
                            color: Color(0xFF687686), fontSize: 12))),
                IconButton(
                    onPressed: () =>
                        Clipboard.setData(ClipboardData(text: message.message)),
                    icon: const Icon(Icons.copy, size: 18)),
              ]),
            ]),
          ),
    ]));

Widget _timelinePanel(List<MerchantCaseTimelineEntry> timeline,
        {required String fallbackStatus, required String fallbackDate}) =>
    MerchantPanel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('سجل المعالجة',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
      const SizedBox(height: 8),
      if (timeline.isEmpty)
        ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.history),
            title: Text(_disputeStatusLabel(fallbackStatus)),
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

String _disputeStatusLabel(String status) => switch (status) {
      'OPEN' => 'مفتوحة',
      'UNDER_REVIEW' || 'IN_REVIEW' => 'قيد المراجعة',
      'RESOLVED' => 'تم الحل',
      'REJECTED' => 'مرفوضة',
      'CLOSED' => 'مغلقة',
      _ => status.isEmpty ? 'غير محددة' : status,
    };

Color _disputeStatusColor(String status) => switch (status) {
      'OPEN' => Colors.orange,
      'UNDER_REVIEW' || 'IN_REVIEW' => Colors.blue,
      'RESOLVED' => Colors.green,
      'REJECTED' || 'CLOSED' => Colors.red,
      _ => Colors.blueGrey,
    };

String _priorityLabel(String priority) => switch (priority) {
      'LOW' => 'منخفضة',
      'NORMAL' => 'عادية',
      'HIGH' => 'عالية',
      'URGENT' => 'عاجلة',
      _ => priority.isEmpty ? 'عادية' : priority,
    };
