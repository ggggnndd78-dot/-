import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/core/config/app_config.dart';
import 'package:ghiyarak/core/theme/app_colors.dart';
import 'package:ghiyarak/core/theme/app_text_styles.dart';
import 'package:ghiyarak/features/auth/logic/auth_controller.dart';
import 'package:ghiyarak/shared/navigation/app_route_resolver.dart';
import 'package:go_router/go_router.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  bool _didNavigate = false;

  @override
  void initState() {
    super.initState();
    _resolveRoute();
  }

  Future<void> _resolveRoute() async {
    await Future.delayed(const Duration(milliseconds: 900));

    if (!mounted || _didNavigate) return;

    final authNotifier = ref.read(authControllerProvider.notifier);

    final isAuthenticated = await authNotifier.initializeSession();
    if (!mounted || _didNavigate) return;

    final authState = ref.read(authControllerProvider);
    if (!mounted || _didNavigate) return;

    _didNavigate = true;

    if (isAuthenticated || authState.isAuthenticated) {
      context.go(AppRouteResolver.resolvePostAuthRoute(authState));
      return;
    }

    if (authState.isGuest) {
      context.go(RouteNames.marketplaceHome);
      return;
    }

    context.go(RouteNames.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        child: Center(
          child: Container(
            width: 230,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 28,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  AppConfig.logoAsset,
                  width: 164,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 20),
                Text(
                  'غيّارك',
                  style: AppTextStyles.heading1.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 14),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
