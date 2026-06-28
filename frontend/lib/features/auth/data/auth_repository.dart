import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/config/api_endpoints.dart';
import 'package:ghiyarak/core/device/device_identity_service.dart';
import 'package:ghiyarak/core/network/api_client.dart';
import 'package:ghiyarak/core/network/api_exception.dart';
import 'package:ghiyarak/core/storage/local_storage_service.dart';
import 'package:ghiyarak/core/storage/secure_storage_service.dart';
import 'package:ghiyarak/core/validation/yemen_phone_validator.dart';
import 'package:ghiyarak/features/auth/data/models/auth_response_model.dart';
import 'package:ghiyarak/features/auth/data/models/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(secureStorageServiceProvider),
    ref.watch(localStorageServiceProvider),
    ref.watch(deviceIdentityServiceProvider),
  );
});

class OtpRequestResult {
  final String target;
  final String? devOtpCode;
  final String? provider;
  final DateTime? expiresAt;

  const OtpRequestResult({
    required this.target,
    this.devOtpCode,
    this.provider,
    this.expiresAt,
  });

  bool get hasDevOtp => (devOtpCode ?? '').trim().isNotEmpty;
}

class LoginStartResult {
  final String phone;
  final bool otpRequired;
  final bool trustedDevice;
  final UserModel? user;

  const LoginStartResult({
    required this.phone,
    required this.otpRequired,
    required this.trustedDevice,
    this.user,
  });
}

class AuthSession {
  final UserModel user;

  const AuthSession(this.user);

  bool get isMerchant =>
      user.hasRole('merchant_owner') || user.hasApprovedMerchantOrganization;
  bool get isWorkshop =>
      user.hasRole('workshop_owner') || user.hasApprovedWorkshopOrganization;
  bool get isWarehouse =>
      user.hasRole('warehouse_owner') || user.hasApprovedWarehouseOrganization;
  bool get isProvider => isMerchant || isWorkshop || isWarehouse;
  bool get isEnterprise => user
      .hasAnyRole(const ['admin_super', 'admin_operations', 'support_agent']);
}

class AuthRepository {
  final ApiClient _apiClient;
  final SecureStorageService _secureStorage;
  final LocalStorageService _localStorage;
  final DeviceIdentityService _deviceIdentity;

  AuthRepository(this._apiClient, this._secureStorage, this._localStorage,
      this._deviceIdentity);

  String normalizeYemeniPhone(String input) {
    return YemenPhoneValidator.toE164(input);
  }

  Future<Map<String, dynamic>> _devicePayload(
      {bool includeDeviceToken = true}) async {
    final device = await _deviceIdentity.load();
    return device.toJson(includeDeviceToken: includeDeviceToken);
  }

  Future<LoginStartResult> startPhoneLogin(String phone) async {
    final normalizedPhone = normalizeYemeniPhone(phone);
    final response = await _apiClient.post(
      ApiEndpoints.authLoginStart,
      data: {
        'phone': normalizedPhone,
        ...(await _devicePayload()),
      },
    );
    final rawData = response.data is Map ? response.data['data'] : null;
    final data = rawData is Map
        ? Map<String, dynamic>.from(rawData)
        : const <String, dynamic>{};
    if (data['access_token'] != null || data['accessToken'] != null) {
      final user = await _persistAuthResponse({'data': data});
      return LoginStartResult(
          phone: normalizedPhone,
          otpRequired: false,
          trustedDevice: true,
          user: user);
    }
    return LoginStartResult(
      phone: normalizedPhone,
      otpRequired: data['otp_required'] != false,
      trustedDevice: data['trusted_device'] == true,
    );
  }

  Future<UserModel> verifyTrustedDeviceOtp(
      {required String phone, required String code}) async {
    final response = await _apiClient.post(
      ApiEndpoints.authVerifyDeviceOtp,
      data: {
        'phone': phone,
        'otpCode': code,
        ...(await _devicePayload(includeDeviceToken: false)),
      },
    );
    return _persistAuthResponse(response.data);
  }

