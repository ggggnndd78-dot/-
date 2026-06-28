import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/features/merchant_market/data/merchant_market_repository.dart';
import 'package:ghiyarak/features/merchant_market/data/models/merchant_dashboard_model.dart';
import 'package:ghiyarak/features/merchant_market/data/models/merchant_notification_model.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_bottom_navigation.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_common_widgets.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_drawer.dart';
import 'package:go_router/go_router.dart';

class MerchantHubPage extends ConsumerStatefulWidget {
  const MerchantHubPage({super.key});

  @override
  ConsumerState<MerchantHubPage> createState() => _MerchantHubPageState();
}

class _MerchantHubPageState extends ConsumerState<MerchantHubPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  String _period = 'day';
  late Future<_HubData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_HubData> _load() async {
    final repository = ref.read(merchantMarketRepositoryProvider);
    final results = await Future.wait([
      repository.getDashboardSummary(period: _period),
      repository.getMerchantNotifications(),
    ]);
    return _HubData(
      dashboard: results[0] as MerchantDashboardModel,
      notifications: results[1] as MerchantNotificationResult,
    );
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  void _reload() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF5F7FA),
        drawer: const MerchantDrawer(currentTab: MerchantNavigationTab.home),
        bottomNavigationBar: const MerchantBottomNavigation(
          currentTab: MerchantNavigationTab.home,
        ),
        body: FutureBuilder<_HubData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const _LoadingDashboard();
            }
            if (snapshot.hasError) {
              return MerchantErrorState(
                message: snapshot.error.toString(),
                onRetry: _reload,
              );
            }
            final data = snapshot.data!;
            return RefreshIndicator(
              onRefresh: _refresh,
              color: const Color(0xFFFF7900),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                children: [
                  _HomeHeader(
                    storeName: data.dashboard.merchant.name,
                    notificationCount: data.notifications.unreadCount,
                    onMenu: () => _scaffoldKey.currentState?.openDrawer(),
                    onNotifications: () =>
                        context.go(RouteNames.merchantNotifications),
                    onSettings: () => context.go(RouteNames.merchantSettings),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SectionTitle(
                          title: 'ملخص اليوم',
                          icon: Icons.calendar_month_outlined,
                        ),
                        const SizedBox(height: 12),
                        _SummaryGrid(summary: data.dashboard.summary),
                        const SizedBox(height: 16),
                        _SalesChartCard(
                          points: data.dashboard.salesChart,
                          period: _period,
                          onPeriodChanged: (value) {
                            setState(() {
                              _period = value;
                              _future = _load();
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        _RecentOrdersCard(
                          orders: data.dashboard.recentOrders,
                          onOpenOrders: () =>
                              context.go(RouteNames.merchantOrders),
                        ),
                        const SizedBox(height: 16),
                        _RecentNotificationsCard(
                          notifications:
                              data.notifications.items.take(4).toList(),
                          onOpen: () =>
                              context.go(RouteNames.merchantNotifications),
                        ),
                        const SizedBox(height: 16),
                        _ShortcutsCard(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.storeName,
    required this.notificationCount,
    required this.onMenu,
    required this.onNotifications,
    required this.onSettings,
  });

  final String storeName;
  final int notificationCount;
  final VoidCallback onMenu;
  final VoidCallback onNotifications;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        18,
        MediaQuery.paddingOf(context).top + 10,
        18,
        26,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF06213D), Color(0xFF00385D)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              MerchantDrawerButton(onPressed: onMenu),
              const Spacer(),
              Image.asset(
                'assets/images/ghiyarak_logo_transparent.png',
                width: 126,
                height: 64,
                fit: BoxFit.contain,
              ),
              const Spacer(),
              _NotificationButton(
                count: notificationCount,
                onTap: onNotifications,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                onTap: onSettings,
                customBorder: const CircleBorder(),
                child: const CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person_rounded, color: Color(0xFF082B51)),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  storeName.isEmpty ? 'متجر غيارك' : storeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded,
                  color: Colors.white),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.summary});

  final MerchantDashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: MerchantStatCard(
            title: 'إجمالي المبيعات',
            value: _format(summary.totalSales),
            caption: _currency(summary.currency),
            icon: Icons.attach_money_rounded,
            color: const Color(0xFF1B9E4B),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: MerchantStatCard(
            title: 'الطلبات الجديدة',
            value: '${summary.newOrders}',
            caption: 'طلب',
            icon: Icons.assignment_outlined,
            color: const Color(0xFF1D63C8),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: MerchantStatCard(
            title: 'منخفض المخزون',
            value: '${summary.lowStockProducts}',
            caption: 'منتج',
            icon: Icons.inventory_2_outlined,
            color: const Color(0xFFFF7900),
          ),
        ),
      ],
    );
  }
}

