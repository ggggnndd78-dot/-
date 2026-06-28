import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/config/api_endpoints.dart';
import 'package:ghiyarak/core/network/api_client.dart';

final providerOnboardingRepositoryProvider =
    Provider<ProviderOnboardingRepository>((ref) {
  return ProviderOnboardingRepository(ref.watch(apiClientProvider));
});

class ProviderOnboardingRepository {
  final ApiClient _apiClient;

  ProviderOnboardingRepository(this._apiClient);

  Future<Map<String, dynamic>> createOrganization({
    required String organizationType,
    required String displayName,
    required String legalName,
    required String primaryPhone,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.organizations,
      data: {
        'organizationType': organizationType,
        'displayName': displayName,
        'legalName': legalName,
        'primaryPhone': primaryPhone,
      },
    );
    return Map<String, dynamic>.from(response.data['data'] as Map);
  }

  Future<Map<String, dynamic>> createBranch({
    required String organizationId,
    required String branchName,
    required int cityId,
    int? districtId,
    int? areaId,
    String? addressLine1,
    String? phone,
    bool supportsPickup = true,
    bool supportsDelivery = false,
    bool supportsInstallation = false,
    bool supportsMobileService = false,
    bool isHeadOffice = true,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.organizationBranches(organizationId),
      data: {
        'branchName': branchName,
        'cityId': cityId,
        'districtId': districtId,
        'areaId': areaId,
        'addressLine1': addressLine1,
        'phone': phone,
        'supportsPickup': supportsPickup,
        'supportsDelivery': supportsDelivery,
        'supportsInstallation': supportsInstallation,
        'supportsMobileService': supportsMobileService,
        'isHeadOffice': isHeadOffice,
      },
    );
    return Map<String, dynamic>.from(response.data['data'] as Map);
  }

  Future<void> saveMerchantProfile({
    required String organizationId,
    required String businessCategoryCode,
    int? averagePreparationMinutes,
    String? warrantyPolicyText,
    String? returnPolicyText,
    String? deliveryPolicyText,
    double? minOrderAmount,
  }) async {
    await _apiClient.post(
      ApiEndpoints.organizationMerchantProfile(organizationId),
      data: {
        'businessCategoryCode': businessCategoryCode,
        'averagePreparationMinutes': averagePreparationMinutes,
        'warrantyPolicyText': warrantyPolicyText,
        'returnPolicyText': returnPolicyText,
        'deliveryPolicyText': deliveryPolicyText,
        'minOrderAmount': minOrderAmount,
      },
    );
  }

  Future<void> saveWorkshopProfile({
    required String organizationId,
    required String serviceModeCode,
    required bool acceptsDiagnosis,
    required bool acceptsInstallation,
    int? capacityPerDay,
    required bool supportsEmergencyService,
    double? defaultDiagnosisFee,
  }) async {
    await _apiClient.post(
      ApiEndpoints.organizationWorkshopProfile(organizationId),
      data: {
        'serviceModeCode': serviceModeCode,
        'acceptsDiagnosis': acceptsDiagnosis,
        'acceptsInstallation': acceptsInstallation,
        'capacityPerDay': capacityPerDay,
        'supportsEmergencyService': supportsEmergencyService,
        'defaultDiagnosisFee': defaultDiagnosisFee,
      },
    );
  }

  Future<void> createBankAccount({
    required String organizationId,
    required String bankName,
    required String accountName,
    required String accountNumber,
    String? iban,
    bool isPrimary = true,
  }) async {
    await _apiClient.post(
      ApiEndpoints.organizationBankAccounts(organizationId),
      data: {
        'bankName': bankName,
        'accountName': accountName,
        'accountNumber': accountNumber,
        'iban': iban,
        'isPrimary': isPrimary,
      },
    );
  }

  Future<void> saveBusinessHours({
    required String organizationId,
    required List<Map<String, dynamic>> items,
  }) async {
    await _apiClient.put(
      ApiEndpoints.organizationBusinessHours(organizationId),
      data: {'items': items},
    );
  }

  Future<Map<String, dynamic>> submitVerificationRequest({
    required String organizationId,
    String? notes,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.organizationVerificationRequests(organizationId),
      data: {'notes': notes},
    );
    return Map<String, dynamic>.from(response.data['data'] as Map);
  }

  Future<void> addVerificationDocument({
    required String verificationRequestId,
    required String documentType,
    required String fileName,
    required String fileUrl,
    String? mimeType,
    String? notes,
  }) async {
    await _apiClient.post(
      ApiEndpoints.verificationRequestDocuments(verificationRequestId),
      data: {
        'documentType': documentType,
        'fileName': fileName,
        'fileUrl': fileUrl,
        'mimeType': mimeType,
        'notes': notes,
      },
    );
  }

  Future<List<Map<String, dynamic>>> getMyOrganizations() async {
    final response = await _apiClient.get(ApiEndpoints.organizationsMine);
    final data = (response.data['data'] as List<dynamic>? ?? []);
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> getOrganizationDetail(
      String organizationId) async {
    final response =
        await _apiClient.get(ApiEndpoints.organizationDetail(organizationId));
    return Map<String, dynamic>.from(response.data['data'] as Map);
  }
}
