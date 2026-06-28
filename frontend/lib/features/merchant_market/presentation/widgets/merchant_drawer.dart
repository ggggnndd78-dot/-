import 'package:flutter/material.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/core/i18n/app_localizations.dart';
import 'package:ghiyarak/core/theme/app_colors.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_bottom_navigation.dart';
import 'package:ghiyarak/shared/layout/dashboard_shell.dart';
import 'package:ghiyarak/shared/navigation/app_navigation_config.dart';

class MerchantDrawerButton extends StatelessWidget {
  const MerchantDrawerButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: context.tr('common.openMenu'),
      child: Material(
        color: Colors.white.withValues(alpha: .08),
        shape: const CircleBorder(
          side: BorderSide(color: Colors.white, width: 1.3),
        ),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: const SizedBox(
            width: 46,
            height: 46,
            child: Icon(Icons.menu_rounded, color: Colors.white, size: 29),
          ),
        ),
      ),
    );
  }
}

class MerchantDrawer extends StatelessWidget {
  const MerchantDrawer({required this.currentTab, super.key});

  final MerchantNavigationTab currentTab;

  @override
  Widget build(BuildContext context) {
    return DashboardSidebar(
      area: AppNavigationArea.merchant,
      currentRoute: _routeForTab(currentTab),
      compact: true,
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

Color merchantStatusColor(String? status) {
  return switch ((status ?? '').toUpperCase()) {
    'APPROVED' || 'ACTIVE' => AppColors.success,
    'PENDING_REVIEW' ||
    'DOCUMENTS_REQUIRED' ||
    'PAUSED' => AppColors.warning,
    'OUT_OF_STOCK' => const Color(0xFFEA580C),
    'SUSPENDED' || 'REJECTED' => AppColors.danger,
    'DRAFT' || 'ARCHIVED' => const Color(0xFF64748B),
    _ => AppColors.info,
  };
}
