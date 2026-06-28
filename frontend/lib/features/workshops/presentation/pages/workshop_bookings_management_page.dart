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

final workshopOperationsBookingsProvider =
    FutureProvider<List<WorkshopBookingModel>>((ref) async {
  return ref.watch(workshopsRepositoryProvider).getWorkshopBookings();
});

class WorkshopBookingsManagementPage extends ConsumerStatefulWidget {
  const WorkshopBookingsManagementPage({super.key});

  @override
  ConsumerState<WorkshopBookingsManagementPage> createState() =>
      _WorkshopBookingsManagementPageState();
}

class _WorkshopBookingsManagementPageState
    extends ConsumerState<WorkshopBookingsManagementPage> {
  bool _loading = false;

  Future<void> _runAction(
      Future<void> Function() action, String message) async {
    setState(() => _loading = true);
    try {
      await action();
      ref.invalidate(workshopOperationsBookingsProvider);
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
    final bookings = ref.watch(workshopOperationsBookingsProvider);
    return AppScaffold(
      title: 'حجوزات الورشة',
      child: ListView(
        children: [
          const SectionTitle(
            title: 'إدارة الحجوزات',
            subtitle: 'تأكيد الحجز، بدء العمل، أو فتح أمر صيانة من الحجز.',
          ),
          const SizedBox(height: AppSpacing.lg),
          bookings.when(
            data: (items) => items.isEmpty
                ? const _InfoCard(text: 'لا توجد حجوزات ورشة حتى الآن')
                : Column(
                    children: items
                        .map((item) => Padding(
                              padding:
                                  const EdgeInsets.only(bottom: AppSpacing.md),
                              child: _BookingTile(
                                booking: item,
                                isLoading: _loading,
                                onConfirm: () => _runAction(
                                  () => ref
                                      .read(workshopsRepositoryProvider)
                                      .updateBookingStatus(
                                        bookingId: item.id,
                                        status: 'CONFIRMED',
                                        note: 'تم تأكيد الحجز من الورشة',
                                      ),
                                  'تم تأكيد الحجز',
                                ),
                                onStart: () => _runAction(
                                  () => ref
                                      .read(workshopsRepositoryProvider)
                                      .updateBookingStatus(
                                        bookingId: item.id,
                                        status: 'IN_PROGRESS',
                                        note: 'بدأ تنفيذ الحجز',
                                      ),
                                  'تم بدء الحجز',
                                ),
                                onCreateOrder: () => _runAction(
                                  () => ref
                                      .read(workshopsRepositoryProvider)
                                      .createServiceOrderFromBooking(item.id),
                                  'تم فتح أمر صيانة',
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

class _BookingTile extends StatelessWidget {
  final WorkshopBookingModel booking;
  final bool isLoading;
  final VoidCallback onConfirm;
  final VoidCallback onStart;
  final VoidCallback onCreateOrder;

  const _BookingTile({
    required this.booking,
    required this.isLoading,
    required this.onConfirm,
    required this.onStart,
    required this.onCreateOrder,
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
          Text(booking.serviceName, style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.xs),
          Text('${booking.workshopName} • ${booking.status}',
              style: AppTextStyles.bodySecondary),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              SizedBox(
                  width: 130,
                  child: AppButton(
                      text: 'تأكيد',
                      isLoading: isLoading,
                      onPressed: onConfirm)),
              SizedBox(
                  width: 130,
                  child: AppButton(
                      text: 'بدء العمل',
                      isOutlined: true,
                      isLoading: isLoading,
                      onPressed: onStart)),
              SizedBox(
                  width: 170,
                  child: AppButton(
                      text: 'فتح أمر صيانة',
                      isOutlined: true,
                      isLoading: isLoading,
                      onPressed: onCreateOrder)),
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
