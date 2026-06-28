import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/config/api_endpoints.dart';
import 'package:ghiyarak/core/network/api_client.dart';
import 'package:ghiyarak/features/orders/data/models/customer_dispute_model.dart';
import 'package:ghiyarak/features/orders/data/models/customer_return_model.dart';
import 'package:ghiyarak/features/orders/data/models/order_summary_model.dart';

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  return OrdersRepository(ref.watch(apiClientProvider));
});

class OrdersRepository {
  final ApiClient _apiClient;
  OrdersRepository(this._apiClient);

  Future<List<OrderSummaryModel>> getMyOrders() async {
    final response = await _apiClient.get(ApiEndpoints.myOrders);
    final raw = response.data is Map ? response.data['data'] : response.data;
    final data = raw is Map && raw['items'] is List
        ? raw['items'] as List
        : raw is List
            ? raw
            : const <dynamic>[];
    return data
        .whereType<Map>()
        .map((e) => OrderSummaryModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Map<String, dynamic>> getOrderDetail(String id) async {
    final response = await _apiClient.get(ApiEndpoints.myOrderDetail(id));
    final data = response.data is Map ? response.data['data'] : response.data;
    return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> getOrderInvoice(String id) async {
    final response =
        await _apiClient.get(ApiEndpoints.customerOrderInvoice(id));
    final data = response.data is Map ? response.data['data'] : response.data;
    return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> getCancellationOptions(String id) async {
    final response =
        await _apiClient.get(ApiEndpoints.customerOrderCancellationOptions(id));
    final data = response.data is Map ? response.data['data'] : response.data;
    return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
  }

  Future<void> cancelOrder(
    String id, {
    String? notes,
    String? reason,
    String? reasonCode,
    String? note,
    bool acknowledged = false,
  }) async {
    await _apiClient.patch(
      ApiEndpoints.customerOrderCancel(id),
      data: {
        if ((reason ?? notes ?? '').trim().isNotEmpty)
          'reason': (reason ?? notes)!.trim(),
        if ((reasonCode ?? '').trim().isNotEmpty)
          'reasonCode': reasonCode!.trim(),
        if ((note ?? '').trim().isNotEmpty) 'note': note!.trim(),
        'acknowledged': acknowledged,
      },
    );
  }

  Future<CustomerReturnOptionsModel> getReturnOptions(String orderId) async {
    final response =
        await _apiClient.get(ApiEndpoints.orderReturnOptions(orderId));
    final data = response.data is Map ? response.data['data'] : response.data;
    return CustomerReturnOptionsModel.fromMap(
        data is Map ? Map<String, dynamic>.from(data) : {'orderId': orderId});
  }

  Future<CustomerReturnRequestModel> requestReturn(
    String orderId, {
    required String requestType,
    required String reason,
    required String refundMethod,
    required String returnMethod,
    required String conditionCode,
    String? details,
    String? contactNote,
    List<String> attachments = const [],
    List<Map<String, dynamic>> items = const [],
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.orderReturnRequest(orderId),
      data: {
        'requestType': requestType,
        'reason': reason,
        'refundMethod': refundMethod,
        'returnMethod': returnMethod,
        'conditionCode': conditionCode,
        if ((details ?? '').trim().isNotEmpty) 'details': details!.trim(),
        if ((contactNote ?? '').trim().isNotEmpty)
          'contactNote': contactNote!.trim(),
        'attachments': attachments,
        'items': items,
      },
    );
    final data = response.data is Map ? response.data['data'] : response.data;
    return CustomerReturnRequestModel.fromMap(
        data is Map ? Map<String, dynamic>.from(data) : {'orderId': orderId});
  }

  Future<CustomerDisputeOptionsModel> getDisputeOptions(String orderId) async {
    final response =
        await _apiClient.get(ApiEndpoints.customerOrderDisputeOptions(orderId));
    final data = response.data is Map ? response.data['data'] : response.data;
    return CustomerDisputeOptionsModel.fromMap(
        data is Map ? Map<String, dynamic>.from(data) : {'orderId': orderId});
  }

  Future<CustomerDisputeModel> requestDispute(
    String orderId, {
    String? reason,
    String? reasonCode,
    String? subject,
    required String description,
    String? priority,
    List<String> attachments = const [],
  }) async {
    final code = (reasonCode ?? reason ?? 'OTHER').trim();
    final response = await _apiClient.post(
      ApiEndpoints.customerOrderDisputeRequest(orderId),
      data: {
        'reasonCode': code,
        if ((subject ?? '').trim().isNotEmpty) 'subject': subject!.trim(),
        'description': description.trim(),
        if ((priority ?? '').trim().isNotEmpty) 'priority': priority!.trim(),
        'attachments': attachments,
      },
    );
    final data = response.data is Map ? response.data['data'] : response.data;
    return CustomerDisputeModel.fromMap(data is Map
        ? Map<String, dynamic>.from(data)
        : {'orderId': orderId, 'reasonCode': code});
  }

  Future<List<CustomerDisputeModel>> getMyDisputes() async {
    final response = await _apiClient.get(ApiEndpoints.customerDisputes);
    final raw = response.data is Map ? response.data['data'] : response.data;
    final items = raw is Map && raw['items'] is List
        ? raw['items'] as List
        : raw is List
            ? raw
            : const <dynamic>[];
    return items
        .whereType<Map>()
        .map((item) =>
            CustomerDisputeModel.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<CustomerDisputeModel> getDisputeDetail(String disputeId) async {
    final response =
        await _apiClient.get(ApiEndpoints.customerDisputeDetail(disputeId));
    final data = response.data is Map ? response.data['data'] : response.data;
    return CustomerDisputeModel.fromMap(
        data is Map ? Map<String, dynamic>.from(data) : {'id': disputeId});
  }

  Future<CustomerDisputeModel> addDisputeMessage(
    String disputeId, {
    required String message,
    List<String> attachments = const [],
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.customerDisputeMessages(disputeId),
      data: {'message': message.trim(), 'attachments': attachments},
    );
    final data = response.data is Map ? response.data['data'] : response.data;
    return CustomerDisputeModel.fromMap(
        data is Map ? Map<String, dynamic>.from(data) : {'id': disputeId});
  }

  Future<void> closeDispute(String disputeId, {String? note}) async {
    await _apiClient.patch(ApiEndpoints.customerDisputeClose(disputeId),
        data: {if ((note ?? '').trim().isNotEmpty) 'note': note!.trim()});
  }

  Future<void> reopenDispute(String disputeId, {String? reason}) async {
    await _apiClient.patch(ApiEndpoints.customerDisputeReopen(disputeId),
        data: {if ((reason ?? '').trim().isNotEmpty) 'reason': reason!.trim()});
  }

  Future<Map<String, dynamic>> getReviewOptions(String orderId) async {
    final response =
        await _apiClient.get(ApiEndpoints.customerOrderReviewOptions(orderId));
    final data = response.data is Map ? response.data['data'] : response.data;
    return data is Map ? Map<String, dynamic>.from(data) : {'orderId': orderId};
  }

  Future<void> submitOrderReview(
    String orderId, {
    required int merchantRating,
    required int productRating,
    required int deliveryRating,
    required int serviceRating,
    String? comment,
    List<String>? attachments,
    List<Map<String, dynamic>> productReviews = const [],
  }) async {
    await _apiClient.post(
      ApiEndpoints.customerOrderReviews(orderId),
      data: {
        'merchantRating': merchantRating,
        'productRating': productRating,
        'deliveryRating': deliveryRating,
        'serviceRating': serviceRating,
        if ((comment ?? '').trim().isNotEmpty) 'comment': comment!.trim(),
        if (attachments != null) 'attachments': attachments,
        'productReviews': productReviews,
      },
    );
  }
}
