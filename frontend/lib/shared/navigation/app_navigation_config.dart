import 'package:flutter/material.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/features/auth/logic/auth_state.dart';
import 'package:ghiyarak/features/authorization/logic/access_policy.dart';

enum AppNavigationArea {
  public,
  customer,
  merchant,
  workshop,
  warehouse,
  support,
  admin,
  finance,
  settings,
}

class AppNavigationItem {
  const AppNavigationItem({
    required this.id,
    required this.labelKey,
    required this.icon,
    required this.route,
    this.activeIcon,
    this.roles = const [],
    this.permissions = const [],
    this.requiresApproval = false,
    this.approvedOrganizationTypes = const [],
    this.areas = const [],
    this.guestVisible = false,
    this.dividerBefore = false,
  });

  final String id;
  final String labelKey;
  final IconData icon;
  final IconData? activeIcon;
  final String route;
  final List<String> roles;
  final List<String> permissions;
  final bool requiresApproval;
  final List<String> approvedOrganizationTypes;
  final List<AppNavigationArea> areas;
  final bool guestVisible;
  final bool dividerBefore;

  bool isVisibleFor(AuthState auth) {
    if (auth.isGuest || !auth.isAuthenticated) return guestVisible;
    if (requiresApproval && approvedOrganizationTypes.isEmpty) return false;
    return AccessPolicy.hasAccess(
      auth,
      roles: roles,
      permissions: permissions,
      approvedOrganizationTypes: approvedOrganizationTypes,
    );
  }

  bool belongsTo(AppNavigationArea area) => areas.contains(area);
}

class AppNavigationConfig {
  const AppNavigationConfig._();

  static const List<AppNavigationItem> guestNavigationItems = [
    AppNavigationItem(
      id: 'marketplace.home',
      labelKey: 'nav.marketplace',
      icon: Icons.storefront_outlined,
      activeIcon: Icons.storefront,
      route: RouteNames.marketplaceHome,
      areas: [AppNavigationArea.public],
      guestVisible: true,
    ),
    AppNavigationItem(
      id: 'marketplace.search',
      labelKey: 'common.search',
      icon: Icons.search_outlined,
      activeIcon: Icons.search,
      route: RouteNames.marketplaceSearch,
      areas: [AppNavigationArea.public],
      guestVisible: true,
    ),
    AppNavigationItem(
      id: 'marketplace.categories',
      labelKey: 'marketplace.categories',
      icon: Icons.category_outlined,
      activeIcon: Icons.category,
      route: RouteNames.marketplaceCategories,
      areas: [AppNavigationArea.public],
      guestVisible: true,
    ),
    AppNavigationItem(
      id: 'auth.login',
      labelKey: 'auth.login',
      icon: Icons.login_rounded,
      activeIcon: Icons.login_rounded,
      route: RouteNames.login,
      areas: [AppNavigationArea.public],
      guestVisible: true,
      dividerBefore: true,
    ),
    AppNavigationItem(
      id: 'auth.register',
      labelKey: 'auth.create_account',
      icon: Icons.person_add_alt_1_outlined,
      activeIcon: Icons.person_add_alt_1_rounded,
      route: RouteNames.register,
      areas: [AppNavigationArea.public],
      guestVisible: true,
    ),
  ];

