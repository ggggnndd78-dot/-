import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/theme/app_text_styles.dart';
import 'package:ghiyarak/features/auth/logic/auth_controller.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';

class WorkshopStatusPage extends ConsumerWidget {
  const WorkshopStatusPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(authControllerProvider).workshopStatus;
    final message = status == 'REJECTED'
        ? 'تم رفض طلب الورشة، يرجى التواصل مع الإدارة'
        : 'حسابك كورشة قيد المراجعة من الإدارة';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AppScaffold(
        title: 'حالة حساب الورشة',
        showBottomNav: false,
        child: Center(
          child: Text(
            message,
            style: AppTextStyles.heading2,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
