import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/core/navigation/app_navigation.dart';
import 'package:ghiyarak/features/orders/data/models/customer_dispute_model.dart';
import 'package:ghiyarak/features/orders/data/orders_repository.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';

final _disputeDetailProvider =
    FutureProvider.family<CustomerDisputeModel, String>((ref, id) {
  return ref.watch(ordersRepositoryProvider).getDisputeDetail(id);
});

class CustomerDisputeDetailPage extends ConsumerStatefulWidget {
  final String disputeId;
  const CustomerDisputeDetailPage({super.key, required this.disputeId});

  @override
  ConsumerState<CustomerDisputeDetailPage> createState() =>
      _CustomerDisputeDetailPageState();
}

class _CustomerDisputeDetailPageState
    extends ConsumerState<CustomerDisputeDetailPage> {
  final _message = TextEditingController();
  final _attachment = TextEditingController();
  final List<String> _attachments = [];
  bool _sending = false;
  bool _closing = false;

  @override
  void dispose() {
    _message.dispose();
    _attachment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_disputeDetailProvider(widget.disputeId));
    return AppScaffold(
      title: 'تفاصيل النزاع',
      child: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _StateCard(
            title: 'تعذر تحميل النزاع',
            message: error.toString(),
            onRetry: () =>
                ref.invalidate(_disputeDetailProvider(widget.disputeId))),
        data: (item) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(_disputeDetailProvider(widget.disputeId));
            await ref.read(_disputeDetailProvider(widget.disputeId).future);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              _Header(item: item),
              const SizedBox(height: 12),
              _DecisionCard(item: item),
              const SizedBox(height: 12),
              _DescriptionCard(item: item),
              const SizedBox(height: 12),
              _TimelineCard(item: item),
              const SizedBox(height: 12),
              if (item.canReply)
                _ReplyCard(
                  message: _message,
                  attachment: _attachment,
                  attachments: _attachments,
                  sending: _sending,
                  onAddAttachment: _addAttachment,
                  onRemoveAttachment: (value) =>
                      setState(() => _attachments.remove(value)),
                  onSend: () => _send(item),
                ),
              if (item.canReply) const SizedBox(height: 12),
              _ActionsCard(
                item: item,
                closing: _closing,
                onClose: () => _close(item),
                onReopen: () => _reopen(item),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addAttachment() {
    final url = _attachment.text.trim();
    if (url.isEmpty) return;
    setState(() {
      _attachments.add(url);
      _attachment.clear();
    });
  }

  Future<void> _send(CustomerDisputeModel item) async {
    final text = _message.text.trim();
    if (text.length < 2) return;
    setState(() => _sending = true);
    try {
      await ref.read(ordersRepositoryProvider).addDisputeMessage(item.publicId,
          message: text, attachments: _attachments);
      _message.clear();
      _attachments.clear();
      ref.invalidate(_disputeDetailProvider(widget.disputeId));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _close(CustomerDisputeModel item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إغلاق النزاع'),
        content: const Text('هل تم حل المشكلة وتريد إغلاق النزاع؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('تراجع')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('إغلاق')),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _closing = true);
    try {
      await ref
          .read(ordersRepositoryProvider)
          .closeDispute(item.publicId, note: 'أغلقه العميل بعد المتابعة');
      ref.invalidate(_disputeDetailProvider(widget.disputeId));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _closing = false);
    }
  }

  Future<void> _reopen(CustomerDisputeModel item) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إعادة فتح النزاع'),
        content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
                labelText: 'سبب إعادة الفتح', border: OutlineInputBorder())),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('إعادة الفتح')),
        ],
      ),
    );
    if ((reason ?? '').length < 5) return;
    try {
      await ref
          .read(ordersRepositoryProvider)
          .reopenDispute(item.publicId, reason: reason!);
      ref.invalidate(_disputeDetailProvider(widget.disputeId));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }
}

class _Header extends StatelessWidget {
  final CustomerDisputeModel item;
  const _Header({required this.item});
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const CircleAvatar(child: Icon(Icons.gavel_outlined)),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(item.subject,
                      style: Theme.of(context).textTheme.titleMedium)),
              Chip(label: Text(item.statusLabel)),
            ]),
            const SizedBox(height: 12),
            Text('الطلب: ${item.orderNumber}'),
            Text('المتجر: ${item.organizationName}'),
            Text('الأولوية: ${_priorityLabel(item.priority)}'),
          ]),
        ),
      );
}

