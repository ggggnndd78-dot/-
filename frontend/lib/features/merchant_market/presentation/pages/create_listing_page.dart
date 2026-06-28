import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/core/network/api_exception.dart';
import 'package:ghiyarak/features/marketplace/data/models/catalog_category.dart';
import 'package:ghiyarak/features/merchant_market/data/merchant_market_repository.dart';
import 'package:ghiyarak/features/product_imports/data/product_imports_repository.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_bottom_navigation.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_drawer.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_page_header.dart';
import 'package:ghiyarak/shared/widgets/app_tile_material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class CreateListingPage extends ConsumerStatefulWidget {
  const CreateListingPage({super.key, this.initialCode});

  final String? initialCode;

  @override
  ConsumerState<CreateListingPage> createState() => _CreateListingPageState();
}

class _CreateListingPageState extends ConsumerState<CreateListingPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  final _name = TextEditingController();
  final _subCategory = TextEditingController();
  final _partNumber = TextEditingController();
  final _country = TextEditingController();
  final _description = TextEditingController();
  final _engineCode = TextEditingController();
  final _price = TextEditingController();
  final _salePrice = TextEditingController();
  final _quantity = TextEditingController();
  final _minOrder = TextEditingController(text: '1');

  final List<XFile> _images = [];
  final List<_CompatibilityDraft> _compatibilities = [];

  String? _categoryId;
  String? _brandId;
  String? _branchId;
  String? _makeId;
  String? _modelId;
  int? _yearFrom;
  int? _yearTo;
  int? _warrantyDays;
  String _condition = 'NEW';
  bool _pickup = true;
  bool _delivery = false;
  bool _saving = false;
  bool _lookupLoading = false;
  bool _importLoading = false;
  bool _showCompatibility = false;
  bool _showImages = false;
  String _addMode = 'manual';
  String? _catalogProductId;
  PlatformFile? _importFile;
  Map<String, dynamic>? _importJob;
  List<Map<String, dynamic>> _importRows = const [];

  @override
  void initState() {
    super.initState();
    final code = widget.initialCode?.trim();
    if (code != null && code.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _handleScannedCode(code);
      });
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _subCategory,
      _partNumber,
      _country,
      _description,
      _engineCode,
      _price,
      _salePrice,
      _quantity,
      _minOrder,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImages() async {
    FocusScope.of(context).unfocus();
    try {
      final picked = await _picker.pickMultiImage(
        imageQuality: 85,
        requestFullMetadata: false,
      );
      if (picked.isEmpty || !mounted) return;
      final remaining = 10 - _images.length;
      if (remaining <= 0) {
        _message('يمكن إضافة 10 صور كحد أقصى');
        return;
      }
      final accepted = <XFile>[];
      for (final image in picked.take(remaining)) {
        final name = image.name.toLowerCase();
        final ok = name.endsWith('.png') ||
            name.endsWith('.jpg') ||
            name.endsWith('.jpeg');
        if (!ok || image.path.isEmpty) {
          _message('صيغة الصورة غير مدعومة. اختر PNG أو JPG');
          continue;
        }
        accepted.add(image);
      }
      if (accepted.isNotEmpty) {
        setState(() => _images.addAll(accepted));
      }
      if (picked.length > remaining) {
        _message('يمكن إضافة 10 صور كحد أقصى');
      }
    } on PlatformException catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Image picker failed: ${error.code} ${error.message}');
        debugPrintStack(stackTrace: stackTrace);
      }
      if (!mounted) return;
      _message(
        error.code.toLowerCase().contains('denied')
            ? 'لم يتم منح صلاحية الوصول للصور'
            : 'تعذر فتح معرض الصور',
      );
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Image picker failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      if (mounted) _message('تعذر فتح معرض الصور');
    }
  }

  Future<void> _scanCode() async {
    FocusScope.of(context).unfocus();
    final result = await Navigator.of(context).push<_ScanResult>(
      MaterialPageRoute(builder: (_) => const _BarcodeScannerPage()),
    );
    if (!mounted || result == null) return;
    if (result.manualEntryRequested) {
      await _enterCodeManually();
      return;
    }
    if (result.failed) {
      _message(
          'تعذر قراءة الكود، جرّب تقريب الكاميرا أو أدخل البيانات يدوياً.');
      return;
    }
    final code = result.value?.trim();
    if (code == null || code.isEmpty) return;
    await _handleScannedCode(code, format: result.format);
  }

  Future<void> _enterCodeManually() async {
    FocusScope.of(context).unfocus();
    final controller = TextEditingController(text: _partNumber.text.trim());
    final code = await showDialog<String>(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('إدخال الكود يدوياً'),
            content: TextField(
              controller: controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: _decoration('الكود أو رقم القطعة'),
              onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () =>
                    Navigator.of(context).pop(controller.text.trim()),
                child: const Text('بحث'),
              ),
            ],
          ),
        );
      },
    );
    controller.dispose();
    if (!mounted || code == null || code.trim().isEmpty) return;
    await _handleScannedCode(code.trim());
  }

  Future<void> _handleScannedCode(String code, {BarcodeFormat? format}) async {
    final isUrl = Uri.tryParse(code)?.hasAbsolutePath == true &&
        (code.startsWith('http://') || code.startsWith('https://'));
    if (kDebugMode) {
      debugPrint('Scanned format: ${format?.name ?? 'manual_or_unknown'}');
      debugPrint('Scanned value: $code');
    }
    setState(() => _lookupLoading = true);
    try {
      final decoded = jsonDecode(code);
      if (decoded is Map) {
        _applyStructuredPayload(Map<String, dynamic>.from(decoded));
        if (mounted) {
          setState(() {
            _lookupLoading = false;
            _addMode = 'manual';
          });
        }
        _message('تمت تعبئة بيانات المنتج من الكود.');
        return;
      }
    } catch (_) {
      // Plain barcode/text/URL; continue with backend lookup.
    }

    try {
      final result = await ref
          .read(merchantMarketRepositoryProvider)
          .lookupProductByCode(code);
      if (result == null) {
        _partNumber.text = code;
        _message(isUrl
            ? 'تم قراءة الرابط ككود فقط. لم يتم العثور على المنتج في الكتالوج، أكمل البيانات يدوياً.'
            : 'تم قراءة الكود، لكن لم يتم العثور على المنتج في الكتالوج. أكمل البيانات يدوياً.');
        return;
      }
      _applyLookupResult(result);
      _message(isUrl
          ? 'تم قراءة الرابط ككود فقط وتعبئة بيانات المنتج المتوفرة.'
          : 'تم العثور على المنتج وتعبئة بياناته المتوفرة.');
    } catch (error) {
      _partNumber.text = code;
      if (kDebugMode) {
        debugPrint('Lookup failed with friendly fallback: $error');
      }
      _message('تعذر البحث عن الكود حالياً. أكمل البيانات يدوياً.');
    } finally {
      if (mounted) {
        setState(() {
          _lookupLoading = false;
          _addMode = 'manual';
        });
      }
    }
  }

  void _applyStructuredPayload(Map<String, dynamic> data) {
    final specifications = data['specifications'];
    final specs = specifications is Map
        ? Map<String, dynamic>.from(specifications)
        : const <String, dynamic>{};
    setState(() {
      _catalogProductId = (data['id'] ?? data['productId'] ?? data['product_id'])?.toString() ?? _catalogProductId;
      _name.text =
          (data['nameAr'] ?? data['name_ar'] ?? data['name'] ?? _name.text)
              .toString();
      _categoryId = (data['categoryId'] ?? data['category_id'])?.toString() ??
          _categoryId;
      _brandId = (data['partBrandId'] ??
                  data['part_brand_id'] ??
                  data['manufacturerId'] ??
                  data['manufacturer_id'])
              ?.toString() ??
          _brandId;
      _subCategory.text =
          (data['subCategory'] ?? data['sub_category'] ?? _subCategory.text)
              .toString();
      _partNumber.text = (data['partNumber'] ??
              data['part_number'] ??
              data['oemNumber'] ??
              data['oem_number'] ??
              data['sku'] ??
              _partNumber.text)
          .toString();
      _country.text = (data['countryOfOrigin'] ??
              data['country_of_origin'] ??
              data['country'] ??
              specs['countryOfOrigin'] ??
              specs['country_of_origin'] ??
              specs['country'] ??
              _country.text)
          .toString();
      _description.text = (data['description'] ?? _description.text).toString();
      final compatibilities = data['compatibilities'] ?? data['compatibility'];
      if (compatibilities is List) {
        _compatibilities
          ..clear()
          ..addAll(
            compatibilities.whereType<Map>().map(
                  (item) => _CompatibilityDraft.fromMap(
                    Map<String, dynamic>.from(item),
                  ),
                ),
          );
      }
    });
  }

  void _applyLookupResult(MerchantProductLookupResult result) {
    setState(() {
      _catalogProductId = result.productId ?? _catalogProductId;
      if ((result.nameAr ?? '').isNotEmpty) _name.text = result.nameAr!;
      _categoryId = result.categoryId ?? _categoryId;
      _brandId = result.partBrandId ?? _brandId;
      if ((result.partNumber ?? '').isNotEmpty) {
        _partNumber.text = result.partNumber!;
      }
      if ((result.countryOfOrigin ?? '').isNotEmpty) {
        _country.text = result.countryOfOrigin!;
      }
      _condition = result.condition ?? _condition;
      if ((result.description ?? '').isNotEmpty) {
        _description.text = result.description!;
      }
      if (result.compatibilities.isNotEmpty) {
        _compatibilities
          ..clear()
          ..addAll(result.compatibilities.map(_CompatibilityDraft.fromMap));
      }
    });
  }

  Future<List<String>> _uploadImages() async {
    if (_images.isNotEmpty && kDebugMode) {
      debugPrint(
        'Product images kept pending: the backend has no product-image upload endpoint.',
      );
    }
    return const [];
  }

  void _addCompatibility() {
    if (_makeId == null || _modelId == null || _yearFrom == null) {
      _message('اختر الشركة والموديل وسنة البداية');
      return;
    }
    final makes = ref.read(_vehicleMakesProvider).asData?.value;
    final models = ref.read(_vehicleModelsProvider(_makeId!)).asData?.value;
    setState(() {
      _compatibilities.add(
        _CompatibilityDraft(
          makeId: _makeId!,
          modelId: _modelId!,
          makeName: _nameOf(makes, _makeId),
          modelName: _nameOf(models, _modelId),
          yearFrom: _yearFrom!,
          yearTo: _yearTo,
          engineCode: _engineCode.text.trim(),
        ),
      );
      _engineCode.clear();
    });
  }

  String _nameOf(List<MerchantLookupItem>? items, String? id) {
    if (items == null || id == null) return '';
    for (final item in items) {
      if (item.id == id) return item.name;
    }
    return '';
  }

  Future<void> _submit({required bool publish}) async {
    final branchesState = ref.read(_merchantBranchesProvider);
    final branches =
        branchesState.asData?.value ?? const <MerchantLookupItem>[];
    final selectedBranchId = _branchId != null &&
            _branchId != 'all' &&
            branches.any((branch) => branch.id == _branchId)
        ? _branchId
        : null;
    if (!_formKey.currentState!.validate()) return;
    if (selectedBranchId == null) {
      _message('اختر الفرع قبل حفظ المنتج');
      return;
    }
    setState(() => _saving = true);
    try {
      final imageUrls = await _uploadImages();
      if (kDebugMode) {
        debugPrint('Create product selectedBranchId: $selectedBranchId');
        debugPrint('Create product categoryId: $_categoryId');
        debugPrint('Create product partBrandId: $_brandId');
        debugPrint('Create product condition: $_condition');
        debugPrint('Create product status: ${publish ? 'ACTIVE' : 'DRAFT'}');
        debugPrint(
            'Create product approvalStatus: ${publish ? 'PENDING' : 'APPROVED'}');
        debugPrint('Create product warrantyDays: $_warrantyDays');
        debugPrint(
          'Create product compatibility data: ${_compatibilities.map((item) => item.toJson()).toList()}',
        );
        debugPrint('Create product images count: ${imageUrls.length}');
        debugPrint(
            'Create product save mode: ${publish ? 'publish' : 'draft'}');
      }
      await ref.read(merchantMarketRepositoryProvider).createMerchantProduct(
            nameAr: _name.text.trim(),
            categoryId: _categoryId!,
            partBrandId: _brandId,
            branchId: selectedBranchId,
            partNumber: _partNumber.text.trim(),
            description: _description.text.trim(),
            unitPrice: double.parse(_price.text.trim()),
            salePrice: double.tryParse(_salePrice.text.trim()),
            availableQuantity: int.parse(_quantity.text.trim()),
            warrantyDays: _warrantyDays,
            condition: _condition,
            supportsPickup: _pickup,
            supportsDelivery: _delivery,
            imageUrls: imageUrls,
            compatibilities: _showCompatibility
                ? _compatibilities.map((item) => item.toJson()).toList()
                : const <Map<String, dynamic>>[],
            existingProductId: _catalogProductId,
            publish: publish,
          );
      if (!mounted) return;
      _message(publish ? 'تم إرسال المنتج للنشر' : 'تم حفظ المنتج كمسودة');
      context.go(RouteNames.merchantListings);
    } on ApiException catch (error) {
      if (mounted) _message('تعذر حفظ المنتج: ${error.message}');
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Create product failed: $error');
      }
      if (mounted) _message('تعذر حفظ المنتج. راجع الحقول وحاول مرة أخرى');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickImportFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xlsx', 'xls', 'csv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty || !mounted) return;
    setState(() {
      _importFile = result.files.single;
      _importJob = null;
      _importRows = const [];
    });
  }

  Future<void> _readImportFile() async {
    final branches =
        ref.read(_merchantBranchesProvider).asData?.value ?? const <MerchantLookupItem>[];
    final branchId = _branchId ?? (branches.length == 1 ? branches.first.id : null);
    if (_importFile == null) {
      _message('اختر ملف Excel أولًا');
      return;
    }
    if (branchId == null) {
      _message('اختر الفرع قبل رفع الملف');
      return;
    }
    setState(() => _importLoading = true);
    try {
      final repository = ref.read(productImportsRepositoryProvider);
      final job = await repository.upload(
        branchId: branchId,
        file: _importFile!,
      );
      final jobId = (job['publicId'] ?? job['public_id'] ?? '').toString();
      final rows =
          jobId.isEmpty ? <Map<String, dynamic>>[] : await repository.getRows(jobId);
      if (!mounted) return;
      setState(() {
        _branchId = branchId;
        _importJob = job;
        _importRows = rows;
      });
      _message('تمت قراءة الملف. راجع المعاينة قبل الاستيراد');
    } catch (error) {
      _message('تعذر قراءة ملف Excel: $error');
    } finally {
      if (mounted) setState(() => _importLoading = false);
    }
  }

  Future<void> _confirmImport() async {
    final jobId =
        (_importJob?['publicId'] ?? _importJob?['public_id'] ?? '').toString();
    if (jobId.isEmpty) return;
    setState(() => _importLoading = true);
    try {
      final job =
          await ref.read(productImportsRepositoryProvider).confirm(jobId);
      final imported = job['importedRows'] ?? job['imported_rows'] ?? 0;
      final failed = job['skippedRows'] ?? job['skipped_rows'] ?? 0;
      if (!mounted) return;
      _message('تم استيراد $imported منتج بنجاح، وفشل $failed منتج');
      context.go(RouteNames.merchantListings);
    } catch (error) {
      _message('تعذر إكمال الاستيراد: $error');
    } finally {
      if (mounted) setState(() => _importLoading = false);
    }
  }

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(_categoriesProvider);
    final branches = ref.watch(_merchantBranchesProvider);
    final makes = ref.watch(_vehicleMakesProvider);
    final models = _makeId == null
        ? const AsyncValue<List<MerchantLookupItem>>.data([])
        : ref.watch(_vehicleModelsProvider(_makeId!));
    final notifications =
        ref.watch(_notificationCountProvider).asData?.value ?? 0;
    branches.whenData((items) {
      if (items.length == 1 && _branchId == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _branchId == null) {
            setState(() => _branchId = items.first.id);
          }
        });
      }
    });

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF4F6F8),
        drawer:
            const MerchantDrawer(currentTab: MerchantNavigationTab.products),
        bottomNavigationBar: const MerchantBottomNavigation(
          currentTab: MerchantNavigationTab.products,
          compact: true,
        ),
        body: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverToBoxAdapter(
                  child: MerchantPageHeader(
                    title: 'إضافة منتج جديد',
                    subtitle: 'أضف معلومات المنتج خطوة بخطوة',
                    onMenu: () => _scaffoldKey.currentState?.openDrawer(),
                    notificationCount: notifications,
                    onNotifications: () =>
                        context.go(RouteNames.merchantNotifications),
                    bottom: const _Steps(),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 104),
                  sliver: SliverList.list(
                    children: [
                      _AddModeSelector(
                        selected: _addMode,
                        onChanged: (value) => setState(() => _addMode = value),
                      ),
                      _gap,
                      if (_addMode == 'barcode') ...[
                        _QuickFillCard(
                          loading: _lookupLoading,
                          onScan: _lookupLoading ? null : _scanCode,
                          onManual:
                              _lookupLoading ? null : _enterCodeManually,
                        ),
                        _gap,
                      ],
                      if (_addMode == 'excel') ...[
                        _ExcelImportCard(
                          branches: branches,
                          selectedBranchId: _branchId,
                          file: _importFile,
                          job: _importJob,
                          rows: _importRows,
                          loading: _importLoading,
                          onBranchChanged: (value) =>
                              setState(() => _branchId = value),
                          onPick: _pickImportFile,
                          onRead: _readImportFile,
                          onConfirm: _confirmImport,
                        ),
                        _gap,
                      ],
                      if (_addMode == 'manual') ...[
                        _SectionCard(
                          title: 'بيانات المنتج الأساسية',
                          icon: Icons.description_outlined,
                          child: Column(
                            children: [
                              _Field(
                                label: 'اسم المنتج *',
                                controller: _name,
                                validator: _required,
                              ),
                              _Field(
                                label: 'رقم القطعة / SKU / الباركود',
                                controller: _partNumber,
                              ),
                              _twoColumns(
                                _AsyncDropdown<CatalogCategory>(
                                  label: 'الفئة *',
                                  value: _categoryId,
                                  items: categories,
                                  itemId: (item) => item.id,
                                  itemName: (item) => item.name,
                                  onChanged: (value) =>
                                      setState(() => _categoryId = value),
                                  requiredField: true,
                                ),
                                _AsyncDropdown<MerchantLookupItem>(
                                  label: 'ماركة القطعة (اختياري)',
                                  value: _brandId,
                                  items: ref.watch(_partBrandsProvider),
                                  itemId: (item) => item.id,
                                  itemName: (item) => item.name,
                                  onChanged: (value) =>
                                      setState(() => _brandId = value),
                                  errorMessage: 'تعذر تحميل ماركات القطع',
                                ),
                              ),
                              DropdownButtonFormField<String>(
                                initialValue: _condition,
                                decoration: _decoration('حالة المنتج *'),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'NEW', child: Text('جديد')),
                                  DropdownMenuItem(
                                      value: 'USED', child: Text('مستخدم')),
                                  DropdownMenuItem(
                                    value: 'REFURBISHED',
                                    child: Text('مجدد'),
                                  ),
                                ],
                                onChanged: (value) => setState(
                                    () => _condition = value ?? 'NEW'),
                              ),
                              const SizedBox(height: 12),
                              _Field(
                                label: 'وصف مختصر (اختياري)',
                                controller: _description,
                                minLines: 2,
                                maxLines: 4,
                              ),
                            ],
                          ),
                        ),
                        _gap,
                        _SectionCard(
                          title: 'البيع والمخزون',
                          icon: Icons.inventory_2_outlined,
                          child: Column(
                            children: [
                              _AsyncDropdown<MerchantLookupItem>(
                                label: 'الفرع *',
                                value: _branchId,
                                items: branches,
                                itemId: (item) => item.id,
                                itemName: (item) => item.name,
                                onChanged: (value) =>
                                    setState(() => _branchId = value),
                                requiredField: true,
                                emptyMessage:
                                    'يجب إضافة فرع قبل إضافة المنتجات',
                                errorMessage:
                                    'تعذر تحميل الفروع، أعد المحاولة',
                              ),
                              branches.maybeWhen(
                                data: (items) => items.isEmpty
                                    ? Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 12),
                                        child: OutlinedButton.icon(
                                          onPressed: () => context.push(
                                              RouteNames.createMerchantBranch),
                                          icon: const Icon(Icons.add_business),
                                          label: const Text('إضافة فرع'),
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                                orElse: () => const SizedBox.shrink(),
                              ),
                              _twoColumns(
                                _Field(
                                  label: 'السعر (ر.ي) *',
                                  controller: _price,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  validator: _positive,
                                ),
                                _Field(
                                  label: 'سعر العرض (اختياري)',
                                  controller: _salePrice,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  validator: _optionalDecimal,
                                ),
                              ),
                              _twoColumns(
                                _Field(
                                  label: 'الكمية المتوفرة *',
                                  controller: _quantity,
                                  keyboardType: TextInputType.number,
                                  validator: _integer,
                                ),
                                DropdownButtonFormField<int?>(
                                  initialValue: _warrantyDays,
                                  decoration: _decoration('الضمان (اختياري)'),
                                  items: const [
                                    DropdownMenuItem(
                                        value: null, child: Text('بدون ضمان')),
                                    DropdownMenuItem(
                                        value: 30, child: Text('شهر')),
                                    DropdownMenuItem(
                                        value: 90, child: Text('3 أشهر')),
                                    DropdownMenuItem(
                                        value: 365, child: Text('سنة')),
                                  ],
                                  onChanged: (value) =>
                                      setState(() => _warrantyDays = value),
                                ),
                              ),
                              _SwitchTile(
                                title: 'يدعم الاستلام من الفرع',
                                value: _pickup,
                                onChanged: (value) =>
                                    setState(() => _pickup = value),
                                icon: Icons.storefront_outlined,
                              ),
                              _SwitchTile(
                                title: 'يدعم التوصيل',
                                value: _delivery,
                                onChanged: (value) =>
                                    setState(() => _delivery = value),
                                icon: Icons.local_shipping_outlined,
                              ),
                            ],
                          ),
                        ),
                        _gap,
                        _SectionCard(
                          title: 'التوافق مع السيارات (اختياري)',
                          icon: Icons.directions_car_outlined,
                          child: _showCompatibility
                              ? _CompatibilitySection(
                                  makes: makes,
                                  models: models,
                                  makeId: _makeId,
                                  modelId: _modelId,
                                  yearFrom: _yearFrom,
                                  yearTo: _yearTo,
                                  engineCode: _engineCode,
                                  items: _compatibilities,
                                  onMakeChanged: (value) => setState(() {
                                    _makeId = value;
                                    _modelId = null;
                                  }),
                                  onModelChanged: (value) =>
                                      setState(() => _modelId = value),
                                  onYearFromChanged: (value) =>
                                      setState(() => _yearFrom = value),
                                  onYearToChanged: (value) =>
                                      setState(() => _yearTo = value),
                                  onAdd: _addCompatibility,
                                  onRemove: (index) => setState(() =>
                                      _compatibilities.removeAt(index)),
                                )
                              : OutlinedButton.icon(
                                  onPressed: () => setState(
                                      () => _showCompatibility = true),
                                  icon: const Icon(Icons.add_rounded),
                                  label: const Text('إضافة توافق مع سيارة'),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(52),
                                  ),
                                ),
                        ),
                        _gap,
                        _SectionCard(
                          title: 'صور المنتج (اختياري)',
                          icon: Icons.image_outlined,
                          child: _showImages
                              ? _ImagesPicker(
                                  images: _images,
                                  onAdd: _saving ? null : _pickImages,
                                  onRemove: _saving
                                      ? null
                                      : (index) => setState(
                                          () => _images.removeAt(index)),
                                )
                              : OutlinedButton.icon(
                                  onPressed: () =>
                                      setState(() => _showImages = true),
                                  icon: const Icon(Icons.add_photo_alternate),
                                  label: const Text('إضافة صور المنتج'),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(52),
                                  ),
                                ),
                        ),
                        _gap,
                        _SubmitActions(
                          saving: _saving,
                          onDraft: () => _submit(publish: false),
                          onPublish: () => _submit(publish: true),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

const _gap = SizedBox(height: 14);

Widget _twoColumns(Widget first, Widget second) {
  return LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < 520) {
        return Column(children: [first, const SizedBox(height: 12), second]);
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: first),
          const SizedBox(width: 12),
          Expanded(child: second),
        ],
      );
    },
  );
}

