import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/core/navigation/app_navigation.dart';
import 'package:ghiyarak/core/theme/app_colors.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/core/theme/app_text_styles.dart';
import 'package:ghiyarak/features/auth/data/auth_repository.dart';
import 'package:ghiyarak/features/chat/data/customer_chat_repository.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';

class CustomerChatPage extends ConsumerStatefulWidget {
  final String listingId;
  final String listingTitle;
  final String providerName;
  final String providerTypeLabel;
  final String serviceLabel;

  const CustomerChatPage({
    super.key,
    required this.listingId,
    required this.listingTitle,
    required this.providerName,
    required this.providerTypeLabel,
    required this.serviceLabel,
  });

  @override
  ConsumerState<CustomerChatPage> createState() => _CustomerChatPageState();
}

class _CustomerChatPageState extends ConsumerState<CustomerChatPage> {
  final _messageController = TextEditingController();
  final _searchController = TextEditingController();
  final _attachmentController = TextEditingController();
  final _scrollController = ScrollController();
  CustomerChatInbox? _inbox;
  CustomerConversation? _conversation;
  bool _loading = true;
  bool _authenticated = false;
  bool _sending = false;
  String _status = 'ALL';
  bool _unreadOnly = false;
  Timer? _refreshTimer;
  final List<String> _pendingAttachments = [];

  bool get _hasInitialConversation =>
      widget.listingId.trim().isNotEmpty ||
      widget.providerName != 'مزود' ||
      widget.listingTitle != 'استفسار عن قطعة';

  @override
  void initState() {
    super.initState();
    _load();
    _refreshTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      if (mounted && _authenticated) _silentRefresh();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _searchController.dispose();
    _attachmentController.dispose();
    _scrollController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final authRepository = ref.read(authRepositoryProvider);
    final isAuthenticated = await authRepository.isAuthenticated();
    if (!mounted) return;
    if (!isAuthenticated) {
      setState(() {
        _authenticated = false;
        _loading = false;
      });
      return;
    }
    try {
      CustomerConversation? conversation;
      if (_hasInitialConversation) {
        conversation =
            await ref.read(customerChatRepositoryProvider).openConversation(
                  listingId: widget.listingId,
                  listingTitle: widget.listingTitle,
                  providerName: widget.providerName,
                  providerTypeLabel: widget.providerTypeLabel,
                  serviceLabel: widget.serviceLabel,
                  orderId: widget.listingId.startsWith('order-')
                      ? widget.listingId.replaceFirst('order-', '')
                      : null,
                );
        await ref
            .read(customerChatRepositoryProvider)
            .markRead(conversation.id);
      }
      final inbox =
          await ref.read(customerChatRepositoryProvider).conversations(
                query: _searchController.text,
                status: _status,
                unreadOnly: _unreadOnly,
              );
      if (!mounted) return;
      setState(() {
        _authenticated = true;
        _conversation = conversation;
        _inbox = inbox;
        _loading = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _snack('تعذر تحميل المحادثات: $e');
    }
  }

  Future<void> _silentRefresh() async {
    try {
      if (_conversation != null) {
        final updated = await ref
            .read(customerChatRepositoryProvider)
            .getConversation(_conversation!.id);
        if (mounted) {
          setState(() => _conversation = updated.copyWith(unreadCount: 0));
        }
      }
      final inbox =
          await ref.read(customerChatRepositoryProvider).conversations(
                query: _searchController.text,
                status: _status,
                unreadOnly: _unreadOnly,
              );
      if (mounted) setState(() => _inbox = inbox);
    } catch (_) {}
  }

  Future<void> _open(CustomerConversation item) async {
    setState(() => _loading = true);
    try {
      final conversation = await ref
          .read(customerChatRepositoryProvider)
          .getConversation(item.id);
      await ref.read(customerChatRepositoryProvider).markRead(item.id);
      if (!mounted) return;
      setState(() {
        _conversation = conversation.copyWith(unreadCount: 0);
        _loading = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _snack('تعذر فتح المحادثة: $e');
    }
  }

  Future<void> _send({String? quickText}) async {
    final text = (quickText ?? _messageController.text).trim();
    if ((text.isEmpty && _pendingAttachments.isEmpty) ||
        _conversation == null ||
        _sending) {
      return;
    }
    setState(() => _sending = true);
    try {
      final updated = await ref.read(customerChatRepositoryProvider).addMessage(
            conversationId: _conversation!.id,
            text: text.isEmpty ? 'مرفق' : text,
            attachments: List<String>.from(_pendingAttachments),
          );
      if (!mounted) return;
      setState(() {
        _conversation = updated;
        _messageController.clear();
        _pendingAttachments.clear();
        _sending = false;
      });
      await _silentRefresh();
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      _snack('تعذر إرسال الرسالة: $e');
    }
  }

  Future<void> _addAttachmentLink() async {
    _attachmentController.clear();
    final link = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
          top: AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('إضافة مرفق', style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.sm),
            Text(
                'ضع رابط صورة أو ملف. رفع الملفات المباشر يمكن ربطه لاحقًا بخدمة التخزين.',
                style: AppTextStyles.body),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _attachmentController,
              decoration: const InputDecoration(
                labelText: 'رابط المرفق',
                prefixIcon: Icon(Icons.link_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: () =>
                  Navigator.pop(context, _attachmentController.text.trim()),
              icon: const Icon(Icons.attach_file_outlined),
              label: const Text('إضافة المرفق'),
            ),
          ],
        ),
      ),
    );
    if (link == null || link.trim().isEmpty) return;
    setState(() => _pendingAttachments.add(link.trim()));
  }

  Future<void> _changeStatus(String status) async {
    final current = _conversation;
    if (current == null) return;
    try {
      final updated = await ref
          .read(customerChatRepositoryProvider)
          .updateStatus(current.id, status);
      if (!mounted) return;
      setState(() => _conversation = updated);
      _snack(status == 'CLOSED' || status == 'RESOLVED'
          ? 'تم إغلاق المحادثة'
          : 'تم إعادة فتح المحادثة');
      await _silentRefresh();
    } catch (e) {
      _snack('تعذر تحديث حالة المحادثة: $e');
    }
  }

  void _copySummary() {
    final c = _conversation;
    if (c == null) return;
    final text = StringBuffer()
      ..writeln('محادثة: ${c.listingTitle}')
      ..writeln('المزود: ${c.providerName}')
      ..writeln('الحالة: ${_statusLabel(c.status)}')
      ..writeln('عدد الرسائل: ${c.messages.length}')
      ..writeln('آخر رسالة: ${c.lastMessage?.text ?? '-'}');
    Clipboard.setData(ClipboardData(text: text.toString()));
    _snack('تم نسخ ملخص المحادثة');
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: _conversation == null ? 'محادثاتي' : 'محادثة العميل',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : !_authenticated
              ? _LoginRequiredChat(returnTo: _chatReturnUrl())
              : _conversation == null
                  ? _buildInbox()
                  : _buildConversation(),
    );
  }

