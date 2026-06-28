import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/storage/local_storage_service.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/features/marketplace/data/models/product_model.dart';
import 'package:ghiyarak/features/merchant/data/merchant_market_repository.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';

class CreateListingPage extends ConsumerStatefulWidget {
  const CreateListingPage({super.key});

  @override
  ConsumerState<CreateListingPage> createState() => _CreateListingPageState();
}

class _CreateListingPageState extends ConsumerState<CreateListingPage> {
  String? _categoryId;
  String? _productId;

  List<ProductModel> _products = const [];

  bool _loadingProducts = false;
  bool _saving = false;
  bool _supportsInstallation = false;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController(text: '0');
  final _stockController = TextEditingController(text: '0');

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    if (_categoryId == null) return;

    setState(() {
      _loadingProducts = true;
    });

    try {
      final products = await ref
          .read(merchantMarketRepositoryProvider)
          .getProducts(categoryId: _categoryId);

      if (!mounted) return;

      setState(() {
        _products = products;
      });
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingProducts = false;
        });
      }
    }
  }

  Future<void> _save() async {
    if (_productId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('اختر المنتج أولًا'),
        ),
      );
      return;
    }

    final organizationId =
        await ref.read(localStorageServiceProvider).getProviderOrganizationId();

    if (organizationId.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'لا يوجد معرّف مؤسسة محفوظ. أكمل إعداد المؤسسة أولًا.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await ref.read(merchantMarketRepositoryProvider).createListing(
            productId: _productId!,
            organizationId: organizationId,
            title: _optionalText(_titleController),
            description: _optionalText(_descriptionController),
            supportsInstallation: _supportsInstallation,
            price: double.tryParse(_priceController.text.trim()) ?? 0,
            quantity: int.tryParse(_stockController.text.trim()) ?? 0,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إنشاء العرض بنجاح'),
        ),
      );

      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
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

  String? _optionalText(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(_categoriesProvider);

    return AppScaffold(
      title: 'إنشاء عرض جديد',
      child: ListView(
        children: [
          categories.when(
            data: (items) => DropdownButtonFormField<String>(
              initialValue: _categoryId,
              decoration: const InputDecoration(
                labelText: 'التصنيف',
              ),
              items: items
                  .map(
                    (category) => DropdownMenuItem<String>(
                      value: category.id,
                      child: Text(category.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _categoryId = value;
                  _productId = null;
                  _products = const [];
                });

                _loadProducts();
              },
            ),
            loading: () => const LinearProgressIndicator(),
            error: (error, _) {
              return Text(
                'تعذر تحميل التصنيفات: $error',
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          if (_loadingProducts) const LinearProgressIndicator(),
          DropdownButtonFormField<String>(
            initialValue: _productId,
            decoration: const InputDecoration(
              labelText: 'المنتج المرجعي',
            ),
            items: _products
                .map(
                  (product) => DropdownMenuItem<String>(
                    value: product.id,
                    child: Text(
                      product.name.isEmpty ? 'منتج' : product.name,
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _productId = value;
              });
            },
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'عنوان العرض (اختياري)',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'وصف العرض (اختياري)',
            ),
            maxLines: 3,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'السعر',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _stockController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'الكمية',
            ),
          ),
          SwitchListTile(
            value: _supportsInstallation,
            onChanged: (value) {
              setState(() {
                _supportsInstallation = value;
              });
            },
            title: const Text('يدعم التركيب'),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            text: 'إنشاء ونشر العرض',
            isLoading: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}

final _categoriesProvider = FutureProvider(
  (ref) => ref.read(merchantMarketRepositoryProvider).getCategories(),
);
