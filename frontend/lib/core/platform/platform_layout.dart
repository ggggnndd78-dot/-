import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Shared cross-platform layout decisions. Business logic must stay outside
/// platform-specific widgets; this class only decides presentation breakpoints.
class PlatformLayout {
  const PlatformLayout._();

  static bool get isDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux);

  static bool get isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 700;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= 700 && width < 1100;
  }

  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 1100;

  /// Desktop/web shell decision for professional workspaces.
  /// Business logic remains shared; only navigation density and layout change.
  static bool isDesktopShell(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (isMobile) return false;
    // Even on Windows/macOS/Linux, a manually resized narrow window must switch
    // to the compact shell to avoid sidebar overflow and mobile-hostile spacing.
    return width >= 1000;
  }

  static bool isMobileShell(BuildContext context) => !isDesktopShell(context);

  static double contentMaxWidth(BuildContext context) {
    if (isWide(context)) return 1180;
    if (isTablet(context)) return 860;
    return double.infinity;
  }
}
