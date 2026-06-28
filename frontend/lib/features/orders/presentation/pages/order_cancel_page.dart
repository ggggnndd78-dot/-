import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/core/navigation/app_navigation.dart';
import 'package:ghiyarak/core/theme/app_colors.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/core/theme/app_text_styles.dart';
import 'package:ghiyarak/features/orders/data/orders_repository.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';

final _cancelOptionsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  return ref.watch(ordersRepositoryProvider).getCancellationOptions(id);
});

class OrderCancelPage extends ConsumerStatefulWidget {
  final String orderId;
  const OrderCancelPage({super.key, required this.orderId});

  @override
  ConsumerState<OrderCancelPage> createState() => _OrderCancelPageState();
}

class _OrderCancelPageState extends ConsumerState<OrderCancelPage> {
  final _noteController = TextEditingController();
  String _reasonCode = 'CUSTOMER_CHANGED_MIND';
  bool _acknowledged = false;
  bool _submitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final options = ref.watch(_cancelOptionsProvider(widget.orderId));
    return AppScaffold(
      title: 'إلغاء الطلب',
      child: options.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _StateCard(
          icon: Icons.error_outline,
          title: 'تعذر فحص الإلغاء',
          message: error.toString(),
          actionText: 'العودة للطلب',
          onAction: () => context.popOrGo(
            '${RouteNames.orderDetail}/${widget.orderId}',
          ),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(_cancelOptionsProvider(widget.orderId));
            await ref.read(_cancelOptionsProvider(widget.orderId).future);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            children: [
              _Header(data: data),
              const SizedBox(height: AppSpacing.lg),
              _EligibilityCard(data: data),
              const SizedBox(height: AppSpacing.lg),
              _ReasonCard(
                reasons: _reasons(data),
                selected: _reasonCode,
                onChanged: (value) => setState(() => _reasonCode = value),
              ),
              const SizedBox(height: AppSpacing.lg),
              _NoteCard(
                  controller: _noteController,
                  onChanged: () => setState(() {})),
              const SizedBox(height: AppSpacing.lg),
              _ImpactCard(data: data),
              const SizedBox(height: AppSpacing.lg),
              _PolicyCard(data: data),
              const SizedBox(height: AppSpacing.lg),
              _ConfirmCard(
                acknowledged: _acknowledged,
                onChanged: (value) => setState(() => _acknowledged = value),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                text: _submitting ? 'جاري إلغاء الطلب...' : 'تأكيد إلغاء الطلب',
                onPressed: _canSubmit(data) ? () => _submit(data) : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: _submitting
                    ? null
                    : () => context
                        .popOrGo('${RouteNames.orderDetail}/${widget.orderId}'),
                icon: const Icon(Icons.arrow_back),
                label: const Text('العودة بدون إلغاء'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _canSubmit(Map<String, dynamic> data) =>
      !_submitting &&
      _bool(data['canCancel']) &&
      _acknowledged &&
      _noteController.text.trim().length >= 6;

  Future<void> _submit(Map<String, dynamic> data) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الإلغاء'),
        content: Text(
            'سيتم إلغاء الطلب ${_orderNumber(data)} وإبلاغ المتجر. هل تريد المتابعة؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('تراجع')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('نعم، إلغاء الطلب')),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _submitting = true);
    try {
      await ref.read(ordersRepositoryProvider).cancelOrder(
            widget.orderId,
            reason: _selectedReasonLabel(data),
            reasonCode: _reasonCode,
            note: _noteController.text.trim(),
            acknowledged: _acknowledged,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('تم إلغاء الطلب وتحديث المخزون والدفع بنجاح')));
      await context.pushReplacementPath(
        '${RouteNames.orderDetail}/${widget.orderId}',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('تعذر إلغاء الطلب: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _selectedReasonLabel(Map<String, dynamic> data) {
    final match = _reasons(data).where((r) => r.code == _reasonCode).toList();
    final label = match.isEmpty ? 'سبب آخر' : match.first.label;
    final note = _noteController.text.trim();
    return note.isEmpty ? label : '$label - $note';
  }
}

class _Header extends StatelessWidget {
  final Map<String, dynamic> data;
  const _Header({required this.data});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: AppColors.headerGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
                color: AppColors.shadow, blurRadius: 18, offset: Offset(0, 10))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(18)),
              child: const Icon(Icons.cancel_schedule_send_outlined,
                  color: AppColors.secondary, size: 34),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('إلغاء الطلب ${_orderNumber(data)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.heading2
                          .copyWith(color: AppColors.textOnDark)),
                  const SizedBox(height: 4),
                  Text(_merchantName(data),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          AppTextStyles.body.copyWith(color: Colors.white70)),
                ])),
          ]),
          const SizedBox(height: AppSpacing.md),
          Text(
              'راجع نتيجة الإلغاء قبل التأكيد؛ سيتم تحديث حالة الطلب وإرجاع المخزون وإشعار المتجر تلقائيًا.',
              style: AppTextStyles.body.copyWith(color: Colors.white70)),
        ]),
      );
}

