import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/theme/app_colors.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/features/admin/data/admin_repository.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:ghiyarak/shared/widgets/section_title.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';

final adminVerificationStatusFilterProvider =
    StateProvider.autoDispose<String?>((ref) => null);

final adminVerificationsProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) {
  final status = ref.watch(adminVerificationStatusFilterProvider);
  return ref
      .watch(adminRepositoryProvider)
      .verificationRequests(status: status);
});

class AdminVerificationsPage extends ConsumerWidget {
  const AdminVerificationsPage({super.key});

  static const _statuses = <String?>[
    null,
    'PENDING_REVIEW',
    'DOCUMENTS_REQUIRED',
    'APPROVED',
    'REJECTED',
    'SUSPENDED',
  ];

  String _statusLabel(String? status) {
    switch (status) {
      case null:
        return 'الكل';
      case 'PENDING_REVIEW':
        return 'قيد المراجعة';
      case 'DOCUMENTS_REQUIRED':
        return 'مطلوب مستندات';
      case 'APPROVED':
        return 'معتمد';
      case 'REJECTED':
        return 'مرفوض';
      case 'SUSPENDED':
        return 'معلّق';
      default:
        return status;
    }
  }

  Future<Map<String, String>?> _askReviewInput(
      BuildContext context, String title, String initial) async {
    final controller = TextEditingController(text: initial);
    var notificationChannel = 'BOTH';
    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: controller,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظة الإدارة',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: notificationChannel,
                  decoration: const InputDecoration(labelText: 'وسيلة الإشعار'),
                  items: const [
                    DropdownMenuItem(value: 'SMS', child: Text('SMS')),
                    DropdownMenuItem(value: 'EMAIL', child: Text('Email')),
                    DropdownMenuItem(value: 'BOTH', child: Text('SMS + Email')),
                  ],
                  onChanged: (value) =>
                      setState(() => notificationChannel = value ?? 'BOTH'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('إلغاء')),
            FilledButton(
              onPressed: () => Navigator.of(context).pop({
                'notes': controller.text.trim(),
                'notificationChannel': notificationChannel
              }),
              child: const Text('تأكيد'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _review(
      BuildContext context, WidgetRef ref, String id, String action) async {
    final defaults = {
      'approve': 'تمت الموافقة من لوحة الإدارة. الحساب أصبح معتمدًا.',
      'reject': 'تم رفض طلب الاعتماد. يرجى مراجعة البيانات والمستندات.',
      'require_documents':
          'يرجى رفع مستندات أو بيانات إضافية لاستكمال المراجعة.',
      'suspend': 'تم تعليق الحساب مؤقتًا من الإدارة.',
    };
    final titles = {
      'approve': 'الموافقة على الطلب',
      'reject': 'رفض الطلب',
      'require_documents': 'طلب مستندات إضافية',
      'suspend': 'تعليق الحساب',
    };
    final input = await _askReviewInput(
        context, titles[action] ?? 'مراجعة الطلب', defaults[action] ?? '');
    final note = input?['notes'] ?? '';
    final notificationChannel = input?['notificationChannel'] ?? 'BOTH';
    if (input == null || note.isEmpty) return;
    try {
      final repo = ref.read(adminRepositoryProvider);
      if (action == 'approve') {
        await repo.approveVerification(id, note,
            notificationChannel: notificationChannel);
      } else if (action == 'reject') {
        await repo.rejectVerification(id, note,
            notificationChannel: notificationChannel);
      } else if (action == 'require_documents') {
        await repo.requireDocuments(id, note,
            notificationChannel: notificationChannel);
      } else if (action == 'suspend') {
        await repo.suspendVerification(id, note,
            notificationChannel: notificationChannel);
      }
      ref.invalidate(adminVerificationsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('تم حفظ قرار المراجعة وتسجيله في السجل')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('تعذر فتح الرابط: $url')));
    }
  }

  Uint8List? _decodeDocumentBytes(Map<String, dynamic> doc) {
    final raw = (doc['preview_base64'] ?? doc['file_content_base64'] ?? '')
        .toString()
        .trim();
    if (raw.isEmpty) return null;
    final cleaned = raw.contains(',') ? raw.split(',').last.trim() : raw;
    try {
      return base64Decode(cleaned);
    } catch (_) {
      return null;
    }
  }

  String _documentTitle(Map<String, dynamic> doc) {
    final type = (doc['document_type'] ?? '').toString();
    final side = (doc['side'] ?? '').toString();
    final name = (doc['file_name'] ?? '').toString();
    final parts = [type, if (side.isNotEmpty) side, if (name.isNotEmpty) name];
    return parts.where((item) => item.trim().isNotEmpty).join(' • ');
  }

  Future<void> _openDocumentViewer(
      BuildContext context, Map<String, dynamic> doc) async {
    final bytes = _decodeDocumentBytes(doc);
    final mime = (doc['mime_type'] ?? '').toString().toLowerCase();
    final fileUrl = (doc['file_url'] ?? '').toString().trim();
    final title =
        _documentTitle(doc).isEmpty ? 'معاينة المستند' : _documentTitle(doc);

    await showDialog<void>(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: Text(title, overflow: TextOverflow.ellipsis),
            actions: [
              IconButton(
                tooltip: 'إغلاق',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: _DocumentPreviewBody(
                bytes: bytes,
                mimeType: mime,
                fileName: (doc['file_name'] ?? '').toString(),
                fileUrl: fileUrl),
          ),
        ),
      ),
    );
  }

  Widget _documentPreview(BuildContext context, Map<String, dynamic> doc) {
    final mime = (doc['mime_type'] ?? '').toString().toLowerCase();
    final bytes = _decodeDocumentBytes(doc);
    final hasBytes = bytes != null && bytes.isNotEmpty;
    final fileUrl = (doc['file_url'] ?? '').toString().trim();
    final hasUrl = fileUrl.isNotEmpty;
    final lowerName = (doc['file_name'] ?? fileUrl).toString().toLowerCase();
    final isImage = mime.startsWith('image/') ||
        lowerName.endsWith('.jpg') ||
        lowerName.endsWith('.jpeg') ||
        lowerName.endsWith('.png') ||
        lowerName.endsWith('.webp');
    final isPdf = mime == 'application/pdf' || lowerName.endsWith('.pdf');

    Widget preview;
    if (!hasBytes && hasUrl && isImage) {
      preview = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(fileUrl,
            height: 180,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                const Text('تعذر عرض الصورة من الرابط')),
      );
    } else if (!hasBytes && hasUrl && isPdf) {
      preview = const ListTile(
        leading: Icon(Icons.picture_as_pdf, color: AppColors.error, size: 34),
        title: Text('ملف PDF جاهز للفتح من الرابط'),
        subtitle:
            Text('سيتم عرضه داخل لوحة الإدارة إذا كان الرابط متاحًا مباشرة.'),
      );
    } else if (!hasBytes) {
      preview = const Text(
          'لا توجد بيانات ملف قابلة للعرض. تأكد أن المستند محفوظ كـ Base64 أو رابط مباشر.');
    } else if (isImage) {
      preview = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(bytes, height: 180, fit: BoxFit.contain),
      );
    } else if (isPdf) {
      preview = Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            const Icon(Icons.picture_as_pdf, color: AppColors.error, size: 34),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'ملف PDF جاهز للفتح والمعاينة داخل لوحة الإدارة. الحجم: ${bytes.length} bytes',
              ),
            ),
          ],
        ),
      );
    } else {
      preview = const Text('نوع ملف غير معروف، ويمكن فتحه من زر المعاينة.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        preview,
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            FilledButton.icon(
              onPressed: (hasBytes || hasUrl)
                  ? () => _openDocumentViewer(context, doc)
                  : null,
              icon: Icon(
                  isPdf ? Icons.picture_as_pdf : Icons.visibility_outlined),
              label: Text(isPdf ? 'فتح PDF داخل اللوحة' : 'فتح ومعاينة الملف'),
            ),
            if (hasBytes || hasUrl)
              OutlinedButton.icon(
                onPressed: () => _openDocumentViewer(context, doc),
                icon: const Icon(Icons.fullscreen),
                label: const Text('عرض كامل'),
              ),
          ],
        ),
      ],
    );
  }

  Widget _branchLocations(
      BuildContext context, Map<String, dynamic> organization) {
    final branches = List<dynamic>.from(organization['branches'] ?? []);
    if (branches.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('موقع المتجر / الورشة',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: AppSpacing.sm),
        ...branches.map((raw) {
          final branch = Map<String, dynamic>.from(raw as Map);
          final mapUrl = (branch['map_url'] ?? '').toString();
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text((branch['branch_name'] ?? '-').toString(),
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text('المحافظة/المدينة: ${branch['city_name'] ?? '-'}'),
                  Text('المديرية: ${branch['district_name'] ?? '-'}'),
                  Text('المنطقة: ${branch['area_name'] ?? '-'}'),
                  Text('العنوان: ${branch['address_line_1'] ?? '-'}'),
                  Text(
                      'الإحداثيات: ${branch['latitude'] ?? '-'}, ${branch['longitude'] ?? '-'}'),
                  if (mapUrl.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    SelectableText(mapUrl,
                        style: const TextStyle(color: AppColors.primary)),
                    const SizedBox(height: AppSpacing.sm),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: OutlinedButton.icon(
                        onPressed: () => _openUrl(context, mapUrl),
                        icon: const Icon(Icons.map_outlined),
                        label: const Text('فتح الموقع على الخريطة'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Future<void> _showDetails(
      BuildContext context, WidgetRef ref, String id) async {
    try {
      final details =
          await ref.read(adminRepositoryProvider).verificationDetail(id);
      if (!context.mounted) return;
      final organization =
          Map<String, dynamic>.from((details['organization'] as Map?) ?? {});
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title:
              Text((organization['display_name'] ?? 'تفاصيل الطلب').toString()),
          content: SizedBox(
            width: 620,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('حالة الطلب: ${details['status']}'),
                  Text('ملاحظات مقدم الطلب: ${details['notes'] ?? '-'}'),
                  const Divider(),
                  _branchLocations(context, organization),
                  const Divider(),
                  const Text('المستندات',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: AppSpacing.sm),
                  ...List<dynamic>.from(details['documents'] ?? []).map((doc) =>
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                  '${doc['document_type']} • ${doc['file_name']}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              if ((doc['file_url'] ?? '').toString().isNotEmpty)
                                SelectableText(
                                    (doc['file_url'] ?? '').toString()),
                              const SizedBox(height: AppSpacing.sm),
                              _documentPreview(context,
                                  Map<String, dynamic>.from(doc as Map)),
                              if ((doc['notes'] ?? '').toString().isNotEmpty)
                                Text('ملاحظة: ${doc['notes']}'),
                            ],
                          ),
                        ),
                      )),
                  const Divider(),
                  const Text('ملاحظات المراجعة',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  ...List<dynamic>.from(details['review_notes_history'] ?? [])
                      .map((note) => ListTile(
                            dense: true,
                            title: Text((note['note'] ?? '').toString()),
                            subtitle: Text(
                                '${note['note_type']} • ${note['actor'] ?? '-'} • ${note['created_at'] ?? '-'}'),
                          )),
                  const Divider(),
                  const Text('سجل الحالات',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  ...List<dynamic>.from(details['status_history'] ?? [])
                      .map((history) => ListTile(
                            dense: true,
                            title: Text(
                                '${history['from_status'] ?? '-'} → ${history['to_status']}'),
                            subtitle: Text(
                                '${history['reason'] ?? '-'} • ${history['changed_by'] ?? '-'}'),
                          )),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('إغلاق'))
          ],
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminVerificationsProvider);
    final selectedStatus = ref.watch(adminVerificationStatusFilterProvider);
    return AppScaffold(
      title: 'الموافقات والتوثيق الإداري',
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (items) => ListView(
          children: [
            const SectionTitle(
              title: 'طلبات اعتماد التجار والورش والمستودعات',
              subtitle:
                  'افتح المستندات، راجع البيانات، وافق أو ارفض أو اطلب مستندات إضافية. كل قرار يسجل في Audit Log.',
            ),
            const SizedBox(height: AppSpacing.md),
            _AdminStatusFilterDropdown(
              value: selectedStatus,
              options: _statuses,
              labelBuilder: _statusLabel,
              onChanged: (status) => ref
                  .read(adminVerificationStatusFilterProvider.notifier)
                  .state = status,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (items.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Text('لا توجد طلبات توثيق حاليًا.'),
                ),
              ),
            ...items.map((item) {
              final id = (item['id'] ?? '').toString();
              final status = (item['request_status'] ?? '-').toString();
              final canReview = item['can_review'] == true ||
                  status == 'SUBMITTED' ||
                  status == 'PENDING_REVIEW' ||
                  status == 'UNDER_REVIEW' ||
                  status == 'DOCUMENTS_REQUIRED';
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                              child: Text(
                                  (item['organization_name'] ?? 'منشأة')
                                      .toString(),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16))),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: status == 'APPROVED'
                                  ? AppColors.success.withValues(alpha: 0.12)
                                  : AppColors.primary.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(_statusLabel(status),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                          'النوع: ${item['organization_type']} • حالة المنشأة: ${item['organization_status']}'),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                          'المستندات: ${item['documents_count'] ?? 0} • مقدم الطلب: ${item['submitted_by'] ?? '-'}'),
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          SizedBox(
                              width: 150,
                              child: AppButton(
                                  text: 'فتح التفاصيل',
                                  isOutlined: true,
                                  onPressed: () =>
                                      _showDetails(context, ref, id))),
                          if (canReview) ...[
                            SizedBox(
                                width: 140,
                                child: AppButton(
                                    text: 'موافقة',
                                    onPressed: () =>
                                        _review(context, ref, id, 'approve'))),
                            SizedBox(
                                width: 160,
                                child: AppButton(
                                    text: 'طلب مستندات',
                                    isOutlined: true,
                                    onPressed: () => _review(context, ref, id,
                                        'require_documents'))),
                            SizedBox(
                                width: 130,
                                child: OutlinedButton(
                                    onPressed: () =>
                                        _review(context, ref, id, 'reject'),
                                    child: const Text('رفض'))),
                          ],
                          if (status == 'APPROVED')
                            SizedBox(
                                width: 130,
                                child: OutlinedButton(
                                    onPressed: () =>
                                        _review(context, ref, id, 'suspend'),
                                    child: const Text('تعليق'))),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}


class _AdminStatusFilterDropdown extends StatelessWidget {
  const _AdminStatusFilterDropdown({
    required this.value,
    required this.options,
    required this.labelBuilder,
    required this.onChanged,
  });

  final String? value;
  final List<String?> options;
  final String Function(String?) labelBuilder;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: DropdownButtonFormField<String>(
        initialValue: value ?? '__all__',
        isExpanded: true,
        decoration: InputDecoration(
          labelText: 'فلترة حسب الحالة',
          prefixIcon: const Icon(Icons.filter_alt_outlined),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
        ),
        items: options
            .map(
              (status) => DropdownMenuItem<String>(
                value: status ?? '__all__',
                child: Text(labelBuilder(status)),
              ),
            )
            .toList(),
        onChanged: (next) => onChanged(next == '__all__' ? null : next),
      ),
    );
  }
}

class _DocumentPreviewBody extends StatelessWidget {
  final Uint8List? bytes;
  final String mimeType;
  final String fileName;
  final String fileUrl;

  const _DocumentPreviewBody(
      {required this.bytes,
      required this.mimeType,
      required this.fileName,
      required this.fileUrl});

  @override
  Widget build(BuildContext context) {
    final data = bytes;
    final lowerName = (fileName.isNotEmpty ? fileName : fileUrl).toLowerCase();
    final isImage = mimeType.startsWith('image/') ||
        lowerName.endsWith('.jpg') ||
        lowerName.endsWith('.jpeg') ||
        lowerName.endsWith('.png') ||
        lowerName.endsWith('.webp');
    final isPdf = mimeType == 'application/pdf' || lowerName.endsWith('.pdf');

    if (data == null || data.isEmpty) {
      if (fileUrl.trim().isEmpty) {
        return const Center(
            child: Text('لا يمكن فتح المستند لأن بيانات الملف غير موجودة.'));
      }
      if (isImage) {
        return InteractiveViewer(
            child: Center(child: Image.network(fileUrl, fit: BoxFit.contain)));
      }
      if (isPdf) {
        return SfPdfViewer.network(fileUrl);
      }
      return Center(child: SelectableText('رابط الملف: $fileUrl'));
    }

    if (isImage) {
      return InteractiveViewer(
        minScale: 0.5,
        maxScale: 5,
        child: Center(
          child: Image.memory(data, fit: BoxFit.contain),
        ),
      );
    }

    if (isPdf) {
      return SfPdfViewer.memory(data);
    }

    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.insert_drive_file_outlined, size: 52),
              const SizedBox(height: AppSpacing.md),
              Text('نوع الملف غير مدعوم للمعاينة المباشرة: $mimeType'),
              const SizedBox(height: AppSpacing.sm),
              Text('اسم الملف: $fileName'),
            ],
          ),
        ),
      ),
    );
  }
}
