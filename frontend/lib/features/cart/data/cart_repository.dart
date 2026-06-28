import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/config/api_endpoints.dart';
import 'package:ghiyarak/core/network/api_client.dart';
import 'package:ghiyarak/core/storage/local_storage_service.dart';
import 'package:ghiyarak/core/storage/secure_storage_service.dart';
import 'package:ghiyarak/features/cart/data/models/cart_model.dart';
import 'package:ghiyarak/features/cart/data/models/checkout_preview_model.dart';
import 'package:ghiyarak/features/cart/data/models/customer_coupon_model.dart';
import 'package:ghiyarak/features/cart/data/models/customer_payment_model.dart';

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return CartRepository(
    ref.watch(apiClientProvider),
    ref.watch(secureStorageServiceProvider),
    ref.watch(localStorageServiceProvider),
  );
});

class CartAuthenticationRequiredException implements Exception {
  final String message;

  const CartAuthenticationRequiredException([
    this.message = 'يجب تسجيل الدخول لاستخدام السلة وإتمام الطلب.',
  ]);

  @override
  String toString() => message;
}

class CartRepository {
  final ApiClient _apiClient;
  final SecureStorageService _secureStorage;
  final LocalStorageService _localStorage;

  CartRepository(
    this._apiClient,
    this._secureStorage,
    this._localStorage,
  );

  Future<void> _ensureAuthenticatedCartAccess() async {
    final accessToken = await _secureStorage.getAccessToken();
    if ((accessToken ?? '').isNotEmpty) {
      return;
    }

    final isGuest = await _localStorage.isGuestMode();
    throw CartAuthenticationRequiredException(
      isGuest
          ? 'يجب تسجيل الدخول لإضافة المنتجات إلى السلة أو متابعة الطلب.'
          : 'يجب تسجيل الدخول لاستخدام السلة وإتمام الطلب.',
    );
  }

  Future<CartModel> getCart() async {
    await _ensureAuthenticatedCartAccess();
    final response = await _apiClient.get(ApiEndpoints.cart);
    final data =
        Map<String, dynamic>.from((response.data['data'] ?? {}) as Map);
    return CartModel.fromMap(data);
  }

  Future<void> addItem({required String listingId, int quantity = 1}) async {
    await _ensureAuthenticatedCartAccess();
    final parsedListingId = int.tryParse(listingId);
    await _apiClient.post(ApiEndpoints.cartItems, data: {
      'listingId': parsedListingId ?? listingId,
      'quantity': quantity,
    });
  }

  Future<void> updateItem(
      {required String itemId, required int quantity}) async {
    await _ensureAuthenticatedCartAccess();
    await _apiClient
        .patch(ApiEndpoints.cartItem(itemId), data: {'quantity': quantity});
  }

  Future<void> removeItem(String itemId) async {
    await _ensureAuthenticatedCartAccess();
    await _apiClient.delete(ApiEndpoints.cartItem(itemId));
  }

  Future<CheckoutPreviewModel> checkoutPreview(
      {String? couponCode,
      String fulfillmentMethod = 'pickup',
      String? addressId}) async {
    await _ensureAuthenticatedCartAccess();
    final response = await _apiClient.post(ApiEndpoints.checkoutPreview, data: {
      'fulfillmentMethod': fulfillmentMethod.toUpperCase(),
      if ((couponCode ?? '').isNotEmpty) 'couponCode': couponCode,
      if ((addressId ?? '').isNotEmpty) 'addressId': int.tryParse(addressId!),
    });
    final data =
        Map<String, dynamic>.from((response.data['data'] ?? {}) as Map);
    return CheckoutPreviewModel.fromMap(data);
  }

  Future<CustomerCouponResponse> getCustomerCoupons() async {
    await _ensureAuthenticatedCartAccess();
    final response = await _apiClient.get(ApiEndpoints.customerCoupons);
    final data = response.data is Map ? response.data['data'] : response.data;
    final map =
        data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
    return CustomerCouponResponse.fromMap(map);
  }

  Future<CouponValidationResult> validateCoupon(String code) async {
    await _ensureAuthenticatedCartAccess();
    final response = await _apiClient.post(
      ApiEndpoints.customerCouponValidate,
      data: {'code': code.trim().toUpperCase()},
    );
    final data = response.data is Map ? response.data['data'] : response.data;
    return CouponValidationResult.fromMap(data is Map
        ? Map<String, dynamic>.from(data)
        : {'code': code, 'valid': false});
  }

  Future<CustomerPaymentSummary> getPaymentSummary(String orderId) async {
    await _ensureAuthenticatedCartAccess();
    final response =
        await _apiClient.get(ApiEndpoints.customerOrderPayment(orderId));
    final data = response.data is Map ? response.data['data'] : response.data;
    return CustomerPaymentSummary.fromMap(
        data is Map ? Map<String, dynamic>.from(data) : {'orderId': orderId});
  }

  Future<CustomerPaymentSummary> submitPaymentProof({
    required String orderId,
    String? reference,
    String? proofUrl,
    String? note,
  }) async {
    await _ensureAuthenticatedCartAccess();
    final response = await _apiClient.post(
      ApiEndpoints.customerOrderPaymentProof(orderId),
      data: {
        if ((reference ?? '').trim().isNotEmpty) 'reference': reference!.trim(),
        if ((proofUrl ?? '').trim().isNotEmpty) 'proofUrl': proofUrl!.trim(),
        if ((note ?? '').trim().isNotEmpty) 'note': note!.trim(),
      },
    );
    final data = response.data is Map ? response.data['data'] : response.data;
    return CustomerPaymentSummary.fromMap(
        data is Map ? Map<String, dynamic>.from(data) : {'orderId': orderId});
  }

  Future<CustomerPaymentSummary> retryPayment({
    required String orderId,
    String? paymentMethod,
  }) async {
    await _ensureAuthenticatedCartAccess();
    final response = await _apiClient.post(
      ApiEndpoints.customerOrderPaymentRetry(orderId),
      data: {
        if ((paymentMethod ?? '').trim().isNotEmpty)
          'paymentMethod': paymentMethod
      },
    );
    final data = response.data is Map ? response.data['data'] : response.data;
    return CustomerPaymentSummary.fromMap(
        data is Map ? Map<String, dynamic>.from(data) : {'orderId': orderId});
  }

  Future<Map<String, dynamic>> placeOrder(
      {String? couponCode,
      String fulfillmentMethod = 'pickup',
      String? addressId}) async {
    await _ensureAuthenticatedCartAccess();
    final response = await _apiClient.post(ApiEndpoints.orders, data: {
      'fulfillmentMethod': fulfillmentMethod.toUpperCase(),
      if ((couponCode ?? '').isNotEmpty) 'couponCode': couponCode,
      if ((addressId ?? '').isNotEmpty) 'addressId': int.tryParse(addressId!),
    });
    final data = response.data['data'];
    return {'orders': data is List ? data : const []};
  }
}
