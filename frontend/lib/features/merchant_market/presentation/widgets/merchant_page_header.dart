import 'package:flutter/material.dart';
import 'package:ghiyarak/core/config/app_config.dart';
import 'package:ghiyarak/core/i18n/app_localizations.dart';
import 'package:ghiyarak/core/theme/app_colors.dart';
import 'package:ghiyarak/core/theme/app_radius.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/core/theme/app_text_styles.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_drawer.dart';

class MerchantPageHeader extends StatelessWidget {
  const MerchantPageHeader({
    required this.title,
    required this.subtitle,
    required this.onMenu,
    required this.notificationCount,
    required this.onNotifications,
    this.bottom,
    super.key,
  });

  final String title;
  final String subtitle;
  final VoidCallback onMenu;
  final int notificationCount;
  final VoidCallback onNotifications;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        MediaQuery.paddingOf(context).top + AppSpacing.sm,
        AppSpacing.lg,
        bottom == null ? AppSpacing.xl : AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius:
            BorderRadius.vertical(bottom: Radius.circular(AppRadius.xl)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              MerchantDrawerButton(onPressed: onMenu),
              const Spacer(),
              Image.asset(
                AppConfig.logoAsset,
                width: 126,
                height: 62,
                fit: BoxFit.contain,
              ),
              const Spacer(),
              _NotificationButton(
                count: notificationCount,
                onTap: onNotifications,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              title,
              style: AppTextStyles.pageTitle.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              subtitle,
              style: AppTextStyles.bodySecondary.copyWith(
                color: Colors.white.withValues(alpha: 0.78),
              ),
            ),
          ),
          if (bottom != null) ...[
            const SizedBox(height: AppSpacing.lg),
            bottom!,
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
          tooltip: context.tr('notifications.title'),
          onPressed: onTap,
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: Colors.white,
            size: 30,
          ),
        ),
        if (count > 0)
          PositionedDirectional(
            top: 0,
            end: 0,
            child: Container(
              constraints: const BoxConstraints(minWidth: 21, minHeight: 21),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.warning,
                shape: BoxShape.circle,
              ),
              child: Text(
                count > 99 ? '99+' : '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
