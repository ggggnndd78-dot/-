import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/features/merchant_market/data/merchant_market_repository.dart';
import 'package:ghiyarak/features/merchant_market/data/models/merchant_listing_model.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_management_scaffold.dart';

class MerchantDataQualityPage extends ConsumerStatefulWidget {
  const MerchantDataQualityPage({super.key});

  @override
  ConsumerState<MerchantDataQualityPage> createState() =>
      _MerchantDataQualityPageState();
}

class _MerchantDataQualityPageState
    extends ConsumerState<MerchantDataQualityPage> {
  late Future<List<MerchantListingModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<MerchantListingModel>> _load() {
    return ref.read(merchantMarketRepositoryProvider).getMyListings();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MerchantListingModel>>(
      future: _future,
      builder: (context, snapshot) {
        return MerchantManagementScaffold(
          title: 'جودة بيانات المنتجات',
          subtitle: 'اكتشاف المنتجات الناقصة قبل أن تؤثر على البيع والبحث',
          onRefresh: () async => setState(() => _future = _load()),
          children: [
            if (snapshot.connectionState != ConnectionState.done)
              const Center(child: CircularProgressIndicator())
            else if (snapshot.hasError)
              MerchantStateCard(
                icon: Icons.error_outline,
                title: 'تعذر تحليل المنتجات',
                message: snapshot.error.toString(),
                actionLabel: 'إعادة المحاولة',
                onAction: () => setState(() => _future = _load()),
              )
            else
              _QualityContent(items: snapshot.requireData),
          ],
        );
      },
    );
  }
}

class _QualityContent extends StatelessWidget {
  const _QualityContent({required this.items});

  final List<MerchantListingModel> items;

  @override
  Widget build(BuildContext context) {
    final issues = <_QualityIssue>[];
    for (final item in items) {
      final itemIssues = <String>[];
      if ((item.imageUrl ?? '').isEmpty) itemIssues.add('بدون صورة');
      if ((item.compatibility ?? '').trim().isEmpty) {
        itemIssues.add('بدون توافق');
      }
      if ((item.partNumber ?? '').trim().isEmpty) {
        itemIssues.add('بدون رقم قطعة');
      }
      if (item.price <= 0) itemIssues.add('سعر غير مكتمل');
      if (item.stock <= 0) itemIssues.add('مخزون غير متوفر');
      if (itemIssues.isNotEmpty) {
        issues.add(_QualityIssue(item: item, issues: itemIssues));
      }
    }
    final score = items.isEmpty
        ? 0
        : (((items.length - issues.length) / items.length) * 100).round();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: MerchantMetricTile(
                icon: Icons.speed_outlined,
                label: 'مؤشر الجودة',
                value: '$score%',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MerchantMetricTile(
                icon: Icons.bug_report_outlined,
                label: 'منتجات تحتاج مراجعة',
                value: '${issues.length}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (items.isEmpty)
          const MerchantStateCard(
            icon: Icons.inventory_2_outlined,
            title: 'لا توجد منتجات',
            message: 'أضف منتجات ليبدأ النظام بتحليل جودة البيانات.',
          )
        else if (issues.isEmpty)
          const MerchantStateCard(
            icon: Icons.verified_outlined,
            title: 'بيانات المنتجات مكتملة',
            message:
                'لا توجد مشاكل ظاهرة من البيانات الحالية القادمة من الخادم.',
          )
        else
          ...issues.map(_QualityIssueCard.new),
      ],
    );
  }
}

class _QualityIssueCard extends StatelessWidget {
  const _QualityIssueCard(this.issue);

  final _QualityIssue issue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MerchantPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              issue.item.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  issue.issues.map((item) => Chip(label: Text(item))).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _QualityIssue {
  const _QualityIssue({required this.item, required this.issues});

  final MerchantListingModel item;
  final List<String> issues;
}
