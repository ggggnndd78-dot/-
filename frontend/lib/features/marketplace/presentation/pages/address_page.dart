import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/theme/app_colors.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/core/theme/app_text_styles.dart';
import 'package:ghiyarak/features/locations/data/locations_repository.dart';
import 'package:ghiyarak/features/profile/data/models/customer_address_model.dart';
import 'package:ghiyarak/features/profile/data/profile_repository.dart';
import 'package:ghiyarak/shared/models/location_item.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';

final customerAddressesProvider =
    FutureProvider.autoDispose<List<CustomerAddressModel>>((ref) {
  return ref.watch(profileRepositoryProvider).getCustomerAddresses();
});

class AddressPage extends ConsumerStatefulWidget {
  const AddressPage({super.key});

  @override
  ConsumerState<AddressPage> createState() => _AddressPageState();
}

class _AddressPageState extends ConsumerState<AddressPage> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerAddressesProvider);
    return AppScaffold(
      title: 'إدارة العناوين',
      child: RefreshIndicator(
        onRefresh: () async => ref.invalidate(customerAddressesProvider),
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ListView(
            children: [
              _HeaderCard(onAdd: () => _openEditor()),
              const SizedBox(height: AppSpacing.lg),
              _EmptyState(
                icon: Icons.error_outline,
                title: 'تعذر تحميل العناوين',
                message: error.toString(),
                actionText: 'إعادة المحاولة',
                onAction: () => ref.invalidate(customerAddressesProvider),
              ),
            ],
          ),
          data: (addresses) => ListView(
            children: [
              _HeaderCard(onAdd: () => _openEditor()),
              const SizedBox(height: AppSpacing.lg),
              _StatsRow(addresses: addresses),
              const SizedBox(height: AppSpacing.lg),
              if (addresses.isEmpty)
                _EmptyState(
                  icon: Icons.add_location_alt_outlined,
                  title: 'لا توجد عناوين بعد',
                  message:
                      'أضف عنوان توصيل واحد على الأقل حتى تتمكن من إكمال الطلبات بسهولة.',
                  actionText: 'إضافة عنوان',
                  onAction: () => _openEditor(),
                )
              else
                ...addresses.map(
                  (address) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _AddressCard(
                      address: address,
                      onEdit: () => _openEditor(address: address),
                      onDelete: () => _delete(address),
                      onSetDefault:
                          address.isDefault ? null : () => _setDefault(address),
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openEditor({CustomerAddressModel? address}) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _AddressEditorSheet(address: address),
    );
    if (changed == true) ref.invalidate(customerAddressesProvider);
  }

  Future<void> _setDefault(CustomerAddressModel address) async {
    try {
      await ref
          .read(profileRepositoryProvider)
          .setDefaultCustomerAddress(address.id);
      ref.invalidate(customerAddressesProvider);
      _snack('تم تعيين العنوان الافتراضي');
    } catch (e) {
      _snack('تعذر تعيين العنوان: $e');
    }
  }

  Future<void> _delete(CustomerAddressModel address) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف العنوان'),
        content: Text('هل تريد حذف عنوان ${address.label}؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref
          .read(profileRepositoryProvider)
          .deleteCustomerAddress(address.id);
      ref.invalidate(customerAddressesProvider);
      _snack('تم حذف العنوان');
    } catch (e) {
      _snack('تعذر حذف العنوان: $e');
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _HeaderCard extends StatelessWidget {
  final VoidCallback onAdd;
  const _HeaderCard({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadow, blurRadius: 18, offset: Offset(0, 10))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .13),
                borderRadius: BorderRadius.circular(18)),
            child: const Icon(Icons.location_on_outlined,
                color: AppColors.headerFooterAccent, size: 34),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('عناوين التوصيل',
                    style: AppTextStyles.title
                        .copyWith(color: AppColors.textOnDark)),
                const SizedBox(height: 4),
                Text(
                    'أضف عناوينك وحدد عنوانًا افتراضيًا لاستخدامه في إتمام الطلبات.',
                    style: AppTextStyles.body.copyWith(
                        color: AppColors.textOnDark.withValues(alpha: .82))),
              ],
            ),
          ),
          IconButton.filledTonal(
              onPressed: onAdd,
              icon: const Icon(Icons.add_location_alt_outlined)),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final List<CustomerAddressModel> addresses;
  const _StatsRow({required this.addresses});

  @override
  Widget build(BuildContext context) {
    final available = addresses.where((a) => a.isDeliveryAvailable).length;
    final withMap = addresses.where((a) => a.hasCoordinates).length;
    return Row(
      children: [
        Expanded(
            child: _MiniStat(
                label: 'العناوين',
                value: '${addresses.length}',
                icon: Icons.location_city_outlined)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
            child: _MiniStat(
                label: 'متاح للتوصيل',
                value: '$available',
                icon: Icons.local_shipping_outlined)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
            child: _MiniStat(
                label: 'بإحداثيات',
                value: '$withMap',
                icon: Icons.map_outlined)),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _MiniStat(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(height: 6),
          Text(value, style: AppTextStyles.title),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final CustomerAddressModel address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onSetDefault;

  const _AddressCard(
      {required this.address,
      required this.onEdit,
      required this.onDelete,
      required this.onSetDefault});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
            color: address.isDefault ? AppColors.primary : AppColors.border,
            width: address.isDefault ? 1.4 : 1),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadow, blurRadius: 14, offset: Offset(0, 7))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.accentSoft,
                child: Icon(
                    address.isDefault
                        ? Icons.home_rounded
                        : Icons.location_on_outlined,
                    color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Flexible(
                          child:
                              Text(address.label, style: AppTextStyles.title)),
                      if (address.isDefault) ...[
                        const SizedBox(width: 8),
                        const _Chip(
                            text: 'افتراضي', icon: Icons.check_circle_outline),
                      ],
                    ]),
                    Text(
                        address.locationLabel.isEmpty
                            ? 'موقع غير محدد'
                            : address.locationLabel,
                        style: AppTextStyles.bodySecondary),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'default' && onSetDefault != null) {
                    onSetDefault!();
                  }
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('تعديل')),
                  if (onSetDefault != null)
                    const PopupMenuItem(
                        value: 'default', child: Text('تعيين افتراضي')),
                  const PopupMenuItem(value: 'delete', child: Text('حذف')),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _Line(icon: Icons.person_outline, text: address.recipientName),
          _Line(
              icon: Icons.phone_outlined,
              text: address.alternativePhone.isEmpty
                  ? address.phone
                  : '${address.phone} / ${address.alternativePhone}'),
          _Line(icon: Icons.place_outlined, text: address.fullAddress),
          if (address.deliveryNotes.isNotEmpty)
            _Line(icon: Icons.notes_outlined, text: address.deliveryNotes),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(
                  text: address.isDeliveryAvailable
                      ? 'التوصيل متاح'
                      : 'خارج نطاق التوصيل',
                  icon: address.isDeliveryAvailable
                      ? Icons.local_shipping_outlined
                      : Icons.warning_amber_outlined),
              if (address.hasCoordinates)
                const _Chip(text: 'محدد على الخريطة', icon: Icons.map_outlined),
            ],
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Line({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 18, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: AppTextStyles.body)),
      ]),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final IconData icon;
  const _Chip({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: AppColors.accentSoft, borderRadius: BorderRadius.circular(30)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 15, color: AppColors.primary),
        const SizedBox(width: 5),
        Text(text, style: AppTextStyles.caption)
      ]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionText;
  final VoidCallback onAction;
  const _EmptyState(
      {required this.icon,
      required this.title,
      required this.message,
      required this.actionText,
      required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border)),
      child: Column(children: [
        Icon(icon, size: 56, color: AppColors.textMuted),
        const SizedBox(height: AppSpacing.md),
        Text(title, style: AppTextStyles.title, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.xs),
        Text(message,
            style: AppTextStyles.bodySecondary, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.lg),
        AppButton(text: actionText, onPressed: onAction),
      ]),
    );
  }
}

