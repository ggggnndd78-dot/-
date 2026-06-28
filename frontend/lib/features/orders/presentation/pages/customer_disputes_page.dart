import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/core/navigation/app_navigation.dart';
import 'package:ghiyarak/features/orders/data/models/customer_dispute_model.dart';
import 'package:ghiyarak/features/orders/data/orders_repository.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';

final _myDisputesProvider = FutureProvider<List<CustomerDisputeModel>>((ref) {
  return ref.watch(ordersRepositoryProvider).getMyDisputes();
});

class CustomerDisputesPage extends ConsumerStatefulWidget {
  const CustomerDisputesPage({super.key});

  @override
  ConsumerState<CustomerDisputesPage> createState() =>
      _CustomerDisputesPageState();
}

class _CustomerDisputesPageState extends ConsumerState<CustomerDisputesPage> {
  String _filter = 'ALL';
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_myDisputesProvider);
    return AppScaffold(
      title: 'النزاعات والشكاوى',
      child: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _StateCard(
            title: 'تعذر تحميل النزاعات',
            message: error.toString(),
            onRetry: () => ref.invalidate(_myDisputesProvider)),
        data: (items) {
          final filtered = _filterItems(items);
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(_myDisputesProvider);
              await ref.read(_myDisputesProvider.future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                _SummaryCard(items: items),
                const SizedBox(height: 12),
                TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'بحث برقم الطلب أو المتجر أو سبب النزاع',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _filter,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'تصفية النزاعات',
                    prefixIcon: Icon(Icons.filter_list_rounded),
                    border: OutlineInputBorder(),
                  ),
                  items: const {
                    'ALL': 'الكل',
                    'OPEN': 'مفتوحة',
                    'UNDER_REVIEW': 'قيد المراجعة',
                    'RESOLVED': 'محلولة',
                    'REJECTED': 'مرفوضة',
                  }
                      .entries
                      .map((e) => DropdownMenuItem<String>(
                            value: e.key,
                            child: Text(e.value),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _filter = value);
                  },
                ),
                const SizedBox(height: 12),
                if (filtered.isEmpty)
                  const _EmptyDisputesCard()
                else
                  ...filtered.map((item) => _DisputeTile(item: item)),
              ],
            ),
          );
        },
      ),
    );
  }

  List<CustomerDisputeModel> _filterItems(List<CustomerDisputeModel> items) {
    final q = _search.text.trim().toLowerCase();
    return items.where((item) {
      final statusOk = _filter == 'ALL' || item.status.toUpperCase() == _filter;
      final text =
          '${item.orderNumber} ${item.organizationName} ${item.reasonCode} ${item.description}'
              .toLowerCase();
      final searchOk = q.isEmpty || text.contains(q);
      return statusOk && searchOk;
    }).toList();
  }
}

class _SummaryCard extends StatelessWidget {
  final List<CustomerDisputeModel> items;
  const _SummaryCard({required this.items});
  @override
  Widget build(BuildContext context) {
    final open = items.where((e) => e.status == 'OPEN').length;
    final review = items.where((e) => e.status == 'UNDER_REVIEW').length;
    final closed = items
        .where((e) => ['RESOLVED', 'REJECTED', 'CLOSED'].contains(e.status))
        .length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Expanded(child: _Metric(label: 'الإجمالي', value: '${items.length}')),
          Expanded(child: _Metric(label: 'مفتوحة', value: '$open')),
          Expanded(child: _Metric(label: 'مراجعة', value: '$review')),
          Expanded(child: _Metric(label: 'مغلقة', value: '$closed')),
        ]),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  const _Metric({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(children: [
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        Text(label)
      ]);
}

class _DisputeTile extends StatelessWidget {
  final CustomerDisputeModel item;
  const _DisputeTile({required this.item});
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.gavel_outlined)),
        title: Text(item.subject.isEmpty
            ? 'نزاع على الطلب ${item.orderNumber}'
            : item.subject),
        subtitle: Text(
            '${item.organizationName} • ${item.statusLabel}\n${item.description}',
            maxLines: 3,
            overflow: TextOverflow.ellipsis),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_left),
        onTap: () => context
            .pushPath('${RouteNames.customerDisputeDetail}/${item.publicId}'),
      ),
    );
  }
}

class _EmptyDisputesCard extends StatelessWidget {
  const _EmptyDisputesCard();
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: const [
            Icon(Icons.verified_user_outlined, size: 48),
            SizedBox(height: 10),
            Text('لا توجد نزاعات مطابقة',
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text(
                'يمكنك فتح نزاع من صفحة تفاصيل الطلب عند وجود مشكلة تحتاج مراجعة.'),
          ]),
        ),
      );
}

class _StateCard extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;
  const _StateCard(
      {required this.title, required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
          child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton(
              onPressed: onRetry, child: const Text('إعادة المحاولة')),
        ]),
      ));
}
