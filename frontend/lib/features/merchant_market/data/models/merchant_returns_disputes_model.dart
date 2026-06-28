class MerchantReturnsResponse {
  MerchantReturnsResponse({
    required this.summary,
    required this.items,
  });

  final MerchantReturnsSummary summary;
  final List<MerchantReturnRequest> items;

  factory MerchantReturnsResponse.fromMap(Map<String, dynamic> map) {
    final data =
        map['data'] is Map ? Map<String, dynamic>.from(map['data']) : map;
    final itemsRaw = data['items'] ?? data['returns'] ?? data['data'];
    return MerchantReturnsResponse(
      summary: MerchantReturnsSummary.fromMap(
        Map<String, dynamic>.from(
            data['summary'] is Map ? data['summary'] : const {}),
      ),
      items: _asList(itemsRaw).map(MerchantReturnRequest.fromMap).toList(),
    );
  }
}

class MerchantReturnsSummary {
  MerchantReturnsSummary({
    required this.total,
    required this.pending,
    required this.approved,
    required this.rejected,
    required this.received,
    required this.refunded,
    required this.totalAmount,
    required this.refundedAmount,
    required this.currency,
  });

  final int total;
  final int pending;
  final int approved;
  final int rejected;
  final int received;
  final int refunded;
  final num totalAmount;
  final num refundedAmount;
  final String currency;

  factory MerchantReturnsSummary.fromMap(Map<String, dynamic> map) {
    return MerchantReturnsSummary(
      total: _int(map['total']),
      pending: _int(map['pending']),
      approved: _int(map['approved']),
      rejected: _int(map['rejected']),
      received: _int(map['received']),
      refunded: _int(map['refunded'] ?? map['paid']),
      totalAmount: _num(map['total_amount'] ?? map['totalAmount']),
      refundedAmount: _num(map['refunded_amount'] ?? map['refundedAmount']),
      currency: _str(map['currency'], 'YER'),
    );
  }
}

class MerchantReturnRequest {
  MerchantReturnRequest({
    required this.id,
    required this.orderId,
    required this.orderNumber,
    required this.customerName,
    required this.customerPhone,
    required this.status,
    required this.orderStatus,
    required this.paymentStatus,
    required this.amount,
    required this.currency,
    required this.reason,
    required this.merchantNote,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
    required this.timeline,
  });

  final String id;
  final String orderId;
  final String orderNumber;
  final String customerName;
  final String customerPhone;
  final String status;
  final String orderStatus;
  final String paymentStatus;
  final num amount;
  final String currency;
  final String reason;
  final String merchantNote;
  final String createdAt;
  final String updatedAt;
  final List<MerchantReturnItem> items;
  final List<MerchantCaseTimelineEntry> timeline;

  factory MerchantReturnRequest.fromMap(Map<String, dynamic> map) {
    return MerchantReturnRequest(
      id: _str(map['publicId'] ?? map['public_id'] ?? map['id']),
      orderId: _str(
          map['order_public_id'] ?? map['orderPublicId'] ?? map['order_id']),
      orderNumber: _str(map['order_number'] ?? map['orderNumber']),
      customerName: _str(map['customer_name'] ?? map['customerName'], 'عميل'),
      customerPhone:
          _str(map['customer_phone'] ?? map['customerPhone'] ?? map['phone']),
      status: _str(map['status'], 'PENDING'),
      orderStatus: _str(map['order_status'] ?? map['orderStatus']),
      paymentStatus: _str(map['payment_status'] ?? map['paymentStatus']),
      amount: _num(map['amount']),
      currency: _str(map['currency'], 'YER'),
      reason: _str(map['reason'], 'لا يوجد سبب مسجل'),
      merchantNote: _str(map['merchant_note'] ?? map['merchantNote']),
      createdAt: _str(map['created_at'] ?? map['createdAt']),
      updatedAt: _str(map['updated_at'] ?? map['updatedAt']),
      items: _asList(map['items']).map(MerchantReturnItem.fromMap).toList(),
      timeline: _asList(map['timeline'])
          .map(MerchantCaseTimelineEntry.fromMap)
          .toList(),
    );
  }
}

class MerchantReturnItem {
  MerchantReturnItem({
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
    required this.listingId,
  });

  final String productName;
  final int quantity;
  final num unitPrice;
  final num totalAmount;
  final String listingId;

  factory MerchantReturnItem.fromMap(Map<String, dynamic> map) {
    return MerchantReturnItem(
      productName: _str(map['product_name'] ?? map['productName'], 'منتج'),
      quantity: _int(map['quantity']),
      unitPrice: _num(map['unit_price'] ?? map['unitPrice']),
      totalAmount: _num(map['total_amount'] ?? map['totalAmount']),
      listingId: _str(map['listing_id'] ?? map['listingId']),
    );
  }
}

class MerchantDisputesResponse {
  MerchantDisputesResponse({required this.summary, required this.items});

  final MerchantDisputesSummary summary;
  final List<MerchantDisputeCase> items;

