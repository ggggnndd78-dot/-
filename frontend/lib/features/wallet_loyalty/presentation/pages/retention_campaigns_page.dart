import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/features/wallet_loyalty/data/wallet_loyalty_repository.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:ghiyarak/shared/widgets/section_title.dart';

final campaignsFutureProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>(
        (ref) => ref.watch(walletLoyaltyRepositoryProvider).campaigns());

class RetentionCampaignsPage extends ConsumerStatefulWidget {
  const RetentionCampaignsPage({super.key});
  @override
  ConsumerState<RetentionCampaignsPage> createState() =>
      _RetentionCampaignsPageState();
}

class _RetentionCampaignsPageState
    extends ConsumerState<RetentionCampaignsPage> {
  final _title = TextEditingController();
  final _messageTitle = TextEditingController();
  final _messageBody = TextEditingController();
  bool _busy = false;
  @override
  void dispose() {
    _title.dispose();
    _messageTitle.dispose();
    _messageBody.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_title.text.trim().isEmpty ||
        _messageTitle.text.trim().isEmpty ||
        _messageBody.text.trim().isEmpty) {
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(walletLoyaltyRepositoryProvider).createCampaign(
          title: _title.text.trim(),
          messageTitle: _messageTitle.text.trim(),
          messageBody: _messageBody.text.trim());
      ref.invalidate(campaignsFutureProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تم إنشاء الحملة')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final campaigns = ref.watch(campaignsFutureProvider);
    return AppScaffold(
      title: 'حملات الاحتفاظ',
      child: ListView(children: [
        const SectionTitle(
            title: 'حملات العملاء',
            subtitle:
                'أنشئ حملة برسالة فعلية من اختيارك. لا توجد بيانات وهمية هنا.'),
        const SizedBox(height: AppSpacing.md),
        TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'اسم الحملة')),
        const SizedBox(height: AppSpacing.sm),
        TextField(
            controller: _messageTitle,
            decoration: const InputDecoration(labelText: 'عنوان الرسالة')),
        const SizedBox(height: AppSpacing.sm),
        TextField(
            controller: _messageBody,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'نص الرسالة')),
        const SizedBox(height: AppSpacing.md),
        AppButton(
            text: _busy ? 'جاري الإنشاء...' : 'إنشاء حملة',
            onPressed: _busy ? null : _create),
        const SizedBox(height: AppSpacing.xl),
        campaigns.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('تعذر تحميل الحملات: $e'),
          data: (r) {
            final items = (r['data'] as List?) ?? [];
            if (items.isEmpty) return const Text('لا توجد حملات.');
            return Column(
                children: items
                    .map((e) => Card(
                        child: ListTile(
                            title: Text(e['title']?.toString() ?? ''),
                            subtitle:
                                Text('${e['audienceType']} - ${e['status']}'))))
                    .toList());
          },
        ),
      ]),
    );
  }
}
