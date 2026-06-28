import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/config/api_endpoints.dart';
import 'package:ghiyarak/core/network/api_client.dart';

final customerChatRepositoryProvider = Provider<CustomerChatRepository>((ref) {
  return CustomerChatRepository(ref.watch(apiClientProvider));
});

class CustomerChatRepository {
  final ApiClient _apiClient;
  CustomerChatRepository(this._apiClient);

  Future<CustomerChatInbox> conversations({
    String? query,
    String status = 'ALL',
    bool unreadOnly = false,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.customerChats,
      queryParameters: {
        if ((query ?? '').trim().isNotEmpty) 'q': query!.trim(),
        if (status != 'ALL') 'status': status,
        if (unreadOnly) 'unreadOnly': true,
      },
    );
    final data =
        Map<String, dynamic>.from((response.data['data'] ?? {}) as Map);
    return CustomerChatInbox.fromMap(data);
  }

  Future<CustomerConversation> openConversation({
    String? conversationId,
    String? listingId,
    String? listingTitle,
    String? providerName,
    String? providerTypeLabel,
    String? serviceLabel,
    String? orderId,
    String? organizationId,
  }) async {
    if ((conversationId ?? '').trim().isNotEmpty) {
      return getConversation(conversationId!.trim());
    }
    final response = await _apiClient.post(
      ApiEndpoints.customerChatsOpen,
      data: {
        if ((listingId ?? '').trim().isNotEmpty) 'listingId': listingId!.trim(),
        if ((listingTitle ?? '').trim().isNotEmpty)
          'listingTitle': listingTitle!.trim(),
        if ((providerName ?? '').trim().isNotEmpty)
          'providerName': providerName!.trim(),
        if ((providerTypeLabel ?? '').trim().isNotEmpty)
          'providerTypeLabel': providerTypeLabel!.trim(),
        if ((serviceLabel ?? '').trim().isNotEmpty)
          'serviceLabel': serviceLabel!.trim(),
        if ((orderId ?? '').trim().isNotEmpty) 'orderId': orderId!.trim(),
        if ((organizationId ?? '').trim().isNotEmpty)
          'organizationId': organizationId!.trim(),
      },
    );
    final data = response.data['data'];
    return CustomerConversation.fromMap(Map<String, dynamic>.from(data as Map));
  }

  Future<CustomerConversation> getConversation(String id) async {
    final response = await _apiClient.get(ApiEndpoints.customerChat(id));
    final data = response.data['data'];
    return CustomerConversation.fromMap(Map<String, dynamic>.from(data as Map));
  }

  Future<CustomerConversation> addMessage({
    required String conversationId,
    required String text,
    List<String> attachments = const [],
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.customerChatMessages(conversationId),
      data: {
        'message': text.trim().isEmpty ? 'مرفق' : text.trim(),
        if (attachments.isNotEmpty) 'attachments': attachments,
      },
    );
    final data = response.data['data'];
    return CustomerConversation.fromMap(Map<String, dynamic>.from(data as Map));
  }

  Future<void> markRead(String conversationId) async {
    await _apiClient.patch(ApiEndpoints.customerChatRead(conversationId));
  }

  Future<CustomerConversation> updateStatus(
      String conversationId, String status) async {
    final response = await _apiClient.patch(
      ApiEndpoints.customerChatStatus(conversationId),
      data: {'status': status},
    );
    return CustomerConversation.fromMap(
      Map<String, dynamic>.from((response.data['data'] ?? {}) as Map),
    );
  }
}

class CustomerChatInbox {
  final List<CustomerConversation> conversations;
  final int total;
  final int openCount;
  final int unreadCount;
  final int waitingReplyCount;
  final int resolvedCount;

  const CustomerChatInbox({
    required this.conversations,
    required this.total,
    required this.openCount,
    required this.unreadCount,
    required this.waitingReplyCount,
    required this.resolvedCount,
  });

  factory CustomerChatInbox.fromMap(Map<String, dynamic> map) {
    final list = map['conversations'] as List<dynamic>? ?? const [];
    return CustomerChatInbox(
      conversations: list
          .whereType<Map>()
          .map(
              (e) => CustomerConversation.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      total: _int(map['total'] ?? list.length),
      openCount: _int(map['open_count'] ?? map['openCount']),
      unreadCount: _int(map['unread_count'] ?? map['unreadCount']),
      waitingReplyCount:
          _int(map['waiting_reply_count'] ?? map['waitingReplyCount']),
      resolvedCount: _int(map['resolved_count'] ?? map['resolvedCount']),
    );
  }
}

class CustomerConversation {
  final String id;
  final String listingId;
  final String orderId;
  final String listingTitle;
  final String providerName;
  final String providerTypeLabel;
  final String serviceLabel;
  final String status;
  final String priority;
  final int unreadCount;
  final DateTime? updatedAt;
  final CustomerChatMessage? lastMessage;
  final List<CustomerChatMessage> messages;
  final List<String> availableActions;

