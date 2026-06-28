import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/core/navigation/app_navigation.dart';
import 'package:ghiyarak/core/theme/app_colors.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/core/theme/app_text_styles.dart';
import 'package:ghiyarak/features/orders/data/models/customer_return_model.dart';
import 'package:ghiyarak/features/orders/data/orders_repository.dart';
import 'package:ghiyarak/features/orders/presentation/pages/my_orders_page.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';

final _returnOptionsProvider =
    FutureProvider.family<CustomerReturnOptionsModel, String>((ref, id) {
  return ref.watch(ordersRepositoryProvider).getReturnOptions(id);
});

class OrderReturnPage extends ConsumerStatefulWidget {
  final String orderId;
  const OrderReturnPage({super.key, required this.orderId});

  @override
  ConsumerState<OrderReturnPage> createState() => _OrderReturnPageState();
}

class _OrderReturnPageState extends ConsumerState<OrderReturnPage> {
  final _formKey = GlobalKey<FormState>();
  final _detailsController = TextEditingController();
  final _contactController = TextEditingController();
  final _attachmentController = TextEditingController();

  String _requestType = 'RETURN';
  String? _selectedReason;
  String _refundMethod = 'WALLET';
  String _returnMethod = 'COURIER_PICKUP';
  String _conditionCode = 'ORIGINAL';
  final Map<String, int> _quantities = {};
  final List<String> _attachments = [];
  bool _acceptedPolicy = false;
  bool _submitting = false;

  @override
  void dispose() {
    _detailsController.dispose();
    _contactController.dispose();
    _attachmentController.dispose();
    super.dispose();
  }

  void _toggleItem(CustomerReturnItemModel item, bool selected) {
    setState(() {
      if (selected) {
        _quantities[item.id] = item.maxReturnQuantity > 0 ? 1 : 0;
      } else {
        _quantities.remove(item.id);
      }
    });
  }

  void _setQty(CustomerReturnItemModel item, int qty) {
    setState(() {
      final safe = qty.clamp(1, item.maxReturnQuantity).toInt();
      _quantities[item.id] = safe;
    });
  }

  double _selectedAmount(CustomerReturnOptionsModel options) {
    double total = 0;
    for (final item in options.items) {
      final qty = _quantities[item.id] ?? 0;
      total += item.unitPrice * qty;
    }
    return total;
  }

  void _addAttachment() {
    final url = _attachmentController.text.trim();
    if (url.isEmpty) return;
    setState(() {
      _attachments.add(url);
      _attachmentController.clear();
    });
  }

