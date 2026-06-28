import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/theme/app_colors.dart';
import 'package:ghiyarak/features/merchant_market/data/merchant_market_repository.dart';
import 'package:ghiyarak/features/merchant_market/data/models/merchant_report_model.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_bottom_navigation.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_drawer.dart';
import 'package:ghiyarak/shared/widgets/app_tile_material.dart';

class MerchantReportsPage extends ConsumerStatefulWidget {
  const MerchantReportsPage({super.key});

  @override
  ConsumerState<MerchantReportsPage> createState() =>
      _MerchantReportsPageState();
}

class _MerchantReportsPageState extends ConsumerState<MerchantReportsPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  String _period = 'month';
  String _type = 'overview';
  DateTime? _dateFrom;
  DateTime? _dateTo;
  late Future<MerchantReportModel> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<MerchantReportModel> _load() {
    return ref.read(merchantMarketRepositoryProvider).getMerchantReport(
          period: _period,
          type: _type,
          dateFrom: _dateFrom,
          dateTo: _dateTo,
        );
  }

  void _refresh() => setState(() => _future = _load());

  Future<void> _exportCsv() async {
    try {
      final csv = await ref
          .read(merchantMarketRepositoryProvider)
          .exportMerchantReportCsv(
            period: _period,
            type: _type,
            dateFrom: _dateFrom,
            dateTo: _dateTo,
          );
      await Clipboard.setData(ClipboardData(text: csv));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم نسخ تقرير CSV ويمكن لصقه في Excel')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تصدير التقرير: $error')),
      );
    }
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _dateFrom != null && _dateTo != null
          ? DateTimeRange(start: _dateFrom!, end: _dateTo!)
          : DateTimeRange(
              start: now.subtract(const Duration(days: 30)), end: now),
      helpText: 'اختر فترة التقرير',
      saveText: 'تطبيق',
      cancelText: 'إلغاء',
    );
    if (range == null) return;
    setState(() {
      _dateFrom = range.start;
      _dateTo = range.end;
      _period = 'custom';
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF5F7FA),
        drawer: const MerchantDrawer(currentTab: MerchantNavigationTab.reports),
        bottomNavigationBar: const MerchantBottomNavigation(
            currentTab: MerchantNavigationTab.reports),
        body: Column(
          children: [
            _Header(
              onMenu: () => _scaffoldKey.currentState?.openDrawer(),
              onExport: _exportCsv,
            ),
            Expanded(
              child: FutureBuilder<MerchantReportModel>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return _StateView(
                      icon: Icons.error_outline,
                      title: 'تعذر تحميل التقارير',
                      message: snapshot.error.toString(),
                      actionText: 'إعادة المحاولة',
                      onAction: _refresh,
                    );
                  }
                  final report = snapshot.requireData;
                  return RefreshIndicator(
                    onRefresh: () async {
                      _refresh();
                      await _future;
                    },
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _FiltersBar(
                          period: _period,
                          type: _type,
                          from: report.filters.dateFrom,
                          to: report.filters.dateTo,
                          onPeriodChanged: (value) {
                            setState(() {
                              _period = value;
                              if (value != 'custom') {
                                _dateFrom = null;
                                _dateTo = null;
                              }
                              _future = _load();
                            });
                          },
                          onTypeChanged: (value) {
                            setState(() {
                              _type = value;
                              _future = _load();
                            });
                          },
                          onCustomRange: _pickDateRange,
                        ),
                        const SizedBox(height: 16),
                        _Insights(insights: report.insights),
                        const SizedBox(height: 16),
                        _SummaryGrid(report: report),
                        const SizedBox(height: 16),
                        _SalesCard(report: report),
                        const SizedBox(height: 16),
                        _ResponsivePair(
                          first: _StatusCard(
                            title: 'حالات الطلبات',
                            icon: Icons.fact_check_outlined,
                            values: report.orderStatusCounts,
                            labeler: _orderStatusLabel,
                          ),
                          second: _StatusCard(
                            title: 'حالات الدفع',
                            icon: Icons.payments_outlined,
                            values: report.paymentStatusCounts,
                            labeler: _paymentStatusLabel,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _ResponsivePair(
                          first: _BranchPerformance(report: report),
                          second: _InventoryFinance(report: report),
                        ),
                        const SizedBox(height: 16),
                        _ProductsTable(report: report),
                        const SizedBox(height: 16),
                        _CustomersTable(report: report),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onMenu, required this.onExport});
  final VoidCallback onMenu;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.paddingOf(context).top + 12, 20, 22),
      decoration: const BoxDecoration(
        gradient:
            LinearGradient(colors: [Color(0xFF061A2D), Color(0xFF0E3659)]),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          MerchantDrawerButton(onPressed: onMenu),
          const Expanded(
            child: Text(
              'التقارير والتحليلات',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w900),
            ),
          ),
          IconButton(
            onPressed: onExport,
            icon: const Icon(Icons.ios_share_outlined,
                color: Colors.white, size: 28),
            tooltip: 'تصدير CSV',
          ),
        ],
      ),
    );
  }
}

