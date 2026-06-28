import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/theme/app_colors.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/core/theme/app_text_styles.dart';
import 'package:ghiyarak/features/orders/data/orders_repository.dart';
import 'package:ghiyarak/features/orders/data/models/order_summary_model.dart';
import 'package:ghiyarak/features/logistics/data/logistics_repository.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:ghiyarak/shared/widgets/section_title.dart';

class PaymentsPage extends ConsumerStatefulWidget {
  const PaymentsPage({super.key});

  @override
  ConsumerState<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends ConsumerState<PaymentsPage> {
  bool _busy = false;

  Future<void> _createPayment(String orderId) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(logisticsRepositoryProvider)
          .createBankTransferPayment(orderId);
      ref.invalidate(_ordersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إنشاء عملية الدفع')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(_ordersProvider);
    return AppScaffold(
      title: 'مدفوعات الطلبات',
      child: orders.when(
        data: (items) => ListView.separated(
          itemCount: items.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) {
            if (index == 0) {
              return const SectionTitle(
                  title: 'مدفوعات الطلبات',
                  subtitle:
                      'إنشاء عمليات دفع بنكي ومتابعة حالة الدفع للطلبات.');
            }
            final order = items[index - 1];
            return Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(18)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.orderNumber, style: AppTextStyles.title),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                        '${order.total.toStringAsFixed(0)} ${order.currency} — ${order.status}',
                        style: AppTextStyles.bodySecondary),
                    const SizedBox(height: AppSpacing.md),
                    AppButton(
                        text: _busy
                            ? 'جاري التنفيذ...'
                            : 'إنشاء عملية تحويل بنكي',
                        onPressed: _busy
                            ? null
                            : () => _createPayment(order.id.toString())),
                  ]),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }
}

final AutoDisposeFutureProvider<List<OrderSummaryModel>> _ordersProvider =
    FutureProvider.autoDispose<List<OrderSummaryModel>>(
        (ref) => ref.read(ordersRepositoryProvider).getMyOrders());
