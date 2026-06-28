import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return const SecureStorageService();
});

class SecureStorageService {
  const SecureStorageService();

  static const _storage = FlutterSecureStorage();

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _trustedDeviceTokenKey = 'trusted_device_token';
  static const _deviceFingerprintKey = 'device_fingerprint';

  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  Future<String?> getAccessToken() async {
    return _storage.read(key: _accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return _storage.read(key: _refreshTokenKey);
  }

  Future<void> saveTrustedDeviceToken(String token) async {
    await _storage.write(key: _trustedDeviceTokenKey, value: token);
  }

  Future<String?> getTrustedDeviceToken() async {
    return _storage.read(key: _trustedDeviceTokenKey);
  }

  Future<void> saveDeviceFingerprint(String value) async {
    await _storage.write(key: _deviceFingerprintKey, value: value);
  }

  Future<String?> getDeviceFingerprint() async {
    return _storage.read(key: _deviceFingerprintKey);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  Future<void> clearTrustedDevice() async {
    await _storage.delete(key: _trustedDeviceTokenKey);
    await _storage.delete(key: _deviceFingerprintKey);
  }
}