  Future<void> _submit(CustomerReturnOptionsModel options) async {
    if (!_formKey.currentState!.validate()) return;
    if (!options.canReturn) {
      return _showMessage(options.blockedReason.isEmpty
          ? 'هذا الطلب غير مؤهل للإرجاع'
          : options.blockedReason);
    }
    if (_quantities.isEmpty) {
      return _showMessage('اختر قطعة واحدة على الأقل للإرجاع');
    }
    if (!_acceptedPolicy) {
      return _showMessage('يجب الموافقة على سياسة الإرجاع والاسترداد');
    }

    final items = options.items
        .where((item) => (_quantities[item.id] ?? 0) > 0)
        .map((item) => {
              'orderItemId': int.tryParse(item.id) ?? item.id,
              'listingId': int.tryParse(item.listingId) ?? item.listingId,
              'quantity': _quantities[item.id] ?? 1,
              'unitPrice': item.unitPrice,
              'reason': _selectedReason,
            })
        .toList();

    setState(() => _submitting = true);
    try {
      final request = await ref.read(ordersRepositoryProvider).requestReturn(
            widget.orderId,
            requestType: _requestType,
            reason: _selectedReason!,
            refundMethod: _refundMethod,
            returnMethod: _returnMethod,
            conditionCode: _conditionCode,
            details: _detailsController.text,
            contactNote: _contactController.text,
            attachments: _attachments,
            items: items,
          );
      ref.invalidate(ordersProvider);
      ref.invalidate(_returnOptionsProvider(widget.orderId));
      if (!mounted) return;
      _showMessage(
          'تم إرسال طلب الإرجاع رقم ${request.publicId.isEmpty ? request.id : request.publicId}');
      await context.pushReplacementPath(
        '${RouteNames.orderDetail}/${widget.orderId}',
      );
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showMessage(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_returnOptionsProvider(widget.orderId));
    return AppScaffold(
      title: 'المرتجعات',
      child: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _StateCard(
          icon: Icons.error_outline,
          title: 'تعذر تحميل بيانات المرتجع',
          message: error.toString(),
          actionText: 'إعادة المحاولة',
          onAction: () =>
              ref.invalidate(_returnOptionsProvider(widget.orderId)),
        ),
        data: (options) => Form(
          key: _formKey,
          child: ListView(
            children: [
              _HeaderCard(options: options, amount: _selectedAmount(options)),
              const SizedBox(height: AppSpacing.lg),
              if (options.activeRequest != null) ...[
                _ActiveRequestCard(request: options.activeRequest!),
                const SizedBox(height: AppSpacing.lg),
              ],
              if (!options.canReturn) ...[
                _BlockedReturnCard(
                    message: options.blockedReason, status: options.status),
                const SizedBox(height: AppSpacing.lg),
              ],
              _RequestTypeCard(
                  value: _requestType,
                  onChanged: (v) => setState(() => _requestType = v)),
              const SizedBox(height: AppSpacing.lg),
              _ItemsCard(
                items: options.items,
                quantities: _quantities,
                onToggle: _toggleItem,
                onQtyChanged: _setQty,
              ),
              const SizedBox(height: AppSpacing.lg),
              _ReasonCard(
                reasons: options.reasons,
                selectedReason: _selectedReason,
                onReasonChanged: (v) => setState(() => _selectedReason = v),
                detailsController: _detailsController,
                contactController: _contactController,
              ),
              const SizedBox(height: AppSpacing.lg),
              _ReturnMethodCard(
                returnMethod: _returnMethod,
                refundMethod: _refundMethod,
                refundMethods: options.refundMethods,
                conditionCode: _conditionCode,
                onReturnMethodChanged: (v) => setState(() => _returnMethod = v),
                onRefundMethodChanged: (v) => setState(() => _refundMethod = v),
                onConditionChanged: (v) => setState(() => _conditionCode = v),
              ),
              const SizedBox(height: AppSpacing.lg),
              _AttachmentsCard(
                controller: _attachmentController,
                attachments: _attachments,
                onAdd: _addAttachment,
                onRemove: (url) => setState(() => _attachments.remove(url)),
              ),
              const SizedBox(height: AppSpacing.lg),
              _PolicyCard(
                  policy: options.policySummary,
                  days: options.returnWindowDays),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _acceptedPolicy,
                onChanged: (v) => setState(() => _acceptedPolicy = v ?? false),
                title: const Text('أوافق على سياسة الإرجاع والاسترداد'),
                subtitle:
                    const Text('سيتم فحص القطعة قبل اعتماد القرار النهائي.'),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                text: 'إرسال طلب الإرجاع',
                isLoading: _submitting,
                onPressed: options.canReturn ? () => _submit(options) : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: () => context
                    .popOrGo('${RouteNames.orderDetail}/${widget.orderId}'),
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('العودة لتفاصيل الطلب'),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final CustomerReturnOptionsModel options;
  final double amount;
  const _HeaderCard({required this.options, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadow, blurRadius: 18, offset: Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18)),
                child: const Icon(Icons.assignment_return_outlined,
                    color: AppColors.secondary, size: 34),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(options.orderNumber,
                          style: AppTextStyles.heading2
                              .copyWith(color: AppColors.textOnDark)),
                      const SizedBox(height: 4),
                      Text(
                          'نافذة الإرجاع ${options.returnWindowDays} أيام • الحالة ${_statusLabel(options.status)}',
                          style: AppTextStyles.body.copyWith(
                              color: AppColors.textOnDark
                                  .withValues(alpha: 0.78))),
                    ]),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(children: [
            Expanded(
                child: _Metric(
                    title: 'إجمالي الطلب',
                    value: _money(options.totalAmount, options.currency))),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
                child: _Metric(
                    title: 'مبلغ محدد',
                    value: _money(amount, options.currency))),
          ]),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String title;
  final String value;
  const _Metric({required this.title, required this.value});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: AppTextStyles.bodySecondary.copyWith(
                  color: AppColors.textOnDark.withValues(alpha: 0.75),
                  fontSize: 12)),
          const SizedBox(height: 4),
          Text(value,
              style: AppTextStyles.title
                  .copyWith(color: AppColors.textOnDark, fontSize: 16)),
        ]),
      );
}

