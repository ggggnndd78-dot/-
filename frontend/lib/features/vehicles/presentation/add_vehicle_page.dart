import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/features/vehicles/data/vehicles_repository.dart';
import 'package:ghiyarak/shared/models/lookup_item.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:go_router/go_router.dart';

class AddVehiclePage extends ConsumerStatefulWidget {
  const AddVehiclePage({super.key});

  @override
  ConsumerState<AddVehiclePage> createState() => _AddVehiclePageState();
}

class _AddVehiclePageState extends ConsumerState<AddVehiclePage> {
  final _formKey = GlobalKey<FormState>();
  final _yearController = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  List<LookupItem> _makes = [];
  List<LookupItem> _models = [];

  LookupItem? _selectedMake;
  LookupItem? _selectedModel;

  @override
  void initState() {
    super.initState();
    _loadMakes();
  }

  Future<void> _loadMakes() async {
    try {
      final makes = await ref.read(vehiclesRepositoryProvider).getMakes();

      if (!mounted) return;

      setState(() {
        _makes = makes;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _loadModels(int makeId) async {
    setState(() {
      _models = [];
      _selectedModel = null;
      _loading = true;
    });

    try {
      final models =
          await ref.read(vehiclesRepositoryProvider).getModels(makeId);

      if (!mounted) return;

      setState(() {
        _models = models;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedMake == null || _selectedModel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار شركة السيارة والموديل'),
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await ref.read(vehiclesRepositoryProvider).addVehicle(
            makeId: _selectedMake!.id,
            modelId: _selectedModel!.id,
            yearValue: int.parse(_yearController.text.trim()),
          );

      if (!mounted) return;

      context.go(RouteNames.vehicles);
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
      title: 'إضافة سيارة',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            DropdownButtonFormField<LookupItem>(
              initialValue: _selectedMake,
              decoration: const InputDecoration(
                labelText: 'شركة السيارة',
              ),
              items: _makes
                  .map(
                    (make) => DropdownMenuItem<LookupItem>(
                      value: make,
                      child: Text(make.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedMake = value;
                });

                if (value != null) {
                  _loadModels(value.id);
                }
              },
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<LookupItem>(
              initialValue: _selectedModel,
              decoration: const InputDecoration(
                labelText: 'الموديل',
              ),
              items: _models
                  .map(
                    (model) => DropdownMenuItem<LookupItem>(
                      value: model,
                      child: Text(model.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedModel = value;
                });
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _yearController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'سنة الصنع',
                hintText: 'مثال: 2020',
              ),
              validator: (value) {
                final v = value?.trim() ?? '';

                if (v.isEmpty) {
                  return 'سنة الصنع مطلوبة';
                }

                final year = int.tryParse(v);

                if (year == null) {
                  return 'سنة الصنع غير صحيحة';
                }

                if (year < 1980 || year > 2035) {
                  return 'سنة الصنع خارج النطاق';
                }

                return null;
              },
            ),
            if (_loading) ...[
              const SizedBox(height: AppSpacing.md),
              const CircularProgressIndicator(),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              text: 'حفظ السيارة',
              isLoading: _saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
