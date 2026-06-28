import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/config/api_endpoints.dart';
import 'package:ghiyarak/core/network/api_client.dart';

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository(ref.watch(apiClientProvider));
});

class CustomerRepository {
  final ApiClient _apiClient;

  CustomerRepository(this._apiClient);

  Future<CustomerRewardsSummary> rewardsSummary() async {
    final loyalty = await _apiClient.get(ApiEndpoints.loyaltySummary);
    final wallet = await _apiClient.get(ApiEndpoints.wallet);
    final referral = await _apiClient.get(ApiEndpoints.referralCode);
    return CustomerRewardsSummary.fromMaps(
      _map(loyalty.data['data']),
      _map(wallet.data['data']),
      _map(referral.data['data']),
    );
  }

  Future<CustomerNotificationsResult> notifications({
    String type = 'all',
    bool unreadOnly = false,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.notifications,
      queryParameters: {
        if (type != 'all') 'type': type,
        if (unreadOnly) 'unreadOnly': 'true',
      },
    );
    final data = _map(response.data['data']);
    final rawItems = (data['items'] as List<dynamic>?) ??
        (response.data['data'] is List<dynamic>
            ? response.data['data'] as List<dynamic>
            : const <dynamic>[]);
    final items = rawItems
        .map((item) => CustomerNotification.fromMap(_map(item)))
        .toList();
    return CustomerNotificationsResult(
      items: items,
      unreadCount: _int(data['unread_count'] ?? data['unreadCount']),
      totalCount: _int(data['total_count'] ?? data['totalCount']),
      typeCounts: _stringIntMap(data['type_counts'] ?? data['typeCounts']),
    );
  }

  Future<void> markNotificationRead(String id) async {
    await _apiClient.patch(ApiEndpoints.notificationRead(id), data: {});
  }

  Future<void> markAllNotificationsRead() async {
    await _apiClient.patch(ApiEndpoints.notificationReadAll, data: {});
  }

  Future<void> deleteNotification(String id) async {
    await _apiClient.delete(ApiEndpoints.notificationDelete(id));
  }

  Future<void> registerNotificationDevice({
    required String token,
    String platform = 'flutter',
    String? deviceName,
  }) async {
    await _apiClient.post(ApiEndpoints.notificationRegisterDevice, data: {
      'token': token,
      'platform': platform,
      if (deviceName != null && deviceName.isNotEmpty) 'deviceName': deviceName,
    });
  }

  Future<List<LoyaltyTransaction>> loyaltyTransactions() async {
    final response = await _apiClient.get(ApiEndpoints.loyaltyTransactions);
    final items = response.data['data'] as List<dynamic>? ?? const [];
    return items.map((item) => LoyaltyTransaction.fromMap(_map(item))).toList();
  }

  Future<List<WalletTransaction>> walletTransactions() async {
    final response = await _apiClient.get(ApiEndpoints.walletTransactions);
    final items = response.data['data'] as List<dynamic>? ?? const [];
    return items.map((item) => WalletTransaction.fromMap(_map(item))).toList();
  }

  Future<CustomerRewardsSummary> redeemPoints(int points) async {
    await _apiClient.post(ApiEndpoints.loyaltyRedeem, data: {'points': points});
    return rewardsSummary();
  }

  Future<CustomerRewardsSummary> useReferralCode(String code) async {
    await _apiClient
        .post(ApiEndpoints.referralUse, data: {'code': code.trim()});
    return rewardsSummary();
  }

  Future<List<HelpFaq>> faqs() async {
    final response = await _apiClient.get(ApiEndpoints.helpFaqs);
    final items = response.data['data'] as List<dynamic>? ?? const [];
    return items.map((item) => HelpFaq.fromMap(_map(item))).toList();
  }

  Future<List<SupportTicket>> myTickets() async {
    final response = await _apiClient.get(ApiEndpoints.mySupportTickets);
    final items = response.data['data'] as List<dynamic>? ?? const [];
    return items.map((item) => SupportTicket.fromMap(_map(item))).toList();
  }

  Future<SupportTicket> createTicket({
    required String subject,
    required String message,
    String? category,
    String priority = 'NORMAL',
    int? orderId,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.supportTickets,
      data: {
        'subject': subject,
        'message': message,
        'priority': priority,
        if (category != null && category.isNotEmpty) 'category': category,
        if (orderId != null) 'orderId': orderId,
      },
    );
    return SupportTicket.fromMap(_map(response.data['data']));
  }

  Map<String, dynamic> _map(Object? value) {
    return value is Map ? Map<String, dynamic>.from(value) : {};
  }
}

class CustomerNotificationsResult {
  final List<CustomerNotification> items;
  final int unreadCount;
  final int totalCount;
  final Map<String, int> typeCounts;

  const CustomerNotificationsResult({
    required this.items,
    required this.unreadCount,
    required this.totalCount,
    required this.typeCounts,
  });
}

class CustomerRewardsSummary {
  final int pointsBalance;
  final int earnedPoints;
  final int redeemedPoints;
  final double pointValueYer;
  final double walletBalance;
  final String walletStatus;
  final String referralCode;

  const CustomerRewardsSummary({
    required this.pointsBalance,
    required this.earnedPoints,
    required this.redeemedPoints,
    required this.pointValueYer,
    required this.walletBalance,
    required this.walletStatus,
    required this.referralCode,
  });

  double get redeemableAmount => pointsBalance * pointValueYer;

