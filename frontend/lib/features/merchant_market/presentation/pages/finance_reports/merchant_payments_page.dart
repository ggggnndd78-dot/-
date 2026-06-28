import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/features/merchant_market/data/models/merchant_finance_model.dart';
import 'package:ghiyarak/features/merchant_market/data/merchant_market_repository.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_management_scaffold.dart';

class MerchantPaymentsPage extends ConsumerStatefulWidget {
  const MerchantPaymentsPage({super.key});
  @override
  ConsumerState<MerchantPaymentsPage> createState() =>
      _MerchantPaymentsPageState();
}

class _MerchantPaymentsPageState extends ConsumerState<MerchantPaymentsPage> {
  late Future<List<MerchantPayment>> _future;
  String _status = 'ALL';
  String _query = '';
  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<MerchantPayment>> _load() =>
      ref.read(merchantMarketRepositoryProvider).getMerchantPayments();
  void _refresh() => setState(() => _future = _load());
  @override
  Widget build(BuildContext context) => FutureBuilder<List<MerchantPayment>>(
      future: _future,
      builder: (context, snapshot) {
        final all = snapshot.data ?? const <MerchantPayment>[];
        final items = all.where((p) {
          final q = _query.trim();
          final matchQ = q.isEmpty ||
              '${p.orderNumber} ${p.customerName} ${p.providerReference}'
                  .contains(q);
          final matchS = _status == 'ALL' || p.status == _status;
          return matchQ && matchS;
        }).toList();
        return MerchantManagementScaffold(
            title: 'مدفوعات المتجر',
            subtitle: 'متابعة المدفوعات المرتبطة بالطلبات وحالتها ومراجعها.',
            onRefresh: () async => _refresh(),
            children: [
              if (snapshot.connectionState != ConnectionState.done &&
                  all.isEmpty)
                const Center(child: CircularProgressIndicator())
              else if (snapshot.hasError)
                MerchantStateCard(
                    icon: Icons.payments_outlined,
                    title: 'تعذر تحميل المدفوعات',
                    message: snapshot.error.toString(),
                    actionLabel: 'إعادة المحاولة',
                    onAction: _refresh)
              else ...[
                Row(children: [
                  Expanded(
                      child: MerchantMetricTile(
                          icon: Icons.payments_outlined,
                          label: 'إجمالي المدفوعات',
                          value: merchantMoney(
                              all.fold<num>(0, (s, e) => s + e.amount),
                              all.isEmpty ? 'YER' : all.first.currency))),
                  const SizedBox(width: 10),
                  Expanded(
                      child: MerchantMetricTile(
                          icon: Icons.verified_outlined,
                          label: 'مؤكدة',
                          value:
                              '${all.where((e) => e.status == 'CONFIRMED').length}'))
                ]),
                const SizedBox(height: 12),
                TextField(
                    decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'بحث برقم الطلب أو العميل أو المرجع',
                        border: OutlineInputBorder()),
                    onChanged: (v) => setState(() => _query = v)),
                const SizedBox(height: 10),
                _CompactStatusDropdown(
                  value: _status,
                  options: const [
                    'ALL',
                    'PENDING',
                    'PENDING_REVIEW',
                    'CONFIRMED',
                    'FAILED',
                    'CANCELLED',
                    'REFUNDED',
                  ],
                  label: (s) => s == 'ALL' ? 'الكل' : merchantFinanceStatusLabel(s),
                  onChanged: (value) => setState(() => _status = value ?? 'ALL'),
                ),
                const SizedBox(height: 14),
                if (items.isEmpty)
                  const MerchantStateCard(
                      icon: Icons.payments_outlined,
                      title: 'لا توجد مدفوعات مطابقة',
                      message: 'غيّر البحث أو الفلترة لعرض نتائج أخرى.')
                else
                  ...items.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: MerchantPanel(
                          child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.payments_outlined,
                                  color: Color(0xFFFF7900)),
                              title: Text(merchantMoney(p.amount, p.currency),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w900)),
                              subtitle: Text([
                                'الحالة: ${merchantFinanceStatusLabel(p.status)}',
                                if (p.orderNumber.isNotEmpty)
                                  'الطلب: ${p.orderNumber}',
                                if (p.customerName.isNotEmpty)
                                  'العميل: ${p.customerName}',
                                if (p.providerCode.isNotEmpty)
                                  'القناة: ${p.providerCode}',
                                if (p.providerReference.isNotEmpty)
                                  'المرجع: ${p.providerReference}',
                                if (p.createdAt.isNotEmpty)
                                  'التاريخ: ${p.createdAt}'
                              ].join('\n')),
                              trailing: Chip(
                                  label: Text(
                                      merchantFinanceStatusLabel(p.status)))))))
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

