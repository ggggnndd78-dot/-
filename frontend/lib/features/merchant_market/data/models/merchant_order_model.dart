class MerchantOrderModel {
  final String id;
  final String orderNumber;
  final String status;
  final String customerName;
  final double total;
  final String fulfillmentMethod;
  final String paymentMethod;
  final String paymentStatus;
  final String currency;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int itemsCount;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final String? customerPhone;
  final String? customerEmail;
  final String? customerNote;
  final String? cancellationReason;
  final String? branchName;
  final String? cityName;
  final String? addressText;
  final List<MerchantOrderItemModel> items;
  final List<MerchantOrderStatusModel> statusHistory;
  final List<MerchantOrderInvoiceModel> invoices;

  const MerchantOrderModel({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.customerName,
    required this.total,
    required this.fulfillmentMethod,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.currency,
    this.createdAt,
    this.updatedAt,
    required this.itemsCount,
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    this.customerPhone,
    this.customerEmail,
    this.customerNote,
    this.cancellationReason,
    this.branchName,
    this.cityName,
    this.addressText,
    this.items = const [],
    this.statusHistory = const [],
    this.invoices = const [],
  });

  factory MerchantOrderModel.fromMap(Map<String, dynamic> map) {
    final user = _asMap(map['user']);
    final branch = _asMap(map['branch']);
    final city = _asMap(map['city']);
    final address = _asMap(map['address'] ?? map['deliveryAddress']);
    final items = _maps(map['items'])
        .map(MerchantOrderItemModel.fromMap)
        .toList(growable: false);
    final history = _maps(map['statusHistory'] ?? map['status_history'])
        .map(MerchantOrderStatusModel.fromMap)
        .toList(growable: false);
    final invoices = _maps(map['invoices'])
        .map(MerchantOrderInvoiceModel.fromMap)
        .toList(growable: false);

    final calculatedItemsCount = items.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );

    return MerchantOrderModel(
      id: (map['id'] ?? map['publicId'] ?? '').toString(),
      orderNumber:
          (map['orderNumber'] ?? map['order_number'] ?? map['id']).toString(),
      status: (map['status'] ?? 'PENDING').toString(),
      customerName: (map['customerName'] ??
              map['customer_name'] ??
              user['displayName'] ??
              user['display_name'] ??
              user['name'] ??
              'عميل')
          .toString(),
      total: _number(map['total'] ?? map['totalAmount'] ?? map['total_amount']),
      fulfillmentMethod:
          (map['fulfillmentMethod'] ?? map['fulfillment_method'] ?? 'PICKUP')
              .toString(),
      paymentMethod:
          (map['paymentMethod'] ?? map['payment_method'] ?? '').toString(),
      paymentStatus: (map['paymentStatus'] ?? map['payment_status'] ?? 'UNPAID')
          .toString(),
      currency: (map['currency'] ?? 'YER').toString(),
      createdAt: _date(map['createdAt'] ?? map['created_at']),
      updatedAt: _date(map['updatedAt'] ?? map['updated_at']),
      itemsCount: int.tryParse(
            (map['itemsCount'] ?? map['items_count'] ?? calculatedItemsCount)
                .toString(),
          ) ??
          calculatedItemsCount,
      subtotal: _number(map['subtotalAmount'] ?? map['subtotal_amount']),
      deliveryFee: _number(map['deliveryFee'] ?? map['delivery_fee']),
      discount: _number(map['discountAmount'] ?? map['discount_amount']),
      customerPhone: (map['customerPhone'] ??
              map['customer_phone'] ??
              user['phoneE164'] ??
              user['phone_e164'] ??
              user['phoneNormalized'] ??
              user['phone_normalized'])
          ?.toString(),
      customerEmail:
          (map['customerEmail'] ?? map['customer_email'] ?? user['email'])
              ?.toString(),
      customerNote: (map['customerNote'] ?? map['customer_note'])?.toString(),
      cancellationReason:
          (map['cancellationReason'] ?? map['cancellation_reason'])?.toString(),
      branchName:
          (branch['name'] ?? branch['nameAr'] ?? branch['name_ar'])?.toString(),
      cityName: (city['name'] ?? city['nameAr'] ?? city['name_ar'])?.toString(),
      addressText: (map['addressText'] ??
              map['address_text'] ??
              address['text'] ??
              address['addressLine'] ??
              address['address_line'])
          ?.toString(),
      items: items,
      statusHistory: history,
      invoices: invoices,
    );
  }

  static Map<String, dynamic> _asMap(dynamic raw) =>
      raw is Map ? Map<String, dynamic>.from(raw) : const <String, dynamic>{};

  static List<Map<String, dynamic>> _maps(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static double _number(dynamic value) =>
      double.tryParse(value?.toString() ?? '') ?? 0;

  static DateTime? _date(dynamic value) =>
      DateTime.tryParse(value?.toString() ?? '');

  bool get isFinal => const ['COMPLETED', 'CANCELLED', 'REJECTED']
      .contains(status.toUpperCase());

  bool get canReject => const ['PENDING', 'CONFIRMED'].contains(status);

  bool get needsDelivery => fulfillmentMethod == 'DELIVERY';

  List<String> get itemNames => items.map((item) => item.name).toList();
}

