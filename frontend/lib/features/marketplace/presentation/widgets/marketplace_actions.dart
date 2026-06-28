import 'package:flutter/material.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:go_router/go_router.dart';

class MarketplaceActions {
  const MarketplaceActions._();

  static void openSearch(BuildContext context) {
    context.go(RouteNames.marketplaceSearch);
  }

  static void showComingSoon(
    BuildContext context, {
    String message = 'سيتم تفعيل هذه الميزة قريبًا',
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
