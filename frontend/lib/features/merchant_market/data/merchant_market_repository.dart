import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/config/api_endpoints.dart';
import 'package:ghiyarak/core/network/api_client.dart';
import 'package:ghiyarak/features/marketplace/data/models/catalog_category.dart';
import 'package:ghiyarak/features/marketplace/data/models/product_model.dart';
import 'package:ghiyarak/features/merchant_market/data/models/merchant_listing_model.dart';
import 'package:ghiyarak/features/merchant_market/data/models/merchant_dashboard_model.dart';
import 'package:ghiyarak/features/merchant_market/data/models/merchant_order_model.dart';
import 'package:ghiyarak/features/merchant_market/data/models/merchant_returns_disputes_model.dart';
import 'package:ghiyarak/features/merchant_market/data/models/merchant_organization_model.dart';
import 'package:ghiyarak/features/merchant_market/data/models/merchant_inventory_model.dart';
import 'package:ghiyarak/features/merchant_market/data/models/merchant_team_member_model.dart';
import 'package:ghiyarak/features/merchant_market/data/models/merchant_report_model.dart';
import 'package:ghiyarak/features/merchant_market/data/models/merchant_notification_model.dart';
import 'package:ghiyarak/features/merchant_market/data/models/merchant_finance_model.dart';
import 'package:ghiyarak/features/merchant_market/data/models/merchant_chat_model.dart';
import 'package:ghiyarak/features/merchant_market/data/models/merchant_shipment_model.dart';
import 'package:ghiyarak/features/merchant_market/data/models/merchant_settings_model.dart';

final merchantMarketRepositoryProvider =
    Provider<MerchantMarketRepository>((ref) {
  return MerchantMarketRepository(ref.watch(apiClientProvider));
});

class MerchantLookupItem {
  final String id;
  final String name;

  const MerchantLookupItem({required this.id, required this.name});

  factory MerchantLookupItem.fromMap(Map<String, dynamic> map) {
    return MerchantLookupItem(
      id: (map['id'] ?? map['publicId'] ?? '').toString(),
      name: (map['name'] ??
              map['nameAr'] ??
              map['name_ar'] ??
              map['branch_name'] ??
              map['branchName'] ??
              map['displayName'] ??
              '')
          .toString(),
    );
  }
}

class MerchantProductLookupResult {
  const MerchantProductLookupResult({
    this.productId,
    this.nameAr,
    this.categoryId,
    this.partBrandId,
    this.partNumber,
    this.countryOfOrigin,
    this.condition,
    this.description,
    this.compatibilities = const [],
  });

  final String? productId;
  final String? nameAr;
  final String? categoryId;
  final String? partBrandId;
  final String? partNumber;
  final String? countryOfOrigin;
  final String? condition;
  final String? description;
  final List<Map<String, dynamic>> compatibilities;

  factory MerchantProductLookupResult.fromMap(Map<String, dynamic> map) {
    final specifications = map['specifications'];
    final specs = specifications is Map
        ? Map<String, dynamic>.from(specifications)
        : const <String, dynamic>{};
    final compatibilities = map['compatibilities'] ?? map['compatibility'];
    return MerchantProductLookupResult(
      productId: (map['id'] ?? map['productId'] ?? map['product_id'])?.toString(),
      nameAr: map['nameAr']?.toString() ?? map['name_ar']?.toString(),
      categoryId:
          map['categoryId']?.toString() ?? map['category_id']?.toString(),
      partBrandId:
          map['partBrandId']?.toString() ?? map['part_brand_id']?.toString(),
      partNumber: map['partNumber']?.toString() ??
          map['part_number']?.toString() ??
          map['oemNumber']?.toString() ??
          map['oem_number']?.toString() ??
          map['sku']?.toString(),
      countryOfOrigin: map['countryOfOrigin']?.toString() ??
          map['country_of_origin']?.toString() ??
          specs['countryOfOrigin']?.toString() ??
          specs['country_of_origin']?.toString() ??
          specs['country']?.toString(),
      condition: map['condition']?.toString(),
      description: map['description']?.toString(),
      compatibilities: compatibilities is List
          ? compatibilities
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
          : const [],
    );
  }
}

class MerchantBranchManagementItem {
  final String id;
  final String name;
  final String? phone;
  final String? address;
  final String? cityName;
  final String? districtName;
  final String? areaName;
  final String? managerName;
  final String? createdAt;
  final String? updatedAt;
  final double? latitude;
  final double? longitude;
  final bool isActive;
  final bool isMain;
  final bool supportsPickup;
  final bool supportsDelivery;
  final bool supportsInstallation;
  final bool supportsMobileService;
  final int productsCount;
  final int ordersCount;
  final int inventoryQuantity;
  final int lowStockCount;

  const MerchantBranchManagementItem({
    required this.id,
    required this.name,
    this.phone,
    this.address,
    this.cityName,
    this.districtName,
    this.areaName,
    this.managerName,
    this.createdAt,
    this.updatedAt,
    this.latitude,
    this.longitude,
    this.isActive = true,
    this.isMain = false,
    this.supportsPickup = true,
    this.supportsDelivery = false,
    this.supportsInstallation = false,
    this.supportsMobileService = false,
    this.productsCount = 0,
    this.ordersCount = 0,
    this.inventoryQuantity = 0,
    this.lowStockCount = 0,
  });

  factory MerchantBranchManagementItem.fromBranchModel(
    MerchantBranchModel model,
  ) {
    return MerchantBranchManagementItem(
      id: model.id,
      name: model.name,
      phone: model.phone,
      address: model.address,
      cityName: model.cityName,
      districtName: model.districtName,
      areaName: model.areaName,
      managerName: model.managerName,
      latitude: model.latitude,
      longitude: model.longitude,
      isActive: true,
      isMain: model.isHeadOffice,
      supportsPickup: model.supportsPickup,
      supportsDelivery: model.supportsDelivery,
      supportsInstallation: model.supportsInstallation,
      supportsMobileService: model.supportsMobileService,
      productsCount: model.productsCount,
      ordersCount: model.ordersCount,
      inventoryQuantity: model.inventoryQuantity,
      lowStockCount: model.lowStockCount,
    );
  }

  factory MerchantBranchManagementItem.fromMap(Map<String, dynamic> map) {
    return MerchantBranchManagementItem(
      id: (map['id'] ?? map['publicId'] ?? map['public_id'] ?? '').toString(),
      name: (map['branchName'] ?? map['branch_name'] ?? map['name'] ?? 'فرع')
          .toString(),
      phone: (map['phone'] ?? map['primaryPhone'] ?? map['primary_phone'])
          ?.toString(),
      address: (map['addressLine1'] ?? map['address_line_1'] ?? map['address'])
          ?.toString(),
      cityName: (map['cityName'] ?? map['city_name'])?.toString(),
      districtName: (map['districtName'] ?? map['district_name'])?.toString(),
      areaName: (map['areaName'] ?? map['area_name'])?.toString(),
      managerName: (map['managerName'] ?? map['manager_name'])?.toString(),
      createdAt: (map['createdAt'] ?? map['created_at'])?.toString(),
      updatedAt: (map['updatedAt'] ?? map['updated_at'])?.toString(),
      latitude: double.tryParse((map['latitude'] ?? '').toString()),
      longitude: double.tryParse((map['longitude'] ?? '').toString()),
      isActive: (map['isActive'] ?? map['is_active'] ?? true) != false,
      isMain: map['isMain'] == true ||
          map['is_main'] == true ||
          map['isHeadOffice'] == true ||
          map['is_head_office'] == true,
      supportsPickup:
          (map['supportsPickup'] ?? map['supports_pickup'] ?? true) != false,
      supportsDelivery:
          map['supportsDelivery'] == true || map['supports_delivery'] == true,
      supportsInstallation: map['supportsInstallation'] == true ||
          map['supports_installation'] == true,
      supportsMobileService: map['supportsMobileService'] == true ||
          map['supports_mobile_service'] == true,
      productsCount: int.tryParse(
              (map['productsCount'] ?? map['products_count'] ?? 0)
                  .toString()) ??
          0,
      ordersCount: int.tryParse(
              (map['ordersCount'] ?? map['orders_count'] ?? 0).toString()) ??
          0,
      inventoryQuantity: int.tryParse(
              (map['inventoryQuantity'] ?? map['inventory_quantity'] ?? 0)
                  .toString()) ??
          0,
      lowStockCount: int.tryParse(
              (map['lowStockCount'] ?? map['low_stock_count'] ?? 0)
                  .toString()) ??
          0,
    );
  }

  String get searchableText =>
      [name, phone, address, cityName, districtName, areaName, managerName]
          .where((value) => (value ?? '').trim().isNotEmpty)
          .join(' ')
          .toLowerCase();
}

