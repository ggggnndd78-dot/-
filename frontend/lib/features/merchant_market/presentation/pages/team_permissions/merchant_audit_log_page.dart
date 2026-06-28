import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/features/merchant_market/data/merchant_market_repository.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_management_scaffold.dart';

class MerchantAuditLogPage extends ConsumerStatefulWidget {
  const MerchantAuditLogPage({super.key});

  @override
  ConsumerState<MerchantAuditLogPage> createState() =>
      _MerchantAuditLogPageState();
}

class _MerchantAuditLogPageState extends ConsumerState<MerchantAuditLogPage> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() {
    return ref.read(merchantMarketRepositoryProvider).getAuditLogs();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        return MerchantManagementScaffold(
          title: 'سجل النشاط',
          subtitle: 'تتبع العمليات الحساسة مثل تعديل الأسعار والمخزون',
          onRefresh: () async => setState(() => _future = _load()),
          children: [
            if (snapshot.connectionState != ConnectionState.done)
              const Center(child: CircularProgressIndicator())
            else if (snapshot.hasError)
              MerchantStateCard(
                icon: Icons.lock_outline,
                title: 'تعذر تحميل سجل النشاط',
                message:
                    'قد تحتاج هذه الصفحة صلاحية إدارية أعلى. التفاصيل: ${snapshot.error}',
                actionLabel: 'إعادة المحاولة',
                onAction: () => setState(() => _future = _load()),
              )
            else if (snapshot.requireData.isEmpty)
              const MerchantStateCard(
                icon: Icons.history_toggle_off_outlined,
                title: 'لا توجد عمليات مسجلة',
                message:
                    'عند تنفيذ عمليات حساسة ستظهر هنا حسب إعدادات التدقيق في الباك اند.',
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: MerchantMetricTile(
                      icon: Icons.receipt_long_outlined,
                      label: 'آخر السجلات',
                      value: '${snapshot.requireData.length}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ...snapshot.requireData.map(_AuditCard.new),
            ],
          ],
        );
      },
    );
  }
}

class _AuditCard extends StatelessWidget {
  const _AuditCard(this.item);

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final action =
        (item['action_code'] ?? item['actionCode'] ?? item['action'] ?? 'عملية')
            .toString();
    final entity =
        (item['entity_type'] ?? item['entityType'] ?? item['entity'] ?? '')
            .toString();
    final actor = (item['actor_name'] ??
            item['actorName'] ??
            item['username'] ??
            item['actor_user_id'] ??
            '')
        .toString();
    final date =
        (item['created_at'] ?? item['createdAt'] ?? item['processed_at'] ?? '')
            .toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MerchantPanel(
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.manage_history, color: Color(0xFFFF7900)),
          title: Text(
            action,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          subtitle: Text(
            [
              if (entity.isNotEmpty) entity,
              if (actor.isNotEmpty) 'بواسطة: $actor',
              if (date.isNotEmpty) date,
            ].join('\n'),
          ),
        ),
      ),
    );
  }
}
