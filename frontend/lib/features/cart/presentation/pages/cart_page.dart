import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/core/theme/app_colors.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/core/theme/app_text_styles.dart';
import 'package:ghiyarak/features/cart/data/cart_repository.dart';
import 'package:ghiyarak/features/cart/data/models/cart_item_model.dart';
import 'package:ghiyarak/features/cart/data/models/cart_model.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:go_router/go_router.dart';

class CartPage extends ConsumerStatefulWidget {
  const CartPage({super.key});

  @override
  ConsumerState<CartPage> createState() => _CartPageState();
}

class _CartPageState extends ConsumerState<CartPage> {
  late Future<CartModel> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(cartRepositoryProvider).getCart();
  }

  Future<void> _reload() async {
    setState(() {
      _future = ref.read(cartRepositoryProvider).getCart();
    });
  }

  Future<void> _removeItem(String id) async {
    await ref.read(cartRepositoryProvider).removeItem(id);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'السلة',
      child: FutureBuilder<CartModel>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _EmptyCartMessage(
              icon: Icons.error_outline,
              title: 'تعذر تحميل السلة',
              message: snapshot.error.toString(),
            );
          }

          final cart = snapshot.data ?? const CartModel();
          if (cart.items.isEmpty) {
            return const _EmptyCartMessage(
              icon: Icons.shopping_cart_outlined,
              title: 'السلة فارغة',
              message: 'أضف المنتجات المناسبة لسيارتك ثم تابع الطلب.',
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  itemCount: cart.items.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return _CartItemCard(
                      item: item,
                      onRemove: () => _removeItem(item.id),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'المجموع الجزئي',
                            style: AppTextStyles.title.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          '${cart.subtotal.toStringAsFixed(0)} ${cart.currency}',
                          style: AppTextStyles.heading2.copyWith(
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppButton(
                      text: 'معاينة الطلب',
                      onPressed: () => context.go(RouteNames.checkoutPreview),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final CartItemModel item;
  final VoidCallback onRemove;

  const _CartItemCard({
    required this.item,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.build_circle_outlined,
              color: AppColors.iconAccent,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: AppTextStyles.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'الكمية: ${item.quantity}',
                  style: AppTextStyles.bodySecondary,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${item.unitPrice.toStringAsFixed(0)} ${item.currency}',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'حذف',
            onPressed: onRemove,
            icon: const Icon(
              Icons.delete_outline,
              color: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCartMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyCartMessage({
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
            Icon(icon, color: AppColors.iconAccent, size: 44),
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
