import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/features/merchant_market/data/merchant_market_repository.dart';
import 'package:ghiyarak/features/merchant_market/data/models/merchant_listing_model.dart';
import 'package:ghiyarak/features/merchant_market/presentation/widgets/merchant_management_scaffold.dart';

class MerchantCompatibilityManagerPage extends ConsumerStatefulWidget {
  const MerchantCompatibilityManagerPage({super.key});

  @override
  ConsumerState<MerchantCompatibilityManagerPage> createState() =>
      _MerchantCompatibilityManagerPageState();
}

class _MerchantCompatibilityManagerPageState
    extends ConsumerState<MerchantCompatibilityManagerPage> {
  late Future<_CompatibilityState> _future;
  String? _selectedMakeId;
  List<MerchantLookupItem> _models = const [];
  bool _loadingModels = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_CompatibilityState> _load() async {
    final repo = ref.read(merchantMarketRepositoryProvider);
    final results = await Future.wait<dynamic>([
      repo.getMyListings(),
      repo.getVehicleMakes(),
    ]);
    return _CompatibilityState(
      listings: results[0] as List<MerchantListingModel>,
      makes: results[1] as List<MerchantLookupItem>,
    );
  }

  Future<void> _loadModels(String makeId) async {
    setState(() {
      _selectedMakeId = makeId;
      _loadingModels = true;
      _models = const [];
    });
    try {
      final data = await ref
          .read(merchantMarketRepositoryProvider)
          .getVehicleModels(makeId);
      if (mounted) setState(() => _models = data);
    } finally {
      if (mounted) setState(() => _loadingModels = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_CompatibilityState>(
      future: _future,
      builder: (context, snapshot) {
        return MerchantManagementScaffold(
          title: 'توافق القطع',
          subtitle: 'مراجعة توافق المنتجات مع السيارات لتحسين نتائج العملاء',
          onRefresh: () async => setState(() => _future = _load()),
          children: [
            if (snapshot.connectionState != ConnectionState.done)
              const Center(child: CircularProgressIndicator())
            else if (snapshot.hasError)
              MerchantStateCard(
                icon: Icons.error_outline,
                title: 'تعذر تحميل التوافق',
                message: snapshot.error.toString(),
                actionLabel: 'إعادة المحاولة',
                onAction: () => setState(() => _future = _load()),
              )
            else
              _CompatibilityContent(
                state: snapshot.requireData,
                selectedMakeId: _selectedMakeId,
                models: _models,
                loadingModels: _loadingModels,
                onMakeSelected: _loadModels,
              ),
          ],
        );
      },
    );
  }
}

class _CompatibilityContent extends StatelessWidget {
  const _CompatibilityContent({
    required this.state,
    required this.selectedMakeId,
    required this.models,
    required this.loadingModels,
    required this.onMakeSelected,
  });

  final _CompatibilityState state;
  final String? selectedMakeId;
  final List<MerchantLookupItem> models;
  final bool loadingModels;
  final ValueChanged<String> onMakeSelected;

  @override
  Widget build(BuildContext context) {
    final compatible = state.listings
        .where((item) => (item.compatibility ?? '').trim().isNotEmpty)
        .toList();
    final missing = state.listings
        .where((item) => (item.compatibility ?? '').trim().isEmpty)
        .toList();
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: MerchantMetricTile(
                icon: Icons.check_circle_outline,
                label: 'لديها توافق',
                value: '${compatible.length}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MerchantMetricTile(
                icon: Icons.report_problem_outlined,
                label: 'تحتاج توافق',
                value: '${missing.length}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        MerchantPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'مرجع السيارات',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: selectedMakeId,
                decoration: const InputDecoration(labelText: 'شركة السيارة'),
                items: state.makes
                    .map((make) => DropdownMenuItem(
                          value: make.id,
                          child: Text(make.name),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) onMakeSelected(value);
                },
              ),
              if (loadingModels) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(),
              ] else if (models.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: models
                      .map((model) => Chip(label: Text(model.name)))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (missing.isEmpty)
          const MerchantStateCard(
            icon: Icons.verified_outlined,
            title: 'كل المنتجات لديها نص توافق',
            message:
                'استمر في إضافة توافق دقيق عند إنشاء المنتجات الجديدة لرفع جودة البحث.',
          )
        else
          ...missing.map((item) => _ListingCompatibilityCard(item: item)),
      ],
    );
  }
}

class _ListingCompatibilityCard extends StatelessWidget {
  const _ListingCompatibilityCard({required this.item});

  final MerchantListingModel item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MerchantPanel(
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading:
              const Icon(Icons.car_repair_outlined, color: Color(0xFFFF7900)),
          title: Text(item.title,
              style: const TextStyle(fontWeight: FontWeight.w900)),
          subtitle: Text(
            [
              if ((item.partNumber ?? '').isNotEmpty)
                'رقم القطعة: ${item.partNumber}',
              'لا يوجد نص توافق ظاهر من الخادم',
            ].join('\n'),
          ),
        ),
      ),
    );
  }
}

class _CompatibilityState {
  const _CompatibilityState({required this.listings, required this.makes});

  final List<MerchantListingModel> listings;
  final List<MerchantLookupItem> makes;
}
