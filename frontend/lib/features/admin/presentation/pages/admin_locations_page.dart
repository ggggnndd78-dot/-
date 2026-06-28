import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/features/locations/data/admin_locations_repository.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:ghiyarak/shared/widgets/section_title.dart';

final adminCitiesProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(adminLocationsRepositoryProvider).cities();
});

class AdminLocationsPage extends ConsumerWidget {
  const AdminLocationsPage({super.key});

  Future<void> _editFee(BuildContext context, WidgetRef ref, String cityId,
      String cityName, String currentFee) async {
    final controller = TextEditingController(text: currentFee);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('رسوم توصيل $cityName'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration:
              const InputDecoration(labelText: 'رسوم التوصيل بالريال اليمني'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء')),
          FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('حفظ')),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref
        .read(adminLocationsRepositoryProvider)
        .saveCityDeliveryFee(cityId, num.tryParse(controller.text.trim()) ?? 0);
    ref.invalidate(adminCitiesProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminCitiesProvider);
    return AppScaffold(
      title: 'إدارة المدن والمواقع',
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (cities) => ListView(
          children: [
            const SectionTitle(
              title: 'المدن اليمنية ورسوم التوصيل',
              subtitle: 'إدارة المدن المتاحة وتحديد رسوم التوصيل حسب المدينة.',
            ),
            const SizedBox(height: AppSpacing.md),
            ...cities.map((raw) {
              final item = Map<String, dynamic>.from(raw as Map);
              final fee = Map<String, dynamic>.from(
                  (item['deliveryFee'] as Map?) ?? {});
              final cityId = (item['id'] ?? '').toString();
              final cityName =
                  (item['nameAr'] ?? item['name_ar'] ?? '').toString();
              final deliveryFee =
                  (fee['deliveryFee'] ?? fee['delivery_fee'] ?? '0').toString();
              final districts = Map<String, dynamic>.from(
                          (item['_count'] as Map?) ?? {})['districts']
                      ?.toString() ??
                  '0';
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(cityName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 16)),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                          'المديريات: $districts • رسوم التوصيل: $deliveryFee YER'),
                      const SizedBox(height: AppSpacing.sm),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: AppButton(
                          text: 'تعديل رسوم التوصيل',
                          onPressed: () => _editFee(
                              context, ref, cityId, cityName, deliveryFee),
                        ),
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
