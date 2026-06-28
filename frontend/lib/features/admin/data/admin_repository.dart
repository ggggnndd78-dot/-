import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/config/api_endpoints.dart';
import 'package:ghiyarak/core/network/api_client.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.watch(apiClientProvider));
});

class AdminRepository {
  final ApiClient _api;
  AdminRepository(this._api);

  Future<Map<String, dynamic>> controlCenter({String locale = 'ar'}) async {
    final res = await _api.get(ApiEndpoints.adminControlCenterData,
        queryParameters: {'locale': locale});
    return Map<String, dynamic>.from(res.data['data'] ?? {});
  }

  Future<Map<String, dynamic>> enterpriseAnalytics() async {
    final res = await _api.get(ApiEndpoints.adminEnterpriseAnalytics);
    return Map<String, dynamic>.from(res.data['data'] ?? {});
  }

  Future<Map<String, dynamic>> localization() async {
    final res = await _api.get(ApiEndpoints.adminLocalization);
    return Map<String, dynamic>.from(res.data['data'] ?? {});
  }

  Future<List<dynamic>> featureFlags() async {
    final res = await _api.get(ApiEndpoints.adminFeatureFlags);
    return List<dynamic>.from(res.data['data'] ?? []);
  }

  Future<Map<String, dynamic>> dashboardSummary() async {
    final res = await _api.get(ApiEndpoints.adminDashboardSummary);
    return Map<String, dynamic>.from(res.data['data'] ?? {});
  }

  Future<List<dynamic>> orderMetrics() async {
    final res = await _api.get(ApiEndpoints.adminAnalyticsOrders);
    return List<dynamic>.from(res.data['data'] ?? []);
  }

  Future<List<dynamic>> revenueDaily() async {
    final res = await _api.get(ApiEndpoints.adminAnalyticsRevenue);
    return List<dynamic>.from(res.data['data'] ?? []);
  }

  Future<List<dynamic>> supportMetrics() async {
    final res = await _api.get(ApiEndpoints.adminAnalyticsSupport);
    return List<dynamic>.from(res.data['data'] ?? []);
  }

  Future<List<dynamic>> merchantMetrics() async {
    final res = await _api.get(ApiEndpoints.adminAnalyticsMerchants);
    return List<dynamic>.from(res.data['data'] ?? []);
  }

  Future<List<dynamic>> users({String? q}) async {
    final res = await _api.get(ApiEndpoints.adminUsers,
        queryParameters: {if (q != null && q.trim().isNotEmpty) 'q': q});
    return List<dynamic>.from(res.data['data'] ?? []);
  }

  Future<List<dynamic>> roles() async {
    final res = await _api.get(ApiEndpoints.adminRoles);
    return List<dynamic>.from(res.data['data'] ?? []);
  }

  Future<void> createUser(Map<String, dynamic> data) async {
    await _api.post(ApiEndpoints.adminUsers, data: data);
  }

  Future<void> updateUser(String id, Map<String, dynamic> data) async {
    await _api.patch(ApiEndpoints.adminUser(id), data: data);
  }

  Future<void> updateUserStatus(String id, String status) async {
    await _api
        .patch(ApiEndpoints.adminUserStatus(id), data: {'status': status});
  }

  Future<void> deleteUser(String id) async {
    await _api.delete(ApiEndpoints.adminUser(id));
  }

  Future<List<dynamic>> verificationRequests({String? status}) async {
    final res = await _api.get(ApiEndpoints.adminVerifications,
        queryParameters: {
          if (status != null && status.isNotEmpty) 'status': status
        });
    return List<dynamic>.from(res.data['data'] ?? []);
  }

  Future<Map<String, dynamic>> verificationDetail(String id) async {
    final res = await _api.get(ApiEndpoints.adminVerificationDetail(id));
    return Map<String, dynamic>.from(res.data['data'] ?? {});
  }

  Future<void> approveVerification(String id, String notes,
      {String notificationChannel = 'BOTH'}) async {
    await _api.post(ApiEndpoints.adminVerificationApprove(id),
        data: {'notes': notes, 'notificationChannel': notificationChannel});
  }

  Future<void> rejectVerification(String id, String notes,
      {String notificationChannel = 'BOTH'}) async {
    await _api.post(ApiEndpoints.adminVerificationReject(id),
        data: {'notes': notes, 'notificationChannel': notificationChannel});
  }

  Future<void> requireDocuments(String id, String notes,
      {String notificationChannel = 'BOTH'}) async {
    await _api.post(ApiEndpoints.adminVerificationRequireDocuments(id),
        data: {'notes': notes, 'notificationChannel': notificationChannel});
  }

  Future<void> suspendVerification(String id, String notes,
      {String notificationChannel = 'BOTH'}) async {
    await _api.post(ApiEndpoints.adminVerificationSuspend(id),
        data: {'notes': notes, 'notificationChannel': notificationChannel});
  }