class _SalesChartCard extends StatelessWidget {
  const _SalesChartCard({
    required this.points,
    required this.period,
    required this.onPeriodChanged,
  });

  final List<MerchantSalesPoint> points;
  final String period;
  final ValueChanged<String> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    final values = points.map((point) => point.sales).toList(growable: false);
    return MerchantSectionCard(
      title: 'مبيعات اليوم',
      icon: Icons.show_chart_rounded,
      child: Column(
        children: [
          Row(
            children: [
              _GrowthPill(points: points),
              const Spacer(),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: period,
                  borderRadius: BorderRadius.circular(12),
                  items: const [
                    DropdownMenuItem(value: 'day', child: Text('اليوم')),
                    DropdownMenuItem(value: 'week', child: Text('الأسبوع')),
                    DropdownMenuItem(value: 'month', child: Text('الشهر')),
                  ],
                  onChanged: (value) {
                    if (value != null) onPeriodChanged(value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 190,
            child: values.isEmpty
                ? const MerchantEmptyState(
                    title: 'لا توجد مبيعات في هذه الفترة',
                    icon: Icons.show_chart_rounded,
                  )
                : CustomPaint(
                    painter: _LineChartPainter(values),
                    child: const SizedBox.expand(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _RecentOrdersCard extends StatelessWidget {
  const _RecentOrdersCard({
    required this.orders,
    required this.onOpenOrders,
  });

  final List<MerchantRecentOrder> orders;
  final VoidCallback onOpenOrders;

  @override
  Widget build(BuildContext context) {
    return MerchantSectionCard(
      title: 'أحدث الطلبات',
      icon: Icons.format_list_bulleted_rounded,
      child: orders.isEmpty
          ? const MerchantEmptyState(
              title: 'لا توجد طلبات حديثة',
              icon: Icons.assignment_outlined,
            )
          : Column(
              children: [
                for (final order in orders.take(4)) ...[
                  ListTile(
                    onTap: onOpenOrders,
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFEAF2FB),
                      child:
                          Icon(Icons.person_rounded, color: Color(0xFF082B51)),
                    ),
                    title: Text(
                      '#${order.orderNumber} - ${order.customerName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    subtitle: Text(
                        '${order.itemsCount} قطع • ${_statusLabel(order.status)}'),
                    trailing: Text(
                      _format(order.totalAmount),
                      style: const TextStyle(
                        color: Color(0xFF082B51),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                ],
                TextButton(
                  onPressed: onOpenOrders,
                  child: const Text('عرض كل الطلبات'),
                ),
              ],
            ),
    );
  }
}

class _RecentNotificationsCard extends StatelessWidget {
  const _RecentNotificationsCard({
    required this.notifications,
    required this.onOpen,
  });

  final List<MerchantNotificationModel> notifications;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return MerchantSectionCard(
      title: 'أحدث الإشعارات',
      icon: Icons.notifications_none_rounded,
      child: notifications.isEmpty
          ? const MerchantEmptyState(
              title: 'لا توجد إشعارات جديدة',
              icon: Icons.notifications_none_rounded,
            )
          : Column(
              children: [
                for (final item in notifications) ...[
                  ListTile(
                    onTap: onOpen,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      item.isUrgent
                          ? Icons.warning_amber_rounded
                          : Icons.notifications_none_rounded,
                      color: item.isUrgent
                          ? const Color(0xFFFF7900)
                          : const Color(0xFF1D63C8),
                    ),
                    title: Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    subtitle: Text(
                      item.message,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: item.isRead
                        ? null
                        : const Icon(Icons.circle,
                            size: 9, color: Color(0xFFFF7900)),
                  ),
                  const Divider(height: 1),
                ],
                TextButton(
                    onPressed: onOpen, child: const Text('فتح مركز المهام')),
              ],
            ),
    );
  }
}

class _ShortcutsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      (
        'إضافة منتج',
        Icons.add_circle_outline_rounded,
        RouteNames.createListing
      ),
      ('الطلبات', Icons.assignment_outlined, RouteNames.merchantOrders),
      ('التقارير', Icons.bar_chart_rounded, RouteNames.merchantReports),
      ('الإعدادات', Icons.settings_outlined, RouteNames.merchantSettings),
    ];
    return MerchantSectionCard(
      title: 'اختصارات سريعة',
      icon: Icons.bolt_outlined,
      child: Row(
        children: [
          for (final item in items) ...[
            Expanded(
              child: InkWell(
                onTap: () => context.go(item.$3),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 76,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE0E7EF)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item.$2, color: const Color(0xFF082B51)),
                      const SizedBox(height: 6),
                      Text(
                        item.$1,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (item != items.last) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: onTap,
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: Colors.white,
            size: 30,
          ),
        ),
        if (count > 0)
          Positioned(
            top: 0,
            left: 0,
            child: CircleAvatar(
              radius: 11,
              backgroundColor: const Color(0xFFFF7900),
              child: Text(
                count > 99 ? '99+' : '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF082B51), size: 21),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF102A43),
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _GrowthPill extends StatelessWidget {
  const _GrowthPill({required this.points});

  final List<MerchantSalesPoint> points;

  @override
  Widget build(BuildContext context) {
    final growth = points.length < 2
        ? 0.0
        : ((points.last.sales - points.first.sales) /
                math.max(points.first.sales, 1)) *
            100;
    final positive = growth >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: positive ? const Color(0xFFE7F7EC) : const Color(0xFFFCEAEA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${positive ? '+' : ''}${growth.toStringAsFixed(1)}%',
        style: TextStyle(
          color: positive ? const Color(0xFF139447) : const Color(0xFFD83B3B),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter(this.values);

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFE4EAF0)
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    final maxValue = values.fold<double>(1, math.max);
    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1 ? 0.0 : size.width * i / (values.length - 1);
      final y = size.height - (values[i] / maxValue * (size.height - 14)) - 7;
      points.add(Offset(x, y));
    }
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    final fill = Path.from(path)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()..color = const Color(0xFFFF7900).withValues(alpha: .12),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFFF7900)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    for (final point in points) {
      canvas.drawCircle(point, 4, Paint()..color = Colors.white);
      canvas.drawCircle(
          point,
          4,
          Paint()
            ..color = const Color(0xFFFF7900)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.values != values;
  }
}

class _LoadingDashboard extends StatelessWidget {
  const _LoadingDashboard();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _HubData {
  const _HubData({
    required this.dashboard,
    required this.notifications,
  });

  final MerchantDashboardModel dashboard;
  final MerchantNotificationResult notifications;
}

String _format(double value) {
  final digits = value.round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

String _currency(String value) {
  return switch (value.toUpperCase()) {
    'SAR' => 'ر.س',
    'YER' => 'ر.ي',
    _ => value,
  };
}

String _statusLabel(String value) {
  return switch (value) {
    'PENDING' => 'جديد',
    'CONFIRMED' || 'PREPARING' => 'قيد التجهيز',
    'READY_FOR_PICKUP' || 'READY' => 'جاهز',
    'COMPLETED' => 'مكتمل',
    'CANCELLED' || 'REJECTED' => 'ملغي',
    _ => value,
  };
}
