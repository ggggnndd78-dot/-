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
import 'package:go_router/go_router.dart';

final _orderDetailProvider =
    FutureProvider.family<_OrderDetail, String>((ref, id) async {
  final data = await ref.watch(ordersRepositoryProvider).getOrderDetail(id);
  return _OrderDetail.fromMap(data);
});

final _orderInvoiceProvider =
    FutureProvider.family<_InvoiceBundle, String>((ref, id) async {
  final data = await ref.watch(ordersRepositoryProvider).getOrderInvoice(id);
  return _InvoiceBundle.fromMap(data);
});

class OrderDetailPage extends ConsumerWidget {
  final String orderId;
  const OrderDetailPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(_orderDetailProvider(orderId));
    return AppScaffold(
      title: 'تفاصيل الطلب والفاتورة',
      child: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _StateCard(
          icon: Icons.error_outline,
          title: 'تعذر تحميل الطلب',
          message: error.toString(),
          actionText: 'العودة إلى طلباتي',
          onAction: () => context.go(RouteNames.myOrders),
        ),
        data: (order) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(_orderDetailProvider(orderId));
            ref.invalidate(_orderInvoiceProvider(orderId));
            await ref.read(_orderDetailProvider(orderId).future);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              _HeaderCard(order: order),
              const SizedBox(height: AppSpacing.lg),
              _QuickActions(order: order),
              const SizedBox(height: AppSpacing.lg),
              _TimelineCard(order: order),
              const SizedBox(height: AppSpacing.lg),
              _ProviderCard(order: order),
              const SizedBox(height: AppSpacing.lg),
              _PaymentDeliveryCard(order: order),
              const SizedBox(height: AppSpacing.lg),
              if (order.customerNote.isNotEmpty ||
                  order.cancellationReason.isNotEmpty) ...[
                _NotesCard(order: order),
                const SizedBox(height: AppSpacing.lg),
              ],
              _SectionTitle(
                  title: 'قطع الطلب', trailing: '${order.items.length}'),
              const SizedBox(height: AppSpacing.sm),
              if (order.items.isEmpty)
                const _EmptyItemsCard()
              else
                ...order.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _OrderItemCard(item: item),
                    )),
              const SizedBox(height: AppSpacing.sm),
              _TotalsCard(order: order),
              const SizedBox(height: AppSpacing.lg),
              if (order.fees.isNotEmpty) ...[
                _FeesCard(fees: order.fees),
                const SizedBox(height: AppSpacing.lg),
              ],
              _InvoicePanel(orderId: orderId, order: order),
              const SizedBox(height: AppSpacing.lg),
              if (order.statusHistory.isNotEmpty) ...[
                _HistoryCard(history: order.statusHistory),
                const SizedBox(height: AppSpacing.lg),
              ],
              _ActionPanel(order: order),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final _OrderDetail order;
  const _HeaderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final status = _statusInfo(order.status);
    return Container(
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
            width: 62,
            height: 62,
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(20)),
            child: Icon(status.icon, color: AppColors.secondary, size: 34),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(order.orderNumber,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.heading2
                        .copyWith(color: AppColors.textOnDark)),
                const SizedBox(height: AppSpacing.xs),
                Text(order.createdAtLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(
                        color: AppColors.textOnDark.withValues(alpha: .72))),
              ])),
        ]),
        const SizedBox(height: AppSpacing.lg),
        Row(children: [
          Expanded(
              child: _DarkMetric(label: 'حالة الطلب', value: status.label)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
              child: _DarkMetric(
                  label: 'الإجمالي',
                  value: _money(order.total, order.currency))),
        ]),
      ]),
    );
  }
}

class _DarkMetric extends StatelessWidget {
  final String label;
  final String value;
  const _DarkMetric({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white24)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: AppTextStyles.body.copyWith(
                  color: AppColors.textOnDark.withValues(alpha: .72),
                  fontSize: 12)),
          const SizedBox(height: AppSpacing.xs),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.title
                  .copyWith(color: AppColors.secondary, fontSize: 15)),
        ]),
      );
}

class _QuickActions extends ConsumerWidget {
  final _OrderDetail order;
  const _QuickActions({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [
      _ActionChipButton(
          icon: Icons.receipt_long_outlined,
          label: 'عرض الفاتورة',
          onTap: () => _showInvoice(context, ref, order.id)),
      _ActionChipButton(
          icon: Icons.copy_outlined,
          label: 'نسخ الملخص',
          onTap: () => _copyOrderSummary(context, order)),
      _ActionChipButton(
          icon: Icons.local_shipping_outlined,
          label: 'التتبع',
          onTap: () => context.pushPath(
              '${RouteNames.customerTracking}?orderId=${Uri.encodeComponent(order.id)}')),
      if (_canCancel(order.status))
        _ActionChipButton(
            icon: Icons.cancel_outlined,
            label: 'إلغاء الطلب',
            onTap: () =>
                context.pushPath('${RouteNames.orderCancel}/${order.id}')),
      _ActionChipButton(
          icon: Icons.chat_bubble_outline,
          label: 'المحادثة',
          onTap: () => context.pushPath(_chatUrl(order))),
      if (_canRequestReturn(order.status))
        _ActionChipButton(
            icon: Icons.star_outline,
            label: 'تقييم الطلب',
            onTap: () => context
                .pushPath('${RouteNames.customerOrderReview}/${order.id}')),
    ]);
  }
}