class _ActiveRequestCard extends StatelessWidget {
  final CustomerReturnRequestModel request;
  const _ActiveRequestCard({required this.request});
  @override
  Widget build(BuildContext context) => _FormCard(
        title: 'طلب مرتجع مفتوح',
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _InfoRow('رقم الطلب',
              request.publicId.isEmpty ? request.id : request.publicId),
          _InfoRow('الحالة', _returnStatusLabel(request.status)),
          _InfoRow('السبب', request.reason),
          _InfoRow('المبلغ', _money(request.amount, request.currency)),
          const SizedBox(height: AppSpacing.sm),
          Text('لا يمكن إنشاء طلب مرتجع جديد قبل إغلاق الطلب الحالي.',
              style: AppTextStyles.bodySecondary),
        ]),
      );
}

class _BlockedReturnCard extends StatelessWidget {
  final String message;
  final String status;
  const _BlockedReturnCard({required this.message, required this.status});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.info_outline, color: AppColors.error),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
              child: Text(
                  message.isEmpty
                      ? 'الإرجاع غير متاح في الحالة الحالية: ${_statusLabel(status)}'
                      : message,
                  style: AppTextStyles.body
                      .copyWith(fontWeight: FontWeight.w800))),
        ]),
      );
}

class _RequestTypeCard extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _RequestTypeCard({required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) => _FormCard(
        title: 'نوع الطلب',
        child: Row(children: [
          Expanded(
              child: _Choice(
                  active: value == 'RETURN',
                  icon: Icons.undo_outlined,
                  title: 'إرجاع',
                  subtitle: 'استرداد المبلغ بعد الفحص',
                  onTap: () => onChanged('RETURN'))),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
              child: _Choice(
                  active: value == 'EXCHANGE',
                  icon: Icons.swap_horiz_outlined,
                  title: 'استبدال',
                  subtitle: 'طلب قطعة بديلة مناسبة',
                  onTap: () => onChanged('EXCHANGE'))),
        ]),
      );
}

class _Choice extends StatelessWidget {
  final bool active;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _Choice(
      {required this.active,
      required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
        color: active
            ? AppColors.success.withValues(alpha: 0.08)
            : AppColors.surfaceTint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: active ? AppColors.success : AppColors.border,
            width: active ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon,
                    color: active ? AppColors.success : AppColors.primary),
                const SizedBox(height: AppSpacing.sm),
                Text(title, style: AppTextStyles.title.copyWith(fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySecondary.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );
}

class _ItemsCard extends StatelessWidget {
  final List<CustomerReturnItemModel> items;
  final Map<String, int> quantities;
  final void Function(CustomerReturnItemModel, bool) onToggle;
  final void Function(CustomerReturnItemModel, int) onQtyChanged;
  const _ItemsCard(
      {required this.items,
      required this.quantities,
      required this.onToggle,
      required this.onQtyChanged});

  @override
  Widget build(BuildContext context) => _FormCard(
        title: 'اختر القطع والكميات',
        child: Column(
          children: items.map((item) {
            final selected = quantities.containsKey(item.id);
            final qty = quantities[item.id] ?? 0;
            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary.withValues(alpha: .06)
                      : AppColors.surfaceTint,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: selected ? AppColors.primary : AppColors.border)),
              child: Column(children: [
                Row(children: [
                  Checkbox(
                      value: selected,
                      onChanged: item.returnable
                          ? (v) => onToggle(item, v ?? false)
                          : null),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(item.title,
                            style: AppTextStyles.title.copyWith(fontSize: 15)),
                        Text(
                            'طلبت ${item.orderedQuantity} • قابل للإرجاع ${item.maxReturnQuantity} • ${_money(item.unitPrice, 'YER')}',
                            style: AppTextStyles.bodySecondary
                                .copyWith(fontSize: 12)),
                        if (item.blockedReason.isNotEmpty)
                          Text(item.blockedReason,
                              style: AppTextStyles.bodySecondary.copyWith(
                                  color: AppColors.error, fontSize: 12)),
                      ])),
                ]),
                if (selected)
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    IconButton(
                        onPressed:
                            qty > 1 ? () => onQtyChanged(item, qty - 1) : null,
                        icon: const Icon(Icons.remove_circle_outline)),
                    Text('$qty', style: AppTextStyles.title),
                    IconButton(
                        onPressed: qty < item.maxReturnQuantity
                            ? () => onQtyChanged(item, qty + 1)
                            : null,
                        icon: const Icon(Icons.add_circle_outline)),
                  ]),
              ]),
            );
          }).toList(),
        ),
      );
}

