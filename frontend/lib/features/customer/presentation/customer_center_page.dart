import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/core/theme/app_colors.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/core/theme/app_text_styles.dart';
import 'package:ghiyarak/features/auth/logic/auth_controller.dart';
import 'package:ghiyarak/features/logistics/data/logistics_repository.dart';
import 'package:ghiyarak/features/orders/data/orders_repository.dart';
import 'package:ghiyarak/features/vehicles/data/vehicles_repository.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:go_router/go_router.dart';

final _customerOrdersCountProvider = FutureProvider.autoDispose<int>(
    (ref) async =>
        (await ref.watch(ordersRepositoryProvider).getMyOrders()).length);
final _customerVehiclesCountProvider = FutureProvider.autoDispose<int>(
    (ref) async =>
        (await ref.watch(vehiclesRepositoryProvider).getVehicles()).length);
final _customerNotificationsCountProvider = FutureProvider.autoDispose<int>(
    (ref) async =>
        (await ref.watch(logisticsRepositoryProvider).getNotifications())
            .where((n) => n.status == 'UNREAD')
            .length);

class CustomerCenterPage extends ConsumerWidget {
  const CustomerCenterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final ordersCount = ref.watch(_customerOrdersCountProvider);
    final vehiclesCount = ref.watch(_customerVehiclesCountProvider);
    final unreadCount = ref.watch(_customerNotificationsCountProvider);

    return AppScaffold(
      title: 'مركز العميل',
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(_customerOrdersCountProvider);
          ref.invalidate(_customerVehiclesCountProvider);
          ref.invalidate(_customerNotificationsCountProvider);
        },
        child: ListView(children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
                gradient: AppColors.headerGradient,
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 18,
                      offset: Offset(0, 10))
                ]),
            child: Row(children: [
              const Icon(Icons.person_pin_circle_outlined,
                  color: AppColors.headerFooterAccent, size: 44),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(
                        auth.user?.displayName.isNotEmpty == true
                            ? auth.user!.displayName
                            : 'مرحباً بك في غيارك',
                        style: AppTextStyles.heading2
                            .copyWith(color: AppColors.textOnDark)),
                    const SizedBox(height: AppSpacing.xs),
                    Text('تابع طلباتك ومركباتك ومحفظتك وإشعاراتك من مكان واحد.',
                        style: AppTextStyles.body.copyWith(
                            color:
                                AppColors.textOnDark.withValues(alpha: 0.78))),
                  ])),
            ]),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(children: [
            Expanded(
                child: _MetricCard(
                    icon: Icons.shopping_bag_outlined,
                    label: 'طلباتي',
                    value: ordersCount.valueOrNull?.toString() ?? '...')),
            const SizedBox(width: AppSpacing.md),
            Expanded(
                child: _MetricCard(
                    icon: Icons.directions_car_outlined,
                    label: 'مركباتي',
                    value: vehiclesCount.valueOrNull?.toString() ?? '...')),
            const SizedBox(width: AppSpacing.md),
            Expanded(
                child: _MetricCard(
                    icon: Icons.notifications_outlined,
                    label: 'غير مقروءة',
                    value: unreadCount.valueOrNull?.toString() ?? '...')),
          ]),
          const SizedBox(height: AppSpacing.lg),
          _FeatureTile(
              icon: Icons.storefront_outlined,
              title: 'المتجر',
              subtitle: 'تصفح القطع والعروض من قاعدة البيانات',
              route: RouteNames.marketplaceHome),
          _FeatureTile(
              icon: Icons.directions_car_outlined,
              title: 'مركباتي',
              subtitle: 'إدارة سياراتك وربطها بالقطع المناسبة',
              route: RouteNames.customerVehicle),
          _FeatureTile(
              icon: Icons.location_on_outlined,
              title: 'عناويني',
              subtitle: 'إدارة عناوين التوصيل الخاصة بك',
              route: RouteNames.myAddresses),
          _FeatureTile(
              icon: Icons.search_outlined,
              title: 'البحث عن قطع',
              subtitle: 'نتائج مباشرة من عروض التجار',
              route: RouteNames.customerParts),
          _FeatureTile(
              icon: Icons.shopping_cart_outlined,
              title: 'السلة',
              subtitle: 'راجع العناصر قبل إنشاء الطلب',
              route: RouteNames.cart),
          _FeatureTile(
              icon: Icons.receipt_long_outlined,
              title: 'طلباتي',
              subtitle: 'متابعة الطلبات وحالاتها',
              route: RouteNames.myOrders),
          _FeatureTile(
              icon: Icons.local_shipping_outlined,
              title: 'شحناتي',
              subtitle: 'متابعة الشحنات المرتبطة بطلباتك',
              route: RouteNames.customerShipments),
          _FeatureTile(
              icon: Icons.car_repair_outlined,
              title: 'صيانة سيارتي',
              subtitle: 'حجوزات الورش وسجل الصيانة',
              route: RouteNames.customerMaintenance),
          _FeatureTile(
              icon: Icons.account_balance_wallet_outlined,
              title: 'محفظتي',
              subtitle: 'الرصيد وسجل العمليات',
              route: RouteNames.customerWallet),
          _FeatureTile(
              icon: Icons.card_giftcard_outlined,
              title: 'الولاء والكوبونات',
              subtitle: 'النقاط والكوبونات الفعلية',
              route: RouteNames.customerLoyalty),
          _FeatureTile(
              icon: Icons.support_agent,
              title: 'الدعم والشكاوى',
              subtitle: 'تذاكر وشكاوى مرتبطة بحسابك',
              route: RouteNames.customerSupportTickets),
          _FeatureTile(
              icon: Icons.notifications_active_outlined,
              title: 'الإشعارات',
              subtitle: 'مركز إشعارات داخل التطبيق',
              route: RouteNames.customerNotifications),
        ]),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _MetricCard(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border)),
      child: Column(children: [
        Icon(icon, color: AppColors.iconAccent),
        const SizedBox(height: AppSpacing.sm),
        Text(value, style: AppTextStyles.heading2),
        Text(label, style: AppTextStyles.bodySecondary),
      ]),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  const _FeatureTile(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.route});

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.go(route),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.iconAccent),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.title),
                      const SizedBox(height: 4),
                      Text(subtitle, style: AppTextStyles.bodySecondary),
                    ],
                  ),
                ),
                Icon(
                  isRtl ? Icons.chevron_left : Icons.chevron_right,
                  color: AppColors.iconAccent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
