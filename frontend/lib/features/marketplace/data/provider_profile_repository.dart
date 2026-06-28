import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/config/api_endpoints.dart';
import 'package:ghiyarak/core/network/api_client.dart';
import 'package:ghiyarak/features/marketplace/data/models/marketplace_provider_profile.dart';

final providerProfileRepositoryProvider =
    Provider<ProviderProfileRepository>((ref) {
  return ProviderProfileRepository(ref.watch(apiClientProvider));
});

class ProviderProfileRepository {
  final ApiClient _apiClient;

  ProviderProfileRepository(this._apiClient);

  Future<MarketplaceProviderProfile> getProviderProfile({
    required String providerId,
    MarketplaceProviderProfile? fallback,
  }) async {
    final organization =
        await _getMap(ApiEndpoints.organizationDetail(providerId));
    final type = (organization['organizationType'] ??
            organization['organization_type'] ??
            fallback?.type ??
            '')
        .toString()
        .toUpperCase();

    final branches =
        await _getList(ApiEndpoints.organizationBranches(providerId));
    final hours =
        await _getList(ApiEndpoints.organizationBusinessHours(providerId));
    final merchantProfile = type == 'MERCHANT'
        ? await _tryGetMap(ApiEndpoints.organizationMerchantProfile(providerId))
        : null;
    final workshopProfile = type == 'WORKSHOP'
        ? await _tryGetMap(ApiEndpoints.organizationWorkshopProfile(providerId))
        : null;

    return MarketplaceProviderProfile.fromMaps(
      id: providerId,
      organization: organization,
      branches: branches,
      businessHours: hours,
      merchantProfile: merchantProfile,
      workshopProfile: workshopProfile,
      fallback: fallback,
    );
  }

  Future<Map<String, dynamic>> _getMap(String path) async {
    final response = await _apiClient.get(path);
    final data = response.data['data'];
    return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
  }

  Future<Map<String, dynamic>?> _tryGetMap(String path) async {
    try {
      return await _getMap(path);
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _getList(String path) async {
    try {
      final response = await _apiClient.get(path);
      final data = response.data['data'];
      if (data is Map && data['items'] is List) {
        return (data['items'] as List)
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
      if (data is List) {
        return data
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    } catch (_) {
      return const [];
    }
    return const [];
  }
}