class _ActionChipButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionChipButton(
      {required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w800),
              ),
            ]),
          ),
        ),
      );
}

class _TimelineCard extends StatelessWidget {
  final _OrderDetail order;
  const _TimelineCard({required this.order});
  @override
  Widget build(BuildContext context) {
    final current = _statusIndex(order.status);
    final steps = const [
      ('تم إنشاء الطلب', 'تم استلام الطلب وحفظه في حسابك.'),
      ('تأكيد التاجر', 'يتأكد التاجر من توفر القطع والكميات.'),
      ('قيد التجهيز', 'يتم تجهيز القطع وتجميع الطلب.'),
      ('جاهز/قيد التوصيل', 'الطلب جاهز للاستلام أو خرج للتوصيل.'),
      ('مكتمل', 'تم التسليم وإغلاق الطلب.'),
    ];
    return _Card(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('مسار الطلب', style: AppTextStyles.title),
      const SizedBox(height: AppSpacing.md),
      for (var i = 0; i < steps.length; i++)
        _TimelineStep(
            title: steps[i].$1,
            subtitle: steps[i].$2,
            done: i <= current,
            last: i == steps.length - 1),
    ]));
  }
}

class _TimelineStep extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool done;
  final bool last;
  const _TimelineStep(
      {required this.title,
      required this.subtitle,
      required this.done,
      required this.last});
  @override
  Widget build(BuildContext context) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Column(children: [
          CircleAvatar(
              radius: 16,
              backgroundColor: done ? AppColors.success : AppColors.surfaceAlt,
              child: Icon(done ? Icons.check : Icons.more_horiz,
                  color: done ? Colors.white : AppColors.iconAccent, size: 18)),
          if (!last)
            Container(
                width: 2,
                height: 48,
                color: done ? AppColors.success : AppColors.border),
        ]),
        const SizedBox(width: AppSpacing.md),
        Expanded(
            child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: AppTextStyles.title.copyWith(fontSize: 16)),
                      const SizedBox(height: AppSpacing.xs),
                      Text(subtitle, style: AppTextStyles.bodySecondary)
                    ]))),
      ]);
}

class _ProviderCard extends StatelessWidget {
  final _OrderDetail order;
  const _ProviderCard({required this.order});
  @override
  Widget build(BuildContext context) =>
      _InfoPanel(title: 'بيانات المتجر والفرع', children: [
        _InfoLine(
            icon: Icons.storefront_outlined,
            label: 'المتجر',
            value:
                order.merchantName.isEmpty ? 'متجر غيارك' : order.merchantName),
        _InfoLine(
            icon: Icons.location_city_outlined,
            label: 'الفرع',
            value: order.branchName.isEmpty ? 'غير محدد' : order.branchName),
        if (order.branchAddress.isNotEmpty)
          _InfoLine(
              icon: Icons.place_outlined,
              label: 'عنوان الفرع',
              value: order.branchAddress),
        if (order.branchPhone.isNotEmpty)
          _InfoLine(
              icon: Icons.phone_outlined,
              label: 'هاتف الفرع',
              value: order.branchPhone),
      ]);
}

class _PaymentDeliveryCard extends StatelessWidget {
  final _OrderDetail order;
  const _PaymentDeliveryCard({required this.order});
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
            child: _SmallInfoCard(
                icon: Icons.payments_outlined,
                title: 'الدفع',
                value: _paymentMethodLabel(order.paymentMethod),
                subtitle: _paymentStatusLabel(order.paymentStatus),
                color: _isPaid(order.paymentStatus)
                    ? AppColors.success
                    : AppColors.gold)),
        const SizedBox(width: AppSpacing.md),
        Expanded(
            child: _SmallInfoCard(
                icon: order.fulfillmentMethod.toUpperCase() == 'DELIVERY'
                    ? Icons.local_shipping_outlined
                    : Icons.storefront_outlined,
                title: 'الاستلام',
                value: _fulfillmentLabel(order.fulfillmentMethod),
                subtitle: order.deliveryAddress.isEmpty
                    ? 'العنوان غير محدد'
                    : order.deliveryAddress,
                color: AppColors.primary)),
      ]);
}

