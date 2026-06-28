import 'package:ghiyarak/features/marketplace/data/models/catalog_category.dart';
import 'package:ghiyarak/features/marketplace/data/models/listing_summary.dart';

class CustomerHomeData {
  final CustomerHomeContext context;
  final List<HomeBannerItem> banners;
  final List<HomeShortcutItem> shortcuts;
  final List<CatalogCategory> categories;
  final List<ListingSummary> recommendedListings;
  final List<ListingSummary> latestListings;
  final List<ListingSummary> popularListings;
  final List<VerifiedProviderSummary> verifiedProviders;
  final List<HomeInsightItem> insights;
  final List<HomeServiceItem> services;
  final HomeStats stats;

  const CustomerHomeData({
    required this.context,
    required this.banners,
    required this.shortcuts,
    required this.categories,
    required this.recommendedListings,
    required this.latestListings,
    required this.popularListings,
    required this.verifiedProviders,
    required this.insights,
    required this.services,
    required this.stats,
  });

  factory CustomerHomeData.fromMap(Map<String, dynamic> map) {
    final categories = _list(map['categories'])
        .map((item) => CatalogCategory.fromMap(_map(item)))
        .toList();
    return CustomerHomeData(
      context: CustomerHomeContext.fromMap(_map(map['context'])),
      banners: _list(map['banners'])
          .map((item) => HomeBannerItem.fromMap(_map(item)))
          .toList(),
      shortcuts: _list(map['shortcuts'])
          .map((item) => HomeShortcutItem.fromMap(_map(item)))
          .toList(),
      categories: categories,
      recommendedListings:
          _list(map['recommendedListings'] ?? map['recommended_listings'])
              .map((item) => ListingSummary.fromMap(_map(item)))
              .toList(),
      latestListings: _list(map['latestListings'] ?? map['latest_listings'])
          .map((item) => ListingSummary.fromMap(_map(item)))
          .toList(),
      popularListings: _list(map['popularListings'] ?? map['popular_listings'])
          .map((item) => ListingSummary.fromMap(_map(item)))
          .toList(),
      verifiedProviders:
          _list(map['verifiedProviders'] ?? map['verified_providers'])
              .map((item) => VerifiedProviderSummary.fromMap(_map(item)))
              .toList(),
      insights: _list(map['insights'])
          .map((item) => HomeInsightItem.fromMap(_map(item)))
          .toList(),
      services: _list(map['services'])
          .map((item) => HomeServiceItem.fromMap(_map(item)))
          .toList(),
      stats: HomeStats.fromMap(_map(map['stats'])),
    );
  }

  CustomerHomeData withFallbacks({
    List<CatalogCategory> fallbackCategories = const [],
    List<ListingSummary> fallbackListings = const [],
  }) {
    return CustomerHomeData(
      context: context,
      banners: banners.isEmpty ? HomeBannerItem.defaults : banners,
      shortcuts: shortcuts.isEmpty ? HomeShortcutItem.defaults : shortcuts,
      categories: categories.isEmpty ? fallbackCategories : categories,
      recommendedListings:
          recommendedListings.isEmpty ? fallbackListings : recommendedListings,
      latestListings:
          latestListings.isEmpty ? fallbackListings : latestListings,
      popularListings:
          popularListings.isEmpty ? fallbackListings : popularListings,
      verifiedProviders: verifiedProviders,
      insights: insights.isEmpty ? HomeInsightItem.defaults : insights,
      services: services.isEmpty ? HomeServiceItem.defaults : services,
      stats: stats,
    );
  }

  static Map<String, dynamic> _map(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
  static List<dynamic> _list(Object? value) =>
      value is List ? value : const <dynamic>[];
}

class CustomerHomeContext {
  final String cityName;
  final String districtName;
  final String vehicleLabel;
  final bool hasVehicle;
  final bool hasLocation;

  const CustomerHomeContext({
    required this.cityName,
    required this.districtName,
    required this.vehicleLabel,
    required this.hasVehicle,
    required this.hasLocation,
  });

