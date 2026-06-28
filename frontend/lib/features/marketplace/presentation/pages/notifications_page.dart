import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/core/theme/app_colors.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/core/theme/app_text_styles.dart';
import 'package:ghiyarak/features/auth/data/auth_repository.dart';
import 'package:ghiyarak/features/customer/data/customer_repository.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:go_router/go_router.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  String _type = 'all';
  bool _unreadOnly = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 35), (_) {
      if (mounted) {
        ref.invalidate(
            _notificationsProvider(_NotificationQuery(_type, _unreadOnly)));
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _NotificationQuery(_type, _unreadOnly);
    final state = ref.watch(_notificationsProvider(query));

    return AppScaffold(
      title: 'إشعاراتي',
      child: state.when(
        loading: () => const _LoadingList(),
        error: (error, _) => _StatePanel(
          icon: Icons.error_outline,
          title: 'تعذر تحميل الإشعارات',
          message: error.toString(),
          actionText: 'إعادة المحاولة',
          onAction: () => ref.invalidate(_notificationsProvider(query)),
        ),
        data: (data) {
          if (!data.isAuthenticated) {
            return _StatePanel(
              icon: Icons.lock_person_outlined,
              title: 'الإشعارات تحتاج تسجيل دخول',
              message:
                  'سجل دخولك حتى تظهر تنبيهات الطلبات والدفع والشحن والمحادثات والنزاعات.',
              actionText: 'تسجيل الدخول',
              onAction: () => context.go(
                  '${RouteNames.login}?returnTo=${Uri.encodeComponent(RouteNames.notifications)}'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(_notificationsProvider(query)),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                _Header(
                  unreadCount: data.result.unreadCount,
                  totalCount: data.result.totalCount,
                  onMarkAllRead: data.result.unreadCount == 0
                      ? null
                      : () => _markAllRead(query),
                  onSettings: () => context.push(RouteNames.customerSettings),
                ),
                const SizedBox(height: 12),
                _TypeFilters(
                  selected: _type,
                  unreadOnly: _unreadOnly,
                  counts: data.result.typeCounts,
                  onSelected: (value) => setState(() => _type = value),
                  onUnreadOnly: (value) => setState(() => _unreadOnly = value),
                ),
                const SizedBox(height: 14),
                if (data.result.items.isEmpty)
                  _StatePanel(
                    icon: Icons.notifications_none,
                    title: _unreadOnly
                        ? 'لا توجد إشعارات غير مقروءة'
                        : 'لا توجد إشعارات حاليا',
                    message:
                        'ستظهر هنا تنبيهات الطلبات والدفع والشحن والمحادثات والعروض والمرتجعات والنزاعات.',
                    actionText: 'تصفح القطع',
                    onAction: () => context.go(RouteNames.marketplaceSearch),
                  )
                else
                  ...data.result.items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _NotificationCard(
                          item: item,
                          onTap: () => _openNotification(item, query),
                          onRead: item.isRead
                              ? null
                              : () => _markRead(item.id, query),
                          onDelete: () => _deleteNotification(item.id, query),
                          onCopy: () => _copy(item),
                        ),
                      )),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _markRead(String id, _NotificationQuery query) async {
    try {
      await ref.read(customerRepositoryProvider).markNotificationRead(id);
      ref.invalidate(_notificationsProvider(query));
    } catch (e) {
      _snack(e.toString());
    }
  }

  Future<void> _markAllRead(_NotificationQuery query) async {
    try {
      await ref.read(customerRepositoryProvider).markAllNotificationsRead();
      ref.invalidate(_notificationsProvider(query));
      _snack('تم تعليم جميع الإشعارات كمقروءة');
    } catch (e) {
      _snack(e.toString());
    }
  }

  Future<void> _deleteNotification(String id, _NotificationQuery query) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الإشعار'),
        content: const Text('هل تريد حذف هذا الإشعار من قائمتك؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('تراجع')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(customerRepositoryProvider).deleteNotification(id);
      ref.invalidate(_notificationsProvider(query));
      _snack('تم حذف الإشعار');
    } catch (e) {
      _snack(e.toString());
    }
  }

  Future<void> _openNotification(
      CustomerNotification item, _NotificationQuery query) async {
    if (!item.isRead && item.id.isNotEmpty) {
      await ref.read(customerRepositoryProvider).markNotificationRead(item.id);
      ref.invalidate(_notificationsProvider(query));
    }
    if (!mounted) return;
    final target = _targetRoute(item);
    if (target == null) {
      _showDetails(item);
      return;
    }
    context.push(target);
  }

  String? _targetRoute(CustomerNotification item) {
    final route = item.route;
    if (route != null && route.startsWith('/')) return route;
    final type = item.typeCode.toLowerCase();
    if ((type.contains('order') ||
            type.contains('cancel') ||
            type.contains('return')) &&
        item.orderId != null) {
      if (type.contains('shipment') || type.contains('delivery')) {
        return '${RouteNames.customerTracking}?orderId=${Uri.encodeComponent(item.orderId!)}';
      }
      return '${RouteNames.orderDetail}/${item.orderId}';
    }
    if ((type.contains('payment') || type.contains('wallet')) &&
        item.orderId != null) {
      return '${RouteNames.paymentResult}/${item.orderId}';
    }
    if ((type.contains('chat') || type.contains('message')) &&
        item.chatId != null) {
      return '${RouteNames.customerChat}?chatId=${Uri.encodeComponent(item.chatId!)}';
    }
    if ((type.contains('dispute') || type.contains('complaint')) &&
        item.disputeId != null) {
      return '${RouteNames.customerDisputeDetail}/${item.disputeId}';
    }
    if (type.contains('promotion') ||
        type.contains('coupon') ||
        type.contains('discount')) {
      return RouteNames.customerCoupons;
    }
    if (type.contains('favorite') ||
        type.contains('price') ||
        type.contains('stock')) {
      return RouteNames.marketplaceFavorites;
    }
    if (item.listingId != null) {
      return '${RouteNames.listingDetail}/${item.listingId}';
    }
    return null;
  }

  void _showDetails(CustomerNotification item) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.title, style: AppTextStyles.title),
            const SizedBox(height: 10),
            Text(item.body, style: AppTextStyles.bodySecondary),
            const SizedBox(height: 12),
            _MetaRow(label: 'النوع', value: _typeLabel(item.typeCode)),
            if (item.createdAt.isNotEmpty)
              _MetaRow(label: 'التاريخ', value: item.createdAt),
            const SizedBox(height: 12),
            AppButton(text: 'نسخ الإشعار', onPressed: () => _copy(item)),
          ],
        ),
      ),
    );
  }

  Future<void> _copy(CustomerNotification item) async {
    await Clipboard.setData(
        ClipboardData(text: '${item.title}\n${item.body}\n${item.createdAt}'));
    _snack('تم نسخ الإشعار');
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _Header extends StatelessWidget {
  final int unreadCount;
  final int totalCount;
  final VoidCallback? onMarkAllRead;
  final VoidCallback onSettings;

  const _Header(
      {required this.unreadCount,
      required this.totalCount,
      required this.onMarkAllRead,
      required this.onSettings});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppColors.primary,
          AppColors.primary.withValues(alpha: .78)
        ]),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_active_outlined,
                  color: Colors.white, size: 34),
              const SizedBox(width: 10),
              Expanded(
                  child: Text('مركز إشعارات العميل',
                      style:
                          AppTextStyles.title.copyWith(color: Colors.white))),
              IconButton(
                  onPressed: onSettings,
                  icon: const Icon(Icons.tune_outlined, color: Colors.white),
                  tooltip: 'إعدادات الإشعارات'),
            ],
          ),
          const SizedBox(height: 10),
          Text(
              'تابع الطلبات، المدفوعات، الشحن، المحادثات، المرتجعات، النزاعات والعروض من مكان واحد.',
              style: AppTextStyles.body
                  .copyWith(color: Colors.white.withValues(alpha: .9))),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                  child: _Metric(label: 'غير مقروء', value: '$unreadCount')),
              const SizedBox(width: 10),
              Expanded(child: _Metric(label: 'الإجمالي', value: '$totalCount')),
              const SizedBox(width: 10),
              FilledButton.tonalIcon(
                  onPressed: onMarkAllRead,
                  icon: const Icon(Icons.done_all),
                  label: const Text('قراءة الكل')),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  const _Metric({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .14),
          borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 20)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(color: Colors.white.withValues(alpha: .82))),
      ]),
    );
  }
}