class _SmallInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  const _SmallInfoCard(
      {required this.icon,
      required this.title,
      required this.value,
      required this.subtitle,
      required this.color});
  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: 140),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: _cardDecoration(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: AppSpacing.sm),
          Text(title, style: AppTextStyles.bodySecondary),
          const SizedBox(height: 4),
          Text(value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.title.copyWith(fontSize: 15)),
          const SizedBox(height: 4),
          Text(subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySecondary
                  .copyWith(color: color, fontWeight: FontWeight.w800)),
        ]),
      );
}

class _NotesCard extends StatelessWidget {
  final _OrderDetail order;
  const _NotesCard({required this.order});
  @override
  Widget build(BuildContext context) =>
      _InfoPanel(title: 'ملاحظات الطلب', children: [
        if (order.customerNote.isNotEmpty)
          _InfoLine(
              icon: Icons.notes_outlined,
              label: 'ملاحظة العميل',
              value: order.customerNote),
        if (order.cancellationReason.isNotEmpty)
          _InfoLine(
              icon: Icons.cancel_outlined,
              label: 'سبب الإلغاء/الرفض',
              value: order.cancellationReason),
      ]);
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String trailing;
  const _SectionTitle({required this.title, required this.trailing});
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(child: Text(title, style: AppTextStyles.heading2)),
        Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(12)),
            child: Text(trailing,
                style: AppTextStyles.body.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.w800))),
      ]);
}

class _OrderItemCard extends StatelessWidget {
  final _OrderItem item;
  const _OrderItemCard({required this.item});
  @override
  Widget build(BuildContext context) => _Card(
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.inventory_2_outlined,
                color: AppColors.primary)),
        const SizedBox(width: AppSpacing.md),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.title.copyWith(fontSize: 15)),
          const SizedBox(height: AppSpacing.xs),
          Text(item.providerName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySecondary),
          const SizedBox(height: AppSpacing.xs),
          if (item.sku.isNotEmpty)
            Text('SKU: ${item.sku}',
                style: AppTextStyles.bodySecondary.copyWith(fontSize: 12)),
          const SizedBox(height: AppSpacing.sm),
          Text('${item.quantity} × ${_money(item.unitPrice, item.currency)}',
              style: AppTextStyles.bodySecondary
                  .copyWith(fontWeight: FontWeight.w700)),
        ])),
        const SizedBox(width: AppSpacing.sm),
        Text(_money(item.lineTotal, item.currency),
            style: AppTextStyles.title
                .copyWith(color: AppColors.secondary, fontSize: 15)),
      ]));
}

class _TotalsCard extends StatelessWidget {
  final _OrderDetail order;
  const _TotalsCard({required this.order});
  @override
  Widget build(BuildContext context) => _Card(
          child: Column(children: [
        _amountRow('المجموع الفرعي', order.subtotal, order.currency),
        const SizedBox(height: AppSpacing.sm),
        _amountRow('الخصم', order.discount, order.currency,
            color: AppColors.success),
        const SizedBox(height: AppSpacing.sm),
        _amountRow('رسوم التوصيل', order.deliveryFee, order.currency),
        const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Divider(color: AppColors.border, height: 1)),
        _amountRow('الإجمالي', order.total, order.currency,
            isTotal: true, color: AppColors.secondary),
      ]));
  Widget _amountRow(String label, double value, String currency,
          {bool isTotal = false, Color? color}) =>
      Row(children: [
        Expanded(
            child: Text(label,
                style: (isTotal ? AppTextStyles.title : AppTextStyles.body)
                    .copyWith(
                        color: isTotal
                            ? AppColors.textPrimary
                            : AppColors.textSecondary))),
        Text(_money(value, currency),
            style: (isTotal ? AppTextStyles.heading2 : AppTextStyles.body)
                .copyWith(
                    color: color ?? AppColors.textPrimary,
                    fontWeight: FontWeight.w800)),
      ]);
}

class _FeesCard extends StatelessWidget {
  final List<_OrderFee> fees;
  const _FeesCard({required this.fees});
  @override
  Widget build(BuildContext context) =>
      _InfoPanel(title: 'الرسوم والتخفيضات', children: [
        for (final fee in fees)
          _InfoLine(
              icon: fee.amount < 0
                  ? Icons.local_offer_outlined
                  : Icons.receipt_long_outlined,
              label: fee.label,
              value: _money(fee.amount, fee.currency)),
      ]);
}

