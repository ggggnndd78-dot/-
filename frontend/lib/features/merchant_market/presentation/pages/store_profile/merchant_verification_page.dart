import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/features/merchant_market/data/merchant_market_repository.dart';
import 'package:ghiyarak/features/merchant_market/data/models/merchant_organization_model.dart';
import 'package:ghiyarak/features/merchant_market/data/models/merchant_settings_model.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_management_scaffold.dart';

class MerchantVerificationPage extends ConsumerStatefulWidget {
  const MerchantVerificationPage({super.key});

  @override
  ConsumerState<MerchantVerificationPage> createState() =>
      _MerchantVerificationPageState();
}

class _MerchantVerificationPageState
    extends ConsumerState<MerchantVerificationPage> {
  final _notes = TextEditingController();
  final _docName = TextEditingController();
  final _docUrl = TextEditingController();
  final _docNotes = TextEditingController();
  String _docType = 'COMMERCIAL_REGISTRATION';
  late Future<_VerificationBundle> _future;
  bool _submitting = false;
  bool _addingDocument = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _notes.dispose();
    _docName.dispose();
    _docUrl.dispose();
    _docNotes.dispose();
    super.dispose();
  }

  Future<_VerificationBundle> _load() async {
    final repo = ref.read(merchantMarketRepositoryProvider);
    final organization = await repo.getMerchantOrganization();
    MerchantVerificationRequestModel? latest;
    if (organization.verificationRequests.isNotEmpty) {
      final latestId = organization.verificationRequests.first.id;
      if (latestId.isNotEmpty)
        latest = await repo.getVerificationRequest(latestId);
    }
    return _VerificationBundle(
        organization: organization, latestRequest: latest);
  }

  Future<void> _reload() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await ref
          .read(merchantMarketRepositoryProvider)
          .submitVerificationRequest(notes: _notes.text);
      if (!mounted) return;
      await _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('تم إرسال طلب التوثيق')));
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _addDocument(String requestId) async {
    if (_docName.text.trim().isEmpty || _docUrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('أدخل اسم المستند ورابط الملف')));
      return;
    }
    setState(() => _addingDocument = true);
    try {
      await ref.read(merchantMarketRepositoryProvider).addVerificationDocument(
            requestId: requestId,
            documentType: _docType,
            fileName: _docName.text,
            fileUrl: _docUrl.text,
            notes: _docNotes.text,
          );
      _docName.clear();
      _docUrl.clear();
      _docNotes.clear();
      if (!mounted) return;
      await _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('تمت إضافة المستند')));
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _addingDocument = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_VerificationBundle>(
      future: _future,
      builder: (context, snapshot) {
        return MerchantManagementScaffold(
          title: 'التوثيق والمستندات',
          subtitle: 'طلب اعتماد المتجر ورفع المستندات ومتابعة قرار الإدارة',
          onRefresh: _reload,
          children: [
            if (snapshot.connectionState != ConnectionState.done)
              const Center(child: CircularProgressIndicator())
            else if (snapshot.hasError)
              MerchantStateCard(
                icon: Icons.error_outline,
                title: 'تعذر تحميل حالة التوثيق',
                message: snapshot.error.toString(),
                actionLabel: 'إعادة المحاولة',
                onAction: () => setState(() => _future = _load()),
              )
            else ...[
              _StatusCard(
                  organization: snapshot.requireData.organization,
                  request: snapshot.requireData.latestRequest),
              const SizedBox(height: 14),
              if (snapshot.requireData.latestRequest == null ||
                  _canSubmitNew(snapshot.requireData.latestRequest!.status))
                _SubmitPanel(
                    notes: _notes, submitting: _submitting, onSubmit: _submit),
              if (snapshot.requireData.latestRequest != null) ...[
                const SizedBox(height: 14),
                _DocumentsPanel(
                  request: snapshot.requireData.latestRequest!,
                  docType: _docType,
                  docName: _docName,
                  docUrl: _docUrl,
                  docNotes: _docNotes,
                  adding: _addingDocument,
                  onTypeChanged: (value) =>
                      setState(() => _docType = value ?? _docType),
                  onAdd: () =>
                      _addDocument(snapshot.requireData.latestRequest!.id),
                ),
                const SizedBox(height: 14),
                _HistoryPanel(request: snapshot.requireData.latestRequest!),
              ],
            ],
          ],
        );
      },
    );
  }

  bool _canSubmitNew(String status) =>
      ['APPROVED', 'REJECTED', 'CANCELLED'].contains(status.toUpperCase());
}