class _ReasonCard extends StatelessWidget {
  final List<String> reasons;
  final String? selectedReason;
  final ValueChanged<String?> onReasonChanged;
  final TextEditingController detailsController;
  final TextEditingController contactController;
  const _ReasonCard(
      {required this.reasons,
      required this.selectedReason,
      required this.onReasonChanged,
      required this.detailsController,
      required this.contactController});
  @override
  Widget build(BuildContext context) => _FormCard(
        title: 'سبب الطلب والتفاصيل',
        child: Column(children: [
          DropdownButtonFormField<String>(
            initialValue: selectedReason,
            decoration: const InputDecoration(
                labelText: 'سبب الإرجاع', prefixIcon: Icon(Icons.help_outline)),
            validator: (v) => (v ?? '').isEmpty ? 'اختر سبب الطلب' : null,
            items: reasons
                .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                .toList(),
            onChanged: onReasonChanged,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: detailsController,
            minLines: 4,
            maxLines: 6,
            maxLength: 700,
            decoration: const InputDecoration(
                labelText: 'وصف المشكلة',
                hintText: 'اشرح المشكلة ومتى ظهرت وهل تم تركيب القطعة',
                prefixIcon: Icon(Icons.notes_outlined)),
            validator: (v) => (v ?? '').trim().length < 10
                ? 'اكتب تفاصيل لا تقل عن 10 أحرف'
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
              controller: contactController,
              decoration: const InputDecoration(
                  labelText: 'ملاحظة تواصل اختيارية',
                  prefixIcon: Icon(Icons.phone_outlined))),
        ]),
      );
}

class _ReturnMethodCard extends StatelessWidget {
  final String returnMethod;
  final String refundMethod;
  final String conditionCode;
  final List<String> refundMethods;
  final ValueChanged<String> onReturnMethodChanged;
  final ValueChanged<String> onRefundMethodChanged;
  final ValueChanged<String> onConditionChanged;
  const _ReturnMethodCard(
      {required this.returnMethod,
      required this.refundMethod,
      required this.conditionCode,
      required this.refundMethods,
      required this.onReturnMethodChanged,
      required this.onRefundMethodChanged,
      required this.onConditionChanged});
  @override
  Widget build(BuildContext context) => _FormCard(
        title: 'طريقة الإرجاع والاسترداد',
        child: Column(children: [
          DropdownButtonFormField<String>(
            initialValue: returnMethod,
            decoration: const InputDecoration(
                labelText: 'طريقة تسليم المرتجع',
                prefixIcon: Icon(Icons.local_shipping_outlined)),
            items: const [
              DropdownMenuItem(
                  value: 'COURIER_PICKUP', child: Text('استلام من العنوان')),
              DropdownMenuItem(
                  value: 'BRANCH_DROP_OFF', child: Text('تسليم في الفرع')),
              DropdownMenuItem(
                  value: 'CUSTOMER_SHIPPING', child: Text('شحن من طرف العميل')),
            ],
            onChanged: (v) => onReturnMethodChanged(v ?? returnMethod),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: refundMethods.contains(refundMethod)
                ? refundMethod
                : (refundMethods.isEmpty ? 'WALLET' : refundMethods.first),
            decoration: const InputDecoration(
                labelText: 'طريقة الاسترداد',
                prefixIcon: Icon(Icons.account_balance_wallet_outlined)),
            items: (refundMethods.isEmpty
                    ? const ['WALLET', 'BANK_TRANSFER', 'ORIGINAL_PAYMENT']
                    : refundMethods)
                .map((m) => DropdownMenuItem(
                    value: m, child: Text(_refundMethodLabel(m))))
                .toList(),
            onChanged: (v) => onRefundMethodChanged(v ?? refundMethod),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: conditionCode,
            decoration: const InputDecoration(
                labelText: 'حالة القطعة',
                prefixIcon: Icon(Icons.fact_check_outlined)),
            items: const [
              DropdownMenuItem(
                  value: 'ORIGINAL', child: Text('بحالتها الأصلية')),
              DropdownMenuItem(value: 'OPENED', child: Text('تم فتحها فقط')),
              DropdownMenuItem(
                  value: 'INSTALLED', child: Text('تم تركيبها أو تجربتها')),
              DropdownMenuItem(
                  value: 'DAMAGED_ON_ARRIVAL', child: Text('وصلت تالفة')),
            ],
            onChanged: (v) => onConditionChanged(v ?? conditionCode),
          ),
        ]),
      );
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
  Widget build(BuildContext context) => _FormCard(
        title: 'صور ومرفقات',
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
              'أضف رابط صورة للقطعة أو الإيصال. رفع الملفات الفعلي يمكن ربطه لاحقًا بخدمة التخزين.',
              style: AppTextStyles.bodySecondary),
          const SizedBox(height: AppSpacing.md),
          Row(children: [
            Expanded(
                child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                        labelText: 'رابط صورة أو مرفق',
                        prefixIcon: Icon(Icons.link_outlined)))),
            const SizedBox(width: AppSpacing.sm),
            IconButton.filled(onPressed: onAdd, icon: const Icon(Icons.add)),
          ]),
          for (final url in attachments)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.attachment_outlined),
              title: Text(url, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => onRemove(url)),
            ),
        ]),
      );
}

