import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/features/logistics/data/logistics_repository.dart';
import 'package:ghiyarak/features/logistics/data/models/logistics_models.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';

final _myPaymentsProvider =
    FutureProvider.autoDispose<List<PaymentTransactionModel>>(
        (ref) => ref.read(logisticsRepositoryProvider).myPayments());

class PaymentStatusPage extends ConsumerStatefulWidget {
  final String paymentId;
  const PaymentStatusPage({super.key, required this.paymentId});

  @override
  ConsumerState<PaymentStatusPage> createState() => _PaymentStatusPageState();
}

class _PaymentStatusPageState extends ConsumerState<PaymentStatusPage> {
  final _url = TextEditingController();
  final _reference = TextEditingController();
  bool _busy = false;

  Future<void> _upload() async {
    setState(() => _busy = true);
    try {
      await ref.read(logisticsRepositoryProvider).uploadPaymentProof(
          widget.paymentId,
          fileUrl: _url.text.trim(),
          referenceNumber: _reference.text.trim());
      ref.invalidate(_myPaymentsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم رفع الإثبات للمراجعة')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final payments = ref.watch(_myPaymentsProvider);
    return AppScaffold(
      title: 'حالة الدفع',
      child: payments.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (items) {
          PaymentTransactionModel? payment;
          for (final item in items) {
            if (item.id.toString() == widget.paymentId) {
              payment = item;
              break;
            }
          }
          if (payment == null) {
            return const Center(child: Text('لم يتم العثور على عملية الدفع.'));
          }
          final needsProof = [
            'WAITING_PROOF',
            'UNDER_REVIEW',
            'PENDING_REVIEW',
            'REJECTED'
          ].contains(payment.status);
          return ListView(children: [
            Card(
                child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('المرجع: ${payment.reference}',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: AppSpacing.xs),
                          Text('الحالة: ${payment.status}'),
                          Text(
                              'المبلغ: ${payment.amount.toStringAsFixed(0)} ${payment.currency}'),
                        ]))),
            if (needsProof) ...[
              const SizedBox(height: AppSpacing.lg),
              TextField(
                  controller: _url,
                  decoration: const InputDecoration(
                      labelText: 'رابط صورة/ملف إثبات التحويل')),
              const SizedBox(height: AppSpacing.md),
              TextField(
                  controller: _reference,
                  decoration:
                      const InputDecoration(labelText: 'رقم مرجع العملية')),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                  text: _busy ? 'جاري الرفع...' : 'رفع الإثبات',
                  onPressed: _busy ? null : _upload),
            ],
          ]);
        },
      ),
    );
  }
}
