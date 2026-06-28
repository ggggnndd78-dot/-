import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/network/api_exception.dart';
import 'package:ghiyarak/features/locations/data/locations_repository.dart';
import 'package:ghiyarak/features/merchant_market/data/merchant_market_repository.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_bottom_navigation.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_drawer.dart';
import 'package:ghiyarak/shared/models/location_item.dart';

class MerchantBranchEditPage extends ConsumerStatefulWidget {
  const MerchantBranchEditPage({required this.branch, super.key});

  final MerchantBranchManagementItem branch;

  @override
  ConsumerState<MerchantBranchEditPage> createState() =>
      _MerchantBranchEditPageState();
}

class _MerchantBranchEditPageState
    extends ConsumerState<MerchantBranchEditPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  final _branchName = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _latitude = TextEditingController();
  final _longitude = TextEditingController();

  List<LocationItem> _cities = const [];
  List<LocationItem> _districts = const [];
  LocationItem? _selectedCity;
  LocationItem? _selectedDistrict;
  bool _loading = true;
  bool _loadingDistricts = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final branch = widget.branch;
    _branchName.text = branch.name;
    _address.text = branch.address ?? '';
    _phone.text = branch.phone ?? '';
    _latitude.text = branch.latitude?.toString() ?? '';
    _longitude.text = branch.longitude?.toString() ?? '';
    _loadLocations();
  }

  @override
  void dispose() {
    _branchName.dispose();
    _address.dispose();
    _phone.dispose();
    _latitude.dispose();
    _longitude.dispose();
    super.dispose();
  }

  Future<void> _loadLocations() async {
    try {
      final cities = await ref.read(locationsRepositoryProvider).fetchCities();
      final selectedCity = _matchLocation(widget.branch.cityName, cities);
      List<LocationItem> districts = const [];
      LocationItem? selectedDistrict;
      if (selectedCity != null) {
        districts = await ref
            .read(locationsRepositoryProvider)
            .fetchDistricts(selectedCity.id);
        selectedDistrict =
            _matchLocation(widget.branch.districtName, districts);
      }
      if (!mounted) return;
      setState(() {
        _cities = cities;
        _selectedCity = selectedCity;
        _districts = districts;
        _selectedDistrict = selectedDistrict;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  LocationItem? _matchLocation(String? name, List<LocationItem> items) {
    final text = (name ?? '').trim().toLowerCase();
    if (text.isEmpty) return null;
    for (final item in items) {
      final itemName = item.name.trim().toLowerCase();
      if (itemName == text ||
          itemName.contains(text) ||
          text.contains(itemName)) {
        return item;
      }
    }
    return null;
  }

  Future<void> _selectCity(LocationItem? city) async {
    setState(() {
      _selectedCity = city;
      _selectedDistrict = null;
      _districts = const [];
    });
    if (city == null) return;
    setState(() => _loadingDistricts = true);
    try {
      final districts =
          await ref.read(locationsRepositoryProvider).fetchDistricts(city.id);
      if (!mounted) return;
      setState(() => _districts = districts);
    } catch (_) {
      if (mounted) _showSnack('تعذر تحميل المناطق.');
    } finally {
      if (mounted) setState(() => _loadingDistricts = false);
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    try {
      await ref.read(merchantMarketRepositoryProvider).updateMerchantBranch(
            branchId: widget.branch.id,
            branchName: _branchName.text,
            addressLine1: _address.text,
            cityId: _selectedCity?.id,
            districtId: _selectedDistrict?.id,
            phone: _phone.text,
            latitude: _parseOptionalDouble(_latitude.text),
            longitude: _parseOptionalDouble(_longitude.text),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث الفرع بنجاح')),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      _showSnack(_errorMessage(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  double? _parseOptionalDouble(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;
    return double.parse(text);
  }

  String _errorMessage(Object error) {
    if (error is ApiException) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        return 'غير مصرح لك بتعديل هذا الفرع.';
      }
      return error.message;
    }
    return 'تعذر تحديث الفرع.';
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String? _required(String? value, String message) {
    return (value ?? '').trim().isEmpty ? message : null;
  }

  String? _phoneValidator(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    return RegExp(r'^\+?[0-9]{7,15}$').hasMatch(text)
        ? null
        : 'رقم الهاتف غير صحيح';
  }

  String? _coordinateValidator({
    required String? value,
    required String otherValue,
    required String label,
    required double min,
    required double max,
  }) {
    final text = (value ?? '').trim();
    final other = otherValue.trim();
    if (text.isEmpty && other.isEmpty) return null;
    if (text.isEmpty) return '$label مطلوب عند تحديد الإحداثيات';
    final number = double.tryParse(text);
    if (number == null) return '$label يجب أن يكون رقمًا';
    if (number < min || number > max) return '$label خارج النطاق الصحيح';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF5F7FA),
        drawer: const MerchantDrawer(
          currentTab: MerchantNavigationTab.settings,
        ),
        bottomNavigationBar: const MerchantBottomNavigation(
          currentTab: MerchantNavigationTab.settings,
        ),
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFFF7900)),
              )
            : Column(
                children: [
                  _Header(
                      onMenu: () => _scaffoldKey.currentState?.openDrawer()),
                  Expanded(
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                        children: [
                          _Field(
                            controller: _branchName,
                            label: 'اسم الفرع',
                            icon: Icons.store_outlined,
                            validator: (value) =>
                                _required(value, 'اسم الفرع مطلوب'),
                          ),
                          const SizedBox(height: 12),
                          _CityDropdown(
                            cities: _cities,
                            value: _selectedCity,
                            onChanged: _selectCity,
                          ),
                          const SizedBox(height: 12),
                          _DistrictDropdown(
                            districts: _districts,
                            value: _selectedDistrict,
                            loading: _loadingDistricts,
                            onChanged: (value) =>
                                setState(() => _selectedDistrict = value),
                          ),
                          const SizedBox(height: 12),
                          _Field(
                            controller: _address,
                            label: 'العنوان',
                            icon: Icons.location_on_outlined,
                            validator: (value) =>
                                _required(value, 'العنوان مطلوب'),
                          ),
                          const SizedBox(height: 12),
                          _Field(
                            controller: _phone,
                            label: 'رقم الهاتف',
                            icon: Icons.call_outlined,
                            keyboardType: TextInputType.phone,
                            validator: _phoneValidator,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9+]')),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _Field(
                                  controller: _latitude,
                                  label: 'خط العرض latitude',
                                  icon: Icons.my_location_outlined,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    signed: true,
                                    decimal: true,
                                  ),
                                  validator: (value) => _coordinateValidator(
                                    value: value,
                                    otherValue: _longitude.text,
                                    label: 'خط العرض',
                                    min: -90,
                                    max: 90,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _Field(
                                  controller: _longitude,
                                  label: 'خط الطول longitude',
                                  icon: Icons.explore_outlined,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    signed: true,
                                    decimal: true,
                                  ),
                                  validator: (value) => _coordinateValidator(
                                    value: value,
                                    otherValue: _latitude.text,
                                    label: 'خط الطول',
                                    min: -180,
                                    max: 180,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          FilledButton.icon(
                            onPressed: _saving ? null : _save,
                            icon: _saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: Text(
                              _saving ? 'جاري الحفظ...' : 'حفظ التعديلات',
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFFF7900),
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onMenu});

  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 12,
        20,
        28,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF061A2D), Color(0xFF0E3659)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onMenu,
            icon: const Icon(Icons.menu_rounded),
            color: Colors.white,
            tooltip: 'القائمة',
          ),
          const Expanded(
            child: Text(
              'تعديل الفرع',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 25,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(false),
            icon: const Icon(Icons.close_rounded),
            color: Colors.white,
            tooltip: 'إغلاق',
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: _inputDecoration(label, icon),
    );
  }
}

class _CityDropdown extends StatelessWidget {
  const _CityDropdown({
    required this.cities,
    required this.value,
    required this.onChanged,
  });

  final List<LocationItem> cities;
  final LocationItem? value;
  final ValueChanged<LocationItem?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<LocationItem>(
      initialValue: value,
      decoration: _inputDecoration('المدينة', Icons.location_city_outlined),
      items: [
        for (final city in cities)
          DropdownMenuItem(value: city, child: Text(city.name)),
      ],
      onChanged: onChanged,
    );
  }
}

class _DistrictDropdown extends StatelessWidget {
  const _DistrictDropdown({
    required this.districts,
    required this.value,
    required this.loading,
    required this.onChanged,
  });

  final List<LocationItem> districts;
  final LocationItem? value;
  final bool loading;
  final ValueChanged<LocationItem?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<LocationItem>(
      initialValue: value,
      decoration: _inputDecoration(
        loading ? 'جاري تحميل المنطقة / الحي' : 'المنطقة / الحي',
        Icons.map_outlined,
      ),
      items: [
        for (final district in districts)
          DropdownMenuItem(value: district, child: Text(district.name)),
      ],
      onChanged: loading ? null : onChanged,
    );
  }
}

InputDecoration _inputDecoration(String label, IconData icon) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE4EAF0)),
    ),
  );
}
