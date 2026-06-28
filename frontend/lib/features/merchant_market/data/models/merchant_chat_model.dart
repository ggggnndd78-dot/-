class MerchantChatResponse {
  final List<MerchantChatTicket> tickets;
  final List<MerchantChatTicket> urgentTickets;
  final int openCount;
  final int unreadCount;
  final int waitingCustomerCount;
  final int resolvedCount;

  const MerchantChatResponse({
    required this.tickets,
    required this.urgentTickets,
    required this.openCount,
    required this.unreadCount,
    required this.waitingCustomerCount,
    required this.resolvedCount,
  });

  factory MerchantChatResponse.fromMap(Map<String, dynamic> map) {
    final items = _list(map['tickets'] ?? map['items'] ?? map['data'])
        .map(MerchantChatTicket.fromMap)
        .toList();
    return MerchantChatResponse(
      tickets: items,
      urgentTickets: items.where((e) => e.isUrgent).toList(),
      openCount: _int(map['open_count'] ??
          map['openCount'] ??
          items.where((e) => e.isOpen).length),
      unreadCount: _int(map['unread_count'] ??
          map['unreadCount'] ??
          items.fold<int>(0, (s, e) => s + e.unreadCount)),
      waitingCustomerCount: _int(map['waiting_customer_count'] ??
          map['waitingCustomerCount'] ??
          items.where((e) => e.waitingForMerchant).length),
      resolvedCount: _int(map['resolved_count'] ??
          map['resolvedCount'] ??
          items
              .where((e) => e.status == 'RESOLVED' || e.status == 'CLOSED')
              .length),
    );
  }
}

class MerchantChatTicket {
  final String id;
  final String publicId;
  final String subject;
  final String status;
  final String priority;
  final String category;
  final String customerName;
  final String customerPhone;
  final String orderNumber;
  final String productName;
  final String lastMessage;
  final String channel;
  final int unreadCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<MerchantChatMessage> messages;

  const MerchantChatTicket({
    required this.id,
    required this.publicId,
    required this.subject,
    required this.status,
    required this.priority,
    required this.category,
    required this.customerName,
    required this.customerPhone,
    required this.orderNumber,
    required this.productName,
    required this.lastMessage,
    required this.channel,
    required this.unreadCount,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
  });

  bool get isOpen =>
      status == 'OPEN' || status == 'PENDING' || status == 'IN_PROGRESS';
  bool get isUrgent => priority == 'URGENT' || priority == 'HIGH';
  bool get waitingForMerchant => unreadCount > 0 || status == 'PENDING';

  factory MerchantChatTicket.fromMap(Map<String, dynamic> map) {
    return MerchantChatTicket(
      id: _str(map['id'] ?? map['ticket_id']),
      publicId: _str(map['publicId'] ?? map['public_id'] ?? map['publicId']),
      subject: _str(map['subject'] ?? map['title'], fallback: 'محادثة عميل'),
      status: _str(map['status'], fallback: 'OPEN'),
      priority: _str(map['priority'], fallback: 'NORMAL'),
      category:
          _str(map['category'] ?? map['category_code'] ?? map['categoryCode']),
      customerName: _str(
          map['customer_name'] ?? map['customerName'] ?? map['display_name']),
      customerPhone:
          _str(map['customer_phone'] ?? map['customerPhone'] ?? map['phone']),
      orderNumber: _str(map['order_number'] ?? map['orderNumber']),
      productName: _str(map['product_name'] ?? map['productName']),
      lastMessage: _str(
          map['last_message'] ??
              map['lastMessage'] ??
              map['message'] ??
              map['description'],
          fallback: 'لا توجد رسالة مختصرة.'),
      channel: _str(map['channel'], fallback: 'APP'),
      unreadCount: _int(map['unread_count'] ?? map['unreadCount']),
      createdAt: _date(map['created_at'] ?? map['createdAt']),
      updatedAt: _date(map['updated_at'] ?? map['updatedAt']),
      messages:
          _list(map['messages']).map(MerchantChatMessage.fromMap).toList(),
    );
  }
}

class MerchantChatMessage {
  final String id;
  final String senderName;
  final String senderType;
  final String message;
  final String attachmentUrl;
  final bool isMine;
  final bool isRead;
  final DateTime? createdAt;

  const MerchantChatMessage({
    required this.id,
    required this.senderName,
    required this.senderType,
    required this.message,
    required this.attachmentUrl,
    required this.isMine,
    required this.isRead,
    required this.createdAt,
  });

