import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/config/api_endpoints.dart';
import 'package:ghiyarak/core/network/api_client.dart';
import 'package:ghiyarak/features/locations/data/address_model.dart';

final addressRepositoryProvider = Provider<AddressRepository>((ref) {
  return AddressRepository(ref.watch(apiClientProvider));
});

class AddressRepository {
  final ApiClient _api;
  AddressRepository(this._api);

  Future<List<AddressModel>> myAddresses() async {
    final response = await _api.get(ApiEndpoints.myAddresses);
    final data = List<dynamic>.from(response.data['data'] ?? []);
    return data
        .map((item) =>
            AddressModel.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<void> createAddress(Map<String, dynamic> data) async {
    await _api.post(ApiEndpoints.addresses, data: data);
  }

  Future<void> updateAddress(String id, Map<String, dynamic> data) async {
    await _api.patch(ApiEndpoints.addressDetail(id), data: data);
  }

  Future<void> deleteAddress(String id) async {
    await _api.delete(ApiEndpoints.addressDetail(id));
  }
}
