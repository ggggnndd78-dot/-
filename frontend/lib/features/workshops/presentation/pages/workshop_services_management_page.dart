import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/theme/app_colors.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/core/theme/app_text_styles.dart';
import 'package:ghiyarak/features/workshops/data/models/workshop_models.dart';
import 'package:ghiyarak/features/workshops/data/workshops_repository.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:ghiyarak/shared/widgets/section_title.dart';

final workshopOperationsServicesProvider =
    FutureProvider<List<WorkshopServiceModel>>((ref) async {
  return ref.watch(workshopsRepositoryProvider).getMyWorkshopServices();
});

class WorkshopServicesManagementPage extends ConsumerStatefulWidget {
  const WorkshopServicesManagementPage({super.key});

  @override
  ConsumerState<WorkshopServicesManagementPage> createState() =>
      _WorkshopServicesManagementPageState();
}

class _WorkshopServicesManagementPageState
    extends ConsumerState<WorkshopServicesManagementPage> {
  final _name = TextEditingController();
  final _category = TextEditingController(text: 'diagnostics');
  final _price = TextEditingController();
  final _description = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _category.dispose();
    _price.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _createService() async {
    if (_name.text.trim().isEmpty || _category.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      await ref.read(workshopsRepositoryProvider).createWorkshopService(
            nameAr: _name.text.trim(),
            categoryCode: _category.text.trim(),
            description: _description.text.trim().isEmpty
                ? null
                : _description.text.trim(),
            basePrice: double.tryParse(_price.text.trim()) ?? 0,
          );
      ref.invalidate(workshopOperationsServicesProvider);
      _name.clear();
      _price.clear();
      _description.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إنشاء خدمة الورشة')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createDefaultSlot(WorkshopServiceModel service) async {
    setState(() => _loading = true);
    try {
      await ref.read(workshopsRepositoryProvider).createBookingSlot(
            workshopServiceId: service.id,
            date: DateTime.now().add(const Duration(days: 1)),
            startTime: '09:00',
            endTime: '10:00',
            capacity: 2,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إنشاء موعد متاح ليوم غد')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = ref.watch(workshopOperationsServicesProvider);
    return AppScaffold(
      title: 'خدمات الورشة',
      child: ListView(
        children: [
          const SectionTitle(
            title: 'إدارة الخدمات',
            subtitle: 'هذه الواجهة مربوطة بواجهات API الخاصة بالورشة.',
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'اسم الخدمة')),
          const SizedBox(height: AppSpacing.sm),
          TextField(
              controller: _category,
              decoration: const InputDecoration(labelText: 'رمز التصنيف')),
          const SizedBox(height: AppSpacing.sm),
          TextField(
              controller: _price,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'السعر الأساسي')),
          const SizedBox(height: AppSpacing.sm),
          TextField(
              controller: _description,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'وصف الخدمة')),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            text: 'إضافة خدمة',
            isLoading: _loading,
            onPressed: _createService,
          ),
          const SizedBox(height: AppSpacing.lg),
          services.when(
            data: (items) => items.isEmpty
                ? const _InfoCard(text: 'لا توجد خدمات مسجلة للورشة بعد')
                : Column(
                    children: items
                        .map((item) => Padding(
                              padding:
                                  const EdgeInsets.only(bottom: AppSpacing.md),
                              child: _ServiceTile(
                                service: item,
                                isLoading: _loading,
                                onCreateSlot: () => _createDefaultSlot(item),
                              ),
                            ))
                        .toList(),
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _InfoCard(text: e.toString()),
          ),
        ],
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final WorkshopServiceModel service;
  final bool isLoading;
  final VoidCallback onCreateSlot;

  const _ServiceTile({
    required this.service,
    required this.isLoading,
    required this.onCreateSlot,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(service.name, style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.xs),
          Text(service.description ?? service.categoryCode,
              style: AppTextStyles.bodySecondary),
          const SizedBox(height: AppSpacing.sm),
          Text(
              'الحالة: ${service.status} • السعر: ${service.basePrice?.toStringAsFixed(0) ?? '-'} ${service.currency}',
              style: AppTextStyles.body),
          const SizedBox(height: AppSpacing.md),
          AppButton(
              text: 'إنشاء موعد ليوم غد',
              isOutlined: true,
              isLoading: isLoading,
              onPressed: onCreateSlot),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String text;
  const _InfoCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(text, style: AppTextStyles.bodySecondary),
    );
  }
}