class _PolicyCard extends StatelessWidget {
  final String policy;
  final int days;
  const _PolicyCard({required this.policy, required this.days});
  @override
  Widget build(BuildContext context) => _FormCard(
        title: 'سياسة الإرجاع',
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _InfoRow('مدة الإرجاع', '$days أيام من تاريخ اكتمال الطلب'),
          _InfoRow('الفحص', 'يتم فحص القطعة قبل قبول القرار النهائي'),
          _InfoRow('الاسترداد', 'يتم بعد قبول التاجر أو فريق غيارك'),
          const SizedBox(height: AppSpacing.sm),
          Text(
              policy.isEmpty
                  ? 'يجب إرجاع القطعة بنفس الحالة مع المرفقات والفاتورة. قد يرفض الطلب إذا ثبت سوء الاستخدام أو اختلاف القطعة.'
                  : policy,
              style: AppTextStyles.bodySecondary),
        ]),
      );
}

class _FormCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _FormCard({required this.title, required this.child});
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
            ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: AppTextStyles.title.copyWith(fontSize: 18)),
          const SizedBox(height: AppSpacing.md),
          child,
        ]),
      );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: Row(children: [
          SizedBox(
              width: 110,
              child: Text(label, style: AppTextStyles.bodySecondary)),
          Expanded(
              child: Text(value.isEmpty ? '—' : value,
                  style: AppTextStyles.body
                      .copyWith(fontWeight: FontWeight.w800))),
        ]),
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
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 46, color: AppColors.primary),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.sm),
            Text(message,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySecondary),
            const SizedBox(height: AppSpacing.lg),
            AppButton(text: actionText, onPressed: onAction),
          ]),
        ),
      );
}

String _money(double value, String currency) =>
    '${value.toStringAsFixed(0)} $currency';
String _statusLabel(String status) {
  switch (status.toUpperCase()) {
    case 'COMPLETED':
      return 'مكتمل';
    case 'DELIVERED':
      return 'تم التسليم';
    case 'CANCELLED':
      return 'ملغي';
    case 'PENDING':
      return 'بانتظار التأكيد';
    case 'CONFIRMED':
      return 'مؤكد';
    default:
      return status.isEmpty ? 'غير محدد' : status;
  }
}

String _returnStatusLabel(String status) {
  switch (status.toUpperCase()) {
    case 'PENDING':
      return 'قيد المراجعة';
    case 'APPROVED':
      return 'مقبول';
    case 'RECEIVED':
      return 'تم استلام القطعة';
    case 'PAID':
      return 'تم الاسترداد';
    case 'REJECTED':
      return 'مرفوض';
    default:
      return status;
  }
}

String _refundMethodLabel(String method) {
  switch (method.toUpperCase()) {
    case 'WALLET':
      return 'إلى محفظة غيارك';
    case 'BANK_TRANSFER':
      return 'تحويل بنكي';
    case 'ORIGINAL_PAYMENT':
      return 'نفس طريقة الدفع';
    default:
      return method;
  }
}
