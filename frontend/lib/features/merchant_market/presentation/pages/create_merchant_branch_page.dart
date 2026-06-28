import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/features/locations/data/locations_repository.dart';
import 'package:ghiyarak/features/merchant_market/data/merchant_market_repository.dart';
import 'package:ghiyarak/features/merchant_market/data/models/merchant_organization_model.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_bottom_navigation.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_drawer.dart';
import 'package:ghiyarak/shared/models/location_item.dart';
import 'package:go_router/go_router.dart';

class CreateMerchantBranchPage extends ConsumerStatefulWidget {
  const CreateMerchantBranchPage({super.key, this.branchId});
  final String? branchId;
  bool get isEdit => (branchId ?? '').isNotEmpty;

  @override
  ConsumerState<CreateMerchantBranchPage> createState() =>
      _CreateMerchantBranchPageState();
}

class _CreateMerchantBranchPageState
    extends ConsumerState<CreateMerchantBranchPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  final _branchName = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _lat = TextEditingController();
  final _lng = TextEditingController();
  final List<_HourDraft> _hours = List.generate(7, (i) => _HourDraft(day: i));

  List<LocationItem> _cities = const [];
  LocationItem? _selectedCity;
  String? _organizationId;
  bool _loading = true;
  bool _saving = false;
  bool _headOffice = false;
  bool _pickup = true;
  bool _delivery = true;
  bool _installation = false;
  bool _mobile = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final repository = ref.read(merchantMarketRepositoryProvider);
      final results = await Future.wait([
        ref.read(locationsRepositoryProvider).fetchCities(),
        repository.getMerchantOrganization(),
      ]);
      final cities = (results[0] as List<LocationItem>);
      final org = results[1] as MerchantOrganizationModel;
      MerchantBranchModel? branch;
      if (widget.isEdit) {
        for (final item in org.branches) {
          if (item.id == widget.branchId) branch = item;
        }
        branch ??= await repository.getBranch(
            organizationId: org.id, branchId: widget.branchId!);
      }
      if (branch != null) _fill(branch, cities);
      if (!mounted) return;
      setState(() {
        _cities = cities;
        _organizationId = org.id;
        if (_selectedCity == null && cities.isNotEmpty)
          _selectedCity = cities.first;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _toast('تعذر تحميل بيانات الفرع: $e');
    }
  }

  void _fill(MerchantBranchModel branch, List<LocationItem> cities) {
    _branchName.text = branch.name;
    _address.text = branch.address ?? '';
    _phone.text = branch.phone ?? '';
    _email.text = branch.email ?? '';
    _lat.text = branch.latitude?.toString() ?? '';
    _lng.text = branch.longitude?.toString() ?? '';
    _headOffice = branch.isHeadOffice;
    _pickup = branch.supportsPickup;
    _delivery = branch.supportsDelivery;
    _installation = branch.supportsInstallation;
    _mobile = branch.supportsMobileService;
    if (branch.cityId != null) {
      for (final city in cities) {
        if (city.id == branch.cityId) _selectedCity = city;
      }
    }
    if (branch.businessHours.isNotEmpty) {
      for (final h in branch.businessHours) {
        if (h.dayOfWeek >= 0 && h.dayOfWeek < 7) {
          _hours[h.dayOfWeek]
            ..isClosed = h.isClosed
            ..openTime = h.openTime ?? '09:00'
            ..closeTime = h.closeTime ?? '21:00';
        }
      }
    }
  }

  @override
  void dispose() {
    _branchName.dispose();
    _address.dispose();
    _phone.dispose();
    _email.dispose();
    _lat.dispose();
    _lng.dispose();
    super.dispose();
  }

  Future<void> _save({required bool draft}) async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false) ||
        _selectedCity == null) {
      _toast('أكمل الحقول المطلوبة.');
      return;
    }
    final orgId = _organizationId;
    if ((orgId ?? '').isEmpty) {
      _toast('تعذر تحديد مؤسسة التاجر.');
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = ref.read(merchantMarketRepositoryProvider);
      final hours = _hours.map((h) => h.toMap()).toList();
      final lat = double.tryParse(_lat.text.trim());
      final lng = double.tryParse(_lng.text.trim());
      if (widget.isEdit) {
        await repo.updateBranch(
          organizationId: orgId!,
          branchId: widget.branchId!,
          branchName: _branchName.text,
          cityId: _selectedCity!.id,
          email: _email.text,
          phone: _phone.text,
          addressLine1: _address.text,
          supportsPickup: _pickup,
          supportsDelivery: _delivery,
          supportsInstallation: _installation,
          supportsMobileService: _mobile,
          isHeadOffice: _headOffice,
          latitude: lat,
          longitude: lng,
          businessHours: hours,
        );
      } else {
        await repo.createBranch(
          organizationId: orgId!,
          branchName: _branchName.text,
          cityId: _selectedCity!.id,
          email: _email.text,
          phone: _phone.text,
          addressLine1: _address.text,
          supportsPickup: _pickup,
          supportsDelivery: _delivery,
          supportsInstallation: _installation,
          supportsMobileService: _mobile,
          isHeadOffice: _headOffice,
          latitude: lat,
          longitude: lng,
          businessHours: hours,
        );
      }
      if (!mounted) return;
      _toast(draft
          ? 'تم حفظ الفرع كمسودة تشغيلية.'
          : widget.isEdit
              ? 'تم تحديث الفرع بنجاح.'
              : 'تم إنشاء الفرع بنجاح.');
      context.go(RouteNames.merchantBranches);
    } catch (e) {
      if (!mounted) return;
      _toast('تعذر حفظ الفرع: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toast(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF5F7FA),
        drawer:
            const MerchantDrawer(currentTab: MerchantNavigationTab.settings),
        bottomNavigationBar: const MerchantBottomNavigation(
            currentTab: MerchantNavigationTab.settings),
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFFF6500)))
            : Column(children: [
                _Header(
                    title: widget.isEdit ? 'تعديل الفرع' : 'إضافة فرع جديد',
                    onMenu: () => _scaffoldKey.currentState?.openDrawer()),
                Expanded(
                    child: Form(
                  key: _formKey,
                  child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                      children: [
                        _Section(
                            title: 'البيانات الأساسية',
                            icon: Icons.storefront_outlined,
                            child: Column(children: [
                              _Input(
                                  controller: _branchName,
                                  label: 'اسم الفرع *',
                                  icon: Icons.store_outlined,
                                  validator: (v) => (v ?? '').trim().length < 2
                                      ? 'اسم الفرع مطلوب'
                                      : null),
                              const SizedBox(height: 12),
                              Row(children: [
                                Expanded(
                                    child: _CityDropdown(
                                        cities: _cities,
                                        value: _selectedCity,
                                        onChanged: (v) =>
                                            setState(() => _selectedCity = v))),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: _Input(
                                        controller: _phone,
                                        label: 'رقم الهاتف',
                                        icon: Icons.phone_outlined,
                                        keyboardType: TextInputType.phone)),
                              ]),
                              const SizedBox(height: 12),
                              _Input(
                                  controller: _email,
                                  label: 'البريد الإلكتروني',
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) {
                                    final value = (v ?? '').trim();
                                    if (value.isEmpty) return null;
                                    return value.contains('@')
                                        ? null
                                        : 'بريد غير صحيح';
                                  }),
                              const SizedBox(height: 12),
                              _Input(
                                  controller: _address,
                                  label: 'العنوان التفصيلي',
                                  icon: Icons.location_on_outlined,
                                  maxLines: 2),
                            ])),
                        const SizedBox(height: 14),
                        _Section(
                            title: 'الخدمات وحالة الفرع',
                            icon: Icons.miscellaneous_services_outlined,
                            child: Column(children: [
                              SwitchListTile(
                                  value: _headOffice,
                                  onChanged: (v) =>
                                      setState(() => _headOffice = v),
                                  title: const Text('فرع رئيسي'),
                                  subtitle: const Text(
                                      'عند التفعيل يصبح هذا الفرع هو الفرع الرئيسي للمتجر')),
                              SwitchListTile(
                                  value: _pickup,
                                  onChanged: (v) => setState(() => _pickup = v),
                                  title: const Text('يدعم الاستلام من الفرع')),
                              SwitchListTile(
                                  value: _delivery,
                                  onChanged: (v) =>
                                      setState(() => _delivery = v),
                                  title: const Text('يدعم التوصيل')),
                              SwitchListTile(
                                  value: _installation,
                                  onChanged: (v) =>
                                      setState(() => _installation = v),
                                  title: const Text('يدعم التركيب')),
                              SwitchListTile(
                                  value: _mobile,
                                  onChanged: (v) => setState(() => _mobile = v),
                                  title: const Text('يدعم الخدمة المتنقلة')),
                            ])),
                        const SizedBox(height: 14),
                        _Section(
                            title: 'موقع الفرع',
                            icon: Icons.map_outlined,
                            child: Column(children: [
                              const _MapHint(),
                              const SizedBox(height: 12),
                              Row(children: [
                                Expanded(
                                    child: _Input(
                                        controller: _lat,
                                        label: 'خط العرض',
                                        icon: Icons.my_location_outlined,
                                        keyboardType: const TextInputType
                                            .numberWithOptions(decimal: true),
                                        inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                          RegExp(r'[0-9.\-]'))
                                    ])),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: _Input(
                                        controller: _lng,
                                        label: 'خط الطول',
                                        icon: Icons.explore_outlined,
                                        keyboardType: const TextInputType
                                            .numberWithOptions(decimal: true),
                                        inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                          RegExp(r'[0-9.\-]'))
                                    ])),
                              ]),
                            ])),
                        const SizedBox(height: 14),
                        _Section(
                            title: 'أوقات العمل',
                            icon: Icons.access_time_rounded,
                            child: Column(children: [
                              for (final hour in _hours)
                                _HourRow(
                                    draft: hour,
                                    onChanged: () => setState(() {})),
                            ])),
                        const SizedBox(height: 18),
                        Row(children: [
                          Expanded(
                              child: OutlinedButton.icon(
                                  onPressed:
                                      _saving ? null : () => _save(draft: true),
                                  icon: const Icon(Icons.save_outlined),
                                  label: const Text('حفظ كمسودة'),
                                  style: OutlinedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(52)))),
                          const SizedBox(width: 10),
                          Expanded(
                              child: FilledButton.icon(
                                  onPressed: _saving
                                      ? null
                                      : () => _save(draft: false),
                                  icon: _saving
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white))
                                      : const Icon(Icons.check_rounded),
                                  label: Text(widget.isEdit
                                      ? 'تحديث الفرع'
                                      : 'حفظ الفرع'),
                                  style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFFFF6500),
                                      minimumSize: const Size.fromHeight(52)))),
                        ]),
                      ]),
                )),
              ]),
      ),
    );
  }
}

