import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/core/config/api_endpoints.dart';
import 'package:ghiyarak/core/network/api_client.dart';
import 'package:ghiyarak/core/theme/app_colors.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/core/theme/app_text_styles.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:go_router/go_router.dart';

class SupportPage extends ConsumerWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final help = ref.watch(_supportHelpProvider);

    return AppScaffold(
      title: 'الدعم',
      child: ListView(
        children: [
          const _HeaderCard(),
          const SizedBox(height: AppSpacing.lg),
          _SupportActions(
            onChat: () => context.go(
              Uri(
                path: RouteNames.customerChat,
                queryParameters: const {
                  'listingId': 'support',
                  'listingTitle': 'دعم العميل',
                  'providerName': 'خدمة العملاء',
                  'providerTypeLabel': 'دعم',
                  'serviceLabel': 'مساعدة مباشرة',
                },
              ).toString(),
            ),
            onOrders: () => context.go(RouteNames.myOrders),
            onTracking: () => context.go(RouteNames.customerTracking),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(child: Text('أسئلة مهمة', style: AppTextStyles.title)),
              IconButton.filledTonal(
                onPressed: () => ref.invalidate(_supportHelpProvider),
                icon: const Icon(Icons.refresh),
                tooltip: 'تحديث',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          help.when(
            loading: () => const _SupportLoadingCard(),
            error: (_, __) => const _FaqList(items: _fallbackFaqs),
            data: (items) => _FaqList(
              items: items.isEmpty ? _fallbackFaqs : items,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _SupportLoadingCard extends StatelessWidget {
  const _SupportLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _FaqList extends StatelessWidget {
  final List<_SupportFaq> items;

  const _FaqList({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final item in items)
          _FaqTile(title: item.question, answer: item.answer),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.circular(22),
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
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.support_agent,
              color: AppColors.secondary,
              size: 34,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'اختر مسار المساعدة المناسب. المحادثة والطلبات مرتبطة بحسابك حتى تبقى المتابعة محفوظة.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textOnDark.withValues(alpha: 0.86),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportActions extends StatelessWidget {
  final VoidCallback onChat;
  final VoidCallback onOrders;
  final VoidCallback onTracking;

  const _SupportActions({
    required this.onChat,
    required this.onOrders,
    required this.onTracking,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          AppButton(text: 'بدء محادثة دعم', onPressed: onChat),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: 'طلباتي',
                  isOutlined: true,
                  onPressed: onOrders,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  text: 'التتبع',
                  isOutlined: true,
                  onPressed: onTracking,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String title;
  final String answer;

  const _FaqTile({
    required this.title,
    required this.answer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: ExpansionTile(
        leading: const Icon(Icons.help_outline, color: AppColors.iconAccent),
        title: Text(title, style: AppTextStyles.title.copyWith(fontSize: 15)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Text(answer, style: AppTextStyles.bodySecondary),
          ),
        ],
      ),
    );
  }
}

class _SupportFaq {
  final String question;
  final String answer;

  const _SupportFaq({required this.question, required this.answer});

  factory _SupportFaq.fromMap(Map<String, dynamic> map) {
    return _SupportFaq(
      question:
          (map['question'] ?? map['questionAr'] ?? map['question_ar'] ?? '')
              .toString(),
      answer: (map['answer'] ?? map['answerAr'] ?? map['answer_ar'] ?? '')
          .toString(),
    );
  }
}

final _supportHelpProvider = FutureProvider<List<_SupportFaq>>((ref) async {
  final response = await ref.read(apiClientProvider).get(ApiEndpoints.helpFaqs);
  final raw = response.data;
  final data = raw is Map ? raw['data'] : raw;
  final list = data is Map ? data['items'] ?? data['faqs'] : data;
  if (list is! List) return const [];
  return list
      .whereType<Map>()
      .map((item) => _SupportFaq.fromMap(Map<String, dynamic>.from(item)))
      .where((item) => item.question.isNotEmpty && item.answer.isNotEmpty)
      .toList();
});

const _fallbackFaqs = [
  _SupportFaq(
    question: 'كيف أتتبع طلبي؟',
    answer:
        'افتح طلباتي ثم اختر الطلب المطلوب. ستجد تفاصيل الطلب وزر التتبع حسب حالته الحالية.',
  ),
  _SupportFaq(
    question: 'متى أستطيع طلب التركيب؟',
    answer:
        'التركيب يظهر فقط مع العروض التي يدعمها مزود من نوع ورشة أو مزود أعلن دعم التركيب.',
  ),
  _SupportFaq(
    question: 'لماذا لا تظهر نتائج لبعض القطع؟',
    answer:
        'نتائج البحث تعتمد على السيارة والموقع والفلاتر المختارة. غيّر كلمة البحث أو السيارة أو المنطقة إذا لم تظهر نتائج.',
  ),
  _SupportFaq(
    question: 'هل يمكنني الشراء كزائر؟',
    answer:
        'يمكنك التصفح وإضافة عناصر للسلة كزائر، لكن إنشاء الطلبات والتتبع يحتاج تسجيل دخول.',
  ),
];
