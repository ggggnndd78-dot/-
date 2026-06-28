import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/config/api_endpoints.dart';
import 'package:ghiyarak/core/network/api_client.dart';

final adminLocationsRepositoryProvider =
    Provider<AdminLocationsRepository>((ref) {
  return AdminLocationsRepository(ref.watch(apiClientProvider));
});

class AdminLocationsRepository {
  final ApiClient _api;
  AdminLocationsRepository(this._api);

  Future<List<dynamic>> cities() async {
    final response = await _api.get(ApiEndpoints.adminLocationCities);
    return List<dynamic>.from(response.data['data'] ?? []);
  }

  Future<List<dynamic>> deliveryZones() async {
    final response = await _api.get(ApiEndpoints.adminDeliveryZones);
    return List<dynamic>.from(response.data['data'] ?? []);
  }

  Future<void> saveCityDeliveryFee(String cityId, num deliveryFee) async {
    await _api.put(
      ApiEndpoints.adminLocationCityDeliveryFee(cityId),
      data: {
        'deliveryFee': deliveryFee,
        'currency': 'YER',
        'isDeliveryAvailable': true,
        'estimatedMinDays': 1,
        'estimatedMaxDays': 3,
      },
    );
  }
}
