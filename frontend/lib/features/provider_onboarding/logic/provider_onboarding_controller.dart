import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/storage/local_storage_service.dart';
import 'package:ghiyarak/features/provider_onboarding/data/provider_onboarding_repository.dart';
import 'package:ghiyarak/features/provider_onboarding/logic/provider_onboarding_state.dart';

final providerOnboardingControllerProvider = StateNotifierProvider<
    ProviderOnboardingController, ProviderOnboardingState>((ref) {
  return ProviderOnboardingController(
    ref.watch(providerOnboardingRepositoryProvider),
    ref.watch(localStorageServiceProvider),
  );
});

class ProviderOnboardingController
    extends StateNotifier<ProviderOnboardingState> {
  final ProviderOnboardingRepository _repository;
  final LocalStorageService _localStorage;

  ProviderOnboardingController(this._repository, this._localStorage)
      : super(const ProviderOnboardingState()) {
    _restoreDraft();
  }

  Future<void> _restoreDraft() async {
    final type = await _localStorage.getProviderOrganizationType();
    final orgId = await _localStorage.getProviderOrganizationId();
    if (type.isNotEmpty || orgId.isNotEmpty) {
      state = state.copyWith(
        organizationType: type.isEmpty ? null : type,
        organizationId: orgId.isEmpty ? null : orgId,
      );
    }
  }

  Future<String?> _currentOrganizationId() async {
    if ((state.organizationId ?? '').isNotEmpty) return state.organizationId;
    final stored = await _localStorage.getProviderOrganizationId();
    if (stored.isNotEmpty) {
      state = state.copyWith(organizationId: stored);
      return stored;
    }
    return null;
  }

  void setOrganizationType(String type) {
    _localStorage.setProviderOrganizationType(type);
    state = state.copyWith(organizationType: type, errorMessage: null);
  }

  Future<bool> createOrganization({
    required String displayName,
    required String legalName,
    required String primaryPhone,
  }) async {
    if (state.organizationType == null) {
      state = state.copyWith(errorMessage: 'يرجى اختيار نوع المزود أولاً');
      return false;
    }
    state = state.copyWith(loading: true, errorMessage: null);
    try {
      final data = await _repository.createOrganization(
        organizationType: state.organizationType!,
        displayName: displayName,
        legalName: legalName,
        primaryPhone: primaryPhone,
      );
      final orgId = data['id']?.toString();
      if ((orgId ?? '').isNotEmpty) {
        await _localStorage.setProviderOrganizationId(orgId!);
      }
      state = state.copyWith(loading: false, organizationId: orgId);
      return true;
    } catch (e) {
      state = state.copyWith(
          loading: false,
          errorMessage: e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  Future<bool> createBranch({
    required String branchName,
    required int cityId,
    int? districtId,
    String? addressLine1,
    String? phone,
  }) async {
    final orgId = await _currentOrganizationId();
    if (orgId == null) return false;
    state = state.copyWith(loading: true, errorMessage: null);
    try {
      await _repository.createBranch(
        organizationId: orgId,
        branchName: branchName,
        cityId: cityId,
        districtId: districtId,
        addressLine1: addressLine1,
        phone: phone,
        supportsPickup: state.organizationType == 'MERCHANT' ||
            state.organizationType == 'WAREHOUSE',
        supportsDelivery: true,
        supportsInstallation: state.organizationType == 'WORKSHOP',
      );
      state = state.copyWith(loading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
          loading: false,
          errorMessage: e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  Future<bool> saveMerchantProfile({
    required String businessCategoryCode,
    int? averagePreparationMinutes,
    String? warrantyPolicyText,
    String? returnPolicyText,
    String? deliveryPolicyText,
    double? minOrderAmount,
  }) async {
    final orgId = await _currentOrganizationId();
    if (orgId == null) return false;
    state = state.copyWith(loading: true, errorMessage: null);
    try {
      await _repository.saveMerchantProfile(
        organizationId: orgId,
        businessCategoryCode: businessCategoryCode,
        averagePreparationMinutes: averagePreparationMinutes,
        warrantyPolicyText: warrantyPolicyText,
        returnPolicyText: returnPolicyText,
        deliveryPolicyText: deliveryPolicyText,
        minOrderAmount: minOrderAmount,
      );
      state = state.copyWith(loading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
          loading: false,
          errorMessage: e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  Future<bool> saveWorkshopProfile({
    required String serviceModeCode,
    required bool acceptsDiagnosis,
    required bool acceptsInstallation,
    int? capacityPerDay,
    required bool supportsEmergencyService,
    double? defaultDiagnosisFee,
  }) async {
    final orgId = await _currentOrganizationId();
    if (orgId == null) return false;
    state = state.copyWith(loading: true, errorMessage: null);
    try {
      await _repository.saveWorkshopProfile(
        organizationId: orgId,
        serviceModeCode: serviceModeCode,
        acceptsDiagnosis: acceptsDiagnosis,
        acceptsInstallation: acceptsInstallation,
        capacityPerDay: capacityPerDay,
        supportsEmergencyService: supportsEmergencyService,
        defaultDiagnosisFee: defaultDiagnosisFee,
      );
      state = state.copyWith(loading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
          loading: false,
          errorMessage: e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  Future<bool> createBankAccount({
    required String bankName,
    required String accountName,
    required String accountNumber,
    String? iban,
  }) async {
    final orgId = await _currentOrganizationId();
    if (orgId == null) return false;
    state = state.copyWith(loading: true, errorMessage: null);
    try {
      await _repository.createBankAccount(
        organizationId: orgId,
        bankName: bankName,
        accountName: accountName,
        accountNumber: accountNumber,
        iban: iban,
      );
      state = state.copyWith(loading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
          loading: false,
          errorMessage: e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  Future<bool> saveBusinessHours(List<Map<String, dynamic>> items) async {
    final orgId = await _currentOrganizationId();
    if (orgId == null) return false;
    state = state.copyWith(loading: true, errorMessage: null);
    try {
      await _repository.saveBusinessHours(organizationId: orgId, items: items);
      state = state.copyWith(loading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
          loading: false,
          errorMessage: e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  Future<bool> submitVerification(String? notes) async {
    final orgId = await _currentOrganizationId();
    if (orgId == null) return false;
    state = state.copyWith(loading: true, errorMessage: null);
    try {
      final data = await _repository.submitVerificationRequest(
          organizationId: orgId, notes: notes);
      state = state.copyWith(
          loading: false, verificationRequestId: data['id']?.toString());
      return true;
    } catch (e) {
      state = state.copyWith(
          loading: false,
          errorMessage: e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  Future<bool> addVerificationDocument({
    required String documentType,
    required String fileName,
    required String fileUrl,
    String? notes,
  }) async {
    final verificationRequestId = state.verificationRequestId;
    if (verificationRequestId == null) return false;
    state = state.copyWith(loading: true, errorMessage: null);
    try {
      await _repository.addVerificationDocument(
        verificationRequestId: verificationRequestId,
        documentType: documentType,
        fileName: fileName,
        fileUrl: fileUrl,
        notes: notes,
      );
      state = state.copyWith(loading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
          loading: false,
          errorMessage: e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  Future<Map<String, dynamic>?> getOrganizationDetail() async {
    var orgId = await _currentOrganizationId();
    try {
      if (orgId == null) {
        final organizations = await _repository.getMyOrganizations();
        final providers = organizations.where((item) {
          final type = item['organization_type']?.toString();
          return type == 'MERCHANT' ||
              type == 'WORKSHOP' ||
              type == 'WAREHOUSE';
        }).toList();
        if (providers.isEmpty) return null;
        orgId = providers.first['id']?.toString();
        if (orgId == null || orgId.isEmpty) return null;
        await _localStorage.setProviderOrganizationId(orgId);
        await _localStorage.setProviderOrganizationType(
            providers.first['organization_type']?.toString() ?? '');
        state = state.copyWith(
            organizationId: orgId,
            organizationType: providers.first['organization_type']?.toString());
      }
      return await _repository.getOrganizationDetail(orgId);
    } catch (_) {
      return null;
    }
  }
}