  static const List<AppNavigationItem> customerNavigationItems = [
    AppNavigationItem(
      id: 'customer.center',
      labelKey: 'nav.home',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
      route: RouteNames.customerCenter,
      roles: ['customer'],
      areas: [AppNavigationArea.customer],
    ),
    AppNavigationItem(
      id: 'customer.marketplace',
      labelKey: 'nav.marketplace',
      icon: Icons.storefront_outlined,
      activeIcon: Icons.storefront,
      route: RouteNames.marketplaceHome,
      roles: ['customer'],
      areas: [AppNavigationArea.customer],
    ),
    AppNavigationItem(
      id: 'customer.cart',
      labelKey: 'nav.cart',
      icon: Icons.shopping_cart_outlined,
      activeIcon: Icons.shopping_cart_rounded,
      route: RouteNames.cart,
      roles: ['customer'],
      areas: [AppNavigationArea.customer],
    ),
    AppNavigationItem(
      id: 'customer.orders',
      labelKey: 'nav.orders',
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long_rounded,
      route: RouteNames.myOrders,
      roles: ['customer'],
      areas: [AppNavigationArea.customer],
    ),
    AppNavigationItem(
      id: 'customer.profile',
      labelKey: 'customer.profile',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      route: RouteNames.customerProfile,
      roles: ['customer'],
      areas: [AppNavigationArea.customer],
      dividerBefore: true,
    ),
    AppNavigationItem(
      id: 'customer.vehicles',
      labelKey: 'vehicles.title',
      icon: Icons.directions_car_outlined,
      activeIcon: Icons.directions_car_rounded,
      route: RouteNames.customerVehicle,
      roles: ['customer'],
      areas: [AppNavigationArea.customer],
    ),
    AppNavigationItem(
      id: 'customer.wallet',
      labelKey: 'wallet.title',
      icon: Icons.account_balance_wallet_outlined,
      activeIcon: Icons.account_balance_wallet_rounded,
      route: RouteNames.customerWallet,
      roles: ['customer'],
      areas: [AppNavigationArea.customer],
    ),
    AppNavigationItem(
      id: 'customer.favorites',
      labelKey: 'customer.favorites',
      icon: Icons.favorite_border_rounded,
      activeIcon: Icons.favorite_rounded,
      route: RouteNames.marketplaceFavorites,
      roles: ['customer'],
      areas: [AppNavigationArea.customer],
    ),
    AppNavigationItem(
      id: 'customer.addresses',
      labelKey: 'customer.addresses',
      icon: Icons.location_on_outlined,
      activeIcon: Icons.location_on_rounded,
      route: RouteNames.customerAddresses,
      roles: ['customer'],
      areas: [AppNavigationArea.customer],
    ),
    AppNavigationItem(
      id: 'customer.chat',
      labelKey: 'customer.chat',
      icon: Icons.chat_bubble_outline_rounded,
      activeIcon: Icons.chat_bubble_rounded,
      route: RouteNames.customerChat,
      roles: ['customer'],
      areas: [AppNavigationArea.customer],
    ),
    AppNavigationItem(
      id: 'customer.rewards',
      labelKey: 'customer.rewards',
      icon: Icons.card_giftcard_outlined,
      activeIcon: Icons.card_giftcard_rounded,
      route: RouteNames.customerRewards,
      roles: ['customer'],
      areas: [AppNavigationArea.customer],
    ),
    AppNavigationItem(
      id: 'customer.support',
      labelKey: 'support.title',
      icon: Icons.support_agent_outlined,
      activeIcon: Icons.support_agent_rounded,
      route: RouteNames.customerSupport,
      roles: ['customer'],
      areas: [AppNavigationArea.customer],
      dividerBefore: true,
    ),
    AppNavigationItem(
      id: 'customer.settings',
      labelKey: 'settings.title',
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
      route: RouteNames.customerSettings,
      roles: ['customer'],
      areas: [AppNavigationArea.customer, AppNavigationArea.settings],
    ),
  ];

