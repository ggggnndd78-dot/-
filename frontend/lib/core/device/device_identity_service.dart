import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/storage/secure_storage_service.dart';

final deviceIdentityServiceProvider = Provider<DeviceIdentityService>((ref) {
  return DeviceIdentityService(ref.watch(secureStorageServiceProvider));
});

class DeviceIdentity {
  final String fingerprint;
  final String deviceName;
  final String platform;
  final String? deviceToken;

  const DeviceIdentity({
    required this.fingerprint,
    required this.deviceName,
    required this.platform,
    this.deviceToken,
  });

  Map<String, dynamic> toJson({bool includeDeviceToken = true}) => {
        'deviceFingerprint': fingerprint,
        'deviceName': deviceName,
        'platform': platform,
        if (includeDeviceToken && (deviceToken ?? '').isNotEmpty)
          'deviceToken': deviceToken,
      };
}

class DeviceIdentityService {
  final SecureStorageService _secureStorage;

  DeviceIdentityService(this._secureStorage);

  Future<DeviceIdentity> load() async {
    var fingerprint = await _secureStorage.getDeviceFingerprint();
    if ((fingerprint ?? '').isEmpty) {
      fingerprint = _generateFingerprint();
      await _secureStorage.saveDeviceFingerprint(fingerprint);
    }
    return DeviceIdentity(
      fingerprint: fingerprint!,
      deviceName: _deviceName(),
      platform: _platformName(),
      deviceToken: await _secureStorage.getTrustedDeviceToken(),
    );
  }

  Future<void> saveTrustedDeviceToken(String token) =>
      _secureStorage.saveTrustedDeviceToken(token);

  String _platformName() {
    if (kIsWeb) return 'WEB';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'ANDROID';
      case TargetPlatform.iOS:
        return 'IOS';
      case TargetPlatform.windows:
        return 'WINDOWS';
      case TargetPlatform.macOS:
        return 'MACOS';
      case TargetPlatform.linux:
        return 'LINUX';
      default:
        return 'UNKNOWN';
    }
  }

  String _deviceName() =>
      kIsWeb ? 'Ghiyarak Web' : 'Ghiyarak ${_platformName()}';

  String _generateFingerprint() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    final body =
        List.generate(40, (_) => chars[random.nextInt(chars.length)]).join();
    return 'ghy_$body';
  }
}
