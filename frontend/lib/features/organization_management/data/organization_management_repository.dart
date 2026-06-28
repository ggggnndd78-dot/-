import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/network/api_client.dart';

final organizationManagementRepositoryProvider =
    Provider<OrganizationManagementRepository>((ref) {
  return OrganizationManagementRepository(ref.watch(apiClientProvider));
});

class OrganizationManagementRepository {
  final ApiClient _api;
  OrganizationManagementRepository(this._api);

  Future<List<Map<String, dynamic>>> myOrganizations() async {
    final response = await _api.get('/organizations/me');
    return (response.data['data'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> branches(String organizationId) async {
    final response = await _api.get('/organizations/$organizationId/branches');
    return (response.data['data'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> employees(String organizationId) async {
    final response = await _api.get('/organizations/$organizationId/employees');
    return (response.data['data'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> availablePermissions(
      String organizationId) async {
    final response = await _api
        .get('/organizations/$organizationId/employees/available-permissions');
    return (response.data['data'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
  }

  Future<void> createBranch(
      String organizationId, Map<String, dynamic> data) async {
    await _api.post('/organizations/$organizationId/branches', data: data);
  }

  Future<void> setBranchClosure(
      String organizationId, String branchId, bool closed,
      {String? reason}) async {
    await _api.patch(
        '/organizations/$organizationId/branches/$branchId/closure',
        data: {
          'temporarilyClosed': closed,
          if (reason != null && reason.trim().isNotEmpty)
            'closedReason': reason.trim(),
        });
  }

  Future<void> addEmployee(
      String organizationId, Map<String, dynamic> data) async {
    await _api.post('/organizations/$organizationId/employees', data: data);
  }

  Future<void> updateEmployeeStatus(
      String organizationId, int memberId, String status) async {
    await _api.patch(
        '/organizations/$organizationId/employees/$memberId/status',
        data: {'status': status});
  }
}