class MerchantOrderItemModel {
  final String name;
  final String? partNumber;
  final String? imageUrl;
  final String? listingId;
  final int quantity;
  final double unitPrice;
  final double total;

  const MerchantOrderItemModel({
    required this.name,
    this.partNumber,
    this.imageUrl,
    this.listingId,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });

  factory MerchantOrderItemModel.fromMap(Map<String, dynamic> map) {
    final listing = MerchantOrderModel._asMap(map['listing']);
    final product = MerchantOrderModel._asMap(listing['product']);
    return MerchantOrderItemModel(
      name: (map['productName'] ??
              map['product_name'] ??
              product['nameAr'] ??
              product['name_ar'] ??
              'منتج')
          .toString(),
      partNumber: (map['partNumber'] ??
              map['part_number'] ??
              product['partNumber'] ??
              product['part_number'])
          ?.toString(),
      imageUrl: (map['imageUrl'] ??
              map['image_url'] ??
              listing['primaryImageUrl'] ??
              listing['primary_image_url'])
          ?.toString(),
      listingId: (map['listingId'] ?? map['listing_id'])?.toString(),
      quantity: int.tryParse(map['quantity']?.toString() ?? '') ?? 0,
      unitPrice: MerchantOrderModel._number(
        map['unitPrice'] ?? map['unit_price'],
      ),
      total: MerchantOrderModel._number(
        map['totalAmount'] ?? map['total_amount'],
      ),
    );
  }
}

class MerchantOrderStatusModel {
  final String status;
  final DateTime? createdAt;
  final String? note;
  final String? changedByName;

  const MerchantOrderStatusModel({
    required this.status,
    this.createdAt,
    this.note,
    this.changedByName,
  });

  factory MerchantOrderStatusModel.fromMap(Map<String, dynamic> map) {
    final user =
        MerchantOrderModel._asMap(map['changedBy'] ?? map['changed_by']);
    return MerchantOrderStatusModel(
      status: (map['status'] ?? '').toString(),
      createdAt:
          MerchantOrderModel._date(map['createdAt'] ?? map['created_at']),
      note: map['note']?.toString(),
      changedByName:
          (user['displayName'] ?? user['display_name'] ?? user['name'])
              ?.toString(),
    );
  }
}

class MerchantOrderInvoiceModel {
  final String id;
  final String invoiceNumber;
  final String status;
  final double total;
  final String currency;
  final DateTime? issuedAt;

  const MerchantOrderInvoiceModel({
    required this.id,
    required this.invoiceNumber,
    required this.status,
    required this.total,
    required this.currency,
    this.issuedAt,
  });

  factory MerchantOrderInvoiceModel.fromMap(Map<String, dynamic> map) {
    return MerchantOrderInvoiceModel(
      id: (map['id'] ?? map['publicId'] ?? '').toString(),
      invoiceNumber:
          (map['invoiceNumber'] ?? map['invoice_number'] ?? '').toString(),
      status: (map['status'] ?? 'ISSUED').toString(),
      total:
          MerchantOrderModel._number(map['totalAmount'] ?? map['total_amount']),
      currency: (map['currency'] ?? 'YER').toString(),
      issuedAt: MerchantOrderModel._date(map['issuedAt'] ?? map['issued_at']),
    );
  }
}
