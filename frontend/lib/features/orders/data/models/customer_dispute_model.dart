class CustomerDisputeOptionsModel {
  final String orderId;
  final String orderNumber;
  final String status;
  final String paymentStatus;
  final String organizationId;
  final String organizationName;
  final bool canOpen;
  final String blockedReason;
  final List<String> reasons;
  final CustomerDisputeModel? activeDispute;

  const CustomerDisputeOptionsModel({
    required this.orderId,
    required this.orderNumber,
    required this.status,
    required this.paymentStatus,
    required this.organizationId,
    required this.organizationName,
    required this.canOpen,
    required this.blockedReason,
    required this.reasons,
    this.activeDispute,
  });

  factory CustomerDisputeOptionsModel.fromMap(Map<String, dynamic> map) {
    return CustomerDisputeOptionsModel(
      orderId: (map['orderId'] ?? map['order_id'] ?? '').toString(),
      orderNumber: (map['orderNumber'] ?? map['order_number'] ?? '').toString(),
      status: (map['status'] ?? '').toString(),
      paymentStatus:
          (map['paymentStatus'] ?? map['payment_status'] ?? '').toString(),
      organizationId:
          (map['organizationId'] ?? map['organization_id'] ?? '').toString(),
      organizationName:
          (map['organizationName'] ?? map['organization_name'] ?? 'المتجر')
              .toString(),
      canOpen: _bool(map['canOpen'] ?? map['can_open']),
      blockedReason:
          (map['blockedReason'] ?? map['blocked_reason'] ?? '').toString(),
      reasons: _stringList(map['reasons']),
      activeDispute: map['activeDispute'] is Map
          ? CustomerDisputeModel.fromMap(
              Map<String, dynamic>.from(map['activeDispute'] as Map))
          : null,
    );
  }
}

class CustomerDisputeModel {
  final String id;
  final String publicId;
  final String orderId;
  final String orderNumber;
  final String organizationId;
  final String organizationName;
  final String status;
  final String reasonCode;
  final String subject;
  final String description;
  final String decision;
  final String decisionNote;
  final String ticketId;
  final String priority;
  final String createdAt;
  final String updatedAt;
  final List<String> attachments;
  final List<CustomerDisputeMessageModel> messages;

  const CustomerDisputeModel({
    required this.id,
    required this.publicId,
    required this.orderId,
    required this.orderNumber,
    required this.organizationId,
    required this.organizationName,
    required this.status,
    required this.reasonCode,
    required this.subject,
    required this.description,
    required this.decision,
    required this.decisionNote,
    required this.ticketId,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
    required this.attachments,
    required this.messages,
  });

  factory CustomerDisputeModel.fromMap(Map<String, dynamic> map) {
    return CustomerDisputeModel(
      id: (map['id'] ?? '').toString(),
      publicId:
          (map['publicId'] ?? map['public_id'] ?? map['id'] ?? '').toString(),
      orderId: (map['orderId'] ?? map['order_id'] ?? '').toString(),
      orderNumber: (map['orderNumber'] ?? map['order_number'] ?? '').toString(),
      organizationId:
          (map['organizationId'] ?? map['organization_id'] ?? '').toString(),
      organizationName:
          (map['organizationName'] ?? map['organization_name'] ?? 'المتجر')
              .toString(),
      status: (map['status'] ?? 'OPEN').toString(),
      reasonCode: (map['reasonCode'] ?? map['reason_code'] ?? '').toString(),
      subject: (map['subject'] ??
              map['reasonCode'] ??
              map['reason_code'] ??
              'نزاع عميل')
          .toString(),
      description: (map['description'] ?? '').toString(),
      decision: (map['decision'] ?? '').toString(),
      decisionNote:
          (map['decisionNote'] ?? map['decision_note'] ?? '').toString(),
      ticketId: (map['ticketId'] ?? map['ticket_id'] ?? '').toString(),
      priority: (map['priority'] ?? 'NORMAL').toString(),
      createdAt: (map['createdAt'] ?? map['created_at'] ?? '').toString(),
      updatedAt: (map['updatedAt'] ?? map['updated_at'] ?? '').toString(),
      attachments: _stringList(map['attachments']),
      messages: _list(map['messages'])
          .map(CustomerDisputeMessageModel.fromMap)
          .toList(),
    );
  }

  String get statusLabel {
    switch (status.toUpperCase()) {
      case 'OPEN':
        return 'مفتوح';
      case 'UNDER_REVIEW':
        return 'قيد المراجعة';
      case 'RESOLVED':
        return 'تم الحل';
      case 'REJECTED':
        return 'مرفوض';
      case 'CLOSED':
        return 'مغلق';
      default:
        return status.isEmpty ? 'غير محدد' : status;
    }
  }

  bool get canReply =>
      !['RESOLVED', 'REJECTED', 'CLOSED'].contains(status.toUpperCase());
  bool get canReopen =>
      ['RESOLVED', 'REJECTED', 'CLOSED'].contains(status.toUpperCase());
}

class CustomerDisputeMessageModel {
  final String id;
  final String senderName;
  final String message;
  final bool fromCustomer;
  final List<String> attachments;
  final String createdAt;

  const CustomerDisputeMessageModel({
    required this.id,
    required this.senderName,
    required this.message,
    required this.fromCustomer,
    required this.attachments,
    required this.createdAt,
  });

  factory CustomerDisputeMessageModel.fromMap(Map<String, dynamic> map) {
    return CustomerDisputeMessageModel(
      id: (map['id'] ?? '').toString(),
      senderName:
          (map['senderName'] ?? map['sender_name'] ?? 'غيارك').toString(),
      message: (map['message'] ?? '').toString(),
      fromCustomer: _bool(map['fromCustomer'] ?? map['from_customer']),
      attachments: _stringList(map['attachments']),
      createdAt: (map['createdAt'] ?? map['created_at'] ?? '').toString(),
    );
  }
}

bool _bool(dynamic value) {
  if (value is bool) return value;
  final text = value?.toString().toLowerCase() ?? '';
  return text == 'true' || text == '1' || text == 'yes';
}

List<Map<String, dynamic>> _list(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
}

List<String> _stringList(dynamic value) {
  if (value is! List) return const [];
  return value
      .map((e) => e.toString())
      .where((e) => e.trim().isNotEmpty)
      .toList();
}