class _TypeFilters extends StatelessWidget {
  final String selected;
  final bool unreadOnly;
  final Map<String, int> counts;
  final ValueChanged<String> onSelected;
  final ValueChanged<bool> onUnreadOnly;

  const _TypeFilters(
      {required this.selected,
      required this.unreadOnly,
      required this.counts,
      required this.onSelected,
      required this.onUnreadOnly});

  @override
  Widget build(BuildContext context) {
    final filters = const [
      ('all', 'الكل', Icons.all_inbox_outlined),
      ('orders', 'الطلبات', Icons.receipt_long_outlined),
      ('payments', 'الدفع', Icons.payments_outlined),
      ('shipments', 'الشحن', Icons.local_shipping_outlined),
      ('chats', 'المحادثات', Icons.chat_bubble_outline),
      ('returns', 'المرتجعات', Icons.assignment_return_outlined),
      ('disputes', 'النزاعات', Icons.report_problem_outlined),
      ('promotions', 'العروض', Icons.local_offer_outlined),
      ('wallet', 'المحفظة', Icons.account_balance_wallet_outlined),
    ];
    return Column(
      children: [
        DropdownButtonFormField<String>(
          initialValue: filters.any((f) => f.$1 == selected) ? selected : 'all',
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'تصفية الإشعارات',
            prefixIcon: Icon(Icons.filter_list_rounded),
          ),
          items: filters.map((f) {
            final count = counts[f.$1] ?? 0;
            return DropdownMenuItem<String>(
              value: f.$1,
              child: Row(
                children: [
                  Icon(f.$3, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      count > 0 ? '${f.$2} ($count)' : f.$2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (next) {
            if (next != null) onSelected(next);
          },
        ),
        const SizedBox(height: 8),
        SwitchListTile.adaptive(
          value: unreadOnly,
          onChanged: onUnreadOnly,
          title: const Text('عرض غير المقروء فقط'),
          secondary: const Icon(Icons.mark_email_unread_outlined),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final CustomerNotification item;
  final VoidCallback onTap;
  final VoidCallback? onRead;
  final VoidCallback onDelete;
  final VoidCallback onCopy;

  const _NotificationCard(
      {required this.item,
      required this.onTap,
      required this.onRead,
      required this.onDelete,
      required this.onCopy});

  @override
  Widget build(BuildContext context) {
    final meta = _typeLabel(item.typeCode);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: item.isRead ? AppColors.surface : AppColors.surfaceTint,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: item.isRead ? AppColors.border : AppColors.secondary,
              width: item.isRead ? 1 : 1.5),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: .04),
                blurRadius: 14,
                offset: const Offset(0, 6))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(18)),
                child:
                    Icon(_iconForType(item.typeCode), color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                            child:
                                Text(item.title, style: AppTextStyles.title)),
                        if (!item.isRead)
                          Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                  color: AppColors.secondary,
                                  shape: BoxShape.circle)),
                      ]),
                      const SizedBox(height: 6),
                      Text(item.body, style: AppTextStyles.bodySecondary),
                    ]),
              ),
            ]),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _Pill(icon: Icons.category_outlined, text: meta),
              if (item.createdAt.isNotEmpty)
                _Pill(icon: Icons.schedule_outlined, text: item.createdAt),
              if (item.isActionable)
                const _Pill(
                    icon: Icons.open_in_new_outlined,
                    text: 'يفتح الصفحة المناسبة'),
            ]),
            const Divider(height: 22),
            Row(children: [
              TextButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('فتح')),
              if (onRead != null)
                TextButton.icon(
                    onPressed: onRead,
                    icon: const Icon(Icons.done),
                    label: const Text('مقروء')),
              const Spacer(),
              IconButton(
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy_outlined),
                  tooltip: 'نسخ'),
              IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'حذف'),
            ]),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Pill({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.border)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(fontSize: 12))
      ]),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;
  const _MetaRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w800)),
        Expanded(child: Text(value))
      ]),
    );
  }
}

