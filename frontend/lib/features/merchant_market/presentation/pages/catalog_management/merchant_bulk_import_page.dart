import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/features/merchant_market/data/merchant_market_repository.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_management_scaffold.dart';

class MerchantBulkImportPage extends ConsumerStatefulWidget {
  const MerchantBulkImportPage({super.key});

  @override
  ConsumerState<MerchantBulkImportPage> createState() =>
      _MerchantBulkImportPageState();
}

class _MerchantBulkImportPageState
    extends ConsumerState<MerchantBulkImportPage> {
  final _fileName = TextEditingController();
  final _fileUrl = TextEditingController();
  late Future<List<Map<String, dynamic>>> _future;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _fileName.dispose();
    _fileUrl.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _load() {
    return ref.read(merchantMarketRepositoryProvider).getImportJobs();
  }

  Future<void> _create() async {
    if (_fileName.text.trim().isEmpty) return;
    setState(() => _creating = true);
    try {
      await ref.read(merchantMarketRepositoryProvider).createImportJob(
            fileName: _fileName.text,
            fileUrl: _fileUrl.text,
          );
      _fileName.clear();
      _fileUrl.clear();
      if (mounted) setState(() => _future = _load());
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _execute(String id) async {
    try {
      await ref.read(merchantMarketRepositoryProvider).executeImportJob(id);
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
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        return MerchantManagementScaffold(
          title: 'الاستيراد الجماعي',
          subtitle: 'إدارة مهام رفع المنتجات بالجملة من الخادم',
          onRefresh: () async => setState(() => _future = _load()),
          children: [
            MerchantPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _fileName,
                    decoration: const InputDecoration(
                      labelText: 'اسم الملف',
                      hintText: 'products.csv',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _fileUrl,
                    decoration: const InputDecoration(
                      labelText: 'رابط الملف',
                      hintText: 'اختياري إذا كان الملف مرفوعاً مسبقاً',
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: _creating ? null : _create,
                    icon: _creating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_upload_outlined),
                    label: const Text('إنشاء مهمة استيراد'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (snapshot.connectionState != ConnectionState.done)
              const Center(child: CircularProgressIndicator())
            else if (snapshot.hasError)
              MerchantStateCard(
                icon: Icons.error_outline,
                title: 'تعذر تحميل مهام الاستيراد',
                message: snapshot.error.toString(),
                actionLabel: 'إعادة المحاولة',
                onAction: () => setState(() => _future = _load()),
              )
            else if (snapshot.requireData.isEmpty)
              const MerchantStateCard(
                icon: Icons.upload_file_outlined,
                title: 'لا توجد مهام استيراد',
                message:
                    'أنشئ مهمة استيراد ثم أضف الصفوف والمطابقة من أدوات الباك اند.',
              )
            else
              ...snapshot.requireData.map(
                (job) => _ImportJobCard(job: job, onExecute: _execute),
              ),
          ],
        );
      },
    );
  }
}

class _ImportJobCard extends StatelessWidget {
  const _ImportJobCard({required this.job, required this.onExecute});

  final Map<String, dynamic> job;
  final ValueChanged<String> onExecute;

  @override
  Widget build(BuildContext context) {
    final id = (job['id'] ?? '').toString();
    final status = (job['status'] ?? '').toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MerchantPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              (job['file_name'] ?? job['fileName'] ?? 'ملف استيراد').toString(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text(status.isEmpty ? 'غير محدد' : status)),
                Chip(label: Text('الإجمالي: ${job['total_rows'] ?? 0}')),
                Chip(label: Text('صحيح: ${job['valid_rows'] ?? 0}')),
                Chip(label: Text('أخطاء: ${job['error_rows'] ?? 0}')),
              ],
            ),
            if (id.isNotEmpty &&
                (status == 'READY_TO_IMPORT' ||
                    status == 'VALIDATION_FAILED')) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => onExecute(id),
                icon: const Icon(Icons.play_arrow_outlined),
                label: const Text('تنفيذ الاستيراد'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
