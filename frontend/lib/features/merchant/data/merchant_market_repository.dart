import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/config/api_endpoints.dart';
import 'package:ghiyarak/core/network/api_client.dart';
import 'package:ghiyarak/features/marketplace/data/models/catalog_category.dart';
import 'package:ghiyarak/features/marketplace/data/models/product_model.dart';
import 'package:ghiyarak/features/merchant/data/models/merchant_listing_model.dart';
import 'package:ghiyarak/features/merchant/data/models/merchant_order_model.dart';

final merchantMarketRepositoryProvider =
    Provider<MerchantMarketRepository>((ref) {
  return MerchantMarketRepository(ref.watch(apiClientProvider));
});

class MerchantMarketRepository {
  final ApiClient _apiClient;

  MerchantMarketRepository(this._apiClient);

  Future<List<MerchantListingModel>> getMyListings() async {
    final response = await _apiClient.get(ApiEndpoints.merchantListings);
    final data = response.data is Map ? response.data['data'] : null;
    final items = data is List ? data : const <dynamic>[];
    return items
        .whereType<Map>()
        .map((item) =>
            MerchantListingModel.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<MerchantOrderModel>> getMerchantOrders() async {
    final response = await _apiClient.get(ApiEndpoints.merchantOrders);
    final data = response.data is Map ? response.data['data'] : null;
    final items = data is List ? data : const <dynamic>[];
    return items
        .whereType<Map>()
        .map((item) =>
            MerchantOrderModel.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<CatalogCategory>> getCategories() async {
    final response = await _apiClient.get(ApiEndpoints.catalogCategories);
    final data = response.data is Map ? response.data['data'] : null;
    final items = data is List ? data : const <dynamic>[];
    return items
        .whereType<Map>()
        .map(
            (item) => CatalogCategory.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<ProductModel>> getProducts({String? categoryId}) async {
    final response = await _apiClient.get(
      ApiEndpoints.catalogProducts,
      queryParameters: {
        if ((categoryId ?? '').isNotEmpty) 'categoryId': categoryId,
      },
    );
    final data = response.data is Map ? response.data['data'] : null;
    final items = data is Map ? data['items'] : null;
    final list = items is List ? items : const <dynamic>[];
    return list
        .whereType<Map>()
        .map((item) => ProductModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> createListing({
    required String productId,
    required String organizationId,
    String? title,
    String? description,
    bool supportsInstallation = false,
    double price = 0,
    int quantity = 0,
  }) async {
    await _apiClient.post(
      ApiEndpoints.merchantListings,
      data: {
        'productId': int.parse(productId),
        'organizationPublicId': organizationId,
        'title': title ?? 'Listing',
        'description': description,
        'unitPrice': price,
        'availableQuantity': quantity,
        'supportsPickup': true,
        'supportsDelivery': supportsInstallation,
      },
    );
  }

  Future<Map<String, dynamic>> getMerchantOrderDetail(String id) async {
    final response = await _apiClient.get(ApiEndpoints.merchantOrderDetail(id));
    final data = response.data is Map ? response.data['data'] : null;
    return Map<String, dynamic>.from((data ?? {}) as Map);
  }

  Future<void> providerAction({
    required String orderId,
    required String action,
    String? notes,
  }) async {
    final status = switch (action) {
      'confirm' => 'CONFIRMED',
      'processing' => 'PROCESSING',
      'ready' => 'READY_FOR_PICKUP',
      'delivery' => 'OUT_FOR_DELIVERY',
      'delivered' => 'DELIVERED',
      'cancel' => 'CANCELLED',
      _ => 'PROCESSING',
    };
    await _apiClient.patch(
      ApiEndpoints.merchantOrderStatus(orderId),
      data: {'status': status, 'note': notes},
    );
  }

  Future<void> updateListingStatus({
    required String listingId,
    required String status,
  }) async {
    await _apiClient.patch(
      ApiEndpoints.merchantListingStatus(listingId),
      data: {'status': status},
    );
  }
}