class _StatePanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionText;
  final VoidCallback onAction;

  const _StatePanel(
      {required this.icon,
      required this.title,
      required this.message,
      required this.actionText,
      required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 20),
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: AppColors.iconAccent, size: 46),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.sm),
          Text(message,
              textAlign: TextAlign.center, style: AppTextStyles.bodySecondary),
          const SizedBox(height: AppSpacing.lg),
          AppButton(text: actionText, onPressed: onAction),
        ]),
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        height: 116,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border)),
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

IconData _iconForType(String type) {
  final value = type.toLowerCase();
  if (value.contains('order')) return Icons.receipt_long_outlined;
  if (value.contains('ship') || value.contains('delivery')) {
    return Icons.local_shipping_outlined;
  }
  if (value.contains('payment') || value.contains('wallet')) {
    return Icons.account_balance_wallet_outlined;
  }
  if (value.contains('chat') || value.contains('message')) {
    return Icons.chat_bubble_outline;
  }
  if (value.contains('return') || value.contains('refund')) {
    return Icons.assignment_return_outlined;
  }
  if (value.contains('dispute') || value.contains('complaint')) {
    return Icons.report_problem_outlined;
  }
  if (value.contains('coupon') ||
      value.contains('promotion') ||
      value.contains('discount')) {
    return Icons.local_offer_outlined;
  }
  if (value.contains('favorite') ||
      value.contains('stock') ||
      value.contains('price')) {
    return Icons.favorite_border;
  }
  return Icons.notifications_active_outlined;
}