class _FiltersBar extends StatelessWidget {
  const _FiltersBar({
    required this.period,
    required this.type,
    required this.onPeriodChanged,
    required this.onTypeChanged,
    required this.onCustomRange,
    this.from,
    this.to,
  });
  final String period;
  final String type;
  final DateTime? from;
  final DateTime? to;
  final ValueChanged<String> onPeriodChanged;
  final ValueChanged<String> onTypeChanged;
  final VoidCallback onCustomRange;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Choice(
                  text: 'اليوم',
                  selected: period == 'day',
                  onTap: () => onPeriodChanged('day')),
              _Choice(
                  text: 'الأسبوع',
                  selected: period == 'week',
                  onTap: () => onPeriodChanged('week')),
              _Choice(
                  text: 'الشهر',
                  selected: period == 'month',
                  onTap: () => onPeriodChanged('month')),
              _Choice(
                  text: 'السنة',
                  selected: period == 'year',
                  onTap: () => onPeriodChanged('year')),
              _Choice(
                  text: 'فترة مخصصة',
                  selected: period == 'custom',
                  onTap: onCustomRange),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Choice(
                  text: 'نظرة عامة',
                  selected: type == 'overview',
                  onTap: () => onTypeChanged('overview')),
              _Choice(
                  text: 'المبيعات',
                  selected: type == 'sales',
                  onTap: () => onTypeChanged('sales')),
              _Choice(
                  text: 'المنتجات',
                  selected: type == 'products',
                  onTap: () => onTypeChanged('products')),
              _Choice(
                  text: 'العملاء',
                  selected: type == 'customers',
                  onTap: () => onTypeChanged('customers')),
              _Choice(
                  text: 'المخزون',
                  selected: type == 'inventory',
                  onTap: () => onTypeChanged('inventory')),
              _Choice(
                  text: 'الأرباح',
                  selected: type == 'profit',
                  onTap: () => onTypeChanged('profit')),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'الفترة: ${_date(from)} - ${_date(to)}',
            style: const TextStyle(
                color: Color(0xFF536271), fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice(
      {required this.text, required this.selected, required this.onTap});
  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : const Color(0xFFF0F4F8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? AppColors.primary : const Color(0xFFDCE4EC)),
        ),
        child: Text(
          text,
          style: TextStyle(
              color: selected ? Colors.white : AppColors.primary,
              fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _Insights extends StatelessWidget {
  const _Insights({required this.insights});
  final List<MerchantReportInsight> insights;

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) return const SizedBox.shrink();
    return Column(
      children: insights
          .take(3)
          .map(
            (item) => Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _severityColor(item.severity).withValues(alpha: .10),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color:
                        _severityColor(item.severity).withValues(alpha: .28)),
              ),
              child: Row(
                children: [
                  Icon(_severityIcon(item.severity),
                      color: _severityColor(item.severity)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title,
                            style:
                                const TextStyle(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 3),
                        Text(item.message,
                            style: const TextStyle(color: Color(0xFF536271))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.report});
  final MerchantReportModel report;

  @override
  Widget build(BuildContext context) {
    final s = report.summary;
    final cards = [
      _Metric('إجمالي المبيعات', _money(s.totalSales, s.currency),
          Icons.trending_up_rounded),
      _Metric('صافي المستحقات', _money(s.netSales, s.currency),
          Icons.account_balance_wallet_outlined),
      _Metric('الطلبات', '${s.ordersCount}', Icons.shopping_bag_outlined),
      _Metric('متوسط الطلب', _money(s.averageOrderValue, s.currency),
          Icons.receipt_long_outlined),
      _Metric('نسبة الإكمال', '${s.completionRate.toStringAsFixed(1)}%',
          Icons.verified_outlined),
      _Metric('العملاء', '${s.customersCount}', Icons.groups_outlined),
      _Metric('عمولة المنصة', _money(s.commissionAmount, s.currency),
          Icons.percent_rounded),
      _Metric('المرتجعات', _money(s.refundsAmount, s.currency),
          Icons.assignment_return_outlined),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final count = width > 950
            ? 4
            : width > 620
                ? 3
                : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: width > 620 ? 2.1 : 1.45,
          ),
          itemBuilder: (_, index) => _MetricCard(metric: cards[index]),
        );
      },
    );
  }
}

class _Metric {
  final String title;
  final String value;
  final IconData icon;
  const _Metric(this.title, this.value, this.icon);
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});
  final _Metric metric;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                    color: const Color(0xFFFF7100).withValues(alpha: .11),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(metric.icon, color: const Color(0xFFFF7100)),
              ),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(metric.title,
                      style: const TextStyle(
                          color: Color(0xFF536271),
                          fontWeight: FontWeight.w800))),
            ],
          ),
          FittedBox(
            alignment: Alignment.centerRight,
            child: Text(metric.value,
                style: const TextStyle(
                    color: Color(0xFF082B51),
                    fontSize: 24,
                    fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

class _SalesCard extends StatelessWidget {
  const _SalesCard({required this.report});
  final MerchantReportModel report;

  @override
  Widget build(BuildContext context) {
    return _ReportCard(
      title: 'منحنى المبيعات اليومية',
      icon: Icons.show_chart_rounded,
      child: SizedBox(
        height: 245,
        child: report.salesSeries.isEmpty
            ? const Center(child: Text('لا توجد مبيعات مكتملة في هذه الفترة'))
            : CustomPaint(
                painter: _SalesChartPainter(report.salesSeries),
                child: const SizedBox.expand(),
              ),
      ),
    );
  }
}

class _SalesChartPainter extends CustomPainter {
  _SalesChartPainter(this.points);
  final List<MerchantSalesPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = const Color(0xFFE0E6EC)
      ..strokeWidth = 1;
    final line = Paint()
      ..color = const Color(0xFF082B51)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final fill = Paint()
      ..color = const Color(0xFF082B51).withValues(alpha: .08)
      ..style = PaintingStyle.fill;
    final dot = Paint()..color = const Color(0xFFFF7100);
    for (var i = 1; i <= 4; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final maxValue = points.map((e) => e.sales).fold<double>(0, math.max);
    final path = Path();
    final area = Path();
    for (var i = 0; i < points.length; i++) {
      final x = points.length == 1
          ? size.width / 2
          : i * size.width / (points.length - 1);
      final y = maxValue <= 0
          ? size.height - 8
          : size.height -
              12 -
              (points[i].sales / maxValue) * (size.height - 28);
      if (i == 0) {
        path.moveTo(x, y);
        area.moveTo(x, size.height);
        area.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        area.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 4, dot);
    }
    if (points.isNotEmpty) {
      area.lineTo(size.width, size.height);
      area.close();
      canvas.drawPath(area, fill);
      canvas.drawPath(path, line);
    }
  }

  @override
  bool shouldRepaint(covariant _SalesChartPainter oldDelegate) =>
      oldDelegate.points != points;
}

class _ResponsivePair extends StatelessWidget {
  const _ResponsivePair({required this.first, required this.second});
  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 720) {
          return Column(children: [first, const SizedBox(height: 16), second]);
        }
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: first),
          const SizedBox(width: 12),
          Expanded(child: second)
        ]);
      },
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard(
      {required this.title,
      required this.icon,
      required this.values,
      required this.labeler});
  final String title;
  final IconData icon;
  final Map<String, int> values;
  final String Function(String) labeler;

  @override
  Widget build(BuildContext context) {
    final total = values.values.fold<int>(0, (a, b) => a + b);
    return _ReportCard(
      title: title,
      icon: icon,
      child: values.isEmpty
          ? const Text('لا توجد بيانات لهذه الفترة')
          : Column(
              children: values.entries.map((entry) {
                final rate = total == 0 ? 0.0 : entry.value / total;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                          flex: 2,
                          child: Text(labeler(entry.key),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800))),
                      Expanded(
                        flex: 4,
                        child: LinearProgressIndicator(
                          value: rate,
                          minHeight: 9,
                          borderRadius: BorderRadius.circular(9),
                          color: _statusColor(entry.key),
                          backgroundColor: const Color(0xFFE8EDF2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${entry.value}',
                          style: const TextStyle(fontWeight: FontWeight.w900)),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _BranchPerformance extends StatelessWidget {
  const _BranchPerformance({required this.report});
  final MerchantReportModel report;

  @override
  Widget build(BuildContext context) {
    final maxSales =
        report.branchPerformance.map((e) => e.sales).fold<double>(0, math.max);
    return _ReportCard(
      title: 'أداء الفروع',
      icon: Icons.business_outlined,
      child: report.branchPerformance.isEmpty
          ? const Text('لا توجد مبيعات حسب الفروع')
          : Column(
              children: report.branchPerformance.take(8).map((branch) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                                child: Text(branch.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800))),
                            Text(_money(branch.sales, report.currency))
                          ]),
                      const SizedBox(height: 5),
                      LinearProgressIndicator(
                          value: maxSales == 0 ? 0 : branch.sales / maxSales,
                          minHeight: 10,
                          borderRadius: BorderRadius.circular(8),
                          color: AppColors.primary,
                          backgroundColor: const Color(0xFFE8EDF2)),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _InventoryFinance extends StatelessWidget {
  const _InventoryFinance({required this.report});
  final MerchantReportModel report;

  @override
  Widget build(BuildContext context) {
    final inv = report.inventory;
    final fin = report.finance;
    return _ReportCard(
      title: 'المخزون والأرباح',
      icon: Icons.analytics_outlined,
      child: Column(
        children: [
          _Line('قيمة المخزون', _money(inv.inventoryValue, report.currency)),
          _Line('الكمية المتاحة', '${inv.totalOnHand}'),
          _Line('المحجوزة', '${inv.totalReserved}'),
          _Line('منخفض المخزون', '${inv.lowStockProducts}'),
          const Divider(height: 22),
          _Line('إجمالي المقبوضات', _money(fin.grossSales, report.currency)),
          _Line('صافي المستحقات', _money(fin.netReceivable, report.currency)),
          _Line('قيد الانتظار', _money(fin.pendingAmount, report.currency)),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.title, this.value);
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(title),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900))
      ]),
    );
  }
}

class _ProductsTable extends StatelessWidget {
  const _ProductsTable({required this.report});
  final MerchantReportModel report;

  @override
  Widget build(BuildContext context) {
    return _ReportCard(
      title: 'أداء المنتجات',
      icon: Icons.inventory_2_outlined,
      child: report.productPerformance.isEmpty
          ? const Text('لا توجد منتجات مباعة في هذه الفترة')
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('المنتج')),
                  DataColumn(label: Text('المبيعات')),
                  DataColumn(label: Text('الوحدات')),
                  DataColumn(label: Text('الطلبات')),
                  DataColumn(label: Text('المخزون')),
                  DataColumn(label: Text('الحالة')),
                ],
                rows: report.productPerformance.take(12).map((item) {
                  return DataRow(cells: [
                    DataCell(SizedBox(
                        width: 220,
                        child:
                            Text(item.name, overflow: TextOverflow.ellipsis))),
                    DataCell(Text(_money(item.sales, report.currency))),
                    DataCell(Text('${item.unitsSold}')),
                    DataCell(Text('${item.ordersCount}')),
                    DataCell(Text('${item.availableQuantity}')),
                    DataCell(Text(_stockLabel(item.stockStatus))),
                  ]);
                }).toList(),
              ),
            ),
    );
  }
}

