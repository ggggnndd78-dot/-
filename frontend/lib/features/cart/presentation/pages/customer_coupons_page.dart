import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/core/theme/app_colors.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/core/theme/app_text_styles.dart';
import 'package:ghiyarak/features/cart/data/cart_repository.dart';
import 'package:ghiyarak/features/cart/data/models/customer_coupon_model.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:go_router/go_router.dart';

class CustomerCouponsPage extends ConsumerStatefulWidget {
  const CustomerCouponsPage({super.key});

  @override
  ConsumerState<CustomerCouponsPage> createState() =>
      _CustomerCouponsPageState();
}

class _CustomerCouponsPageState extends ConsumerState<CustomerCouponsPage> {
  late Future<CustomerCouponResponse> _future;
  final _manualController = TextEditingController();
  bool _validating = false;

  @override
  void initState() {
    super.initState();
    _future = ref.read(cartRepositoryProvider).getCustomerCoupons();
  }

  @override
  void dispose() {
    _manualController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(
        () => _future = ref.read(cartRepositoryProvider).getCustomerCoupons());
  }

  Future<void> _validateManual() async {
    final code = _manualController.text.trim();
    if (code.isEmpty) {
      _snack('أدخل كود الخصم أولًا', error: true);
      return;
    }
    setState(() => _validating = true);
    try {
      final result =
          await ref.read(cartRepositoryProvider).validateCoupon(code);
      if (!mounted) return;
      _showResult(result);
    } catch (error) {
      if (mounted) _snack(error.toString(), error: true);
    } finally {
      if (mounted) setState(() => _validating = false);
    }
  }

  void _copy(String code) {
    Clipboard.setData(ClipboardData(text: code));
    _snack('تم نسخ الكوبون $code');
  }

  void _use(String code) {
    context.go(
        '${RouteNames.checkoutPreview}?coupon=${Uri.encodeComponent(code)}');
  }

  void _showResult(CouponValidationResult result) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(result.valid ? Icons.verified_outlined : Icons.error_outline,
                color: result.valid ? AppColors.success : AppColors.error,
                size: 42),
            const SizedBox(height: AppSpacing.md),
            Text(result.message,
                textAlign: TextAlign.center, style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.lg),
            _InfoLine('المجموع قبل الخصم',
                '${result.subtotal.toStringAsFixed(0)} ${result.currency}'),
            _InfoLine('قيمة الخصم',
                '- ${result.discount.toStringAsFixed(0)} ${result.currency}'),
            _InfoLine('الإجمالي بعد الخصم',
                '${result.total.toStringAsFixed(0)} ${result.currency}',
                bold: true),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
                text: 'استخدام الكوبون في الطلب',
                onPressed: result.valid ? () => _use(result.code) : null),
          ],
        ),
      ),
    );
  }

  void _snack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message),
          backgroundColor: error ? AppColors.error : AppColors.primary),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'كوبوناتي والخصومات',
      child: FutureBuilder<CustomerCouponResponse>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _Loading();
          }
          if (snapshot.hasError) {
            return _StatePanel(
              icon: Icons.local_offer_outlined,
              title: 'تعذر تحميل الكوبونات',
              message: snapshot.error.toString(),
              actionText: 'إعادة المحاولة',
              onAction: _reload,
            );
          }
          final data = snapshot.data ?? const CustomerCouponResponse();
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _Header(stats: data.stats, currency: data.currency),
                const SizedBox(height: AppSpacing.lg),
                _ManualCouponCard(
                  controller: _manualController,
                  validating: _validating,
                  onValidate: _validateManual,
                ),
                const SizedBox(height: AppSpacing.lg),
                if (data.coupons.isEmpty)
                  _StatePanel(
                    icon: Icons.sell_outlined,
                    title: 'لا توجد كوبونات متاحة الآن',
                    message:
                        'عند توفر كوبونات عامة أو عروض للمتاجر ستظهر هنا تلقائيًا.',
                    actionText: 'تصفح العروض',
                    onAction: () => context.go(RouteNames.marketplaceSearch),
                  )
                else ...[
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child:
                        Text('الكوبونات المتاحة', style: AppTextStyles.title),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...data.coupons.map((coupon) => Padding(
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
                        child: _CouponCard(
                            coupon: coupon,
                            onCopy: () => _copy(coupon.code),
                            onUse: () => _use(coupon.code)),
                      )),
                ],
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final CustomerCouponStats stats;
  final String currency;
  const _Header({required this.stats, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
          gradient: AppColors.headerGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
                color: AppColors.shadow, blurRadius: 18, offset: Offset(0, 10))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.card_giftcard,
                  color: AppColors.secondary, size: 34),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                  child: Text('خصوماتك في غيارك',
                      style: AppTextStyles.heading2
                          .copyWith(color: AppColors.textOnDark))),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
              'اختر كوبونًا مناسبًا للسلة، أو أدخل كود الخصم يدويًا قبل إتمام الطلب.',
              style: AppTextStyles.body.copyWith(
                  color: AppColors.textOnDark.withValues(alpha: .75))),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                  child:
                      _Metric(label: 'المتاحة', value: '${stats.available}')),
              Expanded(
                  child: _Metric(
                      label: 'تنتهي قريبًا', value: '${stats.expiringSoon}')),
              Expanded(
                  child: _Metric(
                      label: 'أفضل توفير',
                      value: '${stats.bestSavings} $currency')),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        Text(value,
            style: AppTextStyles.title.copyWith(color: AppColors.secondary)),
        Text(label,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textOnDark.withValues(alpha: .75)))
      ]),
    );
  }
}

