import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/core/config/app_config.dart';
import 'package:ghiyarak/core/theme/app_colors.dart';
import 'package:ghiyarak/features/auth/logic/auth_controller.dart';
import 'package:ghiyarak/features/merchant_market/data/merchant_market_repository.dart';
import 'package:ghiyarak/features/merchant_market/data/models/merchant_organization_model.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_bottom_navigation.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_drawer.dart';
import 'package:go_router/go_router.dart';

class MerchantSettingsPage extends ConsumerStatefulWidget {
  const MerchantSettingsPage({super.key});

  @override
  ConsumerState<MerchantSettingsPage> createState() =>
      _MerchantSettingsPageState();
}

class _MerchantSettingsPageState extends ConsumerState<MerchantSettingsPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late Future<MerchantOrganizationModel> _future;
  bool _savingVacation = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<MerchantOrganizationModel> _load() {
    return ref.read(merchantMarketRepositoryProvider).getMerchantOrganization();
  }

  Future<void> _toggleVacation(
    MerchantOrganizationModel organization,
    bool enabled,
  ) async {
    setState(() => _savingVacation = true);
    try {
      await ref.read(merchantMarketRepositoryProvider).updateVacationMode(
            organizationId: organization.id,
            enabled: enabled,
          );
      if (!mounted) return;
      setState(() => _future = _load());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enabled ? 'تم تفعيل وضع الإجازة' : 'تم إلغاء وضع الإجازة',
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _savingVacation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF5F7FA),
        drawer: const MerchantDrawer(
          currentTab: MerchantNavigationTab.settings,
        ),
        bottomNavigationBar: const MerchantBottomNavigation(
          currentTab: MerchantNavigationTab.settings,
        ),
        body: FutureBuilder<MerchantOrganizationModel>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _ErrorState(
                message: snapshot.error.toString(),
                onRetry: () => setState(() => _future = _load()),
              );
            }
            final organization = snapshot.requireData;
            return RefreshIndicator(
              onRefresh: () async {
                setState(() => _future = _load());
                await _future;
              },
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _StoreHeader(
                    organization: organization,
                    onMenu: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _CompletionCard(organization: organization),
                        const SizedBox(height: 24),
                        const Text(
                          'الإعدادات',
                          style: TextStyle(
                            color: Color(0xFF082B51),
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _SettingsCard(
                          children: [
                            _SettingItem(
                              icon: Icons.storefront_outlined,
                              title: 'معلومات المتجر',
                              subtitle: organization.phone ?? 'الهاتف غير مسجل',
                              onTap: () => _showStoreInfo(
                                context,
                                organization,
                              ),
                            ),
                            _SettingItem(
                              icon: Icons.schedule_outlined,
                              title: 'الفروع وساعات العمل',
                              subtitle: '${organization.branches.length} فرع',
                              onTap: () => context.go(
                                RouteNames.merchantBranches,
                              ),
                            ),
                            _SettingItem(
                              icon: Icons.account_balance_wallet_outlined,
                              title: 'طرق الدفع والتحويلات',
                              subtitle:
                                  '${organization.bankAccountsCount} حساب بنكي',
                              onTap: () => _showUnavailable(
                                context,
                                'إدارة الحسابات البنكية متاحة في مسار إعداد المزود الحالي',
                              ),
                            ),
                            _SettingItem(
                              icon: Icons.local_shipping_outlined,
                              title: 'التوصيل والاستلام',
                              subtitle: _policySummary(
                                organization.merchantProfile?.deliveryPolicy,
                              ),
                              onTap: () => _showPolicy(
                                context,
                                'سياسة التوصيل والاستلام',
                                organization.merchantProfile?.deliveryPolicy,
                              ),
                            ),
                            _SettingItem(
                              icon: Icons.notifications_none_rounded,
                              title: 'الإشعارات',
                              onTap: () => context.go(
                                RouteNames.merchantNotifications,
                              ),
                            ),
                            _SettingItem(
                              icon: Icons.groups_outlined,
                              title: 'فريق العمل والصلاحيات',
                              subtitle: '${organization.membersCount} عضو',
                              onTap: () => context.go(RouteNames.merchantTeam),
                            ),
                            _SettingItem(
                              icon: Icons.assignment_return_outlined,
                              title: 'سياسة الإرجاع',
                              subtitle: _policySummary(
                                organization.merchantProfile?.returnPolicy,
                              ),
                              onTap: () => _showPolicy(
                                context,
                                'سياسة الإرجاع',
                                organization.merchantProfile?.returnPolicy,
                              ),
                            ),
                            _SettingItem(
                              icon: Icons.verified_user_outlined,
                              title: 'سياسة الضمان',
                              subtitle: _policySummary(
                                organization.merchantProfile?.warrantyPolicy,
                              ),
                              onTap: () => _showPolicy(
                                context,
                                'سياسة الضمان',
                                organization.merchantProfile?.warrantyPolicy,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFDCE4EC),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.beach_access_outlined,
                                color: Color(0xFFFF6417),
                                size: 31,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'تفعيل وضع الإجازة',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    Text(
                                      'يتم حفظ حالة المتجر في قاعدة البيانات',
                                      style: TextStyle(
                                        color: Color(0xFF687686),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: organization.isVacationMode,
                                onChanged: _savingVacation
                                    ? null
                                    : (value) => _toggleVacation(
                                          organization,
                                          value,
                                        ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () => _logout(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFE04B4B),
                            side: const BorderSide(
                              color: Color(0xFFE04B4B),
                            ),
                            minimumSize: const Size(double.infinity, 54),
                          ),
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text('تسجيل خروج'),
                        ),
                        const SizedBox(height: 18),
                        const Center(
                          child: Text(
                            'جميع الحقوق محفوظة لمنصة غيارك\nالإصدار 1.0.0',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFF687686)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    await ref.read(authControllerProvider.notifier).logout();
    if (context.mounted) context.go(RouteNames.entry);
  }
}

class _StoreHeader extends StatelessWidget {
  const _StoreHeader({
    required this.organization,
    required this.onMenu,
  });

  final MerchantOrganizationModel organization;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        22,
        MediaQuery.paddingOf(context).top + 24,
        22,
        28,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF061A2D), Color(0xFF0E3659)],
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MerchantDrawerButton(onPressed: onMenu),
              const Text(
                'الإعدادات',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 46, height: 46),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                width: 92,
                height: 92,
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFF8A00),
                    width: 3,
                  ),
                ),
                child: Image.asset(
                  AppConfig.logoAsset,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            organization.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 25,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (organization.isVerified) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.verified_rounded,
                            color: Color(0xFF2587F5),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: organization.isVacationMode
                            ? const Color(0x33FF8A00)
                            : const Color(0x3315B75C),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: organization.isVacationMode
                              ? const Color(0xFFFF8A00)
                              : const Color(0xFF15B75C),
                        ),
                      ),
                      child: Text(
                        organization.isVacationMode
                            ? 'في إجازة'
                            : organization.status == 'APPROVED'
                                ? 'مفتوح'
                                : organization.status,
                        style: TextStyle(
                          color: organization.isVacationMode
                              ? const Color(0xFFFFA240)
                              : const Color(0xFF46D77E),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompletionCard extends StatelessWidget {
  const _CompletionCard({required this.organization});
  final MerchantOrganizationModel organization;

  @override
  Widget build(BuildContext context) {
    final progress = organization.completionPercent / 100;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        boxShadow: const [
          BoxShadow(color: Color(0x10000000), blurRadius: 14),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 82,
            height: 82,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 7,
                  backgroundColor: const Color(0xFFE5EAF0),
                  color: const Color(0xFFFF6417),
                ),
                Text(
                  '${organization.completionPercent}%',
                  style: const TextStyle(
                    color: Color(0xFF082B51),
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'اكتمال ملف المتجر',
                  style: TextStyle(
                    color: Color(0xFF082B51),
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'أكمل بيانات ملفك وسياسات المتجر والفروع',
                  style: TextStyle(color: Color(0xFF687686)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE4EC)),
      ),
      child: Column(
        children: List.generate(children.length * 2 - 1, (index) {
          if (index.isOdd) return const Divider(height: 1);
          return children[index ~/ 2];
        }),
      ),
    );
  }
}

class _SettingItem extends StatelessWidget {
  const _SettingItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F3F6),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, color: AppColors.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      trailing: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          ElevatedButton(
              onPressed: onRetry, child: const Text('إعادة المحاولة')),
        ],
      ),
    );
  }
}

String _policySummary(String? value) {
  if ((value ?? '').trim().isEmpty) return 'غير مكتملة';
  return value!;
}

void _showPolicy(BuildContext context, String title, String? value) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            Text((value ?? '').trim().isEmpty ? 'غير مسجلة' : value!),
          ],
        ),
      ),
    ),
  );
}

void _showStoreInfo(
  BuildContext context,
  MerchantOrganizationModel organization,
) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              organization.name,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Text('الهاتف: ${organization.phone ?? 'غير مسجل'}'),
            Text(
              'السجل التجاري: ${organization.commercialRegistration ?? 'غير مسجل'}',
            ),
            Text('الحالة: ${organization.status}'),
          ],
        ),
      ),
    ),
  );
}

void _showUnavailable(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
