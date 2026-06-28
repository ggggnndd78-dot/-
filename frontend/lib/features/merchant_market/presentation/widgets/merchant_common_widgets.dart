import 'package:flutter/material.dart';
import 'package:ghiyarak/core/i18n/app_localizations.dart';
import 'package:ghiyarak/shared/layout/dashboard_shell.dart';
import 'package:ghiyarak/shared/widgets/app_states.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_management_scaffold.dart';

class MerchantStatCard extends StatelessWidget {
  const MerchantStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.caption,
    super.key,
  });

  final String title;
  final String value;
  final String? caption;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DashboardMetricCard(
      title: title,
      value: value,
      icon: icon,
      color: color,
      caption: caption,
    );
  }
}

class MerchantEmptyState extends StatelessWidget {
  const MerchantEmptyState({
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      title: title,
      message: message,
      icon: icon,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}

class MerchantErrorState extends StatelessWidget {
  const MerchantErrorState(
      {required this.message, required this.onRetry, super.key});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AppErrorState(
      message:
          message.isEmpty ? context.tr('common.error.unexpected') : message,
      onRetry: onRetry,
    );
  }
}

class MerchantSectionCard extends StatelessWidget {
  const MerchantSectionCard({
    required this.child,
    this.title,
    this.icon,
    super.key,
  });

  final String? title;
  final IconData? icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MerchantPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    title!,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF082B51),
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          child,
        ],
      ),
    );
  }
}

String merchantMoney(num value, [String currency = 'ر.س']) {
  final text = value.toStringAsFixed(value % 1 == 0 ? 0 : 2);
  return '$text $currency';
}
