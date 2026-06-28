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

final customerWorkshopServicesProvider =
    FutureProvider<List<WorkshopServiceModel>>((ref) async {
  return ref.watch(workshopsRepositoryProvider).getWorkshopServices();
});

final customerWorkshopBookingsProvider =
    FutureProvider<List<WorkshopBookingModel>>((ref) async {
  return ref.watch(workshopsRepositoryProvider).getMyBookings();
});

final customerMaintenanceRecordsProvider =
    FutureProvider<List<MaintenanceRecordModel>>((ref) async {
  return ref.watch(workshopsRepositoryProvider).getMyMaintenanceRecords();
});

class CustomerMaintenancePage extends ConsumerStatefulWidget {
  const CustomerMaintenancePage({super.key});

  @override
  ConsumerState<CustomerMaintenancePage> createState() =>
      _CustomerMaintenancePageState();
}

class _CustomerMaintenancePageState
    extends ConsumerState<CustomerMaintenancePage> {
  bool _isBooking = false;

  Future<void> _bookService(WorkshopServiceModel service) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (selectedDate == null) return;

    setState(() => _isBooking = true);
    try {
      final slots = await ref.read(workshopsRepositoryProvider).getBookingSlots(
            workshopServiceId: service.id,
            date: selectedDate,
          );
      BookingSlotModel? selectedSlot;
      final availableSlots = slots.where((slot) => slot.isAvailable).toList();
      if (mounted && availableSlots.isNotEmpty) {
        selectedSlot = await showDialog<BookingSlotModel>(
          context: context,
          builder: (context) => SimpleDialog(
            title: const Text('اختر الموعد'),
            children: availableSlots
                .map(
                  (slot) => SimpleDialogOption(
                    onPressed: () => Navigator.of(context).pop(slot),
                    child: Text('${slot.startAt} - ${slot.endAt}'),
                  ),
                )
                .toList(),
          ),
        );
        if (selectedSlot == null) return;
      }
      await ref.read(workshopsRepositoryProvider).createBooking(
            serviceId: service.id,
            bookingSlotId: selectedSlot?.id,
            preferredDate: selectedDate,
            preferredTimeWindow:
                selectedSlot == null ? 'حسب أقرب موعد متاح' : null,
            problemDescription: 'أرغب بحجز ${service.name}',
          );
      ref.invalidate(customerWorkshopBookingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إرسال طلب الحجز للورشة')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  Future<void> _cancelBooking(WorkshopBookingModel booking) async {
    setState(() => _isBooking = true);
    try {
      await ref
          .read(workshopsRepositoryProvider)
          .cancelBooking(booking.id, reason: 'إلغاء من العميل');
      ref.invalidate(customerWorkshopBookingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تم إلغاء الحجز')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  Future<void> _rateBooking(WorkshopBookingModel booking) async {
    setState(() => _isBooking = true);
    try {
      await ref.read(workshopsRepositoryProvider).submitBookingRating(
            bookingId: booking.id,
            rating: 5,
            title: 'خدمة ممتازة',
            body: 'تم تقييم الخدمة من تطبيق غيارك.',
          );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تم إرسال التقييم')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = ref.watch(customerWorkshopServicesProvider);
    final bookings = ref.watch(customerWorkshopBookingsProvider);
    final records = ref.watch(customerMaintenanceRecordsProvider);

    return AppScaffold(
      title: 'صيانة سيارتي',
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(customerWorkshopServicesProvider);
          ref.invalidate(customerWorkshopBookingsProvider);
          ref.invalidate(customerMaintenanceRecordsProvider);
        },
        child: ListView(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: AppColors.headerGradient,
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 18,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.car_repair_outlined,
                    color: AppColors.headerFooterAccent,
                    size: 38,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'مركز خدمات الورش',
                          style: AppTextStyles.heading2.copyWith(
                            color: AppColors.textOnDark,
                          ),
                        ),
                        Text(
                          'احجز فحص أو صيانة، وتابع حالة الحجز وأوامر الصيانة وسجل مركبتك.',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textOnDark.withValues(alpha: 0.78),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const SectionTitle(
              title: 'خدمات الورش المتاحة',
              subtitle: 'الخدمات مرتبطة فعليًا بباك إند الورش.',
            ),
            const SizedBox(height: AppSpacing.md),
            services.when(
              data: (items) => items.isEmpty
                  ? const _EmptyCard(text: 'لا توجد خدمات ورش متاحة حاليًا')
                  : Column(
                      children: items
                          .map((service) => Padding(
                                padding: const EdgeInsets.only(
                                    bottom: AppSpacing.md),
                                child: _ServiceCard(
                                  service: service,
                                  isLoading: _isBooking,
                                  onBook: () => _bookService(service),
                                ),
                              ))
                          .toList(),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _EmptyCard(text: e.toString()),
            ),
            const SizedBox(height: AppSpacing.lg),
            const SectionTitle(title: 'حجوزاتي'),
            const SizedBox(height: AppSpacing.md),
            bookings.when(
              data: (items) => items.isEmpty
                  ? const _EmptyCard(text: 'لا توجد حجوزات صيانة بعد')
                  : Column(
                      children: items
                          .map((booking) => Padding(
                                padding: const EdgeInsets.only(
                                    bottom: AppSpacing.md),
                                child: _BookingCard(
                                  booking: booking,
                                  isLoading: _isBooking,
                                  onCancel: () => _cancelBooking(booking),
                                  onRate: () => _rateBooking(booking),
                                ),
                              ))
                          .toList(),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _EmptyCard(text: e.toString()),
            ),
            const SizedBox(height: AppSpacing.lg),
            const SectionTitle(title: 'سجل الصيانة'),
            const SizedBox(height: AppSpacing.md),
            records.when(
              data: (items) => items.isEmpty
                  ? const _EmptyCard(
                      text: 'سيظهر هنا سجل الصيانة بعد إغلاق أوامر الورشة')
                  : Column(
                      children: items
                          .map((record) => Padding(
                                padding: const EdgeInsets.only(
                                    bottom: AppSpacing.md),
                                child: _RecordCard(record: record),
                              ))
                          .toList(),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _EmptyCard(text: e.toString()),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final WorkshopServiceModel service;
  final bool isLoading;
  final VoidCallback onBook;

  const _ServiceCard({
    required this.service,
    required this.isLoading,
    required this.onBook,
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
          Row(
            children: [
              const Icon(Icons.build_circle_outlined, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(service.name, style: AppTextStyles.title)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            service.description ?? service.organizationName ?? 'خدمة ورشة',
            style: AppTextStyles.bodySecondary,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${service.durationMinutes ?? 30} دقيقة • ${service.basePrice?.toStringAsFixed(0) ?? '-'} ${service.currency}',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
              text: 'احجز الخدمة', isLoading: isLoading, onPressed: onBook),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final WorkshopBookingModel booking;
  final bool isLoading;
  final VoidCallback onCancel;
  final VoidCallback onRate;

  const _BookingCard({
    required this.booking,
    required this.isLoading,
    required this.onCancel,
    required this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    final canCancel =
        booking.status == 'REQUESTED' || booking.status == 'CONFIRMED';
    final canRate = booking.status == 'COMPLETED';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_available_outlined,
                  color: AppColors.iconAccent),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking.serviceName, style: AppTextStyles.title),
                    Text('${booking.workshopName} • ${booking.status}',
                        style: AppTextStyles.bodySecondary),
                    if (booking.timeWindow != null)
                      Text(booking.timeWindow!,
                          style: AppTextStyles.bodySecondary),
                  ],
                ),
              ),
            ],
          ),
          if (canCancel || canRate) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                if (canCancel)
                  SizedBox(
                      width: 130,
                      child: AppButton(
                          text: 'إلغاء',
                          isOutlined: true,
                          isLoading: isLoading,
                          onPressed: onCancel)),
                if (canRate)
                  SizedBox(
                      width: 130,
                      child: AppButton(
                          text: 'تقييم',
                          isLoading: isLoading,
                          onPressed: onRate)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  final MaintenanceRecordModel record;
  const _RecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading:
              const Icon(Icons.fact_check_outlined, color: AppColors.primary),
          title: Text(record.title, style: AppTextStyles.title),
          subtitle:
              Text(record.vehicleName, style: AppTextStyles.bodySecondary),
          trailing: Text(
            record.costAmount?.toStringAsFixed(0) ?? '-',
            style: AppTextStyles.body,
          ),
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String text;
  const _EmptyCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
