import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/features/merchant_market/data/models/merchant_chat_model.dart';
import 'package:ghiyarak/features/merchant_market/data/models/merchant_notification_model.dart';
import 'package:ghiyarak/features/merchant_market/data/merchant_market_repository.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_management_scaffold.dart';

class MerchantNotificationSettingsPage extends ConsumerStatefulWidget {
  const MerchantNotificationSettingsPage({super.key});

  @override
  ConsumerState<MerchantNotificationSettingsPage> createState() =>
      _MerchantNotificationSettingsPageState();
}

class _MerchantNotificationSettingsPageState
    extends ConsumerState<MerchantNotificationSettingsPage> {
  late Future<_NotificationSettingsData> _future;
  MerchantNotificationPreferences? _prefs;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_NotificationSettingsData> _load() async {
    final repo = ref.read(merchantMarketRepositoryProvider);
    final result = await repo.getMerchantNotifications();
    final prefs = await repo.getMerchantNotificationPreferences();
    _prefs = prefs;
    return _NotificationSettingsData(result, prefs);
  }

  void _setPrefs(MerchantNotificationPreferences prefs) =>
      setState(() => _prefs = prefs);

  Future<void> _save() async {
    final prefs = _prefs;
    if (prefs == null) return;
    setState(() => _saving = true);
    try {
      final saved = await ref
          .read(merchantMarketRepositoryProvider)
          .updateMerchantNotificationPreferences(prefs);
      if (!mounted) return;
      setState(() {
        _prefs = saved;
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ إعدادات الإشعارات')));
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_NotificationSettingsData>(
      future: _future,
      builder: (context, snapshot) {
        final prefs = _prefs ?? snapshot.data?.preferences;
        return MerchantManagementScaffold(
          title: 'إعدادات الإشعارات',
          subtitle:
              'إدارة قنوات التنبيه وأنواع التنبيهات المهمة للتاجر والموظفين.',
          onRefresh: () async => setState(() => _future = _load()),
          children: [
            if (snapshot.connectionState != ConnectionState.done &&
                prefs == null)
              const Center(child: CircularProgressIndicator())
            else if (snapshot.hasError && prefs == null)
              MerchantStateCard(
                  icon: Icons.error_outline,
                  title: 'تعذر تحميل الإعدادات',
                  message: snapshot.error.toString(),
                  actionLabel: 'إعادة المحاولة',
                  onAction: () => setState(() => _future = _load()))
            else if (prefs != null)
              _NotificationSettingsContent(
                result: snapshot.data?.result,
                preferences: prefs,
                onChanged: _setPrefs,
                onSave: _save,
                saving: _saving,
              ),
          ],
        );
      },
    );
  }
}

class _NotificationSettingsData {
  final MerchantNotificationResult result;
  final MerchantNotificationPreferences preferences;
  const _NotificationSettingsData(this.result, this.preferences);
}

class _NotificationSettingsContent extends StatelessWidget {
  const _NotificationSettingsContent(
      {required this.result,
      required this.preferences,
      required this.onChanged,
      required this.onSave,
      required this.saving});

  final MerchantNotificationResult? result;
  final MerchantNotificationPreferences preferences;
  final ValueChanged<MerchantNotificationPreferences> onChanged;
  final VoidCallback onSave;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final types = <String, int>{};
    for (final item in result?.items ?? const <MerchantNotificationModel>[]) {
      types[item.type] = (types[item.type] ?? 0) + 1;
    }
    return Column(children: [
      Row(children: [
        Expanded(
            child: MerchantMetricTile(
                icon: Icons.notifications_active_outlined,
                label: 'الإشعارات',
                value: '${result?.items.length ?? 0}')),
        const SizedBox(width: 10),
        Expanded(
            child: MerchantMetricTile(
                icon: Icons.mark_email_unread_outlined,
                label: 'غير مقروءة',
                value: '${result?.unreadCount ?? 0}')),
      ]),
      const SizedBox(height: 14),
      MerchantPanel(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('قنوات الإشعار',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
        _tile(
            'إشعارات التطبيق Push',
            'تنبيه فوري خارج التطبيق عند الطلبات والرسائل المهمة.',
            preferences.pushEnabled,
            (v) => onChanged(preferences.copyWith(pushEnabled: v))),
        _tile(
            'البريد الإلكتروني',
            'إرسال ملخصات وتنبيهات رسمية للبريد.',
            preferences.emailEnabled,
            (v) => onChanged(preferences.copyWith(emailEnabled: v))),
        _tile(
            'الرسائل النصية SMS',
            'للتنبيهات الحرجة فقط مثل الدفع أو الشحن.',
            preferences.smsEnabled,
            (v) => onChanged(preferences.copyWith(smsEnabled: v))),
      ])),
      const SizedBox(height: 14),
      MerchantPanel(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('أنواع التنبيهات',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
        _tile(
            'الطلبات',
            'طلب جديد، قبول، إلغاء، تغيير حالة.',
            preferences.orderNotifications,
            (v) => onChanged(preferences.copyWith(orderNotifications: v))),
        _tile(
            'المحادثات',
            'رسائل العملاء والردود غير المقروءة.',
            preferences.chatNotifications,
            (v) => onChanged(preferences.copyWith(chatNotifications: v))),
        _tile(
            'المخزون',
            'نفاد أو انخفاض كمية منتج.',
            preferences.stockNotifications,
            (v) => onChanged(preferences.copyWith(stockNotifications: v))),
        _tile(
            'المالية',
            'دفعات، تسويات، فواتير وطلبات سحب.',
            preferences.financeNotifications,
            (v) => onChanged(preferences.copyWith(financeNotifications: v))),
        _tile(
            'المرتجعات والنزاعات',
            'طلبات إرجاع وشكاوى تحتاج قرار.',
            preferences.returnsDisputesNotifications,
            (v) => onChanged(
                preferences.copyWith(returnsDisputesNotifications: v))),
        _tile(
            'التقييمات',
            'تقييم أو مراجعة جديدة على المتجر أو المنتج.',
            preferences.reviewNotifications,
            (v) => onChanged(preferences.copyWith(reviewNotifications: v))),
      ])),
      const SizedBox(height: 14),
      MerchantPanel(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('أنواع التنبيهات الواردة فعليًا',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        if (types.isEmpty)
          const Text('لا توجد إشعارات مصنفة حاليًا')
        else
          ...types.entries.map((entry) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.label_important_outline,
                  color: Color(0xFFFF7900)),
              title: Text(_typeLabel(entry.key)),
              trailing: Text('${entry.value}'))),
      ])),
      const SizedBox(height: 14),
      FilledButton.icon(
          onPressed: saving ? null : onSave,
          icon: saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.save_outlined),
          label: const Text('حفظ إعدادات الإشعارات')),
    ]);
  }

  Widget _tile(
      String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle));
  }
}

String _typeLabel(String type) {
  final value = type.toLowerCase();
  if (value.contains('order')) return 'الطلبات';
  if (value.contains('stock') || value.contains('inventory')) return 'المخزون';
  if (value.contains('review')) return 'التقييمات';
  if (value.contains('return') || value.contains('refund')) return 'المرتجعات';
  if (value.contains('dispute') || value.contains('complaint'))
    return 'النزاعات';
  if (value.contains('chat') || value.contains('message')) return 'المحادثات';
  if (value.contains('payment') || value.contains('wallet')) return 'المالية';
  return type.isEmpty ? 'عام' : type;
}
