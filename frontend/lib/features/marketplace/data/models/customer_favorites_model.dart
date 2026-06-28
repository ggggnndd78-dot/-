import 'package:ghiyarak/features/marketplace/data/models/listing_summary.dart';

class CustomerFavoritesData {
  final List<ListingSummary> listings;
  final List<FollowedProviderSummary> providers;
  final List<FavoriteAlertItem> alerts;
  final CustomerFavoritesStats stats;

  const CustomerFavoritesData({
    required this.listings,
    required this.providers,
    required this.alerts,
    required this.stats,
  });

  factory CustomerFavoritesData.fromMap(Map<String, dynamic> map) {
    final rawListings = map['listings'] as List<dynamic>? ?? const [];
    final rawProviders = map['providers'] as List<dynamic>? ?? const [];
    final rawAlerts = map['alerts'] as List<dynamic>? ?? const [];
    return CustomerFavoritesData(
      listings: rawListings
          .whereType<Map>()
          .map(
              (item) => ListingSummary.fromMap(Map<String, dynamic>.from(item)))
          .toList(),
      providers: rawProviders
          .whereType<Map>()
          .map((item) =>
              FollowedProviderSummary.fromMap(Map<String, dynamic>.from(item)))
          .toList(),
      alerts: rawAlerts
          .whereType<Map>()
          .map((item) =>
              FavoriteAlertItem.fromMap(Map<String, dynamic>.from(item)))
          .toList(),
      stats: CustomerFavoritesStats.fromMap(
        Map<String, dynamic>.from(map['stats'] as Map? ?? const {}),
      ),
    );
  }

  factory CustomerFavoritesData.fromLocal(List<Map<String, dynamic>> items) {
    final listings = items.map((item) => ListingSummary.fromMap(item)).toList();
    return CustomerFavoritesData(
      listings: listings,
      providers: const [],
      alerts: const [],
      stats: CustomerFavoritesStats(
        listingsCount: listings.length,
        providersCount: 0,
        priceDropAlerts: 0,
        backInStockAlerts: 0,
      ),
    );
  }
}

class FollowedProviderSummary {
  final String id;
  final String name;
  final String type;
  final String typeLabel;
  final String? cityName;
  final String? logoUrl;
  final bool isVerified;
  final bool supportsDelivery;
  final bool supportsInstallation;
  final int activeListings;
  final int followersCount;
  final String? followedAt;

  const FollowedProviderSummary({
    required this.id,
    required this.name,
    required this.type,
    required this.typeLabel,
    this.cityName,
    this.logoUrl,
    this.isVerified = false,
    this.supportsDelivery = false,
    this.supportsInstallation = false,
    this.activeListings = 0,
    this.followersCount = 0,
    this.followedAt,
  });

  factory FollowedProviderSummary.fromMap(Map<String, dynamic> map) {
    final organization = map['organization'] is Map
        ? Map<String, dynamic>.from(map['organization'] as Map)
        : map;
    final type = (organization['organizationType'] ??
            organization['organization_type'] ??
            map['type'] ??
            '')
        .toString()
        .toUpperCase();
    final isWorkshop = type == 'WORKSHOP';
    return FollowedProviderSummary(
      id: (organization['publicId'] ??
              organization['public_id'] ??
              organization['id'] ??
              map['providerId'] ??
              map['provider_id'] ??
              '')
          .toString(),
      name: (organization['displayName'] ??
              organization['display_name'] ??
              organization['legalName'] ??
              organization['legal_name'] ??
              map['name'] ??
              'مزود')
          .toString(),
      type: type,
      typeLabel: isWorkshop ? 'ورشة' : 'تاجر',
      cityName:
          (map['cityName'] ?? map['city_name'] ?? organization['cityName'])
              ?.toString(),
      logoUrl: (organization['logoUrl'] ??
              organization['logo_url'] ??
              map['logoUrl'] ??
              map['logo_url'])
          ?.toString(),
      isVerified: organization['isVerified'] == true ||
          organization['is_verified'] == true,
      supportsDelivery:
          map['supportsDelivery'] == true || map['supports_delivery'] == true,
      supportsInstallation: isWorkshop ||
          map['supportsInstallation'] == true ||
          map['supports_installation'] == true,
      activeListings: int.tryParse(
              (map['activeListings'] ?? map['active_listings'] ?? 0)
                  .toString()) ??
          0,
      followersCount: int.tryParse(
              (map['followersCount'] ?? map['followers_count'] ?? 0)
                  .toString()) ??
          0,
      followedAt: (map['followedAt'] ??
              map['followed_at'] ??
              map['createdAt'] ??
              map['created_at'])
          ?.toString(),
    );
  }

  String get serviceLabel {
    if (supportsInstallation) return 'توصيل + تركيب';
    if (supportsDelivery) return 'توصيل';
    return 'استلام من الفرع';
  }
}

class FavoriteAlertItem {
  final String id;
  final String title;
  final String message;
  final String type;
  final String? listingId;
  final String? providerId;
  final bool isRead;
  final String? createdAt;

  const FavoriteAlertItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.listingId,
    this.providerId,
    this.isRead = false,
    this.createdAt,
  });

  factory FavoriteAlertItem.fromMap(Map<String, dynamic> map) {
    return FavoriteAlertItem(
      id: (map['id'] ?? map['publicId'] ?? map['public_id'] ?? '').toString(),
      title: (map['title'] ?? 'تنبيه مفضلة').toString(),
      message: (map['message'] ?? '').toString(),
      type: (map['type'] ?? '').toString(),
      listingId: (map['listingId'] ?? map['listing_id'])?.toString(),
      providerId: (map['providerId'] ?? map['provider_id'])?.toString(),
      isRead: map['isRead'] == true || map['is_read'] == true,
      createdAt: (map['createdAt'] ?? map['created_at'])?.toString(),
    );
  }
}

class CustomerFavoritesStats {
  final int listingsCount;
  final int providersCount;
  final int priceDropAlerts;
  final int backInStockAlerts;

  const CustomerFavoritesStats({
    required this.listingsCount,
    required this.providersCount,
    required this.priceDropAlerts,
    required this.backInStockAlerts,
  });

  factory CustomerFavoritesStats.fromMap(Map<String, dynamic> map) {
    return CustomerFavoritesStats(
      listingsCount: int.tryParse(
              (map['listingsCount'] ?? map['listings_count'] ?? 0)
                  .toString()) ??
          0,
      providersCount: int.tryParse(
              (map['providersCount'] ?? map['providers_count'] ?? 0)
                  .toString()) ??
          0,
      priceDropAlerts: int.tryParse(
              (map['priceDropAlerts'] ?? map['price_drop_alerts'] ?? 0)
                  .toString()) ??
          0,
      backInStockAlerts: int.tryParse(
              (map['backInStockAlerts'] ?? map['back_in_stock_alerts'] ?? 0)
                  .toString()) ??
          0,
    );
  }
}