class _InvoicePanel extends ConsumerWidget {
  final String orderId;
  final _OrderDetail order;
  const _InvoicePanel({required this.orderId, required this.order});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoice = ref.watch(_orderInvoiceProvider(orderId));
    return _Card(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.receipt_long_outlined, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text('فاتورة الطلب', style: AppTextStyles.title)),
        TextButton.icon(
            onPressed: () => _showInvoice(context, ref, orderId),
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('عرض')),
      ]),
      const SizedBox(height: AppSpacing.sm),
      invoice.when(
        loading: () => const LinearProgressIndicator(minHeight: 3),
        error: (e, _) => Text('تعذر تحميل الفاتورة: $e',
            style:
                AppTextStyles.bodySecondary.copyWith(color: AppColors.error)),
        data: (bundle) =>
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _InfoLine(
              icon: Icons.tag_outlined,
              label: 'رقم الفاتورة',
              value: bundle.invoice.invoiceNumber),
          const Divider(height: 20, color: AppColors.border),
          _InfoLine(
              icon: Icons.payments_outlined,
              label: 'إجمالي الفاتورة',
              value:
                  _money(bundle.invoice.totalAmount, bundle.invoice.currency)),
          const Divider(height: 20, color: AppColors.border),
          _InfoLine(
              icon: Icons.event_available_outlined,
              label: 'تاريخ الإصدار',
              value: bundle.invoice.issuedAt),
        ]),
      ),
    ]));
  }
}

class _HistoryCard extends StatelessWidget {
  final List<_OrderHistory> history;
  const _HistoryCard({required this.history});
  @override
  Widget build(BuildContext context) =>
      _InfoPanel(title: 'سجل حالات الطلب', children: [
        for (final item in history)
          _InfoLine(
              icon: Icons.history_outlined,
              label: _statusInfo(item.status).label,
              value: [
                if (item.note.isNotEmpty) item.note,
                if (item.createdAt.isNotEmpty) item.createdAt
              ].join(' - ')),
      ]);
}

class _ActionPanel extends StatelessWidget {
  final _OrderDetail order;
  const _ActionPanel({required this.order});
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        AppButton(
            text: 'تتبع هذا الطلب',
            onPressed: () => context.pushPath(
                '${RouteNames.customerTracking}?orderId=${Uri.encodeComponent(order.id)}')),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
            text: 'محادثة المتجر',
            isOutlined: true,
            onPressed: () => context.pushPath(_chatUrl(order))),
        if (_canCancel(order.status)) ...[
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
              onPressed: () =>
                  context.pushPath('${RouteNames.orderCancel}/${order.id}'),
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('إلغاء الطلب')),
        ],
        if (_canRequestReturn(order.status)) ...[
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
              onPressed: () =>
                  context.pushPath('${RouteNames.orderReturn}/${order.id}'),
              icon: const Icon(Icons.assignment_return_outlined),
              label: const Text('طلب إرجاع أو استبدال')),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
              onPressed: () =>
                  context.pushPath('${RouteNames.orderDispute}/${order.id}'),
              icon: const Icon(Icons.gavel_outlined),
              label: const Text('فتح نزاع أو شكوى')),
        ],
        if (_canReview(order.status)) ...[
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
              onPressed: () => context
                  .pushPath('${RouteNames.customerOrderReview}/${order.id}'),
              icon: const Icon(Icons.star_outline),
              label: const Text('تقييم المتجر والطلب')),
        ],
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
            onPressed: () => context.pushPath(RouteNames.customerSupport),
            icon: const Icon(Icons.support_agent_outlined),
            label: const Text('التواصل مع الدعم')),
      ]);
}

class _InfoPanel extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _InfoPanel({required this.title, required this.children});
  @override
  Widget build(BuildContext context) => _Card(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: AppTextStyles.title),
        const SizedBox(height: AppSpacing.md),
        for (var i = 0; i < children.length; i++) ...[
          children[i],
          if (i != children.length - 1)
            const Divider(height: 22, color: AppColors.border)
        ],
      ]));
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoLine(
      {required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: AppColors.iconAccent, size: 22),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: AppTextStyles.bodySecondary),
          const SizedBox(height: 2),
          Text(value.trim().isEmpty ? 'غير محدد' : value,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w800)),
        ])),
      ]);
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: _cardDecoration(),
      child: child);
}

