import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/features/logistics/data/logistics_repository.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:ghiyarak/shared/widgets/section_title.dart';
import 'package:go_router/go_router.dart';

final _methodsProvider = FutureProvider.autoDispose<Map<String, dynamic>>(
    (ref) => ref.read(logisticsRepositoryProvider).paymentMethods());

class PaymentSelectionPage extends ConsumerStatefulWidget {
  final String orderId;
  const PaymentSelectionPage({super.key, required this.orderId});

  @override
  ConsumerState<PaymentSelectionPage> createState() =>
      _PaymentSelectionPageState();
}

class _PaymentSelectionPageState extends ConsumerState<PaymentSelectionPage> {
  bool _busy = false;

  Future<void> _select(String code) async {
    setState(() => _busy = true);
    try {
      final payment = await ref
          .read(logisticsRepositoryProvider)
          .createPaymentIntent(widget.orderId, methodCode: code);
      if (!mounted) return;
      final id = (payment['id'] ?? '').toString();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('تم إنشاء عملية الدفع')));
      if (id.isNotEmpty) context.go(RouteNames.paymentStatus(id));
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
    final methods = ref.watch(_methodsProvider);
    return AppScaffold(
      title: 'اختيار طريقة الدفع',
      child: methods.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (response) {
          final items =
              response['data'] is List ? response['data'] as List : const [];
          if (items.isEmpty) {
            return const Center(child: Text('لا توجد طرق دفع مفعلة حالياً.'));
          }
          return ListView.separated(
            itemCount: items.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              if (index == 0) {
                return const SectionTitle(
                    title: 'الدفع الآمن',
                    subtitle:
                        'اختر طريقة دفع. التأكيد يتم من الخادم أو المالية فقط.');
              }
              final map = Map<String, dynamic>.from(items[index - 1] as Map);
              final code = (map['code'] ?? '').toString();
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            (map['nameAr'] ?? map['name_ar'] ?? code)
                                .toString(),
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: AppSpacing.xs),
                        Text((map['instructionsAr'] ??
                                map['instructions_ar'] ??
                                '')
                            .toString()),
                        const SizedBox(height: AppSpacing.md),
                        AppButton(
                            text: _busy ? 'جاري التنفيذ...' : 'اختيار',
                            onPressed: _busy ? null : () => _select(code)),
                      ]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