class _EligibilityCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _EligibilityCard({required this.data});
  @override
  Widget build(BuildContext context) {
    final canCancel = _bool(data['canCancel']);
    return _Card(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(canCancel ? Icons.check_circle_outline : Icons.lock_outline,
            color: canCancel ? AppColors.success : AppColors.error),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
            child: Text(
                canCancel
                    ? 'الطلب قابل للإلغاء الآن'
                    : 'لا يمكن إلغاء الطلب الآن',
                style: AppTextStyles.title)),
      ]),
      const SizedBox(height: AppSpacing.sm),
      Text(
          (data['message'] ??
                  data['reason'] ??
                  'يتم تحديد إمكانية الإلغاء حسب حالة الطلب الحالية وسياسة المتجر.')
              .toString(),
          style: AppTextStyles.bodySecondary),
      const SizedBox(height: AppSpacing.md),
      _InfoLine(
          label: 'حالة الطلب',
          value: _statusLabel((data['status'] ?? '').toString())),
      _InfoLine(
          label: 'حالة الدفع',
          value: _paymentLabel((data['paymentStatus'] ?? '').toString())),
      _InfoLine(
          label: 'الإجمالي',
          value: '${_money(data['total'])} ${data['currency'] ?? 'YER'}'),
    ]));
  }
}

class _ReasonCard extends StatelessWidget {
  final List<_CancelReason> reasons;
  final String selected;
  final ValueChanged<String> onChanged;
  const _ReasonCard(
      {required this.reasons, required this.selected, required this.onChanged});
  @override
  Widget build(BuildContext context) => _Card(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('سبب الإلغاء', style: AppTextStyles.title),
        const SizedBox(height: AppSpacing.sm),
        Text('اختر السبب الأقرب، ثم اكتب تفاصيل مختصرة في الحقل التالي.',
            style: AppTextStyles.bodySecondary),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: reasons.map((reason) {
            final isSelected = selected == reason.code;
            return ChoiceChip(
              label: Text(reason.label),
              selected: isSelected,
              onSelected: (_) => onChanged(reason.code),
              selectedColor: AppColors.accentSoft,
              side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.border),
            );
          }).toList(),
        ),
      ]));
}

class _NoteCard extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;
  const _NoteCard({required this.controller, required this.onChanged});
  @override
  Widget build(BuildContext context) => _Card(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('تفاصيل الإلغاء', style: AppTextStyles.title),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: controller,
          minLines: 3,
          maxLines: 5,
          maxLength: 300,
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            hintText: 'مثال: وجدت القطعة بسعر آخر، أو لم أعد أحتاج الطلب...',
            filled: true,
            fillColor: AppColors.surfaceTint,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.border)),
          ),
        ),
        Text('يجب كتابة سبب واضح لا يقل عن 6 أحرف ليظهر للتاجر والدعم.',
            style: AppTextStyles.bodySecondary),
      ]));
}

class _ImpactCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ImpactCard({required this.data});
  @override
  Widget build(BuildContext context) => _Card(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('ماذا سيحدث بعد الإلغاء؟', style: AppTextStyles.title),
        const SizedBox(height: AppSpacing.md),
        _ImpactRow(
            icon: Icons.inventory_2_outlined,
            text: 'إرجاع الكميات المحجوزة إلى مخزون المتجر عند نجاح الإلغاء.'),
        _ImpactRow(icon: Icons.payments_outlined, text: _refundText(data)),
        const _ImpactRow(
            icon: Icons.notifications_active_outlined,
            text: 'إرسال إشعار للمتجر والاحتفاظ بسجل الحالة داخل الطلب.'),
        const _ImpactRow(
            icon: Icons.history_outlined,
            text: 'يمكنك الرجوع لتفاصيل الطلب لمراجعة سبب الإلغاء وتاريخه.'),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: () => Clipboard.setData(ClipboardData(
              text:
                  'طلب ${_orderNumber(data)} | حالة الإلغاء: ${_bool(data['canCancel']) ? 'مسموح' : 'غير مسموح'} | الإجمالي: ${_money(data['total'])} ${data['currency'] ?? 'YER'}')),
          icon: const Icon(Icons.copy_outlined),
          label: const Text('نسخ ملخص الإلغاء'),
        ),
      ]));
}

class _PolicyCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _PolicyCard({required this.data});
  @override
  Widget build(BuildContext context) {
    final policies = _list(data['policies']);
    return _Card(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('سياسة الإلغاء', style: AppTextStyles.title),
      const SizedBox(height: AppSpacing.md),
      if (policies.isEmpty) ...const [
        _BulletText('يمكن الإلغاء قبل دخول الطلب في مرحلة التجهيز أو التوصيل.'),
        _BulletText(
            'عند وجود دفع مؤكد يتم تحويل الحالة إلى مسترد أو قيد مراجعة حسب طريقة الدفع.'),
        _BulletText(
            'بعد الإلغاء لا يمكن إعادة فتح نفس الطلب، ويمكنك استخدام إعادة الطلب لاحقًا.'),
      ] else
        ...policies.map((p) => _BulletText(p.toString())),
    ]));
  }
}