  Future<UserModel> registerCustomer(
      {required String phone,
      required String code,
      String? displayName,
      String? email}) async {
    final response = await _apiClient.post(
      ApiEndpoints.registerCustomer,
      data: {
        'phone': phone,
        'otpCode': code,
        if ((displayName ?? '').trim().isNotEmpty)
          'fullName': displayName!.trim(),
        if ((email ?? '').trim().isNotEmpty) 'email': email!.trim(),
        ...(await _devicePayload(includeDeviceToken: false)),
      },
    );
    return _persistAuthResponse(response.data);
  }

  Future<UserModel?> registerBusiness({
    required String accountType,
    required String phone,
    required String code,
    required String fullName,
    required String email,
    required int cityId,
    int? districtId,
    int? areaId,
    String? branchName,
    required String address,
    required String businessName,
    required String businessDescription,
    double? latitude,
    double? longitude,
    String? mapUrl,
    required List<Map<String, dynamic>> documents,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.registerBusiness,
      data: {
        'accountType': accountType,
        'phone': phone,
        'otpCode': code,
        'fullName': fullName,
        'email': email,
        'cityId': cityId,
        if (districtId != null) 'districtId': districtId,
        if (areaId != null) 'areaId': areaId,
        if ((branchName ?? '').trim().isNotEmpty)
          'branchName': branchName!.trim(),
        'address': address,
        'businessName': businessName,
        'businessDescription': businessDescription,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if ((mapUrl ?? '').trim().isNotEmpty) 'mapUrl': mapUrl!.trim(),
        'documents': documents,
        ...(await _devicePayload(includeDeviceToken: false)),
      },
    );
    final rawData = response.data is Map ? response.data['data'] : null;
    final data = rawData is Map
        ? Map<String, dynamic>.from(rawData)
        : const <String, dynamic>{};
    final authPayload = data['auth'];
    if (authPayload is Map) {
      return _persistAuthResponse(
          {'data': Map<String, dynamic>.from(authPayload)});
    }
    return null;
  }

  Future<OtpRequestResult> requestOtp(String phone,
      {String purpose = 'LOGIN'}) async {
    final normalizedPhone = normalizeYemeniPhone(phone);
    final response = await _apiClient.post(
      ApiEndpoints.requestOtp,
      data: {'phone': normalizedPhone, 'channel': 'SMS', 'purpose': purpose},
    );

    final rawData = response.data is Map ? response.data['data'] : null;
    final data = rawData is Map
        ? Map<String, dynamic>.from(rawData)
        : const <String, dynamic>{};
    final expiresAtText = data['expires_at']?.toString();

    return OtpRequestResult(
      target: normalizedPhone,
      devOtpCode: data['if_dev_mode_otp']?.toString(),
      provider: data['provider']?.toString(),
      expiresAt:
          expiresAtText == null ? null : DateTime.tryParse(expiresAtText),
    );
  }

  Future<UserModel> verifyOtp(
      {required String phone,
      required String code,
      String? displayName,
      String purpose = 'LOGIN'}) async {
    final response = await _apiClient.post(
      ApiEndpoints.verifyOtp,
      data: {
        'phone': phone,
        'otpCode': code,
        'purpose': purpose,
        if ((displayName ?? '').trim().isNotEmpty)
          'displayName': displayName!.trim(),
      },
    );
    return _persistAuthResponse(response.data);
  }

  Future<bool> refreshAccessToken() async {
    final refreshToken = await _secureStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;
    try {
      final response = await _apiClient.post(
        ApiEndpoints.refreshToken,
        data: {'refreshToken': refreshToken},
      );
      await _persistAuthResponse(response.data);
      return true;
    } catch (_) {
      await clearAuthSession();
      return false;
    }
  }

