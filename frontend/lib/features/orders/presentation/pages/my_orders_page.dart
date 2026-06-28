import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/core/theme/app_colors.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/core/theme/app_text_styles.dart';
import 'package:ghiyarak/features/orders/data/models/order_summary_model.dart';
import 'package:ghiyarak/features/orders/data/orders_repository.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:go_router/go_router.dart';

class MyOrdersPage extends ConsumerWidget {
  const MyOrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final future = ref.watch(_ordersProvider);

    return AppScaffold(
      title: 'ط·ظ„ط¨ط§طھظٹ',
      child: future.when(
        data: (orders) {
          if (orders.isEmpty) {
            return const _OrdersState(
              icon: Icons.receipt_long_outlined,
              title: 'ظ„ط§ طھظˆط¬ط¯ ط·ظ„ط¨ط§طھ ط­طھظ‰ ط§ظ„ط¢ظ†',
              message:
                  'ط¹ظ†ط¯ طھظ†ظپظٹط° ط£ظˆظ„ ط·ظ„ط¨ ط³طھط¸ظ‡ط± طھظپط§طµظٹظ„ظ‡ ظˆط­ط§ظ„طھظ‡ ظ‡ظ†ط§.',
            );
          }

          return ListView.separated(
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              return _OrderCard(order: orders[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _OrdersState(
          icon: Icons.error_outline,
          title: 'طھط¹ط°ط± طھط­ظ…ظٹظ„ ط§ظ„ط·ظ„ط¨ط§طھ',
          message: e.toString(),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final OrderSummaryModel order;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shadowColor: AppColors.shadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.push(RouteNames.orderDetails(order.id)),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: const BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 14,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      color: AppColors.iconAccent,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order.orderNumber, style: AppTextStyles.title),
                        const SizedBox(height: AppSpacing.xs),
                        Text(order.createdAt,
                            style: AppTextStyles.bodySecondary),
                      ],
                    ),
                  ),
                  Text(
                    '${order.total.toStringAsFixed(0)} ${order.currency}',
                    style: AppTextStyles.title.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'ط§ظ„ط­ط§ظ„ط©: ${order.status}',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrdersState extends StatelessWidget {
  const _OrdersState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.iconAccent, size: 44),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

final _ordersProvider = FutureProvider<List<OrderSummaryModel>>(
  (ref) => ref.read(ordersRepositoryProvider).getMyOrders(),
);

final ordersProvider = _ordersProvider;