class _CustomersTable extends StatelessWidget {
  const _CustomersTable({required this.report});
  final MerchantReportModel report;

  @override
  Widget build(BuildContext context) {
    return _ReportCard(
      title: 'أفضل العملاء',
      icon: Icons.groups_outlined,
      child: report.customerPerformance.isEmpty
          ? const Text('لا توجد بيانات عملاء في هذه الفترة')
          : Column(
              children: report.customerPerformance.take(8).map((customer) {
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: .12),
                      child: const Icon(Icons.person_outline)),
                  title: Text(customer.name,
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                  subtitle: Text(
                      '${customer.ordersCount} طلب • آخر طلب: ${_date(customer.lastOrderAt)}'),
                  trailing: Text(_money(customer.sales, report.currency),
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                );
              }).toList(),
            ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard(
      {required this.title, required this.icon, required this.child});
  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(title,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w900))
          ]),
          const Divider(height: 24),
          child,
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0E6EC)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: .03),
              blurRadius: 16,
              offset: const Offset(0, 8))
        ],
      ),
      child: AppTileMaterial(
        borderRadius: BorderRadius.circular(18),
        child: child,
      ),
    );
  }
}

class _StateView extends StatelessWidget {
  const _StateView(
      {required this.icon,
      required this.title,
      required this.message,
      this.actionText,
      this.onAction});
  final IconData icon;
  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(title,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF536271))),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(actionText!)),
            ],
          ],
        ),
      ),
    );
  }
}