String? _required(String? value) =>
    (value ?? '').trim().isEmpty ? 'هذا الحقل مطلوب' : null;

String? _positive(String? value) {
  final number = double.tryParse((value ?? '').trim());
  return number == null || number <= 0 ? 'أدخل قيمة صحيحة' : null;
}

String? _optionalDecimal(String? value) {
  final text = (value ?? '').trim();
  if (text.isEmpty) return null;
  final number = double.tryParse(text);
  return number == null || number < 0 ? 'أدخل قيمة صحيحة' : null;
}

String? _integer(String? value) {
  final number = int.tryParse((value ?? '').trim());
  return number == null || number < 0 ? 'أدخل رقماً صحيحاً' : null;
}

final _categoriesProvider = FutureProvider<List<CatalogCategory>>(
  (ref) => ref.read(merchantMarketRepositoryProvider).getCategories(),
);

final _partBrandsProvider = FutureProvider<List<MerchantLookupItem>>(
  (ref) => ref.read(merchantMarketRepositoryProvider).getPartBrands(),
);

final _merchantBranchesProvider = FutureProvider<List<MerchantLookupItem>>(
  (ref) => ref.read(merchantMarketRepositoryProvider).getMerchantBranches(),
);

final _vehicleMakesProvider = FutureProvider<List<MerchantLookupItem>>(
  (ref) => ref.read(merchantMarketRepositoryProvider).getVehicleMakes(),
);

