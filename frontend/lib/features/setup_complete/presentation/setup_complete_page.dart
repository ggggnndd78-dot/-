import 'package:flutter/material.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/core/theme/app_text_styles.dart';
import 'package:ghiyarak/core/config/app_config.dart';
import 'package:ghiyarak/core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';

class SetupCompletePage extends StatelessWidget {
  const SetupCompletePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.headerFooter,
              AppColors.primaryDark,
              AppColors.headerFooterEnd,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.md),
                Center(child: Image.asset(AppConfig.logoAsset, height: 72)),
                const SizedBox(height: AppSpacing.lg),

                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      TextSpan(
                          text: 'كل ما تحتاجه لسيارتك\n',
                          style: AppTextStyles.heading1
                              .copyWith(color: Colors.white)),
                      TextSpan(
                          text: 'في مكان واحد',
                          style: AppTextStyles.heading1
                              .copyWith(color: AppColors.secondary)),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'سجّل دخولك للوصول الكامل إلى المزايا أو تابع كزائر لتصفح السوق والخدمات.',
                  style: AppTextStyles.body.copyWith(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppSpacing.lg),

                // User-provided image (log.png)
                Expanded(
                  child: Center(
                    child: Image.asset('assets/images/log.png',
                        height: 280, fit: BoxFit.contain),
                  ),
                ),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    onPressed: () => context.go(RouteNames.providerType),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text('تسجيل الدخول',
                            style:
                                TextStyle(fontSize: 18, color: Colors.white)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.secondary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    onPressed: () => context.go(RouteNames.marketplaceHome),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.person_outline, color: AppColors.secondary),
                        SizedBox(width: AppSpacing.sm),
                        Text('الدخول كزائر',
                            style:
                                TextStyle(color: Colors.white, fontSize: 16)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.md),
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      Text('ليس لديك حساب؟ ',
                          style: AppTextStyles.body
                              .copyWith(color: Colors.white70)),
                      GestureDetector(
                          onTap: () => context.go(RouteNames.providerType),
                          child: Text('إنشاء حساب',
                              style: AppTextStyles.body
                                  .copyWith(color: AppColors.secondary))),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
