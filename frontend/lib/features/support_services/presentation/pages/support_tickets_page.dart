import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ghiyarak/core/theme/app_colors.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/core/theme/app_text_styles.dart';
import 'package:ghiyarak/features/support_services/data/support_repository.dart';
import 'package:ghiyarak/features/support_services/data/models/support_models.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:ghiyarak/shared/widgets/section_title.dart';

final AutoDisposeFutureProvider<List<SupportTicketModel>> _myTicketsProvider =
    FutureProvider.autoDispose<List<SupportTicketModel>>(
        (ref) => ref.read(supportRepositoryProvider).getMyTickets());
final AutoDisposeFutureProvider<List<SupportTicketModel>>
    _manageTicketsProvider =
    FutureProvider.autoDispose<List<SupportTicketModel>>(
        (ref) => ref.read(supportRepositoryProvider).getManageTickets());

class SupportTicketsPage extends ConsumerStatefulWidget {
  final bool manageMode;
  const SupportTicketsPage({super.key, this.manageMode = false});

  @override
  ConsumerState<SupportTicketsPage> createState() => _SupportTicketsPageState();
}

class _SupportTicketsPageState extends ConsumerState<SupportTicketsPage> {
  final _subject = TextEditingController();
  final _description = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _subject.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _createTicket() async {
    if (_subject.text.trim().isEmpty || _description.text.trim().isEmpty) {
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(supportRepositoryProvider).createTicket(
          subject: _subject.text.trim(), description: _description.text.trim());
      ref.invalidate(_myTicketsProvider);
      _subject.clear();
      _description.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إنشاء تذكرة الدعم')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tickets = ref
        .watch(widget.manageMode ? _manageTicketsProvider : _myTicketsProvider);
    return AppScaffold(
      title: widget.manageMode ? 'إدارة تذاكر الدعم' : 'تذاكر الدعم',
      child: ListView(children: [
        SectionTitle(
            title: widget.manageMode ? 'تذاكر العملاء' : 'الدعم الفني',
            subtitle: widget.manageMode
                ? 'البيانات تعرض من باك إند الإدارة حسب صلاحية الدعم.'
                : 'أنشئ تذكرة حقيقية مرتبطة بحسابك.'),
        if (!widget.manageMode) ...[
          const SizedBox(height: AppSpacing.md),
          TextField(
              controller: _subject,
              decoration: const InputDecoration(labelText: 'عنوان التذكرة')),
          const SizedBox(height: AppSpacing.sm),
          TextField(
              controller: _description,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'وصف المشكلة')),
          const SizedBox(height: AppSpacing.md),
          AppButton(
              text: _busy ? 'جاري الإنشاء...' : 'إنشاء تذكرة',
              onPressed: _busy ? null : _createTicket),
        ],
        const SizedBox(height: AppSpacing.lg),
        tickets.when(
          data: (items) => items.isEmpty
              ? const _Empty(text: 'لا توجد تذاكر.')
              : Column(
                  children: items
                      .map((ticket) => _TicketCard(ticket: ticket))
                      .toList()),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(e.toString())),
        ),
      ]),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final SupportTicketModel ticket;
  const _TicketCard({required this.ticket});
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () => context
            .go(RouteNames.customerSupportTicketDetails(ticket.id.toString())),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(ticket.subject, style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.xs),
            Text(
                '${ticket.ticketNumber} — ${ticket.status} — ${ticket.priority}',
                style: AppTextStyles.bodySecondary),
          ]),
        ),
      );
}

class _Empty extends StatelessWidget {
  final String text;
  const _Empty({required this.text});
  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppTextStyles.bodySecondary);
}