class _EmptyItemsCard extends StatelessWidget {
  const _EmptyItemsCard();
  @override
  Widget build(BuildContext context) => _Card(
          child: Column(children: [
        const Icon(Icons.inventory_2_outlined,
            color: AppColors.iconAccent, size: 42),
        const SizedBox(height: AppSpacing.md),
        Text('لا توجد عناصر ظاهرة لهذا الطلب', style: AppTextStyles.title),
        const SizedBox(height: AppSpacing.sm),
        Text('تم تحميل الطلب، لكن تفاصيل المنتجات غير متاحة من الخادم.',
            textAlign: TextAlign.center, style: AppTextStyles.bodySecondary),
      ]));
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

class _OrderDetail {
  final String id;
  final String organizationId;
  final String orderNumber;
  final String status;
  final String paymentStatus;
  final double subtotal;
  final double discount;
  final double deliveryFee;
  final double total;
  final String currency;
  final String createdAt;
  final String updatedAt;
  final String fulfillmentMethod;
  final String paymentMethod;
  final String merchantName;
  final String branchName;
  final String branchPhone;
  final String branchAddress;
  final String deliveryAddress;
  final String customerNote;
  final String cancellationReason;
  final List<_OrderItem> items;
  final List<_OrderFee> fees;
  final List<_OrderHistory> statusHistory;
  const _OrderDetail(
      {required this.id,
      required this.organizationId,
      required this.orderNumber,
      required this.status,
      required this.paymentStatus,
      required this.subtotal,
      required this.discount,
      required this.deliveryFee,
      required this.total,
      required this.currency,
      required this.createdAt,
      required this.updatedAt,
      required this.fulfillmentMethod,
      required this.paymentMethod,
      required this.merchantName,
      required this.branchName,
      required this.branchPhone,
      required this.branchAddress,
      required this.deliveryAddress,
      required this.customerNote,
      required this.cancellationReason,
      required this.items,
      required this.fees,
      required this.statusHistory});
  String get createdAtLabel =>
      createdAt.isEmpty ? 'تاريخ الطلب غير محدد' : createdAt;
  factory _OrderDetail.fromMap(Map<String, dynamic> map) {
    final organization = _map(map['organization']);
    final branch = _map(map['branch']);
    final address = _map(
        map['customerAddress'] ?? map['customer_address'] ?? map['address']);
    final itemsRaw =
        _list(map['items'] ?? map['orderItems'] ?? map['order_items']);
    final parsedItems =
        itemsRaw.map((item) => _OrderItem.fromMap(item, organization)).toList();
    final subtotal = _double(map['subtotal'] ??
        map['subTotal'] ??
        map['subtotalAmount'] ??
        map['subtotal_amount'] ??
        parsedItems.fold<double>(0, (sum, item) => sum + item.lineTotal));
    final total = _double(
        map['totalAmount'] ?? map['total_amount'] ?? map['total'] ?? subtotal);
    return _OrderDetail(
      id: (map['id'] ?? '').toString(),
      organizationId: (map['organizationId'] ??
              map['organization_id'] ??
              organization['id'] ??
              '')
          .toString(),
      orderNumber:
          (map['orderNumber'] ?? map['order_number'] ?? map['id'] ?? 'طلب')
              .toString(),
      status: (map['status'] ?? '').toString(),
      paymentStatus:
          (map['paymentStatus'] ?? map['payment_status'] ?? '').toString(),
      subtotal: subtotal,
      discount: _double(
          map['discount'] ?? map['discountAmount'] ?? map['discount_amount']),
      deliveryFee: _double(map['deliveryFee'] ?? map['delivery_fee']),
      total: total,
      currency: (map['currency'] ?? 'YER').toString(),
      createdAt: (map['createdAt'] ?? map['created_at'] ?? '').toString(),
      updatedAt: (map['updatedAt'] ?? map['updated_at'] ?? '').toString(),
      fulfillmentMethod:
          (map['fulfillmentMethod'] ?? map['fulfillment_method'] ?? '')
              .toString(),
      paymentMethod:
          (map['paymentMethod'] ?? map['payment_method'] ?? '').toString(),
      merchantName: (organization['displayName'] ??
              organization['display_name'] ??
              organization['name'] ??
              organization['name_ar'] ??
              '')
          .toString(),
      branchName: (branch['branchName'] ??
              branch['branch_name'] ??
              branch['name'] ??
              '')
          .toString(),
      branchPhone: (branch['phone'] ?? '').toString(),
      branchAddress:
          (branch['addressLine1'] ?? branch['address_line_1'] ?? '').toString(),
      deliveryAddress: (address['addressLine1'] ??
              address['address_line_1'] ??
              address['fullAddress'] ??
              address['full_address'] ??
              '')
          .toString(),
      customerNote:
          (map['customerNote'] ?? map['customer_note'] ?? '').toString(),
      cancellationReason:
          (map['cancellationReason'] ?? map['cancellation_reason'] ?? '')
              .toString(),
      items: parsedItems,
      fees: _list(map['fees']).map(_OrderFee.fromMap).toList(),
      statusHistory: _list(map['statusHistory'] ?? map['status_history'])
          .map(_OrderHistory.fromMap)
          .toList(),
    );
  }
}

class _OrderItem {
  final String title;
  final String providerName;
  final String sku;
  final int quantity;
  final double unitPrice;
  final double lineTotal;
  final String currency;
  const _OrderItem(
      {required this.title,
      required this.providerName,
      required this.sku,
      required this.quantity,
      required this.unitPrice,
      required this.lineTotal,
      required this.currency});
  factory _OrderItem.fromMap(
      Map<String, dynamic> map, Map<String, dynamic> orderOrganization) {
    final listing = _map(map['listing']);
    final product = _map(map['product'] ?? listing['product']);
    final organization = _map(map['organization'] ?? listing['organization']);
    final quantity = _int(map['quantity'], fallback: 1);
    final unitPrice = _double(map['unitPrice'] ??
        map['unit_price'] ??
        map['price'] ??
        listing['unitPrice'] ??
        listing['unit_price'] ??
        listing['salePrice'] ??
        listing['sale_price']);
    return _OrderItem(
      title: (map['productName'] ??
              map['product_name'] ??
              map['title'] ??
              product['nameAr'] ??
              product['name_ar'] ??
              listing['title'] ??
              'قطعة')
          .toString(),
      providerName: (map['providerName'] ??
              map['provider_name'] ??
              organization['displayName'] ??
              organization['display_name'] ??
              orderOrganization['displayName'] ??
              orderOrganization['display_name'] ??
              'متجر')
          .toString(),
      sku: (map['sku'] ?? listing['sku'] ?? product['sku'] ?? '').toString(),
      quantity: quantity,
      unitPrice: unitPrice,
      lineTotal: _double(map['lineTotal'] ??
          map['line_total'] ??
          map['totalAmount'] ??
          map['total_amount'] ??
          map['total'] ??
          unitPrice * quantity),
      currency: (map['currency'] ?? listing['currency'] ?? 'YER').toString(),
    );
  }
}

class _OrderFee {
  final String label;
  final double amount;
  final String currency;
  const _OrderFee(
      {required this.label, required this.amount, required this.currency});
  factory _OrderFee.fromMap(Map<String, dynamic> map) => _OrderFee(
      label: (map['label'] ?? map['feeType'] ?? map['fee_type'] ?? 'رسوم')
          .toString(),
      amount: _double(map['amount']),
      currency: (map['currency'] ?? 'YER').toString());
}

class _OrderHistory {
  final String status;
  final String note;
  final String createdAt;
  const _OrderHistory(
      {required this.status, required this.note, required this.createdAt});
  factory _OrderHistory.fromMap(Map<String, dynamic> map) => _OrderHistory(
      status: (map['status'] ?? '').toString(),
      note: (map['note'] ?? '').toString(),
      createdAt: (map['createdAt'] ?? map['created_at'] ?? '').toString());
}

class _InvoiceBundle {
  final _InvoiceData invoice;
  final List<_InvoiceLine> lines;
  final _ShipmentData? shipment;
  const _InvoiceBundle(
      {required this.invoice, required this.lines, required this.shipment});
  factory _InvoiceBundle.fromMap(Map<String, dynamic> map) {
    return _InvoiceBundle(
        invoice: _InvoiceData.fromMap(_map(map['invoice'])),
        lines: _list(map['lines']).map(_InvoiceLine.fromMap).toList(),
        shipment: map['shipment'] == null
            ? null
            : _ShipmentData.fromMap(_map(map['shipment'])));
  }
}

class _InvoiceData {
  final String invoiceNumber;
  final String status;
  final double subtotalAmount;
  final double discountAmount;
  final double taxAmount;
  final double deliveryFee;
  final double totalAmount;
  final String currency;
  final String issuedAt;
  const _InvoiceData(
      {required this.invoiceNumber,
      required this.status,
      required this.subtotalAmount,
      required this.discountAmount,
      required this.taxAmount,
      required this.deliveryFee,
      required this.totalAmount,
      required this.currency,
      required this.issuedAt});
  factory _InvoiceData.fromMap(Map<String, dynamic> map) => _InvoiceData(
      invoiceNumber:
          (map['invoiceNumber'] ?? map['invoice_number'] ?? '').toString(),
      status: (map['status'] ?? '').toString(),
      subtotalAmount: _double(map['subtotalAmount'] ?? map['subtotal_amount']),
      discountAmount: _double(map['discountAmount'] ?? map['discount_amount']),
      taxAmount: _double(map['taxAmount'] ?? map['tax_amount']),
      deliveryFee: _double(map['deliveryFee'] ?? map['delivery_fee']),
      totalAmount: _double(map['totalAmount'] ?? map['total_amount']),
      currency: (map['currency'] ?? 'YER').toString(),
      issuedAt: (map['issuedAt'] ?? map['issued_at'] ?? '').toString());
}

class _InvoiceLine {
  final String productName;
  final int quantity;
  final double unitPrice;
  final double totalAmount;
  const _InvoiceLine(
      {required this.productName,
      required this.quantity,
      required this.unitPrice,
      required this.totalAmount});
  factory _InvoiceLine.fromMap(Map<String, dynamic> map) => _InvoiceLine(
      productName:
          (map['productName'] ?? map['product_name'] ?? 'قطعة').toString(),
      quantity: _int(map['quantity'], fallback: 1),
      unitPrice: _double(map['unitPrice'] ?? map['unit_price']),
      totalAmount: _double(map['totalAmount'] ?? map['total_amount']));
}

class _ShipmentData {
  final String status;
  final String trackingNumber;
  final String companyName;
  final String driverName;
  final List<_OrderHistory> tracking;
  const _ShipmentData(
      {required this.status,
      required this.trackingNumber,
      required this.companyName,
      required this.driverName,
      required this.tracking});
  factory _ShipmentData.fromMap(Map<String, dynamic> map) => _ShipmentData(
      status: (map['status'] ?? '').toString(),
      trackingNumber:
          (map['tracking_number'] ?? map['trackingNumber'] ?? '').toString(),
      companyName: (map['shipping_company_name'] ?? '').toString(),
      driverName: (map['driver_name'] ?? '').toString(),
      tracking: _list(map['tracking'])
          .map((e) => _OrderHistory.fromMap({
                'status': e['status'],
                'note': e['note'],
                'createdAt': e['created_at']
              }))
          .toList());
}

Future<void> _showInvoice(
    BuildContext context, WidgetRef ref, String orderId) async {
  final bundle = await ref.read(_orderInvoiceProvider(orderId).future);
  if (!context.mounted) return;
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: .82,
      minChildSize: .45,
      maxChildSize: .95,
      builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text('فاتورة ${bundle.invoice.invoiceNumber}',
                style: AppTextStyles.heading2),
            const SizedBox(height: AppSpacing.md),
            _InfoLine(
                icon: Icons.event_outlined,
                label: 'تاريخ الإصدار',
                value: bundle.invoice.issuedAt),
            const Divider(height: 24),
            for (final line in bundle.lines)
              Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(children: [
                    Expanded(
                        child: Text(
                            '${line.productName}\n${line.quantity} × ${_money(line.unitPrice, bundle.invoice.currency)}',
                            style: AppTextStyles.body)),
                    Text(_money(line.totalAmount, bundle.invoice.currency),
                        style: AppTextStyles.title
                            .copyWith(color: AppColors.secondary))
                  ])),
            const Divider(height: 24),
            _invoiceAmount('المجموع الفرعي', bundle.invoice.subtotalAmount,
                bundle.invoice.currency),
            _invoiceAmount('الخصم', bundle.invoice.discountAmount,
                bundle.invoice.currency),
            _invoiceAmount(
                'الضريبة', bundle.invoice.taxAmount, bundle.invoice.currency),
            _invoiceAmount(
                'التوصيل', bundle.invoice.deliveryFee, bundle.invoice.currency),
            const Divider(height: 24),
            _invoiceAmount(
                'الإجمالي', bundle.invoice.totalAmount, bundle.invoice.currency,
                total: true),
            if (bundle.shipment != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Text('بيانات الشحنة', style: AppTextStyles.title),
              const SizedBox(height: AppSpacing.sm),
              _InfoLine(
                  icon: Icons.local_shipping_outlined,
                  label: 'الحالة',
                  value: bundle.shipment!.status),
              _InfoLine(
                  icon: Icons.confirmation_number_outlined,
                  label: 'رقم التتبع',
                  value: bundle.shipment!.trackingNumber),
              _InfoLine(
                  icon: Icons.business_outlined,
                  label: 'شركة الشحن',
                  value: bundle.shipment!.companyName),
              _InfoLine(
                  icon: Icons.person_outline,
                  label: 'السائق',
                  value: bundle.shipment!.driverName),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppButton(
                text: 'نسخ الفاتورة',
                onPressed: () => _copyInvoice(context, bundle)),
          ]),
    ),
  );
}

