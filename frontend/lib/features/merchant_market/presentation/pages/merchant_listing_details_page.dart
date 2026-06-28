import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/features/merchant_market/data/merchant_market_repository.dart';
import 'package:ghiyarak/features/merchant_market/data/models/merchant_listing_model.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_bottom_navigation.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_drawer.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_page_header.dart';
import 'package:go_router/go_router.dart';

class MerchantListingDetailsPage extends ConsumerStatefulWidget {
  const MerchantListingDetailsPage({super.key, required this.listingId});

  final String listingId;

  @override
  ConsumerState<MerchantListingDetailsPage> createState() =>
      _MerchantListingDetailsPageState();
}

class _MerchantListingDetailsPageState
    extends ConsumerState<MerchantListingDetailsPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final listing = ref.watch(_listingDetailsProvider(widget.listingId));
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF4F6F8),
        drawer:
            const MerchantDrawer(currentTab: MerchantNavigationTab.products),
        bottomNavigationBar: const MerchantBottomNavigation(
          currentTab: MerchantNavigationTab.products,
          compact: true,
        ),
        body: SafeArea(
          top: false,
          child: listing.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _StateView(
              icon: Icons.cloud_off_outlined,
              title: 'تعذر تحميل المنتج',
              message: error.toString(),
              actionLabel: 'إعادة المحاولة',
              onAction: () =>
                  ref.invalidate(_listingDetailsProvider(widget.listingId)),
            ),
            data: (item) => CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: MerchantPageHeader(
                    title: 'تفاصيل المنتج',
                    subtitle: item.title,
                    onMenu: () => _scaffoldKey.currentState?.openDrawer(),
                    notificationCount: 0,
                    onNotifications: () =>
                        context.go(RouteNames.merchantNotifications),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 104),
                  sliver: SliverList.list(
                    children: [
                      _HeroCard(item: item),
                      const SizedBox(height: 12),
                      if (item.imageUrls.length > 1) ...[
                        _GalleryCard(images: item.imageUrls),
                        const SizedBox(height: 12),
                      ],
                      _MetricsCard(item: item),
                      const SizedBox(height: 12),
                      _InfoCard(item: item),
                      const SizedBox(height: 12),
                      _OperationsCard(item: item),
                      const SizedBox(height: 12),
                      _ActionsCard(item: item),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final _listingDetailsProvider =
    FutureProvider.family<MerchantListingModel, String>((ref, id) async {
  final items =
      await ref.read(merchantMarketRepositoryProvider).getMyListings();
  return items.firstWhere((item) => item.id == id);
});

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.item});
  final MerchantListingModel item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _decoration,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ImageBox(url: item.imageUrl, width: 100, height: 116),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF082B51),
                  ),
                ),
                const SizedBox(height: 6),
                Text('SKU: ${item.sku ?? '-'}',
                    style: const TextStyle(color: Color(0xFF6D7D8F))),
                Text('رقم القطعة: ${item.partNumber ?? '-'}',
                    style: const TextStyle(color: Color(0xFF6D7D8F))),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Pill(label: _statusLabel(item), color: _statusColor(item)),
                    _Pill(
                        label: _approvalLabel(item),
                        color: _approvalColor(item)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GalleryCard extends StatelessWidget {
  const _GalleryCard({required this.images});
  final List<String> images;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _decoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('صور المنتج',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          SizedBox(
            height: 86,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (_, index) =>
                  _ImageBox(url: images[index], width: 88, height: 86),
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemCount: images.length,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricsCard extends StatelessWidget {
  const _MetricsCard({required this.item});
  final MerchantListingModel item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _decoration,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: _Metric(
                      title: 'السعر',
                      value:
                          '${item.price.toStringAsFixed(2)} ${item.currency}')),
              Expanded(
                  child: _Metric(
                      title: 'التخفيض',
                      value: item.salePrice == null
                          ? '-'
                          : '${item.salePrice!.toStringAsFixed(2)} ${item.currency}')),
              Expanded(
                  child:
                      _Metric(title: 'المخزون', value: '${item.stock} قطعة')),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                  child:
                      _Metric(title: 'محجوز', value: '${item.reservedStock}')),
              Expanded(
                  child: _Metric(
                      title: 'أقل طلب', value: '${item.minOrderQuantity}')),
              Expanded(
                  child: _Metric(
                      title: 'الضمان',
                      value: item.warrantyDays == null
                          ? '-'
                          : '${item.warrantyDays} يوم')),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.item});
  final MerchantListingModel item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _decoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('معلومات المنتج',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          const Divider(height: 22),
          _Line(label: 'الفئة', value: item.categoryName ?? '-'),
          _Line(label: 'العلامة', value: item.partBrandName ?? '-'),
          _Line(label: 'الفرع', value: item.branchName ?? '-'),
          _Line(label: 'المدينة', value: item.cityName ?? '-'),
          _Line(label: 'حالة القطعة', value: _conditionLabel(item.condition)),
          _Line(label: 'حالة الموافقة', value: _approvalLabel(item)),
          if ((item.approvalRejectionReason ?? '').isNotEmpty)
            _Line(label: 'سبب الرفض', value: item.approvalRejectionReason!),
          _Line(
              label: 'التوافق',
              value: item.compatibility ?? 'لم يحدد توافق السيارات'),
          _Line(label: 'الوصف', value: item.description ?? '-'),
        ],
      ),
    );
  }
}

class _OperationsCard extends StatelessWidget {
  const _OperationsCard({required this.item});
  final MerchantListingModel item;

