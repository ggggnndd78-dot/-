import 'package:flutter/foundation.dart';

class AppSurface {
  static bool get isManagementSurface {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  static bool get isMobileAppSurface => !isManagementSurface;
}
