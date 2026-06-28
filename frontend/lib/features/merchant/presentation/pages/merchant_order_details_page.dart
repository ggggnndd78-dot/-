import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/features/merchant/data/merchant_market_repository.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';

class MerchantOrderDetailsPage extends ConsumerStatefulWidget {
  final String orderId;
  const MerchantOrderDetailsPage({super.key, required this.orderId});

  @override
  ConsumerState<MerchantOrderDetailsPage> createState() =>
      _MerchantOrderDetailsPageState();
}

class _MerchantOrderDetailsPageState
    extends ConsumerState<MerchantOrderDetailsPage> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = ref
        .read(merchantMarketRepositoryProvider)
        .getMerchantOrderDetail(widget.orderId);
  }

  Future<void> _update(String status) async {
    try {
      await ref.read(merchantMarketRepositoryProvider).providerAction(
          orderId: widget.orderId, action: _actionFromStatus(status));
      if (!mounted) return;
      setState(() {
        _future = ref
            .read(merchantMarketRepositoryProvider)
            .getMerchantOrderDetail(widget.orderId);
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('تم تحديث الطلب')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'تفاصيل طلب التاجر',
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
          final status = (order['status'] ?? '').toString();
          return ListView(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text((order['orderNumber'] ?? order['id']).toString(),
                            style: Theme.of(context).textTheme.titleMedium),
                        Text('الحالة: $status'),
                        Text(
                            'الإجمالي: ${order['totalAmount'] ?? 0} ${order['currency'] ?? 'YER'}'),
                      ]),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: _nextStatuses(status)
                      .map((s) => OutlinedButton(
                          onPressed: () => _update(s), child: Text(s)))
                      .toList()),
              const SizedBox(height: AppSpacing.md),
              ...items.map((raw) {
                final item = Map<String, dynamic>.from(raw as Map);
                return Card(
                    child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Text(
                            '${item['productName'] ?? 'منتج'} × ${item['quantity']}')));
              }),
            ],
          );
        },
      ),
    );
  }
}

List<String> _nextStatuses(String status) {
  switch (status) {
    case 'PENDING':
      return ['CONFIRMED', 'CANCELLED'];
    case 'CONFIRMED':
      return ['PROCESSING', 'CANCELLED'];
    case 'PROCESSING':
      return ['READY_FOR_PICKUP', 'OUT_FOR_DELIVERY', 'CANCELLED'];
    case 'READY_FOR_PICKUP':
    case 'OUT_FOR_DELIVERY':
      return ['DELIVERED'];
    default:
      return const [];
  }
}

String _actionFromStatus(String status) => switch (status) {
      'CONFIRMED' => 'confirm',
      'PROCESSING' => 'processing',
      'READY_FOR_PICKUP' => 'ready',
      'OUT_FOR_DELIVERY' => 'delivery',
      'DELIVERED' => 'delivered',
      'CANCELLED' => 'cancel',
      _ => 'processing',
    };
