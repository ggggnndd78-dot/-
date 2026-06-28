import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/core/theme/app_colors.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/core/theme/app_text_styles.dart';
import 'package:ghiyarak/features/cart/data/cart_repository.dart';
import 'package:ghiyarak/features/cart/data/models/customer_payment_model.dart';
import 'package:ghiyarak/shared/widgets/app_button.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:go_router/go_router.dart';

class PaymentResultPage extends ConsumerStatefulWidget {
  final String orderId;
  const PaymentResultPage({super.key, required this.orderId});

  @override
  ConsumerState<PaymentResultPage> createState() => _PaymentResultPageState();
}

class _PaymentResultPageState extends ConsumerState<PaymentResultPage> {
  late Future<CustomerPaymentSummary> _future;
  final _referenceController = TextEditingController();
  final _proofController = TextEditingController();
  final _noteController = TextEditingController();
  bool _submittingProof = false;
  bool _retrying = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _referenceController.dispose();
    _proofController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<CustomerPaymentSummary> _load() {
    return ref.read(cartRepositoryProvider).getPaymentSummary(widget.orderId);
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() {
      _future = next;
    });
    await next;
  }

  Future<void> _submitProof() async {
    if (_referenceController.text.trim().isEmpty &&
        _proofController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل رقم العملية أو رابط الإيصال')),
      );
      return;
    }
    setState(() => _submittingProof = true);
    try {
      final summary = await ref.read(cartRepositoryProvider).submitPaymentProof(
            orderId: widget.orderId,
            reference: _referenceController.text.trim(),
            proofUrl: _proofController.text.trim(),
            note: _noteController.text.trim(),
          );
      if (!mounted) return;
      setState(() {
        _future = Future.value(summary);
        _referenceController.clear();
        _proofController.clear();
        _noteController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال إثبات الدفع للمراجعة')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _submittingProof = false);
    }
  }

  Future<void> _retryWalletPayment() async {
    setState(() => _retrying = true);
    try {
      final summary = await ref.read(cartRepositoryProvider).retryPayment(
            orderId: widget.orderId,
            paymentMethod: 'WALLET',
          );
      if (!mounted) return;
      setState(() {
        _future = Future.value(summary);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(summary.resultMessage)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  Future<void> _copy(CustomerPaymentSummary summary) async {
    final text = '''
طلب رقم: ${summary.orderNumber}
حالة الدفع: ${_statusLabel(summary.paymentStatus)}
طريقة الدفع: ${_methodLabel(summary.paymentMethod)}
المبلغ: ${summary.amount.toStringAsFixed(0)} ${summary.currency}
${summary.resultMessage}
'''
        .trim();
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ نتيجة الدفع')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'نتيجة الدفع',
      child: FutureBuilder<CustomerPaymentSummary>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _StateCard(
              icon: Icons.payment_outlined,
              title: 'تعذر جلب نتيجة الدفع',
              message: snapshot.error.toString(),
              actionLabel: 'إعادة المحاولة',
              onAction: _refresh,
            );
          }
          final summary = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _ResultHero(summary: summary),
                const SizedBox(height: AppSpacing.lg),
                _PaymentInfoCard(
                    summary: summary, onCopy: () => _copy(summary)),
                if (summary.instructions.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _InstructionsCard(items: summary.instructions),
                ],
                if (summary.canUploadProof) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _ProofCard(
                    referenceController: _referenceController,
                    proofController: _proofController,
                    noteController: _noteController,
                    submitting: _submittingProof,
                    onSubmit: _submitProof,
                  ),
                ],
                if (summary.canPayFromWallet || summary.canRetry) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _ActionsCard(
                    summary: summary,
                    retrying: _retrying,
                    onRetryWallet:
                        summary.canPayFromWallet ? _retryWalletPayment : null,
                  ),
                ],
                if (summary.proofs.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _ProofsHistoryCard(proofs: summary.proofs),
                ],
                if (summary.attempts.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _AttemptsCard(attempts: summary.attempts),
                ],
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        text: 'تفاصيل الطلب',
                        onPressed: () => context
                            .go('${RouteNames.orderDetail}/${widget.orderId}'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppButton(
                        text: 'طلباتي',
                        isOutlined: true,
                        onPressed: () => context.go(RouteNames.myOrders),
                      ),
                    ),
                  ],
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

class _ResultHero extends StatelessWidget {
  final CustomerPaymentSummary summary;
  const _ResultHero({required this.summary});

  @override
  Widget build(BuildContext context) {
    final color = summary.isSuccess
        ? AppColors.success
        : summary.isFailed
            ? AppColors.error
            : AppColors.secondary;
    final icon = summary.isSuccess
        ? Icons.check_circle_outline
        : summary.isFailed
            ? Icons.error_outline
            : Icons.hourglass_top_outlined;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadow, blurRadius: 18, offset: Offset(0, 10))
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Icon(icon,
                color: color == AppColors.secondary
                    ? AppColors.headerFooterAccent
                    : color,
                size: 48),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            summary.resultTitle.isEmpty
                ? _statusLabel(summary.paymentStatus)
                : summary.resultTitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.heading2.copyWith(color: AppColors.textOnDark),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            summary.resultMessage,
            textAlign: TextAlign.center,
            style: AppTextStyles.body
                .copyWith(color: AppColors.textOnDark.withValues(alpha: 0.82)),
          ),
        ],
      ),
    );
  }
}

