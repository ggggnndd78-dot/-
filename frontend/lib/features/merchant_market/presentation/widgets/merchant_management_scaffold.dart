import 'package:flutter/material.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/core/theme/app_colors.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_bottom_navigation.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_theme_tokens.dart';
import 'package:ghiyarak/shared/layout/dashboard_shell.dart';
import 'package:ghiyarak/shared/navigation/app_navigation_config.dart';
import 'package:ghiyarak/shared/widgets/app_card.dart';
import 'package:ghiyarak/shared/widgets/app_states.dart';

class MerchantManagementScaffold extends StatelessWidget {
  const MerchantManagementScaffold({
    required this.title,
    required this.subtitle,
    required this.children,
    this.currentTab = MerchantNavigationTab.settings,
    this.onRefresh,
    super.key,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final MerchantNavigationTab currentTab;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: MerchantThemeTokens.theme(context),
      child: DashboardShell(
        title: title,
        subtitle: subtitle,
        currentRoute: _routeForTab(currentTab),
        navigationArea: AppNavigationArea.merchant,
        onRefresh: onRefresh,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < children.length; i++) ...[
                    if (i > 0) const SizedBox(height: AppSpacing.lg),
                    children[i],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _routeForTab(MerchantNavigationTab tab) {
    return switch (tab) {
      MerchantNavigationTab.home => RouteNames.merchantHub,
      MerchantNavigationTab.products => RouteNames.merchantListings,
      MerchantNavigationTab.orders => RouteNames.merchantOrders,
      MerchantNavigationTab.reports => RouteNames.merchantReports,
      MerchantNavigationTab.settings => RouteNames.merchantSettings,
    };
  }
}

class MerchantPanel extends StatelessWidget {
  const MerchantPanel({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadding),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: MerchantThemeTokens.panelBackground,
        borderRadius:
            BorderRadius.circular(MerchantThemeTokens.panelRadius),
        border: Border.all(color: MerchantThemeTokens.panelBorder),
        boxShadow: MerchantThemeTokens.panelShadow,
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: MerchantThemeTokens.heading),
        child: Material(
          color: Colors.transparent,
          child: child,
        ),
      ),
    );
  }
}

class MerchantStateCard extends StatelessWidget {
  const MerchantStateCard({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: icon,
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}

class MerchantMetricTile extends StatelessWidget {
  const MerchantMetricTile({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DashboardMetricCard(
      icon: icon,
      title: label,
      value: value,
      color: AppColors.primary,
    );
  }
}
