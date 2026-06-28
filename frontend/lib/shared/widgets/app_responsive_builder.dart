import 'package:flutter/material.dart';
import 'package:ghiyarak/core/platform/platform_layout.dart';

typedef AppResponsiveWidgetBuilder = Widget Function(
  BuildContext context,
  bool isDesktop,
  bool isTablet,
  bool isMobile,
);

class AppResponsiveBuilder extends StatelessWidget {
  const AppResponsiveBuilder({super.key, required this.builder});

  final AppResponsiveWidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    final desktop = PlatformLayout.isDesktopShell(context);
    final tablet = PlatformLayout.isTablet(context);
    final mobile = !desktop && !tablet;
    return builder(context, desktop, tablet, mobile);
  }
}