  static const List<AppNavigationItem> merchantNavigationItems = [
    AppNavigationItem(
      id: 'merchant.hub',
      labelKey: 'merchant.dashboard',
      icon: Icons.business_center_outlined,
      activeIcon: Icons.business_center_rounded,
      route: RouteNames.merchantHub,
      roles: ['merchant_owner'],
      requiresApproval: true,
      approvedOrganizationTypes: ['MERCHANT'],
      areas: [AppNavigationArea.merchant],
    ),
    AppNavigationItem(
      id: 'merchant.listings',
      labelKey: 'marketplace.products',
      icon: Icons.inventory_2_outlined,
      activeIcon: Icons.inventory_2_rounded,
      route: RouteNames.merchantListings,
      roles: ['merchant_owner'],
      permissions: ['merchant.products.manage'],
      requiresApproval: true,
      approvedOrganizationTypes: ['MERCHANT'],
      areas: [AppNavigationArea.merchant],
    ),
    AppNavigationItem(
      id: 'merchant.orders',
      labelKey: 'orders.title',
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long_rounded,
      route: RouteNames.merchantOrders,
      roles: ['merchant_owner'],
      permissions: ['merchant.orders.manage'],
      requiresApproval: true,
      approvedOrganizationTypes: ['MERCHANT'],
      areas: [AppNavigationArea.merchant],
    ),
    AppNavigationItem(
      id: 'merchant.inventory',
      labelKey: 'merchant.inventory',
      icon: Icons.warehouse_outlined,
      activeIcon: Icons.warehouse_rounded,
      route: RouteNames.merchantInventory,
      roles: ['merchant_owner'],
      permissions: ['merchant.inventory.manage'],
      requiresApproval: true,
      approvedOrganizationTypes: ['MERCHANT'],
      areas: [AppNavigationArea.merchant],
    ),
    AppNavigationItem(
      id: 'merchant.branches',
      labelKey: 'merchant.branches',
      icon: Icons.store_outlined,
      activeIcon: Icons.store_rounded,
      route: RouteNames.merchantBranches,
      roles: ['merchant_owner'],
      permissions: ['merchant.branches.manage'],
      requiresApproval: true,
      approvedOrganizationTypes: ['MERCHANT'],
      areas: [AppNavigationArea.merchant],
    ),
    AppNavigationItem(
      id: 'merchant.reports',
      labelKey: 'reports.title',
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart_rounded,
      route: RouteNames.merchantReports,
      roles: ['merchant_owner'],
      permissions: ['view_reports'],
      requiresApproval: true,
      approvedOrganizationTypes: ['MERCHANT'],
      areas: [AppNavigationArea.merchant],
      dividerBefore: true,
    ),
    AppNavigationItem(
      id: 'merchant.finance',
      labelKey: 'admin.finance',
      icon: Icons.account_balance_outlined,
      activeIcon: Icons.account_balance_rounded,
      route: RouteNames.merchantFinanceOverview,
      roles: ['merchant_owner'],
      permissions: ['finance.payments.review'],
      requiresApproval: true,
      approvedOrganizationTypes: ['MERCHANT'],
      areas: [AppNavigationArea.merchant, AppNavigationArea.finance],
    ),
    AppNavigationItem(
      id: 'merchant.settings',
      labelKey: 'settings.title',
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
      route: RouteNames.merchantSettings,
      roles: ['merchant_owner'],
      requiresApproval: true,
      approvedOrganizationTypes: ['MERCHANT'],
      areas: [AppNavigationArea.merchant, AppNavigationArea.settings],
    ),
    AppNavigationItem(
      id: 'merchant.store_profile',
      labelKey: 'merchant.storeProfile',
      icon: Icons.storefront_outlined,
      activeIcon: Icons.storefront_rounded,
      route: RouteNames.merchantStoreProfile,
      roles: ['merchant_owner'],
      requiresApproval: true,
      approvedOrganizationTypes: ['MERCHANT'],
      areas: [AppNavigationArea.merchant],
      dividerBefore: true,
    ),
    AppNavigationItem(
      id: 'merchant.verification',
      labelKey: 'merchant.verification',
      icon: Icons.verified_outlined,
      activeIcon: Icons.verified_rounded,
      route: RouteNames.merchantVerification,
      roles: ['merchant_owner'],
      areas: [AppNavigationArea.merchant],
    ),
    AppNavigationItem(
      id: 'merchant.categories',
      labelKey: 'merchant.catalog',
      icon: Icons.account_tree_outlined,
      activeIcon: Icons.account_tree_rounded,
      route: RouteNames.merchantCategoriesManager,
      roles: ['merchant_owner'],
      permissions: ['merchant.products.manage'],
      requiresApproval: true,
      approvedOrganizationTypes: ['MERCHANT'],
      areas: [AppNavigationArea.merchant],
      dividerBefore: true,
    ),
    AppNavigationItem(
      id: 'merchant.compatibility',
      labelKey: 'merchant.compatibility',
      icon: Icons.rule_outlined,
      activeIcon: Icons.rule_rounded,
      route: RouteNames.merchantCompatibilityManager,
      roles: ['merchant_owner'],
      permissions: ['merchant.products.manage'],
      requiresApproval: true,
      approvedOrganizationTypes: ['MERCHANT'],
      areas: [AppNavigationArea.merchant],
    ),
    AppNavigationItem(
      id: 'merchant.bulk_import',
      labelKey: 'merchant.bulkImport',
      icon: Icons.upload_file_outlined,
      activeIcon: Icons.upload_file_rounded,
      route: RouteNames.merchantBulkImport,
      roles: ['merchant_owner'],
      permissions: ['merchant.products.manage'],
      requiresApproval: true,
      approvedOrganizationTypes: ['MERCHANT'],
      areas: [AppNavigationArea.merchant],
    ),
    AppNavigationItem(
      id: 'merchant.promotions',
      labelKey: 'merchant.promotions',
      icon: Icons.local_offer_outlined,
      activeIcon: Icons.local_offer_rounded,
      route: RouteNames.merchantPromotions,
      roles: ['merchant_owner'],
      permissions: ['coupons.manage'],
      requiresApproval: true,
      approvedOrganizationTypes: ['MERCHANT'],
      areas: [AppNavigationArea.merchant],
    ),
    AppNavigationItem(
      id: 'merchant.team',
      labelKey: 'merchant.team',
      icon: Icons.groups_outlined,
      activeIcon: Icons.groups_rounded,
      route: RouteNames.merchantEmployees,
      roles: ['merchant_owner'],
      permissions: ['merchant.employees.manage'],
      requiresApproval: true,
      approvedOrganizationTypes: ['MERCHANT'],
      areas: [AppNavigationArea.merchant],
      dividerBefore: true,
    ),
    AppNavigationItem(
      id: 'merchant.notifications',
      labelKey: 'merchant.notifications',
      icon: Icons.notifications_outlined,
      activeIcon: Icons.notifications_rounded,
      route: RouteNames.merchantNotifications,
      roles: ['merchant_owner'],
      requiresApproval: true,
      approvedOrganizationTypes: ['MERCHANT'],
      areas: [AppNavigationArea.merchant],
    ),
    AppNavigationItem(
      id: 'merchant.returns',
      labelKey: 'merchant.returns',
      icon: Icons.assignment_return_outlined,
      activeIcon: Icons.assignment_return_rounded,
      route: RouteNames.merchantReturns,
      roles: ['merchant_owner'],
      permissions: ['merchant.orders.manage'],
      requiresApproval: true,
      approvedOrganizationTypes: ['MERCHANT'],
      areas: [AppNavigationArea.merchant],
      dividerBefore: true,
    ),
    AppNavigationItem(
      id: 'merchant.disputes',
      labelKey: 'merchant.disputes',
      icon: Icons.gavel_outlined,
      activeIcon: Icons.gavel_rounded,
      route: RouteNames.merchantDisputes,
      roles: ['merchant_owner'],
      permissions: ['merchant.orders.manage'],
      requiresApproval: true,
      approvedOrganizationTypes: ['MERCHANT'],
      areas: [AppNavigationArea.merchant],
    ),
    AppNavigationItem(
      id: 'merchant.reviews',
      labelKey: 'merchant.reviews',
      icon: Icons.reviews_outlined,
      activeIcon: Icons.reviews_rounded,
      route: RouteNames.merchantReviews,
      roles: ['merchant_owner'],
      requiresApproval: true,
      approvedOrganizationTypes: ['MERCHANT'],
      areas: [AppNavigationArea.merchant],
    ),
    AppNavigationItem(
      id: 'merchant.wallet',
      labelKey: 'merchant.wallet',
      icon: Icons.account_balance_wallet_outlined,
      activeIcon: Icons.account_balance_wallet_rounded,
      route: RouteNames.merchantWallet,
      roles: ['merchant_owner'],
      permissions: ['finance.payments.review'],
      requiresApproval: true,
      approvedOrganizationTypes: ['MERCHANT'],
      areas: [AppNavigationArea.merchant, AppNavigationArea.finance],
      dividerBefore: true,
    ),
    AppNavigationItem(
      id: 'merchant.settlements',
      labelKey: 'merchant.settlements',
      icon: Icons.payments_outlined,
      activeIcon: Icons.payments_rounded,
      route: RouteNames.merchantSettlements,
      roles: ['merchant_owner'],
      permissions: ['finance.payments.review'],
      requiresApproval: true,
      approvedOrganizationTypes: ['MERCHANT'],
      areas: [AppNavigationArea.merchant, AppNavigationArea.finance],
    ),
    AppNavigationItem(
      id: 'merchant.invoices',
      labelKey: 'merchant.invoices',
      icon: Icons.description_outlined,
      activeIcon: Icons.description_rounded,
      route: RouteNames.merchantInvoices,
      roles: ['merchant_owner'],
      permissions: ['finance.payments.review'],
      requiresApproval: true,
      approvedOrganizationTypes: ['MERCHANT'],
      areas: [AppNavigationArea.merchant, AppNavigationArea.finance],
    ),
  ];

