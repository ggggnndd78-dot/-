import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/core/storage/local_storage_service.dart';
import 'package:ghiyarak/core/theme/app_colors.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/core/theme/app_text_styles.dart';
import 'package:ghiyarak/features/vehicles/data/models/vehicle_model.dart';
import 'package:ghiyarak/features/vehicles/logic/vehicles_controller.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:go_router/go_router.dart';

class VehiclesPage extends ConsumerWidget {
  const VehiclesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesState = ref.watch(vehiclesControllerProvider);

    return AppScaffold(
      title: 'سياراتي',
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: AppColors.headerGradient,
              borderRadius: BorderRadius.circular(20),
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
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.directions_car_outlined,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'اختر سيارتك الافتراضية لتحسين نتائج القطع والخدمات.',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textOnDark.withValues(alpha: 0.82),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            text: 'إضافة سيارة',
            onPressed: () => context.go(RouteNames.addVehicle),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: vehiclesState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _VehicleStateMessage(
                icon: Icons.error_outline,
                title: 'حدث خطأ',
                message: error.toString(),
              ),
              data: (vehicles) {
                if (vehicles.isEmpty) {
                  return const _VehicleStateMessage(
                    icon: Icons.no_crash_outlined,
                    title: 'لا توجد سيارات محفوظة',
                    message: 'أضف سيارتك الأولى للحصول على نتائج أدق.',
                  );
                }

                return ListView.separated(
                  itemCount: vehicles.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final vehicle = vehicles[index];
                    return _VehicleCard(vehicle: vehicle);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            text: 'إنهاء هذه الجزئية',
            onPressed: () async {
              final local = ref.read(localStorageServiceProvider);
              await local.setSetupComplete(true);
              if (context.mounted) {
                context.go(RouteNames.setupComplete);
              }
            },
          ),
        ],
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
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: vehicle.isDefault ? AppColors.secondary : AppColors.border,
          width: vehicle.isDefault ? 1.4 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: vehicle.isDefault
                  ? AppColors.accentSoft
                  : AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              vehicle.isDefault
                  ? Icons.check_circle_outline
                  : Icons.directions_car_outlined,
              color: vehicle.isDefault
                  ? AppColors.secondary
                  : AppColors.iconAccent,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${vehicle.make} ${vehicle.model}',
                  style: AppTextStyles.title,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'سنة الصنع: ${vehicle.year}',
                  style: AppTextStyles.bodySecondary,
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            iconColor: AppColors.primary,
            onSelected: (value) async {
              if (value == 'default') {
                await ref
                    .read(vehiclesControllerProvider.notifier)
                    .setDefault(vehicle.id);
              } else if (value == 'delete') {
                await ref
                    .read(vehiclesControllerProvider.notifier)
                    .deleteVehicle(vehicle.id);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'default',
                child: Text('تعيين كافتراضية'),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text('حذف'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VehicleStateMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _VehicleStateMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

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