String _typeLabel(String type) {
  final value = type.toLowerCase();
  if (value.contains('order')) return 'الطلبات';
  if (value.contains('ship') || value.contains('delivery')) return 'الشحن';
  if (value.contains('payment')) return 'الدفع';
  if (value.contains('wallet')) return 'المحفظة';
  if (value.contains('chat') || value.contains('message')) return 'المحادثات';
  if (value.contains('return') || value.contains('refund')) return 'المرتجعات';
  if (value.contains('dispute') || value.contains('complaint')) {
    return 'النزاعات';
  }
  if (value.contains('coupon') ||
      value.contains('promotion') ||
      value.contains('discount')) {
    return 'العروض';
  }
  return 'عام';
}

class _NotificationsState {
  final bool isAuthenticated;
  final CustomerNotificationsResult result;

  const _NotificationsState(
      {required this.isAuthenticated, required this.result});
}

class _NotificationQuery {
  final String type;
  final bool unreadOnly;
  const _NotificationQuery(this.type, this.unreadOnly);

  @override
  bool operator ==(Object other) =>
      other is _NotificationQuery &&
      other.type == type &&
      other.unreadOnly == unreadOnly;

  @override
  int get hashCode => Object.hash(type, unreadOnly);
}

final _notificationsProvider =
    FutureProvider.family<_NotificationsState, _NotificationQuery>(
        (ref, query) async {
  final authRepository = ref.read(authRepositoryProvider);
  final isAuthenticated = await authRepository.isAuthenticated();
  if (!isAuthenticated) {
    return const _NotificationsState(
      isAuthenticated: false,
      result: CustomerNotificationsResult(
          items: [], unreadCount: 0, totalCount: 0, typeCounts: {}),
    );
  }

  final result = await ref
      .read(customerRepositoryProvider)
      .notifications(type: query.type, unreadOnly: query.unreadOnly);
  return _NotificationsState(isAuthenticated: true, result: result);
});