  static const List<AppNavigationItem> workshopNavigationItems = [
    AppNavigationItem(
      id: 'workshop.hub',
      labelKey: 'workshop.dashboard',
      icon: Icons.car_repair_outlined,
      activeIcon: Icons.car_repair_rounded,
      route: RouteNames.workshopOperationsHub,
      roles: ['workshop_owner'],
      requiresApproval: true,
      approvedOrganizationTypes: ['WORKSHOP'],
      areas: [AppNavigationArea.workshop],
    ),
    AppNavigationItem(
      id: 'workshop.services',
      labelKey: 'workshops.services',
      icon: Icons.build_outlined,
      activeIcon: Icons.build_rounded,
      route: RouteNames.workshopOperationsServices,
      roles: ['workshop_owner'],
      permissions: ['workshop.services.manage'],
      requiresApproval: true,
      approvedOrganizationTypes: ['WORKSHOP'],
      areas: [AppNavigationArea.workshop],
    ),
    AppNavigationItem(
      id: 'workshop.bookings',
      labelKey: 'bookings.title',
      icon: Icons.event_note_outlined,
      activeIcon: Icons.event_note_rounded,
      route: RouteNames.workshopOperationsBookings,
      roles: ['workshop_owner'],
      permissions: ['workshop.bookings.manage'],
      requiresApproval: true,
      approvedOrganizationTypes: ['WORKSHOP'],
      areas: [AppNavigationArea.workshop],
    ),
    AppNavigationItem(
      id: 'workshop.orders',
      labelKey: 'orders.title',
      icon: Icons.assignment_outlined,
      activeIcon: Icons.assignment_rounded,
      route: RouteNames.workshopOperationsServiceOrders,
      roles: ['workshop_owner'],
      permissions: ['workshop.service_orders.manage'],
      requiresApproval: true,
      approvedOrganizationTypes: ['WORKSHOP'],
      areas: [AppNavigationArea.workshop],
    ),
  ];