  Widget _buildInbox() {
    final inbox = _inbox;
    final conversations =
        inbox?.conversations ?? const <CustomerConversation>[];
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _InboxHeader(inbox: inbox),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _searchController,
            onSubmitted: (_) => _load(),
            decoration: InputDecoration(
              labelText: 'ابحث في المحادثات',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                  onPressed: _load, icon: const Icon(Icons.tune_outlined)),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _StatusFilters(
            value: _status,
            unreadOnly: _unreadOnly,
            onStatusChanged: (value) {
              setState(() => _status = value);
              _load();
            },
            onUnreadChanged: (value) {
              setState(() => _unreadOnly = value);
              _load();
            },
          ),
          const SizedBox(height: AppSpacing.md),
          if (conversations.isEmpty)
            _EmptyChatState(
                onStart: () => context.pushPath(RouteNames.marketplaceSearch))
          else
            ...conversations.map((item) => _ConversationTile(
                  conversation: item,
                  onTap: () => _open(item),
                )),
        ],
      ),
    );
  }

  Widget _buildConversation() {
    final conversation = _conversation!;
    return Column(
      children: [
        _ConversationHeader(
          conversation: conversation,
          onBack: () => setState(() => _conversation = null),
          onCopy: _copySummary,
          onClose: conversation.isOpen ? () => _changeStatus('CLOSED') : null,
          onReopen: !conversation.isOpen ? () => _changeStatus('OPEN') : null,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (conversation.isOpen)
          _QuickQuestions(onSelect: (value) => _send(quickText: value)),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await _open(conversation);
            },
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              itemCount: conversation.messages.length,
              itemBuilder: (context, index) =>
                  _MessageBubble(message: conversation.messages[index]),
            ),
          ),
        ),
        if (_pendingAttachments.isNotEmpty)
          _AttachmentPreview(
            attachments: _pendingAttachments,
            onRemove: (item) =>
                setState(() => _pendingAttachments.remove(item)),
          ),
        if (conversation.isOpen && conversation.canReply)
          _Composer(
            controller: _messageController,
            sending: _sending,
            onAttach: _addAttachmentLink,
            onSend: () => _send(),
          )
        else
          _ClosedComposer(onReopen: () => _changeStatus('OPEN')),
      ],
    );
  }

  String _chatReturnUrl() {
    final query = Uri(queryParameters: {
      if (widget.listingId.isNotEmpty) 'listingId': widget.listingId,
      if (widget.listingTitle.isNotEmpty) 'listingTitle': widget.listingTitle,
      if (widget.providerName.isNotEmpty) 'providerName': widget.providerName,
      if (widget.providerTypeLabel.isNotEmpty)
        'providerTypeLabel': widget.providerTypeLabel,
      if (widget.serviceLabel.isNotEmpty) 'serviceLabel': widget.serviceLabel,
    }).query;
    return query.isEmpty
        ? RouteNames.customerChat
        : '${RouteNames.customerChat}?$query';
  }
}