class _HourDraft {
  _HourDraft({required this.day})
      : openTime = '09:00',
        closeTime = '21:00',
        isClosed = false;
  final int day;
  String openTime;
  String closeTime;
  bool isClosed;
  Map<String, dynamic> toMap() => {
        'dayOfWeek': day,
        if (!isClosed) 'openTime': openTime,
        if (!isClosed) 'closeTime': closeTime,
        'isClosed': isClosed
      };
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onMenu});
  final String title;
  final VoidCallback onMenu;
  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.fromLTRB(
            20, MediaQuery.paddingOf(context).top + 10, 20, 28),
        decoration: const BoxDecoration(
            gradient:
                LinearGradient(colors: [Color(0xFF061A2D), Color(0xFF0E3659)]),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24))),
        child: Column(children: [
          Row(children: [
            IconButton(
                onPressed: onMenu,
                icon: const Icon(Icons.menu_rounded,
                    color: Colors.white, size: 30)),
            const Spacer(),
            Image.asset('assets/images/ghiyarak_logo_transparent.png',
                width: 126, height: 58),
            const Spacer(),
            IconButton(
                onPressed: () => context.go(RouteNames.merchantBranches),
                icon: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 30))
          ]),
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Text('بيانات الفرع، الخدمات، الموقع، وأوقات العمل',
              style: TextStyle(color: Color(0xFFD6E2EC))),
        ]),
      );
}