class MerchantMarketRepository {
  final ApiClient _apiClient;

  MerchantMarketRepository(this._apiClient);

  Future<MerchantDashboardModel> getDashboardSummary({
    String period = 'day',
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.merchantDashboardSummary,
      queryParameters: {'period': period},
    );
    final data = response.data is Map ? response.data['data'] : null;
    if (data is! Map) {
      throw StateError('تعذر تحميل ملخص لوحة التاجر');
    }
    return MerchantDashboardModel.fromMap(
      Map<String, dynamic>.from(data),
    );
  }

  Future<List<MerchantListingModel>> getMyListings() async {
    final response = await _apiClient.get(ApiEndpoints.merchantListings);
    final data = response.data is Map ? response.data['data'] : null;
    final items = data is List ? data : const <dynamic>[];
    return items
        .whereType<Map>()
        .map((item) =>
            MerchantListingModel.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getImportJobs() async {
    final organizationId = await getMerchantOrganizationId();
    if ((organizationId ?? '').isEmpty) {
      throw StateError('لا توجد مؤسسة تاجر مرتبطة بالحساب');
    }
    final response =
        await _apiClient.get(ApiEndpoints.merchantImportJobs(organizationId!));
    final data = response.data is Map ? response.data['data'] : response.data;
    final items = data is List ? data : const <dynamic>[];
    return items
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> createImportJob({
    required String fileName,
    String? fileUrl,
    String? branchId,
  }) async {
    final organizationId = await getMerchantOrganizationId();
    if ((organizationId ?? '').isEmpty) {
      throw StateError('لا توجد مؤسسة تاجر مرتبطة بالحساب');
    }
    await _apiClient.post(
      ApiEndpoints.merchantImportJobs(organizationId!),
      data: {
        'fileName': fileName.trim(),
        if ((fileUrl ?? '').trim().isNotEmpty) 'fileUrl': fileUrl!.trim(),
        if ((branchId ?? '').trim().isNotEmpty)
          'branchId': int.tryParse(branchId!.trim()),
      },
    );
  }

  Future<void> executeImportJob(String jobId) async {
    await _apiClient.post('/merchant/import-jobs/$jobId/execute');
  }

  Future<List<Map<String, dynamic>>> getCoupons() async {
    final response = await _apiClient.get(ApiEndpoints.merchantCoupons);
    final data = response.data is Map ? response.data['data'] : response.data;
    final items = data is List ? data : const <dynamic>[];
    return items
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> createCoupon({
    required String code,
    required String discountType,
    required double discountValue,
    String? description,
  }) async {
    await _apiClient.post(
      ApiEndpoints.merchantCoupons,
      data: {
        'code': code.trim().toUpperCase(),
        'discountType': discountType,
        'discountValue': discountValue,
        if ((description ?? '').trim().isNotEmpty)
          'description': description!.trim(),
        'isActive': true,
      },
    );
  }

  Future<List<MerchantOrderModel>> getMerchantOrders() async {
    final response = await _apiClient.get(ApiEndpoints.merchantOrders);
    final data = response.data is Map ? response.data['data'] : null;
    final items = data is List ? data : const <dynamic>[];
    return items
        .whereType<Map>()
        .map((item) =>
            MerchantOrderModel.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<MerchantOrderModel> getMerchantOrderDetail(String orderId) async {
    final response =
        await _apiClient.get(ApiEndpoints.merchantOrderDetail(orderId));
    final data = response.data is Map ? response.data['data'] : null;
    if (data is! Map) {
      throw StateError('تعذر تحميل تفاصيل الطلب');
    }
    return MerchantOrderModel.fromMap(Map<String, dynamic>.from(data));
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
    String? note,
  }) async {
    await _apiClient.patch(
      ApiEndpoints.merchantOrderStatus(orderId),
      data: {
        'status': status,
        if ((note ?? '').trim().isNotEmpty) 'note': note!.trim(),
      },
    );
  }

  Future<void> rejectOrder({
    required String orderId,
    required String reason,
  }) {
    return updateOrderStatus(
      orderId: orderId,
      status: 'REJECTED',
      note: reason,
    );
  }

  Future<Map<String, dynamic>> getOrderInvoice(String orderId) async {
    final response =
        await _apiClient.get(ApiEndpoints.merchantOrderInvoice(orderId));
    final data = response.data is Map ? response.data['data'] : null;
    if (data is! Map) {
      throw StateError('تعذر تحميل فاتورة الطلب');
    }
    return Map<String, dynamic>.from(data);
  }

  Future<MerchantInventoryModel> getMerchantInventory({
    String? branchId,
    String? status,
    String? query,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.merchantInventory,
      queryParameters: {
        if ((branchId ?? '').isNotEmpty &&
            branchId != 'all' &&
            int.tryParse(branchId!) != null)
          'branchId': branchId,
        if ((branchId ?? '').isNotEmpty &&
            branchId != 'all' &&
            int.tryParse(branchId!) == null)
          'branchPublicId': branchId,
        if ((status ?? '').isNotEmpty && status != 'all') 'status': status,
        if ((query ?? '').isNotEmpty) 'search': query,
      },
    );
    final data = response.data is Map ? response.data['data'] : null;
    if (data is! Map) {
      throw StateError('تعذر تحميل بيانات المخزون');
    }
    return MerchantInventoryModel.fromMap(Map<String, dynamic>.from(data));
  }

  Future<void> updateInventoryQuantity({
    required String listingId,
    String? inventoryId,
    required String type,
    required int quantity,
    int? reorderLevel,
    String? note,
  }) async {
    final organizationId = await getMerchantOrganizationId();
    if ((organizationId ?? '').isEmpty) {
      throw StateError('لا توجد مؤسسة تاجر مرتبطة بالحساب');
    }
    await _apiClient.post(
      ApiEndpoints.merchantInventoryAdjust(organizationId!),
      data: {
        if ((inventoryId ?? '').isNotEmpty) 'inventoryId': inventoryId,
        if (int.tryParse(listingId) != null) 'listingId': int.parse(listingId),
        'type': type,
        'quantity': quantity,
        if (reorderLevel != null) 'reorderLevel': reorderLevel,
        if ((note ?? '').trim().isNotEmpty) 'note': note!.trim(),
      },
    );
  }

  Future<void> setInventoryReorderLevel({
    required String inventoryId,
    required int reorderLevel,
  }) async {
    await _apiClient.patch(
      ApiEndpoints.merchantInventoryReorderLevel(inventoryId),
      data: {'reorderLevel': reorderLevel},
    );
  }

  Future<List<MerchantInventoryMovement>> getInventoryMovements(
      String inventoryId) async {
    final response = await _apiClient
        .get(ApiEndpoints.merchantInventoryMovements(inventoryId));
    final data = response.data is Map ? response.data['data'] : null;
    final items = data is List ? data : const <dynamic>[];
    return items
        .whereType<Map>()
        .map((item) =>
            MerchantInventoryMovement.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> transferInventory({
    required String inventoryId,
    required String listingId,
    String? fromBranchId,
    required String toBranchId,
    required int quantity,
    String? note,
  }) async {
    final organizationId = await getMerchantOrganizationId();
    if ((organizationId ?? '').isEmpty) {
      throw StateError('لا توجد مؤسسة تاجر مرتبطة بالحساب');
    }
    await _apiClient.post(
      ApiEndpoints.merchantInventoryTransfer(organizationId!),
      data: {
        'inventoryId': inventoryId,
        if (int.tryParse(listingId) != null) 'listingId': int.parse(listingId),
        if ((fromBranchId ?? '').isNotEmpty) 'fromBranchId': fromBranchId,
        'toBranchId': toBranchId,
        'quantity': quantity,
        if ((note ?? '').trim().isNotEmpty) 'note': note!.trim(),
      },
    );
  }

  Future<List<CatalogCategory>> getCategories() async {
    final response = await _apiClient.get(ApiEndpoints.catalogCategories);
    final data = response.data is Map ? response.data['data'] : null;
    final items = data is List ? data : const <dynamic>[];
    return items
        .whereType<Map>()
        .map(
            (item) => CatalogCategory.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<ProductModel>> getProducts({String? categoryId}) async {
    final response = await _apiClient.get(
      ApiEndpoints.catalogProducts,
      queryParameters: {
        if ((categoryId ?? '').isNotEmpty) 'categoryId': categoryId,
      },
    );
    final data = response.data is Map ? response.data['data'] : null;
    final items = data is Map ? data['items'] : null;
    final list = items is List ? items : const <dynamic>[];
    return list
        .whereType<Map>()
        .map((item) => ProductModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<MerchantLookupItem>> getPartBrands() async {
    final response = await _apiClient.get(ApiEndpoints.catalogBrands);
    final data = response.data is Map ? response.data['data'] : null;
    final items = data is List ? data : const <dynamic>[];
    return items
        .whereType<Map>()
        .map((item) =>
            MerchantLookupItem.fromMap(Map<String, dynamic>.from(item)))
        .where((item) => item.id.isNotEmpty && item.name.isNotEmpty)
        .toList();
  }

  Future<List<MerchantLookupItem>> getMerchantBranches() async {
    final response = await _apiClient.get(ApiEndpoints.merchantBranches);
    if (kDebugMode) {
      debugPrint(
          'Merchant branches endpoint: ${ApiEndpoints.merchantBranches}');
      debugPrint('Merchant branches statusCode: ${response.statusCode}');
      debugPrint('Merchant branches response body: ${response.data}');
    }
    final data = response.data is Map ? response.data['data'] : response.data;
    final items = data is List ? data : const <dynamic>[];
    final branches = items
        .whereType<Map>()
        .map((item) =>
            MerchantLookupItem.fromMap(Map<String, dynamic>.from(item)))
        .where((item) => item.id.isNotEmpty && item.name.isNotEmpty)
        .toList();
    if (kDebugMode) {
      debugPrint('Merchant branches parsed count: ${branches.length}');
    }
    return branches;
  }

  Future<List<MerchantBranchManagementItem>>
      getMerchantBranchManagement() async {
    final response = await _apiClient.get(ApiEndpoints.merchantBranches);
    final data = response.data is Map ? response.data['data'] : response.data;
    final items = data is List ? data : const <dynamic>[];
    return items
        .whereType<Map>()
        .map((item) => MerchantBranchManagementItem.fromMap(
              Map<String, dynamic>.from(item),
            ))
        .where((item) => item.id.isNotEmpty)
        .toList();
  }

  Future<List<MerchantLookupItem>> getVehicleMakes() async {
    final response = await _apiClient.get(ApiEndpoints.vehicleMakes);
    final data = response.data is Map ? response.data['data'] : null;
    final items = data is List ? data : const <dynamic>[];
    return items
        .whereType<Map>()
        .map((item) =>
            MerchantLookupItem.fromMap(Map<String, dynamic>.from(item)))
        .where((item) => item.id.isNotEmpty && item.name.isNotEmpty)
        .toList();
  }

  Future<List<MerchantLookupItem>> getVehicleModels(String makeId) async {
    final response = await _apiClient.get(
      ApiEndpoints.vehicleModels,
      queryParameters: {'makeId': int.parse(makeId)},
    );
    final data = response.data is Map ? response.data['data'] : null;
    final items = data is List ? data : const <dynamic>[];
    return items
        .whereType<Map>()
        .map((item) =>
            MerchantLookupItem.fromMap(Map<String, dynamic>.from(item)))
        .where((item) => item.id.isNotEmpty && item.name.isNotEmpty)
        .toList();
  }

  Future<String> uploadMerchantProductImage({
    required List<int> bytes,
    required String fileName,
    required String mimeType,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.merchantProductImages,
      data: {
        'fileName': fileName,
        'mimeType': mimeType,
        'imageBase64': base64Encode(bytes),
      },
    );
    final data = response.data is Map ? response.data['data'] : null;
    if (data is! Map || data['imageUrl'] == null) {
      throw StateError('تعذر رفع صورة المنتج');
    }
    return data['imageUrl'].toString();
  }

  Future<MerchantProductLookupResult?> lookupProductByCode(String code) async {
    final cleanCode = code.trim();
    if (cleanCode.isEmpty) return null;

    Future<MerchantProductLookupResult?> request(Map<String, dynamic> query) async {
      final response = await _apiClient.get(
        ApiEndpoints.catalogProducts,
        queryParameters: query,
      );
      if (kDebugMode) {
        debugPrint('Catalog lookup endpoint: ${ApiEndpoints.catalogProducts}');
        debugPrint('Catalog lookup query keys: ${query.keys.toList()}');
        debugPrint('Catalog lookup status: ${response.statusCode}');
      }
      final root = response.data is Map ? response.data['data'] : response.data;
      final items = root is Map
          ? (root['items'] is List ? root['items'] as List : const <dynamic>[])
          : root is List
              ? root
              : const <dynamic>[];
      for (final item in items.whereType<Map>()) {
        final map = Map<String, dynamic>.from(item);
        final sku = (map['sku'] ?? '').toString().trim().toLowerCase();
        final oem = (map['oemNumber'] ?? map['oem_number'] ?? '').toString().trim().toLowerCase();
        final aftermarket = (map['aftermarketCode'] ?? map['aftermarket_code'] ?? '').toString().trim().toLowerCase();
        final wanted = cleanCode.toLowerCase();
        if (sku == wanted || oem == wanted || aftermarket == wanted || items.length == 1) {
          return MerchantProductLookupResult.fromMap(map);
        }
      }
      return null;
    }

    try {
      return await request({'partNumber': cleanCode}) ??
          await request({'q': cleanCode, 'limit': 10});
    } catch (error) {
      if (kDebugMode) debugPrint('Catalog lookup failed: $error');
      return null;
    }
  }

  String _slugifyProduct(String name, String? sku) {
    final source = [name, if ((sku ?? '').trim().isNotEmpty) sku!.trim()]
        .join(' ')
        .trim()
        .toLowerCase();
    final slug = source
        .replaceAll(RegExp(r'[^\u0600-\u06FFa-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    final fallback = DateTime.now().millisecondsSinceEpoch.toString();
    return slug.isEmpty ? 'product-$fallback' : slug;
  }

  Future<String?> _findCatalogProductIdByCode(String code) async {
    if (code.trim().isEmpty) return null;
    final lookup = await lookupProductByCode(code);
    return lookup?.productId;
  }

  Future<String> _createCatalogProduct({
    required String nameAr,
    required String categoryId,
    String? partNumber,
    String? partBrandId,
    String? description,
    List<String> imageUrls = const [],
    List<Map<String, dynamic>> compatibilities = const [],
  }) async {
    final cleanPartNumber = (partNumber ?? '').trim();
    final media = imageUrls
        .where((url) => url.trim().isNotEmpty)
        .map((url) => {
              'mediaUrl': url.trim(),
              'mediaType': 'IMAGE',
              'altText': nameAr.trim(),
            })
        .toList();
    final requestBody = <String, dynamic>{
      'categoryId': int.parse(categoryId),
      if ((partBrandId ?? '').trim().isNotEmpty)
        'partBrandId': int.parse(partBrandId!.trim()),
      'nameAr': nameAr.trim(),
      'slug': _slugifyProduct(nameAr, cleanPartNumber),
      if (cleanPartNumber.isNotEmpty) 'sku': cleanPartNumber,
      if (cleanPartNumber.isNotEmpty) 'oemNumber': cleanPartNumber,
      if ((description ?? '').trim().isNotEmpty) 'description': description!.trim(),
      'isUniversal': compatibilities.isEmpty,
      if (media.isNotEmpty) 'media': media,
      if (compatibilities.isNotEmpty) 'compatibilities': compatibilities,
    };
    if (kDebugMode) {
      debugPrint('Create catalog product endpoint: ${ApiEndpoints.catalogProducts}');
      debugPrint('Create catalog product payload keys: ${requestBody.keys.toList()}');
    }
    final response = await _apiClient.post(
      ApiEndpoints.catalogProducts,
      data: requestBody,
    );
    final data = response.data is Map ? response.data['data'] : null;
    if (data is! Map || data['id'] == null) {
      throw StateError('تم إنشاء المنتج في الكتالوج دون إرجاع معرّفه');
    }
    return data['id'].toString();
  }

  Future<String> createMerchantProduct({
    required String nameAr,
    required String categoryId,
    required String partNumber,
    String? countryOfOrigin,
    String? compatibilityText,
    String? partBrandId,
    String? branchId,
    int minOrderQuantity = 1,
    List<Map<String, dynamic>> compatibilities = const [],
    String? description,
    required double unitPrice,
    double? salePrice,
    required int availableQuantity,
    int? warrantyDays,
    String condition = 'NEW',
    bool supportsPickup = true,
    bool supportsDelivery = false,
    List<String> imageUrls = const [],
    bool publish = false,
    String? existingProductId,
  }) async {
    final organizationId = await requireMerchantOrganizationId();
    final cleanPartNumber = partNumber.trim();
    final normalizedCompatibilities = compatibilities
        .where((item) => item.isNotEmpty)
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    String? productId = (existingProductId ?? '').trim().isEmpty
        ? null
        : existingProductId!.trim();
    productId ??= await _findCatalogProductIdByCode(cleanPartNumber);
    productId ??= await _createCatalogProduct(
      nameAr: nameAr,
      categoryId: categoryId,
      partBrandId: partBrandId,
      partNumber: cleanPartNumber,
      description: description,
      imageUrls: imageUrls,
      compatibilities: normalizedCompatibilities,
    );

    final numericOrganizationId = int.tryParse(organizationId);
    final requestBody = <String, dynamic>{
      'productId': int.parse(productId),
      if (numericOrganizationId != null)
        'organizationId': numericOrganizationId,
      if (numericOrganizationId == null)
        'organizationPublicId': organizationId,
      if ((branchId ?? '').trim().isNotEmpty && branchId != 'all')
        'branchId': int.parse(branchId!.trim()),
      'title': nameAr.trim(),
      if ((description ?? '').trim().isNotEmpty) 'description': description!.trim(),
      'condition': condition,
      'qualityType': 'AFTERMARKET',
      'unitPrice': unitPrice,
      if (salePrice != null) 'salePrice': salePrice,
      'currency': 'YER',
      'availableQuantity': availableQuantity,
      'minOrderQuantity': minOrderQuantity,
      if (warrantyDays != null) 'warrantyDays': warrantyDays,
      'supportsPickup': supportsPickup,
      'supportsDelivery': supportsDelivery,
    };
    if (kDebugMode) {
      debugPrint('Create listing endpoint: ${ApiEndpoints.merchantListings}');
      debugPrint('Create listing payload keys: ${requestBody.keys.toList()}');
      debugPrint('Create listing productId: $productId');
      debugPrint('Create listing organizationId exists: ${organizationId.isNotEmpty}');
      debugPrint('Create listing branchId: $branchId');
      debugPrint('Create listing condition: $condition');
      debugPrint('Create listing publish: $publish');
    }
    final response = await _apiClient.post(
      ApiEndpoints.merchantListings,
      data: requestBody,
    );
    final data = response.data is Map ? response.data['data'] : null;
    if (data is! Map || data['id'] == null) {
      throw StateError('تم حفظ المنتج دون إرجاع معرفه');
    }
    final listingId = data['id'].toString();
    if (publish) {
      try {
        await updateListingStatus(listingId: listingId, status: 'ACTIVE');
      } catch (error) {
        if (kDebugMode) debugPrint('Publish after create failed: $error');
        rethrow;
      }
    }
    return listingId;
  }

  Future<String> createListing({
    required String productId,
    required String organizationId,
    String? title,
    String? description,
    double price = 0,
    double? salePrice,
    int quantity = 0,
    int? warrantyDays,
    String? condition,
    bool supportsPickup = true,
    bool supportsDelivery = false,
  }) async {
    final orgId = int.tryParse(organizationId);
    final response = await _apiClient.post(
      ApiEndpoints.merchantListings,
      data: {
        'productId': int.parse(productId),
        ...(orgId != null
            ? {'organizationId': orgId}
            : {'organizationPublicId': organizationId}),
        'title': title ?? 'Listing',
        'description': description,
        'condition': condition,
        'unitPrice': price,
        'salePrice': salePrice,
        'currency': 'YER',
        'availableQuantity': quantity,
        'warrantyDays': warrantyDays,
        'supportsPickup': supportsPickup,
        'supportsDelivery': supportsDelivery,
      },
    );
    final data = response.data is Map ? response.data['data'] : null;
    if (data is! Map || data['id'] == null) {
      throw StateError('تم إنشاء العرض دون إرجاع معرّفه');
    }
    return data['id'].toString();
  }

  Future<String?> getMerchantOrganizationId() async {
    final response = await _apiClient.get(ApiEndpoints.organizationsMine);
    final data = response.data is Map ? response.data['data'] : null;
    final organizations = data is List ? data : const <dynamic>[];
    for (final item in organizations.whereType<Map>()) {
      final type = (item['organization_type'] ?? item['organizationType'])?.toString();
      if (type == 'MERCHANT') {
        return item['id']?.toString();
      }
    }
    return null;
  }

  Future<String> requireMerchantOrganizationId() async {
    final organizationId = await getMerchantOrganizationId();
    if ((organizationId ?? '').isEmpty) {
      throw StateError('لا توجد مؤسسة تاجر مرتبطة بالحساب');
    }
    return organizationId!;
  }

  Future<MerchantOrganizationModel> getMerchantOrganization() async {
    final organizationId = await getMerchantOrganizationId();
    if ((organizationId ?? '').isEmpty) {
      throw StateError('لا توجد مؤسسة تاجر مرتبطة بالحساب');
    }
    final response = await _apiClient.get(
      ApiEndpoints.organizationDetail(organizationId!),
    );
    final data = response.data is Map ? response.data['data'] : null;
    if (data is! Map) {
      throw StateError('تعذر تحميل بيانات المؤسسة');
    }
    return MerchantOrganizationModel.fromMap(
      Map<String, dynamic>.from(data),
    );
  }

  Map<String, dynamic> _branchPayload({
    required String branchName,
    required int cityId,
    String? email,
    String? phone,
    String? addressLine1,
    bool supportsPickup = true,
    bool supportsDelivery = false,
    bool supportsInstallation = false,
    bool supportsMobileService = false,
    bool isHeadOffice = false,
    double? latitude,
    double? longitude,
  }) {
    return {
      'branchName': branchName.trim(),
      'cityId': cityId,
      if ((email ?? '').trim().isNotEmpty) 'email': email!.trim(),
      if ((phone ?? '').trim().isNotEmpty) 'phone': phone!.trim(),
      if ((addressLine1 ?? '').trim().isNotEmpty)
        'addressLine1': addressLine1!.trim(),
      'supportsPickup': supportsPickup,
      'supportsDelivery': supportsDelivery,
      'supportsInstallation': supportsInstallation,
      'supportsMobileService': supportsMobileService,
      'isHeadOffice': isHeadOffice,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }

  Future<void> createBranch({
    required String organizationId,
    required String branchName,
    required int cityId,
    String? email,
    String? phone,
    String? addressLine1,
    bool supportsPickup = true,
    bool supportsDelivery = false,
    bool supportsInstallation = false,
    bool supportsMobileService = false,
    bool isHeadOffice = false,
    double? latitude,
    double? longitude,
    List<Map<String, dynamic>> businessHours = const [],
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.organizationBranches(organizationId),
      data: _branchPayload(
        branchName: branchName,
        cityId: cityId,
        email: email,
        phone: phone,
        addressLine1: addressLine1,
        supportsPickup: supportsPickup,
        supportsDelivery: supportsDelivery,
        supportsInstallation: supportsInstallation,
        supportsMobileService: supportsMobileService,
        isHeadOffice: isHeadOffice,
        latitude: latitude,
        longitude: longitude,
      ),
    );
    final data = response.data is Map ? response.data['data'] : null;
    final branchId = data is Map ? data['id']?.toString() : null;
    if ((branchId ?? '').isNotEmpty && businessHours.isNotEmpty) {
      await updateBranchBusinessHours(
        organizationId: organizationId,
        branchId: branchId!,
        items: businessHours,
      );
    }
  }

  Future<MerchantBranchModel> getBranch({
    required String organizationId,
    required String branchId,
  }) async {
    final response = await _apiClient
        .get(ApiEndpoints.organizationBranch(organizationId, branchId));
    final data = response.data is Map ? response.data['data'] : null;
    if (data is! Map) throw StateError('تعذر تحميل بيانات الفرع');
    return MerchantBranchModel.fromMap(Map<String, dynamic>.from(data));
  }

  Future<void> updateMerchantBranch({
    required String branchId,
    required String branchName,
    int? cityId,
    int? districtId,
    String? email,
    String? phone,
    String? addressLine1,
    bool supportsPickup = true,
    bool supportsDelivery = false,
    bool supportsInstallation = false,
    bool supportsMobileService = false,
    bool isHeadOffice = false,
    double? latitude,
    double? longitude,
    List<Map<String, dynamic>> businessHours = const [],
  }) async {
    final organizationId = await requireMerchantOrganizationId();
    await _apiClient.patch(
      ApiEndpoints.organizationBranch(organizationId, branchId),
      data: {
        'name': branchName.trim(),
        'branchName': branchName.trim(),
        if (cityId != null) 'cityId': cityId,
        if (districtId != null) 'districtId': districtId,
        if ((email ?? '').trim().isNotEmpty) 'email': email!.trim(),
        if ((phone ?? '').trim().isNotEmpty) 'phone': phone!.trim(),
        if ((addressLine1 ?? '').trim().isNotEmpty)
          'addressLine1': addressLine1!.trim(),
        'supportsPickup': supportsPickup,
        'supportsDelivery': supportsDelivery,
        'supportsInstallation': supportsInstallation,
        'supportsMobileService': supportsMobileService,
        'isHeadOffice': isHeadOffice,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      },
    );
    if (businessHours.isNotEmpty) {
      await updateBranchBusinessHours(
        organizationId: organizationId,
        branchId: branchId,
        items: businessHours,
      );
    }
  }

  Future<void> updateBranch({
    required String organizationId,
    required String branchId,
    required String branchName,
    required int cityId,
    String? email,
    String? phone,
    String? addressLine1,
    bool supportsPickup = true,
    bool supportsDelivery = false,
    bool supportsInstallation = false,
    bool supportsMobileService = false,
    bool isHeadOffice = false,
    double? latitude,
    double? longitude,
    List<Map<String, dynamic>> businessHours = const [],
  }) async {
    await _apiClient.patch(
      ApiEndpoints.organizationBranch(organizationId, branchId),
      data: _branchPayload(
        branchName: branchName,
        cityId: cityId,
        email: email,
        phone: phone,
        addressLine1: addressLine1,
        supportsPickup: supportsPickup,
        supportsDelivery: supportsDelivery,
        supportsInstallation: supportsInstallation,
        supportsMobileService: supportsMobileService,
        isHeadOffice: isHeadOffice,
        latitude: latitude,
        longitude: longitude,
      ),
    );
    if (businessHours.isNotEmpty) {
      await updateBranchBusinessHours(
        organizationId: organizationId,
        branchId: branchId,
        items: businessHours,
      );
    }
  }

  Future<void> updateBranchBusinessHours({
    required String organizationId,
    required String branchId,
    required List<Map<String, dynamic>> items,
  }) async {
    await _apiClient.put(
      ApiEndpoints.organizationBranchBusinessHours(organizationId, branchId),
      data: {'items': items},
    );
  }

  Future<void> closeBranchTemporarily({
    required String organizationId,
    required String branchId,
  }) async {
    await _apiClient.put(
      ApiEndpoints.organizationBranchBusinessHours(organizationId, branchId),
      data: {
        'items': List.generate(
            7,
            (index) => {
                  'dayOfWeek': index,
                  'isClosed': true,
                }),
      },
    );
  }

  Future<void> deleteBranch({
    required String organizationId,
    required String branchId,
  }) async {
    await _apiClient
        .delete(ApiEndpoints.organizationBranch(organizationId, branchId));
  }

  Future<void> updateVacationMode({
    required String organizationId,
    required bool enabled,
  }) async {
    await _apiClient.patch(
      ApiEndpoints.organizationDetail(organizationId),
      data: {'isVacationMode': enabled},
    );
  }

  Future<void> updateMerchantOrganization({
    required String organizationId,
    required String displayName,
    String? legalName,
    String? primaryPhone,
    String? contactEmail,
    String? whatsappPhone,
    String? commercialRegistration,
    String? logoUrl,
    String? coverUrl,
    String? vacationMessage,
  }) async {
    await _apiClient.patch(
      ApiEndpoints.organizationDetail(organizationId),
      data: {
        'displayName': displayName.trim(),
        if ((legalName ?? '').trim().isNotEmpty) 'legalName': legalName!.trim(),
        if ((primaryPhone ?? '').trim().isNotEmpty)
          'primaryPhone': primaryPhone!.trim(),
        if ((contactEmail ?? '').trim().isNotEmpty)
          'contactEmail': contactEmail!.trim(),
        if ((whatsappPhone ?? '').trim().isNotEmpty)
          'whatsappPhone': whatsappPhone!.trim(),
        if ((commercialRegistration ?? '').trim().isNotEmpty)
          'commercialRegistration': commercialRegistration!.trim(),
        if ((logoUrl ?? '').trim().isNotEmpty) 'logoUrl': logoUrl!.trim(),
        if ((coverUrl ?? '').trim().isNotEmpty) 'coverUrl': coverUrl!.trim(),
        if ((vacationMessage ?? '').trim().isNotEmpty)
          'vacationMessage': vacationMessage!.trim(),
      },
    );
  }

  Future<void> updateMerchantPolicies({
    required String organizationId,
    String? businessCategoryCode,
    int? averagePreparationMinutes,
    String? warrantyPolicyText,
    String? returnPolicyText,
    String? deliveryPolicyText,
    double? minOrderAmount,
  }) async {
    await _apiClient.post(
      ApiEndpoints.organizationMerchantProfile(organizationId),
      data: {
        if ((businessCategoryCode ?? '').trim().isNotEmpty)
          'businessCategoryCode': businessCategoryCode!.trim(),
        if (averagePreparationMinutes != null)
          'averagePreparationMinutes': averagePreparationMinutes,
        if (warrantyPolicyText != null)
          'warrantyPolicyText': warrantyPolicyText.trim(),
        if (returnPolicyText != null)
          'returnPolicyText': returnPolicyText.trim(),
        if (deliveryPolicyText != null)
          'deliveryPolicyText': deliveryPolicyText.trim(),
        if (minOrderAmount != null) 'minOrderAmount': minOrderAmount,
      },
    );
  }

  Future<MerchantReadinessModel> getMerchantReadiness() async {
    final organizationId = await getMerchantOrganizationId();
    if ((organizationId ?? '').isEmpty) {
      throw StateError('لا توجد مؤسسة تاجر مرتبطة بالحساب');
    }
    final response = await _apiClient
        .get(ApiEndpoints.organizationReadiness(organizationId!));
    final data = response.data is Map ? response.data['data'] : response.data;
    if (data is! Map) throw StateError('تعذر تحميل جاهزية المتجر');
    return MerchantReadinessModel.fromMap(Map<String, dynamic>.from(data));
  }

  Future<List<MerchantBankAccountModel>> getBankAccounts() async {
    final organizationId = await getMerchantOrganizationId();
    if ((organizationId ?? '').isEmpty) {
      throw StateError('لا توجد مؤسسة تاجر مرتبطة بالحساب');
    }
    final response = await _apiClient
        .get(ApiEndpoints.organizationBankAccounts(organizationId!));
    final data = response.data is Map ? response.data['data'] : response.data;
    final items = data is List ? data : const <dynamic>[];
    return items
        .whereType<Map>()
        .map((e) =>
            MerchantBankAccountModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> createBankAccount({
    required String bankName,
    required String accountName,
    required String accountNumber,
    String? iban,
    bool isPrimary = false,
  }) async {
    final organizationId = await getMerchantOrganizationId();
    if ((organizationId ?? '').isEmpty) {
      throw StateError('لا توجد مؤسسة تاجر مرتبطة بالحساب');
    }
    await _apiClient.post(
      ApiEndpoints.organizationBankAccounts(organizationId!),
      data: {
        'bankName': bankName.trim(),
        'accountName': accountName.trim(),
        'accountNumber': accountNumber.trim(),
        if ((iban ?? '').trim().isNotEmpty) 'iban': iban!.trim(),
        'isPrimary': isPrimary,
      },
    );
  }

  Future<void> deleteBankAccount(String bankId) async {
    final organizationId = await getMerchantOrganizationId();
    if ((organizationId ?? '').isEmpty) {
      throw StateError('لا توجد مؤسسة تاجر مرتبطة بالحساب');
    }
    await _apiClient
        .delete(ApiEndpoints.organizationBankAccount(organizationId!, bankId));
  }

  Future<MerchantVerificationRequestModel> getVerificationRequest(
      String requestId) async {
    final response =
        await _apiClient.get(ApiEndpoints.verificationRequest(requestId));
    final data = response.data is Map ? response.data['data'] : response.data;
    if (data is! Map) throw StateError('تعذر تحميل طلب التوثيق');
    return MerchantVerificationRequestModel.fromMap(
        Map<String, dynamic>.from(data));
  }

  Future<void> addVerificationDocument({
    required String requestId,
    required String documentType,
    required String fileName,
    required String fileUrl,
    String? mimeType,
    String? notes,
  }) async {
    await _apiClient.post(
      ApiEndpoints.verificationRequestDocuments(requestId),
      data: {
        'documentType': documentType,
        'fileName': fileName.trim(),
        'fileUrl': fileUrl.trim(),
        if ((mimeType ?? '').trim().isNotEmpty) 'mimeType': mimeType!.trim(),
        if ((notes ?? '').trim().isNotEmpty) 'notes': notes!.trim(),
      },
    );
  }

  Future<List<Map<String, dynamic>>> getOrganizationRoles() async {
    final organizationId = await getMerchantOrganizationId();
    if ((organizationId ?? '').isEmpty) {
      throw StateError('لا توجد مؤسسة تاجر مرتبطة بالحساب');
    }
    final response =
        await _apiClient.get(ApiEndpoints.organizationRoles(organizationId!));
    final data = response.data is Map ? response.data['data'] : response.data;
    final items = data is List ? data : const <dynamic>[];
    return items
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> createOrganizationRole({
    required String code,
    required String name,
    String? description,
    List<String> permissionCodes = const [],
  }) async {
    final organizationId = await getMerchantOrganizationId();
    if ((organizationId ?? '').isEmpty) {
      throw StateError('لا توجد مؤسسة تاجر مرتبطة بالحساب');
    }
    await _apiClient.post(
      ApiEndpoints.organizationRoles(organizationId!),
      data: {
        'code': code.trim(),
        'name': name.trim(),
        if ((description ?? '').trim().isNotEmpty)
          'description': description!.trim(),
        'isSystem': false,
        'permissionCodes': permissionCodes,
      },
    );
  }

  Future<List<Map<String, dynamic>>> getEmployeeInvitations() async {
    final organizationId = await getMerchantOrganizationId();
    if ((organizationId ?? '').isEmpty) {
      throw StateError('لا توجد مؤسسة تاجر مرتبطة بالحساب');
    }
    final response = await _apiClient.get(
      ApiEndpoints.organizationInvitations(organizationId!),
    );
    final data = response.data is Map ? response.data['data'] : response.data;
    final items = data is List ? data : const <dynamic>[];
    return items
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> inviteEmployee({
    String? phone,
    String? email,
    String? memberRole,
  }) async {
    final organizationId = await getMerchantOrganizationId();
    if ((organizationId ?? '').isEmpty) {
      throw StateError('لا توجد مؤسسة تاجر مرتبطة بالحساب');
    }
    await _apiClient.post(
      ApiEndpoints.organizationInvitations(organizationId!),
      data: {
        if ((phone ?? '').trim().isNotEmpty) 'phone': phone!.trim(),
        if ((email ?? '').trim().isNotEmpty) 'email': email!.trim(),
        if ((memberRole ?? '').trim().isNotEmpty)
          'memberRole': memberRole!.trim(),
      },
    );
  }

  Future<void> updateMemberPermissions({
    required String memberId,
    required List<String> permissionCodes,
  }) async {
    final organizationId = await getMerchantOrganizationId();
    if ((organizationId ?? '').isEmpty) {
      throw StateError('لا توجد مؤسسة تاجر مرتبطة بالحساب');
    }
    await _apiClient.put(
      ApiEndpoints.organizationMemberPermissions(organizationId!, memberId),
      data: {'permissionCodes': permissionCodes},
    );
  }

  Future<void> updateOrganizationRole({
    required String roleId,
    required String code,
    required String name,
    String? description,
    List<String> permissionCodes = const [],
  }) async {
    final organizationId = await getMerchantOrganizationId();
    if ((organizationId ?? '').isEmpty) {
      throw StateError('لا توجد مؤسسة تاجر مرتبطة بالحساب');
    }
    await _apiClient.patch(
      ApiEndpoints.organizationRole(organizationId!, roleId),
      data: {
        'code': code.trim(),
        'name': name.trim(),
        'description': description?.trim(),
        'permissionCodes': permissionCodes,
      },
    );
  }

  Future<void> deleteOrganizationRole(String roleId) async {
    final organizationId = await getMerchantOrganizationId();
    if ((organizationId ?? '').isEmpty) {
      throw StateError('لا توجد مؤسسة تاجر مرتبطة بالحساب');
    }
    await _apiClient
        .delete(ApiEndpoints.organizationRole(organizationId!, roleId));
  }

  Future<List<MerchantPermissionOptionModel>>
      getOrganizationPermissions() async {
    final organizationId = await getMerchantOrganizationId();
    if ((organizationId ?? '').isEmpty) {
      throw StateError('لا توجد مؤسسة تاجر مرتبطة بالحساب');
    }
    final response = await _apiClient
        .get(ApiEndpoints.organizationPermissions(organizationId!));
    final data = response.data is Map ? response.data['data'] : response.data;
    final items = data is List ? data : const <dynamic>[];
    return items
        .whereType<Map>()
        .map((item) => MerchantPermissionOptionModel.fromMap(
            Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> updateMemberStatus({
    required String memberId,
    required String status,
    String? memberRole,
  }) async {
    final organizationId = await getMerchantOrganizationId();
    if ((organizationId ?? '').isEmpty) {
      throw StateError('لا توجد مؤسسة تاجر مرتبطة بالحساب');
    }
    await _apiClient.patch(
      ApiEndpoints.organizationMember(organizationId!, memberId),
      data: {
        'status': status,
        if ((memberRole ?? '').trim().isNotEmpty)
          'memberRole': memberRole!.trim(),
      },
    );
  }

  Future<void> removeMember(String memberId) async {
    final organizationId = await getMerchantOrganizationId();
    if ((organizationId ?? '').isEmpty) {
      throw StateError('لا توجد مؤسسة تاجر مرتبطة بالحساب');
    }
    await _apiClient
        .delete(ApiEndpoints.organizationMember(organizationId!, memberId));
  }

  Future<void> updateMemberBranchAccess({
    required String memberId,
    required List<Map<String, dynamic>> items,
  }) async {
    final organizationId = await getMerchantOrganizationId();
    if ((organizationId ?? '').isEmpty) {
      throw StateError('لا توجد مؤسسة تاجر مرتبطة بالحساب');
    }
    await _apiClient.put(
      ApiEndpoints.organizationMemberBranchAccess(organizationId!, memberId),
      data: {'items': items},
    );
  }

  Future<void> cancelEmployeeInvitation(String invitationId) async {
    final organizationId = await getMerchantOrganizationId();
    if ((organizationId ?? '').isEmpty) {
      throw StateError('لا توجد مؤسسة تاجر مرتبطة بالحساب');
    }
    await _apiClient.delete(
        ApiEndpoints.organizationInvitation(organizationId!, invitationId));
  }

  Future<void> submitVerificationRequest({String? notes}) async {
    final organizationId = await getMerchantOrganizationId();
    if ((organizationId ?? '').isEmpty) {
      throw StateError('لا توجد مؤسسة تاجر مرتبطة بالحساب');
    }
    await _apiClient.post(
      ApiEndpoints.organizationVerificationRequests(organizationId!),
      data: {
        if ((notes ?? '').trim().isNotEmpty) 'notes': notes!.trim(),
      },
    );
  }

  Future<List<Map<String, dynamic>>> getAuditLogs({int limit = 50}) async {
    final organizationId = await getMerchantOrganizationId();
    if ((organizationId ?? '').isEmpty) {
      throw StateError('لا توجد مؤسسة تاجر مرتبطة بالحساب');
    }
    final response = await _apiClient.get(
      ApiEndpoints.organizationAuditLogs(organizationId!),
      queryParameters: {'limit': limit},
    );
    final data = response.data is Map ? response.data['data'] : response.data;
    final items = data is List ? data : const <dynamic>[];
    return items
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<List<MerchantTeamMemberModel>> getMerchantTeam() async {
    final organizationId = await getMerchantOrganizationId();
    if ((organizationId ?? '').isEmpty) {
      throw StateError('لا توجد مؤسسة تاجر مرتبطة بالحساب');
    }
    final response = await _apiClient.get(
      ApiEndpoints.organizationMembers(organizationId!),
    );
    final data = response.data is Map ? response.data['data'] : null;
    final items = data is List ? data : const <dynamic>[];
    return items
        .whereType<Map>()
        .map(
          (item) => MerchantTeamMemberModel.fromMap(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  Future<MerchantReportModel> getMerchantReport({
    String period = 'month',
    String type = 'overview',
    String? branchId,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.merchantReports,
      queryParameters: {
        'period': period,
        'type': type,
        if ((branchId ?? '').isNotEmpty && branchId != 'all')
          'branchId': branchId,
        if (dateFrom != null) 'dateFrom': dateFrom.toIso8601String(),
        if (dateTo != null) 'dateTo': dateTo.toIso8601String(),
      },
    );
    final data = response.data is Map ? response.data['data'] : null;
    if (data is! Map) {
      throw StateError('تعذر تحميل بيانات التقرير');
    }
    return MerchantReportModel.fromMap(Map<String, dynamic>.from(data));
  }

  Future<String> exportMerchantReportCsv({
    String period = 'month',
    String type = 'overview',
    String? branchId,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.merchantReportsExport,
      queryParameters: {
        'period': period,
        'type': type,
        'format': 'csv',
        if ((branchId ?? '').isNotEmpty && branchId != 'all')
          'branchId': branchId,
        if (dateFrom != null) 'dateFrom': dateFrom.toIso8601String(),
        if (dateTo != null) 'dateTo': dateTo.toIso8601String(),
      },
    );
    final data = response.data is Map ? response.data['data'] : null;
    if (data is Map && data['content'] != null)
      return data['content'].toString();
    if (response.data is String) return response.data.toString();
    throw StateError('تعذر تصدير التقرير');
  }

  Future<MerchantNotificationResult> getMerchantNotifications(
      {String? type, bool? unreadOnly}) async {
    final response = await _apiClient.get(
      ApiEndpoints.merchantNotifications,
      queryParameters: {
        if ((type ?? '').isNotEmpty) 'type': type,
        if (unreadOnly == true) 'unreadOnly': 'true',
      },
    );
    final data = response.data is Map ? response.data['data'] : null;
    if (data is! Map) {
      throw StateError('تعذر تحميل الإشعارات');
    }
    return MerchantNotificationResult.fromMap(
      Map<String, dynamic>.from(data),
    );
  }

  Future<MerchantReturnsResponse> getMerchantReturns({
    String? status,
    String? query,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.merchantReturns,
      queryParameters: {
        if ((status ?? '').isNotEmpty) 'status': status,
        if ((query ?? '').trim().isNotEmpty) 'q': query!.trim(),
      },
    );
    final data = response.data is Map
        ? Map<String, dynamic>.from(response.data)
        : {'data': response.data};
    return MerchantReturnsResponse.fromMap(data);
  }

  Future<MerchantReturnRequest> getMerchantReturnDetail(String id) async {
    final response =
        await _apiClient.get(ApiEndpoints.merchantReturnDetail(id));
    final data = response.data is Map ? response.data['data'] : response.data;
    return MerchantReturnRequest.fromMap(
        Map<String, dynamic>.from(data as Map));
  }

  Future<void> decideMerchantReturn({
    required String id,
    required String decision,
    String? note,
    bool restockOnReceive = true,
  }) async {
    await _apiClient.patch(
      ApiEndpoints.merchantReturnDecision(id),
      data: {
        'decision': decision,
        if ((note ?? '').trim().isNotEmpty) 'note': note!.trim(),
        'restockOnReceive': restockOnReceive,
      },
    );
  }

  Future<void> receiveMerchantReturn({
    required String id,
    String? note,
    bool restock = true,
  }) async {
    await _apiClient.patch(
      ApiEndpoints.merchantReturnReceive(id),
      data: {
        if ((note ?? '').trim().isNotEmpty) 'note': note!.trim(),
        'restock': restock,
      },
    );
  }

  Future<void> refundMerchantReturn({
    required String id,
    String? note,
  }) async {
    await _apiClient.patch(
      ApiEndpoints.merchantReturnRefund(id),
      data: {if ((note ?? '').trim().isNotEmpty) 'note': note!.trim()},
    );
  }

  Future<void> updateMerchantReturnStatus({
    required String id,
    required String status,
    String? note,
  }) async {
    await _apiClient.patch(
      ApiEndpoints.merchantReturnStatus(id),
      data: {
        'status': status,
        if ((note ?? '').trim().isNotEmpty) 'note': note!.trim(),
      },
    );
  }

  Future<MerchantDisputesResponse> getMerchantDisputes({
    String? status,
    String? query,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.merchantDisputes,
      queryParameters: {
        if ((status ?? '').isNotEmpty) 'status': status,
        if ((query ?? '').trim().isNotEmpty) 'q': query!.trim(),
      },
    );
    final data = response.data is Map
        ? Map<String, dynamic>.from(response.data)
        : {'data': response.data};
    return MerchantDisputesResponse.fromMap(data);
  }

  Future<MerchantDisputeCase> getMerchantDisputeDetail(String id) async {
    final response =
        await _apiClient.get(ApiEndpoints.merchantDisputeDetail(id));
    final data = response.data is Map ? response.data['data'] : response.data;
    return MerchantDisputeCase.fromMap(Map<String, dynamic>.from(data as Map));
  }

  Future<void> addMerchantDisputeMessage({
    required String id,
    required String message,
  }) async {
    await _apiClient.post(
      ApiEndpoints.merchantDisputeMessage(id),
      data: {'message': message.trim()},
    );
  }

  Future<void> resolveMerchantDispute({
    required String id,
    required String resolution,
    required String note,
  }) async {
    await _apiClient.patch(
      ApiEndpoints.merchantDisputeResolve(id),
      data: {'resolution': resolution, 'note': note.trim()},
    );
  }

  Future<void> updateMerchantDisputeStatus({
    required String id,
    required String status,
    String? note,
  }) async {
    await _apiClient.patch(
      ApiEndpoints.merchantDisputeStatus(id),
      data: {
        'status': status,
        if ((note ?? '').trim().isNotEmpty) 'note': note!.trim(),
      },
    );
  }

  Future<MerchantChatResponse> getMerchantSupportTickets({
    String? status,
    String? query,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.merchantSupportTickets,
      queryParameters: {
        if ((status ?? '').isNotEmpty) 'status': status,
        if ((query ?? '').trim().isNotEmpty) 'q': query!.trim(),
      },
    );
    final data = response.data is Map
        ? Map<String, dynamic>.from(response.data['data'] is Map
            ? response.data['data']
            : response.data)
        : <String, dynamic>{'tickets': response.data};
    return MerchantChatResponse.fromMap(data);
  }

  Future<MerchantChatTicket> getMerchantSupportTicketDetail(
      String ticketId) async {
    final response = await _apiClient
        .get(ApiEndpoints.merchantSupportTicketDetail(ticketId));
    final data = response.data is Map ? response.data['data'] : response.data;
    return MerchantChatTicket.fromMap(Map<String, dynamic>.from(data as Map));
  }

  Future<void> addMerchantTicketMessage({
    required String ticketId,
    required String message,
    String? attachmentUrl,
  }) async {
    await _apiClient.post(
      ApiEndpoints.merchantSupportTicketMessages(ticketId),
      data: {
        'message': message.trim(),
        if ((attachmentUrl ?? '').trim().isNotEmpty)
          'attachmentUrl': attachmentUrl!.trim(),
      },
    );
  }

  Future<void> markMerchantTicketRead(String ticketId) async {
    await _apiClient.patch(ApiEndpoints.merchantSupportTicketRead(ticketId));
  }

  Future<void> updateMerchantTicketStatus({
    required String ticketId,
    required String status,
    String? note,
  }) async {
    await _apiClient.patch(
      ApiEndpoints.merchantSupportTicketStatus(ticketId),
      data: {
        'status': status,
        if ((note ?? '').trim().isNotEmpty) 'note': note!.trim(),
      },
    );
  }

  Future<Map<String, List<Map<String, dynamic>>>> getMerchantReviews() async {
    final response = await _apiClient.get(ApiEndpoints.merchantReviews);
    final data = response.data is Map ? response.data['data'] : response.data;
    final map = data is Map ? Map<String, dynamic>.from(data) : {};
    return {
      'merchant': _mapList(map['merchant']),
      'products': _mapList(map['products']),
    };
  }

  Future<void> replyToMerchantReview({
    required String type,
    required String id,
    required String replyText,
  }) async {
    await _apiClient.post(
      ApiEndpoints.merchantReviewReply(type, id),
      data: {'replyText': replyText.trim()},
    );
  }

  Future<MerchantFinanceSummary> getMerchantFinanceSummary() async {
    final response = await _apiClient.get(ApiEndpoints.merchantFinanceSummary);
    final data = response.data is Map ? response.data['data'] : response.data;
    return MerchantFinanceSummary.fromMap(
      data is Map ? Map<String, dynamic>.from(data) : const <String, dynamic>{},
    );
  }

  Future<List<MerchantLedgerEntry>> getMerchantFinanceLedger() async {
    final response = await _apiClient.get(ApiEndpoints.merchantFinanceLedger);
    return _mapList(response.data).map(MerchantLedgerEntry.fromMap).toList();
  }

  Future<String> getMerchantFinanceStatementCsv() async {
    final response =
        await _apiClient.get(ApiEndpoints.merchantFinanceStatement);
    final data = response.data is Map ? response.data['data'] : response.data;
    if (data is Map && data['csv'] != null) return data['csv'].toString();
    return '';
  }

  Future<List<MerchantWallet>> getMerchantWallets() async {
    final response = await _apiClient.get(ApiEndpoints.merchantWallets);
    return _mapList(response.data).map(MerchantWallet.fromMap).toList();
  }

  Future<List<MerchantWalletTransaction>> getMerchantWalletTransactions(
      String walletId) async {
    final response =
        await _apiClient.get(ApiEndpoints.merchantWalletTransactions(walletId));
    return _mapList(response.data)
        .map(MerchantWalletTransaction.fromMap)
        .toList();
  }

  Future<void> requestMerchantWithdrawal({
    required num amount,
    String currency = 'YER',
    String? note,
  }) async {
    await _apiClient.post(
      ApiEndpoints.merchantWithdrawals,
      data: {
        'amount': amount,
        'currency': currency,
        if ((note ?? '').trim().isNotEmpty) 'note': note!.trim(),
      },
    );
  }

  Future<List<MerchantPayment>> getMerchantPayments() async {
    final response = await _apiClient.get(ApiEndpoints.merchantPayments);
    return _mapList(response.data).map(MerchantPayment.fromMap).toList();
  }

  Future<List<MerchantSettlement>> getMerchantSettlements() async {
    final response = await _apiClient.get(ApiEndpoints.merchantSettlements);
    return _mapList(response.data).map(MerchantSettlement.fromMap).toList();
  }

  Future<List<MerchantInvoice>> getMerchantInvoices() async {
    final response = await _apiClient.get(ApiEndpoints.merchantInvoices);
    return _mapList(response.data).map(MerchantInvoice.fromMap).toList();
  }

  Future<MerchantShipmentsResponse> getMerchantShipments({
    String? status,
    String? query,
    String? deliveryMethod,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.merchantShipments,
      queryParameters: {
        if ((status ?? '').trim().isNotEmpty && status != 'ALL')
          'status': status,
        if ((query ?? '').trim().isNotEmpty) 'q': query!.trim(),
        if ((deliveryMethod ?? '').trim().isNotEmpty && deliveryMethod != 'ALL')
          'deliveryMethod': deliveryMethod,
      },
    );
    final data = response.data is Map ? response.data['data'] : null;
    if (data is Map) {
      return MerchantShipmentsResponse.fromMap(Map<String, dynamic>.from(data));
    }
    if (data is List) {
      return MerchantShipmentsResponse.fromMap({'shipments': data});
    }
    return MerchantShipmentsResponse.fromMap(
        {'shipments': _mapList(response.data)});
  }

  Future<MerchantShipment> getMerchantShipmentDetail(String id) async {
    final response =
        await _apiClient.get(ApiEndpoints.merchantShipmentDetail(id));
    final data = response.data is Map ? response.data['data'] : null;
    if (data is! Map) throw StateError('تعذر تحميل تفاصيل الشحنة');
    return MerchantShipment.fromMap(Map<String, dynamic>.from(data));
  }

  Future<void> createMerchantShipment({
    required String orderId,
    String? deliveryMethodId,
    String? driverId,
    String? shippingCompanyId,
    String? trackingNumber,
    num? deliveryFee,
  }) async {
    await _apiClient.post(
      ApiEndpoints.merchantShipments,
      data: {
        'orderId': int.tryParse(orderId) ?? orderId,
        if ((deliveryMethodId ?? '').trim().isNotEmpty)
          'deliveryMethodId':
              int.tryParse(deliveryMethodId!.trim()) ?? deliveryMethodId.trim(),
        if ((driverId ?? '').trim().isNotEmpty)
          'driverId': int.tryParse(driverId!.trim()) ?? driverId.trim(),
        if ((shippingCompanyId ?? '').trim().isNotEmpty)
          'shippingCompanyId': int.tryParse(shippingCompanyId!.trim()) ??
              shippingCompanyId.trim(),
        if ((trackingNumber ?? '').trim().isNotEmpty)
          'trackingNumber': trackingNumber!.trim(),
        if (deliveryFee != null) 'deliveryFee': deliveryFee,
      },
    );
  }

  Future<void> assignMerchantShipment({
    required String id,
    String? driverId,
    String? shippingCompanyId,
    String? trackingNumber,
  }) async {
    await _apiClient.patch(
      ApiEndpoints.merchantShipmentAssign(id),
      data: {
        if ((driverId ?? '').trim().isNotEmpty)
          'driverId': int.tryParse(driverId!.trim()) ?? driverId.trim(),
        if ((shippingCompanyId ?? '').trim().isNotEmpty)
          'shippingCompanyId': int.tryParse(shippingCompanyId!.trim()) ??
              shippingCompanyId.trim(),
        if ((trackingNumber ?? '').trim().isNotEmpty)
          'trackingNumber': trackingNumber!.trim(),
      },
    );
  }

  Future<void> updateMerchantShipmentStatus({
    required String id,
    required String status,
    String? note,
    num? latitude,
    num? longitude,
  }) async {
    await _apiClient.patch(
      ApiEndpoints.merchantShipmentStatus(id),
      data: {
        'status': status,
        if ((note ?? '').trim().isNotEmpty) 'note': note!.trim(),
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      },
    );
  }

  Future<void> rescheduleMerchantShipment({
    required String id,
    required String scheduledAt,
    String? note,
  }) async {
    await _apiClient.patch(
      ApiEndpoints.merchantShipmentReschedule(id),
      data: {
        'scheduledAt': scheduledAt,
        if ((note ?? '').trim().isNotEmpty) 'note': note!.trim(),
      },
    );
  }

  Future<void> markMerchantNotificationRead(String key) async {
    await _apiClient.patch(
      ApiEndpoints.merchantNotificationRead,
      data: {'key': key},
    );
  }

  Future<void> markAllMerchantNotificationsRead() async {
    await _apiClient.patch(ApiEndpoints.merchantNotificationsReadAll);
  }

  Future<MerchantNotificationPreferences>
      getMerchantNotificationPreferences() async {
    final response =
        await _apiClient.get(ApiEndpoints.merchantNotificationPreferences);
    final data = response.data is Map ? response.data['data'] : response.data;
    if (data is Map)
      return MerchantNotificationPreferences.fromMap(
          Map<String, dynamic>.from(data));
    return MerchantNotificationPreferences.defaults();
  }

  Future<MerchantNotificationPreferences> updateMerchantNotificationPreferences(
    MerchantNotificationPreferences preferences,
  ) async {
    final response = await _apiClient.put(
      ApiEndpoints.merchantNotificationPreferences,
      data: preferences.toMap(),
    );
    final data = response.data is Map ? response.data['data'] : response.data;
    if (data is Map)
      return MerchantNotificationPreferences.fromMap(
          Map<String, dynamic>.from(data));
    return preferences;
  }

  Future<void> providerAction({
    required String orderId,
    required String action,
    String? notes,
  }) async {
    final status = switch (action) {
      'confirm' => 'CONFIRMED',
      'reject' => 'REJECTED',
      _ => 'PREPARING',
    };
    await _apiClient.patch(
      ApiEndpoints.merchantOrderStatus(orderId),
      data: {'status': status, 'note': notes},
    );
  }

  Future<void> updateMerchantListing({
    required String listingId,
    required String title,
    String? description,
    required double unitPrice,
    double? salePrice,
    required int availableQuantity,
    int? warrantyDays,
    String condition = 'NEW',
    bool supportsPickup = true,
    bool supportsDelivery = false,
    int minOrderQuantity = 1,
    String? imageUrl,
  }) {
    return updateListing(
      listingId: listingId,
      title: title,
      description: description,
      unitPrice: unitPrice,
      salePrice: salePrice,
      availableQuantity: availableQuantity,
      warrantyDays: warrantyDays,
      condition: condition,
      supportsPickup: supportsPickup,
      supportsDelivery: supportsDelivery,
      minOrderQuantity: minOrderQuantity,
      imageUrl: imageUrl,
    );
  }

  Future<void> updateListing({
    required String listingId,
    required String title,
    String? description,
    required double unitPrice,
    double? salePrice,
    required int availableQuantity,
    int? warrantyDays,
    String condition = 'NEW',
    bool supportsPickup = true,
    bool supportsDelivery = false,
    int minOrderQuantity = 1,
    String? imageUrl,
  }) async {
    await _apiClient.patch(
      ApiEndpoints.merchantListingDetail(listingId),
      data: {
        'title': title.trim(),
        'description': (description ?? '').trim(),
        'unitPrice': unitPrice,
        'salePrice': salePrice,
        'availableQuantity': availableQuantity,
        'minOrderQuantity': minOrderQuantity,
        if (warrantyDays != null) 'warrantyDays': warrantyDays,
        'condition': condition,
        'supportsPickup': supportsPickup,
        'supportsDelivery': supportsDelivery,
      },
    );
  }

  Future<void> updateListingStatus({
    required String listingId,
    required String status,
  }) async {
    await _apiClient.patch(
      ApiEndpoints.merchantListingStatus(listingId),
      data: {'status': status},
    );
  }
}

List<Map<String, dynamic>> _mapList(Object? responseData) {
  final data = responseData is Map ? responseData['data'] : responseData;
  final items = data is List ? data : const <dynamic>[];
  return items
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}