Widget _invoiceAmount(String label, double value, String currency,
        {bool total = false}) =>
    Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(children: [
          Expanded(
              child: Text(label,
                  style: total
                      ? AppTextStyles.title
                      : AppTextStyles.bodySecondary)),
          Text(_money(value, currency),
              style: (total ? AppTextStyles.heading2 : AppTextStyles.body)
                  .copyWith(
                      color:
                          total ? AppColors.secondary : AppColors.textPrimary,
                      fontWeight: FontWeight.w800))
        ]));

void _copyInvoice(BuildContext context, _InvoiceBundle bundle) {
  final b = StringBuffer()
    ..writeln('فاتورة: ${bundle.invoice.invoiceNumber}')
    ..writeln('تاريخ الإصدار: ${bundle.invoice.issuedAt}')
    ..writeln('---')
    ..writeln('القطع:');
  for (final line in bundle.lines) {
    b.writeln(
        '- ${line.productName}: ${line.quantity} × ${line.unitPrice.toStringAsFixed(0)} = ${line.totalAmount.toStringAsFixed(0)}');
  }
  b
    ..writeln('---')
    ..writeln(
        'الإجمالي: ${_money(bundle.invoice.totalAmount, bundle.invoice.currency)}');
  Clipboard.setData(ClipboardData(text: b.toString()));
  ScaffoldMessenger.of(context)
      .showSnackBar(const SnackBar(content: Text('تم نسخ الفاتورة')));
}