final _vehicleModelsProvider =
    FutureProvider.family<List<MerchantLookupItem>, String>(
  (ref, makeId) =>
      ref.read(merchantMarketRepositoryProvider).getVehicleModels(makeId),
);

final _notificationCountProvider = FutureProvider<int>(
  (ref) async => (await ref
          .read(merchantMarketRepositoryProvider)
          .getMerchantNotifications())
      .unreadCount,
);


class _AddModeSelector extends StatelessWidget {
  const _AddModeSelector({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const items = [
      ('manual', 'إضافة يدوية', Icons.edit_note_rounded),
      ('barcode', 'مسح باركود', Icons.qr_code_scanner_rounded),
      ('excel', 'استيراد Excel', Icons.table_view_rounded),
    ];
    return _SectionCard(
      title: 'طريقة الإضافة',
      icon: Icons.add_box_outlined,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 560;
          final children = items.map((item) {
            final active = selected == item.$1;
            return InkWell(
              onTap: () => onChanged(item.$1),
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                decoration: BoxDecoration(
                  color: active ? const Color(0xFFEAF2FF) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: active
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFE0E6EC),
                    width: active ? 1.4 : 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item.$3,
                      color: active
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF52667B),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        item.$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: active
                              ? const Color(0xFF0B2E55)
                              : const Color(0xFF52667B),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList();
          if (narrow) {
            return Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i != children.length - 1) const SizedBox(height: 10),
                ],
              ],
            );
          }
          return Row(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                Expanded(child: children[i]),
                if (i != children.length - 1) const SizedBox(width: 10),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SubmitActions extends StatelessWidget {
  const _SubmitActions({
    required this.saving,
    required this.onDraft,
    required this.onPublish,
  });

  final bool saving;
  final VoidCallback onDraft;
  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final draft = OutlinedButton.icon(
          onPressed: saving ? null : onDraft,
          icon: const Icon(Icons.save_outlined),
          label: const Text('حفظ كمسودة'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
            foregroundColor: const Color(0xFF092F55),
            backgroundColor: Colors.white,
          ),
        );
        final publish = FilledButton.icon(
          onPressed: saving ? null : onPublish,
          icon: saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.send_rounded),
          label: const Text('إرسال للنشر'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFFF6500),
            minimumSize: const Size.fromHeight(54),
          ),
        );
        if (constraints.maxWidth < 560) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [publish, const SizedBox(height: 10), draft],
          );
        }
        return Row(
          children: [
            Expanded(child: draft),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: publish),
          ],
        );
      },
    );
  }
}

