import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/features/merchant_market/data/merchant_market_repository.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_management_scaffold.dart';

class MerchantReviewsPage extends ConsumerStatefulWidget {
  const MerchantReviewsPage({super.key});

  @override
  ConsumerState<MerchantReviewsPage> createState() =>
      _MerchantReviewsPageState();
}

class _MerchantReviewsPageState extends ConsumerState<MerchantReviewsPage> {
  late Future<Map<String, List<Map<String, dynamic>>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, List<Map<String, dynamic>>>> _load() {
    return ref.read(merchantMarketRepositoryProvider).getMerchantReviews();
  }

  Future<void> _reply({
    required String type,
    required String id,
    required String replyText,
  }) async {
    try {
      await ref.read(merchantMarketRepositoryProvider).replyToMerchantReview(
            type: type,
            id: id,
            replyText: replyText,
          );
      if (mounted) setState(() => _future = _load());
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
      future: _future,
      builder: (context, snapshot) {
        final data =
            snapshot.data ?? const <String, List<Map<String, dynamic>>>{};
        final merchantReviews =
            data['merchant'] ?? const <Map<String, dynamic>>[];
        final productReviews =
            data['products'] ?? const <Map<String, dynamic>>[];
        final all = [...merchantReviews, ...productReviews];
        return MerchantManagementScaffold(
          title: 'تقييمات العملاء',
          subtitle:
              'قراءة تقييمات المتجر والمنتجات والرد عليها من حساب التاجر بشكل موثق.',
          onRefresh: () async => setState(() => _future = _load()),
          children: [
            if (snapshot.connectionState != ConnectionState.done)
              const Center(child: CircularProgressIndicator())
            else if (snapshot.hasError)
              MerchantStateCard(
                icon: Icons.error_outline,
                title: 'تعذر تحميل التقييمات',
                message: snapshot.error.toString(),
                actionLabel: 'إعادة المحاولة',
                onAction: () => setState(() => _future = _load()),
              )
            else if (all.isEmpty)
              const MerchantStateCard(
                icon: Icons.star_border_rounded,
                title: 'لا توجد تقييمات بعد',
                message:
                    'تقييمات العملاء على المتجر والمنتجات ستظهر هنا بعد اكتمال الطلبات.',
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: MerchantMetricTile(
                      icon: Icons.star_rate_rounded,
                      label: 'متوسط التقييم',
                      value: _averageRating(all),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: MerchantMetricTile(
                      icon: Icons.reviews_outlined,
                      label: 'عدد التقييمات',
                      value: '${all.length}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (merchantReviews.isNotEmpty)
                _ReviewSection(
                  title: 'تقييمات المتجر',
                  type: 'MERCHANT',
                  reviews: merchantReviews,
                  onReply: _reply,
                ),
              if (productReviews.isNotEmpty)
                _ReviewSection(
                  title: 'تقييمات المنتجات',
                  type: 'PRODUCT',
                  reviews: productReviews,
                  onReply: _reply,
                ),
            ],
          ],
        );
      },
    );
  }
}

class _ReviewSection extends StatelessWidget {
  const _ReviewSection({
    required this.title,
    required this.type,
    required this.reviews,
    required this.onReply,
  });

  final String title;
  final String type;
  final List<Map<String, dynamic>> reviews;
  final Future<void> Function({
    required String type,
    required String id,
    required String replyText,
  }) onReply;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF082B51),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          ...reviews.map(
            (item) => _ReviewCard(item: item, type: type, onReply: onReply),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.item,
    required this.type,
    required this.onReply,
  });

  final Map<String, dynamic> item;
  final String type;
  final Future<void> Function({
    required String type,
    required String id,
    required String replyText,
  }) onReply;

  @override
  Widget build(BuildContext context) {
    final id = _text(item, ['id', 'review_id', 'reviewId']);
    final customer = _text(item, ['customer_name', 'customerName']);
    final product = _text(item, ['product_name', 'productName']);
    final comment = _text(item, ['comment', 'review_text', 'reviewText']);
    final reply = _text(item, ['reply_text', 'replyText', 'merchant_reply']);
    final rating = int.tryParse(_text(item, ['rating'])) ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: MerchantPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    product.isEmpty ? 'تقييم المتجر' : product,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _Stars(rating: rating),
              ],
            ),
            if (customer.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                customer,
                style: const TextStyle(color: Color(0xFF687686)),
              ),
            ],
            if (comment.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(comment, style: const TextStyle(height: 1.45)),
            ],
            if (reply.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFDCE4EC)),
                ),
                child: Text('رد المتجر: $reply'),
              ),
            ],
            if (id.isNotEmpty) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: () => _showReplySheet(context, id),
                  icon: const Icon(Icons.reply_rounded),
                  label: Text(reply.isEmpty ? 'إضافة رد' : 'تعديل الرد'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showReplySheet(BuildContext context, String id) async {
    final controller = TextEditingController();
    final replyText = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              MediaQuery.viewInsetsOf(sheetContext).bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'رد التاجر',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'اكتب رد واضح ومهني للعميل',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () {
                    final value = controller.text.trim();
                    if (value.isNotEmpty) Navigator.pop(sheetContext, value);
                  },
                  child: const Text('حفظ الرد'),
                ),
              ],
            ),
          ),
        );
      },
    );
    controller.dispose();
    if (replyText == null || replyText.isEmpty) return;
    await onReply(type: type, id: id, replyText: replyText);
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.rating});

  final int rating;

  @override
  Widget build(BuildContext context) {
    final safeRating = rating.clamp(0, 5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (index) => Icon(
          index < safeRating ? Icons.star_rounded : Icons.star_border_rounded,
          color: const Color(0xFFFF9D1B),
          size: 18,
        ),
      ),
    );
  }
}

String _averageRating(List<Map<String, dynamic>> items) {
  final ratings = items
      .map((item) => num.tryParse(_text(item, ['rating'])))
      .whereType<num>()
      .toList();
  if (ratings.isEmpty) return '0.0';
  final average = ratings.reduce((a, b) => a + b) / ratings.length;
  return average.toStringAsFixed(1);
}

String _text(
  Map<String, dynamic> item,
  List<String> keys, {
  String fallback = '',
}) {
  for (final key in keys) {
    final value = item[key];
    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString();
    }
  }
  return fallback;
}