void _copyOrderSummary(BuildContext context, _OrderDetail order) {
  final b = StringBuffer()
    ..writeln('طلب: ${order.orderNumber}')
    ..writeln('الحالة: ${_statusInfo(order.status).label}')
    ..writeln('المتجر: ${order.merchantName}')
    ..writeln(
        'الدفع: ${_paymentMethodLabel(order.paymentMethod)} - ${_paymentStatusLabel(order.paymentStatus)}')
    ..writeln('الإجمالي: ${_money(order.total, order.currency)}');
  Clipboard.setData(ClipboardData(text: b.toString()));
  ScaffoldMessenger.of(context)
      .showSnackBar(const SnackBar(content: Text('تم نسخ ملخص الطلب')));
}

String _chatUrl(_OrderDetail order) =>
    '${RouteNames.customerChat}?listingId=order-${Uri.encodeComponent(order.id)}&listingTitle=${Uri.encodeComponent('طلب ${order.orderNumber}')}&providerName=${Uri.encodeComponent(order.merchantName.isEmpty ? 'المتجر' : order.merchantName)}&providerTypeLabel=${Uri.encodeComponent('متجر')}&serviceLabel=${Uri.encodeComponent('متابعة طلب')}';

BoxDecoration _cardDecoration() => BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadow, blurRadius: 12, offset: Offset(0, 6))
        ]);