  const CustomerConversation({
    required this.id,
    this.listingId = '',
    this.orderId = '',
    required this.listingTitle,
    required this.providerName,
    required this.providerTypeLabel,
    required this.serviceLabel,
    this.status = 'OPEN',
    this.priority = 'NORMAL',
    this.unreadCount = 0,
    this.updatedAt,
    this.lastMessage,
    this.messages = const [],
    this.availableActions = const [],
  });

  bool get isOpen => !['RESOLVED', 'CLOSED'].contains(status.toUpperCase());
  bool get canReply =>
      availableActions.isEmpty || availableActions.contains('reply');
  bool get canClose => availableActions.contains('close') || isOpen;
  bool get canReopen => availableActions.contains('reopen') || !isOpen;

  CustomerConversation copyWith({
    List<CustomerChatMessage>? messages,
    int? unreadCount,
  }) {
    return CustomerConversation(
      id: id,
      listingId: listingId,
      orderId: orderId,
      listingTitle: listingTitle,
      providerName: providerName,
      providerTypeLabel: providerTypeLabel,
      serviceLabel: serviceLabel,
      status: status,
      priority: priority,
      unreadCount: unreadCount ?? this.unreadCount,
      updatedAt: updatedAt,
      lastMessage: lastMessage,
      messages: messages ?? this.messages,
      availableActions: availableActions,
    );
  }

  factory CustomerConversation.fromMap(Map<String, dynamic> map) {
    final rawMessages = map['messages'] as List<dynamic>? ?? const [];
    final messages = rawMessages
        .whereType<Map>()
        .map((e) => CustomerChatMessage.fromMap(Map<String, dynamic>.from(e)))
        .toList();
    final rawLast = map['last_message'] ?? map['lastMessage'];
    return CustomerConversation(
      id: (map['publicId'] ?? map['id'] ?? '').toString(),
      listingId: (map['listing_id'] ?? map['listingId'] ?? '').toString(),
      orderId: (map['order_id'] ?? map['orderId'] ?? '').toString(),
      listingTitle: (map['listing_title'] ??
              map['listingTitle'] ??
              map['subject'] ??
              'محادثة عميل')
          .toString(),
      providerName: (map['provider_name'] ??
              map['providerName'] ??
              map['organization_name'] ??
              'الدعم أو المتجر')
          .toString(),
      providerTypeLabel:
          (map['provider_type_label'] ?? map['providerTypeLabel'] ?? 'مزود')
              .toString(),
      serviceLabel: (map['service_label'] ??
              map['serviceLabel'] ??
              map['category'] ??
              'محادثة')
          .toString(),
      status: (map['status'] ?? 'OPEN').toString(),
      priority: (map['priority'] ?? 'NORMAL').toString(),
      unreadCount: _int(map['unread_count'] ?? map['unreadCount']),
      updatedAt: _date(map['updated_at'] ?? map['updatedAt']),
      lastMessage: rawLast is Map
          ? CustomerChatMessage.fromMap(Map<String, dynamic>.from(rawLast))
          : (messages.isNotEmpty ? messages.last : null),
      messages: messages,
      availableActions: (map['available_actions'] as List<dynamic>? ??
              map['availableActions'] as List<dynamic>? ??
              const [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

class CustomerChatMessage {
  final String id;
  final String text;
  final ChatSender sender;
  final DateTime createdAt;
  final List<String> attachments;
  final String senderName;
  final bool read;

  const CustomerChatMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.createdAt,
    this.attachments = const [],
    this.senderName = '',
    this.read = true,
  });

  bool get isCustomer => sender == ChatSender.customer;

  factory CustomerChatMessage.fromMap(Map<String, dynamic> map) {
    final role =
        (map['sender_role'] ?? map['senderRole'] ?? map['sender'] ?? '')
            .toString()
            .toLowerCase();
    final sender = role.contains('customer') || role == 'user' || role == 'me'
        ? ChatSender.customer
        : role.contains('support')
            ? ChatSender.support
            : ChatSender.provider;
    return CustomerChatMessage(
      id: (map['publicId'] ?? map['id'] ?? '').toString(),
      text: (map['message'] ?? map['text'] ?? '').toString(),
      sender: sender,
      senderName: (map['sender_name'] ?? map['senderName'] ?? '').toString(),
      createdAt: _date(map['created_at'] ?? map['createdAt']) ?? DateTime.now(),
      attachments: _attachments(map['attachments']),
      read: map['read'] != false,
    );
  }
}

enum ChatSender { customer, provider, support }

int _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _date(dynamic value) => DateTime.tryParse(value?.toString() ?? '');

List<String> _attachments(dynamic value) {
  if (value is List) {
    return value
        .map((e) => e.toString())
        .where((e) => e.trim().isNotEmpty)
        .toList();
  }
  if (value is String && value.trim().startsWith('[')) {
    final cleaned =
        value.replaceAll('[', '').replaceAll(']', '').replaceAll('"', '');
    return cleaned
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
  if (value is String && value.trim().isNotEmpty) return [value.trim()];
  return const [];
}
