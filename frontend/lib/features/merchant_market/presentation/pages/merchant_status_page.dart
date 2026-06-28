import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/theme/app_colors.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/core/theme/app_text_styles.dart';
import 'package:ghiyarak/features/auth/logic/auth_controller.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';

class MerchantStatusPage extends ConsumerWidget {
  const MerchantStatusPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(authControllerProvider).merchantStatus;
    final rejected = status == 'REJECTED';

    return AppScaffold(
      title: 'حالة حساب التاجر',
      showBottomNav: false,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                rejected ? Icons.cancel_outlined : Icons.hourglass_top_rounded,
                size: 54,
                color: rejected ? AppColors.error : AppColors.secondary,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                rejected
                    ? 'تم رفض طلب التاجر، يرجى التواصل مع الإدارة'
                    : 'حسابك كتاجر قيد المراجعة من الإدارة',
                style: AppTextStyles.title,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