class _ManualCouponCard extends StatelessWidget {
  final TextEditingController controller;
  final bool validating;
  final VoidCallback onValidate;
  const _ManualCouponCard(
      {required this.controller,
      required this.validating,
      required this.onValidate});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: _box(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('تحقق من كوبون', style: AppTextStyles.title),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: controller,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
              prefixIcon: Icon(Icons.confirmation_number_outlined),
              labelText: 'اكتب كود الخصم',
              border: OutlineInputBorder()),
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
            text: validating ? 'جار التحقق...' : 'تحقق من الكوبون',
            onPressed: validating ? null : onValidate),
      ]),
    );
  }
}

class _CouponCard extends StatelessWidget {
  final CustomerCouponModel coupon;
  final VoidCallback onCopy;
  final VoidCallback onUse;
  const _CouponCard(
      {required this.coupon, required this.onCopy, required this.onUse});

  @override
  Widget build(BuildContext context) {
    final color = coupon.isApplicable ? AppColors.success : AppColors.gold;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: _box(borderColor: color.withValues(alpha: .35)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(18)),
              child: Center(
                  child: Text(coupon.discountLabel,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(
                          color: color, fontWeight: FontWeight.w900)))),
          const SizedBox(width: AppSpacing.md),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(coupon.title, style: AppTextStyles.title),
                const SizedBox(height: 3),
                Text(
                    coupon.description.isEmpty
                        ? coupon.validityMessage
                        : coupon.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySecondary),
              ])),
          Chip(
              label: Text(coupon.statusLabel),
              backgroundColor: color.withValues(alpha: .10)),
        ]),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border)),
          child: Row(children: [
            Expanded(
                child: Text(coupon.code,
                    style: AppTextStyles.title.copyWith(letterSpacing: 1.2))),
            TextButton.icon(
                onPressed: onCopy,
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('نسخ'))
          ]),
        ),
        if (coupon.estimatedDiscount > 0) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
              'التوفير المتوقع: ${coupon.estimatedDiscount.toStringAsFixed(0)} ر.ي',
              style: AppTextStyles.body.copyWith(
                  color: AppColors.success, fontWeight: FontWeight.w800)),
        ],
        if (coupon.validityMessage.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(coupon.validityMessage,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary)),
        ],
        const SizedBox(height: AppSpacing.md),
        Row(children: [
          Expanded(
              child: OutlinedButton(
                  onPressed: onCopy, child: const Text('نسخ الكود'))),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
              child: FilledButton(
                  onPressed: coupon.isApplicable ? onUse : null,
                  child: const Text('استخدم الآن')))
        ]),
      ]),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _InfoLine(this.label, this.value, {this.bold = false});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Expanded(
              child: Text(label,
                  style: bold
                      ? AppTextStyles.title
                      : AppTextStyles.bodySecondary)),
          Text(value,
              style: (bold ? AppTextStyles.heading2 : AppTextStyles.title)
                  .copyWith(color: AppColors.secondary))
        ]),
      );
}

class _StatePanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionText;
  final VoidCallback onAction;
  const _StatePanel(
      {required this.icon,
      required this.title,
      required this.message,
      required this.actionText,
      required this.onAction});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 56, color: AppColors.iconAccent),
            const SizedBox(height: AppSpacing.md),
            Text(title,
                textAlign: TextAlign.center, style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.sm),
            Text(message,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySecondary),
            const SizedBox(height: AppSpacing.lg),
            AppButton(text: actionText, onPressed: onAction)
          ]),
        ),
      );
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) => ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: 5,
        itemBuilder: (_, __) => Container(
            height: 118,
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(18))),
      );
}

BoxDecoration _box({Color? borderColor}) => BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor ?? AppColors.border),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadow, blurRadius: 14, offset: Offset(0, 8))
        ]);
