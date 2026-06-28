import 'package:flutter/material.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/shared/layout/dashboard_shell.dart';
import 'package:ghiyarak/shared/navigation/app_navigation_config.dart';

enum MerchantNavigationTab {
  home,
  orders,
  products,
  reports,
  settings,
}

class MerchantBottomNavigation extends StatelessWidget {
  const MerchantBottomNavigation({
    required this.currentTab,
    this.compact = false,
    super.key,
  });

  final MerchantNavigationTab currentTab;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DashboardBottomNavigation(
      area: AppNavigationArea.merchant,
      currentRoute: _routeForTab(currentTab),
    );
  }

  String _routeForTab(MerchantNavigationTab tab) {
    return switch (tab) {
      MerchantNavigationTab.home => RouteNames.merchantHub,
      MerchantNavigationTab.orders => RouteNames.merchantOrders,
      MerchantNavigationTab.products => RouteNames.merchantListings,
      MerchantNavigationTab.reports => RouteNames.merchantReports,
      MerchantNavigationTab.settings => RouteNames.merchantSettings,
    };
  }
}
