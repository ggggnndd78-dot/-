import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ghiyarak/core/config/env.dart';

class AppConfig {
  static const String appName = 'غيارك';
  static const String localeCode = String.fromEnvironment(
    'GHIYARAK_LOCALE',
    defaultValue: 'ar',
  );

  static Locale get locale => localeCode.toLowerCase().startsWith('en')
      ? const Locale('en')
      : const Locale('ar');
  static const String logoAsset = 'assets/images/ghiyarak_logo.png';
  static const bool clearSessionOnLaunchInDevelopment = false;

  /// Use --dart-define=GHIYARAK_API_BASE_URL=https://your-api/api/v1
  /// when building Web / Windows / Android / iOS production releases.
  static const String apiBaseUrlOverride = String.fromEnvironment(
    'GHIYARAK_API_BASE_URL',
    defaultValue: '',
  );

  static String get baseUrl {
    if (apiBaseUrlOverride.trim().isNotEmpty) return apiBaseUrlOverride.trim();

    switch (Env.current) {
      case AppEnv.development:
        if (kIsWeb ||
            defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.linux) {
          return 'http://localhost:3000/api/v1';
        }
        return 'http://192.168.8.130:3000/api/v1';
      case AppEnv.staging:
        return 'https://staging-api.ghiyarak.app/api/v1';
      case AppEnv.production:
        return apiBaseUrlOverride.trim().isNotEmpty
            ? apiBaseUrlOverride.trim()
            : 'https://api.ghiyarak.app/api/v1';
    }
  }
}
