import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/navigation/app_navigation.dart';
import 'package:ghiyarak/core/theme/app_colors.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/features/orders/data/orders_repository.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';

class OrderDetailsPage extends ConsumerStatefulWidget {
  final String orderId;
  const OrderDetailsPage({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends ConsumerState<OrderDetailsPage> {
  late Future<Map<String, dynamic>> _future;
  bool _cancelling = false;

  @override
  void initState() {
    super.initState();
    _future = ref.read(ordersRepositoryProvider).getOrderDetail(widget.orderId);
  }

  Future<void> _cancel() async {
    setState(() => _cancelling = true);
    try {
      await ref
          .read(ordersRepositoryProvider)
          .cancelOrder(widget.orderId, notes: 'Cancelled by customer');
      if (!mounted) return;
      setState(() {
        _future =
            ref.read(ordersRepositoryProvider).getOrderDetail(widget.orderId);
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('تم إلغاء الطلب')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'تفاصيل الطلب',
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('تعذر تحميل الطلب: ${snapshot.error}'));
          }
          final order = snapshot.data ?? const <String, dynamic>{};
          final items =
              order['items'] is List ? order['items'] as List : const [];
          final invoices =
              order['invoices'] is List ? order['invoices'] as List : const [];
          final canCancel = ['PENDING', 'CONFIRMED']
              .contains((order['status'] ?? '').toString());
          return ListView(
            children: [
              _InfoCard(children: [
                _RowText(
                    'رقم الطلب',
                    (order['orderNumber'] ??
                            order['order_number'] ??
                            order['id'])
                        .toString()),
                _RowText('الحالة', (order['status'] ?? '-').toString()),
                _RowText('الإجمالي',
                    '${order['totalAmount'] ?? order['total_amount'] ?? 0} ${order['currency'] ?? 'YER'}'),
                _RowText('المزود', _nestedName(order['organization'])),
              ]),
              const SizedBox(height: AppSpacing.md),
              _SectionTitle('العناصر'),
              ...items.map((raw) =>
                  _ItemCard(map: Map<String, dynamic>.from(raw as Map))),
              if (invoices.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                _SectionTitle('الفاتورة'),
                _InfoCard(children: [
                  _RowText(
                      'رقم الفاتورة',
                      (Map<String, dynamic>.from(
                                  invoices.first as Map)['invoiceNumber'] ??
                              '-')
                          .toString()),
                ]),
              ],
              if (!['PAID', 'CONFIRMED', 'REFUNDED'].contains(
                  (order['paymentStatus'] ?? order['payment_status'] ?? '')
                      .toString())) ...[
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton.icon(
                  onPressed: () =>
                      context.pushPath(RouteNames.orderPayment(widget.orderId)),
                  icon: const Icon(Icons.payments_outlined),
                  label: const Text('اختيار طريقة الدفع'),
                ),
              ],
              if (canCancel) ...[
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton.icon(
                  onPressed: _cancelling ? null : _cancel,
                  icon: _cancelling
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.cancel_outlined),
                  label: const Text('إلغاء الطلب'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final Map<String, dynamic> map;
  const _ItemCard({required this.map});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                (map['productName'] ?? map['product_name'] ?? 'منتج')
                    .toString(),
                style: Theme.of(context).textTheme.titleMedium),
            Text('الكمية: ${map['quantity']}'),
            Text('السعر: ${map['unitPrice'] ?? map['unit_price'] ?? 0}'),
            Text('الإجمالي: ${map['totalAmount'] ?? map['total_amount'] ?? 0}'),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }
}

class _RowText extends StatelessWidget {
  final String label;
  final String value;
  const _RowText(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w700))),
          Expanded(child: Text(value, textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      );
}

String _nestedName(dynamic raw) {
  if (raw is! Map) return '-';
  final map = Map<String, dynamic>.from(raw);
  return (map['displayName'] ?? map['display_name'] ?? map['name'] ?? '-')
      .toString();
}
