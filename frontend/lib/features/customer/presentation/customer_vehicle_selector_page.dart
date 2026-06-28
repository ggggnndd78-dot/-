import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/core/theme/app_colors.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/core/theme/app_text_styles.dart';
import 'package:ghiyarak/features/vehicles/data/models/vehicle_model.dart';
import 'package:ghiyarak/features/vehicles/data/vehicles_repository.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:ghiyarak/shared/widgets/section_title.dart';
import 'package:go_router/go_router.dart';

final _customerVehiclesProvider =
    FutureProvider.autoDispose<List<VehicleModel>>(
        (ref) => ref.watch(vehiclesRepositoryProvider).getVehicles());

class CustomerVehicleSelectorPage extends ConsumerWidget {
  const CustomerVehicleSelectorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicles = ref.watch(_customerVehiclesProvider);
    return AppScaffold(
      title: 'مركباتي',
      child: RefreshIndicator(
        onRefresh: () async => ref.invalidate(_customerVehiclesProvider),
        child: ListView(children: [
          const SectionTitle(
              title: 'سياراتك المسجلة',
              subtitle:
                  'هذه القائمة تأتي من قاعدة البيانات، ولا تحتوي على بيانات ثابتة.'),
          const SizedBox(height: AppSpacing.md),
          vehicles.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _EmptyCard(text: e.toString()),
            data: (items) {
              if (items.isEmpty) {
                return Column(children: [
                  const _EmptyCard(text: 'لم تقم بإضافة أي مركبة بعد.'),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                      text: 'إضافة مركبة',
                      onPressed: () => context.go(RouteNames.addVehicle)),
                ]);
              }
              return Column(children: [
                ...items.map((vehicle) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _VehicleCard(vehicle: vehicle),
                    )),
                AppButton(
                    text: 'إضافة مركبة أخرى',
                    isOutlined: true,
                    onPressed: () => context.go(RouteNames.addVehicle)),
              ]);
            },
          ),
        ]),
      ),
    );
  }
}

class _VehicleCard extends ConsumerWidget {
  final VehicleModel vehicle;
  const _VehicleCard({required this.vehicle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color:
                  vehicle.isDefault ? AppColors.secondary : AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.directions_car, color: AppColors.iconAccent),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
              child: Text('${vehicle.make} ${vehicle.model} ${vehicle.year}',
                  style: AppTextStyles.title)),
          if (vehicle.isDefault) const Chip(label: Text('افتراضية')),
        ]),
        if ((vehicle.variantName ?? '').isNotEmpty)
          Text(vehicle.variantName!, style: AppTextStyles.bodySecondary),
        const SizedBox(height: AppSpacing.md),
        Row(children: [
          Expanded(
              child: AppButton(
                  text: 'عرض القطع',
                  onPressed: () => context.go(
                      '${RouteNames.customerParts}?vehicleId=${Uri.encodeComponent(vehicle.id)}'))),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
              child: AppButton(
                  text: 'تعيين افتراضية',
                  isOutlined: true,
                  onPressed: vehicle.isDefault
                      ? null
                      : () async {
                          await ref
                              .read(vehiclesRepositoryProvider)
                              .setDefault(vehicle.id);
                          ref.invalidate(_customerVehiclesProvider);
                        })),
        ]),
      ]),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String text;
  const _EmptyCard({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border)),
      child: Text(text, style: AppTextStyles.bodySecondary),
    );
  }
}
