import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/features/profile/data/profile_repository.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:ghiyarak/shared/widgets/app_text_field.dart';
import 'package:go_router/go_router.dart';

class ProfileBasicsPage extends ConsumerStatefulWidget {
  const ProfileBasicsPage({super.key});

  @override
  ConsumerState<ProfileBasicsPage> createState() => _ProfileBasicsPageState();
}

class _ProfileBasicsPageState extends ConsumerState<ProfileBasicsPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ref
          .read(profileRepositoryProvider)
          .saveProfileName(_nameController.text.trim());
      if (!mounted) return;
      context.go(RouteNames.locationSelection);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'البيانات الأساسية',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            AppTextField(
              controller: _nameController,
              label: 'الاسم الكامل',
              hint: 'أدخل اسمك',
              validator: (value) {
                final v = value?.trim() ?? '';
                if (v.isEmpty) return 'الاسم مطلوب';
                if (v.length < 3) return 'الاسم قصير جدًا';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              text: 'حفظ ومتابعة',
              isLoading: _isLoading,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
