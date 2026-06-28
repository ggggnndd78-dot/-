import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/core/network/api_exception.dart';
import 'package:ghiyarak/core/theme/app_colors.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/core/theme/app_text_styles.dart';
import 'package:ghiyarak/features/auth/data/auth_repository.dart';
import 'package:ghiyarak/features/customer/data/customer_repository.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:go_router/go_router.dart';

class CustomerRewardsPage extends ConsumerWidget {
  const CustomerRewardsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_rewardsPageProvider);

    return AppScaffold(
      title: 'المحفظة والمكافآت',
      child: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _StatePanel(
          icon: Icons.error_outline,
          title: 'تعذر تحميل المكافآت',
          message: error.toString(),
          actionText: 'إعادة المحاولة',
          onPressed: () => ref.invalidate(_rewardsPageProvider),
        ),
        data: (data) {
          if (!data.isAuthenticated) {
            return _StatePanel(
              icon: Icons.lock_outline,
              title: 'سجل دخولك لعرض محفظتك',
              message: 'النقاط والمحفظة وكود الإحالة مرتبطة بحسابك الشخصي.',
              actionText: 'تسجيل الدخول',
              onPressed: () => context.go(
                '${RouteNames.login}?returnTo=${Uri.encodeComponent(RouteNames.customerRewards)}',
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(_rewardsPageProvider.future),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _RewardsHeader(summary: data.summary!),
                const SizedBox(height: AppSpacing.lg),
                _ReferralCard(code: data.summary!.referralCode),
                const SizedBox(height: AppSpacing.lg),
                _RedeemPanel(pointsBalance: data.summary!.pointsBalance),
                const SizedBox(height: AppSpacing.lg),
                const _UseReferralCodePanel(),
                const SizedBox(height: AppSpacing.lg),
                _TransactionsSection(
                  loyalty: data.loyaltyTransactions,
                  wallet: data.walletTransactions,
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RewardsHeader extends StatelessWidget {
  final CustomerRewardsSummary summary;

  const _RewardsHeader({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined,
                  color: AppColors.secondary, size: 34),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'رصيدك في غيارك',
                  style: AppTextStyles.heading2.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _HeaderMetric(
                  label: 'المحفظة',
                  value: '${summary.walletBalance.toStringAsFixed(0)} YER',
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _HeaderMetric(
                  label: 'النقاط',
                  value: '${summary.pointsBalance}',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'يمكنك استبدال النقاط إلى رصيد محفظة واستخدامه لاحقا في الطلبات عند دعم الدفع بالمحفظة.',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textOnDark.withValues(alpha: 0.78),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  final String label;
  final String value;

  const _HeaderMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.body.copyWith(color: Colors.white70)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.title.copyWith(color: AppColors.secondary),
          ),
        ],
      ),
    );
  }
}

class _ReferralCard extends StatelessWidget {
  final String code;

  const _ReferralCard({required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          const Icon(Icons.ios_share_outlined, color: AppColors.iconAccent),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('كود الإحالة', style: AppTextStyles.title),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  code.isEmpty ? 'لم يتم إنشاء كود بعد' : code,
                  style: AppTextStyles.heading2.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            onPressed: code.isEmpty
                ? null
                : () async {
                    await Clipboard.setData(ClipboardData(text: code));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم نسخ كود الإحالة')),
                      );
                    }
                  },
            icon: const Icon(Icons.copy),
            tooltip: 'نسخ',
          ),
        ],
      ),
    );
  }
}

class _RedeemPanel extends ConsumerStatefulWidget {
  final int pointsBalance;

  const _RedeemPanel({required this.pointsBalance});

  @override
  ConsumerState<_RedeemPanel> createState() => _RedeemPanelState();
}