  factory CustomerRewardsSummary.fromMaps(
    Map<String, dynamic> loyalty,
    Map<String, dynamic> wallet,
    Map<String, dynamic> referral,
  ) {
    return CustomerRewardsSummary(
      pointsBalance: _int(loyalty['balance']),
      earnedPoints: _int(loyalty['earned']),
      redeemedPoints: _int(loyalty['redeemed']),
      pointValueYer: _double(loyalty['point_value_yer']),
      walletBalance: _double(wallet['balance']),
      walletStatus: wallet['status']?.toString() ?? 'ACTIVE',
      referralCode: referral['code']?.toString() ?? '',
    );
  }
}

class CustomerNotification {
  final String id;
  final String title;
  final String body;
  final String typeCode;
  final bool isRead;
  final String createdAt;
  final String? route;
  final String? orderId;
  final String? listingId;
  final String? chatId;
  final String? disputeId;
  final String? returnId;
  final String? paymentId;
  final String? shipmentId;
  final Map<String, dynamic> data;

  const CustomerNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.typeCode,
    required this.isRead,
    required this.createdAt,
    required this.data,
    this.route,
    this.orderId,
    this.listingId,
    this.chatId,
    this.disputeId,
    this.returnId,
    this.paymentId,
    this.shipmentId,
  });

  bool get isActionable =>
      route != null ||
      orderId != null ||
      listingId != null ||
      chatId != null ||
      disputeId != null;

  factory CustomerNotification.fromMap(Map<String, dynamic> map) {
    final rawData = map['data'];
    final data = rawData is Map
        ? Map<String, dynamic>.from(rawData)
        : <String, dynamic>{};
    return CustomerNotification(
      id: map['publicId']?.toString() ??
          map['public_id']?.toString() ??
          map['id']?.toString() ??
          '',
      title: map['title']?.toString() ?? '',
      body: map['body']?.toString() ?? '',
      typeCode:
          (map['type_code'] ?? map['typeCode'] ?? map['type'])?.toString() ??
              '',
      isRead: (map['read_at'] ?? map['readAt']) != null &&
          (map['read_at'] ?? map['readAt']).toString().isNotEmpty,
      createdAt: (map['created_at'] ?? map['createdAt'])?.toString() ?? '',
      data: data,
      route: (data['route'] ?? map['route'])?.toString(),
      orderId: (data['orderId'] ??
              data['order_id'] ??
              map['orderId'] ??
              map['order_id'])
          ?.toString(),
      listingId: (data['listingId'] ??
              data['listing_id'] ??
              map['listingId'] ??
              map['listing_id'])
          ?.toString(),
      chatId: (data['chatId'] ??
              data['chat_id'] ??
              data['ticketId'] ??
              data['ticket_id'])
          ?.toString(),
      disputeId: (data['disputeId'] ??
              data['dispute_id'] ??
              data['complaintId'] ??
              data['complaint_id'])
          ?.toString(),
      returnId: (data['returnId'] ??
              data['return_id'] ??
              data['refundId'] ??
              data['refund_id'])
          ?.toString(),
      paymentId: (data['paymentId'] ?? data['payment_id'])?.toString(),
      shipmentId: (data['shipmentId'] ?? data['shipment_id'])?.toString(),
    );
  }
}

class LoyaltyTransaction {
  final int points;
  final String type;
  final String referenceType;
  final String createdAt;

  const LoyaltyTransaction({
    required this.points,
    required this.type,
    required this.referenceType,
    required this.createdAt,
  });

  factory LoyaltyTransaction.fromMap(Map<String, dynamic> map) {
    return LoyaltyTransaction(
      points: _int(map['points']),
      type: map['transaction_type']?.toString() ?? '',
      referenceType: map['reference_type']?.toString() ?? '',
      createdAt: map['created_at']?.toString() ?? '',
    );
  }
}

class WalletTransaction {
  final double amount;
  final double balanceAfter;
  final String type;
  final String note;
  final String createdAt;

  const WalletTransaction({
    required this.amount,
    required this.balanceAfter,
    required this.type,
    required this.note,
    required this.createdAt,
  });

  factory WalletTransaction.fromMap(Map<String, dynamic> map) {
    return WalletTransaction(
      amount: _double(map['amount']),
      balanceAfter: _double(map['balance_after']),
      type: map['transaction_type']?.toString() ?? '',
      note: map['note']?.toString() ?? '',
      createdAt: map['created_at']?.toString() ?? '',
    );
  }
}

class HelpFaq {
  final String question;
  final String answer;

  const HelpFaq({required this.question, required this.answer});

  factory HelpFaq.fromMap(Map<String, dynamic> map) {
    return HelpFaq(
      question: map['question_ar']?.toString() ?? '',
      answer: map['answer_ar']?.toString() ?? '',
    );
  }
}

class SupportTicket {
  final String id;
  final String subject;
  final String status;
  final String priority;
  final String createdAt;

  const SupportTicket({
    required this.id,
    required this.subject,
    required this.status,
    required this.priority,
    required this.createdAt,
  });

  factory SupportTicket.fromMap(Map<String, dynamic> map) {
    return SupportTicket(
      id: map['publicId']?.toString() ?? '',
      subject: map['subject']?.toString() ?? '',
      status: map['status']?.toString() ?? '',
      priority: map['priority']?.toString() ?? '',
      createdAt: map['created_at']?.toString() ?? '',
    );
  }
}

Map<String, int> _stringIntMap(Object? value) {
  if (value is! Map) return const {};
  return value.map((key, v) => MapEntry(key.toString(), _int(v)));
}

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _double(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
