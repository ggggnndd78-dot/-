import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/config/app_config.dart';
import 'package:ghiyarak/core/config/env.dart';
import 'package:ghiyarak/core/network/auth_session_events.dart';
import 'package:ghiyarak/features/auth/data/auth_repository.dart';
import 'package:ghiyarak/features/auth/logic/auth_state.dart';

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final controller = AuthController(repository);
  ref.listen<int>(authSessionInvalidationProvider, (previous, next) {
    if (previous != null && previous != next) {
      controller.clearAuthSession();
    }
  });
  return controller;
});

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  AuthController(this._repository) : super(const AuthState());

  Future<bool> initializeSession() async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    if (Env.current == AppEnv.development &&
        AppConfig.clearSessionOnLaunchInDevelopment) {
      await clearAuthSession();
      return false;
    }

    final isAuthenticated = await _repository.isAuthenticated();
    if (isAuthenticated) {
      try {
        final user = await _repository.getCurrentUser();
        state = AuthState(
            status: AuthStatus.authenticated, phone: user.phone, user: user);
        return true;
      } catch (_) {
        final refreshed = await _repository.refreshAccessToken();
        if (refreshed) {
          try {
            final user = await _repository.getCurrentUser();
            state = AuthState(
                status: AuthStatus.authenticated, phone: user.phone, user: user);
            return true;
          } catch (_) {}
        }
        await _repository.clearAuthSession();
        state = const AuthState(status: AuthStatus.initial);
        return false;
      }
    }

    final isGuest = await _repository.isGuest();
    if (isGuest) {
      state = const AuthState(status: AuthStatus.guest);
      return false;
    }

    await _repository.clearAuthSession();
    state = const AuthState(status: AuthStatus.initial);
    return false;
  }

  Future<void> clearAuthSession() async {
    await _repository.clearAuthSession();
    state = const AuthState(status: AuthStatus.initial);
  }

  Future<LoginStartResult?> startPhoneLogin(String phone) async {
    try {
      state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
      final result = await _repository.startPhoneLogin(phone);
      if (!result.otpRequired && result.user != null) {
        state = AuthState(
            status: AuthStatus.authenticated,
            phone: result.user!.phone,
            user: result.user);
      } else {
        state = state.copyWith(status: AuthStatus.otpSent, phone: result.phone);
      }
      return result;
    } catch (e) {
      state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: e.toString().replaceFirst('Exception: ', ''));
      return null;
    }
  }

  Future<OtpRequestResult?> requestOtp(String phone,
      {String purpose = 'LOGIN'}) async {
    try {
      state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
      final result = await _repository.requestOtp(phone, purpose: purpose);
      state = state.copyWith(status: AuthStatus.otpSent, phone: result.target);
      return result;
    } catch (e) {
      state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: e.toString().replaceFirst('Exception: ', ''));
      return null;
    }
  }

  Future<bool> verifyTrustedDeviceOtp(
      {required String phone, required String code}) async {
    try {
      state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
      final user =
          await _repository.verifyTrustedDeviceOtp(phone: phone, code: code);
      state = AuthState(
          status: AuthStatus.authenticated, phone: user.phone, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  Future<bool> registerCustomer(
      {required String phone,
      required String code,
      String? displayName,
      String? email}) async {
    try {
      state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
      final user = await _repository.registerCustomer(
          phone: phone, code: code, displayName: displayName, email: email);
      state = AuthState(
          status: AuthStatus.authenticated, phone: user.phone, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  Future<bool> registerBusiness({
    required String accountType,
    required String phone,
    required String code,
    required String fullName,
    required String email,
    required int cityId,
    int? districtId,
    int? areaId,
    String? branchName,
    required String address,
    required String businessName,
    required String businessDescription,
    double? latitude,
    double? longitude,
    String? mapUrl,
    required List<Map<String, dynamic>> documents,
  }) async {
    try {
      state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
      final user = await _repository.registerBusiness(
        accountType: accountType,
        phone: phone,
        code: code,
        fullName: fullName,
        email: email,
        cityId: cityId,
        districtId: districtId,
        areaId: areaId,
        branchName: branchName,
        address: address,
        businessName: businessName,
        businessDescription: businessDescription,
        latitude: latitude,
        longitude: longitude,
        mapUrl: mapUrl,
        documents: documents,
      );
      state = AuthState(
          status: AuthStatus.authenticated,
          phone: user?.phone ?? phone,
          user: user);
      return true;
    } catch (e) {
      state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  Future<bool> verifyOtp(
      {required String phone,
      required String code,
      String? displayName,
      String purpose = 'LOGIN'}) async {
    try {
      state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
      final user = await _repository.verifyOtp(
          phone: phone, code: code, displayName: displayName, purpose: purpose);
      state = AuthState(
          status: AuthStatus.authenticated, phone: user.phone, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  Future<bool> continueAsGuest() async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _repository.continueAsGuest();
      final saved = await _repository.isGuest();
      if (!saved) {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'تم إنشاء جلسة الزائر لكن تعذر حفظها محليًا',
        );
        return false;
      }
      state = const AuthState(status: AuthStatus.guest);
      debugPrint('[Ghiyarak][Auth] Guest mode activated');
      return true;
    } catch (e) {
      state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  Future<bool> hasProviderOrganization() async {
    final user = state.user;
    if (user != null) {
      return user.hasApprovedMerchantOrganization ||
          user.hasApprovedWorkshopOrganization ||
          user.hasApprovedWarehouseOrganization ||
          user.hasPendingProviderOrganization;
    }
    try {
      final current = await _repository.getCurrentUser();
      state = state.copyWith(user: current, status: AuthStatus.authenticated);
      return current.hasApprovedMerchantOrganization ||
          current.hasApprovedWorkshopOrganization ||
          current.hasApprovedWarehouseOrganization ||
          current.hasPendingProviderOrganization;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState(status: AuthStatus.initial);
  }
}
