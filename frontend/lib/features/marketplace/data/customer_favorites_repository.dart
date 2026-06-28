import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/config/api_endpoints.dart';
import 'package:ghiyarak/core/network/api_client.dart';
import 'package:ghiyarak/core/storage/local_storage_service.dart';
import 'package:ghiyarak/features/marketplace/data/models/customer_favorites_model.dart';
import 'package:ghiyarak/features/marketplace/data/models/listing_summary.dart';

final customerFavoritesRepositoryProvider =
    Provider<CustomerFavoritesRepository>((ref) {
  return CustomerFavoritesRepository(
    ref.watch(apiClientProvider),
    ref.watch(localStorageServiceProvider),
  );
});

class CustomerFavoritesRepository {
  final ApiClient _apiClient;
  final LocalStorageService _localStorage;

  CustomerFavoritesRepository(this._apiClient, this._localStorage);

  Future<CustomerFavoritesData> getFavorites({String type = 'all'}) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.meFavorites,
        queryParameters: {'type': type},
      );
      final data = Map<String, dynamic>.from(response.data['data'] as Map);
      return CustomerFavoritesData.fromMap(data);
    } catch (_) {
      final localItems = await _localStorage.getFavoriteListings();
      return CustomerFavoritesData.fromLocal(localItems);
    }
  }

  Future<bool> isListingFavorite(String listingId) async {
    try {
      final response =
          await _apiClient.get(ApiEndpoints.meFavoriteListingStatus(listingId));
      final data = Map<String, dynamic>.from(response.data['data'] as Map);
      return data['isFavorite'] == true || data['is_favorite'] == true;
    } catch (_) {
      return _localStorage.isFavoriteListing(listingId);
    }
  }

  Future<bool> toggleListingFavorite(ListingSummary listing) async {
    final isFavorite = await isListingFavorite(listing.id);
    if (isFavorite) {
      await removeListingFavorite(listing.id);
      return false;
    }
    await addListingFavorite(listing);
    return true;
  }

  Future<void> addListingFavorite(ListingSummary listing) async {
    await _localStorage.toggleFavoriteListing(_listingToLocalMap(listing));
    try {
      await _apiClient.post(
        ApiEndpoints.meFavoriteListing(listing.id),
        data: {
          'notifyPriceDrop': true,
          'notifyBackInStock': true,
          'targetPrice': listing.salePrice ?? listing.price,
        },
      );
    } catch (_) {}
  }

  Future<void> removeListingFavorite(String listingId) async {
    final isLocalFavorite = await _localStorage.isFavoriteListing(listingId);
    if (isLocalFavorite) {
      await _localStorage.toggleFavoriteListing({'id': listingId});
    }
    try {
      await _apiClient.delete(ApiEndpoints.meFavoriteListing(listingId));
    } catch (_) {}
  }

  Future<void> updateListingFavoritePreferences({
    required String listingId,
    bool? notifyPriceDrop,
    bool? notifyBackInStock,
    double? targetPrice,
  }) async {
    await _apiClient.put(
      ApiEndpoints.meFavoriteListingPreferences(listingId),
      data: {
        if (notifyPriceDrop != null) 'notifyPriceDrop': notifyPriceDrop,
        if (notifyBackInStock != null) 'notifyBackInStock': notifyBackInStock,
        if (targetPrice != null) 'targetPrice': targetPrice,
      },
    );
  }

  Future<bool> isProviderFollowed(String providerId) async {
    try {
      final response = await _apiClient
          .get(ApiEndpoints.meFollowedProviderStatus(providerId));
      final data = Map<String, dynamic>.from(response.data['data'] as Map);
      return data['isFollowed'] == true || data['is_followed'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> toggleProviderFollow({
    required String providerId,
    required String providerName,
    String? providerType,
  }) async {
    final isFollowed = await isProviderFollowed(providerId);
    if (isFollowed) {
      await _apiClient.delete(ApiEndpoints.meFollowedProvider(providerId));
      return false;
    }
    await _apiClient.post(
      ApiEndpoints.meFollowedProvider(providerId),
      data: {
        'providerName': providerName,
        'providerType': providerType,
        'notifyNewListings': true,
        'notifyPromotions': true,
      },
    );
    return true;
  }

  Map<String, dynamic> _listingToLocalMap(ListingSummary summary) {
    return {
      'id': summary.id,
      'title': summary.title,
      'providerName': summary.providerName,
      'providerId': summary.providerId,
      'price': summary.price,
      'salePrice': summary.salePrice,
      'currency': summary.currency,
      'cityName': summary.cityName,
      'imageUrl': summary.imageUrl,
      'providerType': summary.providerType,
      'providerTypeLabel': summary.providerTypeLabel,
      'serviceLabel': summary.serviceLabel,
      'availableQuantity': summary.availableQuantity,
      'warrantyDays': summary.warrantyDays,
    };
  }
}
