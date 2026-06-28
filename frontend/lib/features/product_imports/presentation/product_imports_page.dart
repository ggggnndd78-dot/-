import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/features/product_imports/data/product_imports_repository.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:ghiyarak/shared/widgets/app_text_field.dart';
import 'package:ghiyarak/shared/widgets/section_title.dart';

class ProductImportsPage extends ConsumerStatefulWidget {
  const ProductImportsPage({super.key});

  @override
  ConsumerState<ProductImportsPage> createState() => _ProductImportsPageState();
}

class _ProductImportsPageState extends ConsumerState<ProductImportsPage> {
  final _organizationIdController = TextEditingController();
  final _branchIdController = TextEditingController();
  PlatformFile? _selectedFile;
  bool _loading = false;
  List<Map<String, dynamic>> _jobs = const [];

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  @override
  void dispose() {
    _organizationIdController.dispose();
    _branchIdController.dispose();
    super.dispose();
  }

  Future<void> _loadJobs() async {
    setState(() => _loading = true);
    try {
      final jobs = await ref.read(productImportsRepositoryProvider).getJobs();
      if (!mounted) return;
      setState(() => _jobs = jobs);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xlsx', 'xls', 'csv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    setState(() => _selectedFile = result.files.single);
  }

  Future<void> _upload() async {
    final orgId = _organizationIdController.text.trim();
    final branchId = _branchIdController.text.trim();
    if (orgId.isEmpty || branchId.isEmpty || _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('أدخل رقم المؤسسة والفرع واختر ملف Excel أولًا')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final job = await ref.read(productImportsRepositoryProvider).upload(
            organizationId: orgId,
            branchId: branchId,
            file: _selectedFile!,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'تم رفع الملف. الصفوف الصحيحة: ${job['validRows'] ?? 0}، الأخطاء: ${job['invalidRows'] ?? 0}')),
      );
      await _loadJobs();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirm(String jobId) async {
    setState(() => _loading = true);
    try {
      final job =
          await ref.read(productImportsRepositoryProvider).confirm(jobId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('تم التأكيد. المستورد: ${job['importedRows'] ?? 0}')),
      );
      await _loadJobs();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'استيراد المنتجات',
      child: ListView(
        children: [
          const SectionTitle(
            title: 'استيراد Excel',
            subtitle:
                'ارفع ملف المنتجات بعد اعتماد حسابك. النظام يقرأ الصفوف، يعرض الأخطاء، ثم يحفظ المنتجات الصحيحة بعد التأكيد.',
          ),
          const SizedBox(height: AppSpacing.lg),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextField(
                    controller: _organizationIdController,
                    label: 'رقم المؤسسة',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _branchIdController,
                    label: 'رقم الفرع',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(_selectedFile == null
                      ? 'لم يتم اختيار ملف'
                      : 'الملف: ${_selectedFile!.name}'),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                          child: AppButton(
                              text: 'اختيار ملف Excel',
                              isOutlined: true,
                              onPressed: _loading ? null : _pickFile)),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                          child: AppButton(
                              text: 'رفع وقراءة',
                              onPressed: _loading ? null : _upload)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionTitle(title: 'عمليات الاستيراد السابقة'),
          const SizedBox(height: AppSpacing.md),
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (!_loading && _jobs.isEmpty)
            const Center(child: Text('لا توجد عمليات استيراد بعد')),
          ..._jobs.map((job) {
            final id = (job['publicId'] ?? job['public_id'] ?? '').toString();
            final status = (job['status'] ?? '').toString();
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(job['originalFileName']?.toString() ?? 'ملف منتجات',
                        style: Theme.of(context).textTheme.titleMedium),
                    Text('الحالة: $status'),
                    Text(
                        'الإجمالي: ${job['totalRows'] ?? 0} | صحيح: ${job['validRows'] ?? 0} | أخطاء: ${job['invalidRows'] ?? 0} | مستورد: ${job['importedRows'] ?? 0}'),
                    const SizedBox(height: AppSpacing.sm),
                    if (status == 'READY_TO_CONFIRM')
                      AppButton(
                          text: 'تأكيد الاستيراد',
                          onPressed: _loading ? null : () => _confirm(id)),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
