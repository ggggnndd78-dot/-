import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/theme/app_spacing.dart';
import 'package:ghiyarak/features/merchant/data/merchant_market_repository.dart';
import 'package:ghiyarak/features/merchant/data/models/merchant_listing_model.dart';
import 'package:ghiyarak/shared/widgets/app_scaffold.dart';

class MerchantListingsPage extends ConsumerWidget {
  const MerchantListingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final future = ref.watch(_provider);

    return AppScaffold(
      title: 'عروضي',
      child: future.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text('لا توجد عروض حتى الآن'),
            );
          }

          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final item = items[index];

              return Card(
                child: ListTile(
                  title: Text(item.title),
                  subtitle: Text(
                    'الحالة: ${item.status}\nالمخزون: ${item.stock}',
                  ),
                  trailing: Text(
                    '${item.price.toStringAsFixed(0)} YER',
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('تعذر تحميل العروض: $e'),
        ),
      ),
    );
  }
}

final _provider = FutureProvider<List<MerchantListingModel>>(
  (ref) => ref.read(merchantMarketRepositoryProvider).getMyListings(),
);
