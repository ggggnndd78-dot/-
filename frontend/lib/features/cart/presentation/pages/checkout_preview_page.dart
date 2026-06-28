import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/core/theme/app_colors.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/core/theme/app_text_styles.dart';
import 'package:ghiyarak/features/cart/data/cart_repository.dart';
import 'package:ghiyarak/features/cart/data/models/checkout_preview_model.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:go_router/go_router.dart';

class CheckoutPreviewPage extends ConsumerStatefulWidget {
  const CheckoutPreviewPage({super.key});

  @override
  ConsumerState<CheckoutPreviewPage> createState() =>
      _CheckoutPreviewPageState();
}

class _CheckoutPreviewPageState extends ConsumerState<CheckoutPreviewPage> {
  late Future<CheckoutPreviewModel> _future;
  bool _placing = false;
  String _fulfillmentMethod = 'pickup';
  final _couponController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _future = ref
        .read(cartRepositoryProvider)
        .checkoutPreview(fulfillmentMethod: _fulfillmentMethod);
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  String? get _couponCode {
    final value = _couponController.text.trim();
    return value.isEmpty ? null : value;
  }

  Future<void> _refreshPreview() async {
    setState(() {
      _future = ref.read(cartRepositoryProvider).checkoutPreview(
          couponCode: _couponCode, fulfillmentMethod: _fulfillmentMethod);
    });
  }

  Future<void> _placeOrder() async {
    setState(() => _placing = true);
    try {
      await ref.read(cartRepositoryProvider).placeOrder(
          couponCode: _couponCode, fulfillmentMethod: _fulfillmentMethod);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إنشاء الطلب بنجاح')),
      );
      context.go(RouteNames.myOrders);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'معاينة الطلب',
      child: FutureBuilder<CheckoutPreviewModel>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _StateMessage(
              icon: Icons.receipt_long_outlined,
              title: 'تعذر معاينة الطلب',
              message: snapshot.error.toString(),
            );
          }

          final preview = snapshot.data!;
          return ListView(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: AppColors.headerGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 18,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.verified_outlined,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'راجع طلبك قبل التأكيد',
                            style: AppTextStyles.title.copyWith(
                              color: AppColors.textOnDark,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'الأسعار والرسوم محسوبة من بيانات السلة الحالية.',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textOnDark.withValues(
                                alpha: 0.76,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('طريقة الاستلام', style: AppTextStyles.title),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<String>(
                      initialValue: _fulfillmentMethod,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.local_shipping_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'pickup', child: Text('استلام من المتجر')),
                        DropdownMenuItem(
                            value: 'delivery',
                            child: Text('توصيل حسب المدينة')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _fulfillmentMethod = value;
                          _future =
                              ref.read(cartRepositoryProvider).checkoutPreview(
                                    couponCode: _couponCode,
                                    fulfillmentMethod: _fulfillmentMethod,
                                  );
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _couponController,
                      cursorColor: AppColors.primary,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.local_offer_outlined),
                        labelText: 'كود الخصم',
                        hintText: 'اختياري',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppButton(
                      text: 'تحديث المعاينة',
                      isOutlined: true,
                      onPressed: _refreshPreview,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _TotalsCard(preview: preview),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                text: 'تأكيد الطلب',
                isLoading: _placing,
                onPressed: _placeOrder,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  final CheckoutPreviewModel preview;

  const _TotalsCard({required this.preview});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _amountRow(
            label: 'المجموع الفرعي',
            value: preview.subtotal,
            currency: preview.currency,
          ),
          const SizedBox(height: AppSpacing.sm),
          _amountRow(
            label: 'الخصم',
            value: preview.discount,
            currency: preview.currency,
            valueColor: AppColors.success,
          ),
          const SizedBox(height: AppSpacing.sm),
          _amountRow(
            label: 'رسوم التوصيل',
            value: preview.deliveryFee,
            currency: preview.currency,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Divider(color: AppColors.border, height: 1),
          ),
          _amountRow(
            label: 'الإجمالي',
            value: preview.total,
            currency: preview.currency,
            isTotal: true,
            valueColor: AppColors.secondary,
          ),
        ],
      ),
    );
  }

  Widget _amountRow({
    required String label,
    required double value,
    required String currency,
    bool isTotal = false,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style:
                (isTotal ? AppTextStyles.title : AppTextStyles.body).copyWith(
              color: isTotal ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          '${value.toStringAsFixed(0)} $currency',
          style:
              (isTotal ? AppTextStyles.heading2 : AppTextStyles.body).copyWith(
            color: valueColor ?? AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _StateMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _StateMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.iconAccent, size: 42),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
