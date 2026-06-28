import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/features/admin/data/admin_repository.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';
import 'package:go_router/go_router.dart';

class AdminOrdersPage extends ConsumerStatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  ConsumerState<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends ConsumerState<AdminOrdersPage> {
  String _status = 'ALL';
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(adminRepositoryProvider).orders();
  }

  void _reload() {
    setState(() {
      _future = ref
          .read(adminRepositoryProvider)
          .orders(status: _status == 'ALL' ? null : _status);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'ط¥ط¯ط§ط±ط© ط§ظ„ط·ظ„ط¨ط§طھ',
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            initialValue: _status,
            decoration: const InputDecoration(
                labelText: 'ظپظ„طھط±ط© ط­ط³ط¨ ط§ظ„ط­ط§ظ„ط©'),
            items: const [
              DropdownMenuItem(
                  value: 'ALL', child: Text('ظƒظ„ ط§ظ„ط­ط§ظ„ط§طھ')),
              DropdownMenuItem(value: 'PENDING', child: Text('PENDING')),
              DropdownMenuItem(value: 'CONFIRMED', child: Text('CONFIRMED')),
              DropdownMenuItem(value: 'PROCESSING', child: Text('PROCESSING')),
              DropdownMenuItem(
                  value: 'READY_FOR_PICKUP', child: Text('READY_FOR_PICKUP')),
              DropdownMenuItem(
                  value: 'OUT_FOR_DELIVERY', child: Text('OUT_FOR_DELIVERY')),
              DropdownMenuItem(value: 'DELIVERED', child: Text('DELIVERED')),
              DropdownMenuItem(value: 'CANCELLED', child: Text('CANCELLED')),
              DropdownMenuItem(
                  value: 'RETURN_REQUESTED', child: Text('RETURN_REQUESTED')),
              DropdownMenuItem(value: 'REFUNDED', child: Text('REFUNDED')),
            ],
            onChanged: (value) {
              _status = value ?? 'ALL';
              _reload();
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                        'طھط¹ط°ط± طھط­ظ…ظٹظ„ ط§ظ„ط·ظ„ط¨ط§طھ: ${snapshot.error}'),
                  );
                }
                final orders = snapshot.data ?? const [];
                if (orders.isEmpty) {
                  return const Center(child: Text('ظ„ط§ طھظˆط¬ط¯ ط·ظ„ط¨ط§طھ'));
                }
                return ListView.separated(
                  itemCount: orders.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final map = Map<String, dynamic>.from(orders[index] as Map);
                    final customer = map['user'] is Map
                        ? Map<String, dynamic>.from(map['user'] as Map)
                        : const <String, dynamic>{};
                    final org = map['organization'] is Map
                        ? Map<String, dynamic>.from(map['organization'] as Map)
                        : const <String, dynamic>{};
                    final id = (map['id'] ?? '').toString();
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: id.isEmpty
                            ? null
                            : () =>
                                context.push(RouteNames.adminOrderDetails(id)),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (map['orderNumber'] ??
                                        map['order_number'] ??
                                        map['id'])
                                    .toString(),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text('ط§ظ„ط­ط§ظ„ط©: ${map['status']}'),
                              Text(
                                'ط§ظ„ط¹ظ…ظٹظ„: ${customer['displayName'] ?? customer['phoneNormalized'] ?? '-'}',
                              ),
                              Text(
                                'ط§ظ„ظ…ط¤ط³ط³ط©: ${org['displayName'] ?? org['display_name'] ?? '-'}',
                              ),
                              Text(
                                'ط§ظ„ط¥ط¬ظ…ط§ظ„ظٹ: ${map['totalAmount'] ?? map['total_amount'] ?? 0} ${map['currency'] ?? 'YER'}',
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
