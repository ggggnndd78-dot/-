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

final _notificationsProvider =
    FutureProvider.autoDispose<List<NotificationModel>>(
        (ref) => ref.read(logisticsRepositoryProvider).getNotifications());

class NotificationsCenterPage extends ConsumerWidget {
  const NotificationsCenterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(_notificationsProvider);
    return AppScaffold(
      title: 'الإشعارات',
      child: RefreshIndicator(
        onRefresh: () async => ref.invalidate(_notificationsProvider),
        child: notifications.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(children: [_Message(text: e.toString())]),
          data: (items) => ListView.separated(
            itemCount: items.isEmpty ? 2 : items.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionTitle(
                          title: 'مركز الإشعارات',
                          subtitle:
                              'كل الإشعارات محمّلة من الباك إند حسب المستخدم الحالي.'),
                      const SizedBox(height: AppSpacing.md),
                      AppButton(
                          text: 'تحديد الكل كمقروء',
                          isOutlined: true,
                          onPressed: () async {
                            await ref
                                .read(logisticsRepositoryProvider)
                                .markAllNotificationsRead();
                            ref.invalidate(_notificationsProvider);
                          }),
                    ]);
              }
              if (items.isEmpty) {
                return const _Message(text: 'لا توجد إشعارات حالياً.');
              }
              return _NotificationCard(notification: items[index - 1]);
            },
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends ConsumerWidget {
  final NotificationModel notification;
  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = notification.status == 'UNREAD';
    return InkWell(
      onTap: () async {
        await ref
            .read(logisticsRepositoryProvider)
            .markNotificationRead(notification.id.toString());
        ref.invalidate(_notificationsProvider);
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
            color: unread ? AppColors.accentSoft : AppColors.surface,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(18)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(notification.title, style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.xs),
          Text(notification.body, style: AppTextStyles.bodySecondary),
          const SizedBox(height: AppSpacing.xs),
          Text(notification.createdAt, style: AppTextStyles.caption),
        ]),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final String text;
  const _Message({required this.text});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border)),
      child: Text(text, style: AppTextStyles.bodySecondary));
}
