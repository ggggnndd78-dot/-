import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/features/merchant_market/data/models/merchant_finance_model.dart';
import 'package:ghiyarak/features/merchant_market/data/merchant_market_repository.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_management_scaffold.dart';

class MerchantSettlementsPage extends ConsumerStatefulWidget {
  const MerchantSettlementsPage({super.key});
  @override
  ConsumerState<MerchantSettlementsPage> createState() =>
      _MerchantSettlementsPageState();
}

class _MerchantSettlementsPageState
    extends ConsumerState<MerchantSettlementsPage> {
  late Future<List<MerchantSettlement>> _future;
  String _status = 'ALL';
  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<MerchantSettlement>> _load() =>
      ref.read(merchantMarketRepositoryProvider).getMerchantSettlements();
  void _refresh() => setState(() => _future = _load());
  @override
  Widget build(BuildContext context) => FutureBuilder<List<MerchantSettlement>>(
      future: _future,
      builder: (context, snapshot) {
        final all = snapshot.data ?? const <MerchantSettlement>[];
        final items =
            all.where((e) => _status == 'ALL' || e.status == _status).toList();
        return MerchantManagementScaffold(
            title: 'التسويات والسحوبات',
            subtitle: 'طلبات السحب والتسويات المعتمدة والمدفوعة من الإدارة.',
            onRefresh: () async => _refresh(),
            children: [
              if (snapshot.connectionState != ConnectionState.done &&
                  all.isEmpty)
                const Center(child: CircularProgressIndicator())
              else if (snapshot.hasError)
                MerchantStateCard(
                    icon: Icons.account_balance_outlined,
                    title: 'تعذر تحميل التسويات',
                    message: snapshot.error.toString(),
                    actionLabel: 'إعادة المحاولة',
                    onAction: _refresh)
              else ...[
                Row(children: [
                  Expanded(
                      child: MerchantMetricTile(
                          icon: Icons.pending_actions_outlined,
                          label: 'قيد الاعتماد',
                          value:
                              '${all.where((e) => e.status == 'PENDING').length}')),
                  const SizedBox(width: 10),
                  Expanded(
                      child: MerchantMetricTile(
                          icon: Icons.paid_outlined,
                          label: 'مدفوعة',
                          value:
                              '${all.where((e) => e.status == 'PAID').length}'))
                ]),
                const SizedBox(height: 10),
                _CompactStatusDropdown(
                  value: _status,
                  options: const ['ALL', 'PENDING', 'APPROVED', 'PAID', 'REJECTED'],
                  label: (s) => s == 'ALL' ? 'الكل' : merchantFinanceStatusLabel(s),
                  onChanged: (value) => setState(() => _status = value ?? 'ALL'),
                ),
                const SizedBox(height: 14),
                if (items.isEmpty)
                  const MerchantStateCard(
                      icon: Icons.account_balance_outlined,
                      title: 'لا توجد تسويات',
                      message: 'ستظهر هنا طلبات السحب والتسويات المالية.')
                else
                  ...items.map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: MerchantPanel(
                          child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                  Icons.account_balance_outlined,
                                  color: Color(0xFFFF7900)),
                              title: Text(merchantMoney(s.amount, s.currency),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w900)),
                              subtitle: Text([
                                'الحالة: ${merchantFinanceStatusLabel(s.status)}',
                                if (s.organizationName.isNotEmpty)
                                  'المتجر: ${s.organizationName}',
                                if (s.periodStart.isNotEmpty ||
                                    s.periodEnd.isNotEmpty)
                                  'الفترة: ${s.periodStart} إلى ${s.periodEnd}',
                                if (s.createdAt.isNotEmpty)
                                  'تاريخ الطلب: ${s.createdAt}',
                                if (s.paidAt.isNotEmpty)
                                  'تاريخ الدفع: ${s.paidAt}'
                              ].join('\n')),
                              trailing: IconButton(
                                  icon: const Icon(Icons.copy),
                                  onPressed: () => Clipboard.setData(ClipboardData(
                                      text:
                                          'Settlement ${s.id} - ${merchantMoney(s.amount, s.currency)} - ${s.status}')))))))
              ]
            ]);
      });
}


class _CompactStatusDropdown extends StatelessWidget {
  const _CompactStatusDropdown({
    required this.value,
    required this.options,
    required this.label,
    required this.onChanged,
  });

  final String value;
  final List<String> options;
  final String Function(String) label;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'فلترة الحالة',
        prefixIcon: const Icon(Icons.filter_alt_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      items: options
          .map((status) => DropdownMenuItem<String>(
                value: status,
                child: Text(label(status)),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}