  Future<List<dynamic>> orders({String? status}) async {
    final res = await _api.get(ApiEndpoints.adminOrders, queryParameters: {
      if (status != null && status.isNotEmpty) 'status': status
    });
    return List<dynamic>.from(res.data['data'] ?? []);
  }

  Future<Map<String, dynamic>> orderDetail(String id) async {
    final res = await _api.get(ApiEndpoints.adminOrderDetail(id));
    return Map<String, dynamic>.from(res.data['data'] ?? {});
  }

  Future<void> updateOrderStatus(String id, String status,
      {String? note}) async {
    await _api.patch(ApiEndpoints.adminOrderStatus(id), data: {
      'status': status,
      if ((note ?? '').isNotEmpty) 'note': note,
    });
  }

  Future<List<dynamic>> auditLogs() async {
    final res = await _api.get(ApiEndpoints.adminAuditLogs);
    return List<dynamic>.from(res.data['data'] ?? []);
  }

  Future<List<dynamic>> settings() async {
    final res = await _api.get(ApiEndpoints.adminSettings);
    return List<dynamic>.from(res.data['data'] ?? []);
  }

  Future<void> upsertSetting(String key, Map<String, dynamic> data) async {
    await _api.put(ApiEndpoints.adminSetting(key), data: data);
  }

  Future<void> upsertFeatureFlag(String key,
      {required bool enabled, String? description}) async {
    await _api.put(ApiEndpoints.adminFeatureFlag(key), data: {
      'enabled': enabled,
      if ((description ?? '').trim().isNotEmpty)
        'description': description!.trim()
    });
  }

  Future<Map<String, dynamic>> systemHardeningOverview() async {
    final res = await _api.get(ApiEndpoints.adminSystemHardeningOverview);
    return Map<String, dynamic>.from(res.data['data'] ?? {});
  }

  Future<Map<String, dynamic>> namingStandardReport() async {
    final res = await _api.get(ApiEndpoints.adminSystemHardeningNaming);
    return Map<String, dynamic>.from(res.data['data'] ?? {});
  }

  Future<List<dynamic>> systemModules({String locale = 'ar'}) async {
    final res = await _api.get(ApiEndpoints.adminSystemHardeningModules,
        queryParameters: {'locale': locale});
    return List<dynamic>.from(res.data['data'] ?? []);
  }

  Future<List<dynamic>> translationCatalog(
      {String? locale, String? namespace, String? q}) async {
    final res = await _api.get(ApiEndpoints.adminI18nCatalog, queryParameters: {
      if (locale != null) 'locale': locale,
      if (namespace != null && namespace.isNotEmpty) 'namespace': namespace,
      if (q != null && q.isNotEmpty) 'q': q,
    });
    return List<dynamic>.from(res.data['data'] ?? []);
  }

  Future<void> upsertTranslation({
    required String key,
    required String locale,
    required String value,
    String namespace = 'app',
    String status = 'PUBLISHED',
  }) async {
    await _api.put(
      ApiEndpoints.adminI18nCatalogEntry(key),
      data: {
        'locale': locale,
        'value': value,
        'namespace': namespace,
        'platform': 'GLOBAL',
        'status': status,
      },
    );
  }

  Future<List<dynamic>> analyticsSnapshots({String? group}) async {
    final res = await _api.get(ApiEndpoints.adminAnalyticsSnapshots,
        queryParameters: {
          if (group != null && group.isNotEmpty) 'group': group
        });
    return List<dynamic>.from(res.data['data'] ?? []);
  }

  Future<void> refreshAnalyticsSnapshots() async {
    await _api.post(ApiEndpoints.adminRefreshAnalyticsSnapshots);
  }

  Future<Map<String, dynamic>> createAuditIntegrityCheckpoint() async {
    final res = await _api.post(ApiEndpoints.adminAuditIntegrityCheckpoint);
    return Map<String, dynamic>.from(res.data['data'] ?? {});
  }

  Future<Map<String, dynamic>> qualityReadiness() async {
    final res = await _api.get(ApiEndpoints.qualityReadiness);
    return Map<String, dynamic>.from(res.data['data'] ?? {});
  }

  Future<List<dynamic>> qualityRuns() async {
    final res = await _api.get(ApiEndpoints.qualityRuns);
    return List<dynamic>.from(res.data['data'] ?? []);
  }

  Future<List<dynamic>> releaseChecklist() async {
    final res = await _api.get(ApiEndpoints.releaseChecklist);
    return List<dynamic>.from(res.data['data'] ?? []);
  }

  Future<List<dynamic>> deploymentRuns() async {
    final res = await _api.get(ApiEndpoints.deploymentRuns);
    return List<dynamic>.from(res.data['data'] ?? []);
  }
}
