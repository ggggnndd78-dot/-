import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/core/i18n/app_localizations.dart';
import 'package:ghiyarak/core/theme/app_colors.dart';
import 'package:ghiyarak/core/theme/app_radius.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/core/theme/app_text_styles.dart';
import 'package:ghiyarak/core/validation/yemen_phone_validator.dart';
import 'package:ghiyarak/features/auth/logic/auth_controller.dart';
import 'package:ghiyarak/features/auth/logic/auth_state.dart';
import 'package:ghiyarak/features/locations/data/locations_repository.dart';
import 'package:ghiyarak/features/locations/presentation/map_location_picker_page.dart';
import 'package:ghiyarak/shared/models/location_item.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:ghiyarak/shared/widgets/app_text_field.dart';

const int _maxVerificationDocumentBytes = 5 * 1024 * 1024;

class RegisterPage extends ConsumerStatefulWidget {
  final String accountType;

  const RegisterPage({super.key, this.accountType = ''});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _PickedVerificationDocument {
  final String documentType;
  final String side;
  final String fileName;
  final String mimeType;
  final int fileSizeBytes;
  final String fileContentBase64;

  const _PickedVerificationDocument({
    required this.documentType,
    required this.side,
    required this.fileName,
    required this.mimeType,
    required this.fileSizeBytes,
    required this.fileContentBase64,
  });

  Map<String, dynamic> toJson() => {
        'documentType': documentType,
        'side': side,
        'fileName': fileName,
        'mimeType': mimeType,
        'fileSizeBytes': fileSizeBytes,
        'fileContentBase64': fileContentBase64,
      };
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _detailsFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _branchNameController = TextEditingController(text: 'الفرع الرئيسي');
  final _businessNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _mapUrlController = TextEditingController();
  final _otpController = TextEditingController();

  String _accountType = '';
  int _step = 0;
  String _documentType = 'NATIONAL_ID';
  String? _devOtp;

  List<LocationItem> _states = [];
  List<LocationItem> _cities = [];
  List<LocationItem> _districts = [];
  List<LocationItem> _areas = [];
  int? _stateId;
  int? _cityId;
  int? _districtId;
  int? _areaId;
  bool _loadingLocations = false;
  final List<_PickedVerificationDocument> _documents = [];

  bool get _isCustomer => _accountType == 'customer';
  bool get _isMerchant => _accountType == 'merchant';
  bool get _isWorkshop => _accountType == 'workshop';
  bool get _isWarehouse => _accountType == 'warehouse';
  bool get _isProvider => _isMerchant || _isWorkshop || _isWarehouse;

  @override
  void initState() {
    super.initState();
    final initial = widget.accountType.toLowerCase();
    if (initial == 'customer' ||
        initial == 'merchant' ||
        initial == 'workshop' ||
        initial == 'warehouse') {
      _accountType = initial;
    }
    _loadStates();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _branchNameController.dispose();
    _businessNameController.dispose();
    _descriptionController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _mapUrlController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _loadStates() async {
    setState(() => _loadingLocations = true);
    try {
      final states = await ref.read(locationsRepositoryProvider).fetchStates();
      if (!mounted) return;
      setState(() => _states = states);
    } finally {
      if (mounted) setState(() => _loadingLocations = false);
    }
  }

  Future<void> _loadCities(int stateId) async {
    setState(() {
      _loadingLocations = true;
      _stateId = stateId;
      _cityId = null;
      _districtId = null;
      _areaId = null;
      _cities = [];
      _districts = [];
      _areas = [];
    });
    try {
      final cities = await ref
          .read(locationsRepositoryProvider)
          .fetchCitiesByState(stateId);
      if (mounted) setState(() => _cities = cities);
    } finally {
      if (mounted) setState(() => _loadingLocations = false);
    }
  }

  Future<void> _loadDistricts(int cityId) async {
    setState(() {
      _cityId = cityId;
      _districtId = null;
      _areaId = null;
      _districts = [];
      _areas = [];
    });
    final districts =
        await ref.read(locationsRepositoryProvider).fetchDistricts(cityId);
    if (mounted) setState(() => _districts = districts);
  }

  Future<void> _loadAreas(int districtId) async {
    setState(() {
      _districtId = districtId;
      _areaId = null;
      _areas = [];
    });
    final areas =
        await ref.read(locationsRepositoryProvider).fetchAreas(districtId);
    if (mounted) setState(() => _areas = areas);
  }

  String? _required(String? value) =>
      (value ?? '').trim().isEmpty ? context.tr('validation.required') : null;

  String? _email(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return context.tr('validation.required');
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
      return context.tr('validation.email');
    }
    return null;
  }

  String? _validateYemeniPhone(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return context.tr('auth.validation.phone_required');
    if (!YemenPhoneValidator.isValid(text)) {
      return context.tr('auth.validation.yemeni_phone_companies');
    }
    return null;
  }

  String? _requiredDropdown<T>(T? value) =>
      value == null ? context.tr('validation.required') : null;

  bool get _hasMapLocation =>
      double.tryParse(_latitudeController.text.trim()) != null &&
      double.tryParse(_longitudeController.text.trim()) != null &&
      _mapUrlController.text.trim().isNotEmpty;

  String? _validateMapLocation(String? value) {
    if (!_isProvider) return null;
    if (!_hasMapLocation) return context.tr('auth.map.location_required');
    return null;
  }

  Future<void> _openMapPicker() async {
    final picked = await Navigator.of(context).push<PickedMapLocation>(
      MaterialPageRoute(
        builder: (_) => MapLocationPickerPage(
          initialLatitude: double.tryParse(_latitudeController.text.trim()),
          initialLongitude: double.tryParse(_longitudeController.text.trim()),
          initialAddress: _addressController.text.trim(),
        ),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _latitudeController.text = picked.latitude.toStringAsFixed(7);
      _longitudeController.text = picked.longitude.toStringAsFixed(7);
      _mapUrlController.text = picked.mapUrl;
      _addressController.text = picked.addressLabel;
    });
  }

  String get _businessLabel {
    if (_isWorkshop) return context.tr('auth.workshop_name');
    if (_isWarehouse) return context.tr('auth.warehouse_name');
    return context.tr('auth.store_name');
  }

  List<String> get _allowedExtensions {
    switch (_documentType) {
      case 'BANK_STATEMENT':
        return const ['pdf'];
      case 'COMMERCIAL_REGISTRATION':
        return const ['jpg', 'jpeg', 'png', 'pdf'];
      default:
        return const ['jpg', 'jpeg', 'png'];
    }
  }

  List<String> get _requiredSides {
    switch (_documentType) {
      case 'NATIONAL_ID':
        return const ['FRONT', 'BACK'];
      case 'PASSPORT':
      case 'BANK_STATEMENT':
      case 'COMMERCIAL_REGISTRATION':
        return const ['MAIN'];
      default:
        return const ['MAIN'];
    }
  }

  String _sideLabel(String side) {
    switch (side) {
      case 'FRONT':
        return context.tr('auth.document.front');
      case 'BACK':
        return context.tr('auth.document.back');
      default:
        return context.tr('auth.document.file');
    }
  }

  String _mimeFromExtension(String extension) {
    final ext = extension.toLowerCase();
    if (ext == 'pdf') return 'application/pdf';
    if (ext == 'png') return 'image/png';
    return 'image/jpeg';
  }

  String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }

