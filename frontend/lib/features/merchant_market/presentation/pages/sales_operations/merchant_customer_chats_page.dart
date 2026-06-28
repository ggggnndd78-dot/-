import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/features/merchant_market/data/models/merchant_chat_model.dart';
import 'package:ghiyarak/features/merchant_market/data/merchant_market_repository.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_management_scaffold.dart';

class MerchantCustomerChatsPage extends ConsumerStatefulWidget {
  const MerchantCustomerChatsPage({super.key});

  @override
  ConsumerState<MerchantCustomerChatsPage> createState() =>
      _MerchantCustomerChatsPageState();
}

class _MerchantCustomerChatsPageState
    extends ConsumerState<MerchantCustomerChatsPage> {
  final _search = TextEditingController();
  late Future<MerchantChatResponse> _future;
  String _status = '';

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

  Future<MerchantChatResponse> _load() {
    return ref.read(merchantMarketRepositoryProvider).getMerchantSupportTickets(
          status: _status,
          query: _search.text,
        );
  }

  void _refresh() => setState(() => _future = _load());

  Future<void> _reply(String ticketId, String message,
      {String? attachmentUrl}) async {
    try {
      await ref.read(merchantMarketRepositoryProvider).addMerchantTicketMessage(
            ticketId: ticketId,
            message: message,
            attachmentUrl: attachmentUrl,
          );
      if (mounted) _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _statusAction(String ticketId, String status) async {
    final note =
        await _askText('تحديث حالة المحادثة', 'ملاحظة اختيارية للتوثيق');
    try {
      await ref
          .read(merchantMarketRepositoryProvider)
          .updateMerchantTicketStatus(
            ticketId: ticketId,
            status: status,
            note: note,
          );
      if (mounted) _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<String?> _askText(String title, String label) async {
    final controller = TextEditingController();
    final value = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              16, 16, 16, MediaQuery.viewInsetsOf(sheetContext).bottom + 16),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                TextField(
                    controller: controller,
                    maxLines: 3,
                    decoration: InputDecoration(
                        labelText: label, border: const OutlineInputBorder())),
                const SizedBox(height: 12),
                FilledButton(
                    onPressed: () =>
                        Navigator.pop(sheetContext, controller.text.trim()),
                    child: const Text('حفظ')),
              ]),
        ),
      ),
    );
    controller.dispose();
    return value;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MerchantChatResponse>(
      future: _future,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final items = data?.tickets ?? const <MerchantChatTicket>[];
        return MerchantManagementScaffold(
          title: 'محادثات العملاء',
          subtitle:
              'رسائل العملاء المرتبطة بالطلبات والمنتجات مع حالة القراءة والردود والتصعيد.',
          onRefresh: () async => _refresh(),
          children: [
            Row(children: [
              Expanded(
                  child: MerchantMetricTile(
                      icon: Icons.forum_outlined,
                      label: 'المحادثات',
                      value: '${items.length}')),
              const SizedBox(width: 10),
              Expanded(
                  child: MerchantMetricTile(
                      icon: Icons.mark_chat_unread_outlined,
                      label: 'غير مقروءة',
                      value: '${data?.unreadCount ?? 0}')),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                  child: MerchantMetricTile(
                      icon: Icons.support_agent_outlined,
                      label: 'بانتظار التاجر',
                      value: '${data?.waitingCustomerCount ?? 0}')),
              const SizedBox(width: 10),
              Expanded(
                  child: MerchantMetricTile(
                      icon: Icons.task_alt_outlined,
                      label: 'محلولة',
                      value: '${data?.resolvedCount ?? 0}')),
            ]),
            const SizedBox(height: 14),
            MerchantPanel(
              child: Column(children: [
                TextField(
                  controller: _search,
                  decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      labelText: 'بحث برقم الطلب، العميل، الهاتف أو الرسالة',
                      border: OutlineInputBorder()),
                  onSubmitted: (_) => _refresh(),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(
                      labelText: 'حالة المحادثة', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: '', child: Text('كل الحالات')),
                    DropdownMenuItem(value: 'OPEN', child: Text('مفتوحة')),
                    DropdownMenuItem(
                        value: 'PENDING', child: Text('بانتظار الرد')),
                    DropdownMenuItem(
                        value: 'IN_PROGRESS', child: Text('قيد المتابعة')),
                    DropdownMenuItem(value: 'RESOLVED', child: Text('تم الحل')),
                    DropdownMenuItem(value: 'CLOSED', child: Text('مغلقة')),
                  ],
                  onChanged: (v) {
                    _status = v ?? '';
                    _refresh();
                  },
                ),
              ]),
            ),
            const SizedBox(height: 14),
            if (snapshot.connectionState != ConnectionState.done)
              const Center(child: CircularProgressIndicator())
            else if (snapshot.hasError)
              MerchantStateCard(
                  icon: Icons.error_outline,
                  title: 'تعذر تحميل المحادثات',
                  message: snapshot.error.toString(),
                  actionLabel: 'إعادة المحاولة',
                  onAction: _refresh)
            else if (items.isEmpty)
              const MerchantStateCard(
                  icon: Icons.forum_outlined,
                  title: 'لا توجد محادثات',
                  message:
                      'ستظهر هنا رسائل العملاء وتذاكر الدعم المرتبطة بمتجرك.')
            else
              ...items.map((item) => _TicketCard(
                    item: item,
                    onReply: _reply,
                    onStatus: _statusAction,
                    onMarkRead: () async {
                      await ref
                          .read(merchantMarketRepositoryProvider)
                          .markMerchantTicketRead(item.publicId.isNotEmpty
                              ? item.publicId
                              : item.id);
                      _refresh();
                    },
                  )),
          ],
        );
      },
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard(
      {required this.item,
      required this.onReply,
      required this.onStatus,
      required this.onMarkRead});

  final MerchantChatTicket item;
  final Future<void> Function(String ticketId, String message,
      {String? attachmentUrl}) onReply;
  final Future<void> Function(String ticketId, String status) onStatus;
  final Future<void> Function() onMarkRead;

  String get ticketId => item.publicId.isNotEmpty ? item.publicId : item.id;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MerchantPanel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(
                item.unreadCount > 0
                    ? Icons.mark_chat_unread_rounded
                    : Icons.forum_outlined,
                color: const Color(0xFFFF7900)),
            const SizedBox(width: 8),
            Expanded(
                child: Text(item.subject,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w900))),
            if (item.unreadCount > 0)
              Chip(label: Text('${item.unreadCount} جديد')),
          ]),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            Chip(label: Text(_ticketStatusLabel(item.status))),
            Chip(label: Text(_priorityLabel(item.priority))),
            if (item.category.isNotEmpty) Chip(label: Text(item.category)),
            if (item.customerName.isNotEmpty)
              Chip(label: Text(item.customerName)),
            if (item.orderNumber.isNotEmpty)
              Chip(label: Text('طلب ${item.orderNumber}')),
            if (item.productName.isNotEmpty)
              Chip(label: Text(item.productName)),
          ]),
          const SizedBox(height: 8),
          Text(item.lastMessage,
              style: const TextStyle(color: Color(0xFF687686), height: 1.45)),
          if (item.updatedAt != null) ...[
            const SizedBox(height: 8),
            Text('آخر تحديث: ${item.updatedAt}',
                style: const TextStyle(color: Color(0xFF8A98A8), fontSize: 12)),
          ],
          if (item.messages.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...item.messages.take(4).map((m) => _MessageBubble(message: m)),
          ],
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            FilledButton.icon(
                onPressed: () => _showReplySheet(context),
                icon: const Icon(Icons.send_rounded),
                label: const Text('إرسال رد')),
            OutlinedButton.icon(
                onPressed: onMarkRead,
                icon: const Icon(Icons.done_all),
                label: const Text('تحديد كمقروء')),
            OutlinedButton.icon(
                onPressed: () => onStatus(ticketId, 'IN_PROGRESS'),
                icon: const Icon(Icons.pending_actions),
                label: const Text('قيد المتابعة')),
            OutlinedButton.icon(
                onPressed: () => onStatus(ticketId, 'RESOLVED'),
                icon: const Icon(Icons.task_alt),
                label: const Text('تم الحل')),
            IconButton(
                onPressed: () => Clipboard.setData(ClipboardData(
                    text:
                        'محادثة: ${item.subject}\nالعميل: ${item.customerName}\nآخر رسالة: ${item.lastMessage}')),
                icon: const Icon(Icons.copy)),
          ]),
        ]),
      ),
    );
  }

  Future<void> _showReplySheet(BuildContext context) async {
    final controller = TextEditingController();
    final attachment = TextEditingController();
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              16, 16, 16, MediaQuery.viewInsetsOf(sheetContext).bottom + 16),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('رد على العميل',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                TextField(
                    controller: controller,
                    maxLines: 4,
                    decoration: const InputDecoration(
                        labelText: 'اكتب الرد', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(
                    controller: attachment,
                    decoration: const InputDecoration(
                        labelText: 'رابط مرفق اختياري',
                        border: OutlineInputBorder())),
                const SizedBox(height: 12),
                FilledButton(
                    onPressed: () {
                      final value = controller.text.trim();
                      if (value.isNotEmpty)
                        Navigator.pop(sheetContext, {
                          'message': value,
                          'attachment': attachment.text.trim()
                        });
                    },
                    child: const Text('إرسال')),
              ]),
        ),
      ),
    );
    controller.dispose();
    attachment.dispose();
    if (result == null) return;
    await onReply(ticketId, result['message'] ?? '',
        attachmentUrl: result['attachment']);
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final MerchantChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isMine ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: message.isMine
              ? const Color(0xFFFFF3E8)
              : const Color(0xFFF2F5F8),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(message.senderName,
              style:
                  const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
          const SizedBox(height: 4),
          Text(message.message),
          if (message.attachmentUrl.isNotEmpty)
            Text('مرفق: ${message.attachmentUrl}',
                style: const TextStyle(color: Color(0xFFFF7900))),
        ]),
      ),
    );
  }
}

String _ticketStatusLabel(String status) => switch (status) {
      'OPEN' => 'مفتوحة',
      'PENDING' => 'بانتظار الرد',
      'IN_PROGRESS' => 'قيد المتابعة',
      'RESOLVED' => 'تم الحل',
      'CLOSED' => 'مغلقة',
      _ => status.isEmpty ? 'غير محددة' : status,
    };

String _priorityLabel(String priority) => switch (priority) {
      'LOW' => 'منخفضة',
      'NORMAL' => 'عادية',
      'HIGH' => 'عالية',
      'URGENT' => 'عاجلة',
      _ => priority,
    };
