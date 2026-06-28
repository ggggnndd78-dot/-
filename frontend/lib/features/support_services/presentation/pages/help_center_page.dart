import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/theme/app_colors.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/core/theme/app_text_styles.dart';
import 'package:ghiyarak/features/support_services/data/models/support_models.dart';
import 'package:ghiyarak/features/support_services/data/support_repository.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:ghiyarak/shared/widgets/section_title.dart';

final _helpCategoriesProvider =
    FutureProvider.autoDispose<List<HelpCenterCategoryModel>>(
        (ref) => ref.read(supportRepositoryProvider).getHelpCategories());
final _helpArticlesProvider =
    FutureProvider.autoDispose<List<HelpArticleModel>>(
        (ref) => ref.read(supportRepositoryProvider).getHelpArticles());
final _faqsProvider = FutureProvider.autoDispose<List<FaqModel>>(
    (ref) => ref.read(supportRepositoryProvider).getFaqs());
final _whatsappLinksProvider =
    FutureProvider.autoDispose<List<WhatsappSupportLinkModel>>(
        (ref) => ref.read(supportRepositoryProvider).getWhatsappLinks());

class HelpCenterPage extends ConsumerWidget {
  const HelpCenterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(_helpCategoriesProvider);
    final articles = ref.watch(_helpArticlesProvider);
    final faqs = ref.watch(_faqsProvider);
    final links = ref.watch(_whatsappLinksProvider);
    return AppScaffold(
      title: 'مركز المساعدة',
      child: ListView(children: [
        const SectionTitle(
            title: 'مركز المساعدة والدعم',
            subtitle: 'مقالات، أسئلة شائعة، وروابط تواصل واتساب من النظام.'),
        const SizedBox(height: AppSpacing.lg),
        _SectionAsync<HelpCenterCategoryModel>(
          title: 'الأقسام',
          value: categories,
          emptyText: 'لا توجد أقسام مساعدة.',
          builder: (item) => _SimpleCard(
              title: item.title,
              subtitle:
                  item.description.isEmpty ? item.code : item.description),
        ),
        const SizedBox(height: AppSpacing.lg),
        _SectionAsync<HelpArticleModel>(
          title: 'مقالات مساعدة',
          value: articles,
          emptyText: 'لا توجد مقالات منشورة.',
          builder: (item) => _SimpleCard(
              title: item.title,
              subtitle: item.summary.isEmpty ? item.body : item.summary),
        ),
        const SizedBox(height: AppSpacing.lg),
        _SectionAsync<FaqModel>(
          title: 'الأسئلة الشائعة',
          value: faqs,
          emptyText: 'لا توجد أسئلة شائعة.',
          builder: (item) =>
              _SimpleCard(title: item.question, subtitle: item.answer),
        ),
        const SizedBox(height: AppSpacing.lg),
        _SectionAsync<WhatsappSupportLinkModel>(
          title: 'روابط واتساب',
          value: links,
          emptyText: 'لا توجد روابط واتساب مفعلة.',
          builder: (item) => _SimpleCard(
              title: item.title,
              subtitle: '${item.department} — ${item.phone}'),
        ),
      ]),
    );
  }
}

class _SectionAsync<T> extends StatelessWidget {
  final String title;
  final AsyncValue<List<T>> value;
  final Widget Function(T item) builder;
  final String emptyText;
  const _SectionAsync(
      {required this.title,
      required this.value,
      required this.builder,
      required this.emptyText});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: AppTextStyles.title),
      const SizedBox(height: AppSpacing.sm),
      value.when(
        data: (items) => items.isEmpty
            ? Text(emptyText, style: AppTextStyles.bodySecondary)
            : Column(children: items.map(builder).toList()),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text(e.toString(), style: AppTextStyles.bodySecondary),
      ),
    ]);
  }
}

class _SimpleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SimpleCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: AppTextStyles.title),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(subtitle,
              style: AppTextStyles.bodySecondary,
              maxLines: 4,
              overflow: TextOverflow.ellipsis),
        ],
      ]),
    );
  }
}