  static const List<AppNavigationItem> warehouseNavigationItems = [
    AppNavigationItem(
      id: 'warehouse.hub',
      labelKey: 'warehouse.dashboard',
      icon: Icons.warehouse_outlined,
      activeIcon: Icons.warehouse_rounded,
      route: RouteNames.warehouseHub,
      roles: ['warehouse_owner'],
      requiresApproval: true,
      approvedOrganizationTypes: ['WAREHOUSE'],
      areas: [AppNavigationArea.warehouse],
    ),
  ];

  static const List<AppNavigationItem> supportNavigationItems = [
    AppNavigationItem(
      id: 'support.operations',
      labelKey: 'support.operations',
      icon: Icons.support_agent_outlined,
      activeIcon: Icons.support_agent_rounded,
      route: RouteNames.supportOperations,
      permissions: [
        'support.tickets.manage',
        'manage_support',
        'manage_complaints',
        'manage_reviews',
        'support.content.manage',
        'support.whatsapp.manage',
        'manage_system',
      ],
      areas: [AppNavigationArea.support],
    ),
    AppNavigationItem(
      id: 'support.tickets',
      labelKey: 'support.tickets',
      icon: Icons.confirmation_number_outlined,
      activeIcon: Icons.confirmation_number_rounded,
      route: RouteNames.supportTickets,
      permissions: [
        'support.tickets.manage',
        'manage_support',
        'manage_system',
      ],
      areas: [AppNavigationArea.support],
    ),
    AppNavigationItem(
      id: 'support.complaints',
      labelKey: 'support.complaints',
      icon: Icons.report_problem_outlined,
      activeIcon: Icons.report_problem_rounded,
      route: RouteNames.supportComplaints,
      permissions: ['manage_complaints', 'manage_support', 'manage_system'],
      areas: [AppNavigationArea.support],
    ),
    AppNavigationItem(
      id: 'support.reviews',
      labelKey: 'support.reviews',
      icon: Icons.reviews_outlined,
      activeIcon: Icons.reviews_rounded,
      route: RouteNames.supportReviews,
      permissions: ['manage_reviews', 'manage_support', 'manage_system'],
      areas: [AppNavigationArea.support],
      dividerBefore: true,
    ),
  ];

