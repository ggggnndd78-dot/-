class CustomerReturnOptionsModel {
  final String orderId;
  final String orderNumber;
  final String status;
  final String paymentStatus;
  final String currency;
  final double totalAmount;
  final bool canReturn;
  final int returnWindowDays;
  final int daysSinceCompletion;
  final String policySummary;
  final String blockedReason;
  final List<String> reasons;
  final List<String> refundMethods;
  final List<CustomerReturnItemModel> items;
  final CustomerReturnRequestModel? activeRequest;

  const CustomerReturnOptionsModel({
    required this.orderId,
    required this.orderNumber,
    required this.status,
    required this.paymentStatus,
    required this.currency,
    required this.totalAmount,
    required this.canReturn,
    required this.returnWindowDays,
    required this.daysSinceCompletion,
    required this.policySummary,
    required this.blockedReason,
    required this.reasons,
    required this.refundMethods,
    required this.items,
    this.activeRequest,
  });

  factory CustomerReturnOptionsModel.fromMap(Map<String, dynamic> map) {
    return CustomerReturnOptionsModel(
      orderId: (map['orderId'] ?? map['order_id'] ?? '').toString(),
      orderNumber: (map['orderNumber'] ?? map['order_number'] ?? '').toString(),
      status: (map['status'] ?? '').toString(),
      paymentStatus:
          (map['paymentStatus'] ?? map['payment_status'] ?? '').toString(),
      currency: (map['currency'] ?? 'YER').toString(),
      totalAmount: _double(map['totalAmount'] ?? map['total_amount']),
      canReturn: _bool(map['canReturn'] ?? map['can_return']),
      returnWindowDays:
          _int(map['returnWindowDays'] ?? map['return_window_days'] ?? 7),
      daysSinceCompletion:
          _int(map['daysSinceCompletion'] ?? map['days_since_completion']),
      policySummary:
          (map['policySummary'] ?? map['policy_summary'] ?? '').toString(),
      blockedReason:
          (map['blockedReason'] ?? map['blocked_reason'] ?? '').toString(),
      reasons: _stringList(map['reasons']),
      refundMethods: _stringList(map['refundMethods'] ?? map['refund_methods']),
      items: _list(map['items']).map(CustomerReturnItemModel.fromMap).toList(),
      activeRequest: map['activeRequest'] is Map
          ? CustomerReturnRequestModel.fromMap(
              Map<String, dynamic>.from(map['activeRequest'] as Map))
          : null,
    );
  }
}

class CustomerReturnItemModel {
  final String id;
  final String listingId;
  final String title;
  final String sku;
  final String oemNumber;
  final int orderedQuantity;
  final int maxReturnQuantity;
  final double unitPrice;
  final double totalAmount;
  final String imageUrl;
  final bool returnable;
  final String blockedReason;

  const CustomerReturnItemModel({
    required this.id,
    required this.listingId,
    required this.title,
    required this.sku,
    required this.oemNumber,
    required this.orderedQuantity,
    required this.maxReturnQuantity,
    required this.unitPrice,
    required this.totalAmount,
    required this.imageUrl,
    required this.returnable,
    required this.blockedReason,
  });

  factory CustomerReturnItemModel.fromMap(Map<String, dynamic> map) {
    return CustomerReturnItemModel(
      id: (map['id'] ?? '').toString(),
      listingId: (map['listingId'] ?? map['listing_id'] ?? '').toString(),
      title: (map['title'] ??
              map['productName'] ??
              map['product_name'] ??
              'قطعة غيار')
          .toString(),
      sku: (map['sku'] ?? '').toString(),
      oemNumber: (map['oemNumber'] ?? map['oem_number'] ?? '').toString(),
      orderedQuantity: _int(
          map['orderedQuantity'] ?? map['ordered_quantity'] ?? map['quantity']),
      maxReturnQuantity: _int(map['maxReturnQuantity'] ??
          map['max_return_quantity'] ??
          map['quantity']),
      unitPrice: _double(map['unitPrice'] ?? map['unit_price']),
      totalAmount: _double(map['totalAmount'] ?? map['total_amount']),
      imageUrl: (map['imageUrl'] ?? map['image_url'] ?? '').toString(),
      returnable: _bool(map['returnable'] ?? true),
      blockedReason:
          (map['blockedReason'] ?? map['blocked_reason'] ?? '').toString(),
    );
  }
}

class CustomerReturnRequestModel {
  final String id;
  final String publicId;
  final String orderId;
  final String orderNumber;
  final String status;
  final String requestType;
  final String reason;
  final String details;
  final String refundMethod;
  final String returnMethod;
  final double amount;
  final String currency;
  final String createdAt;
  final String updatedAt;
  final List<CustomerReturnItemModel> items;
  final List<String> attachments;

  const CustomerReturnRequestModel({
    required this.id,
    required this.publicId,
    required this.orderId,
    required this.orderNumber,
    required this.status,
    required this.requestType,
    required this.reason,
    required this.details,
    required this.refundMethod,
    required this.returnMethod,
    required this.amount,
    required this.currency,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
    required this.attachments,
  });

  factory CustomerReturnRequestModel.fromMap(Map<String, dynamic> map) {
    return CustomerReturnRequestModel(
      id: (map['id'] ?? '').toString(),
      publicId: (map['publicId'] ?? map['public_id'] ?? '').toString(),
      orderId: (map['orderId'] ?? map['order_id'] ?? '').toString(),
      orderNumber: (map['orderNumber'] ?? map['order_number'] ?? '').toString(),
      status: (map['status'] ?? '').toString(),
      requestType:
          (map['requestType'] ?? map['request_type'] ?? 'RETURN').toString(),
      reason: (map['reason'] ?? '').toString(),
      details: (map['details'] ?? '').toString(),
      refundMethod:
          (map['refundMethod'] ?? map['refund_method'] ?? '').toString(),
      returnMethod:
          (map['returnMethod'] ?? map['return_method'] ?? '').toString(),
      amount: _double(map['amount']),
      currency: (map['currency'] ?? 'YER').toString(),
      createdAt: (map['createdAt'] ?? map['created_at'] ?? '').toString(),
      updatedAt: (map['updatedAt'] ?? map['updated_at'] ?? '').toString(),
      items: _list(map['items']).map(CustomerReturnItemModel.fromMap).toList(),
      attachments: _stringList(map['attachments']),
    );
  }
}

double _double(Object? value) => double.tryParse((value ?? 0).toString()) ?? 0;
int _int(Object? value) => int.tryParse((value ?? 0).toString()) ?? 0;
bool _bool(Object? value) {
  if (value is bool) return value;
  final text = (value ?? '').toString().toLowerCase();
  return text == 'true' || text == '1' || text == 'yes';
}

List<Map<String, dynamic>> _list(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
}

List<String> _stringList(Object? value) {
  if (value is! List) return const [];
  return value
      .map((e) => e.toString())
      .where((e) => e.trim().isNotEmpty)
      .toList();
}
