import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/theme/app_colors.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/core/theme/app_text_styles.dart';
import 'package:ghiyarak/features/support_services/data/models/support_models.dart';
import 'package:ghiyarak/features/support_services/data/support_repository.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:ghiyarak/shared/widgets/section_title.dart';

final AutoDisposeFutureProvider<Map<String, List<ReviewModel>>>
    _myReviewsProvider =
    FutureProvider.autoDispose<Map<String, List<ReviewModel>>>(
        (ref) => ref.read(supportRepositoryProvider).getMyReviews());
final AutoDisposeFutureProvider<Map<String, List<ReviewModel>>>
    _adminReviewsProvider =
    FutureProvider.autoDispose<Map<String, List<ReviewModel>>>(
        (ref) => ref.read(supportRepositoryProvider).getAdminReviews());

class ReviewsPage extends ConsumerStatefulWidget {
  final bool manageMode;
  const ReviewsPage({super.key, this.manageMode = false});

  @override
  ConsumerState<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends ConsumerState<ReviewsPage> {
  final _targetId = TextEditingController();
  final _orderId = TextEditingController();
  final _organizationId = TextEditingController();
  final _title = TextEditingController();
  final _body = TextEditingController();
  String _type = 'MERCHANT';
  int _rating = 5;
  bool _busy = false;

  @override
  void dispose() {
    _targetId.dispose();
    _orderId.dispose();
    _organizationId.dispose();
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _createReview() async {
    final repo = ref.read(supportRepositoryProvider);
    final title = _title.text.trim();
    final body = _body.text.trim();
    if (title.isEmpty || body.isEmpty) return;
    setState(() => _busy = true);
    try {
      if (_type == 'PRODUCT') {
        final productId = int.tryParse(_targetId.text.trim());
        final orderId = int.tryParse(_orderId.text.trim());
        if (productId == null || orderId == null) return;
        await repo.createProductReview(
            productId: productId,
            orderId: orderId,
            rating: _rating,
            title: title,
            body: body);
      } else if (_type == 'MERCHANT') {
        final organizationId = int.tryParse(_organizationId.text.trim());
        final orderId = int.tryParse(_orderId.text.trim());
        if (organizationId == null || orderId == null) return;
        await repo.createMerchantReview(
            organizationId: organizationId,
            orderId: orderId,
            rating: _rating,
            title: title,
            body: body);
      } else if (_type == 'WORKSHOP') {
        final organizationId = int.tryParse(_organizationId.text.trim());
        final serviceOrderId = int.tryParse(_orderId.text.trim());
        if (organizationId == null || serviceOrderId == null) return;
        await repo.createWorkshopReview(
            organizationId: organizationId,
            serviceOrderId: serviceOrderId,
            rating: _rating,
            title: title,
            body: body);
      } else {
        final serviceOrderId = int.tryParse(_orderId.text.trim());
        if (serviceOrderId == null) return;
        await repo.createServiceReview(
            serviceOrderId: serviceOrderId,
            rating: _rating,
            title: title,
            body: body);
      }
      ref.invalidate(_myReviewsProvider);
      _targetId.clear();
      _orderId.clear();
      _organizationId.clear();
      _title.clear();
      _body.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('تم حفظ التقييم بعد التحقق من الأهلية')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _moderate(ReviewModel review, String action) async {
    await ref.read(supportRepositoryProvider).moderateReview(
        targetType: review.targetType, reviewId: review.id, action: action);
    ref.invalidate(_adminReviewsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final reviews = ref
        .watch(widget.manageMode ? _adminReviewsProvider : _myReviewsProvider);
    return AppScaffold(
      title: widget.manageMode ? 'إدارة السمعة والتقييمات' : 'تقييماتي',
      child: ListView(children: [
        SectionTitle(
          title: widget.manageMode
              ? 'مراجعة التقييمات والسمعة'
              : 'تقييمات موثقة فقط',
          subtitle: widget.manageMode
              ? 'إخفاء أو استعادة التقييمات المخالفة مع سجل تدقيق.'
              : 'لا يمكن إنشاء تقييم إلا بعد طلب مكتمل أو خدمة مكتملة.',
        ),
        if (!widget.manageMode) ...[
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _type,
            decoration: const InputDecoration(labelText: 'نوع التقييم'),
            items: const [
              DropdownMenuItem(value: 'MERCHANT', child: Text('تقييم تاجر')),
              DropdownMenuItem(value: 'PRODUCT', child: Text('تقييم منتج')),
              DropdownMenuItem(value: 'WORKSHOP', child: Text('تقييم ورشة')),
              DropdownMenuItem(value: 'SERVICE', child: Text('تقييم خدمة')),
            ],
            onChanged: (value) => setState(() => _type = value ?? 'MERCHANT'),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_type == 'PRODUCT')
            TextField(
                controller: _targetId,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'رقم المنتج')),
          if (_type == 'MERCHANT' || _type == 'WORKSHOP')
            TextField(
                controller: _organizationId,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'رقم المؤسسة')),
          const SizedBox(height: AppSpacing.sm),
          TextField(
              controller: _orderId,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                  labelText: _type == 'MERCHANT' || _type == 'PRODUCT'
                      ? 'رقم الطلب المكتمل'
                      : 'رقم أمر الخدمة المكتمل')),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<int>(
              initialValue: _rating,
              decoration: const InputDecoration(labelText: 'التقييم'),
              items: [1, 2, 3, 4, 5]
                  .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
                  .toList(),
              onChanged: (v) => _rating = v ?? 5),
          const SizedBox(height: AppSpacing.sm),
          TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'عنوان التقييم')),
          const SizedBox(height: AppSpacing.sm),
          TextField(
              controller: _body,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'تفاصيل التقييم')),
          const SizedBox(height: AppSpacing.md),
          AppButton(
              text: _busy ? 'جاري الحفظ...' : 'حفظ تقييم موثق',
              onPressed: _busy ? null : _createReview),
        ],
        const SizedBox(height: AppSpacing.lg),
        reviews.when(
          data: (groups) {
            final all = groups.values.expand((items) => items).toList();
            if (all.isEmpty) return const Text('لا توجد تقييمات.');
            return Column(
                children: all
                    .map((review) => _ReviewCard(
                        review: review,
                        manageMode: widget.manageMode,
                        onHide: () => _moderate(review, 'HIDDEN'),
                        onRestore: () => _moderate(review, 'RESTORED')))
                    .toList());
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(e.toString())),
        ),
      ]),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ReviewModel review;
  final bool manageMode;
  final VoidCallback onHide;
  final VoidCallback onRestore;
  const _ReviewCard(
      {required this.review,
      required this.manageMode,
      required this.onHide,
      required this.onRestore});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Text('${review.rating}/5 — ${review.title}',
                  style: AppTextStyles.title)),
          Text(review.targetType, style: AppTextStyles.bodySecondary),
        ]),
        const SizedBox(height: AppSpacing.xs),
        Text(
            review.body.isEmpty
                ? review.status
                : '${review.body} — ${review.status}',
            style: AppTextStyles.bodySecondary),
        const SizedBox(height: AppSpacing.xs),
        Text('ردود: ${review.repliesCount} | مرفقات: ${review.mediaCount}',
            style: AppTextStyles.bodySecondary),
        if (manageMode) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(children: [
            Expanded(
                child: OutlinedButton(
                    onPressed: onHide, child: const Text('إخفاء'))),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
                child: OutlinedButton(
                    onPressed: onRestore, child: const Text('استعادة'))),
          ]),
        ],
      ]),
    );
  }
}
