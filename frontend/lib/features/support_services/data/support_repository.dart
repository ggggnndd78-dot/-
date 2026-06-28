import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/config/api_endpoints.dart';
import 'package:ghiyarak/core/network/api_client.dart';
import 'package:ghiyarak/features/support_services/data/models/support_models.dart';

final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  return SupportRepository(ref.watch(apiClientProvider));
});

class SupportRepository {
  final ApiClient _apiClient;
  SupportRepository(this._apiClient);

  List<Map<String, dynamic>> _dataList(dynamic responseData) {
    final data = responseData is Map ? responseData['data'] : null;
    final list = data is List ? data : const <dynamic>[];
    return list
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<List<SupportTicketModel>> getMyTickets() async {
    final response = await _apiClient.get(ApiEndpoints.mySupportTickets);
    return _dataList(response.data).map(SupportTicketModel.fromMap).toList();
  }

  Future<List<SupportTicketModel>> getManageTickets() async {
    final response = await _apiClient.get(ApiEndpoints.manageSupportTickets);
    return _dataList(response.data).map(SupportTicketModel.fromMap).toList();
  }

  Future<Map<String, dynamic>> getTicketDetails(String id) async {
    final response = await _apiClient.get(ApiEndpoints.supportTicketDetail(id));
    final data = response.data is Map ? response.data['data'] : null;
    return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
  }

  Future<void> createTicket(
      {required String subject,
      required String description,
      String category = 'GENERAL',
      String priority = 'NORMAL'}) async {
    await _apiClient.post(ApiEndpoints.supportTickets, data: {
      'category': category,
      'priority': priority,
      'subject': subject,
      'description': description
    });
  }

  Future<void> addTicketMessage(String ticketId, String body) async {
    await _apiClient.post(ApiEndpoints.supportTicketMessages(ticketId),
        data: {'body': body});
  }

  Future<void> updateTicketStatus(String id, String status,
      {String? note}) async {
    await _apiClient.patch(ApiEndpoints.supportTicketStatus(id),
        data: {'status': status, if (note != null) 'note': note});
  }

  Future<List<ComplaintModel>> getMyComplaints() async {
    final response = await _apiClient.get(ApiEndpoints.myComplaints);
    return _dataList(response.data).map(ComplaintModel.fromMap).toList();
  }

  Future<List<ComplaintModel>> getManageComplaints() async {
    final response = await _apiClient.get(ApiEndpoints.manageComplaints);
    return _dataList(response.data).map(ComplaintModel.fromMap).toList();
  }

  Future<void> createComplaint(
      {required String subject,
      required String description,
      String severity = 'NORMAL'}) async {
    await _apiClient.post(ApiEndpoints.complaints, data: {
      'severity': severity,
      'subject': subject,
      'description': description
    });
  }

  Future<void> resolveComplaint(String id, String resolutionNote) async {
    await _apiClient.patch(ApiEndpoints.complaintStatus(id),
        data: {'status': 'RESOLVED', 'resolutionNote': resolutionNote});
  }

  Future<List<HelpCenterCategoryModel>> getHelpCategories() async {
    final response = await _apiClient.get(ApiEndpoints.helpCategories);
    return _dataList(response.data)
        .map(HelpCenterCategoryModel.fromMap)
        .toList();
  }

  Future<List<HelpArticleModel>> getHelpArticles({String? q}) async {
    final response = await _apiClient.get(ApiEndpoints.helpArticles,
        queryParameters: q == null || q.isEmpty ? null : {'q': q});
    return _dataList(response.data).map(HelpArticleModel.fromMap).toList();
  }

  Future<List<FaqModel>> getFaqs({String? q}) async {
    final response = await _apiClient.get(ApiEndpoints.faqs,
        queryParameters: q == null || q.isEmpty ? null : {'q': q});
    return _dataList(response.data).map(FaqModel.fromMap).toList();
  }

  Future<List<WhatsappSupportLinkModel>> getWhatsappLinks() async {
    final response = await _apiClient.get(ApiEndpoints.whatsappSupportLinks);
    return _dataList(response.data)
        .map(WhatsappSupportLinkModel.fromMap)
        .toList();
  }

  Future<Map<String, List<ReviewModel>>> getMyReviews() async {
    final response = await _apiClient.get(ApiEndpoints.myReviews);
    final data = response.data is Map ? response.data['data'] : null;
    if (data is! Map) {
      return {'products': [], 'merchants': [], 'workshops': [], 'services': []};
    }
    List<ReviewModel> parse(String key) {
      final list = data[key] is List ? data[key] as List : const <dynamic>[];
      return list
          .whereType<Map>()
          .map((item) => ReviewModel.fromMap(Map<String, dynamic>.from(item),
              targetType: key.toUpperCase()))
          .toList();
    }

    return {
      'products': parse('products'),
      'merchants': parse('merchants'),
      'workshops': parse('workshops'),
      'services': parse('services')
    };
  }

  Future<Map<String, List<ReviewModel>>> getAdminReviews() async {
    final response = await _apiClient.get(ApiEndpoints.adminReviews);
    final data = response.data is Map ? response.data['data'] : null;
    if (data is! Map) {
      return {'product': [], 'merchant': [], 'workshop': [], 'service': []};
    }
    List<ReviewModel> parse(String key) {
      final list = data[key] is List ? data[key] as List : const <dynamic>[];
      return list
          .whereType<Map>()
          .map((item) => ReviewModel.fromMap(Map<String, dynamic>.from(item),
              targetType: key.toUpperCase()))
          .toList();
    }

    return {
      'product': parse('product'),
      'merchant': parse('merchant'),
      'workshop': parse('workshop'),
      'service': parse('service')
    };
  }

  Future<void> createProductReview(
      {required int productId,
      required int orderId,
      required int rating,
      required String title,
      required String body}) async {
    await _apiClient.post(ApiEndpoints.productReviews, data: {
      'productId': productId,
      'orderId': orderId,
      'rating': rating,
      'title': title,
      'body': body
    });
  }

  Future<void> createMerchantReview(
      {required int organizationId,
      required int orderId,
      required int rating,
      required String title,
      required String body}) async {
    await _apiClient.post(ApiEndpoints.merchantReviews, data: {
      'organizationId': organizationId,
      'orderId': orderId,
      'rating': rating,
      'title': title,
      'body': body
    });
  }

  Future<void> createWorkshopReview(
      {required int organizationId,
      required int serviceOrderId,
      required int rating,
      required String title,
      required String body}) async {
    await _apiClient.post(ApiEndpoints.workshopReviews, data: {
      'organizationId': organizationId,
      'serviceOrderId': serviceOrderId,
      'rating': rating,
      'title': title,
      'body': body
    });
  }

  Future<void> createServiceReview(
      {required int serviceOrderId,
      required int rating,
      required String title,
      required String body}) async {
    await _apiClient.post(ApiEndpoints.serviceReviews, data: {
      'serviceOrderId': serviceOrderId,
      'rating': rating,
      'title': title,
      'body': body
    });
  }

  Future<void> replyToReview(
      {required String targetType,
      required int reviewId,
      required int organizationId,
      required String body}) async {
    await _apiClient.post(ApiEndpoints.reviewReply, data: {
      'targetType': targetType,
      'reviewId': reviewId,
      'organizationId': organizationId,
      'body': body
    });
  }

  Future<void> moderateReview(
      {required String targetType,
      required int reviewId,
      required String action,
      String? reason}) async {
    await _apiClient.patch(ApiEndpoints.reviewModeration, data: {
      'targetType': targetType,
      'reviewId': reviewId,
      'action': action,
      if (reason != null) 'reason': reason
    });
  }
}
