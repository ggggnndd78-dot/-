import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/theme/app_colors.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/core/theme/app_text_styles.dart';
import 'package:ghiyarak/features/logistics/data/models/logistics_models.dart';
import 'package:ghiyarak/features/logistics/data/logistics_repository.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:ghiyarak/shared/widgets/section_title.dart';

class ShipmentsPage extends ConsumerWidget {
  final bool merchantMode;
  final bool driverMode;
  final bool adminMode;
  const ShipmentsPage(
      {super.key,
      this.merchantMode = false,
      this.driverMode = false,
      this.adminMode = false});

  String get _title {
    if (adminMode) return 'إدارة الشحنات';
    if (driverMode) return 'توصيلاتي';
    if (merchantMode) return 'شحنات التاجر';
    return 'شحناتي';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = adminMode
        ? _adminShipmentsProvider
        : driverMode
            ? _driverShipmentsProvider
            : merchantMode
                ? _merchantShipmentsProvider
                : _myShipmentsProvider;
    final shipments = ref.watch(provider);
    return AppScaffold(
      title: _title,
      child: shipments.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
                child: Text('لا توجد شحنات حتى الآن',
                    style: AppTextStyles.bodySecondary));
          }
          return ListView.separated(
            itemCount: items.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              if (index == 0) {
                return SectionTitle(
                  title: 'نظام التوصيل والتتبع',
                  subtitle: adminMode
                      ? 'متابعة كل الشحنات والسائقين وشركات الشحن.'
                      : driverMode
                          ? 'الشحنات المسندة لك فقط.'
                          : 'متابعة الشحنات وتحديث حالتها حسب الصلاحية.',
                );
              }
              return _ShipmentCard(
                  shipment: items[index - 1],
                  merchantMode: merchantMode || adminMode,
                  driverMode: driverMode,
                  adminMode: adminMode);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }
}

class _ShipmentCard extends ConsumerWidget {
  final ShipmentModel shipment;
  final bool merchantMode;
  final bool driverMode;
  final bool adminMode;
  const _ShipmentCard(
      {required this.shipment,
      required this.merchantMode,
      required this.driverMode,
      required this.adminMode});

  Future<void> _next(WidgetRef ref) async {
    const flow = [
      'PENDING',
      'READY_FOR_PICKUP',
      'PICKED_UP',
      'IN_TRANSIT',
      'OUT_FOR_DELIVERY',
      'DELIVERED'
    ];
    final idx = flow.indexOf(shipment.status);
    if (idx < 0 || idx >= flow.length - 1) return;
    await ref.read(logisticsRepositoryProvider).updateShipmentStatus(
        shipmentId: shipment.id.toString(), status: flow[idx + 1]);
    ref.invalidate(_merchantShipmentsProvider);
    ref.invalidate(_driverShipmentsProvider);
    ref.invalidate(_adminShipmentsProvider);
  }

  Future<void> _accept(WidgetRef ref) async {
    await ref
        .read(logisticsRepositoryProvider)
        .acceptDriverShipment(shipment.id.toString());
    ref.invalidate(_driverShipmentsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Text(shipment.shipmentNumber, style: AppTextStyles.title)),
          _StatusChip(status: shipment.status)
        ]),
        const SizedBox(height: AppSpacing.xs),
        if (shipment.trackingNumber.isNotEmpty)
          Text('رقم التتبع: ${shipment.trackingNumber}',
              style: AppTextStyles.bodySecondary),
        if (shipment.driverName.isNotEmpty)
          Text('السائق: ${shipment.driverName}',
              style: AppTextStyles.bodySecondary),
        if (shipment.shippingCompanyName.isNotEmpty)
          Text('شركة الشحن: ${shipment.shippingCompanyName}',
              style: AppTextStyles.bodySecondary),
        if (shipment.courierName.isNotEmpty)
          Text('الناقل: ${shipment.courierName}',
              style: AppTextStyles.bodySecondary),
        const SizedBox(height: AppSpacing.sm),
        Text('${shipment.deliveryFee.toStringAsFixed(0)} ${shipment.currency}',
            style: AppTextStyles.body),
        if (merchantMode || driverMode) ...[
          const SizedBox(height: AppSpacing.md),
          Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [
            if (driverMode)
              AppButton(
                  text: 'قبول الشحنة',
                  isOutlined: true,
                  onPressed: () => _accept(ref)),
            AppButton(
                text: 'تحديث للحالة التالية',
                isOutlined: true,
                onPressed: () => _next(ref)),
          ]),
        ],
      ]),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(99)),
      child: Text(status,
          style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
    );
  }
}

final _myShipmentsProvider = FutureProvider<List<ShipmentModel>>(
    (ref) => ref.read(logisticsRepositoryProvider).getMyShipments());
final _merchantShipmentsProvider = FutureProvider<List<ShipmentModel>>(
    (ref) => ref.read(logisticsRepositoryProvider).getMerchantShipments());
final _driverShipmentsProvider = FutureProvider<List<ShipmentModel>>(
    (ref) => ref.read(logisticsRepositoryProvider).getDriverShipments());
final _adminShipmentsProvider = FutureProvider<List<ShipmentModel>>(
    (ref) => ref.read(logisticsRepositoryProvider).getAdminShipments());
