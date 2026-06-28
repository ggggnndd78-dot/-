import 'package:flutter/material.dart';
import 'package:ghiyarak/core/theme/app_colors.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/core/theme/app_text_styles.dart';
import 'package:ghiyarak/features/cart/data/models/checkout_preview_model.dart';

class CheckoutOrderReviewCard extends StatelessWidget {
  final CheckoutPreviewModel preview;
  final String fulfillmentLabel;
  final String paymentLabel;
  final String locationLabel;
  final String? customerNote;

  const CheckoutOrderReviewCard({
    super.key,
    required this.preview,
    required this.fulfillmentLabel,
    required this.paymentLabel,
    required this.locationLabel,
    this.customerNote,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fact_check_outlined,
                  color: AppColors.iconAccent),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'مراجعة الطلب قبل التأكيد',
                  style: AppTextStyles.title,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _SummaryStrip(
            fulfillmentLabel: fulfillmentLabel,
            paymentLabel: paymentLabel,
            locationLabel: locationLabel,
          ),
          const SizedBox(height: AppSpacing.md),
          if (preview.merchants.isEmpty)
            const _EmptyPreview()
          else
            ...preview.merchants.map(
              (merchant) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _MerchantGroup(
                  merchant: merchant,
                  currency: preview.currency,
                ),
              ),
            ),
          if (preview.coupon != null) ...[
            const SizedBox(height: AppSpacing.xs),
            _CouponLine(coupon: preview.coupon!, currency: preview.currency),
          ],
          if ((customerNote ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _NoteLine(note: customerNote!.trim()),
          ],
        ],
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  final String fulfillmentLabel;
  final String paymentLabel;
  final String locationLabel;

  const _SummaryStrip({
    required this.fulfillmentLabel,
    required this.paymentLabel,
    required this.locationLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _SummaryRow(
            icon: Icons.local_shipping_outlined,
            label: 'الاستلام',
            value: fulfillmentLabel,
          ),
          const SizedBox(height: AppSpacing.xs),
          _SummaryRow(
            icon: Icons.payments_outlined,
            label: 'الدفع',
            value: paymentLabel,
          ),
          const SizedBox(height: AppSpacing.xs),
          _SummaryRow(
            icon: Icons.location_on_outlined,
            label: 'الموقع',
            value: locationLabel,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.iconAccent, size: 20),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '$label: ',
          style: AppTextStyles.body.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}

class _MerchantGroup extends StatelessWidget {
  final CheckoutMerchantPreview merchant;
  final String currency;

  const _MerchantGroup({
    required this.merchant,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: const BoxDecoration(
              color: AppColors.surfaceTint,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.storefront_outlined, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    merchant.organizationName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.title.copyWith(fontSize: 16),
                  ),
                ),
                Text(
                  '${merchant.items.length} قطع',
                  style: AppTextStyles.bodySecondary.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < merchant.items.length; i++) ...[
            _ItemRow(item: merchant.items[i], currency: currency),
            if (i != merchant.items.length - 1)
              const Divider(height: 1, color: AppColors.border),
          ],
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                _AmountRow(
                  label: 'إجمالي المتجر',
                  value: merchant.subtotal,
                  currency: currency,
                ),
                if (merchant.deliveryFee > 0) ...[
                  const SizedBox(height: 4),
                  _AmountRow(
                    label: 'نصيبه من التوصيل',
                    value: merchant.deliveryFee,
                    currency: currency,
                  ),
                ],
                if (merchant.discount > 0) ...[
                  const SizedBox(height: 4),
                  _AmountRow(
                    label: 'الخصم',
                    value: merchant.discount,
                    currency: currency,
                    valueColor: AppColors.success,
                  ),
                ],
                const SizedBox(height: 8),
                _AmountRow(
                  label: 'المجموع',
                  value: merchant.total,
                  currency: currency,
                  strong: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final CheckoutItemPreview item;
  final String currency;

  const _ItemRow({
    required this.item,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.build_circle_outlined,
                color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${item.quantity} x ${item.unitPrice.toStringAsFixed(0)} $currency',
                  style: AppTextStyles.bodySecondary,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${item.total.toStringAsFixed(0)} $currency',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  final String label;
  final double value;
  final String currency;
  final Color? valueColor;
  final bool strong;

  const _AmountRow({
    required this.label,
    required this.value,
    required this.currency,
    this.valueColor,
    this.strong = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.body.copyWith(
              color: strong ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: strong ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
        ),
        Text(
          '${value.toStringAsFixed(0)} $currency',
          style: AppTextStyles.body.copyWith(
            color: valueColor ?? AppColors.textPrimary,
            fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _CouponLine extends StatelessWidget {
  final CheckoutCouponModel coupon;
  final String currency;

  const _CouponLine({
    required this.coupon,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_offer_outlined, color: AppColors.success),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'تم تطبيق كوبون ${coupon.code}',
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          Text(
            '-${coupon.discountAmount.toStringAsFixed(0)} $currency',
            style: AppTextStyles.body.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteLine extends StatelessWidget {
  final String note;

  const _NoteLine({required this.note});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        'ملاحظة الطلب: $note',
        style: AppTextStyles.bodySecondary.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyPreview extends StatelessWidget {
  const _EmptyPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        'لا توجد قطع في المعاينة الحالية.',
        textAlign: TextAlign.center,
        style: AppTextStyles.bodySecondary,
      ),
    );
  }
}