String _money(double value, String currency) {
  final rounded = value
      .round()
      .toString()
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
  return '$rounded $currency';
}

String _date(DateTime? date) {
  if (date == null) return '-';
  return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
}

String _orderStatusLabel(String value) {
  const labels = {
    'PENDING': 'جديد',
    'CONFIRMED': 'مقبول',
    'PREPARING': 'قيد التجهيز',
    'READY_FOR_PICKUP': 'جاهز للاستلام',
    'OUT_FOR_DELIVERY': 'قيد التوصيل',
    'COMPLETED': 'مكتمل',
    'CANCELLED': 'ملغي',
    'REJECTED': 'مرفوض',
    'RETURNED': 'مرتجع',
  };
  return labels[value] ?? value;
}

String _paymentStatusLabel(String value) {
  const labels = {
    'UNPAID': 'غير مدفوع',
    'PENDING': 'قيد المراجعة',
    'PAID': 'مدفوع',
    'FAILED': 'فشل',
    'REFUNDED': 'مسترد',
  };
  return labels[value] ?? value;
}

String _stockLabel(String value) {
  const labels = {
    'OUT_OF_STOCK': 'نافد',
    'LOW_STOCK': 'منخفض',
    'IN_STOCK': 'متوفر',
    'OVERSTOCK': 'زائد',
    'UNKNOWN': 'غير محدد',
  };
  return labels[value] ?? value;
}

Color _statusColor(String value) {
  if (['COMPLETED', 'PAID', 'IN_STOCK'].contains(value))
    return const Color(0xFF0A8F5A);
  if (['PENDING', 'PREPARING', 'UNPAID'].contains(value))
    return const Color(0xFFFF9800);
  if (['CANCELLED', 'REJECTED', 'FAILED', 'OUT_OF_STOCK'].contains(value))
    return const Color(0xFFD32F2F);
  return AppColors.primary;
}

Color _severityColor(String value) {
  switch (value) {
    case 'warning':
      return const Color(0xFFFF9800);
    case 'danger':
      return const Color(0xFFD32F2F);
    case 'success':
      return const Color(0xFF0A8F5A);
    default:
      return AppColors.primary;
  }
}

IconData _severityIcon(String value) {
  switch (value) {
    case 'warning':
      return Icons.warning_amber_rounded;
    case 'danger':
      return Icons.error_outline;
    case 'success':
      return Icons.check_circle_outline;
    default:
      return Icons.tips_and_updates_outlined;
  }
}