class _ConfirmCard extends StatelessWidget {
  final bool acknowledged;
  final ValueChanged<bool> onChanged;
  const _ConfirmCard({required this.acknowledged, required this.onChanged});
  @override
  Widget build(BuildContext context) => _Card(
          child: CheckboxListTile(
        value: acknowledged,
        onChanged: (value) => onChanged(value ?? false),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
        title: Text('أوافق على إلغاء الطلب وتطبيق سياسة الإلغاء',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w800)),
        subtitle: const Text(
            'لن يتم تنفيذ الإلغاء قبل تحديد السبب وكتابة الملاحظة والموافقة على السياسة.'),
      ));
}

class _ImpactRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _ImpactRow({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: AppColors.iconAccent, size: 22),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: AppTextStyles.body)),
        ]),
      );
}

class _BulletText extends StatelessWidget {
  final String text;
  const _BulletText(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('•  ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(text, style: AppTextStyles.bodySecondary)),
        ]),
      );
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;
  const _InfoLine({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(children: [
          Expanded(child: Text(label, style: AppTextStyles.bodySecondary)),
          Text(value,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w900)),
        ]),
      );
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
                color: AppColors.shadow, blurRadius: 14, offset: Offset(0, 8))
          ],
        ),
        child: child,
      );
}

class _StateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionText;
  final VoidCallback onAction;
  const _StateCard(
      {required this.icon,
      required this.title,
      required this.message,
      required this.actionText,
      required this.onAction});
  @override
  Widget build(BuildContext context) => Center(
          child: _Card(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: AppColors.iconAccent, size: 46),
        const SizedBox(height: AppSpacing.md),
        Text(title, style: AppTextStyles.title),
        const SizedBox(height: AppSpacing.sm),
        Text(message,
            textAlign: TextAlign.center, style: AppTextStyles.bodySecondary),
        const SizedBox(height: AppSpacing.lg),
        AppButton(text: actionText, onPressed: onAction),
      ])));
}

class _CancelReason {
  final String code;
  final String label;
  const _CancelReason(this.code, this.label);
}

List<_CancelReason> _reasons(Map<String, dynamic> data) {
  final raw = _list(data['reasons']);
  if (raw.isEmpty) {
    return const [
      _CancelReason('CUSTOMER_CHANGED_MIND', 'غيرت رأيي'),
      _CancelReason('WRONG_ITEM', 'اخترت قطعة غير مناسبة'),
      _CancelReason('FOUND_BETTER_PRICE', 'وجدت سعرًا أفضل'),
      _CancelReason('DELIVERY_TOO_LATE', 'موعد التوصيل غير مناسب'),
      _CancelReason('PAYMENT_ISSUE', 'مشكلة في الدفع'),
      _CancelReason('OTHER', 'سبب آخر'),
    ];
  }
  return raw.map((item) {
    final map =
        item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{};
    return _CancelReason((map['code'] ?? 'OTHER').toString(),
        (map['label'] ?? 'سبب آخر').toString());
  }).toList();
}

List<dynamic> _list(dynamic value) => value is List ? value : const [];
bool _bool(dynamic value) =>
    value == true || value.toString().toLowerCase() == 'true';
double _double(dynamic value) => double.tryParse((value ?? 0).toString()) ?? 0;
String _money(dynamic value) =>
    _double(value).toStringAsFixed(_double(value) % 1 == 0 ? 0 : 2);
String _orderNumber(Map<String, dynamic> data) =>
    (data['orderNumber'] ?? data['order_number'] ?? data['id'] ?? '')
        .toString();
String _merchantName(Map<String, dynamic> data) =>
    (data['merchantName'] ?? data['merchant_name'] ?? 'المتجر').toString();
String _refundText(Map<String, dynamic> data) {
  final payment = (data['paymentStatus'] ?? '').toString().toUpperCase();
  if (payment == 'PAID') {
    return 'سيتم وضع المبلغ كاسترداد/رصيد حسب طريقة الدفع وسياسة المتجر.';
  }
  if (payment == 'PENDING_REVIEW') {
    return 'سيتم إيقاف مراجعة الدفع وربطها بالإلغاء.';
  }
  return 'لا يوجد مبلغ مدفوع مؤكد، لذلك لن يلزم استرداد مالي.';
}

String _statusLabel(String status) => switch (status.toUpperCase()) {
      'PENDING' => 'طلب جديد',
      'CONFIRMED' => 'مؤكد',
      'PREPARING' => 'قيد التجهيز',
      'READY_FOR_PICKUP' => 'جاهز للاستلام',
      'OUT_FOR_DELIVERY' => 'قيد التوصيل',
      'COMPLETED' => 'مكتمل',
      'CANCELLED' || 'CANCELED' => 'ملغي',
      'REJECTED' => 'مرفوض',
      _ => status,
    };
String _paymentLabel(String status) => switch (status.toUpperCase()) {
      'UNPAID' => 'غير مدفوع',
      'PENDING_REVIEW' => 'قيد المراجعة',
      'PAID' => 'مدفوع',
      'FAILED' => 'فشل الدفع',
      'REFUNDED' => 'مسترد',
      _ => status,
    };