  void _showDocumentSnack(String key,
      {Map<String, Object?> params = const {}}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr(key, params: params))),
    );
  }

  Future<void> _pickDocument(String side) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _allowedExtensions,
        allowMultiple: false,
        withData: true,
        lockParentWindow: true,
        dialogTitle: context.tr('auth.document.pick_dialog_title'),
      );
      if (!mounted || result == null || result.files.isEmpty) return;

      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        _showDocumentSnack('auth.document.read_failed');
        return;
      }

      final extension = (file.extension ?? '').toLowerCase();
      if (!_allowedExtensions.contains(extension)) {
        _showDocumentSnack('auth.document.invalid_type');
        return;
      }

      if (bytes.length > _maxVerificationDocumentBytes) {
        _showDocumentSnack(
          'auth.document.file_too_large',
          params: {'max': _formatBytes(_maxVerificationDocumentBytes)},
        );
        return;
      }

      setState(() {
        _documents.removeWhere(
            (item) => item.documentType == _documentType && item.side == side);
        _documents.add(_PickedVerificationDocument(
          documentType: _documentType,
          side: side,
          fileName: file.name,
          mimeType: _mimeFromExtension(extension),
          fileSizeBytes: bytes.length,
          fileContentBase64: base64Encode(bytes),
        ));
      });
    } on MissingPluginException catch (error, stackTrace) {
      debugPrint('[Ghiyarak][FilePicker] Missing plugin: $error\n$stackTrace');
      _showDocumentSnack('auth.document.picker_plugin_missing');
    } on PlatformException catch (error, stackTrace) {
      debugPrint('[Ghiyarak][FilePicker] Platform error: $error\n$stackTrace');
      _showDocumentSnack('auth.document.pick_failed');
    } catch (error, stackTrace) {
      debugPrint(
          '[Ghiyarak][FilePicker] Unexpected error: $error\n$stackTrace');
      _showDocumentSnack('auth.document.pick_failed');
    }
  }

  _PickedVerificationDocument? _documentForSide(String side) {
    for (final doc in _documents) {
      if (doc.documentType == _documentType && doc.side == side) return doc;
    }
    return null;
  }

  bool _documentsComplete() {
    return _requiredSides.every((side) => _documents
        .any((doc) => doc.documentType == _documentType && doc.side == side));
  }

  Future<void> _sendOtp() async {
    if (_accountType.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.tr('auth.select_account_type_required'))));
      return;
    }
    if (!_detailsFormKey.currentState!.validate()) return;
    if (_isProvider && (_cityId == null || _districtId == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('auth.location_required'))));
      return;
    }
    if (_isProvider && !_hasMapLocation) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('auth.map.location_required'))));
      return;
    }
    final phone = YemenPhoneValidator.toE164(_phoneController.text);
    final result = await ref
        .read(authControllerProvider.notifier)
        .requestOtp(phone, purpose: 'REGISTER');
    if (!mounted) return;
    if (result != null) {
      setState(() {
        _devOtp = result.devOtpCode;
        _step = 1;
      });
      return;
    }
    final message = ref.read(authControllerProvider).errorMessage ??
        context.tr('auth.error.otp_failed');
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submitCustomer() async {
    if (!_otpFormKey.currentState!.validate()) return;
    final phone = YemenPhoneValidator.toE164(_phoneController.text);
    final ok = await ref.read(authControllerProvider.notifier).registerCustomer(
          phone: phone,
          code: _otpController.text.trim(),
          displayName: _fullNameController.text.trim(),
          email: _emailController.text.trim(),
        );
    if (!mounted) return;
    if (ok) {
      context.go(RouteNames.customerCenter);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ref.read(authControllerProvider).errorMessage ??
            context.tr('auth.error.otp_verify_failed'))));
  }

  Future<void> _submitBusiness() async {
    if (!_documentsComplete()) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('auth.document.required'))));
      return;
    }
    final latitude = double.tryParse(_latitudeController.text.trim());
    final longitude = double.tryParse(_longitudeController.text.trim());
    final ok = await ref.read(authControllerProvider.notifier).registerBusiness(
          accountType: _isMerchant
              ? 'MERCHANT'
              : _isWorkshop
                  ? 'WORKSHOP'
                  : 'WAREHOUSE',
          phone: YemenPhoneValidator.toE164(_phoneController.text),
          code: _otpController.text.trim(),
          fullName: _fullNameController.text.trim(),
          email: _emailController.text.trim(),
          cityId: _cityId!,
          districtId: _districtId,
          areaId: _areaId,
          branchName: _branchNameController.text.trim(),
          address: _addressController.text.trim(),
          businessName: _businessNameController.text.trim(),
          businessDescription: _descriptionController.text.trim(),
          latitude: latitude,
          longitude: longitude,
          mapUrl: _mapUrlController.text.trim(),
          documents: _documents
              .where((doc) => doc.documentType == _documentType)
              .map((doc) => doc.toJson())
              .toList(),
        );
    if (!mounted) return;
    if (ok) {
      setState(() => _step = 3);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ref.read(authControllerProvider).errorMessage ??
            context.tr('auth.error.registration_failed'))));
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    return AppScaffold(
      title: context.tr('auth.create_account'),
      showBottomNav: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              side: const BorderSide(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _buildCurrentStep(authState),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepScroll({required Key key, required List<Widget> children}) {
    return SingleChildScrollView(
      key: key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }

  Widget _buildCurrentStep(AuthState authState) {
    if (_step == 3) return _successStep();
    if (_step == 2) return _documentsStep(authState);
    if (_step == 1) return _otpStep(authState);
    return _detailsStep(authState);
  }

  Widget _detailsStep(AuthState authState) {
    return Form(
      key: _detailsFormKey,
      child: _stepScroll(
        key: const ValueKey('details'),
        children: [
          Text(context.tr('auth.register.title'),
              style: AppTextStyles.heading2, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.sm),
          Text(context.tr('auth.register.subtitle'),
              style: AppTextStyles.bodySecondary, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xl),
          _AccountTypeDropdown(
              value: _accountType.isEmpty ? null : _accountType,
              onChanged: (value) => setState(() => _accountType = value ?? '')),
          if (_accountType.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            AppTextField(
                controller: _fullNameController,
                label: context.tr('auth.full_name'),
                validator: _required),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _phoneController,
              label: context.tr('auth.phone'),
              hint: context.tr('auth.phone_hint_yemen'),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s-]'))
              ],
              validator: _validateYemeniPhone,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(context.tr('auth.phone.carriers_yemen'),
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
                controller: _emailController,
                label: context.tr('auth.email'),
                keyboardType: TextInputType.emailAddress,
                validator: _email),
            if (_isProvider) ...[
              const SizedBox(height: AppSpacing.lg),
              _locationDropdowns(),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _addressController,
                readOnly: true,
                validator: _validateMapLocation,
                onTap: _openMapPicker,
                decoration: InputDecoration(
                  labelText: context.tr('auth.address'),
                  hintText: context.tr('auth.map.tap_to_select'),
                  suffixIcon: const Icon(Icons.map_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (_hasMapLocation)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.20)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.tr('auth.map.location_saved'),
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      SelectableText(
                          '${_latitudeController.text}, ${_longitudeController.text}'),
                      SelectableText(_mapUrlController.text,
                          style: const TextStyle(color: AppColors.primary)),
                    ],
                  ),
                )
              else
                _notice(context.tr('auth.map.tap_to_select_notice')),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                  controller: _branchNameController,
                  label: context.tr('auth.branch_name'),
                  validator: _required),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                  controller: _businessNameController,
                  label: _businessLabel,
                  validator: _required),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                  controller: _descriptionController,
                  label: context.tr('auth.business_description'),
                  maxLines: 3,
                  validator: _required),
              const SizedBox(height: AppSpacing.md),
              _notice(context.tr('auth.provider_review_notice')),
            ],
            const SizedBox(height: AppSpacing.xl),
            AppButton(
                text: context.tr('auth.send_otp'),
                isLoading: authState.status == AuthStatus.loading,
                onPressed: _sendOtp),
          ],
          const SizedBox(height: AppSpacing.md),
          AppButton(
              text: context.tr('auth.back_to_login'),
              isOutlined: true,
              onPressed: () => context.go(RouteNames.login)),
        ],
      ),
    );
  }

  Widget _locationDropdowns() {
    return Column(
      children: [
        DropdownButtonFormField<int>(
          initialValue: _stateId,
          isExpanded: true,
          decoration:
              InputDecoration(labelText: context.tr('auth.governorate')),
          items: _states
              .map((item) =>
                  DropdownMenuItem(value: item.id, child: Text(item.name)))
              .toList(),
          validator: _requiredDropdown,
          onChanged: _loadingLocations
              ? null
              : (value) {
                  if (value != null) _loadCities(value);
                },
        ),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<int>(
          initialValue: _cityId,
          isExpanded: true,
          decoration: InputDecoration(labelText: context.tr('auth.city')),
          items: _cities
              .map((item) =>
                  DropdownMenuItem(value: item.id, child: Text(item.name)))
              .toList(),
          validator: _requiredDropdown,
          onChanged: _cities.isEmpty
              ? null
              : (value) {
                  if (value != null) _loadDistricts(value);
                },
        ),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<int>(
          initialValue: _districtId,
          isExpanded: true,
          decoration: InputDecoration(labelText: context.tr('auth.district')),
          items: _districts
              .map((item) =>
                  DropdownMenuItem(value: item.id, child: Text(item.name)))
              .toList(),
          validator: _requiredDropdown,
          onChanged: _districts.isEmpty
              ? null
              : (value) {
                  if (value != null) _loadAreas(value);
                },
        ),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<int>(
          initialValue: _areaId,
          isExpanded: true,
          decoration:
              InputDecoration(labelText: context.tr('auth.area_optional')),
          items: _areas
              .map((item) =>
                  DropdownMenuItem(value: item.id, child: Text(item.name)))
              .toList(),
          onChanged: _areas.isEmpty
              ? null
              : (value) => setState(() => _areaId = value),
        ),
      ],
    );
  }

  Widget _otpStep(AuthState authState) {
    return Form(
      key: _otpFormKey,
      child: _stepScroll(
        key: const ValueKey('otp'),
        children: [
          Text(context.tr('auth.otp'),
              style: AppTextStyles.heading2, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.sm),
          Text(
              context.tr('auth.otp.sent_to', params: {
                'phone': YemenPhoneValidator.toE164(_phoneController.text)
              }),
              textAlign: TextAlign.center),
          if ((_devOtp ?? '').isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _notice('${context.tr('auth.dev_otp')}: $_devOtp'),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _otpController,
            label: context.tr('auth.otp'),
            hint: context.tr('auth.otp_hint'),
            keyboardType: TextInputType.number,
            validator: (value) {
              final v = value?.trim() ?? '';
              if (v.isEmpty) return context.tr('auth.validation.otp_required');
              if (v.length < 4) {
                return context.tr('auth.validation.otp_invalid');
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            text: _isCustomer
                ? context.tr('auth.create_customer_account')
                : context.tr('auth.continue_to_documents'),
            isLoading: authState.status == AuthStatus.loading,
            onPressed: _isCustomer
                ? _submitCustomer
                : () {
                    if (_otpFormKey.currentState!.validate()) {
                      setState(() => _step = 2);
                    }
                  },
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
              text: context.tr('common.cancel'),
              isOutlined: true,
              onPressed: () => setState(() => _step = 0)),
        ],
      ),
    );
  }

  Widget _documentsStep(AuthState authState) {
    return _stepScroll(
      key: const ValueKey('documents'),
      children: [
        Text(context.tr('auth.documents.title'),
            style: AppTextStyles.heading2, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.sm),
        Text(context.tr('auth.documents.subtitle'),
            style: AppTextStyles.bodySecondary, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.lg),
        DropdownButtonFormField<String>(
          initialValue: _documentType,
          isExpanded: true,
          decoration:
              InputDecoration(labelText: context.tr('auth.document.choose')),
          items: [
            DropdownMenuItem(
                value: 'NATIONAL_ID',
                child: Text(context.tr('auth.document.national_id'))),
            DropdownMenuItem(
                value: 'PASSPORT',
                child: Text(context.tr('auth.document.passport'))),
            DropdownMenuItem(
                value: 'BANK_STATEMENT',
                child: Text(context.tr('auth.document.bank_statement'))),
            DropdownMenuItem(
                value: 'COMMERCIAL_REGISTRATION',
                child:
                    Text(context.tr('auth.document.commercial_registration'))),
          ],
          onChanged: (value) => setState(() {
            _documentType = value ?? 'NATIONAL_ID';
            _documents.clear();
          }),
        ),
        const SizedBox(height: AppSpacing.lg),
        ..._requiredSides.map((side) {
          final doc = _documentForSide(side);
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(_sideLabel(side),
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                      doc == null
                          ? context.tr('auth.document.not_uploaded')
                          : doc.fileName,
                      overflow: TextOverflow.ellipsis),
                  if (doc != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text('${doc.mimeType} • ${_formatBytes(doc.fileSizeBytes)}',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: SizedBox(
                      width: 150,
                      child: OutlinedButton.icon(
                        onPressed: () => _pickDocument(side),
                        icon: const Icon(Icons.upload_file_outlined, size: 18),
                        label: Text(context.tr('auth.document.upload')),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: AppSpacing.lg),
        _notice(context.tr('auth.document.storage_notice')),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
            text: context.tr('auth.submit_application'),
            isLoading: authState.status == AuthStatus.loading,
            onPressed: _submitBusiness),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
            text: context.tr('common.cancel'),
            isOutlined: true,
            onPressed: () => setState(() => _step = 1)),
      ],
    );
  }

  Widget _successStep() {
    return _stepScroll(
      key: const ValueKey('success'),
      children: [
        const Icon(Icons.check_circle, color: AppColors.success, size: 72),
        const SizedBox(height: AppSpacing.lg),
        Text(context.tr('membership.application_submitted_title'),
            style: AppTextStyles.heading2, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.md),
        Text(context.tr('membership.application_submitted_message'),
            style: AppTextStyles.bodySecondary, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
            text: context.tr('common.confirm'),
            onPressed: () => context.go(RouteNames.providerStatus)),
      ],
    );
  }

  Widget _notice(String text) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Text(text, style: AppTextStyles.bodySecondary),
    );
  }
}

class _AccountTypeDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const _AccountTypeDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: context.tr('auth.account_type')),
      hint: Text(context.tr('auth.choose_account_type')),
      items: [
        DropdownMenuItem(
            value: 'customer', child: Text(context.tr('role.customer'))),
        DropdownMenuItem(
            value: 'merchant', child: Text(context.tr('role.merchant_owner'))),
        DropdownMenuItem(
            value: 'workshop', child: Text(context.tr('role.workshop_owner'))),
        DropdownMenuItem(
            value: 'warehouse',
            child: Text(context.tr('role.warehouse_owner'))),
      ],
      onChanged: onChanged,
    );
  }
}
