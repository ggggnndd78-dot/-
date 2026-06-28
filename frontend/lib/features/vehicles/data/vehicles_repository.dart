import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/config/api_endpoints.dart';
import 'package:ghiyarak/core/network/api_client.dart';
import 'package:ghiyarak/features/auth/data/auth_repository.dart';
import 'package:ghiyarak/features/vehicles/data/models/vehicle_model.dart';
import 'package:ghiyarak/shared/models/lookup_item.dart';

final vehiclesRepositoryProvider = Provider<VehiclesRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final authRepo = ref.watch(authRepositoryProvider);
  return VehiclesRepository(apiClient, authRepo);
});

class VehiclesRepository {
  VehiclesRepository(this._apiClient, this._authRepository);

  final ApiClient _apiClient;
  final AuthRepository _authRepository;

  Future<List<LookupItem>> getMakes() async {
    final response = await _apiClient.get(ApiEndpoints.vehicleMakes);
    final List<dynamic> raw = response.data['data'] as List<dynamic>;
    return raw
        .map((e) => LookupItem(
            id: e['id'] as int,
            label: (e['nameAr'] ?? e['name_ar']).toString()))
        .toList();
  }

  Future<List<LookupItem>> getModels(int makeId) async {
    final response = await _apiClient.get(
      ApiEndpoints.vehicleModels,
      queryParameters: {'makeId': makeId},
    );
    final List<dynamic> raw = response.data['data'] as List<dynamic>;
    return raw
        .map((e) => LookupItem(
            id: e['id'] as int,
            label: (e['nameAr'] ?? e['name_ar']).toString()))
        .toList();
  }

  Future<List<LookupItem>> getYears(int modelId) async {
    final response = await _apiClient.get(
      ApiEndpoints.vehicleYears,
      queryParameters: {'modelId': modelId},
    );
    final List<dynamic> raw = response.data['data'] as List<dynamic>;
    return raw
        .map((e) => LookupItem(
            id: e['id'] as int, label: (e['year'] ?? e['id']).toString()))
        .toList();
  }

  Future<List<LookupItem>> getTrims(int modelId, {int? year}) async {
    final response = await _apiClient.get(
      ApiEndpoints.vehicleTrims,
      queryParameters: {'modelId': modelId, if (year != null) 'year': year},
    );
    final List<dynamic> raw = response.data['data'] as List<dynamic>;
    return raw
        .map((e) => LookupItem(
            id: e['id'] as int,
            label: (e['trimName'] ?? e['trim_name'] ?? 'فئة').toString()))
        .toList();
  }

  Future<List<VehicleModel>> getVehicles() async {
    if (!await _authRepository.isAuthenticated()) {
      return [];
    }
    final response = await _apiClient.get(ApiEndpoints.myVehicles);
    final List<dynamic> raw = response.data['data'] as List<dynamic>;
    return raw
        .map((e) => VehicleModel.fromApi(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> addVehicle({
    required int makeId,
    required int modelId,
    required int yearValue,
    int? variantId,
    bool isDefault = false,
  }) async {
    await _apiClient.post(
      ApiEndpoints.myVehicles,
      data: {
        'makeId': makeId,
        'modelId': modelId,
        'yearValue': yearValue,
        if (variantId != null) 'variantId': variantId,
        'isDefault': isDefault,
      },
    );
  }

  Future<void> setDefault(String id) async {
    await _apiClient.post('${ApiEndpoints.myVehicles}/$id/set-default');
  }

  Future<void> deleteVehicle(String id) async {
    await _apiClient.delete('${ApiEndpoints.myVehicles}/$id');
  }
}
