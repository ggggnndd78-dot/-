import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/features/auth/logic/auth_controller.dart';
import 'package:ghiyarak/features/locations/data/locations_repository.dart';
import 'package:ghiyarak/shared/models/location_item.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:go_router/go_router.dart';

class LocationSelectionPage extends ConsumerStatefulWidget {
  const LocationSelectionPage({super.key});

  @override
  ConsumerState<LocationSelectionPage> createState() =>
      _LocationSelectionPageState();
}

class _LocationSelectionPageState extends ConsumerState<LocationSelectionPage> {
  List<LocationItem> _cities = const [];
  List<LocationItem> _districts = const [];

  LocationItem? _selectedCity;
  LocationItem? _selectedDistrict;

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  Future<void> _loadCities() async {
    try {
      final cities = await ref.read(locationsRepositoryProvider).fetchCities();

      if (!mounted) return;

      setState(() {
        _cities = cities;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  Future<void> _loadDistricts(int cityId) async {
    setState(() {
      _districts = const [];
      _selectedDistrict = null;
    });

    try {
      final districts =
          await ref.read(locationsRepositoryProvider).fetchDistricts(cityId);

      if (!mounted) return;

      setState(() {
        _districts = districts;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  Future<void> _save() async {
    if (_selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار المدينة'),
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await ref.read(locationsRepositoryProvider).saveLocation(
            cityId: _selectedCity!.id,
            cityName: _selectedCity!.name,
            districtId: _selectedDistrict?.id,
            districtName: _selectedDistrict?.name,
          );

      if (!mounted) return;

      final authState = ref.read(authControllerProvider);
      context.go(
          authState.isGuest ? RouteNames.marketplaceHome : RouteNames.vehicles);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'اختيار الموقع',
      showBottomNav: false,
      child: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                DropdownButtonFormField<LocationItem>(
                  initialValue: _selectedCity,
                  decoration: const InputDecoration(
                    labelText: 'المدينة',
                  ),
                  items: _cities
                      .map(
                        (city) => DropdownMenuItem<LocationItem>(
                          value: city,
                          child: Text(city.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCity = value;
                    });

                    if (value != null) {
                      _loadDistricts(value.id);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                DropdownButtonFormField<LocationItem>(
                  initialValue: _selectedDistrict,
                  decoration: const InputDecoration(
                    labelText: 'المنطقة / الحي',
                  ),
                  items: _districts
                      .map(
                        (district) => DropdownMenuItem<LocationItem>(
                          value: district,
                          child: Text(district.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDistrict = value;
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  text: 'حفظ ومتابعة',
                  isLoading: _saving,
                  onPressed: _save,
                ),
              ],
            ),
    );
  }
}
