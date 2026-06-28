import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/theme/app_colors.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/core/theme/app_text_styles.dart';
import 'package:ghiyarak/features/support_services/data/support_repository.dart';
import 'package:ghiyarak/features/support_services/data/models/support_models.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:ghiyarak/shared/widgets/section_title.dart';

final AutoDisposeFutureProvider<List<ComplaintModel>> _complaintsProvider =
    FutureProvider.autoDispose<List<ComplaintModel>>(
        (ref) => ref.read(supportRepositoryProvider).getMyComplaints());
final AutoDisposeFutureProvider<List<ComplaintModel>>
    _manageComplaintsProvider =
    FutureProvider.autoDispose<List<ComplaintModel>>(
        (ref) => ref.read(supportRepositoryProvider).getManageComplaints());

class ComplaintsPage extends ConsumerStatefulWidget {
  final bool manageMode;
  const ComplaintsPage({super.key, this.manageMode = false});

  @override
  ConsumerState<ComplaintsPage> createState() => _ComplaintsPageState();
}

class _ComplaintsPageState extends ConsumerState<ComplaintsPage> {
  final _subject = TextEditingController();
  final _description = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _subject.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _createComplaint() async {
    if (_subject.text.trim().isEmpty || _description.text.trim().isEmpty) {
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(supportRepositoryProvider).createComplaint(
          subject: _subject.text.trim(), description: _description.text.trim());
      ref.invalidate(_complaintsProvider);
      _subject.clear();
      _description.clear();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تم إنشاء الشكوى')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final complaints = ref.watch(
        widget.manageMode ? _manageComplaintsProvider : _complaintsProvider);
    return AppScaffold(
      title: widget.manageMode ? 'إدارة الشكاوى' : 'الشكاوى',
      child: ListView(children: [
        SectionTitle(
            title: widget.manageMode ? 'شكاوى العملاء' : 'مركز الشكاوى',
            subtitle: widget.manageMode
                ? 'إدارة الشكاوى الفعلية حسب الصلاحيات.'
                : 'سجّل شكوى فعلية مرتبطة بحسابك.'),
        if (!widget.manageMode) ...[
          const SizedBox(height: AppSpacing.md),
          TextField(
              controller: _subject,
              decoration: const InputDecoration(labelText: 'عنوان الشكوى')),
          const SizedBox(height: AppSpacing.sm),
          TextField(
              controller: _description,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'وصف الشكوى')),
          const SizedBox(height: AppSpacing.md),
          AppButton(
              text: _busy ? 'جاري الإنشاء...' : 'إنشاء شكوى',
              onPressed: _busy ? null : _createComplaint),
        ],
        const SizedBox(height: AppSpacing.lg),
        complaints.when(
          data: (items) => items.isEmpty
              ? const _Empty(text: 'لا توجد شكاوى.')
              : Column(
                  children: items
                      .map((complaint) => _ComplaintCard(complaint: complaint))
                      .toList()),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(e.toString())),
        ),
      ]),
    );
  }
}

class _ComplaintCard extends StatelessWidget {
  final ComplaintModel complaint;
  const _ComplaintCard({required this.complaint});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(complaint.subject, style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.xs),
          Text(
              '${complaint.complaintNumber} — ${complaint.status} — ${complaint.severity}',
              style: AppTextStyles.bodySecondary),
        ]),
      );
}

class _Empty extends StatelessWidget {
  final String text;
  const _Empty({required this.text});
  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppTextStyles.bodySecondary);
}
