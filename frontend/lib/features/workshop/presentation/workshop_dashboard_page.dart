import 'package:flutter/material.dart';
import 'package:ghiyarak/core/theme/app_text_styles.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';

class WorkshopDashboardPage extends StatelessWidget {
  const WorkshopDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Directionality(
      textDirection: TextDirection.rtl,
      child: AppScaffold(
        title: 'لوحة الورشة',
        showBottomNav: false,
        child: Center(
          child: Text(
            'تم تسجيل الدخول إلى حساب الورشة',
            style: AppTextStyles.heading2,
          ),
        ),
      ),
    );
  }
}