class _DecisionCard extends StatelessWidget {
  final CustomerDisputeModel item;
  const _DecisionCard({required this.item});
  @override
  Widget build(BuildContext context) {
    final hasDecision =
        item.decision.isNotEmpty || item.decisionNote.isNotEmpty;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('قرار الإدارة',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(hasDecision
              ? '${item.decision} ${item.decisionNote}'.trim()
              : 'لم يصدر قرار نهائي بعد. سيتم إشعارك عند تحديث النزاع.'),
        ]),
      ),
    );
  }
}

class _DescriptionCard extends StatelessWidget {
  final CustomerDisputeModel item;
  const _DescriptionCard({required this.item});
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('تفاصيل المشكلة',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(item.description),
            if (item.attachments.isNotEmpty) ...[
              const Divider(),
              const Text('المرفقات'),
              ...item.attachments.map((a) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.attach_file),
                  title:
                      Text(a, maxLines: 1, overflow: TextOverflow.ellipsis))),
            ],
          ]),
        ),
      );
}

class _TimelineCard extends StatelessWidget {
  final CustomerDisputeModel item;
  const _TimelineCard({required this.item});
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('محادثة النزاع',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (item.messages.isEmpty)
              const Text('لا توجد رسائل بعد.')
            else
              ...item.messages.map((m) => Align(
                    alignment: m.fromCustomer
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(12),
                      constraints: const BoxConstraints(maxWidth: 320),
                      decoration: BoxDecoration(
                        color: m.fromCustomer
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.senderName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(m.message),
                            if (m.attachments.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              ...m.attachments.map((a) => Text('📎 $a',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis)),
                            ],
                          ]),
                    ),
                  )),
          ]),
        ),
      );
}

class _ReplyCard extends StatelessWidget {
  final TextEditingController message;
  final TextEditingController attachment;
  final List<String> attachments;
  final bool sending;
  final VoidCallback onAddAttachment;
  final ValueChanged<String> onRemoveAttachment;
  final VoidCallback onSend;
  const _ReplyCard(
      {required this.message,
      required this.attachment,
      required this.attachments,
      required this.sending,
      required this.onAddAttachment,
      required this.onRemoveAttachment,
      required this.onSend});
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('إضافة رد',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
                controller: message,
                maxLines: 4,
                decoration: const InputDecoration(
                    labelText: 'اكتب ردك أو أضف توضيحًا',
                    border: OutlineInputBorder())),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                  child: TextField(
                      controller: attachment,
                      decoration: const InputDecoration(
                          labelText: 'رابط مرفق اختياري',
                          border: OutlineInputBorder()))),
              const SizedBox(width: 8),
              IconButton.filled(
                  onPressed: onAddAttachment, icon: const Icon(Icons.add)),
            ]),
            ...attachments.map((a) => ListTile(
                dense: true,
                leading: const Icon(Icons.attach_file),
                title: Text(a, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => onRemoveAttachment(a)))),
            const SizedBox(height: 8),
            FilledButton.icon(
                onPressed: sending ? null : onSend,
                icon: const Icon(Icons.send),
                label: Text(sending ? 'جاري الإرسال...' : 'إرسال الرد')),
          ]),
        ),
      );
}

class _ActionsCard extends StatelessWidget {
  final CustomerDisputeModel item;
  final bool closing;
  final VoidCallback onClose;
  final VoidCallback onReopen;
  const _ActionsCard(
      {required this.item,
      required this.closing,
      required this.onClose,
      required this.onReopen});
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            OutlinedButton.icon(
                onPressed: () => context
                    .pushPath('${RouteNames.orderDetail}/${item.orderId}'),
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('تفاصيل الطلب')),
            OutlinedButton.icon(
                onPressed: () => Clipboard.setData(ClipboardData(
                    text:
                        'نزاع ${item.publicId} - الطلب ${item.orderNumber} - ${item.statusLabel}')),
                icon: const Icon(Icons.copy_outlined),
                label: const Text('نسخ الملخص')),
            if (item.canReply)
              FilledButton.icon(
                  onPressed: closing ? null : onClose,
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(closing ? 'جاري الإغلاق...' : 'إغلاق كمحلول')),
            if (item.canReopen)
              FilledButton.icon(
                  onPressed: onReopen,
                  icon: const Icon(Icons.refresh_outlined),
                  label: const Text('إعادة فتح النزاع')),
          ]),
        ),
      );
}

String _priorityLabel(String value) {
  switch (value.toUpperCase()) {
    case 'HIGH':
      return 'مهم';
    case 'URGENT':
      return 'عاجل';
    case 'LOW':
      return 'منخفض';
    default:
      return 'عادي';
  }
}

class _StateCard extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;
  const _StateCard(
      {required this.title, required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
          child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton(
              onPressed: onRetry, child: const Text('إعادة المحاولة')),
        ]),
      ));
}