class _PaymentInfoCard extends StatelessWidget {
  final CustomerPaymentSummary summary;
  final VoidCallback onCopy;
  const _PaymentInfoCard({required this.summary, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'ملخص الدفع',
      child: Column(
        children: [
          _InfoRow(label: 'رقم الطلب', value: summary.orderNumber),
          _InfoRow(
              label: 'طريقة الدفع', value: _methodLabel(summary.paymentMethod)),
          _InfoRow(
              label: 'حالة الدفع', value: _statusLabel(summary.paymentStatus)),
          _InfoRow(
              label: 'المبلغ',
              value: '${summary.amount.toStringAsFixed(0)} ${summary.currency}',
              prominent: true),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onCopy,
              icon: const Icon(Icons.copy_outlined),
              label: const Text('نسخ بيانات الدفع'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InstructionsCard extends StatelessWidget {
  final List<String> items;
  const _InstructionsCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'تعليمات الدفع',
      child: Column(
        children: [
          for (final item in items) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline,
                    color: AppColors.iconAccent, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(item, style: AppTextStyles.body)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _ProofCard extends StatelessWidget {
  final TextEditingController referenceController;
  final TextEditingController proofController;
  final TextEditingController noteController;
  final bool submitting;
  final VoidCallback onSubmit;

  const _ProofCard({
    required this.referenceController,
    required this.proofController,
    required this.noteController,
    required this.submitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'رفع إثبات الدفع',
      child: Column(
        children: [
          TextField(
            controller: referenceController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.confirmation_number_outlined),
              labelText: 'رقم العملية',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: proofController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.image_outlined),
              labelText: 'رابط صورة الإيصال',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: noteController,
            maxLines: 2,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.notes_outlined),
              labelText: 'ملاحظة اختيارية',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
              text: 'إرسال الإثبات للمراجعة',
              isLoading: submitting,
              onPressed: onSubmit),
        ],
      ),
    );
  }
}

class _ActionsCard extends StatelessWidget {
  final CustomerPaymentSummary summary;
  final bool retrying;
  final VoidCallback? onRetryWallet;
  const _ActionsCard(
      {required this.summary, required this.retrying, this.onRetryWallet});

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'إجراءات الدفع',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (onRetryWallet != null)
            AppButton(
                text: 'الدفع من المحفظة الآن',
                isLoading: retrying,
                onPressed: onRetryWallet),
          if (summary.canRetry && onRetryWallet == null)
            Text('يمكنك إعادة محاولة الدفع أو تحديث بياناته من خلال الدعم.',
                style: AppTextStyles.bodySecondary),
        ],
      ),
    );
  }
}

class _ProofsHistoryCard extends StatelessWidget {
  final List<CustomerPaymentProof> proofs;
  const _ProofsHistoryCard({required this.proofs});

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'إثباتات الدفع المرسلة',
      child: Column(
        children: proofs
            .map((proof) => _HistoryTile(
                  icon: Icons.receipt_long_outlined,
                  title:
                      proof.reference.isEmpty ? 'إثبات دفع' : proof.reference,
                  subtitle:
                      '${_statusLabel(proof.status)} • ${proof.createdAt}',
                ))
            .toList(),
      ),
    );
  }
}

class _AttemptsCard extends StatelessWidget {
  final List<CustomerPaymentAttempt> attempts;
  const _AttemptsCard({required this.attempts});

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'محاولات الدفع',
      child: Column(
        children: attempts
            .map((attempt) => _HistoryTile(
                  icon: Icons.history_outlined,
                  title:
                      'محاولة ${attempt.attemptNumber} - ${_statusLabel(attempt.status)}',
                  subtitle: [attempt.createdAt, attempt.message]
                      .where((e) => e.trim().isNotEmpty)
                      .join(' • '),
                ))
            .toList(),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _HistoryTile(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.iconAccent),
      title: Text(title,
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w900)),
      subtitle: subtitle.isEmpty
          ? null
          : Text(subtitle, style: AppTextStyles.bodySecondary),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool prominent;
  const _InfoRow(
      {required this.label, required this.value, this.prominent = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.bodySecondary)),
          Text(
            value,
            style:
                (prominent ? AppTextStyles.title : AppTextStyles.body).copyWith(
              color: prominent ? AppColors.secondary : AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  const _Card({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadow, blurRadius: 12, offset: Offset(0, 6))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  const _StateCard(
      {required this.icon,
      required this.title,
      required this.message,
      required this.actionLabel,
      required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _Card(
        title: title,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: AppColors.iconAccent),
            const SizedBox(height: AppSpacing.md),
            Text(message,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySecondary),
            const SizedBox(height: AppSpacing.md),
            AppButton(text: actionLabel, onPressed: onAction),
          ],
        ),
      ),
    );
  }
}

String _methodLabel(String method) => switch (method.toUpperCase()) {
      'CASH_ON_DELIVERY' => 'الدفع عند التوصيل',
      'CASH_ON_PICKUP' => 'الدفع عند الاستلام من الفرع',
      'BANK_TRANSFER' => 'تحويل بنكي',
      'WALLET' => 'المحفظة',
      _ => method.isEmpty ? 'غير محدد' : method,
    };

String _statusLabel(String status) => switch (status.toUpperCase()) {
      'CONFIRMED' || 'PAID' || 'COMPLETED' => 'مدفوع',
      'PENDING' => 'بانتظار الدفع',
      'UNDER_REVIEW' || 'PENDING_REVIEW' || 'REVIEW' => 'قيد المراجعة',
      'FAILED' => 'فشل الدفع',
      'REJECTED' => 'مرفوض',
      'CANCELLED' => 'ملغي',
      _ => status.isEmpty ? 'غير محدد' : status,
    };
