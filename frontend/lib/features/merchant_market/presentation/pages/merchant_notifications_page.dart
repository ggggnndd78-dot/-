import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/core/theme/app_colors.dart';
import 'package:ghiyarak/features/merchant_market/data/merchant_market_repository.dart';
import 'package:ghiyarak/features/merchant_market/data/models/merchant_notification_model.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_bottom_navigation.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_drawer.dart';
import 'package:go_router/go_router.dart';

class MerchantNotificationsPage extends ConsumerStatefulWidget {
  const MerchantNotificationsPage({super.key});

  @override
  ConsumerState<MerchantNotificationsPage> createState() =>
      _MerchantNotificationsPageState();
}

class _MerchantNotificationsPageState
    extends ConsumerState<MerchantNotificationsPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  String _category = 'ALL';
  late Future<MerchantNotificationResult> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<MerchantNotificationResult> _load() {
    return ref
        .read(merchantMarketRepositoryProvider)
        .getMerchantNotifications();
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _markAll() async {
    await ref
        .read(merchantMarketRepositoryProvider)
        .markAllMerchantNotificationsRead();
    if (mounted) setState(() => _future = _load());
  }

  Future<void> _open(MerchantNotificationModel notification) async {
    if (!notification.isRead) {
      await ref
          .read(merchantMarketRepositoryProvider)
          .markMerchantNotificationRead(notification.key);
    }
    if (!mounted) return;

    switch (notification.category.toLowerCase()) {
      case 'orders':
        context.go(RouteNames.merchantOrders);
        break;
      case 'inventory':
        context.go(RouteNames.merchantInventory);
        break;
      case 'chats':
        context.go(RouteNames.merchantCustomerChats);
        break;
      case 'finance':
        context.go(RouteNames.merchantFinanceOverview);
        break;
      case 'returns_disputes':
        context.go(RouteNames.merchantDisputes);
        break;
      case 'admin':
        context.go(RouteNames.merchantSettings);
        break;
      default:
        setState(() => _future = _load());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF5F7FA),
        drawer: const MerchantDrawer(currentTab: MerchantNavigationTab.home),
        bottomNavigationBar: const MerchantBottomNavigation(
            currentTab: MerchantNavigationTab.home),
        body: FutureBuilder<MerchantNotificationResult>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _ErrorState(
                message: snapshot.error.toString(),
                onRetry: () => setState(() => _future = _load()),
              );
            }

            final result = snapshot.requireData;
            final items = result.items
                .where((item) =>
                    _category == 'ALL' ||
                    item.category.toLowerCase() == _category.toLowerCase())
                .toList();

            return Column(
              children: [
                _Header(
                  unreadCount: result.unreadCount,
                  onMarkAll: result.unreadCount == 0 ? null : _markAll,
                  onMenu: () => _scaffoldKey.currentState?.openDrawer(),
                ),
                _Categories(
                  selected: _category,
                  count: result.unreadCount,
                  onChanged: (value) => setState(() => _category = value),
                ),
                if (result.urgentCount > 0)
                  _UrgentBanner(count: result.urgentCount),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refresh,
                    child: items.isEmpty
                        ? const _EmptyState()
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: items.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final item = items[index];
                              return _NotificationCard(
                                notification: item,
                                onTap: () => _open(item),
                              );
                            },
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.unreadCount,
    required this.onMarkAll,
    required this.onMenu,
  });

  final int unreadCount;
  final VoidCallback? onMarkAll;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 14,
        20,
        24,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF061A2D), Color(0xFF0E3659)],
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                tooltip: 'القائمة',
                onPressed: onMenu,
                icon: const Icon(
                  Icons.menu_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const Text(
                'إشعارات التاجر',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.notifications_none_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: -5,
                      right: -5,
                      child: _Badge(value: unreadCount),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onMarkAll,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('تحديد الكل كمقروء'),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _Categories extends StatelessWidget {
  const _Categories({
    required this.selected,
    required this.count,
    required this.onChanged,
  });

  final String selected;
  final int count;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const categories = [
      ('ALL', 'الكل'),
      ('orders', 'الطلبات'),
      ('chats', 'المحادثات'),
      ('inventory', 'المخزون'),
      ('finance', 'المالية'),
      ('returns_disputes', 'المرتجعات'),
      ('admin', 'الإدارة'),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color(0x10000000), blurRadius: 14),
        ],
      ),
      child: Row(
        children: categories.map((category) {
          final active = selected == category.$1;
          return Expanded(
            child: InkWell(
              onTap: () => onChanged(category.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      category.$2,
                      style: TextStyle(
                        color: active ? Colors.white : AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (category.$1 == 'ALL' && count > 0) ...[
                      const SizedBox(width: 6),
                      _Badge(value: count),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _UrgentBanner extends StatelessWidget {
  const _UrgentBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9F3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFB375)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.notification_important_outlined,
            color: Color(0xFFFF6417),
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'لديك $count إشعار مهم يحتاج متابعة سريعة.',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  final MerchantNotificationModel notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = _notificationStyle(notification.type);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: const Color(0xFFE0E6EC)),
          boxShadow: const [
            BoxShadow(color: Color(0x0D000000), blurRadius: 12),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                color: style.$2.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(style.$1, color: style.$2, size: 34),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title.isEmpty
                        ? _fallbackTitle(notification.type)
                        : notification.title,
                    style: const TextStyle(
                      color: Color(0xFF082B51),
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    notification.message.isEmpty
                        ? 'افتح التفاصيل لمتابعة هذا التحديث.'
                        : notification.message,
                    style: const TextStyle(color: Color(0xFF566678)),
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 17,
                        color: Color(0xFF778493),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _relativeTime(notification.createdAt),
                        style: const TextStyle(
                          color: Color(0xFF778493),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!notification.isRead)
              Container(
                width: 11,
                height: 11,
                decoration: const BoxDecoration(
                  color: Color(0xFF1477EE),
                  shape: BoxShape.circle,
                ),
              ),
            const SizedBox(width: 10),
            OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: style.$2,
                side: BorderSide(color: style.$2),
              ),
              child: Text(_actionLabel(notification.category)),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        SizedBox(height: 150),
        Icon(
          Icons.notifications_none_outlined,
          color: Color(0xFF778493),
          size: 54,
        ),
        SizedBox(height: 12),
        Center(
          child: Text(
            'لا توجد إشعارات حاليا',
            style: TextStyle(
              color: Color(0xFF566678),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFFFF7100),
        shape: BoxShape.circle,
      ),
      child: Text(
        value > 99 ? '99+' : '$value',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 42),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}

(IconData, Color) _notificationStyle(String type) => switch (type) {
      'NEW_ORDER' => (
          Icons.add_shopping_cart_rounded,
          const Color(0xFF1558A6),
        ),
      'LOW_STOCK' => (
          Icons.inventory_2_outlined,
          const Color(0xFFF08A00),
        ),
      'LISTING_APPROVED' => (
          Icons.verified_outlined,
          const Color(0xFF15883E),
        ),
      'LISTING_REJECTED' || 'ORDER_CANCELLED' => (
          Icons.cancel_outlined,
          const Color(0xFFE04B4B),
        ),
      _ => (Icons.notifications_outlined, AppColors.primary),
    };

String _actionLabel(String category) => switch (category) {
      'ORDERS' => 'عرض الطلبات',
      'INVENTORY' => 'فتح المخزون',
      'ADMIN' => 'عرض الإعدادات',
      _ => 'عرض',
    };

String _fallbackTitle(String type) => switch (type) {
      'NEW_ORDER' => 'طلب جديد',
      'LOW_STOCK' => 'تنبيه مخزون',
      'LISTING_APPROVED' => 'تم اعتماد عرض',
      'LISTING_REJECTED' => 'تم رفض عرض',
      'ORDER_CANCELLED' => 'تم إلغاء طلب',
      _ => 'تحديث جديد',
    };

String _relativeTime(DateTime? value) {
  if (value == null) return 'الوقت غير متوفر';
  final difference = DateTime.now().difference(value.toLocal());
  if (difference.inMinutes < 1) return 'الآن';
  if (difference.inMinutes < 60) return 'منذ ${difference.inMinutes} دقيقة';
  if (difference.inHours < 24) return 'منذ ${difference.inHours} ساعة';
  return 'منذ ${difference.inDays} يوم';
}