  @override
  Widget build(BuildContext context) {
    final pickup = item.supportsPickup ? 'مفعّل' : 'غير مفعّل';
    final delivery = item.supportsDelivery ? 'مفعّل' : 'غير مفعّل';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _decoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('خيارات البيع والتشغيل',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          const Divider(height: 22),
          _Line(label: 'الاستلام', value: pickup),
          _Line(label: 'التوصيل', value: delivery),
          _Line(label: 'تاريخ النشر', value: _dateText(item.publishedAt)),
          _Line(label: 'آخر تحديث', value: _dateText(item.updatedAt)),
        ],
      ),
    );
  }
}

class _ActionsCard extends ConsumerWidget {
  const _ActionsCard({required this.item});
  final MerchantListingModel item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> change(String status) async {
      final confirmed = status == 'ARCHIVED'
          ? await showDialog<bool>(
              context: context,
              builder: (context) => Directionality(
                textDirection: TextDirection.rtl,
                child: AlertDialog(
                  title: const Text('تأكيد الأرشفة'),
                  content: const Text(
                      'سيتم إخفاء المنتج من المتجر. يمكن إعادته للنشر لاحقًا.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('إلغاء')),
                    FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('أرشفة')),
                  ],
                ),
              ),
            )
          : true;
      if (confirmed != true) return;
      try {
        await ref.read(merchantMarketRepositoryProvider).updateListingStatus(
              listingId: item.id,
              status: status,
            );
        ref.invalidate(_listingDetailsProvider(item.id));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم تحديث حالة المنتج')));
        }
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('تعذر تحديث الحالة: $error')));
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _decoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('إجراءات المنتج',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: () =>
                    context.go(RouteNames.editMerchantListing(item.id)),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('تعديل المنتج'),
              ),
              OutlinedButton.icon(
                onPressed: () => change('ACTIVE'),
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('نشر'),
              ),
              OutlinedButton.icon(
                onPressed: () => change('PAUSED'),
                icon: const Icon(Icons.pause_circle_outline),
                label: const Text('إيقاف مؤقت'),
              ),
              OutlinedButton.icon(
                onPressed: () => change('ARCHIVED'),
                icon: const Icon(Icons.archive_outlined),
                label: const Text('أرشفة'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ImageBox extends StatelessWidget {
  const _ImageBox(
      {required this.url, required this.width, required this.height});
  final String? url;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFE9EEF3),
        borderRadius: BorderRadius.circular(14),
      ),
      child: (url ?? '').isEmpty
          ? const Icon(Icons.settings_outlined,
              size: 44, color: Color(0xFF8291A0))
          : Image.network(
              url!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.settings_outlined,
                  size: 44, color: Color(0xFF8291A0)),
            ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.title, required this.value});
  final String title;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(color: Color(0xFF7B8794), fontSize: 12)),
          const SizedBox(height: 5),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontWeight: FontWeight.w900, color: Color(0xFF082B51))),
        ],
      );
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 110,
                child: Text(label,
                    style: const TextStyle(color: Color(0xFF7B8794)))),
            Expanded(
                child: Text(value,
                    style: const TextStyle(fontWeight: FontWeight.w800))),
          ],
        ),
      );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: color.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(999)),
        child: Text(label,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w900, fontSize: 12)),
      );
}

class _StateView extends StatelessWidget {
  const _StateView(
      {required this.icon,
      required this.title,
      required this.message,
      required this.actionLabel,
      required this.onAction});
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: const Color(0xFF8291A0)),
              const SizedBox(height: 12),
              Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF6B7C93))),
              const SizedBox(height: 14),
              FilledButton(onPressed: onAction, child: Text(actionLabel)),
            ],
          ),
        ),
      );
}

String _statusLabel(MerchantListingModel item) {
  final status = item.status.toUpperCase();
  if (status == 'ACTIVE') return 'منشور';
  if (status == 'PAUSED') return 'متوقف مؤقتاً';
  if (status == 'ARCHIVED') return 'مؤرشف';
  if (item.stock <= 0) return 'نفد المخزون';
  return 'مسودة';
}

Color _statusColor(MerchantListingModel item) {
  final status = item.status.toUpperCase();
  if (status == 'ACTIVE') return const Color(0xFF16A34A);
  if (status == 'PAUSED') return const Color(0xFFF59E0B);
  if (status == 'ARCHIVED') return const Color(0xFF64748B);
  if (item.stock <= 0) return const Color(0xFFE43B45);
  return const Color(0xFF268FC0);
}

String _approvalLabel(MerchantListingModel item) {
  final approval = item.approvalStatus.toUpperCase();
  if (approval.contains('PENDING')) return 'قيد المراجعة';
  if (approval.contains('REJECT')) return 'مرفوض';
  if (approval.contains('APPROVED')) return 'مقبول';
  return item.approvalStatus.isEmpty ? 'غير محدد' : item.approvalStatus;
}

Color _approvalColor(MerchantListingModel item) {
  final approval = item.approvalStatus.toUpperCase();
  if (approval.contains('PENDING')) return const Color(0xFF268FC0);
  if (approval.contains('REJECT')) return const Color(0xFFE43B45);
  return const Color(0xFF16A34A);
}

String _conditionLabel(String value) {
  switch (value.toUpperCase()) {
    case 'USED':
      return 'مستعملة';
    case 'REFURBISHED':
      return 'مجددة';
    default:
      return 'جديدة';
  }
}

String _dateText(DateTime? value) {
  if (value == null) return '-';
  return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}

final _decoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: const Color(0xFFE0E6EC)),
  boxShadow: const [
    BoxShadow(color: Color(0x10071D33), blurRadius: 14, offset: Offset(0, 5))
  ],
);
