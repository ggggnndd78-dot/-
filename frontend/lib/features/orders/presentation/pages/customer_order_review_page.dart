import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/core/navigation/app_navigation.dart';
import 'package:ghiyarak/core/theme/app_colors.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/core/theme/app_text_styles.dart';
import 'package:ghiyarak/features/orders/data/orders_repository.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';

final _reviewOptionsProvider =
    FutureProvider.family<_ReviewOptions, String>((ref, orderId) async {
  final data =
      await ref.watch(ordersRepositoryProvider).getReviewOptions(orderId);
  return _ReviewOptions.fromMap(data);
});

class CustomerOrderReviewPage extends ConsumerStatefulWidget {
  final String orderId;
  const CustomerOrderReviewPage({super.key, required this.orderId});

  @override
  ConsumerState<CustomerOrderReviewPage> createState() =>
      _CustomerOrderReviewPageState();
}

class _CustomerOrderReviewPageState
    extends ConsumerState<CustomerOrderReviewPage> {
  final _comment = TextEditingController();
  final _attachment = TextEditingController();
  int _merchantRating = 5;
  int _productRating = 5;
  int _deliveryRating = 5;
  int _serviceRating = 5;
  bool _loading = false;
  bool _agree = false;

  @override
  void dispose() {
    _comment.dispose();
    _attachment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final options = ref.watch(_reviewOptionsProvider(widget.orderId));
    return AppScaffold(
      title: 'تقييم الطلب',
      child: options.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _StatePanel(
          icon: Icons.error_outline,
          title: 'تعذر تجهيز التقييم',
          message: error.toString(),
          actionText: 'العودة للطلب',
          onPressed: () => context.popOrGo(
            '${RouteNames.orderDetail}/${widget.orderId}',
          ),
        ),
        data: (data) {
          if (!data.canReview) {
            return _StatePanel(
              icon: Icons.lock_clock_outlined,
              title: 'التقييم غير متاح الآن',
              message: data.reason.isEmpty
                  ? 'يمكن تقييم الطلب بعد اكتماله فقط، ولا يمكن تكرار التقييم لنفس الطلب.'
                  : data.reason,
              actionText: 'تفاصيل الطلب',
              onPressed: () => context.popOrGo(
                '${RouteNames.orderDetail}/${widget.orderId}',
              ),
            );
          }
          return ListView(
            children: [
              _Header(options: data),
              const SizedBox(height: AppSpacing.lg),
              _RatingCard(
                  title: 'تقييم المتجر',
                  subtitle: 'التعامل، الالتزام، وضوح المعلومات',
                  value: _merchantRating,
                  onChanged: (v) => setState(() => _merchantRating = v)),
              const SizedBox(height: AppSpacing.md),
              _RatingCard(
                  title: 'جودة القطع',
                  subtitle: 'جودة القطع ومطابقتها للوصف',
                  value: _productRating,
                  onChanged: (v) => setState(() => _productRating = v)),
              const SizedBox(height: AppSpacing.md),
              _RatingCard(
                  title: 'التوصيل أو الاستلام',
                  subtitle: 'سرعة التسليم وسلامة التغليف',
                  value: _deliveryRating,
                  onChanged: (v) => setState(() => _deliveryRating = v)),
              const SizedBox(height: AppSpacing.md),
              _RatingCard(
                  title: 'الخدمة العامة',
                  subtitle: 'سهولة الطلب والمتابعة والدعم',
                  value: _serviceRating,
                  onChanged: (v) => setState(() => _serviceRating = v)),
              const SizedBox(height: AppSpacing.lg),
              _ItemsPreview(items: data.items),
              const SizedBox(height: AppSpacing.lg),
              _Card(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('تعليقك', style: AppTextStyles.title),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _comment,
                      minLines: 4,
                      maxLines: 8,
                      decoration: const InputDecoration(
                        labelText: 'اكتب تجربتك باختصار',
                        hintText:
                            'مثال: القطعة وصلت بسرعة وكانت مطابقة للوصف...',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _attachment,
                      decoration: const InputDecoration(
                        labelText: 'رابط صورة أو مرفق اختياري',
                        prefixIcon: Icon(Icons.attach_file),
                      ),
                    ),
                  ])),
              const SizedBox(height: AppSpacing.md),
              CheckboxListTile(
                value: _agree,
                onChanged: (v) => setState(() => _agree = v ?? false),
                title: const Text(
                    'أؤكد أن التقييم مبني على تجربتي الحقيقية مع هذا الطلب'),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                  text: _loading ? 'جارٍ الحفظ...' : 'إرسال التقييم',
                  onPressed: _loading || !_agree ? null : () => _submit(data)),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                  text: 'نسخ ملخص التقييم',
                  isOutlined: true,
                  onPressed: () => _copySummary(data)),
              const SizedBox(height: AppSpacing.xl),
            ],
          );
        },
      ),
    );
  }

  Future<void> _submit(_ReviewOptions data) async {
    setState(() => _loading = true);
    try {
      await ref.read(ordersRepositoryProvider).submitOrderReview(
            widget.orderId,
            merchantRating: _merchantRating,
            productRating: _productRating,
            deliveryRating: _deliveryRating,
            serviceRating: _serviceRating,
            comment: _comment.text,
            attachments: _attachment.text.trim().isEmpty
                ? null
                : [_attachment.text.trim()],
            productReviews: data.items
                .map((item) => {
                      if (item.productId != null) 'productId': item.productId,
                      if (item.orderItemId != null)
                        'orderItemId': item.orderItemId,
                      'rating': _productRating,
                      if (_comment.text.trim().isNotEmpty)
                        'comment': _comment.text.trim(),
                    })
                .toList(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إرسال التقييم بنجاح')));
      await context.pushReplacementPath(
        '${RouteNames.orderDetail}/${widget.orderId}',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _copySummary(_ReviewOptions data) async {
    final text =
        'تقييم طلب ${data.orderNumber}\nالمتجر: $_merchantRating/5\nالقطع: $_productRating/5\nالتوصيل: $_deliveryRating/5\nالخدمة: $_serviceRating/5\n${_comment.text.trim()}';
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('تم نسخ ملخص التقييم')));
    }
  }
}

class _Header extends StatelessWidget {
  final _ReviewOptions options;
  const _Header({required this.options});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
            gradient: AppColors.headerGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 18,
                  offset: Offset(0, 10))
            ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.stars_rounded,
                color: AppColors.secondary, size: 38),
            const SizedBox(width: AppSpacing.md),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('شارك تجربتك',
                      style:
                          AppTextStyles.heading2.copyWith(color: Colors.white)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(options.orderNumber,
                      style:
                          AppTextStyles.body.copyWith(color: Colors.white70)),
                ])),
          ]),
          const SizedBox(height: AppSpacing.md),
          Text('تقييمك يساعد العملاء الآخرين ويحسن جودة المتاجر داخل غيارك.',
              style: AppTextStyles.body.copyWith(color: Colors.white70)),
        ]),
      );
}

