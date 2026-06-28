import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/config/api_endpoints.dart';
import 'package:ghiyarak/core/network/api_client.dart';
import 'package:ghiyarak/features/marketplace/data/models/catalog_category.dart';
import 'package:ghiyarak/features/marketplace/data/models/listing_detail.dart';
import 'package:ghiyarak/features/marketplace/data/models/listing_summary.dart';
import 'package:ghiyarak/features/marketplace/data/models/customer_home_model.dart';

final marketplaceRepositoryProvider = Provider<MarketplaceRepository>((ref) {
  return MarketplaceRepository(ref.watch(apiClientProvider));
});

final catalogCategoriesProvider = FutureProvider<List<CatalogCategory>>(
  (ref) => ref.watch(marketplaceRepositoryProvider).getCategories(),
);

class MarketplaceRepository {
  final ApiClient _apiClient;

  MarketplaceRepository(this._apiClient);

  Future<CustomerHomeData> getCustomerHome() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.customerHome);
      final raw = response.data is Map ? response.data['data'] : response.data;
      final data =
          raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
      final home = CustomerHomeData.fromMap(data);
      if (home.categories.isNotEmpty ||
          home.latestListings.isNotEmpty ||
          home.recommendedListings.isNotEmpty) {
        return home.withFallbacks();
      }
    } catch (_) {}
    final categories = await getCategories();
    final listings = await searchListings();
    return CustomerHomeData.fromMap(const <String, dynamic>{}).withFallbacks(
      fallbackCategories: categories,
      fallbackListings: listings,
    );
  }

  Future<List<ListingSummary>> compareOffers(
      {String? q, String? listingId, int limit = 16}) async {
    final response = await _apiClient.get(
      ApiEndpoints.compareListings,
      queryParameters: {
        if ((q ?? '').trim().isNotEmpty) 'q': q!.trim(),
        if ((listingId ?? '').trim().isNotEmpty) 'listingId': listingId!.trim(),
        'limit': limit,
      },
    );
    final raw = response.data is Map ? response.data['data'] : response.data;
    final items = raw is Map ? raw['items'] : raw;
    final list = items is List ? items : const <dynamic>[];
    return list
        .whereType<Map>()
        .map((item) => ListingSummary.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<CatalogCategory>> getCategories() async {
    final response = await _apiClient.get(ApiEndpoints.catalogCategories);
    final raw = response.data is Map ? response.data['data'] : null;
    final items = raw is List ? raw : const <dynamic>[];
    return items
        .whereType<Map>()
        .map(
            (item) => CatalogCategory.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<ListingSummary>> searchListings({
    String? q,
    String? categoryId,
    String? brandId,
    String? vehicleId,
    String? cityId,
    String? providerType,
    String? qualityType,
    String? condition,
    String? makeId,
    String? modelId,
    String? year,
    String? minPrice,
    String? maxPrice,
    bool? supportsInstallation,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.searchListings,
      queryParameters: {
        if ((q ?? '').isNotEmpty) 'q': q,
        if ((categoryId ?? '').isNotEmpty) 'categoryId': categoryId,
        if ((brandId ?? '').isNotEmpty) 'partBrandId': brandId,
        if ((cityId ?? '').isNotEmpty) 'cityId': cityId,
        if ((qualityType ?? '').isNotEmpty) 'qualityType': qualityType,
        if ((condition ?? '').isNotEmpty) 'condition': condition,
        if ((makeId ?? '').isNotEmpty) 'makeId': makeId,
        if ((modelId ?? '').isNotEmpty) 'modelId': modelId,
        if ((year ?? '').isNotEmpty) 'year': year,
        if ((minPrice ?? '').isNotEmpty) 'minPrice': minPrice,
        if ((maxPrice ?? '').isNotEmpty) 'maxPrice': maxPrice,
      },
    );
    final raw = response.data is Map ? response.data['data'] : null;
    final items = raw is Map ? raw['items'] : raw;
    final list = items is List ? items : const <dynamic>[];
    return list
        .whereType<Map>()
        .map((item) => ListingSummary.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList();
  }

  Future<List<ListingSummary>> compareListings(String productId) async {
    final response =
        await _apiClient.get(ApiEndpoints.listingCompare(productId));
    final raw = response.data is Map ? response.data['data'] : null;
    final list = raw is List ? raw : const <dynamic>[];
    return list
        .whereType<Map>()
        .map((item) => ListingSummary.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<ListingSummary>> getSimilarListings(String listingId) async {
    final response =
        await _apiClient.get(ApiEndpoints.listingSimilar(listingId));
    final raw = response.data is Map ? response.data['data'] : null;
    final list = raw is List ? raw : const <dynamic>[];
    return list
        .whereType<Map>()
        .map((item) => ListingSummary.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<ListingDetail> getListingDetail(
    String id, {
    String? vehicleId,
  }) async {
    final response = await _apiClient.get(ApiEndpoints.listingDetail(id));
    final raw = response.data is Map ? response.data['data'] : null;
    final data =
        raw is Map ? Map<String, dynamic>.from(raw) : const <String, dynamic>{};
    return ListingDetail.fromJson(data);
  }
}