({String label, IconData icon}) _statusInfo(String status) {
  switch (status.toUpperCase()) {
    case 'PENDING':
      return (label: 'طلب جديد', icon: Icons.schedule_outlined);
    case 'CONFIRMED':
      return (label: 'مؤكد', icon: Icons.verified_outlined);
    case 'PREPARING':
      return (label: 'قيد التجهيز', icon: Icons.handyman_outlined);
    case 'READY_FOR_PICKUP':
      return (label: 'جاهز للاستلام', icon: Icons.storefront_outlined);
    case 'OUT_FOR_DELIVERY':
      return (label: 'قيد التوصيل', icon: Icons.local_shipping_outlined);
    case 'COMPLETED':
      return (label: 'مكتمل', icon: Icons.check_circle_outline);
    case 'CANCELLED':
      return (label: 'ملغي', icon: Icons.cancel_outlined);
    case 'REJECTED':
      return (label: 'مرفوض', icon: Icons.block_outlined);
    default:
      return (
        label: status.isEmpty ? 'غير محدد' : status,
        icon: Icons.receipt_long_outlined
      );
  }
}

int _statusIndex(String status) {
  switch (status.toUpperCase()) {
    case 'PENDING':
      return 0;
    case 'CONFIRMED':
      return 1;
    case 'PREPARING':
      return 2;
    case 'READY_FOR_PICKUP':
    case 'OUT_FOR_DELIVERY':
      return 3;
    case 'COMPLETED':
      return 4;
    case 'CANCELLED':
    case 'REJECTED':
      return 0;
    default:
      return 0;
  }
}

bool _canCancel(String status) =>
    ['PENDING', 'CREATED', 'CONFIRMED'].contains(status.toUpperCase());
bool _canRequestReturn(String status) => status.toUpperCase() == 'COMPLETED';
bool _canReview(String status) => status.toUpperCase() == 'COMPLETED';
bool _isPaid(String status) => ['PAID', 'CONFIRMED', 'CAPTURED', 'REFUNDED']
    .contains(status.toUpperCase());

String _paymentStatusLabel(String status) {
  switch (status.toUpperCase()) {
    case 'UNPAID':
      return 'غير مدفوع';
    case 'PENDING':
      return 'بانتظار الدفع';
    case 'PENDING_REVIEW':
      return 'قيد المراجعة';
    case 'CONFIRMED':
    case 'PAID':
      return 'مدفوع';
    case 'FAILED':
      return 'فشل الدفع';
    case 'REFUNDED':
      return 'مسترد';
    default:
      return status.isEmpty ? 'غير محدد' : status;
  }
}

String _paymentMethodLabel(String value) {
  switch (value.toUpperCase()) {
    case 'CASH_ON_DELIVERY':
      return 'الدفع عند التوصيل';
    case 'CASH_ON_PICKUP':
      return 'الدفع عند الاستلام';
    case 'BANK_TRANSFER':
      return 'تحويل بنكي/محفظة خارجية';
    case 'WALLET':
      return 'محفظة غيارك';
    default:
      return value.isEmpty ? 'غير محدد' : value;
  }
}

String _fulfillmentLabel(String value) {
  switch (value.toUpperCase()) {
    case 'DELIVERY':
      return 'توصيل';
    case 'PICKUP':
      return 'استلام من الفرع';
    default:
      return value.isEmpty ? 'غير محدد' : value;
  }
}

String _money(double value, String currency) =>
    '${value.toStringAsFixed(0)} $currency';

double _double(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

int _int(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

Map<String, dynamic> _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
List<Map<String, dynamic>> _list(dynamic value) => value is List
    ? value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
    : <Map<String, dynamic>>[];
