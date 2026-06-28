import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/core/config/app_config.dart';
import 'package:ghiyarak/core/i18n/app_localizations.dart';
import 'package:ghiyarak/core/theme/app_colors.dart';
import 'package:ghiyarak/core/theme/app_radius.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/core/theme/app_text_styles.dart';
import 'package:ghiyarak/core/validation/yemen_phone_validator.dart';
import 'package:ghiyarak/features/auth/logic/auth_controller.dart';
import 'package:ghiyarak/features/auth/logic/auth_state.dart';
import 'package:ghiyarak/shared/navigation/app_route_resolver.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:ghiyarak/shared/widgets/app_text_field.dart';

class LoginPage extends ConsumerStatefulWidget {
  final String accountType;
  final String? nextRoute;

  const LoginPage({
    super.key,
    this.accountType = 'login',
    this.nextRoute,
  });

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String? _validateYemeniPhone(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return context.tr('auth.validation.phone_required');
    if (!YemenPhoneValidator.isValid(text)) {
      return context.tr('auth.validation.yemeni_phone_companies');
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = _phoneController.text.trim();
    final result =
        await ref.read(authControllerProvider.notifier).startPhoneLogin(phone);

    if (!mounted) return;

    if (result?.otpRequired == false) {
      final auth = ref.read(authControllerProvider);
      context.go(
        AppRouteResolver.resolvePostAuthRoute(
          auth,
          nextRoute: widget.nextRoute,
        ),
      );
      return;
    }

    if (result != null) {
      final next = widget.nextRoute == null
          ? ''
          : '&next=${Uri.encodeQueryComponent(widget.nextRoute!)}';
      context.go(
          '${RouteNames.otp}?phone=${Uri.encodeQueryComponent(result.phone)}&accountType=login&authProvider=trusted_device$next');
      return;
    }

    final error = ref.read(authControllerProvider).errorMessage ??
        context.tr('auth.error.login_start_failed');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }

  Future<void> _continueAsGuest() async {
    final ok =
        await ref.read(authControllerProvider.notifier).continueAsGuest();
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('auth.guestModeNotice'))),
      );
      context.go(RouteNames.marketplaceHome);
      return;
    }
    final error = ref.read(authControllerProvider).errorMessage ??
        context.tr('common.error.unexpected');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return AppScaffold(
      title: context.tr('auth.login'),
      showAppBar: false,
      showBottomNav: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(color: AppColors.border),
                boxShadow: const [
                  BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 24,
                      offset: Offset(0, 14)),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                        child: Image.asset(AppConfig.logoAsset,
                            width: 96, fit: BoxFit.contain)),
                    const SizedBox(height: AppSpacing.lg),
                    Text(context.tr('auth.login.title'),
                        style: AppTextStyles.heading2,
                        textAlign: TextAlign.center),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      context.tr('auth.login.secure_subtitle'),
                      style: AppTextStyles.bodySecondary,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AppTextField(
                      controller: _phoneController,
                      label: context.tr('auth.phone'),
                      hint: context.tr('auth.phone_hint_yemen'),
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s-]'))
                      ],
                      validator: _validateYemeniPhone,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(context.tr('auth.phone.carriers_yemen'),
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: AppSpacing.lg),
                    AppButton(
                      text: context.tr('auth.login.button'),
                      isLoading: authState.status == AuthStatus.loading,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppButton(
                      text: context.tr('auth.create_account'),
                      isOutlined: true,
                      onPressed: () => context.go(RouteNames.register),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextButton.icon(
                      onPressed: authState.status == AuthStatus.loading
                          ? null
                          : _continueAsGuest,
                      icon: const Icon(Icons.travel_explore_outlined),
                      label: Text(context.tr('auth.continueAsGuest')),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      context.tr('auth.trusted_device_note'),
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
