import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/features/locations/data/locations_repository.dart';
import 'package:ghiyarak/features/provider_onboarding/logic/provider_onboarding_controller.dart';
import 'package:ghiyarak/shared/models/location_item.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:ghiyarak/shared/widgets/app_text_field.dart';
import 'package:go_router/go_router.dart';

class ProviderBranchPage extends ConsumerStatefulWidget {
  const ProviderBranchPage({super.key});

  @override
  ConsumerState<ProviderBranchPage> createState() => _ProviderBranchPageState();
}

class _ProviderBranchPageState extends ConsumerState<ProviderBranchPage> {
  final _formKey = GlobalKey<FormState>();

  final _branchName = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();

  List<LocationItem> _cities = const [];
  List<LocationItem> _districts = const [];

  LocationItem? _selectedCity;
  LocationItem? _selectedDistrict;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cities = await ref.read(locationsRepositoryProvider).fetchCities();

    if (!context.mounted) return;

    setState(() {
      _cities = cities;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _branchName.dispose();
    _address.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(providerOnboardingControllerProvider);

    return AppScaffold(
      title: 'الفرع الأول',
      child: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  AppTextField(
                    controller: _branchName,
                    label: 'اسم الفرع',
                    validator: (v) =>
                        (v?.trim().isEmpty ?? true) ? 'الحقل مطلوب' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<LocationItem>(
                    initialValue: _selectedCity,
                    decoration: const InputDecoration(
                      labelText: 'المدينة',
                    ),
                    items: _cities
                        .map(
                          (e) => DropdownMenuItem<LocationItem>(
                            value: e,
                            child: Text(e.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) async {
                      setState(() {
                        _selectedCity = v;
                        _selectedDistrict = null;
                        _districts = const [];
                      });

                      if (v != null) {
                        final districts = await ref
                            .read(locationsRepositoryProvider)
                            .fetchDistricts(v.id);

                        if (!context.mounted) return;

                        setState(() {
                          _districts = districts;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<LocationItem>(
                    initialValue: _selectedDistrict,
                    decoration: const InputDecoration(
                      labelText: 'المنطقة',
                    ),
                    items: _districts
                        .map(
                          (e) => DropdownMenuItem<LocationItem>(
                            value: e,
                            child: Text(e.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        _selectedDistrict = v;
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _address,
                    label: 'العنوان',
                    validator: (v) =>
                        (v?.trim().isEmpty ?? true) ? 'الحقل مطلوب' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _phone,
                    label: 'جوال الفرع',
                    keyboardType: TextInputType.phone,
                    validator: (v) =>
                        (v?.trim().length ?? 0) < 9 ? 'رقم غير صالح' : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    text: 'حفظ ومتابعة',
                    isLoading: state.loading,
                    onPressed: () async {
                      if (!_formKey.currentState!.validate() ||
                          _selectedCity == null) {
                        return;
                      }

                      final ok = await ref
                          .read(
                            providerOnboardingControllerProvider.notifier,
                          )
                          .createBranch(
                            branchName: _branchName.text.trim(),
                            cityId: _selectedCity!.id,
                            districtId: _selectedDistrict?.id,
                            addressLine1: _address.text.trim(),
                            phone: _phone.text.trim(),
                          );

                      if (!context.mounted) return;

                      if (ok) {
                        context.go(RouteNames.providerProfile);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              ref
                                      .read(
                                        providerOnboardingControllerProvider,
                                      )
                                      .errorMessage ??
                                  'تعذر حفظ الفرع',
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