  factory MerchantDisputesResponse.fromMap(Map<String, dynamic> map) {
    final data =
        map['data'] is Map ? Map<String, dynamic>.from(map['data']) : map;
    final itemsRaw = data['items'] ?? data['disputes'] ?? data['data'];
    return MerchantDisputesResponse(
      summary: MerchantDisputesSummary.fromMap(
        Map<String, dynamic>.from(
            data['summary'] is Map ? data['summary'] : const {}),
      ),
      items: _asList(itemsRaw).map(MerchantDisputeCase.fromMap).toList(),
    );
  }
}

class MerchantDisputesSummary {
  MerchantDisputesSummary({
    required this.total,
    required this.open,
    required this.underReview,
    required this.resolved,
    required this.rejected,
  });

  final int total;
  final int open;
  final int underReview;
  final int resolved;
  final int rejected;

  factory MerchantDisputesSummary.fromMap(Map<String, dynamic> map) {
    return MerchantDisputesSummary(
      total: _int(map['total']),
      open: _int(map['open']),
      underReview: _int(map['under_review'] ?? map['underReview']),
      resolved: _int(map['resolved']),
      rejected: _int(map['rejected']),
    );
  }
}

class MerchantDisputeCase {
  MerchantDisputeCase({
    required this.id,
    required this.ticketId,
    required this.orderId,
    required this.orderNumber,
    required this.customerName,
    required this.customerPhone,
    required this.reasonCode,
    required this.description,
    required this.status,
    required this.priority,
    required this.resolutionNote,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
    required this.timeline,
  });

  final String id;
  final String ticketId;
  final String orderId;
  final String orderNumber;
  final String customerName;
  final String customerPhone;
  final String reasonCode;
  final String description;
  final String status;
  final String priority;
  final String resolutionNote;
  final String createdAt;
  final String updatedAt;
  final List<MerchantCaseMessage> messages;
  final List<MerchantCaseTimelineEntry> timeline;

  factory MerchantDisputeCase.fromMap(Map<String, dynamic> map) {
    return MerchantDisputeCase(
      id: _str(map['publicId'] ?? map['public_id'] ?? map['id']),
      ticketId: _str(
          map['ticket_public_id'] ?? map['ticketPublicId'] ?? map['ticket_id']),
      orderId: _str(
          map['order_public_id'] ?? map['orderPublicId'] ?? map['order_id']),
      orderNumber: _str(map['order_number'] ?? map['orderNumber']),
      customerName: _str(map['customer_name'] ?? map['customerName'], 'عميل'),
      customerPhone:
          _str(map['customer_phone'] ?? map['customerPhone'] ?? map['phone']),
      reasonCode: _str(
          map['reason_code'] ?? map['reasonCode'] ?? map['subject'],
          'شكوى عميل'),
      description:
          _str(map['description'] ?? map['message'], 'لا يوجد وصف إضافي'),
      status: _str(map['status'], 'OPEN'),
      priority: _str(map['priority'], 'NORMAL'),
      resolutionNote: _str(map['resolution_note'] ?? map['resolutionNote']),
      createdAt: _str(map['created_at'] ?? map['createdAt']),
      updatedAt: _str(map['updated_at'] ?? map['updatedAt']),
      messages:
          _asList(map['messages']).map(MerchantCaseMessage.fromMap).toList(),
      timeline: _asList(map['timeline'])
          .map(MerchantCaseTimelineEntry.fromMap)
          .toList(),
    );
  }
}

class MerchantCaseMessage {
  MerchantCaseMessage({
    required this.id,
    required this.senderName,
    required this.message,
    required this.createdAt,
    required this.attachments,
  });

  final String id;
  final String senderName;
  final String message;
  final String createdAt;
  final List<String> attachments;

  factory MerchantCaseMessage.fromMap(Map<String, dynamic> map) {
    return MerchantCaseMessage(
      id: _str(map['id'] ?? map['publicId']),
      senderName: _str(map['sender_name'] ?? map['senderName'], 'النظام'),
      message: _str(map['message']),
      createdAt: _str(map['created_at'] ?? map['createdAt']),
      attachments:
          _asDynamicList(map['attachments']).map((e) => e.toString()).toList(),
    );
  }
}

class MerchantCaseTimelineEntry {
  MerchantCaseTimelineEntry({
    required this.status,
    required this.note,
    required this.createdAt,
    required this.actorName,
  });

  final String status;
  final String note;
  final String createdAt;
  final String actorName;

  factory MerchantCaseTimelineEntry.fromMap(Map<String, dynamic> map) {
    return MerchantCaseTimelineEntry(
      status: _str(map['status'] ?? map['event']),
      note: _str(map['note'] ?? map['message']),
      createdAt: _str(map['created_at'] ?? map['createdAt']),
      actorName: _str(map['actor_name'] ?? map['actorName'], 'النظام'),
    );
  }
}

List<Map<String, dynamic>> _asList(dynamic value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
  return const [];
}

List<dynamic> _asDynamicList(dynamic value) {
  if (value is List) return value;
  return const [];
}

String _str(dynamic value, [String fallback = '']) {
  if (value == null) return fallback;
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

int _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

num _num(dynamic value) {
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '') ?? 0;
}
