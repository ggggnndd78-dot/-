import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/theme/app_colors.dart';
import 'package:ghiyarak/features/profile/data/models/customer_settings_model.dart';
import 'package:ghiyarak/features/profile/data/profile_repository.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';

final customerSettingsProvider =
    FutureProvider.autoDispose<CustomerSettingsModel>((ref) async {
  return ref.watch(profileRepositoryProvider).getCustomerSettings();
});

class CustomerSettingsPage extends ConsumerStatefulWidget {
  const CustomerSettingsPage({super.key});

  @override
  ConsumerState<CustomerSettingsPage> createState() =>
      _CustomerSettingsPageState();
}

class _CustomerSettingsPageState extends ConsumerState<CustomerSettingsPage> {
  CustomerSettingsModel? _draft;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerSettingsProvider);
    return AppScaffold(
      title: 'إعدادات العميل',
      child: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _StateCard(
          icon: Icons.error_outline,
          title: 'تعذر تحميل الإعدادات',
          message: e.toString(),
          action: () => ref.invalidate(customerSettingsProvider),
        ),
        data: (settings) {
          _draft ??= settings;
          final draft = _draft!;
          return RefreshIndicator(
            onRefresh: () async {
              _draft = null;
              ref.invalidate(customerSettingsProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _Header(settings: draft),
                const SizedBox(height: 14),
                _SectionCard(
                  title: 'اللغة والمظهر',
                  icon: Icons.palette_outlined,
                  children: [
                    _ChoiceTile<String>(
                      label: 'اللغة',
                      value: draft.locale,
                      items: const {'ar': 'العربية', 'en': 'English'},
                      onChanged: (v) => _set(draft.copyWith(locale: v)),
                    ),
                    _ChoiceTile<String>(
                      label: 'المظهر',
                      value: draft.themeMode,
                      items: const {
                        'system': 'حسب النظام',
                        'light': 'فاتح',
                        'dark': 'داكن',
                      },
                      onChanged: (v) => _set(draft.copyWith(themeMode: v)),
                    ),
                  ],
                ),
                _SectionCard(
                  title: 'الإشعارات',
                  icon: Icons.notifications_active_outlined,
                  children: [
                    _SwitchRow('إشعارات التطبيق Push', draft.pushEnabled,
                        (v) => _set(draft.copyWith(pushEnabled: v))),
                    _SwitchRow('البريد الإلكتروني', draft.emailEnabled,
                        (v) => _set(draft.copyWith(emailEnabled: v))),
                    _SwitchRow('الرسائل النصية SMS', draft.smsEnabled,
                        (v) => _set(draft.copyWith(smsEnabled: v))),
                    const Divider(),
                    _SwitchRow('تحديثات الطلبات', draft.orderUpdates,
                        (v) => _set(draft.copyWith(orderUpdates: v))),
                    _SwitchRow('رسائل المحادثات', draft.chatMessages,
                        (v) => _set(draft.copyWith(chatMessages: v))),
                    _SwitchRow('العروض والخصومات', draft.promotions,
                        (v) => _set(draft.copyWith(promotions: v))),
                    _SwitchRow('المحفظة والمدفوعات', draft.walletUpdates,
                        (v) => _set(draft.copyWith(walletUpdates: v))),
                    _SwitchRow('المرتجعات والنزاعات', draft.returnsDisputes,
                        (v) => _set(draft.copyWith(returnsDisputes: v))),
                  ],
                ),
                _SectionCard(
                  title: 'الخصوصية',
                  icon: Icons.privacy_tip_outlined,
                  children: [
                    _ChoiceTile<String>(
                      label: 'مستوى الخصوصية',
                      value: draft.privacyLevel,
                      items: const {
                        'strict': 'عالي',
                        'balanced': 'متوازن',
                        'open': 'مرن',
                      },
                      onChanged: (v) => _set(draft.copyWith(privacyLevel: v)),
                    ),
                    _SwitchRow(
                        'إظهار رقمي للتاجر بعد الطلب',
                        draft.showPhoneToMerchants,
                        (v) => _set(draft.copyWith(showPhoneToMerchants: v))),
                    _SwitchRow(
                        'السماح بعروض مخصصة حسب نشاطي',
                        draft.allowPersonalizedOffers,
                        (v) =>
                            _set(draft.copyWith(allowPersonalizedOffers: v))),
                  ],
                ),
                _SectionCard(
                  title: 'الأمان والجلسات',
                  icon: Icons.security_outlined,
                  children: [
                    _SwitchRow(
                        'طلب تأكيد إضافي عند تسجيل الدخول',
                        draft.requireLoginConfirmation,
                        (v) =>
                            _set(draft.copyWith(requireLoginConfirmation: v))),
                    const SizedBox(height: 8),
                    ...draft.sessions.map((s) => _SessionTile(
                          session: s,
                          onRevoke:
                              s.isActive ? () => _revokeSession(s.id) : null,
                        )),
                    if (draft.sessions.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('لا توجد جلسات مسجلة حاليًا.'),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                AppButton(
                  text: _saving ? 'جاري الحفظ...' : 'حفظ الإعدادات',
                  isLoading: _saving,
                  onPressed: _saving ? null : _save,
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  void _set(CustomerSettingsModel settings) =>
      setState(() => _draft = settings);

  Future<void> _save() async {
    if (_draft == null) return;
    setState(() => _saving = true);
    try {
      final saved = await ref
          .read(profileRepositoryProvider)
          .updateCustomerSettings(_draft!);
      if (!mounted) return;
      setState(() => _draft = saved);
      ref.invalidate(customerSettingsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ الإعدادات بنجاح')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _revokeSession(String id) async {
    try {
      await ref.read(profileRepositoryProvider).revokeCustomerSession(id);
      _draft = null;
      ref.invalidate(customerSettingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إنهاء الجلسة')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
}

class _Header extends StatelessWidget {
  final CustomerSettingsModel settings;
  const _Header({required this.settings});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.tune_outlined, size: 34, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('تحكم كامل بتجربتك',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                    'آخر تحديث: ${settings.updatedAt == null ? 'غير محدد' : _date(settings.updatedAt!)}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _SectionCard(
      {required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16))
            ]),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchRow(this.label, this.value, this.onChanged);

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _ChoiceTile<T> extends StatelessWidget {
  final String label;
  final T value;
  final Map<T, String> items;
  final ValueChanged<T> onChanged;
  const _ChoiceTile(
      {required this.label,
      required this.value,
      required this.items,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
          DropdownButton<T>(
            value: value,
            items: items.entries
                .map((e) =>
                    DropdownMenuItem<T>(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final CustomerSessionModel session;
  final VoidCallback? onRevoke;
  const _SessionTile({required this.session, this.onRevoke});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
          session.isActive ? Icons.devices_outlined : Icons.block_outlined),
      title: Text(session.deviceName),
      subtitle: Text(
          '${session.platform} • ${session.ipAddress}\n${session.createdAt == null ? '' : _date(session.createdAt!)}'),
      isThreeLine: true,
      trailing: onRevoke == null
          ? const Text('منتهية')
          : TextButton(onPressed: onRevoke, child: const Text('إنهاء')),
    );
  }
}

class _StateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback action;
  const _StateCard(
      {required this.icon,
      required this.title,
      required this.message,
      required this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            AppButton(text: 'إعادة المحاولة', onPressed: action),
          ],
        ),
      ),
    );
  }
}

String _date(DateTime value) =>
    '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
