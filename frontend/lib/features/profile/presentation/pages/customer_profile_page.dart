import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/core/theme/app_colors.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/core/theme/app_text_styles.dart';
import 'package:ghiyarak/features/profile/data/models/customer_profile_model.dart';
import 'package:ghiyarak/features/profile/data/profile_repository.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:go_router/go_router.dart';

final customerProfileProvider =
    FutureProvider.autoDispose<CustomerProfileModel>((ref) async {
  return ref.watch(profileRepositoryProvider).getCustomerProfile();
});

class CustomerProfilePage extends ConsumerStatefulWidget {
  const CustomerProfilePage({super.key});

  @override
  ConsumerState<CustomerProfilePage> createState() =>
      _CustomerProfilePageState();
}

class _CustomerProfilePageState extends ConsumerState<CustomerProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _avatarController = TextEditingController();
  String _locale = 'ar';
  bool _saving = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _avatarController.dispose();
    super.dispose();
  }

  void _fill(CustomerProfileModel profile) {
    if (_initialized) return;
    _initialized = true;
    _nameController.text = profile.displayName;
    _emailController.text = profile.email;
    _avatarController.text = profile.avatarUrl;
    _locale = profile.locale == 'en' ? 'en' : 'ar';
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(customerProfileProvider);

    return AppScaffold(
      title: 'الملف الشخصي',
      child: profileState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _StateCard(
          icon: Icons.error_outline,
          title: 'تعذر تحميل الملف الشخصي',
          message: error.toString(),
          actionText: 'إعادة المحاولة',
          onPressed: () => ref.invalidate(customerProfileProvider),
        ),
        data: (profile) {
          _fill(profile);
          return RefreshIndicator(
            onRefresh: () async {
              _initialized = false;
              ref.invalidate(customerProfileProvider);
            },
            child: Form(
              key: _formKey,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _ProfileHeader(profile: profile),
                  const SizedBox(height: AppSpacing.lg),
                  if (profile.hasDeletionRequest) ...[
                    _DeletionNotice(profile: profile),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  _SectionCard(
                    title: 'بيانات الحساب',
                    subtitle: 'هذه البيانات تظهر في الطلبات والمحادثات والدعم.',
                    children: [
                      TextFormField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'الاسم الكامل',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.length < 3) {
                            return 'اكتب اسمًا لا يقل عن 3 أحرف';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        initialValue: profile.phone,
                        enabled: false,
                        decoration: InputDecoration(
                          labelText: 'رقم الجوال',
                          prefixIcon: const Icon(Icons.phone_android_outlined),
                          suffixIcon: profile.isPhoneVerified
                              ? const Icon(Icons.verified,
                                  color: AppColors.success)
                              : null,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'البريد الإلكتروني',
                          hintText: 'example@email.com',
                          prefixIcon: const Icon(Icons.email_outlined),
                          suffixIcon: profile.isEmailVerified
                              ? const Icon(Icons.verified,
                                  color: AppColors.success)
                              : null,
                        ),
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.isEmpty) return null;
                          final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                              .hasMatch(text);
                          return valid ? null : 'البريد الإلكتروني غير صحيح';
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _avatarController,
                        keyboardType: TextInputType.url,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'رابط الصورة الشخصية',
                          hintText: 'https://...',
                          prefixIcon: Icon(Icons.image_outlined),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      DropdownButtonFormField<String>(
                        initialValue: _locale,
                        decoration: const InputDecoration(
                          labelText: 'لغة الحساب',
                          prefixIcon: Icon(Icons.language),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'ar', child: Text('العربية')),
                          DropdownMenuItem(value: 'en', child: Text('English')),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _locale = value);
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppButton(
                        text: 'حفظ التعديلات',
                        isLoading: _saving,
                        onPressed: _saving ? null : () => _save(profile),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _SectionCard(
                    title: 'جاهزية العميل',
                    subtitle: 'اكتمال هذه العناصر يجعل الشراء والتوصيل أسرع.',
                    children: [
                      _InfoTile(
                        icon: Icons.location_on_outlined,
                        title: 'الموقع الحالي',
                        value: profile.location.label,
                        actionText: 'تحديث',
                        onTap: () => context.go(RouteNames.locationSelection),
                      ),
                      const Divider(height: 1, color: AppColors.border),
                      _InfoTile(
                        icon: Icons.directions_car_outlined,
                        title: 'المركبات',
                        value: profile.vehicles.isEmpty
                            ? 'لم يتم إضافة مركبة'
                            : '${profile.vehicles.length} مركبة • ${profile.vehicles.firstWhere((v) => v.isDefault, orElse: () => profile.vehicles.first).label}',
                        actionText: 'إدارة',
                        onTap: () => context.go(RouteNames.vehicles),
                      ),
                      const Divider(height: 1, color: AppColors.border),
                      _InfoTile(
                        icon: Icons.storefront_outlined,
                        title: 'حسابات التاجر/المزود',
                        value: profile.organizations.isEmpty
                            ? 'لا توجد مؤسسة مرتبطة'
                            : '${profile.organizations.length} مؤسسة مرتبطة',
                        actionText:
                            profile.organizations.isEmpty ? 'إنشاء' : 'عرض',
                        onTap: () => context.go(RouteNames.providerType),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _SectionCard(
                    title: 'الأمان والحساب',
                    subtitle: 'إجراءات مهمة لإدارة الجلسة والحساب.',
                    children: [
                      _InfoTile(
                        icon: Icons.copy_outlined,
                        title: 'معرّف الحساب',
                        value: profile.id.isEmpty ? 'غير متاح' : profile.id,
                        actionText: 'نسخ',
                        onTap: profile.id.isEmpty
                            ? null
                            : () =>
                                _copyText(profile.id, 'تم نسخ معرّف الحساب'),
                      ),
                      const Divider(height: 1, color: AppColors.border),
                      _InfoTile(
                        icon: Icons.settings_outlined,
                        title: 'إعدادات العميل',
                        value: 'اللغة، المظهر، الإشعارات، الخصوصية، والجلسات',
                        actionText: 'فتح',
                        onTap: () => context.go(RouteNames.customerSettings),
                      ),
                      const Divider(height: 1, color: AppColors.border),
                      _InfoTile(
                        icon: Icons.location_on_outlined,
                        title: 'عناوين التوصيل',
                        value: 'إضافة، تعديل، حذف، وتحديد العنوان الافتراضي',
                        actionText: 'إدارة',
                        onTap: () => context.go(RouteNames.customerAddresses),
                      ),
                      const Divider(height: 1, color: AppColors.border),
                      _InfoTile(
                        icon: Icons.logout,
                        title: 'تسجيل الخروج',
                        value:
                            'إنهاء الجلسة الحالية ومسح البيانات المحلية الحساسة',
                        actionText: 'خروج',
                        onTap: _logout,
                      ),
                      const Divider(height: 1, color: AppColors.border),
                      _InfoTile(
                        icon: Icons.delete_outline,
                        title: 'طلب حذف الحساب',
                        value: 'إرسال طلب مراجعة لحذف أو تعطيل الحساب',
                        actionText: 'طلب',
                        isDanger: true,
                        onTap: profile.hasDeletionRequest
                            ? null
                            : _requestDeletion,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _save(CustomerProfileModel profile) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(profileRepositoryProvider).updateCustomerProfile(
            displayName: _nameController.text,
            email: _emailController.text,
            avatarUrl: _avatarController.text,
            locale: _locale,
          );
      _initialized = false;
      ref.invalidate(customerProfileProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ الملف الشخصي بنجاح')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _copyText(String value, String message) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل تريد تسجيل الخروج من حسابك؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(profileRepositoryProvider).logout();
    if (!mounted) return;
    context.go(RouteNames.entry);
  }

  Future<void> _requestDeletion() async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('طلب حذف الحساب'),
        content: TextField(
          controller: reasonController,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'سبب الطلب',
            hintText: 'اكتب سبب حذف أو تعطيل الحساب...',
            alignLabelWithHint: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(reasonController.text),
            child: const Text('إرسال الطلب'),
          ),
        ],
      ),
    );
    reasonController.dispose();
    if (reason == null) return;
    try {
      await ref.read(profileRepositoryProvider).requestAccountDeletion(
            reason: reason,
          );
      ref.invalidate(customerProfileProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال طلب حذف الحساب للمراجعة')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }
}

class _ProfileHeader extends StatelessWidget {
  final CustomerProfileModel profile;

  const _ProfileHeader({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: Colors.white.withValues(alpha: 0.14),
            backgroundImage: profile.avatarUrl.isEmpty
                ? null
                : NetworkImage(profile.avatarUrl),
            child: profile.avatarUrl.isEmpty
                ? Text(
                    profile.displayInitial,
                    style: AppTextStyles.heading1.copyWith(
                      color: AppColors.textOnDark,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.displayName.isEmpty
                      ? 'عميل غيارك'
                      : profile.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.heading2.copyWith(
                    color: AppColors.textOnDark,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${profile.accountStatusLabel} • ${profile.isPhoneVerified ? 'الجوال موثق' : 'الجوال غير موثق'}',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textOnDark.withValues(alpha: 0.78),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  profile.phone.isEmpty ? profile.email : profile.phone,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textOnDark.withValues(alpha: 0.68),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeletionNotice extends StatelessWidget {
  final CustomerProfileModel profile;

  const _DeletionNotice({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.error),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'لديك طلب حذف حساب قيد المراجعة. ${profile.deletionReason.isEmpty ? '' : 'السبب: ${profile.deletionReason}'}',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: _cardDecoration(),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.xs),
            Text(subtitle, style: AppTextStyles.bodySecondary),
            const SizedBox(height: AppSpacing.lg),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String actionText;
  final VoidCallback? onTap;
  final bool isDanger;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.actionText,
    required this.onTap,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDanger ? AppColors.error : AppColors.iconAccent;
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        minLeadingWidth: 0,
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w800,
            color: isDanger ? AppColors.error : AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: TextButton(
          onPressed: onTap,
          child: Text(actionText),
        ),
        onTap: onTap,
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionText;
  final VoidCallback onPressed;

  const _StateCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: _cardDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.iconAccent, size: 48),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.sm),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            AppButton(text: actionText, onPressed: onPressed),
          ],
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: AppColors.border),
    boxShadow: const [
      BoxShadow(
        color: AppColors.shadow,
        blurRadius: 16,
        offset: Offset(0, 8),
      ),
    ],
  );
}