  factory CustomerHomeContext.fromMap(Map<String, dynamic> map) {
    return CustomerHomeContext(
      cityName: (map['cityName'] ?? map['city_name'] ?? '').toString(),
      districtName:
          (map['districtName'] ?? map['district_name'] ?? '').toString(),
      vehicleLabel:
          (map['vehicleLabel'] ?? map['vehicle_label'] ?? '').toString(),
      hasVehicle: map['hasVehicle'] == true || map['has_vehicle'] == true,
      hasLocation: map['hasLocation'] == true || map['has_location'] == true,
    );
  }

  String get locationLabel {
    final parts = [cityName, districtName].where((e) => e.trim().isNotEmpty);
    return parts.isEmpty ? 'اختر المدينة والمنطقة' : parts.join(' - ');
  }
}

class HomeBannerItem {
  final String title;
  final String subtitle;
  final String actionLabel;
  final String actionRoute;
  final String icon;

  const HomeBannerItem({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.actionRoute,
    required this.icon,
  });

  factory HomeBannerItem.fromMap(Map<String, dynamic> map) {
    return HomeBannerItem(
      title: (map['title'] ?? '').toString(),
      subtitle: (map['subtitle'] ?? '').toString(),
      actionLabel:
          (map['actionLabel'] ?? map['action_label'] ?? 'ابدأ الآن').toString(),
      actionRoute:
          (map['actionRoute'] ?? map['action_route'] ?? '/marketplace/search')
              .toString(),
      icon: (map['icon'] ?? 'search').toString(),
    );
  }

  static const defaults = [
    HomeBannerItem(
      title: 'اعثر على القطعة المناسبة لسيارتك',
      subtitle: 'بحث ذكي حسب السيارة والمدينة مع عروض من تجار وورش موثقة.',
      actionLabel: 'ابحث الآن',
      actionRoute: '/marketplace/search',
      icon: 'search',
    ),
    HomeBannerItem(
      title: 'قارن السعر والضمان والتوصيل',
      subtitle: 'اختر أفضل عرض حسب السعر، المخزون، الضمان، والتركيب.',
      actionLabel: 'قارن العروض',
      actionRoute: '/marketplace/compare',
      icon: 'compare',
    ),
  ];
}

class HomeShortcutItem {
  final String title;
  final String subtitle;
  final String route;
  final String icon;

  const HomeShortcutItem({
    required this.title,
    required this.subtitle,
    required this.route,
    required this.icon,
  });

  factory HomeShortcutItem.fromMap(Map<String, dynamic> map) {
    return HomeShortcutItem(
      title: (map['title'] ?? '').toString(),
      subtitle: (map['subtitle'] ?? '').toString(),
      route: (map['route'] ?? '').toString(),
      icon: (map['icon'] ?? '').toString(),
    );
  }

  static const defaults = [
    HomeShortcutItem(
        title: 'طلباتي',
        subtitle: 'تتبع وراجع',
        route: '/marketplace/my-orders',
        icon: 'orders'),
    HomeShortcutItem(
        title: 'مركباتي',
        subtitle: 'سيارتك الافتراضية',
        route: '/vehicles',
        icon: 'vehicle'),
    HomeShortcutItem(
        title: 'المفضلة',
        subtitle: 'القطع والمتاجر',
        route: '/marketplace/favorites',
        icon: 'favorite'),
    HomeShortcutItem(
        title: 'السلة',
        subtitle: 'إتمام الشراء',
        route: '/marketplace/cart',
        icon: 'cart'),
  ];
}

class VerifiedProviderSummary {
  final String id;
  final String name;
  final String typeLabel;
  final String? cityName;
  final double rating;
  final int completedOrders;
  final bool isVerified;
  final String? logoUrl;

  const VerifiedProviderSummary({
    required this.id,
    required this.name,
    required this.typeLabel,
    this.cityName,
    this.rating = 0,
    this.completedOrders = 0,
    this.isVerified = false,
    this.logoUrl,
  });

