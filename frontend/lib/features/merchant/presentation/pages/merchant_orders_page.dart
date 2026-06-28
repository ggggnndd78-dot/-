import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/features/merchant/data/merchant_market_repository.dart';
import 'package:ghiyarak/features/merchant/data/models/merchant_order_model.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';

class MerchantOrdersPage extends ConsumerStatefulWidget {
  const MerchantOrdersPage({super.key});

  @override
  ConsumerState<MerchantOrdersPage> createState() => _MerchantOrdersPageState();
}

class _MerchantOrdersPageState extends ConsumerState<MerchantOrdersPage> {
  late Future<List<MerchantOrderModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(merchantMarketRepositoryProvider).getMerchantOrders();
  }

  Future<void> _action(String orderId, String action, {String? notes}) async {
    try {
      await ref
          .read(merchantMarketRepositoryProvider)
          .providerAction(orderId: orderId, action: action, notes: notes);
      if (!mounted) return;
      setState(() {
        _future =
            ref.read(merchantMarketRepositoryProvider).getMerchantOrders();
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('تم تحديث حالة الطلب')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  List<Widget> _buttons(MerchantOrderModel item) {
    switch (item.status) {
      case 'PENDING':
        return [
          ElevatedButton(
              onPressed: () => _action(item.id, 'confirm'),
              child: const Text('تأكيد')),
          OutlinedButton(
              onPressed: () =>
                  _action(item.id, 'cancel', notes: 'Cancelled by provider'),
              child: const Text('إلغاء')),
        ];
      case 'CONFIRMED':
        return [
          OutlinedButton(
              onPressed: () => _action(item.id, 'processing'),
              child: const Text('قيد التجهيز'))
        ];
      case 'PROCESSING':
        return [
          OutlinedButton(
              onPressed: () => _action(item.id, 'ready'),
              child: const Text('جاهز للاستلام')),
          OutlinedButton(
              onPressed: () => _action(item.id, 'delivery'),
              child: const Text('خرج للتوصيل')),
        ];
      case 'READY_FOR_PICKUP':
      case 'OUT_FOR_DELIVERY':
        return [
          ElevatedButton(
              onPressed: () => _action(item.id, 'delivered'),
              child: const Text('تم التسليم'))
        ];
      default:
        return const [Text('لا توجد إجراءات متاحة')];
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'طلبات التاجر',
      child: FutureBuilder<List<MerchantOrderModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('تعذر تحميل الطلبات: ${snapshot.error}'));
          }
          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return const Center(child: Text('لا توجد طلبات حالياً'));
          }
          return ListView.separated(
            itemBuilder: (context, index) {
              final item = items[index];
              return InkWell(
                  onTap: () =>
                      context.push(RouteNames.merchantOrderDetails(item.id)),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.orderNumber,
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: AppSpacing.xs),
                          Text('الحالة: ${item.status}'),
                          Text('العميل: ${item.customerName}'),
                          Text(
                              'الإجمالي: ${item.total.toStringAsFixed(0)} YER'),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.xs,
                              children: _buttons(item)),
                        ],
                      ),
                    ),
                  ));
            },
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemCount: items.length,
          );
        },
      ),
    );
  }
}
