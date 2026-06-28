import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/core/navigation/app_navigation.dart';
import 'package:ghiyarak/features/orders/data/models/customer_dispute_model.dart';
import 'package:ghiyarak/features/orders/data/orders_repository.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';

final _disputeOptionsProvider =
    FutureProvider.family<CustomerDisputeOptionsModel, String>((ref, id) {
  return ref.watch(ordersRepositoryProvider).getDisputeOptions(id);
});

class OrderDisputePage extends ConsumerStatefulWidget {
  final String orderId;
  const OrderDisputePage({super.key, required this.orderId});

  @override
  ConsumerState<OrderDisputePage> createState() => _OrderDisputePageState();
}

class _OrderDisputePageState extends ConsumerState<OrderDisputePage> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  final _attachment = TextEditingController();
  final List<String> _attachments = [];
  String _reason = 'PRODUCT_NOT_AS_DESCRIBED';
  String _priority = 'NORMAL';
  bool _accepted = false;
  bool _submitting = false;

  @override
  void dispose() {
    _description.dispose();
    _attachment.dispose();
    super.dispose();
  }

  void _addAttachment() {
    final value = _attachment.text.trim();
    if (value.isEmpty) return;
    setState(() {
      _attachments.add(value);
      _attachment.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final options = ref.watch(_disputeOptionsProvider(widget.orderId));
    return AppScaffold(
      title: 'فتح نزاع أو شكوى',
      child: options.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _StateCard(
          title: 'تعذر فحص إمكانية فتح النزاع',
          message: error.toString(),
          icon: Icons.error_outline,
          onRetry: () =>
              ref.invalidate(_disputeOptionsProvider(widget.orderId)),
        ),
        data: (data) {
          if (data.activeDispute != null) {
            return _ExistingDisputeCard(dispute: data.activeDispute!);
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(_disputeOptionsProvider(widget.orderId));
              await ref.read(_disputeOptionsProvider(widget.orderId).future);
            },
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _OrderInfoCard(options: data),
                  const SizedBox(height: 12),
                  if (!data.canOpen)
                    _BlockedCard(reason: data.blockedReason)
                  else ...[
                    _GuidelinesCard(),
                    const SizedBox(height: 12),
                    _ReasonCard(
                      reasons:
                          data.reasons.isEmpty ? _defaultReasons : data.reasons,
                      selected: _reason,
                      onChanged: (value) => setState(() => _reason = value),
                    ),
                    const SizedBox(height: 12),
                    _PriorityCard(
                        selected: _priority,
                        onChanged: (value) =>
                            setState(() => _priority = value)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _description,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: 'اشرح المشكلة بالتفصيل',
                        hintText:
                            'اكتب ماذا حدث، وما المطلوب من المتجر أو الإدارة...',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => (value ?? '').trim().length < 10
                          ? 'اكتب وصفًا واضحًا لا يقل عن 10 أحرف'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    _AttachmentsCard(
                      controller: _attachment,
                      attachments: _attachments,
                      onAdd: _addAttachment,
                      onRemove: (item) =>
                          setState(() => _attachments.remove(item)),
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      value: _accepted,
                      onChanged: (value) =>
                          setState(() => _accepted = value ?? false),
                      title: const Text(
                          'أقر أن المعلومات والمرفقات صحيحة وأوافق على مراجعة الإدارة للنزاع'),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _submitting || !_accepted
                          ? null
                          : () => _submit(data),
                      icon: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.gavel_outlined),
                      label: Text(
                          _submitting ? 'جاري فتح النزاع...' : 'إرسال النزاع'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => Clipboard.setData(ClipboardData(
                          text:
                              'طلب ${data.orderNumber} - سبب النزاع: $_reason')),
                      icon: const Icon(Icons.copy_outlined),
                      label: const Text('نسخ ملخص النزاع'),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _submit(CustomerDisputeOptionsModel data) async {
    if (!_formKey.currentState!.validate()) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد إرسال النزاع'),
        content: Text(
            'سيتم فتح نزاع على الطلب ${data.orderNumber} وإبلاغ المتجر والإدارة. هل تريد المتابعة؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('تراجع')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('إرسال')),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _submitting = true);
    try {
      final dispute = await ref.read(ordersRepositoryProvider).requestDispute(
            widget.orderId,
            reasonCode: _reason,
            subject: _reasonLabel(_reason),
            priority: _priority,
            description: _description.text.trim(),
            attachments: _attachments,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('تم فتح النزاع بنجاح')));
      await context.pushReplacementPath(
        '${RouteNames.customerDisputeDetail}/${dispute.publicId}',
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

const _defaultReasons = [
  'PRODUCT_NOT_AS_DESCRIBED',
  'WRONG_ITEM',
  'DAMAGED_ITEM',
  'MISSING_ITEM',
  'LATE_DELIVERY',
  'REFUND_DELAY',
  'MERCHANT_NOT_RESPONDING',
  'PAYMENT_PROBLEM',
  'OTHER',
];

String _reasonLabel(String code) {
  switch (code) {
    case 'PRODUCT_NOT_AS_DESCRIBED':
      return 'القطعة غير مطابقة للوصف';
    case 'WRONG_ITEM':
      return 'تم إرسال قطعة مختلفة';
    case 'DAMAGED_ITEM':
      return 'القطعة تالفة أو مكسورة';
    case 'MISSING_ITEM':
      return 'قطعة أو كمية ناقصة';
    case 'LATE_DELIVERY':
      return 'تأخر التسليم';
    case 'REFUND_DELAY':
      return 'تأخر الاسترداد المالي';
    case 'MERCHANT_NOT_RESPONDING':
      return 'المتجر لا يرد';
    case 'PAYMENT_PROBLEM':
      return 'مشكلة في الدفع';
    case 'OTHER':
      return 'سبب آخر';
    default:
      return code;
  }
}

class _OrderInfoCard extends StatelessWidget {
  final CustomerDisputeOptionsModel options;
  const _OrderInfoCard({required this.options});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('الطلب ${options.orderNumber}',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('المتجر: ${options.organizationName}'),
          Text('حالة الطلب: ${options.status}'),
          Text('حالة الدفع: ${options.paymentStatus}'),
        ]),
      ),
    );
  }
}

class _GuidelinesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('قبل فتح النزاع',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(
                  '• اشرح المشكلة بوضوح.\n• أرفق صورًا أو روابط إثبات عند وجودها.\n• سيتم إنشاء محادثة نزاع مرتبطة بالطلب.\n• تستطيع متابعة الردود والقرار من صفحة النزاعات.'),
            ]),
      ),
    );
  }
}

class _ReasonCard extends StatelessWidget {
  final List<String> reasons;
  final String selected;
  final ValueChanged<String> onChanged;
  const _ReasonCard(
      {required this.reasons, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('سبب النزاع',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...reasons.map((code) => RadioListTile<String>(
                value: code,
                // ignore: deprecated_member_use
                groupValue: selected,
                // ignore: deprecated_member_use
                onChanged: (value) => onChanged(value ?? code),
                title: Text(_reasonLabel(code)),
                contentPadding: EdgeInsets.zero,
              )),
        ]),
      ),
    );
  }
}