  static const List<AppNavigationItem> adminNavigationItems = [
    AppNavigationItem(
      id: 'admin.control',
      labelKey: 'admin.title',
      icon: Icons.admin_panel_settings_outlined,
      activeIcon: Icons.admin_panel_settings_rounded,
      route: RouteNames.adminControlCenter,
      permissions: ['view_admin_panel', 'manage_system'],
      areas: [AppNavigationArea.admin],
    ),
    AppNavigationItem(
      id: 'admin.analytics',
      labelKey: 'admin.analytics',
      icon: Icons.analytics_outlined,
      activeIcon: Icons.analytics_rounded,
      route: RouteNames.adminAnalytics,
      permissions: ['view_reports', 'manage_system'],
      areas: [AppNavigationArea.admin],
    ),
    AppNavigationItem(
      id: 'admin.users',
      labelKey: 'admin.users',
      icon: Icons.people_outline,
      activeIcon: Icons.people_rounded,
      route: RouteNames.adminUsers,
      permissions: ['manage_users'],
      areas: [AppNavigationArea.admin],
    ),
    AppNavigationItem(
      id: 'admin.verifications',
      labelKey: 'admin.verifications',
      icon: Icons.verified_user_outlined,
      activeIcon: Icons.verified_user_rounded,
      route: RouteNames.adminVerifications,
      permissions: ['review_verifications'],
      areas: [AppNavigationArea.admin],
    ),
    AppNavigationItem(
      id: 'admin.locations',
      labelKey: 'admin.locations',
      icon: Icons.location_city_outlined,
      activeIcon: Icons.location_city_rounded,
      route: RouteNames.adminLocations,
      permissions: ['manage_location', 'manage_system'],
      areas: [AppNavigationArea.admin],
    ),
    AppNavigationItem(
      id: 'admin.orders',
      labelKey: 'admin.orders',
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long_rounded,
      route: RouteNames.adminOrders,
      permissions: ['admin.orders.view', 'manage_system'],
      areas: [AppNavigationArea.admin],
    ),
    AppNavigationItem(
      id: 'admin.delivery',
      labelKey: 'admin.delivery',
      icon: Icons.local_shipping_outlined,
      activeIcon: Icons.local_shipping_rounded,
      route: RouteNames.adminDeliveryManagement,
      permissions: ['delivery.shipments.manage', 'manage_system'],
      areas: [AppNavigationArea.admin],
    ),
    AppNavigationItem(
      id: 'admin.finance',
      labelKey: 'admin.finance',
      icon: Icons.account_balance_outlined,
      activeIcon: Icons.account_balance_rounded,
      route: RouteNames.financeReview,
      permissions: ['finance.payments.review', 'manage_system'],
      areas: [AppNavigationArea.admin, AppNavigationArea.finance],
      dividerBefore: true,
    ),
    AppNavigationItem(
      id: 'admin.coupons',
      labelKey: 'admin.coupons',
      icon: Icons.local_offer_outlined,
      activeIcon: Icons.local_offer_rounded,
      route: RouteNames.adminCoupons,
      permissions: ['coupons.manage', 'manage_system'],
      areas: [AppNavigationArea.admin],
    ),
    AppNavigationItem(
      id: 'admin.support',
      labelKey: 'admin.support',
      icon: Icons.support_agent_outlined,
      activeIcon: Icons.support_agent_rounded,
      route: RouteNames.supportOperations,
      permissions: [
        'support.tickets.manage',
        'manage_support',
        'manage_system',
      ],
      areas: [AppNavigationArea.admin, AppNavigationArea.support],
      dividerBefore: true,
    ),
    AppNavigationItem(
      id: 'admin.complaints',
      labelKey: 'support.complaints',
      icon: Icons.report_problem_outlined,
      activeIcon: Icons.report_problem_rounded,
      route: RouteNames.supportComplaints,
      permissions: ['manage_complaints', 'manage_support', 'manage_system'],
      areas: [AppNavigationArea.admin, AppNavigationArea.support],
    ),
    AppNavigationItem(
      id: 'admin.reviews',
      labelKey: 'admin.reviews',
      icon: Icons.reviews_outlined,
      activeIcon: Icons.reviews_rounded,
      route: RouteNames.supportReviews,
      permissions: ['manage_reviews', 'manage_support', 'manage_system'],
      areas: [AppNavigationArea.admin, AppNavigationArea.support],
    ),
    AppNavigationItem(
      id: 'admin.audit',
      labelKey: 'admin.audit',
      icon: Icons.manage_search_outlined,
      activeIcon: Icons.manage_search_rounded,
      route: RouteNames.adminAuditLogs,
      permissions: ['view_audit_logs', 'manage_system'],
      areas: [AppNavigationArea.admin],
      dividerBefore: true,
    ),
    AppNavigationItem(
      id: 'admin.translations',
      labelKey: 'admin.i18n_catalog',
      icon: Icons.translate_outlined,
      activeIcon: Icons.translate_rounded,
      route: RouteNames.adminTranslations,
      permissions: ['manage_settings', 'manage_system'],
      areas: [AppNavigationArea.admin, AppNavigationArea.settings],
    ),
    AppNavigationItem(
      id: 'admin.hardening',
      labelKey: 'admin.system_hardening',
      icon: Icons.security_outlined,
      activeIcon: Icons.security_rounded,
      route: RouteNames.adminSystemHardening,
      permissions: ['manage_settings', 'manage_system'],
      areas: [AppNavigationArea.admin, AppNavigationArea.settings],
    ),
    AppNavigationItem(
      id: 'admin.quality_release',
      labelKey: 'admin.quality_release',
      icon: Icons.fact_check_outlined,
      activeIcon: Icons.fact_check_rounded,
      route: RouteNames.adminQualityRelease,
      permissions: ['release.manage', 'manage_system'],
      areas: [AppNavigationArea.admin, AppNavigationArea.settings],
    ),
    AppNavigationItem(
      id: 'admin.settings',
      labelKey: 'settings.title',
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
      route: RouteNames.adminSettings,
      permissions: ['manage_settings', 'manage_system'],
      areas: [AppNavigationArea.admin, AppNavigationArea.settings],
    ),
  ];