  Future<UserModel> _persistAuthResponse(dynamic responseBody) async {
    final rawData = responseBody is Map ? responseBody['data'] : null;
    final data = rawData is Map
        ? Map<String, dynamic>.from(rawData)
        : const <String, dynamic>{};
    final auth = AuthResponseModel.fromJson(data);
    if (auth.accessToken.isEmpty) {
      throw Exception('Access token was not returned by the server');
    }
    await _secureStorage.saveAccessToken(auth.accessToken);
    if ((auth.refreshToken ?? '').isNotEmpty) {
      await _secureStorage.saveRefreshToken(auth.refreshToken!);
    }
    if ((auth.deviceToken ?? '').isNotEmpty) {
      await _deviceIdentity.saveTrustedDeviceToken(auth.deviceToken!);
    }
    await _localStorage.clearGuestSession();
    final user = auth.user ?? await getCurrentUser();
    await _localStorage.setProfileName(user.displayName);
    await _localStorage.setLocaleCode(user.locale);
    return user;
  }

  Future<UserModel> getCurrentUser() async {
    final accessToken = await _secureStorage.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('Authentication token is missing');
    }
    final response = await _apiClient.get(ApiEndpoints.me);
    final data = response.data is Map ? response.data['data'] : null;
    final user = data is Map ? data['user'] : null;
    final model = UserModel.fromJson(user is Map
        ? Map<String, dynamic>.from(user)
        : const <String, dynamic>{});
    await _localStorage.setLocaleCode(model.locale);
    return model;
  }

  Future<void> continueAsGuest() async {
    final response = await _apiClient.post(
      ApiEndpoints.guestSessions,
      data: const <String, dynamic>{},
    );
    final rawData = response.data is Map ? response.data['data'] : null;
    final data = rawData is Map
        ? Map<String, dynamic>.from(rawData)
        : const <String, dynamic>{};
    final guestToken = data['guest_token']?.toString() ?? '';
    final guestSessionId = data['id']?.toString() ?? '';

    if (guestToken.isEmpty || guestSessionId.isEmpty) {
      throw Exception('تعذر إنشاء جلسة الزائر من الخادم');
    }

    await _secureStorage.clearTokens();
    await _localStorage.setGuestToken(guestToken);
    await _localStorage.setGuestSessionId(guestSessionId);
    await _localStorage.setGuestMode(true);
    debugPrint(
        '[Ghiyarak][Guest] Saved guest session id=$guestSessionId tokenLength=${guestToken.length}');
  }

  Future<bool> isAuthenticated() async {
    final token = await _secureStorage.getAccessToken();
    if (token == null || token.isEmpty) return false;
    if (_isJwtExpired(token)) return refreshAccessToken();
    try {
      await _apiClient.post(ApiEndpoints.validateSession,
          data: await _devicePayload());
      await getCurrentUser();
      return true;
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        return refreshAccessToken();
      }
      if (error.statusCode == 403) return true;
      return true;
    } catch (_) {
      return refreshAccessToken();
    }
  }

  Future<bool> isGuest() async {
    final guestMode = await _localStorage.isGuestMode();
    final guestToken = await _localStorage.getGuestToken();
    final guestSessionId = await _localStorage.getGuestSessionId();
    final ok = guestMode && guestToken.isNotEmpty && guestSessionId.isNotEmpty;
    debugPrint(
        '[Ghiyarak][Guest] isGuest=$ok mode=$guestMode id=${guestSessionId.isNotEmpty} token=${guestToken.isNotEmpty}');
    return ok;
  }

  Future<void> clearAuthSession() async {
    await _secureStorage.clearTokens();
    await _localStorage.clearSessionData();
  }

  Future<void> logout() async {
    final accessToken = await _secureStorage.getAccessToken();
    final refreshToken = await _secureStorage.getRefreshToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      try {
        await _apiClient.post(
          ApiEndpoints.logout,
          data: {
            if ((refreshToken ?? '').isNotEmpty) 'refreshToken': refreshToken
          },
        );
      } catch (_) {}
    }
    await clearAuthSession();
  }

  bool _isJwtExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      final payload = jsonDecode(
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      if (payload is! Map) return true;
      final expiry = int.tryParse(payload['exp']?.toString() ?? '');
      if (expiry == null) return true;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return expiry <= now + 30;
    } catch (_) {
      return true;
    }
  }
}