class _AddressEditorSheet extends ConsumerStatefulWidget {
  final CustomerAddressModel? address;
  const _AddressEditorSheet({this.address});

  @override
  ConsumerState<_AddressEditorSheet> createState() =>
      _AddressEditorSheetState();
}

class _AddressEditorSheetState extends ConsumerState<_AddressEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  final _label = TextEditingController();
  final _recipient = TextEditingController();
  final _phone = TextEditingController();
  final _altPhone = TextEditingController();
  final _line1 = TextEditingController();
  final _line2 = TextEditingController();
  final _landmark = TextEditingController();
  final _notes = TextEditingController();
  final _lat = TextEditingController();
  final _lng = TextEditingController();
  List<LocationItem> _cities = const [];
  List<LocationItem> _districts = const [];
  List<LocationItem> _areas = const [];
  LocationItem? _city;
  LocationItem? _district;
  LocationItem? _area;
  bool _loadingLocations = true;
  bool _saving = false;
  bool _isDefault = false;

  bool get _isEdit => widget.address != null;

  @override
  void initState() {
    super.initState();
    final a = widget.address;
    _label.text = a?.label ?? 'المنزل';
    _recipient.text = a?.recipientName ?? '';
    _phone.text = a?.phone ?? '';
    _altPhone.text = a?.alternativePhone ?? '';
    _line1.text = a?.addressLine1 ?? '';
    _line2.text = a?.addressLine2 ?? '';
    _landmark.text = a?.landmark ?? '';
    _notes.text = a?.deliveryNotes ?? '';
    _lat.text = a?.latitude?.toString() ?? '';
    _lng.text = a?.longitude?.toString() ?? '';
    _isDefault = a?.isDefault ?? false;
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    try {
      final repo = ref.read(locationsRepositoryProvider);
      final cities = await repo.fetchCities();
      final a = widget.address;
      LocationItem? city = _find(cities, a?.cityId);
      List<LocationItem> districts = const [];
      LocationItem? district;
      List<LocationItem> areas = const [];
      LocationItem? area;
      if (city != null) {
        districts = await repo.fetchDistricts(city.id);
        district = _find(districts, a?.districtId);
      }
      if (district != null) {
        areas = await repo.fetchAreas(district.id);
        area = _find(areas, a?.areaId);
      }
      if (!mounted) return;
      setState(() {
        _cities = cities;
        _city = city;
        _districts = districts;
        _district = district;
        _areas = areas;
        _area = area;
        _loadingLocations = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingLocations = false);
    }
  }

  LocationItem? _find(List<LocationItem> items, int? id) {
    if (id == null) return null;
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  @override
  void dispose() {
    for (final c in [
      _label,
      _recipient,
      _phone,
      _altPhone,
      _line1,
      _line2,
      _landmark,
      _notes,
      _lat,
      _lng
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: .92,
        minChildSize: .55,
        maxChildSize: .98,
        builder: (_, controller) => Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: Form(
            key: _formKey,
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Row(children: [
                  Expanded(
                      child: Text(_isEdit ? 'تعديل عنوان' : 'إضافة عنوان',
                          style: AppTextStyles.title)),
                  IconButton(
                      onPressed: () => Navigator.pop(context, false),
                      icon: const Icon(Icons.close)),
                ]),
                const SizedBox(height: AppSpacing.md),
                _Input(
                    controller: _label,
                    label: 'اسم العنوان',
                    icon: Icons.bookmark_outline,
                    required: true),
                _Input(
                    controller: _recipient,
                    label: 'اسم المستلم',
                    icon: Icons.person_outline,
                    required: true),
                _Input(
                    controller: _phone,
                    label: 'رقم التواصل',
                    icon: Icons.phone_outlined,
                    required: true,
                    keyboardType: TextInputType.phone),
                _Input(
                    controller: _altPhone,
                    label: 'رقم بديل اختياري',
                    icon: Icons.phone_android_outlined,
                    keyboardType: TextInputType.phone),
                const SizedBox(height: AppSpacing.sm),
                if (_loadingLocations)
                  const LinearProgressIndicator()
                else ...[
                  _LocationDropdown(
                    label: 'المدينة',
                    value: _city,
                    items: _cities,
                    required: true,
                    onChanged: (value) async {
                      setState(() {
                        _city = value;
                        _district = null;
                        _area = null;
                        _districts = const [];
                        _areas = const [];
                      });
                      if (value != null) {
                        final list = await ref
                            .read(locationsRepositoryProvider)
                            .fetchDistricts(value.id);
                        if (mounted) setState(() => _districts = list);
                      }
                    },
                  ),
                  _LocationDropdown(
                    label: 'المديرية / الحي',
                    value: _district,
                    items: _districts,
                    onChanged: (value) async {
                      setState(() {
                        _district = value;
                        _area = null;
                        _areas = const [];
                      });
                      if (value != null) {
                        final list = await ref
                            .read(locationsRepositoryProvider)
                            .fetchAreas(value.id);
                        if (mounted) setState(() => _areas = list);
                      }
                    },
                  ),
                  _LocationDropdown(
                      label: 'المنطقة',
                      value: _area,
                      items: _areas,
                      onChanged: (value) => setState(() => _area = value)),
                ],
                _Input(
                    controller: _line1,
                    label: 'العنوان التفصيلي',
                    icon: Icons.place_outlined,
                    required: true,
                    maxLines: 2),
                _Input(
                    controller: _line2,
                    label: 'تفاصيل إضافية',
                    icon: Icons.apartment_outlined,
                    maxLines: 2),
                _Input(
                    controller: _landmark,
                    label: 'علامة مميزة قريبة',
                    icon: Icons.flag_outlined),
                _Input(
                    controller: _notes,
                    label: 'ملاحظات للسائق',
                    icon: Icons.notes_outlined,
                    maxLines: 3),
                Row(children: [
                  Expanded(
                      child: _Input(
                          controller: _lat,
                          label: 'خط العرض',
                          icon: Icons.my_location_outlined,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true, signed: true))),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                      child: _Input(
                          controller: _lng,
                          label: 'خط الطول',
                          icon: Icons.explore_outlined,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true, signed: true))),
                ]),
                SwitchListTile(
                  value: _isDefault,
                  onChanged: (v) => setState(() => _isDefault = v),
                  title: const Text('تعيين كعنوان افتراضي'),
                  subtitle: const Text('سيظهر تلقائيًا في صفحة إتمام الطلب'),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                    text: _isEdit ? 'حفظ التعديلات' : 'إضافة العنوان',
                    isLoading: _saving,
                    onPressed: _save),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_city == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('اختر المدينة')));
      return;
    }
    setState(() => _saving = true);
    try {
      final payload = CustomerAddressPayload(
        label: _label.text,
        recipientName: _recipient.text,
        phone: _phone.text,
        alternativePhone: _altPhone.text,
        cityId: _city!.id,
        districtId: _district?.id,
        areaId: _area?.id,
        addressLine1: _line1.text,
        addressLine2: _line2.text,
        landmark: _landmark.text,
        deliveryNotes: _notes.text,
        latitude: double.tryParse(_lat.text.trim()),
        longitude: double.tryParse(_lng.text.trim()),
        isDefault: _isDefault,
      );
      if (_isEdit) {
        await ref
            .read(profileRepositoryProvider)
            .updateCustomerAddress(widget.address!.id, payload);
      } else {
        await ref
            .read(profileRepositoryProvider)
            .createCustomerAddress(payload);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('تعذر حفظ العنوان: $e')));
      }
    }
  }
}

class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool required;
  final int maxLines;
  final TextInputType? keyboardType;
  const _Input(
      {required this.controller,
      required this.label,
      required this.icon,
      this.required = false,
      this.maxLines = 1,
      this.keyboardType});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
        validator: required
            ? (v) => (v ?? '').trim().isEmpty ? 'هذا الحقل مطلوب' : null
            : null,
      ),
    );
  }
}

class _LocationDropdown extends StatelessWidget {
  final String label;
  final LocationItem? value;
  final List<LocationItem> items;
  final ValueChanged<LocationItem?> onChanged;
  final bool required;
  const _LocationDropdown(
      {required this.label,
      required this.value,
      required this.items,
      required this.onChanged,
      this.required = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: DropdownButtonFormField<LocationItem>(
        initialValue: value,
        items: items
            .map(
                (item) => DropdownMenuItem(value: item, child: Text(item.name)))
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.location_city_outlined)),
        validator:
            required ? (v) => v == null ? 'هذا الحقل مطلوب' : null : null,
      ),
    );
  }
}