  factory VerifiedProviderSummary.fromMap(Map<String, dynamic> map) {
    final type = (map['organizationType'] ??
            map['organization_type'] ??
            map['type'] ??
            '')
        .toString()
        .toUpperCase();
    return VerifiedProviderSummary(
      id: (map['publicId'] ?? map['public_id'] ?? map['id'] ?? '').toString(),
      name: (map['displayName'] ?? map['display_name'] ?? map['name'] ?? 'مزود')
          .toString(),
      typeLabel: type == 'WORKSHOP'
          ? 'ورشة'
          : type == 'MERCHANT'
              ? 'تاجر'
              : 'مزود',
      cityName: (map['cityName'] ?? map['city_name'])?.toString(),
      rating: double.tryParse(
              (map['rating'] ?? map['avgRating'] ?? 0).toString()) ??
          0,
      completedOrders: int.tryParse(
              (map['completedOrders'] ?? map['completed_orders'] ?? 0)
                  .toString()) ??
          0,
      isVerified: map['isVerified'] == true || map['is_verified'] == true,
      logoUrl: (map['logoUrl'] ?? map['logo_url'])?.toString(),
    );
  }
}

class HomeInsightItem {
  final String title;
  final String value;
  final String subtitle;
  final String icon;

  const HomeInsightItem({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  factory HomeInsightItem.fromMap(Map<String, dynamic> map) {
    return HomeInsightItem(
      title: (map['title'] ?? '').toString(),
      value: (map['value'] ?? '').toString(),
      subtitle: (map['subtitle'] ?? '').toString(),
      icon: (map['icon'] ?? '').toString(),
    );
  }

  static const defaults = [
    HomeInsightItem(
        title: 'توافق ذكي',
        value: 'سيارتك',
        subtitle: 'نتائج مفلترة حسب الموديل والسنة',
        icon: 'vehicle'),
    HomeInsightItem(
        title: 'مزودون',
        value: 'موثقون',
        subtitle: 'متاجر وورش قابلة للمراجعة',
        icon: 'verified'),
    HomeInsightItem(
        title: 'تتبع',
        value: 'مباشر',
        subtitle: 'من التجهيز حتى التسليم',
        icon: 'shipping'),
  ];
}

class HomeServiceItem {
  final String title;
  final String subtitle;
  final String route;
  final String icon;

  const HomeServiceItem({
    required this.title,
    required this.subtitle,
    required this.route,
    required this.icon,
  });

  factory HomeServiceItem.fromMap(Map<String, dynamic> map) {
    return HomeServiceItem(
      title: (map['title'] ?? '').toString(),
      subtitle: (map['subtitle'] ?? '').toString(),
      route: (map['route'] ?? '').toString(),
      icon: (map['icon'] ?? '').toString(),
    );
  }

  static const defaults = [
    HomeServiceItem(
        title: 'قطع غيار',
        subtitle: 'ابحث واشتر القطع',
        route: '/marketplace/search',
        icon: 'parts'),
    HomeServiceItem(
        title: 'ورش تركيب',
        subtitle: 'قطع مع خدمة تركيب',
        route: '/marketplace/search?providerType=WORKSHOP',
        icon: 'workshop'),
    HomeServiceItem(
        title: 'الدعم',
        subtitle: 'تواصل مع المساعدة',
        route: '/customer/support',
        icon: 'support'),
  ];
}

class HomeStats {
  final int activeListings;
  final int verifiedProviders;
  final int availableCategories;
  final int deliveryReady;

  const HomeStats({
    required this.activeListings,
    required this.verifiedProviders,
    required this.availableCategories,
    required this.deliveryReady,
  });

  factory HomeStats.fromMap(Map<String, dynamic> map) {
    return HomeStats(
      activeListings: int.tryParse(
              (map['activeListings'] ?? map['active_listings'] ?? 0)
                  .toString()) ??
          0,
      verifiedProviders: int.tryParse(
              (map['verifiedProviders'] ?? map['verified_providers'] ?? 0)
                  .toString()) ??
          0,
      availableCategories: int.tryParse(
              (map['availableCategories'] ?? map['available_categories'] ?? 0)
                  .toString()) ??
          0,
      deliveryReady: int.tryParse(
              (map['deliveryReady'] ?? map['delivery_ready'] ?? 0)
                  .toString()) ??
          0,
    );
  }
}
