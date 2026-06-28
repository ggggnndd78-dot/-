import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/features/merchant_market/data/models/merchant_finance_model.dart';
import 'package:ghiyarak/features/merchant_market/data/merchant_market_repository.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_management_scaffold.dart';

class MerchantInvoicesPage extends ConsumerStatefulWidget {
  const MerchantInvoicesPage({super.key});
  @override
  ConsumerState<MerchantInvoicesPage> createState() =>
      _MerchantInvoicesPageState();
}

class _MerchantInvoicesPageState extends ConsumerState<MerchantInvoicesPage> {
  late Future<List<MerchantInvoice>> _future;
  String _query = '';
  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<MerchantInvoice>> _load() =>
      ref.read(merchantMarketRepositoryProvider).getMerchantInvoices();
  void _refresh() => setState(() => _future = _load());
  @override
  Widget build(BuildContext context) => FutureBuilder<List<MerchantInvoice>>(
      future: _future,
      builder: (context, snapshot) {
        final all = snapshot.data ?? const <MerchantInvoice>[];
        final items = all.where((i) {
          final q = _query.trim();
          return q.isEmpty ||
              '${i.invoiceNumber} ${i.orderNumber} ${i.customerName}'
                  .contains(q);
        }).toList();
        return MerchantManagementScaffold(
            title: 'فواتير المتجر',
            subtitle:
                'فواتير الطلبات مع المبالغ والخصومات والحالة وقابلية النسخ.',
            onRefresh: () async => _refresh(),
            children: [
              if (snapshot.connectionState != ConnectionState.done &&
                  all.isEmpty)
                const Center(child: CircularProgressIndicator())
              else if (snapshot.hasError)
                MerchantStateCard(
                    icon: Icons.receipt_long_outlined,
                    title: 'تعذر تحميل الفواتير',
                    message: snapshot.error.toString(),
                    actionLabel: 'إعادة المحاولة',
                    onAction: _refresh)
              else ...[
                Row(children: [
                  Expanded(
                      child: MerchantMetricTile(
                          icon: Icons.request_quote_outlined,
                          label: 'إجمالي الفواتير',
                          value: merchantMoney(
                              all.fold<num>(0, (s, e) => s + e.totalAmount),
                              all.isEmpty ? 'YER' : all.first.currency))),
                  const SizedBox(width: 10),
                  Expanded(
                      child: MerchantMetricTile(
                          icon: Icons.description_outlined,
                          label: 'عدد الفواتير',
                          value: '${all.length}'))
                ]),
                const SizedBox(height: 12),
                TextField(
                    decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'بحث برقم الفاتورة أو الطلب أو العميل',
                        border: OutlineInputBorder()),
                    onChanged: (v) => setState(() => _query = v)),
                const SizedBox(height: 14),
                if (items.isEmpty)
                  const MerchantStateCard(
                      icon: Icons.receipt_long_outlined,
                      title: 'لا توجد فواتير',
                      message:
                          'الفواتير تظهر بعد إكمال الطلبات أو إنشاء فاتورة للطلب.')
                else
                  ...items.map((i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: MerchantPanel(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Row(children: [
                              Expanded(
                                  child: Text(i.invoiceNumber,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900))),
                              Chip(
                                  label: Text(
                                      merchantFinanceStatusLabel(i.status)))
                            ]),
                            const SizedBox(height: 8),
                            Wrap(spacing: 8, runSpacing: 8, children: [
                              Chip(
                                  label: Text(
                                      'الإجمالي: ${merchantMoney(i.totalAmount, i.currency)}')),
                              Chip(
                                  label: Text(
                                      'الخصم: ${merchantMoney(i.discountAmount, i.currency)}')),
                              if (i.orderNumber.isNotEmpty)
                                Chip(label: Text('طلب ${i.orderNumber}')),
                              if (i.customerName.isNotEmpty)
                                Chip(label: Text(i.customerName))
                            ]),
                            const SizedBox(height: 8),
                            Text(
                                'تاريخ الإصدار: ${i.issuedAt.isEmpty ? i.createdAt : i.issuedAt}',
                                style:
                                    const TextStyle(color: Color(0xFF687686))),
                            Align(
                                alignment: AlignmentDirectional.centerEnd,
                                child: OutlinedButton.icon(
                                    onPressed: () => _copyInvoice(i),
                                    icon: const Icon(Icons.copy),
                                    label: const Text('نسخ الفاتورة')))
                          ]))))
              ]
            ]);
      });
  void _copyInvoice(MerchantInvoice i) {
    final text =
        '''فاتورة: ${i.invoiceNumber}\nطلب: ${i.orderNumber}\nالعميل: ${i.customerName}\nالإجمالي: ${merchantMoney(i.totalAmount, i.currency)}\nالحالة: ${merchantFinanceStatusLabel(i.status)}''';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('تم نسخ الفاتورة')));
  }
}
