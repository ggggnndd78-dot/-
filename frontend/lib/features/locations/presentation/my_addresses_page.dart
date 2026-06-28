import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/features/locations/data/address_repository.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:ghiyarak/shared/widgets/app_text_field.dart';
import 'package:ghiyarak/shared/widgets/section_title.dart';

final myAddressesProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(addressRepositoryProvider).myAddresses();
});

class MyAddressesPage extends ConsumerWidget {
  const MyAddressesPage({super.key});

  Future<void> _addAddress(BuildContext context, WidgetRef ref) async {
    final label = TextEditingController(text: 'المنزل');
    final recipient = TextEditingController();
    final phone = TextEditingController();
    final cityId = TextEditingController();
    final districtId = TextEditingController();
    final address = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة عنوان'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(controller: label, label: 'اسم العنوان'),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(controller: recipient, label: 'اسم المستلم'),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(controller: phone, label: 'رقم الجوال'),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(controller: cityId, label: 'رقم المدينة City ID'),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(
                    controller: districtId,
                    label: 'رقم المديرية District ID اختياري'),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(controller: address, label: 'العنوان التفصيلي'),
              ],
            ),
          ),
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
    await ref.read(addressRepositoryProvider).createAddress({
      'label': label.text.trim(),
      'recipientName': recipient.text.trim(),
      'phone': phone.text.trim(),
      'cityId': int.tryParse(cityId.text.trim()) ?? 0,
      if (districtId.text.trim().isNotEmpty)
        'districtId': int.tryParse(districtId.text.trim()),
      'addressLine1': address.text.trim(),
      'isDefault': true,
    });
    ref.invalidate(myAddressesProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myAddressesProvider);
    return AppScaffold(
      title: 'عناويني',
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (items) => ListView(
          children: [
            const SectionTitle(
              title: 'عناوين التوصيل',
              subtitle: 'إضافة عناوين العميل لاستخدامها في الطلبات القادمة.',
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
                text: 'إضافة عنوان',
                onPressed: () => _addAddress(context, ref)),
            const SizedBox(height: AppSpacing.md),
            if (items.isEmpty)
              const Card(
                  child: Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Text('لا توجد عناوين محفوظة.'))),
            ...items.map((item) => Card(
                  child: ListTile(
                    title: Text(
                        '${item.label} ${item.isDefault ? '• الافتراضي' : ''}'),
                    subtitle: Text(
                        '${item.recipientName} • ${item.phone}\n${item.cityName}${item.districtName == null ? '' : ' - ${item.districtName}'}\n${item.addressLine1}'),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        await ref
                            .read(addressRepositoryProvider)
                            .deleteAddress(item.id);
                        ref.invalidate(myAddressesProvider);
                      },
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