class _Section extends StatelessWidget {
  const _Section(
      {required this.title, required this.icon, required this.child});
  final String title;
  final IconData icon;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Icon(icon, color: const Color(0xFF082B51)),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF092B4D)))
          ]),
          const SizedBox(height: 14),
          child
        ]),
      );
}

class _Input extends StatelessWidget {
  const _Input(
      {required this.controller,
      required this.label,
      this.icon,
      this.validator,
      this.keyboardType,
      this.inputFormatters,
      this.maxLines = 1});
  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        decoration: InputDecoration(
            labelText: label,
            prefixIcon: icon == null ? null : Icon(icon),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(13)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(color: Color(0xFFDCE4EC)))),
      );
}

class _CityDropdown extends StatelessWidget {
  const _CityDropdown(
      {required this.cities, required this.value, required this.onChanged});
  final List<LocationItem> cities;
  final LocationItem? value;
  final ValueChanged<LocationItem?> onChanged;
  @override
  Widget build(BuildContext context) => DropdownButtonFormField<LocationItem>(
        initialValue: value,
        validator: (value) => value == null ? 'اختر المدينة' : null,
        decoration: InputDecoration(
            labelText: 'المدينة *',
            filled: true,
            fillColor: Colors.white,
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(13))),
        items: cities
            .map(
                (city) => DropdownMenuItem(value: city, child: Text(city.name)))
            .toList(),
        onChanged: onChanged,
      );
}