class _RatingCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final int value;
  final ValueChanged<int> onChanged;
  const _RatingCard(
      {required this.title,
      required this.subtitle,
      required this.value,
      required this.onChanged});
  @override
  Widget build(BuildContext context) => _Card(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: AppTextStyles.title),
        const SizedBox(height: AppSpacing.xs),
        Text(subtitle, style: AppTextStyles.bodySecondary),
        const SizedBox(height: AppSpacing.md),
        Row(
            children: List.generate(5, (i) {
          final star = i + 1;
          return IconButton(
            onPressed: () => onChanged(star),
            icon: Icon(
                star <= value ? Icons.star_rounded : Icons.star_border_rounded,
                color: AppColors.gold,
                size: 34),
          );
        })),
      ]));
}

class _ItemsPreview extends StatelessWidget {
  final List<_ReviewItem> items;
  const _ItemsPreview({required this.items});
  @override
  Widget build(BuildContext context) => _Card(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('القطع المشمولة بالتقييم', style: AppTextStyles.title),
        const SizedBox(height: AppSpacing.md),
        if (items.isEmpty)
          Text('لا توجد بنود ظاهرة لهذا الطلب.',
              style: AppTextStyles.bodySecondary)
        else
          ...items.map((item) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                    backgroundColor: AppColors.accentSoft,
                    child: Icon(Icons.build_circle_outlined,
                        color: AppColors.primary)),
                title: Text(item.title,
                    style: AppTextStyles.body
                        .copyWith(fontWeight: FontWeight.w800)),
                subtitle: Text('الكمية: ${item.quantity}',
                    style: AppTextStyles.bodySecondary),
              )),
      ]));
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border)),
        child: child,
      );
}

class _StatePanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionText;
  final VoidCallback onPressed;
  const _StatePanel(
      {required this.icon,
      required this.title,
      required this.message,
      required this.actionText,
      required this.onPressed});
  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: _Card(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: AppColors.iconAccent, size: 52),
            const SizedBox(height: AppSpacing.md),
            Text(title,
                style: AppTextStyles.title, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text(message,
                style: AppTextStyles.bodySecondary,
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            AppButton(text: actionText, onPressed: onPressed),
          ]))));
}

class _ReviewOptions {
  final bool canReview;
  final String reason;
  final String orderNumber;
  final List<_ReviewItem> items;
  const _ReviewOptions(
      {required this.canReview,
      required this.reason,
      required this.orderNumber,
      required this.items});
  factory _ReviewOptions.fromMap(Map<String, dynamic> map) => _ReviewOptions(
        canReview: map['canReview'] == true || map['can_review'] == true,
        reason: (map['reason'] ?? '').toString(),
        orderNumber:
            (map['orderNumber'] ?? map['order_number'] ?? '').toString(),
        items: _list(map['items']).map(_ReviewItem.fromMap).toList(),
      );
}

class _ReviewItem {
  final int? orderItemId;
  final int? productId;
  final String title;
  final int quantity;
  const _ReviewItem(
      {this.orderItemId,
      this.productId,
      required this.title,
      required this.quantity});
  factory _ReviewItem.fromMap(Map<String, dynamic> map) => _ReviewItem(
        orderItemId:
            _intOrNull(map['orderItemId'] ?? map['order_item_id'] ?? map['id']),
        productId: _intOrNull(map['productId'] ?? map['product_id']),
        title: (map['title'] ??
                map['productName'] ??
                map['product_name'] ??
                'قطعة')
            .toString(),
        quantity: _int(map['quantity'], fallback: 1),
      );
}

List<Map<String, dynamic>> _list(Object? value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
  return const [];
}

int _int(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

int? _intOrNull(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}
