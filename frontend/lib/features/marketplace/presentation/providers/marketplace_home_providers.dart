import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/storage/local_storage_service.dart';
import 'package:ghiyarak/features/marketplace/data/marketplace_repository.dart';
import 'package:ghiyarak/features/marketplace/data/models/catalog_category.dart';
import 'package:ghiyarak/features/marketplace/data/models/customer_home_model.dart';
import 'package:ghiyarak/features/marketplace/data/models/listing_summary.dart';

final marketplacePreferenceVersionProvider = StateProvider<int>((ref) => 0);

final marketplaceCustomerHomeProvider =
    FutureProvider.autoDispose<CustomerHomeData>((ref) async {
  ref.watch(marketplacePreferenceVersionProvider);
  return ref.read(marketplaceRepositoryProvider).getCustomerHome();
});

final marketplaceCategoriesProvider = FutureProvider<List<CatalogCategory>>(
  (ref) async {
    final repo = ref.read(marketplaceRepositoryProvider);
    return repo.getCategories();
  },
);

final selectedMarketplaceVehicleProvider =
    FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  ref.watch(marketplacePreferenceVersionProvider);
  return ref.read(localStorageServiceProvider).getSelectedVehicle();
});

final selectedMarketplaceLocationProvider =
    FutureProvider.autoDispose<Map<String, String>>((ref) async {
  ref.watch(marketplacePreferenceVersionProvider);
  final local = ref.read(localStorageServiceProvider);
  return {
    'city': await local.getSelectedCity(),
    'district': await local.getSelectedDistrict(),
  };
});

final marketplaceFeaturedListingsProvider =
    FutureProvider.autoDispose<List<ListingSummary>>((ref) async {
  ref.watch(marketplacePreferenceVersionProvider);
  final repo = ref.read(marketplaceRepositoryProvider);
  final listings = await repo.searchListings();
  return listings;
});
