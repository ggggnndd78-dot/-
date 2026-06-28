import 'package:flutter/material.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/core/theme/app_text_styles.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:go_router/go_router.dart';

class EmailLinkAuthPage extends StatelessWidget {
  final String accountType;
  final String initialEmail;

  const EmailLinkAuthPage({
    super.key,
    this.accountType = 'customer',
    this.initialEmail = '',
  });

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'التحقق عبر SMS',
      showBottomNav: false,
      child: ListView(
        children: [
          const Text('تم إلغاء التحقق الخارجي القديم من هذه النسخة',
              style: AppTextStyles.heading2),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'هذه النسخة تعتمد على Backend OTP + CommPeak SMS فقط. استخدم رقم الجوال لإرسال رمز التحقق الحقيقي.',
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            text: 'العودة لتسجيل الدخول بالجوال',
            onPressed: () => context.go(
                '${RouteNames.login}?accountType=${Uri.encodeQueryComponent(accountType)}'),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            text: 'إنشاء حساب جديد بالجوال',
            isOutlined: true,
            onPressed: () => context.go(
                '${RouteNames.register}?accountType=${Uri.encodeQueryComponent(accountType)}'),
          ),
        ],
      ),
    );
  }
}
