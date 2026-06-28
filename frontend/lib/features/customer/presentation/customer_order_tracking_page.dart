import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/theme/app_colors.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/core/theme/app_text_styles.dart';
import 'package:ghiyarak/features/orders/data/models/order_summary_model.dart';
import 'package:ghiyarak/features/orders/data/orders_repository.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';

final _trackingOrdersProvider =
    FutureProvider.autoDispose<List<OrderSummaryModel>>(
        (ref) => ref.watch(ordersRepositoryProvider).getMyOrders());

class CustomerOrderTrackingPage extends ConsumerWidget {
  const CustomerOrderTrackingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(_trackingOrdersProvider);
    return AppScaffold(
      title: 'تتبع الطلبات',
      child: RefreshIndicator(
        onRefresh: () async => ref.invalidate(_trackingOrdersProvider),
        child: orders.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(children: [_Card(text: e.toString())]),
          data: (items) => items.isEmpty
              ? ListView(children: const [_Card(text: 'لا توجد طلبات للتتبع.')])
              : ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) =>
                      _OrderCard(order: items[index]),
                ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderSummaryModel order;
  const _OrderCard({required this.order});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(order.orderNumber, style: AppTextStyles.title),
        const SizedBox(height: AppSpacing.xs),
        Text('الحالة: ${order.status}', style: AppTextStyles.bodySecondary),
        Text('${order.total.toStringAsFixed(0)} ${order.currency}',
            style: AppTextStyles.heading2.copyWith(color: AppColors.primary)),
        if (order.createdAt.isNotEmpty)
          Text(order.createdAt, style: AppTextStyles.bodySecondary),
      ]),
    );
  }
}

class _Card extends StatelessWidget {
  final String text;
  const _Card({required this.text});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border)),
      child: Text(text, style: AppTextStyles.bodySecondary));
}