class _ExcelImportCard extends StatelessWidget {
  const _ExcelImportCard({
    required this.branches,
    required this.selectedBranchId,
    required this.file,
    required this.job,
    required this.rows,
    required this.loading,
    required this.onBranchChanged,
    required this.onPick,
    required this.onRead,
    required this.onConfirm,
  });

  final AsyncValue<List<MerchantLookupItem>> branches;
  final String? selectedBranchId;
  final PlatformFile? file;
  final Map<String, dynamic>? job;
  final List<Map<String, dynamic>> rows;
  final bool loading;
  final ValueChanged<String?> onBranchChanged;
  final VoidCallback onPick;
  final VoidCallback onRead;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final valid = job?['validRows'] ?? job?['valid_rows'] ?? 0;
    final invalid = job?['invalidRows'] ?? job?['invalid_rows'] ?? 0;
    return _SectionCard(
      title: 'استيراد من Excel',
      icon: Icons.table_view_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'ارفع ملف XLSX أو XLS أو CSV. ستظهر معاينة الصفوف والأخطاء قبل الاستيراد.',
            style: TextStyle(color: Color(0xFF66778B)),
          ),
          const SizedBox(height: 14),
          _AsyncDropdown<MerchantLookupItem>(
            label: 'الفرع *',
            value: selectedBranchId,
            items: branches,
            itemId: (item) => item.id,
            itemName: (item) => item.name,
            onChanged: onBranchChanged,
            requiredField: true,
            emptyMessage: 'يجب إضافة فرع قبل إضافة المنتجات',
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: loading ? null : onPick,
            icon: const Icon(Icons.upload_file_outlined),
            label: Text(file == null ? 'رفع ملف Excel' : file!.name),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: loading || file == null ? null : onRead,
            icon: loading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.preview_outlined),
            label: const Text('قراءة الملف وعرض المعاينة'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF092F55),
              minimumSize: const Size.fromHeight(50),
            ),
          ),
          if (job != null) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                Text(
                  'جاهز للاستيراد: $valid',
                  style: const TextStyle(
                    color: Color(0xFF087F5B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'به أخطاء: $invalid',
                  style: const TextStyle(
                    color: Color(0xFFC92A2A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 330),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFDCE5EE)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: rows.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('لا توجد صفوف للمعاينة'),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('#')),
                            DataColumn(label: Text('اسم المنتج')),
                            DataColumn(label: Text('SKU')),
                            DataColumn(label: Text('الفئة')),
                            DataColumn(label: Text('الحالة')),
                            DataColumn(label: Text('السعر')),
                            DataColumn(label: Text('الكمية')),
                            DataColumn(label: Text('الفرع')),
                            DataColumn(label: Text('التحقق')),
                          ],
                          rows: rows.map((row) {
                            final source = row['normalizedData'] is Map
                                ? Map<String, dynamic>.from(
                                    row['normalizedData'] as Map)
                                : row['rawData'] is Map
                                    ? Map<String, dynamic>.from(
                                        row['rawData'] as Map)
                                    : <String, dynamic>{};
                            String cell(String key) =>
                                (source[key] ?? '').toString();
                            final isValid = row['status'] == 'VALID';
                            return DataRow(cells: [
                              DataCell(Text('${row['rowNumber'] ?? ''}')),
                              DataCell(Text(cell('product_name'))),
                              DataCell(Text(cell('part_number'))),
                              DataCell(Text(cell('category'))),
                              DataCell(Text(cell('condition_type'))),
                              DataCell(Text(cell('price_yer'))),
                              DataCell(Text(cell('stock_quantity'))),
                              DataCell(Text(cell('branch'))),
                              DataCell(Tooltip(
                                message:
                                    (row['errorSummary'] ?? '').toString(),
                                child: Icon(
                                  isValid
                                      ? Icons.check_circle
                                      : Icons.error_outline,
                                  color: isValid
                                      ? const Color(0xFF087F5B)
                                      : const Color(0xFFC92A2A),
                                ),
                              )),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: loading || valid == 0 ? null : onConfirm,
              icon: const Icon(Icons.playlist_add_check_circle_outlined),
              label: const Text('استيراد المنتجات'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF6500),
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CompatibilityDraft {
  const _CompatibilityDraft({
    required this.makeId,
    required this.modelId,
    required this.makeName,
    required this.modelName,
    required this.yearFrom,
    this.yearTo,
    this.engineCode,
  });

  final String makeId;
  final String modelId;
  final String makeName;
  final String modelName;
  final int yearFrom;
  final int? yearTo;
  final String? engineCode;

  factory _CompatibilityDraft.fromMap(Map<String, dynamic> map) {
    return _CompatibilityDraft(
      makeId: (map['makeId'] ?? map['make_id'] ?? '').toString(),
      modelId: (map['modelId'] ?? map['model_id'] ?? '').toString(),
      makeName: (map['makeName'] ?? map['make_name'] ?? '').toString(),
      modelName: (map['modelName'] ?? map['model_name'] ?? '').toString(),
      yearFrom: int.tryParse(
              (map['yearFrom'] ?? map['year_from'] ?? '').toString()) ??
          DateTime.now().year,
      yearTo: int.tryParse((map['yearTo'] ?? map['year_to'] ?? '').toString()),
      engineCode:
          map['engineCode']?.toString() ?? map['engine_code']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'makeId': int.parse(makeId),
        'modelId': int.parse(modelId),
        'yearFrom': yearFrom,
        if (yearTo != null) 'yearTo': yearTo,
        if ((engineCode ?? '').isNotEmpty) 'engineCode': engineCode,
      };
}

class _Steps extends StatelessWidget {
  const _Steps();

  @override
  Widget build(BuildContext context) {
    const steps = [
      ('1', 'طريقة الإضافة'),
      ('2', 'البيانات'),
      ('3', 'البيع'),
      ('4', 'اختياري'),
    ];
    return Row(
      children: List.generate(steps.length, (index) {
        final active = index == 0;
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  if (index > 0)
                    const Expanded(child: Divider(color: Colors.white54)),
                  CircleAvatar(
                    radius: 18,
                    backgroundColor:
                        active ? const Color(0xFFFF6500) : Colors.white,
                    child: Text(
                      steps[index].$1,
                      style: TextStyle(
                        color: active ? Colors.white : const Color(0xFF173550),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (index < steps.length - 1)
                    const Expanded(child: Divider(color: Colors.white54)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                steps[index].$2,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E6EC)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12051E35),
            blurRadius: 16,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF092F55)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF092F55),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _QuickFillCard extends StatelessWidget {
  const _QuickFillCard({
    required this.loading,
    required this.onScan,
    required this.onManual,
  });

  final bool loading;
  final VoidCallback? onScan;
  final VoidCallback? onManual;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'تعبئة سريعة',
      icon: Icons.bolt_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: onScan,
            icon: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.qr_code_scanner_rounded),
            label: Text(loading ? 'جاري البحث...' : 'مسح QR / Barcode'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF06213D),
              minimumSize: const Size.fromHeight(54),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onManual,
            icon: const Icon(Icons.keyboard_alt_outlined),
            label: const Text('إدخال الكود يدوياً'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              foregroundColor: const Color(0xFF092F55),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'امسح الكود لتعبئة البيانات إن كانت متوفرة، أو أدخل المنتج يدوياً.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF66788B), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ImagesPicker extends StatelessWidget {
  const _ImagesPicker({
    required this.images,
    required this.onAdd,
    required this.onRemove,
  });

  final List<XFile> images;
  final VoidCallback? onAdd;
  final ValueChanged<int>? onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            InkWell(
              onTap: onAdd,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 132,
                height: 132,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF9AAFC3),
                    style: BorderStyle.solid,
                  ),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined,
                        size: 42, color: Color(0xFF71839A)),
                    SizedBox(height: 8),
                    Text('إضافة صور',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                    SizedBox(height: 3),
                    Text(
                      'PNG أو JPG حتى 10 صور',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF7B8998), fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
            for (var i = 0; i < images.length; i++)
              _ImagePreview(
                file: images[i],
                onRemove: onRemove == null ? null : () => onRemove!(i),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          images.isEmpty
              ? 'نوصي برفع صور واضحة من جميع الزوايا على خلفية بيضاء'
              : 'تم اختيار ${images.length} من 10 صور',
          style: const TextStyle(color: Color(0xFF77869A), fontSize: 12),
        ),
      ],
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.file, required this.onRemove});

  final XFile file;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      height: 88,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(File(file.path), fit: BoxFit.cover),
            ),
          ),
          Positioned(
            top: -7,
            left: -7,
            child: InkWell(
              onTap: onRemove,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFD4DEE8)),
                ),
                child: const Icon(Icons.close_rounded,
                    size: 16, color: Color(0xFF092F55)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompatibilitySection extends StatelessWidget {
  const _CompatibilitySection({
    required this.makes,
    required this.models,
    required this.makeId,
    required this.modelId,
    required this.yearFrom,
    required this.yearTo,
    required this.engineCode,
    required this.items,
    required this.onMakeChanged,
    required this.onModelChanged,
    required this.onYearFromChanged,
    required this.onYearToChanged,
    required this.onAdd,
    required this.onRemove,
  });

  final AsyncValue<List<MerchantLookupItem>> makes;
  final AsyncValue<List<MerchantLookupItem>> models;
  final String? makeId;
  final String? modelId;
  final int? yearFrom;
  final int? yearTo;
  final TextEditingController engineCode;
  final List<_CompatibilityDraft> items;
  final ValueChanged<String?> onMakeChanged;
  final ValueChanged<String?> onModelChanged;
  final ValueChanged<int?> onYearFromChanged;
  final ValueChanged<int?> onYearToChanged;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _twoColumns(
          _AsyncDropdown<MerchantLookupItem>(
            label: 'الشركة *',
            value: makeId,
            items: makes,
            itemId: (item) => item.id,
            itemName: (item) => item.name,
            onChanged: onMakeChanged,
          ),
          _AsyncDropdown<MerchantLookupItem>(
            label: 'الموديل *',
            value: modelId,
            items: models,
            itemId: (item) => item.id,
            itemName: (item) => item.name,
            onChanged: onModelChanged,
          ),
        ),
        _twoColumns(
          DropdownButtonFormField<int>(
            initialValue: yearFrom,
            decoration: _decoration('من سنة'),
            items: _yearItems(),
            onChanged: onYearFromChanged,
          ),
          DropdownButtonFormField<int>(
            initialValue: yearTo,
            decoration: _decoration('إلى سنة'),
            items: _yearItems(),
            onChanged: onYearToChanged,
          ),
        ),
        _twoColumns(
          _Field(label: 'كود المحرك اختياري', controller: engineCode),
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('إضافة سيارة متوافقة'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              foregroundColor: const Color(0xFF092F55),
            ),
          ),
        ),
        if (items.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(items.length, (index) {
              final item = items[index];
              return Chip(
                label: Text(
                  '${item.makeName} ${item.modelName} ${item.yearFrom}-${item.yearTo ?? ''}',
                ),
                deleteIcon: const Icon(Icons.close_rounded, size: 18),
                onDeleted: () => onRemove(index),
              );
            }),
          ),
        ],
      ],
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.title,
    required this.value,
    required this.onChanged,
    required this.icon,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppTileMaterial(
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: value,
        onChanged: onChanged,
        activeThumbColor: const Color(0xFFFF6500),
        secondary: Icon(icon, color: const Color(0xFF71839A)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.validator,
    this.minLines,
    this.maxLines,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int? minLines;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        minLines: minLines,
        maxLines: maxLines ?? 1,
        decoration: _decoration(label),
      ),
    );
  }
}

class _AsyncDropdown<T> extends StatelessWidget {
  const _AsyncDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.itemId,
    required this.itemName,
    required this.onChanged,
    this.requiredField = false,
    this.emptyMessage,
    this.errorMessage,
  });

  final String label;
  final String? value;
  final AsyncValue<List<T>> items;
  final String Function(T item) itemId;
  final String Function(T item) itemName;
  final ValueChanged<String?> onChanged;
  final bool requiredField;
  final String? emptyMessage;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: items.when(
        loading: () => const LinearProgressIndicator(minHeight: 2),
        error: (_, __) => Text(
          errorMessage ?? 'تعذر تحميل $label',
          style: const TextStyle(color: Color(0xFFC62828)),
        ),
        data: (data) {
          if (data.isEmpty && emptyMessage != null) {
            return Text(
              emptyMessage!,
              style: const TextStyle(color: Color(0xFFC62828)),
            );
          }
          return DropdownButtonFormField<String>(
            initialValue: value,
            isExpanded: true,
            decoration: _decoration(label),
            items: data
                .map(
                  (item) => DropdownMenuItem(
                    value: itemId(item),
                    child: Text(
                      itemName(item),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: onChanged,
            validator: requiredField
                ? (value) => value == null ? 'هذا الحقل مطلوب' : null
                : null,
          );
        },
      ),
    );
  }
}

class _ScanResult {
  const _ScanResult.scanned(this.value, this.format)
      : failed = false,
        manualEntryRequested = false;

  const _ScanResult.failed()
      : value = null,
        format = null,
        failed = true,
        manualEntryRequested = false;

  const _ScanResult.manualEntry()
      : value = null,
        format = null,
        failed = false,
        manualEntryRequested = true;

  final String? value;
  final BarcodeFormat? format;
  final bool failed;
  final bool manualEntryRequested;
}

const _supportedBarcodeFormats = <BarcodeFormat>[
  BarcodeFormat.qrCode,
  BarcodeFormat.ean13,
  BarcodeFormat.ean8,
  BarcodeFormat.upcA,
  BarcodeFormat.upcE,
  BarcodeFormat.code128,
  BarcodeFormat.code39,
  BarcodeFormat.code93,
  BarcodeFormat.itf,
  BarcodeFormat.codabar,
  BarcodeFormat.dataMatrix,
  BarcodeFormat.pdf417,
  BarcodeFormat.aztec,
];

class _BarcodeScannerPage extends StatefulWidget {
  const _BarcodeScannerPage();

  @override
  State<_BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<_BarcodeScannerPage> {
  late final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    formats: _supportedBarcodeFormats,
  );
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _completeScan(String value, BarcodeFormat format) {
    if (_handled) return;
    _handled = true;
    Navigator.of(context).pop(_ScanResult.scanned(value, format));
  }

  Widget _buildError(
    BuildContext context,
    MobileScannerException error,
    Widget? child,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography_outlined,
                color: Colors.white, size: 46),
            const SizedBox(height: 14),
            const Text(
              "تعذر قراءة الكود، جرّب تقريب الكاميرا أو أدخل البيانات يدوياً.",
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () =>
                  Navigator.of(context).pop(const _ScanResult.manualEntry()),
              icon: const Icon(Icons.keyboard_alt_outlined),
              label: const Text("إدخال الكود يدوياً"),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(const _ScanResult.failed()),
              child: const Text("إغلاق", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: const Color(0xFF06213D),
          foregroundColor: Colors.white,
          title: const Text("مسح QR / Barcode"),
          actions: [
            ValueListenableBuilder(
              valueListenable: _controller,
              builder: (context, state, _) {
                final torchState = state.torchState;
                final enabled = torchState != TorchState.unavailable;
                return IconButton(
                  tooltip: "تشغيل الفلاش",
                  onPressed: enabled ? _controller.toggleTorch : null,
                  icon: Icon(
                    torchState == TorchState.on
                        ? Icons.flash_on_rounded
                        : Icons.flash_off_rounded,
                  ),
                );
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            MobileScanner(
              controller: _controller,
              errorBuilder: _buildError,
              onDetect: (capture) {
                if (_handled) return;
                for (final barcode in capture.barcodes) {
                  final raw = barcode.rawValue?.trim();
                  if (raw != null && raw.isNotEmpty) {
                    _completeScan(raw, barcode.format);
                    return;
                  }
                }
              },
            ),
            Center(
              child: Container(
                width: 300,
                height: 190,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 3),
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 32,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "وجّه الكاميرا نحو QR أو الباركود داخل الإطار",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context)
                        .pop(const _ScanResult.manualEntry()),
                    icon: const Icon(Icons.keyboard_alt_outlined),
                    label: const Text("إدخال الكود يدوياً"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration _decoration(String label) => InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: Color(0xFFD8E0E8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: Color(0xFF092F55)),
      ),
    );

List<DropdownMenuItem<int>> _yearItems() {
  final current = DateTime.now().year + 1;
  return [
    for (var year = current; year >= 1980; year--)
      DropdownMenuItem(value: year, child: Text(year.toString())),
  ];
}