class _PriorityCard extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const _PriorityCard({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const items = {'NORMAL': 'عادي', 'HIGH': 'مهم', 'URGENT': 'عاجل'};
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('أولوية النزاع',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: items.entries
                .map((e) => ChoiceChip(
                      label: Text(e.value),
                      selected: selected == e.key,
                      onSelected: (_) => onChanged(e.key),
                    ))
                .toList(),
          ),
        ]),
      ),
    );
  }
}

class _AttachmentsCard extends StatelessWidget {
  final TextEditingController controller;
  final List<String> attachments;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;
  const _AttachmentsCard(
      {required this.controller,
      required this.attachments,
      required this.onAdd,
      required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('المرفقات والروابط',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
                child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                        labelText: 'رابط صورة أو ملف',
                        border: OutlineInputBorder()))),
            const SizedBox(width: 8),
            IconButton.filled(onPressed: onAdd, icon: const Icon(Icons.add)),
          ]),
          const SizedBox(height: 8),
          ...attachments.map((item) => ListTile(
                dense: true,
                leading: const Icon(Icons.attach_file),
                title: Text(item, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => onRemove(item)),
              )),
        ]),
      ),
    );
  }
}

class _ExistingDisputeCard extends StatelessWidget {
  final CustomerDisputeModel dispute;
  const _ExistingDisputeCard({required this.dispute});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.gavel_outlined, size: 48),
              const SizedBox(height: 12),
              const Text('يوجد نزاع مفتوح لهذا الطلب',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('الحالة: ${dispute.statusLabel}'),
              const SizedBox(height: 16),
              FilledButton(
                  onPressed: () => context.pushPath(
                      '${RouteNames.customerDisputeDetail}/${dispute.publicId}'),
                  child: const Text('متابعة النزاع')),
            ]),
          ),
        ),
      ),
    );
  }
}

class _BlockedCard extends StatelessWidget {
  final String reason;
  const _BlockedCard({required this.reason});
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(children: [
            const Icon(Icons.block_outlined, size: 42),
            const SizedBox(height: 8),
            const Text('لا يمكن فتح نزاع لهذا الطلب حاليًا',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(reason.isEmpty ? 'راجع حالة الطلب أو تواصل مع الدعم.' : reason,
                textAlign: TextAlign.center),
          ]),
        ),
      );
}

class _StateCard extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback onRetry;
  const _StateCard(
      {required this.title,
      required this.message,
      required this.icon,
      required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 48),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(
                onPressed: onRetry, child: const Text('إعادة المحاولة')),
          ]),
        ),
      );
}
