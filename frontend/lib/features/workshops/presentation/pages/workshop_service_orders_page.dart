import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/theme/app_colors.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/core/theme/app_text_styles.dart';
import 'package:ghiyarak/features/workshops/data/models/workshop_models.dart';
import 'package:ghiyarak/features/workshops/data/workshops_repository.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:ghiyarak/shared/widgets/section_title.dart';

final workshopServiceOrdersProvider =
    FutureProvider<List<ServiceOrderModel>>((ref) async {
  return ref.watch(workshopsRepositoryProvider).getServiceOrders();
});

class WorkshopServiceOrdersPage extends ConsumerStatefulWidget {
  const WorkshopServiceOrdersPage({super.key});

  @override
  ConsumerState<WorkshopServiceOrdersPage> createState() =>
      _WorkshopServiceOrdersPageState();
}

class _WorkshopServiceOrdersPageState
    extends ConsumerState<WorkshopServiceOrdersPage> {
  bool _loading = false;

  Future<void> _runAction(
      Future<void> Function() action, String message) async {
    setState(() => _loading = true);
    try {
      await action();
      ref.invalidate(workshopServiceOrdersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(workshopServiceOrdersProvider);
    return AppScaffold(
      title: 'أوامر الصيانة',
      child: ListView(
        children: [
          const SectionTitle(
            title: 'تشغيل الورشة',
            subtitle: 'متابعة أمر الصيانة من التشخيص إلى الإصلاح والتسليم.',
          ),
          const SizedBox(height: AppSpacing.lg),
          orders.when(
            data: (items) => items.isEmpty
                ? const _InfoCard(text: 'لا توجد أوامر صيانة بعد')
                : Column(
                    children: items
                        .map((item) => Padding(
                              padding:
                                  const EdgeInsets.only(bottom: AppSpacing.md),
                              child: _ServiceOrderTile(
                                order: item,
                                isLoading: _loading,
                                onDiagnosis: () => _runAction(
                                  () => ref
                                      .read(workshopsRepositoryProvider)
                                      .addDiagnosticReport(item.id),
                                  'تم إضافة تقرير التشخيص',
                                ),
                                onRepair: () => _runAction(
                                  () => ref
                                      .read(workshopsRepositoryProvider)
                                      .updateServiceOrderStatus(
                                        serviceOrderId: item.id,
                                        status: 'IN_REPAIR',
                                        note: 'بدء الإصلاح',
                                      ),
                                  'تم تحويل الأمر إلى قيد الإصلاح',
                                ),
                                onReady: () => _runAction(
                                  () => ref
                                      .read(workshopsRepositoryProvider)
                                      .updateServiceOrderStatus(
                                        serviceOrderId: item.id,
                                        status: 'READY_FOR_DELIVERY',
                                        note: 'السيارة جاهزة للتسليم',
                                      ),
                                  'تم تجهيز أمر الصيانة للتسليم',
                                ),
                                onComplete: () => _runAction(
                                  () => ref
                                      .read(workshopsRepositoryProvider)
                                      .updateServiceOrderStatus(
                                        serviceOrderId: item.id,
                                        status: 'COMPLETED',
                                        note: 'تم إنجاز أمر الصيانة',
                                      ),
                                  'تم إغلاق أمر الصيانة',
                                ),
                              ),
                            ))
                        .toList(),
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _InfoCard(text: e.toString()),
          ),
        ],
      ),
    );
  }
}

class _ServiceOrderTile extends StatelessWidget {
  final ServiceOrderModel order;
  final bool isLoading;
  final VoidCallback onDiagnosis;
  final VoidCallback onRepair;
  final VoidCallback onReady;
  final VoidCallback onComplete;

  const _ServiceOrderTile({
    required this.order,
    required this.isLoading,
    required this.onDiagnosis,
    required this.onRepair,
    required this.onReady,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(order.number.isEmpty ? order.serviceName : order.number,
              style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.xs),
          Text('${order.customerName} • ${order.status}',
              style: AppTextStyles.bodySecondary),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              SizedBox(
                  width: 130,
                  child: AppButton(
                      text: 'تشخيص',
                      isLoading: isLoading,
                      onPressed: onDiagnosis)),
              SizedBox(
                  width: 130,
                  child: AppButton(
                      text: 'إصلاح',
                      isOutlined: true,
                      isLoading: isLoading,
                      onPressed: onRepair)),
              SizedBox(
                  width: 130,
                  child: AppButton(
                      text: 'جاهز',
                      isOutlined: true,
                      isLoading: isLoading,
                      onPressed: onReady)),
              SizedBox(
                  width: 130,
                  child: AppButton(
                      text: 'إغلاق',
                      isOutlined: true,
                      isLoading: isLoading,
                      onPressed: onComplete)),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String text;
  const _InfoCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(text, style: AppTextStyles.bodySecondary),
    );
  }
}