  static const List<AppNavigationItem> items = [
    ...guestNavigationItems,
    ...customerNavigationItems,
    ...merchantNavigationItems,
    ...workshopNavigationItems,
    ...warehouseNavigationItems,
    ...supportNavigationItems,
    ...adminNavigationItems,
  ];

  static List<AppNavigationItem> visibleItems(
    AuthState auth, {
    AppNavigationArea? area,
    bool includeSettings = true,
  }) {
    final source = _itemsForAuth(auth);
    return source.where((item) {
      if (area != null && !item.belongsTo(area)) return false;
      if (!includeSettings && item.belongsTo(AppNavigationArea.settings)) {
        return false;
      }
      return item.isVisibleFor(auth);
    }).toList(growable: false);
  }

  static AppNavigationArea areaForPath(String path) {
    if (path.startsWith('/admin')) return AppNavigationArea.admin;
    if (path.startsWith('/finance')) return AppNavigationArea.finance;
    if (path.startsWith('/merchant')) return AppNavigationArea.merchant;
    if (path.startsWith('/workshop')) return AppNavigationArea.workshop;
    if (path.startsWith('/warehouse')) return AppNavigationArea.warehouse;
    if (path.startsWith('/support')) return AppNavigationArea.support;

    final protectedMarketplacePaths = <String>{
      RouteNames.cart,
      RouteNames.checkoutPreview,
      RouteNames.compareOffers,
      RouteNames.marketplaceFavorites,
      RouteNames.customerCoupons,
      RouteNames.paymentResult,
      RouteNames.orderDetail,
      RouteNames.orderReturn,
      RouteNames.orderCancel,
      RouteNames.orderDispute,
      RouteNames.customerDisputes,
      RouteNames.customerDisputeDetail,
      RouteNames.customerOrderReview,
      RouteNames.vehicles,
      RouteNames.addVehicle,
      RouteNames.locationSelection,
      RouteNames.profileBasics,
      RouteNames.setupComplete,
      RouteNames.myAddresses,
    };

    if (path.startsWith('/customer') ||
        path.startsWith('/orders') ||
        path.startsWith('/payments') ||
        protectedMarketplacePaths.any(
          (route) => path == route || path.startsWith('$route/'),
        )) {
      return AppNavigationArea.customer;
    }

    return AppNavigationArea.public;
  }