class _MapHint extends StatelessWidget {
  const _MapHint();
  @override
  Widget build(BuildContext context) => Container(
        height: 100,
        decoration: BoxDecoration(
            color: const Color(0xFFEAF2FB),
            borderRadius: BorderRadius.circular(16)),
        child: const Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.location_pin, color: Color(0xFFFF6500), size: 38),
          SizedBox(height: 6),
          Text('أدخل الإحداثيات يدويًا أو اربط الخريطة لاحقًا',
              style: TextStyle(fontWeight: FontWeight.w800))
        ])),
      );
}

class _HourRow extends StatelessWidget {
  const _HourRow({required this.draft, required this.onChanged});
  final _HourDraft draft;
  final VoidCallback onChanged;
  static const days = [
    'الأحد',
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت'
  ];
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE0E7EF))),
        child: Column(children: [
          Row(children: [
            Expanded(
                child: Text(days[draft.day],
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF092B4D)))),
            Switch(
                value: !draft.isClosed,
                onChanged: (v) {
                  draft.isClosed = !v;
                  onChanged();
                })
          ]),
          if (!draft.isClosed)
            Row(children: [
              Expanded(
                  child: _TimeField(
                      label: 'يفتح',
                      value: draft.openTime,
                      onChanged: (v) {
                        draft.openTime = v;
                        onChanged();
                      })),
              const SizedBox(width: 8),
              Expanded(
                  child: _TimeField(
                      label: 'يغلق',
                      value: draft.closeTime,
                      onChanged: (v) {
                        draft.closeTime = v;
                        onChanged();
                      })),
            ])
          else
            const Align(
                alignment: Alignment.centerRight,
                child: Text('مغلق طوال اليوم',
                    style: TextStyle(
                        color: Color(0xFFE11D48),
                        fontWeight: FontWeight.w800))),
        ]),
      );
}

class _TimeField extends StatelessWidget {
  const _TimeField(
      {required this.label, required this.value, required this.onChanged});
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => TextFormField(
        initialValue: value,
        onChanged: onChanged,
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9:]'))],
        decoration: InputDecoration(
            labelText: label,
            hintText: '09:00',
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
      );
}

final _cardDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(18),
  border: Border.all(color: const Color(0xFFE0E7EF)),
  boxShadow: const [
    BoxShadow(color: Color(0x0F051E35), blurRadius: 14, offset: Offset(0, 8))
  ],
);