class _VerificationBundle {
  const _VerificationBundle({required this.organization, this.latestRequest});
  final MerchantOrganizationModel organization;
  final MerchantVerificationRequestModel? latestRequest;
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.organization, this.request});
  final MerchantOrganizationModel organization;
  final MerchantVerificationRequestModel? request;

  @override
  Widget build(BuildContext context) {
    final verified = organization.isVerified;
    final status = request?.status ?? organization.status;
    return MerchantPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                  verified ? Icons.verified_rounded : Icons.fact_check_outlined,
                  size: 42,
                  color: verified ? Colors.green : const Color(0xFFFF7900)),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(
                      verified
                          ? 'المتجر موثق ومعتمد'
                          : 'حالة التوثيق: ${_statusLabel(status)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: Color(0xFF082B51)))),
            ],
          ),
          const SizedBox(height: 8),
          Text(
              verified
                  ? 'يمكن للمتجر البيع والاستفادة من مزايا التاجر الموثق.'
                  : 'أكمل بيانات المتجر والسياسات والحساب البنكي ثم ارفع المستندات المطلوبة.',
              style: const TextStyle(color: Color(0xFF687686), height: 1.5)),
          if ((request?.reviewSummary ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('ملاحظة الإدارة: ${request!.reviewSummary}',
                style: const TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.w800)),
          ],
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'SUBMITTED':
        return 'مُرسل';
      case 'UNDER_REVIEW':
        return 'قيد المراجعة';
      case 'DOCUMENTS_REQUIRED':
        return 'مطلوب مستندات';
      case 'APPROVED':
        return 'مقبول';
      case 'REJECTED':
        return 'مرفوض';
      default:
        return status.isEmpty ? 'مسودة' : status;
    }
  }
}

class _SubmitPanel extends StatelessWidget {
  const _SubmitPanel(
      {required this.notes, required this.submitting, required this.onSubmit});
  final TextEditingController notes;
  final bool submitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return MerchantPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('إرسال طلب توثيق',
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: Color(0xFF082B51))),
          const SizedBox(height: 12),
          TextField(
              controller: notes,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'ملاحظات للإدارة')),
          const SizedBox(height: 14),
          FilledButton.icon(
              onPressed: submitting ? null : onSubmit,
              icon: const Icon(Icons.send_outlined),
              label: Text(submitting ? 'جارٍ الإرسال...' : 'إرسال الطلب')),
        ],
      ),
    );
  }
}

class _DocumentsPanel extends StatelessWidget {
  const _DocumentsPanel(
      {required this.request,
      required this.docType,
      required this.docName,
      required this.docUrl,
      required this.docNotes,
      required this.adding,
      required this.onTypeChanged,
      required this.onAdd});
  final MerchantVerificationRequestModel request;
  final String docType;
  final TextEditingController docName;
  final TextEditingController docUrl;
  final TextEditingController docNotes;
  final bool adding;
  final ValueChanged<String?> onTypeChanged;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return MerchantPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('المستندات',
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: Color(0xFF082B51))),
          const SizedBox(height: 8),
          if (request.documents.isEmpty)
            const Text('لم يتم رفع مستندات بعد.',
                style: TextStyle(color: Color(0xFF687686)))
          else
            ...request.documents.map((doc) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.description_outlined),
                  title: Text(doc.fileName,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text('${doc.documentType}\n${doc.fileUrl}'),
                )),
          const Divider(height: 28),
          DropdownButtonFormField<String>(
            initialValue: docType,
            decoration: const InputDecoration(labelText: 'نوع المستند'),
            items: const [
              DropdownMenuItem(
                  value: 'COMMERCIAL_REGISTRATION',
                  child: Text('السجل التجاري')),
              DropdownMenuItem(
                  value: 'SHOP_GUARANTEE', child: Text('ضمان المحل')),
              DropdownMenuItem(
                  value: 'NATIONAL_ID', child: Text('هوية المالك')),
              DropdownMenuItem(
                  value: 'BANK_PROOF', child: Text('إثبات الحساب البنكي')),
              DropdownMenuItem(
                  value: 'STORE_FRONT', child: Text('واجهة المتجر')),
              DropdownMenuItem(value: 'OTHER', child: Text('أخرى')),
            ],
            onChanged: onTypeChanged,
          ),
          const SizedBox(height: 10),
          TextField(
              controller: docName,
              decoration: const InputDecoration(labelText: 'اسم الملف')),
          const SizedBox(height: 10),
          TextField(
              controller: docUrl,
              decoration: const InputDecoration(labelText: 'رابط الملف')),
          const SizedBox(height: 10),
          TextField(
              controller: docNotes,
              decoration: const InputDecoration(labelText: 'ملاحظات المستند'),
              maxLines: 2),
          const SizedBox(height: 14),
          FilledButton.icon(
              onPressed: adding ? null : onAdd,
              icon: const Icon(Icons.upload_file_outlined),
              label: Text(adding ? 'جارٍ الرفع...' : 'إضافة المستند')),
        ],
      ),
    );
  }
}

class _HistoryPanel extends StatelessWidget {
  const _HistoryPanel({required this.request});
  final MerchantVerificationRequestModel request;

  @override
  Widget build(BuildContext context) {
    return MerchantPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('سجل المراجعة',
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: Color(0xFF082B51))),
          const SizedBox(height: 8),
          if (request.statusHistory.isEmpty)
            const Text('لا يوجد سجل بعد.')
          else
            ...request.statusHistory.map((item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.timeline_outlined),
                  title: Text(
                      '${item['from_status'] ?? '-'} ← ${item['to_status'] ?? '-'}'),
                  subtitle: Text(
                      '${item['note'] ?? ''}\n${item['created_at'] ?? ''}'),
                )),
          if (request.reviewNotes.isNotEmpty) ...[
            const Divider(),
            ...request.reviewNotes.map((item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.admin_panel_settings_outlined),
                  title: Text((item['note_type'] ?? 'ملاحظة').toString()),
                  subtitle: Text((item['note'] ?? '').toString()),
                )),
          ],
        ],
      ),
    );
  }
}