class _InboxHeader extends StatelessWidget {
  final CustomerChatInbox? inbox;
  const _InboxHeader({required this.inbox});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.forum_outlined, color: AppColors.secondary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                  child: Text('محادثاتك مع المتاجر والدعم',
                      style: AppTextStyles.title
                          .copyWith(color: AppColors.textOnDark))),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _MetricChip(label: 'الكل', value: inbox?.total ?? 0),
              _MetricChip(label: 'مفتوحة', value: inbox?.openCount ?? 0),
              _MetricChip(label: 'غير مقروءة', value: inbox?.unreadCount ?? 0),
              _MetricChip(
                  label: 'بانتظار رد', value: inbox?.waitingReplyCount ?? 0),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final int value;
  const _MetricChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Chip(
      backgroundColor: Colors.white.withValues(alpha: 0.14),
      label: Text('$label: $value',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w800)),
    );
  }
}

class _StatusFilters extends StatelessWidget {
  final String value;
  final bool unreadOnly;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<bool> onUnreadChanged;
  const _StatusFilters(
      {required this.value,
      required this.unreadOnly,
      required this.onStatusChanged,
      required this.onUnreadChanged});

  @override
  Widget build(BuildContext context) {
    const filters = {
      'ALL': 'الكل',
      'OPEN': 'مفتوحة',
      'PENDING': 'بانتظار رد',
      'RESOLVED': 'محلولة',
      'CLOSED': 'مغلقة'
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          initialValue: filters.containsKey(value) ? value : 'ALL',
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'فلترة المحادثات',
            prefixIcon: Icon(Icons.filter_list_rounded),
          ),
          items: filters.entries
              .map((e) => DropdownMenuItem<String>(
                    value: e.key,
                    child: Text(e.value, overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: (next) {
            if (next != null) onStatusChanged(next);
          },
        ),
        const SizedBox(height: AppSpacing.xs),
        SwitchListTile.adaptive(
          value: unreadOnly,
          onChanged: onUnreadChanged,
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: const Text('غير مقروءة فقط'),
          secondary: const Icon(Icons.mark_email_unread_outlined),
        ),
      ],
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final CustomerConversation conversation;
  final VoidCallback onTap;
  const _ConversationTile({required this.conversation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: conversation.unreadCount > 0
              ? AppColors.secondary
              : AppColors.surfaceVariant,
          child: Icon(conversation.unreadCount > 0
              ? Icons.mark_chat_unread_outlined
              : Icons.chat_bubble_outline),
        ),
        title: Text(conversation.listingTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                '${conversation.providerName} • ${_statusLabel(conversation.status)}'),
            if (conversation.lastMessage != null)
              Text(conversation.lastMessage!.text,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (conversation.unreadCount > 0)
              Badge(label: Text('${conversation.unreadCount}')),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _ConversationHeader extends StatelessWidget {
  final CustomerConversation conversation;
  final VoidCallback onBack;
  final VoidCallback onCopy;
  final VoidCallback? onClose;
  final VoidCallback? onReopen;
  const _ConversationHeader(
      {required this.conversation,
      required this.onBack,
      required this.onCopy,
      this.onClose,
      this.onReopen});

  @override
  Widget build(BuildContext context) {
    final isWorkshop = conversation.providerTypeLabel.contains('ورشة');
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
          gradient: AppColors.headerGradient,
          borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back, color: Colors.white)),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16)),
            child: Icon(
                isWorkshop
                    ? Icons.car_repair_outlined
                    : Icons.storefront_outlined,
                color: AppColors.secondary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(conversation.providerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.title
                        .copyWith(color: AppColors.textOnDark)),
                Text(
                    '${conversation.providerTypeLabel} • ${conversation.serviceLabel}',
                    style: AppTextStyles.body.copyWith(color: Colors.white70)),
                Text(conversation.listingTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          PopupMenuButton<String>(
            iconColor: Colors.white,
            onSelected: (value) {
              if (value == 'copy') onCopy();
              if (value == 'close') onClose?.call();
              if (value == 'reopen') onReopen?.call();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: 'copy', child: Text('نسخ ملخص المحادثة')),
              if (onClose != null)
                const PopupMenuItem(
                    value: 'close', child: Text('إغلاق المحادثة')),
              if (onReopen != null)
                const PopupMenuItem(
                    value: 'reopen', child: Text('إعادة فتح المحادثة')),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickQuestions extends StatelessWidget {
  final ValueChanged<String> onSelect;
  const _QuickQuestions({required this.onSelect});
  @override
  Widget build(BuildContext context) {
    const questions = [
      'هل هذه القطعة متوافقة مع سيارتي؟',
      'هل السعر يشمل التوصيل؟',
      'متى يمكن توفير القطعة؟',
      'هل التركيب متاح لهذه القطعة؟'
    ];
    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        scrollDirection: Axis.horizontal,
        itemCount: questions.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) => ActionChip(
            label: Text(questions[index]),
            avatar: const Icon(Icons.bolt_outlined, size: 16),
            onPressed: () => onSelect(questions[index])),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final CustomerChatMessage message;
  const _MessageBubble({required this.message});
  @override
  Widget build(BuildContext context) {
    final alignRight = message.isCustomer;
    final color = alignRight ? AppColors.primary : AppColors.surfaceVariant;
    final textColor = alignRight ? Colors.white : AppColors.textPrimary;
    return Align(
      alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .78),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(18)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.senderName.isNotEmpty)
              Text(message.senderName,
                  style: TextStyle(
                      color: textColor.withValues(alpha: .8),
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            Text(message.text, style: TextStyle(color: textColor, height: 1.5)),
            if (message.attachments.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              ...message.attachments.map((a) => Text('📎 $a',
                  style: TextStyle(
                      color: textColor.withValues(alpha: .9),
                      decoration: TextDecoration.underline))),
            ],
            const SizedBox(height: AppSpacing.xs),
            Text(_dateLabel(message.createdAt),
                style: TextStyle(
                    color: textColor.withValues(alpha: .72), fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _AttachmentPreview extends StatelessWidget {
  final List<String> attachments;
  final ValueChanged<String> onRemove;
  const _AttachmentPreview({required this.attachments, required this.onRemove});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      color: AppColors.surfaceVariant,
      child: Wrap(
        spacing: AppSpacing.xs,
        children: attachments
            .map((item) => Chip(
                label: Text(item, maxLines: 1, overflow: TextOverflow.ellipsis),
                onDeleted: () => onRemove(item)))
            .toList(),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onAttach;
  final VoidCallback onSend;
  const _Composer(
      {required this.controller,
      required this.sending,
      required this.onAttach,
      required this.onSend});
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 10)]),
        child: Row(
          children: [
            IconButton(
                onPressed: onAttach,
                icon: const Icon(Icons.attach_file_outlined)),
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                decoration: const InputDecoration(
                    hintText: 'اكتب رسالتك...', border: InputBorder.none),
              ),
            ),
            FilledButton(
              onPressed: sending ? null : onSend,
              child: sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClosedComposer extends StatelessWidget {
  final VoidCallback onReopen;
  const _ClosedComposer({required this.onReopen});
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: FilledButton.icon(
            onPressed: onReopen,
            icon: const Icon(Icons.lock_open_outlined),
            label: const Text('إعادة فتح المحادثة')),
      ),
    );
  }
}

class _EmptyChatState extends StatelessWidget {
  final VoidCallback onStart;
  const _EmptyChatState({required this.onStart});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          const Icon(Icons.chat_bubble_outline,
              size: 60, color: AppColors.primary),
          const SizedBox(height: AppSpacing.md),
          Text('لا توجد محادثات بعد', style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.sm),
          Text('ابدأ محادثة من صفحة المنتج أو الطلب أو الدعم.',
              textAlign: TextAlign.center, style: AppTextStyles.body),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.search),
              label: const Text('ابحث عن قطع')),
        ],
      ),
    );
  }
}

class _LoginRequiredChat extends StatelessWidget {
  final String returnTo;
  const _LoginRequiredChat({required this.returnTo});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 54, color: AppColors.primary),
            const SizedBox(height: AppSpacing.md),
            Text('سجّل الدخول لعرض المحادثات', style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.sm),
            Text('المحادثات مرتبطة بحسابك لكي تتم مزامنتها بين الأجهزة.',
                textAlign: TextAlign.center, style: AppTextStyles.body),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: () => context.pushPath(
                  '${RouteNames.login}?returnTo=${Uri.encodeComponent(returnTo)}'),
              icon: const Icon(Icons.login),
              label: const Text('تسجيل الدخول'),
            ),
          ],
        ),
      ),
    );
  }
}

String _statusLabel(String status) {
  switch (status.toUpperCase()) {
    case 'OPEN':
      return 'مفتوحة';
    case 'PENDING':
      return 'بانتظار رد';
    case 'RESOLVED':
      return 'محلولة';
    case 'CLOSED':
      return 'مغلقة';
    default:
      return status;
  }
}

String _dateLabel(DateTime date) {
  final d = date.toLocal();
  return '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