  factory MerchantChatMessage.fromMap(Map<String, dynamic> map) {
    final senderType = _str(map['sender_type'] ?? map['senderType']);
    return MerchantChatMessage(
      id: _str(map['id']),
      senderName: _str(
          map['sender_name'] ?? map['senderName'] ?? map['display_name'],
          fallback: senderType == 'MERCHANT' ? 'التاجر' : 'العميل'),
      senderType: senderType,
      message: _str(map['message'] ?? map['body'] ?? map['content']),
      attachmentUrl: _str(map['attachment_url'] ?? map['attachmentUrl']),
      isMine: map['is_mine'] == true ||
          map['isMine'] == true ||
          senderType == 'MERCHANT' ||
          senderType == 'STAFF',
      isRead: map['is_read'] == true ||
          map['isRead'] == true ||
          map['read_at'] != null,
      createdAt: _date(map['created_at'] ?? map['createdAt']),
    );
  }
}

class MerchantNotificationPreferences {
  final bool pushEnabled;
  final bool emailEnabled;
  final bool smsEnabled;
  final bool orderNotifications;
  final bool chatNotifications;
  final bool stockNotifications;
  final bool financeNotifications;
  final bool returnsDisputesNotifications;
  final bool reviewNotifications;

  const MerchantNotificationPreferences({
    required this.pushEnabled,
    required this.emailEnabled,
    required this.smsEnabled,
    required this.orderNotifications,
    required this.chatNotifications,
    required this.stockNotifications,
    required this.financeNotifications,
    required this.returnsDisputesNotifications,
    required this.reviewNotifications,
  });

  factory MerchantNotificationPreferences.defaults() =>
      const MerchantNotificationPreferences(
        pushEnabled: true,
        emailEnabled: true,
        smsEnabled: false,
        orderNotifications: true,
        chatNotifications: true,
        stockNotifications: true,
        financeNotifications: true,
        returnsDisputesNotifications: true,
        reviewNotifications: true,
      );

  factory MerchantNotificationPreferences.fromMap(Map<String, dynamic> map) {
    return MerchantNotificationPreferences(
      pushEnabled: _bool(map['push_enabled'] ?? map['pushEnabled'], true),
      emailEnabled: _bool(map['email_enabled'] ?? map['emailEnabled'], true),
      smsEnabled: _bool(map['sms_enabled'] ?? map['smsEnabled'], false),
      orderNotifications:
          _bool(map['order_notifications'] ?? map['orderNotifications'], true),
      chatNotifications:
          _bool(map['chat_notifications'] ?? map['chatNotifications'], true),
      stockNotifications:
          _bool(map['stock_notifications'] ?? map['stockNotifications'], true),
      financeNotifications: _bool(
          map['finance_notifications'] ?? map['financeNotifications'], true),
      returnsDisputesNotifications: _bool(
          map['returns_disputes_notifications'] ??
              map['returnsDisputesNotifications'],
          true),
      reviewNotifications: _bool(
          map['review_notifications'] ?? map['reviewNotifications'], true),
    );
  }

  Map<String, dynamic> toMap() => {
        'pushEnabled': pushEnabled,
        'emailEnabled': emailEnabled,
        'smsEnabled': smsEnabled,
        'orderNotifications': orderNotifications,
        'chatNotifications': chatNotifications,
        'stockNotifications': stockNotifications,
        'financeNotifications': financeNotifications,
        'returnsDisputesNotifications': returnsDisputesNotifications,
        'reviewNotifications': reviewNotifications,
      };

  MerchantNotificationPreferences copyWith({
    bool? pushEnabled,
    bool? emailEnabled,
    bool? smsEnabled,
    bool? orderNotifications,
    bool? chatNotifications,
    bool? stockNotifications,
    bool? financeNotifications,
    bool? returnsDisputesNotifications,
    bool? reviewNotifications,
  }) =>
      MerchantNotificationPreferences(
        pushEnabled: pushEnabled ?? this.pushEnabled,
        emailEnabled: emailEnabled ?? this.emailEnabled,
        smsEnabled: smsEnabled ?? this.smsEnabled,
        orderNotifications: orderNotifications ?? this.orderNotifications,
        chatNotifications: chatNotifications ?? this.chatNotifications,
        stockNotifications: stockNotifications ?? this.stockNotifications,
        financeNotifications: financeNotifications ?? this.financeNotifications,
        returnsDisputesNotifications:
            returnsDisputesNotifications ?? this.returnsDisputesNotifications,
        reviewNotifications: reviewNotifications ?? this.reviewNotifications,
      );
}

List<Map<String, dynamic>> _list(dynamic value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
  return const [];
}

String _str(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

int _int(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;

bool _bool(dynamic value, bool fallback) {
  if (value == null) return fallback;
  if (value is bool) return value;
  final text = value.toString().toLowerCase();
  if (text == '1' || text == 'true' || text == 'yes') return true;
  if (text == '0' || text == 'false' || text == 'no') return false;
  return fallback;
}

DateTime? _date(dynamic value) => DateTime.tryParse(value?.toString() ?? '');
