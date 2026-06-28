import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/config/api_endpoints.dart';
import 'package:ghiyarak/core/network/api_client.dart';
import 'package:ghiyarak/core/storage/local_storage_service.dart';
import 'package:ghiyarak/core/storage/secure_storage_service.dart';
import 'package:ghiyarak/shared/models/location_item.dart';

final locationsRepositoryProvider = Provider<LocationsRepository>((ref) {
  return LocationsRepository(
    ref.watch(apiClientProvider),
    ref.watch(localStorageServiceProvider),
    ref.watch(secureStorageServiceProvider),
  );
});

class LocationsRepository {
  final ApiClient _apiClient;
  final LocalStorageService _localStorage;
  final SecureStorageService _secureStorage;

  LocationsRepository(this._apiClient, this._localStorage, this._secureStorage);

  Future<List<LocationItem>> fetchStates() async {
    final response = await _apiClient.get(ApiEndpoints.states);
    final data = (response.data['data'] as List<dynamic>? ?? []);
    return data
        .map((e) => LocationItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<LocationItem>> fetchCitiesByState(int stateId) async {
    final response = await _apiClient
        .get(ApiEndpoints.cities, queryParameters: {'stateId': stateId});
    final data = (response.data['data'] as List<dynamic>? ?? []);
    return data
        .map((e) => LocationItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<LocationItem>> fetchCities() async {
    final response = await _apiClient.get(ApiEndpoints.cities);
    final data = (response.data['data'] as List<dynamic>? ?? []);
    return data
        .map((e) => LocationItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<dynamic>> fetchDeliveryFees({int? cityId}) async {
    final response = await _apiClient.get(
      ApiEndpoints.deliveryFees,
      queryParameters: {if (cityId != null) 'cityId': cityId},
    );
    return List<dynamic>.from(response.data['data'] ?? []);
  }

  Future<List<LocationItem>> fetchDistricts(int cityId) async {
    final response = await _apiClient
        .get(ApiEndpoints.districts, queryParameters: {'cityId': cityId});
    final data = (response.data['data'] as List<dynamic>? ?? []);
    return data
        .map((e) => LocationItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<LocationItem>> fetchAreas(int districtId) async {
    final response = await _apiClient
        .get(ApiEndpoints.areas, queryParameters: {'districtId': districtId});
    final data = (response.data['data'] as List<dynamic>? ?? []);
    return data
        .map((e) => LocationItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveLocation({
    required int cityId,
    required String cityName,
    int? districtId,
    String? districtName,
  }) async {
    final accessToken = await _secureStorage.getAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      await _apiClient.patch(
        ApiEndpoints.meLocation,
        data: {
          'cityId': cityId,
          'districtId': districtId,
        },
      );
    } else {
      final guestToken = await _localStorage.getGuestToken();
      if (guestToken.isNotEmpty) {
        await _apiClient.patch(
          ApiEndpoints.guestSessionLocation,
          data: {
            'guestToken': guestToken,
            'cityId': cityId,
            'districtId': districtId,
          },
        );
      }
    }

    await _localStorage.setSelectedCity(cityName);
    await _localStorage.setSelectedDistrict(districtName ?? '');
  }
}
