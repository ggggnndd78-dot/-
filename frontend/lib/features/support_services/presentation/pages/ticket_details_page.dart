import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/theme/app_colors.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/core/theme/app_text_styles.dart';
import 'package:ghiyarak/features/support_services/data/support_repository.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:ghiyarak/shared/widgets/section_title.dart';

final _ticketDetailsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>(
        (ref, id) => ref.read(supportRepositoryProvider).getTicketDetails(id));

class TicketDetailsPage extends ConsumerStatefulWidget {
  final String ticketId;
  const TicketDetailsPage({super.key, required this.ticketId});

  @override
  ConsumerState<TicketDetailsPage> createState() => _TicketDetailsPageState();
}

class _TicketDetailsPageState extends ConsumerState<TicketDetailsPage> {
  final _message = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_message.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(supportRepositoryProvider)
          .addTicketMessage(widget.ticketId, _message.text.trim());
      _message.clear();
      ref.invalidate(_ticketDetailsProvider(widget.ticketId));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final details = ref.watch(_ticketDetailsProvider(widget.ticketId));
    return AppScaffold(
      title: 'تفاصيل التذكرة',
      child: details.when(
        data: (ticket) {
          final messages = ticket['messages'] is List
              ? ticket['messages'] as List
              : const [];
          return ListView(children: [
            SectionTitle(
                title: ticket['subject']?.toString() ?? 'تذكرة دعم',
                subtitle:
                    '${ticket['ticketNumber'] ?? ''} — ${ticket['status'] ?? ''}'),
            const SizedBox(height: AppSpacing.lg),
            ...messages.map((m) =>
                _MessageCard(message: Map<String, dynamic>.from(m as Map))),
            const SizedBox(height: AppSpacing.lg),
            TextField(
                controller: _message,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'رسالة جديدة')),
            const SizedBox(height: AppSpacing.md),
            AppButton(
                text: _busy ? 'جاري الإرسال...' : 'إرسال',
                onPressed: _busy ? null : _send),
          ]);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final Map<String, dynamic> message;
  const _MessageCard({required this.message});

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
        Text(message['messageType']?.toString() ?? 'MESSAGE',
            style: AppTextStyles.caption),
        const SizedBox(height: AppSpacing.xs),
        Text(message['body']?.toString() ?? '', style: AppTextStyles.body),
      ]),
    );
  }
}
