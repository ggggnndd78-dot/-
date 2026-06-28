import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/config/api_endpoints.dart';
import 'package:ghiyarak/core/network/api_client.dart';
import 'package:ghiyarak/core/storage/local_storage_service.dart';
import 'package:ghiyarak/core/storage/secure_storage_service.dart';
import 'package:ghiyarak/features/profile/data/models/customer_address_model.dart';
import 'package:ghiyarak/features/profile/data/models/customer_profile_model.dart';
import 'package:ghiyarak/features/profile/data/models/customer_settings_model.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(
    ref.watch(apiClientProvider),
    ref.watch(localStorageServiceProvider),
    ref.watch(secureStorageServiceProvider),
  );
});

class ProfileRepository {
  final ApiClient _apiClient;
  final LocalStorageService _localStorage;
  final SecureStorageService _secureStorage;

  ProfileRepository(this._apiClient, this._localStorage, this._secureStorage);

  Future<void> _requireAccessToken() async {
    final accessToken = await _secureStorage.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('Authentication token is missing');
    }
  }

  Future<void> saveProfileName(String displayName) async {
    final accessToken = await _secureStorage.getAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      await _apiClient
          .patch(ApiEndpoints.meProfile, data: {'displayName': displayName});
    }
    await _localStorage.setProfileName(displayName);
  }

  Future<CustomerProfileModel> getCustomerProfile() async {
    await _requireAccessToken();
    final response = await _apiClient.get(ApiEndpoints.me);
    final data = response.data is Map ? response.data['data'] : response.data;
    return CustomerProfileModel.fromApi(
        data is Map ? Map<String, dynamic>.from(data) : const {});
  }

  Future<CustomerProfileModel> updateCustomerProfile({
    required String displayName,
    String? email,
    int? cityId,
    int? districtId,
    int? areaId,
    String? avatarUrl,
    String? locale,
  }) async {
    await _requireAccessToken();
    await _apiClient.patch(
      ApiEndpoints.meProfile,
      data: {
        'displayName': displayName.trim(),
        if ((email ?? '').trim().isNotEmpty) 'email': email!.trim(),
        if (cityId != null) 'cityId': cityId,
        if (districtId != null) 'districtId': districtId,
        if (areaId != null) 'areaId': areaId,
        if ((avatarUrl ?? '').trim().isNotEmpty) 'avatarUrl': avatarUrl!.trim(),
        if ((locale ?? '').trim().isNotEmpty) 'locale': locale!.trim(),
      },
    );
    await _localStorage.setProfileName(displayName.trim());
    return getCustomerProfile();
  }

  Future<void> logout() async {
    await _apiClient.post(ApiEndpoints.logout);
    await _secureStorage.clearTokens();
    await _localStorage.clearSessionData();
  }

  Future<void> requestAccountDeletion({required String reason}) async {
    await _requireAccessToken();
    await _apiClient
        .post(ApiEndpoints.meDeleteRequest, data: {'reason': reason.trim()});
  }

  Future<List<CustomerAddressModel>> getCustomerAddresses() async {
    await _requireAccessToken();
    final response = await _apiClient.get(ApiEndpoints.meAddresses);
    final data = response.data is Map ? response.data['data'] : response.data;
    final items = data is List
        ? data
        : data is Map && data['items'] is List
            ? data['items'] as List
            : const <dynamic>[];
    return items
        .whereType<Map>()
        .map((item) =>
            CustomerAddressModel.fromApi(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<CustomerAddressModel> createCustomerAddress(
      CustomerAddressPayload payload) async {
    await _requireAccessToken();
    final response =
        await _apiClient.post(ApiEndpoints.meAddresses, data: payload.toApi());
    final data = response.data is Map ? response.data['data'] : response.data;
    return CustomerAddressModel.fromApi(
        data is Map ? Map<String, dynamic>.from(data) : const {});
  }

  Future<CustomerAddressModel> updateCustomerAddress(
      String id, CustomerAddressPayload payload) async {
    await _requireAccessToken();
    final response = await _apiClient.patch(ApiEndpoints.meAddress(id),
        data: payload.toApi());
    final data = response.data is Map ? response.data['data'] : response.data;
    return CustomerAddressModel.fromApi(
        data is Map ? Map<String, dynamic>.from(data) : const {});
  }

  Future<void> deleteCustomerAddress(String id) async {
    await _requireAccessToken();
    await _apiClient.delete(ApiEndpoints.meAddress(id));
  }

  Future<void> setDefaultCustomerAddress(String id) async {
    await _requireAccessToken();
    await _apiClient.patch(ApiEndpoints.meAddressDefault(id));
  }

  Future<CustomerSettingsModel> getCustomerSettings() async {
    await _requireAccessToken();
    final response = await _apiClient.get(ApiEndpoints.meSettings);
    final data = response.data is Map ? response.data['data'] : response.data;
    return CustomerSettingsModel.fromApi(
        data is Map ? Map<String, dynamic>.from(data) : const {});
  }

  Future<CustomerSettingsModel> updateCustomerSettings(
      CustomerSettingsModel settings) async {
    await _requireAccessToken();
    final response =
        await _apiClient.put(ApiEndpoints.meSettings, data: settings.toApi());
    final data = response.data is Map ? response.data['data'] : response.data;
    return CustomerSettingsModel.fromApi(
        data is Map ? Map<String, dynamic>.from(data) : settings.toApi());
  }

  Future<void> revokeCustomerSession(String sessionId) async {
    await _requireAccessToken();
    await _apiClient.delete(ApiEndpoints.meSession(sessionId));
  }
}