  static AppNavigationArea effectiveAreaForPath(String path, AuthState auth) {
    final area = areaForPath(path);
    if (auth.isGuest || !auth.isAuthenticated) return AppNavigationArea.public;
    if (auth.canAccessAdminConsole &&
        (area == AppNavigationArea.public || area == AppNavigationArea.customer)) {
      return AppNavigationArea.admin;
    }
    if (auth.canOpenSupportConsole &&
        !auth.canAccessAdminConsole &&
        (area == AppNavigationArea.public || area == AppNavigationArea.customer)) {
      return AppNavigationArea.support;
    }
    if (area == AppNavigationArea.public && auth.isCustomer) {
      return AppNavigationArea.customer;
    }
    return area;
  }

  static bool isRouteSelected(String currentPath, String route) {
    if (currentPath == route) return true;
    if (route == RouteNames.adminControlCenter &&
        currentPath == RouteNames.adminOperations) {
      return true;
    }
    if (route == RouteNames.supportOperations &&
        currentPath == RouteNames.supportCenter) {
      return true;
    }
    if (route == RouteNames.marketplaceHome) {
      return currentPath == route;
    }
    return currentPath.startsWith('$route/');
  }

  static List<AppNavigationItem> _itemsForAuth(AuthState auth) {
    if (auth.isGuest || !auth.isAuthenticated) return guestNavigationItems;
    if (auth.isSuperAdmin || auth.isAdminOperations) {
      return adminNavigationItems;
    }
    if (auth.isSupportAgent) return supportNavigationItems;
    if (auth.canAccessAdminConsole) return adminNavigationItems;
    if (auth.canOpenSupportConsole) return supportNavigationItems;
    if (auth.canOpenMerchantConsole) return merchantNavigationItems;
    if (auth.canOpenWorkshopConsole) return workshopNavigationItems;
    if (auth.canOpenWarehouseConsole) return warehouseNavigationItems;
    return customerNavigationItems;
  }
}
