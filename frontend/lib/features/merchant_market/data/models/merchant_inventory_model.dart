class MerchantInventoryModel {
  final MerchantInventorySummary summary;
  final List<MerchantInventoryBranch> branches;
  final List<MerchantInventoryItem> alerts;
  final List<MerchantInventoryItem> items;
  final List<MerchantInventoryMovement> recentMovements;

  const MerchantInventoryModel({
    required this.summary,
    required this.branches,
    required this.alerts,
    required this.items,
    this.recentMovements = const [],
  });

  factory MerchantInventoryModel.fromMap(Map<String, dynamic> map) {
    return MerchantInventoryModel(
      summary: MerchantInventorySummary.fromMap(
        Map<String, dynamic>.from(map['summary'] as Map? ?? {}),
      ),
      branches:
          _maps(map['branches']).map(MerchantInventoryBranch.fromMap).toList(),
      alerts: _maps(map['alerts']).map(MerchantInventoryItem.fromMap).toList(),
      items: _maps(map['items']).map(MerchantInventoryItem.fromMap).toList(),
      recentMovements: _maps(map['recentMovements'] ?? map['recent_movements'])
          .map(MerchantInventoryMovement.fromMap)
          .toList(),
    );
  }

  static List<Map<String, dynamic>> _maps(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
}

class MerchantInventorySummary {
  final int totalProducts;
  final int availableProducts;
  final int lowStock;
  final int outOfStock;
  final int movementsToday;
  final int reservedQuantity;
  final int totalOnHand;
  final int totalAvailable;
  final int reorderNeeded;

  const MerchantInventorySummary({
    required this.totalProducts,
    required this.availableProducts,
    required this.lowStock,
    required this.outOfStock,
    required this.movementsToday,
    required this.reservedQuantity,
    required this.totalOnHand,
    required this.totalAvailable,
    required this.reorderNeeded,
  });

  factory MerchantInventorySummary.fromMap(Map<String, dynamic> map) {
    final low =
        _int(map['lowStockProducts'] ?? map['lowStock'] ?? map['low_stock']);
    final out = _int(
        map['outOfStockProducts'] ?? map['outOfStock'] ?? map['out_of_stock']);
    return MerchantInventorySummary(
      totalProducts: _int(map['totalProducts'] ?? map['total_products']),
      availableProducts:
          _int(map['availableProducts'] ?? map['available_products']),
      lowStock: low,
      outOfStock: out,
      movementsToday: _int(map['todayMovements'] ??
          map['movementsToday'] ??
          map['movements_today']),
      reservedQuantity:
          _int(map['reservedQuantity'] ?? map['reserved_quantity']),
      totalOnHand: _int(map['totalOnHand'] ?? map['total_on_hand']),
      totalAvailable: _int(map['totalAvailable'] ?? map['total_available']),
      reorderNeeded:
          _int(map['reorderNeeded'] ?? map['reorder_needed'] ?? (low + out)),
    );
  }
}

class MerchantInventoryBranch {
  final String id;
  final String name;
  final int totalProducts;
  final int lowStock;
  final int outOfStock;

  const MerchantInventoryBranch({
    required this.id,
    required this.name,
    this.totalProducts = 0,
    this.lowStock = 0,
    this.outOfStock = 0,
  });

  factory MerchantInventoryBranch.fromMap(Map<String, dynamic> map) {
    return MerchantInventoryBranch(
      id: (map['publicId'] ??
              map['public_id'] ??
              map['branchId'] ??
              map['branch_id'] ??
              map['listingId'] ??
              map['id'] ??
              map['productId'] ??
              '')
          .toString(),
      name: (map['name'] ?? map['branchName'] ?? map['branch_name'] ?? 'فرع')
          .toString(),
      totalProducts: _int(map['totalProducts'] ?? map['total_products']),
      lowStock: _int(map['lowStock'] ?? map['low_stock']),
      outOfStock: _int(map['outOfStock'] ?? map['out_of_stock']),
    );
  }
}

class MerchantInventoryItem {
  final String id;
  final String? numericId;
  final String? listingId;
  final String? listingNumericId;
  final String title;
  final String? sku;
  final String? branchId;
  final String? branchNumericId;
  final String branchName;
  final int currentQuantity;
  final int reservedQuantity;
  final int availableQuantity;
  final int alertThreshold;
  final String status;
  final DateTime? updatedAt;
  final String? imageUrl;
  final String? categoryName;
  final String? brandName;
  final String? locationCode;
  final String? lastMovementType;
  final int? lastMovementQuantity;
  final DateTime? lastMovementAt;

  const MerchantInventoryItem({
    required this.id,
    this.numericId,
    this.listingId,
    this.listingNumericId,
    required this.title,
    this.sku,
    this.branchId,
    this.branchNumericId,
    required this.branchName,
    required this.currentQuantity,
    required this.reservedQuantity,
    required this.availableQuantity,
    required this.alertThreshold,
    required this.status,
    this.updatedAt,
    this.imageUrl,
    this.categoryName,
    this.brandName,
    this.locationCode,
    this.lastMovementType,
    this.lastMovementQuantity,
    this.lastMovementAt,
  });

  bool get isOutOfStock => status == 'out_of_stock';
  bool get isLowStock => status == 'low_stock';
  bool get needsReorder =>
      isOutOfStock || isLowStock || availableQuantity <= alertThreshold;

  factory MerchantInventoryItem.fromMap(Map<String, dynamic> map) {
    final onHand = _int(map['currentStock'] ??
        map['quantity_on_hand'] ??
        map['current_quantity'] ??
        map['quantityOnHand']);
    final reserved = _int(map['reservedStock'] ??
        map['quantity_reserved'] ??
        map['reserved_quantity'] ??
        map['quantityReserved']);
    final available = map.containsKey('available_quantity') ||
            map.containsKey('availableQuantity')
        ? _int(map['available_quantity'] ?? map['availableQuantity'])
        : onHand - reserved;
    final movement = map['lastMovement'] ?? map['last_movement'];
    final movementMap = movement is Map
        ? Map<String, dynamic>.from(movement)
        : const <String, dynamic>{};
    return MerchantInventoryItem(
      id: (map['id'] ?? map['publicId'] ?? map['public_id'] ?? '').toString(),
      numericId: (map['numericId'] ?? map['numeric_id'])?.toString(),
      listingId: (map['listing_id'] ?? map['listingId'])?.toString(),
      listingNumericId:
          (map['listingNumericId'] ?? map['listing_numeric_id'])?.toString(),
      title:
          (map['title'] ?? map['product_name'] ?? map['productName'] ?? 'منتج')
              .toString(),
      sku: (map['sku'] ?? map['part_number'] ?? map['partNumber'])?.toString(),
      branchId: (map['branchId'] ?? map['branch_id'])?.toString(),
      branchNumericId:
          (map['branchNumericId'] ?? map['branch_numeric_id'])?.toString(),
      branchName: (map['branchName'] ?? map['branch_name'] ?? 'الفرع الرئيسي')
          .toString(),
      currentQuantity: onHand,
      reservedQuantity: reserved,
      availableQuantity: available,
      alertThreshold: _int(map['lowStockThreshold'] ??
          map['reorder_level'] ??
          map['alert_threshold'] ??
          map['reorderLevel']),
      status: _status(map['status']),
      updatedAt:
          _date(map['lastUpdated'] ?? map['updated_at'] ?? map['updatedAt']),
      imageUrl: (map['imageUrl'] ?? map['image_url'])?.toString(),
      categoryName: (map['categoryName'] ?? map['category_name'])?.toString(),
      brandName: (map['brandName'] ?? map['brand_name'])?.toString(),
      locationCode: (map['locationCode'] ?? map['location_code'])?.toString(),
      lastMovementType: (movementMap['type'] ??
              movementMap['movementType'] ??
              movementMap['movement_type'])
          ?.toString(),
      lastMovementQuantity:
          movementMap.isEmpty ? null : _int(movementMap['quantity']),
      lastMovementAt:
          _date(movementMap['createdAt'] ?? movementMap['created_at']),
    );
  }
}

class MerchantInventoryMovement {
  final String id;
  final String inventoryItemId;
  final String productName;
  final String? sku;
  final String branchName;
  final String movementType;
  final int quantity;
  final int? beforeQuantity;
  final int? afterQuantity;
  final String? referenceType;
  final String? referenceId;
  final String? note;
  final String? createdBy;
  final DateTime? createdAt;

  const MerchantInventoryMovement({
    required this.id,
    required this.inventoryItemId,
    required this.productName,
    this.sku,
    required this.branchName,
    required this.movementType,
    required this.quantity,
    this.beforeQuantity,
    this.afterQuantity,
    this.referenceType,
    this.referenceId,
    this.note,
    this.createdBy,
    this.createdAt,
  });

  factory MerchantInventoryMovement.fromMap(Map<String, dynamic> map) {
    return MerchantInventoryMovement(
      id: (map['id'] ?? '').toString(),
      inventoryItemId:
          (map['inventoryItemId'] ?? map['inventory_item_id'] ?? '').toString(),
      productName:
          (map['productName'] ?? map['product_name'] ?? map['title'] ?? 'منتج')
              .toString(),
      sku: (map['sku'] ?? map['part_number'])?.toString(),
      branchName: (map['branchName'] ?? map['branch_name'] ?? 'الفرع الرئيسي')
          .toString(),
      movementType:
          (map['movementType'] ?? map['movement_type'] ?? map['type'] ?? '')
              .toString(),
      quantity: _int(map['quantity']),
      beforeQuantity: map.containsKey('beforeQuantity') ||
              map.containsKey('before_quantity')
          ? _int(map['beforeQuantity'] ?? map['before_quantity'])
          : null,
      afterQuantity:
          map.containsKey('afterQuantity') || map.containsKey('after_quantity')
              ? _int(map['afterQuantity'] ?? map['after_quantity'])
              : null,
      referenceType:
          (map['referenceType'] ?? map['reference_type'])?.toString(),
      referenceId: (map['referenceId'] ?? map['reference_id'])?.toString(),
      note: map['note']?.toString(),
      createdBy: (map['createdBy'] ?? map['created_by'])?.toString(),
      createdAt: _date(map['createdAt'] ?? map['created_at']),
    );
  }
}

int _int(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;

DateTime? _date(dynamic value) => DateTime.tryParse(value?.toString() ?? '');

String _status(dynamic value) {
  return switch (value?.toString().toUpperCase()) {
    'LOW' || 'LOW_STOCK' => 'low_stock',
    'OUT' || 'OUT_OF_STOCK' => 'out_of_stock',
    'ARCHIVED' => 'archived',
    'ACTIVE' || 'AVAILABLE' => 'available',
    _ => 'available',
  };
}
