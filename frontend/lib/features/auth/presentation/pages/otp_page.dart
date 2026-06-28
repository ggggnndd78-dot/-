import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/core/i18n/app_localizations.dart';
import 'package:ghiyarak/core/theme/app_colors.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/features/auth/logic/auth_controller.dart';
import 'package:ghiyarak/features/auth/logic/auth_state.dart';
import 'package:ghiyarak/features/provider_onboarding/logic/provider_onboarding_controller.dart';
import 'package:ghiyarak/shared/navigation/app_route_resolver.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:ghiyarak/shared/widgets/app_text_field.dart';
import 'package:go_router/go_router.dart';

class OtpPage extends ConsumerStatefulWidget {
  final String phone;
  final String accountType;
  final String displayName;
  final String email;
  final String? nextRoute;
  final String authProvider;
  final String verificationId;
  final String devOtp;

  const OtpPage({
    super.key,
    required this.phone,
    this.accountType = 'login',
    this.displayName = '',
    this.email = '',
    this.nextRoute,
    this.authProvider = 'backend_otp',
    this.verificationId = '',
    this.devOtp = '',
  });

  @override
  ConsumerState<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends ConsumerState<OtpPage> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();

  bool get _isMerchantRegistration => widget.accountType == 'merchant';
  bool get _isWorkshopRegistration => widget.accountType == 'workshop';
  bool get _isWarehouseRegistration => widget.accountType == 'warehouse';
  bool get _isProviderRegistration =>
      _isMerchantRegistration ||
      _isWorkshopRegistration ||
      _isWarehouseRegistration;
  bool get _isCustomerRegistration => widget.accountType == 'customer';

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  String _landingRouteFor(AuthState auth) {
    return AppRouteResolver.resolvePostAuthRoute(
      auth,
      nextRoute: widget.nextRoute,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final code = _otpController.text.trim();
    final ok = _isCustomerRegistration
        ? await ref.read(authControllerProvider.notifier).registerCustomer(
              phone: widget.phone,
              code: code,
              displayName: widget.displayName,
              email: widget.email,
            )
        : _isProviderRegistration
            ? await ref.read(authControllerProvider.notifier).verifyOtp(
                  phone: widget.phone,
                  code: code,
                  displayName: widget.displayName,
                  purpose: 'REGISTER',
                )
            : await ref
                .read(authControllerProvider.notifier)
                .verifyTrustedDeviceOtp(
                  phone: widget.phone,
                  code: code,
                );

    if (!mounted) return;

    if (ok) {
      if (_isMerchantRegistration) {
        ref
            .read(providerOnboardingControllerProvider.notifier)
            .setOrganizationType('MERCHANT');
        context.go(RouteNames.providerOrganization);
        return;
      }
      if (_isWorkshopRegistration) {
        ref
            .read(providerOnboardingControllerProvider.notifier)
            .setOrganizationType('WORKSHOP');
        context.go(RouteNames.providerOrganization);
        return;
      }
      if (_isWarehouseRegistration) {
        ref
            .read(providerOnboardingControllerProvider.notifier)
            .setOrganizationType('WAREHOUSE');
        context.go(RouteNames.providerOrganization);
        return;
      }
      if (_isCustomerRegistration) {
        context.go(RouteNames.customerCenter);
        return;
      }
      context.go(_landingRouteFor(ref.read(authControllerProvider)));
      return;
    }

    final error = ref.read(authControllerProvider).errorMessage ??
        context.tr('auth.error.otp_verify_failed');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final flowText = _isProviderRegistration
        ? context.tr('auth.otp.provider_flow')
        : _isCustomerRegistration
            ? context.tr('auth.otp.customer_flow')
            : context.tr('auth.otp.login_flow');

    return AppScaffold(
      title: context.tr('auth.otp'),
      showBottomNav: false,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(context
                .tr('auth.otp.sent_to', params: {'phone': widget.phone})),
            const SizedBox(height: AppSpacing.sm),
            Text(flowText,
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _otpController,
              label: context.tr('auth.otp'),
              hint: context.tr('auth.otp_hint'),
              keyboardType: TextInputType.number,
              validator: (value) {
                final v = value?.trim() ?? '';
                if (v.isEmpty) {
                  return context.tr('auth.validation.otp_required');
                }
                if (v.length < 4) {
                  return context.tr('auth.validation.otp_invalid');
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              text: context.tr('common.confirm'),
              isLoading: authState.status == AuthStatus.loading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