class _RedeemPanelState extends ConsumerState<_RedeemPanel> {
  final _controller = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('استبدال النقاط', style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'عدد النقاط',
              prefixIcon: Icon(Icons.stars_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            text: _loading ? 'جار الاستبدال...' : 'تحويل إلى المحفظة',
            onPressed: _loading ? null : _redeem,
          ),
        ],
      ),
    );
  }

  Future<void> _redeem() async {
    final points = int.tryParse(_controller.text.trim()) ?? 0;
    if (points <= 0 || points > widget.pointsBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل عدد نقاط صحيح ومتاح')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(customerRepositoryProvider).redeemPoints(points);
      ref.invalidate(_rewardsPageProvider);
      if (mounted) {
        _controller.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحويل النقاط إلى المحفظة')),
        );
      }
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _UseReferralCodePanel extends ConsumerStatefulWidget {
  const _UseReferralCodePanel();

  @override
  ConsumerState<_UseReferralCodePanel> createState() =>
      _UseReferralCodePanelState();
}

class _UseReferralCodePanelState extends ConsumerState<_UseReferralCodePanel> {
  final _controller = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('استخدام كود إحالة', style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _controller,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'كود الإحالة من صديق',
              prefixIcon: Icon(Icons.redeem_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            text: _loading ? 'جارٍ التطبيق...' : 'تطبيق الكود',
            isOutlined: true,
            onPressed: _loading ? null : _submit,
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final code = _controller.text.trim();
    if (code.isEmpty) return;
    setState(() => _loading = true);
    try {
      await ref.read(customerRepositoryProvider).useReferralCode(code);
      ref.invalidate(_rewardsPageProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('تم تطبيق كود الإحالة وإضافة النقاط')));
        _controller.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _TransactionsSection extends StatelessWidget {
  final List<LoyaltyTransaction> loyalty;
  final List<WalletTransaction> wallet;

  const _TransactionsSection({required this.loyalty, required this.wallet});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _SectionHeader(title: 'آخر عمليات النقاط'),
          if (loyalty.isEmpty)
            const _EmptyLine(text: 'لا توجد عمليات نقاط حتى الآن')
          else
            ...loyalty.take(5).map(
                  (item) => ListTile(
                    leading: const Icon(Icons.stars_outlined),
                    title: Text('${item.points} نقطة'),
                    subtitle: Text('${item.type} - ${item.referenceType}'),
                  ),
                ),
          const Divider(height: 1),
          _SectionHeader(title: 'آخر عمليات المحفظة'),
          if (wallet.isEmpty)
            const _EmptyLine(text: 'لا توجد عمليات محفظة حتى الآن')
          else
            ...wallet.take(5).map(
                  (item) => ListTile(
                    leading: const Icon(Icons.account_balance_wallet_outlined),
                    title: Text('${item.amount.toStringAsFixed(0)} YER'),
                    subtitle: Text(
                      '${item.type} - الرصيد بعد العملية ${item.balanceAfter.toStringAsFixed(0)}',
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(title, style: AppTextStyles.title),
      ),
    );
  }
}

class _EmptyLine extends StatelessWidget {
  final String text;

  const _EmptyLine({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Text(text, style: AppTextStyles.bodySecondary),
    );
  }
}

class _StatePanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionText;
  final VoidCallback onPressed;

  const _StatePanel({
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
            Icon(icon, color: AppColors.iconAccent, size: 44),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.sm),
            Text(message,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySecondary),
            const SizedBox(height: AppSpacing.lg),
            AppButton(text: actionText, onPressed: onPressed),
          ],
        ),
      ),
    );
  }
}

class _RewardsPageState {
  final bool isAuthenticated;
  final CustomerRewardsSummary? summary;
  final List<LoyaltyTransaction> loyaltyTransactions;
  final List<WalletTransaction> walletTransactions;

  const _RewardsPageState.authRequired()
      : isAuthenticated = false,
        summary = null,
        loyaltyTransactions = const [],
        walletTransactions = const [];

  const _RewardsPageState.loaded({
    required this.summary,
    required this.loyaltyTransactions,
    required this.walletTransactions,
  }) : isAuthenticated = true;
}

final _rewardsPageProvider = FutureProvider<_RewardsPageState>((ref) async {
  final authRepository = ref.read(authRepositoryProvider);
  final isAuthenticated = await authRepository.isAuthenticated();
  if (!isAuthenticated) return const _RewardsPageState.authRequired();

  final repository = ref.read(customerRepositoryProvider);
  final summary = await repository.rewardsSummary();
  final loyalty = await repository.loyaltyTransactions();
  final wallet = await repository.walletTransactions();
  return _RewardsPageState.loaded(
    summary: summary,
    loyaltyTransactions: loyalty,
    walletTransactions: wallet,
  );
});

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: AppColors.border),
    boxShadow: const [
      BoxShadow(
        color: AppColors.shadow,
        blurRadius: 12,
        offset: Offset(0, 7),
      ),
    ],
  );
}
