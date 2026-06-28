import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/features/admin/presentation/pages/admin_analytics_page.dart';
import 'package:ghiyarak/features/admin/presentation/pages/admin_audit_logs_page.dart';
import 'package:ghiyarak/features/admin/presentation/pages/admin_control_center_page.dart';
import 'package:ghiyarak/features/admin/presentation/pages/admin_dashboard_page.dart';
import 'package:ghiyarak/features/admin/presentation/pages/admin_settings_page.dart';
import 'package:ghiyarak/features/admin/presentation/pages/admin_system_hardening_page.dart';
import 'package:ghiyarak/features/admin/presentation/pages/admin_translations_page.dart';
import 'package:ghiyarak/features/admin/presentation/pages/admin_quality_release_page.dart';
import 'package:ghiyarak/features/admin/presentation/pages/admin_users_page.dart';
import 'package:ghiyarak/features/admin/presentation/pages/admin_verifications_page.dart';
import 'package:ghiyarak/features/admin/presentation/pages/admin_locations_page.dart';
import 'package:ghiyarak/features/admin/presentation/pages/admin_order_details_page.dart';
import 'package:ghiyarak/features/admin/presentation/pages/admin_orders_page.dart';
import 'package:ghiyarak/features/auth/logic/auth_controller.dart';
import 'package:ghiyarak/features/auth/logic/auth_state.dart';
import 'package:ghiyarak/features/auth/presentation/pages/login_page.dart';
import 'package:ghiyarak/features/auth/presentation/pages/otp_page.dart';
import 'package:ghiyarak/features/auth/presentation/pages/email_link_auth_page.dart';
import 'package:ghiyarak/features/auth/presentation/pages/register_page.dart';
import 'package:ghiyarak/features/authorization/presentation/permission_guard.dart';
import 'package:ghiyarak/features/authorization/presentation/unauthorized_page.dart';
import 'package:ghiyarak/features/cart/presentation/pages/cart_page.dart';
import 'package:ghiyarak/features/cart/presentation/pages/checkout_preview_page.dart';
import 'package:ghiyarak/features/cart/presentation/pages/customer_coupons_page.dart';
import 'package:ghiyarak/features/cart/presentation/pages/payment_result_page.dart';
import 'package:ghiyarak/features/chat/presentation/customer_chat_page.dart';
import 'package:ghiyarak/features/customer/presentation/customer_rewards_page.dart';
import 'package:ghiyarak/features/marketplace/presentation/pages/address_page.dart';
import 'package:ghiyarak/features/marketplace/presentation/pages/categories_page.dart';
import 'package:ghiyarak/features/marketplace/presentation/pages/compare_offers_page.dart';
import 'package:ghiyarak/features/marketplace/presentation/pages/favorites_page.dart';
import 'package:ghiyarak/features/marketplace/presentation/pages/provider_profile_page.dart';
import 'package:ghiyarak/features/marketplace/presentation/pages/provider_reviews_page.dart';
import 'package:ghiyarak/features/marketplace/presentation/pages/support_page.dart';
import 'package:ghiyarak/features/orders/presentation/pages/customer_dispute_detail_page.dart';
import 'package:ghiyarak/features/orders/presentation/pages/customer_disputes_page.dart';
import 'package:ghiyarak/features/orders/presentation/pages/customer_order_review_page.dart';
import 'package:ghiyarak/features/orders/presentation/pages/order_cancel_page.dart';
import 'package:ghiyarak/features/orders/presentation/pages/order_detail_page.dart';
import 'package:ghiyarak/features/orders/presentation/pages/order_dispute_page.dart';
import 'package:ghiyarak/features/orders/presentation/pages/order_return_page.dart';
import 'package:ghiyarak/features/profile/presentation/pages/customer_profile_page.dart';
import 'package:ghiyarak/features/profile/presentation/pages/customer_settings_page.dart';
import 'package:ghiyarak/features/customer/presentation/customer_center_page.dart';
import 'package:ghiyarak/features/customer/presentation/customer_maintenance_page.dart';
import 'package:ghiyarak/features/customer/presentation/customer_order_tracking_page.dart';
import 'package:ghiyarak/features/customer/presentation/customer_parts_page.dart';
import 'package:ghiyarak/features/customer/presentation/customer_vehicle_selector_page.dart';
import 'package:ghiyarak/features/entry/presentation/entry_page.dart';
import 'package:ghiyarak/features/locations/presentation/location_selection_page.dart';
import 'package:ghiyarak/features/locations/presentation/my_addresses_page.dart';
import 'package:ghiyarak/features/logistics/presentation/pages/merchant_fulfillment_hub_page.dart';
import 'package:ghiyarak/features/logistics/presentation/pages/notifications_center_page.dart';
import 'package:ghiyarak/features/logistics/presentation/pages/payment_selection_page.dart';
import 'package:ghiyarak/features/logistics/presentation/pages/payment_status_page.dart';
import 'package:ghiyarak/features/logistics/presentation/pages/finance_review_page.dart';
import 'package:ghiyarak/features/logistics/presentation/pages/finance_refunds_page.dart';
import 'package:ghiyarak/features/logistics/presentation/pages/finance_settlements_page.dart';
import 'package:ghiyarak/features/logistics/presentation/pages/finance_accounting_page.dart';
import 'package:ghiyarak/features/logistics/presentation/pages/shipments_page.dart';
import 'package:ghiyarak/features/marketplace/presentation/pages/listing_detail_page.dart';
import 'package:ghiyarak/features/marketplace/presentation/pages/marketplace_home_page.dart';
import 'package:ghiyarak/features/marketplace/presentation/pages/marketplace_search_page.dart';
import 'package:ghiyarak/features/merchant_market/presentation/pages/create_listing_page.dart'
    as merchant_market;
import 'package:ghiyarak/features/merchant_market/presentation/pages/create_merchant_branch_page.dart'
    as merchant_market;
import 'package:ghiyarak/features/merchant_market/presentation/pages/edit_listing_page.dart'
    as merchant_market;
import 'package:ghiyarak/features/merchant_market/presentation/pages/merchant_branch_details_page.dart'
    as merchant_market;
import 'package:ghiyarak/features/merchant_market/presentation/pages/merchant_branch_edit_loader_page.dart'
    as merchant_market;
import 'package:ghiyarak/features/merchant_market/presentation/pages/merchant_branches_page.dart'
    as merchant_market;
import 'package:ghiyarak/features/merchant_market/presentation/pages/merchant_hub_page.dart'
    as merchant_market;
import 'package:ghiyarak/features/merchant_market/presentation/pages/merchant_inventory_page.dart'
    as merchant_market;
import 'package:ghiyarak/features/merchant_market/presentation/pages/merchant_listing_details_page.dart'
    as merchant_market;
import 'package:ghiyarak/features/merchant_market/presentation/pages/merchant_listings_page.dart'
    as merchant_market;
import 'package:ghiyarak/features/merchant_market/presentation/pages/merchant_notifications_page.dart'
    as merchant_market;
import 'package:ghiyarak/features/merchant_market/presentation/pages/merchant_order_details_page.dart'
    as merchant_market;
import 'package:ghiyarak/features/merchant_market/presentation/pages/merchant_orders_page.dart'
    as merchant_market;
import 'package:ghiyarak/features/merchant_market/presentation/pages/merchant_reports_page.dart'
    as merchant_market;
import 'package:ghiyarak/features/merchant_market/presentation/pages/merchant_settings_page.dart'
    as merchant_market;
import 'package:ghiyarak/features/merchant_market/presentation/pages/merchant_status_page.dart'
    as merchant_market;
import 'package:ghiyarak/features/merchant_market/presentation/pages/merchant_team_page.dart'
    as merchant_market;
import 'package:ghiyarak/features/merchant_market/presentation/pages/catalog_management/merchant_bulk_import_page.dart'
    as merchant_market;
import 'package:ghiyarak/features/merchant_market/presentation/pages/catalog_management/merchant_categories_manager_page.dart'
    as merchant_market;
import 'package:ghiyarak/features/merchant_market/presentation/pages/catalog_management/merchant_compatibility_manager_page.dart'
    as merchant_market;
import 'package:ghiyarak/features/merchant_market/presentation/pages/catalog_management/merchant_data_quality_page.dart'
    as merchant_market;
import 'package:ghiyarak/features/merchant_market/presentation/pages/finance_reports/merchant_finance_overview_page.dart'
    as merchant_market;
import 'package:ghiyarak/features/merchant_market/presentation/pages/finance_reports/merchant_invoices_page.dart'
    as merchant_market;
import 'package:ghiyarak/features/merchant_market/presentation/pages/finance_reports/merchant_notification_settings_page.dart'
    as merchant_market;
import 'package:ghiyarak/features/merchant_market/presentation/pages/finance_reports/merchant_payments_page.dart'
    as merchant_market;
import 'package:ghiyarak/features/merchant_market/presentation/pages/finance_reports/merchant_promotions_page.dart'
    as merchant_market;
import 'package:ghiyarak/features/merchant_market/presentation/pages/finance_reports/merchant_settlements_page.dart'
    as merchant_market;
import 'package:ghiyarak/features/merchant_market/presentation/pages/finance_reports/merchant_wallet_page.dart'
    as merchant_market;
import 'package:ghiyarak/features/merchant_market/presentation/pages/sales_operations/merchant_customer_chats_page.dart'
    as merchant_market;
import 'package:ghiyarak/features/merchant_market/presentation/pages/sales_operations/merchant_disputes_page.dart'
    as merchant_market;
import 'package:ghiyarak/features/merchant_market/presentation/pages/sales_operations/merchant_returns_page.dart'
    as merchant_market;
import 'package:ghiyarak/features/merchant_market/presentation/pages/sales_operations/merchant_reviews_page.dart'
    as merchant_market;
import 'package:ghiyarak/features/merchant_market/presentation/pages/sales_operations/merchant_shipments_page.dart'
    as merchant_market;
import 'package:ghiyarak/features/merchant_market/presentation/pages/store_profile/merchant_policies_page.dart'
    as merchant_market;
import 'package:ghiyarak/features/merchant_market/presentation/pages/store_profile/merchant_store_profile_page.dart'
    as merchant_market;
import 'package:ghiyarak/features/merchant_market/presentation/pages/store_profile/merchant_verification_page.dart'
    as merchant_market;
import 'package:ghiyarak/features/merchant_market/presentation/pages/team_permissions/merchant_audit_log_page.dart'
    as merchant_market;
import 'package:ghiyarak/features/merchant_market/presentation/pages/team_permissions/merchant_employees_page.dart'
    as merchant_market;
import 'package:ghiyarak/features/merchant_market/presentation/pages/team_permissions/merchant_roles_permissions_page.dart'
    as merchant_market;
import 'package:ghiyarak/features/orders/presentation/pages/my_orders_page.dart';
import 'package:ghiyarak/features/orders/presentation/pages/order_details_page.dart';
import 'package:ghiyarak/features/organization_management/presentation/pages/branch_employee_management_page.dart';
import 'package:ghiyarak/features/product_imports/presentation/product_imports_page.dart';
import 'package:ghiyarak/features/profile/presentation/profile_basics_page.dart';
import 'package:ghiyarak/features/provider_onboarding/presentation/provider_bank_account_page.dart';
import 'package:ghiyarak/features/provider_onboarding/presentation/provider_branch_page.dart';
import 'package:ghiyarak/features/provider_onboarding/presentation/provider_business_hours_page.dart';
import 'package:ghiyarak/features/provider_onboarding/presentation/provider_documents_page.dart';
import 'package:ghiyarak/features/provider_onboarding/presentation/provider_organization_page.dart';
import 'package:ghiyarak/features/provider_onboarding/presentation/provider_profile_page.dart';
import 'package:ghiyarak/features/provider_onboarding/presentation/provider_status_page.dart';
import 'package:ghiyarak/features/provider_onboarding/presentation/provider_type_page.dart';
import 'package:ghiyarak/features/setup_complete/presentation/setup_complete_page.dart';
import 'package:ghiyarak/features/splash/presentation/splash_page.dart';
import 'package:ghiyarak/features/settings/presentation/pages/settings_page.dart';
import 'package:ghiyarak/features/support_services/presentation/pages/complaints_page.dart';
import 'package:ghiyarak/features/support_services/presentation/pages/reviews_page.dart';
import 'package:ghiyarak/features/support_services/presentation/pages/support_operations_hub_page.dart';
import 'package:ghiyarak/features/support_services/presentation/pages/support_tickets_page.dart';
import 'package:ghiyarak/features/support_services/presentation/pages/ticket_details_page.dart';
import 'package:ghiyarak/features/support_services/presentation/pages/help_center_page.dart';
import 'package:ghiyarak/features/vehicles/presentation/add_vehicle_page.dart';
import 'package:ghiyarak/features/vehicles/presentation/vehicles_page.dart';
import 'package:ghiyarak/features/wallet_loyalty/presentation/pages/admin_coupons_page.dart';
import 'package:ghiyarak/features/wallet_loyalty/presentation/pages/loyalty_page.dart';
import 'package:ghiyarak/features/wallet_loyalty/presentation/pages/referral_dashboard_page.dart';
import 'package:ghiyarak/features/wallet_loyalty/presentation/pages/retention_campaigns_page.dart';
import 'package:ghiyarak/features/wallet_loyalty/presentation/pages/wallet_page.dart';
import 'package:ghiyarak/features/workshops/presentation/pages/workshop_bookings_management_page.dart';
import 'package:ghiyarak/features/workshops/presentation/pages/workshop_operations_hub_page.dart';
import 'package:ghiyarak/features/workshops/presentation/pages/workshop_service_orders_page.dart';
import 'package:ghiyarak/features/warehouse/presentation/pages/warehouse_hub_page.dart';
import 'package:ghiyarak/features/workshops/presentation/pages/workshop_services_management_page.dart';
import 'package:ghiyarak/shared/navigation/app_route_resolver.dart';
import 'package:go_router/go_router.dart';

final _routerRefreshProvider = Provider<_RouterRefreshNotifier>((ref) {
  final notifier = _RouterRefreshNotifier();
  ref.listen<AuthState>(authControllerProvider, (_, __) => notifier.refresh());
  ref.onDispose(notifier.dispose);
  return notifier;
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ref.watch(_routerRefreshProvider);
  return GoRouter(
    initialLocation: RouteNames.splash,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final path = state.uri.path;
      final isAdminRoute = path.startsWith('/admin');
      final isMerchantRoute = path.startsWith('/merchant');
      final isWorkshopRoute = path.startsWith('/workshop');
      final isWarehouseRoute = path.startsWith('/warehouse');
      final isSupportRoute = path.startsWith('/support');
      final isProductImportRoute = path.startsWith('/product-imports');
      final isProviderOnboardingRoute = path.startsWith('/provider-onboarding');
      final isPublicRoute = AppRouteResolver.isPublicPath(path);
      final isCustomerProtectedRoute =
          AppRouteResolver.isCustomerProtectedPath(path);

      if (authState.status == AuthStatus.loading) return null;

      if (authState.isGuest) {
        if (AppRouteResolver.isAuthEntryPath(path) || isPublicRoute) {
          return null;
        }
        return '${RouteNames.login}?accountType=login&next=${Uri.encodeComponent(state.uri.toString())}';
      }

      if (authState.isAuthenticated) {
        if (AppRouteResolver.isAuthEntryPath(path) ||
            path == RouteNames.splash ||
            path == RouteNames.entry) {
          return AppRouteResolver.landingRouteFor(authState);
        }

        if (path == RouteNames.supportCenter) {
          return RouteNames.supportOperations;
        }

        if (isCustomerProtectedRoute &&
            authState.hasAdministrativeAccess &&
            !authState.isCustomer) {
          return AppRouteResolver.landingRouteFor(authState);
        }

        if (isAdminRoute && !authState.canAccessAdminConsole) {
          return RouteNames.unauthorized;
        }
        if (isMerchantRoute && !authState.canOpenMerchantConsole) {
          return _providerOrUnauthorized(authState, 'MERCHANT');
        }
        if (isWorkshopRoute && !authState.canOpenWorkshopConsole) {
          return _providerOrUnauthorized(authState, 'WORKSHOP');
        }
        if (isWarehouseRoute && !authState.canOpenWarehouseConsole) {
          return _providerOrUnauthorized(authState, 'WAREHOUSE');
        }
        if (isSupportRoute && !authState.canOpenSupportConsole) {
          return RouteNames.unauthorized;
        }
        if (isProviderOnboardingRoute && !authState.canOpenProviderOnboarding) {
          return RouteNames.unauthorized;
        }
        if (isProductImportRoute &&
            !(authState.canOpenMerchantConsole ||
                authState.canOpenWorkshopConsole ||
                authState.canOpenWarehouseConsole ||
                authState.isSuperAdmin ||
                authState.isAdminOperations)) {
          return RouteNames.unauthorized;
        }
        return null;
      }

      if (isPublicRoute) return null;
      if (isAdminRoute ||
          isMerchantRoute ||
          isWorkshopRoute ||
          isWarehouseRoute ||
          isSupportRoute ||
          isProductImportRoute ||
          isProviderOnboardingRoute ||
          isCustomerProtectedRoute) {
        return AppRouteResolver.loginRouteForNext(state.uri.toString());
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/admin',
        redirect: (context, state) {
          final authState = ref.read(authControllerProvider);
          if (!authState.isAuthenticated) {
            return AppRouteResolver.loginRouteForNext(state.uri.toString());
          }
          if (!authState.canAccessAdminConsole) {
            return RouteNames.unauthorized;
          }
          return AppRouteResolver.landingRouteFor(authState);
        },
      ),
      GoRoute(
        path: '/support',
        redirect: (context, state) {
          final authState = ref.read(authControllerProvider);
          if (!authState.isAuthenticated) {
            return AppRouteResolver.loginRouteForNext(state.uri.toString());
          }
          if (!authState.canOpenSupportConsole) {
            return RouteNames.unauthorized;
          }
          return RouteNames.supportOperations;
        },
      ),
      GoRoute(
          path: RouteNames.splash,
          builder: (context, state) => const SplashPage()),
      GoRoute(
          path: RouteNames.entry,
          builder: (context, state) => const EntryPage()),
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => LoginPage(
          accountType: state.uri.queryParameters['accountType'] ?? 'login',
          nextRoute: state.uri.queryParameters['next'],
        ),
      ),
      GoRoute(
          path: RouteNames.register,
          builder: (context, state) => RegisterPage(
              accountType: state.uri.queryParameters['accountType'] ?? '')),
      GoRoute(
          path: RouteNames.otp,
          builder: (context, state) => OtpPage(
              phone: state.uri.queryParameters['phone'] ?? '',
              accountType: state.uri.queryParameters['accountType'] ?? 'login',
              displayName: state.uri.queryParameters['displayName'] ?? '',
              email: state.uri.queryParameters['email'] ?? '',
              nextRoute: state.uri.queryParameters['next'],
              authProvider:
                  state.uri.queryParameters['authProvider'] ?? 'backend_otp',
              verificationId: state.uri.queryParameters['verificationId'] ?? '',
              devOtp: state.uri.queryParameters['devOtp'] ?? '')),
      GoRoute(
          path: RouteNames.emailLink,
          builder: (context, state) => EmailLinkAuthPage(
              accountType:
                  state.uri.queryParameters['accountType'] ?? 'customer',
              initialEmail: state.uri.queryParameters['email'] ?? '')),
      GoRoute(
          path: RouteNames.emailLinkCallback,
          builder: (context, state) => EmailLinkAuthPage(
              accountType:
                  state.uri.queryParameters['accountType'] ?? 'customer',
              initialEmail: state.uri.queryParameters['email'] ?? '')),
      GoRoute(
          path: RouteNames.unauthorized,
          builder: (context, state) => const UnauthorizedPage()),
      GoRoute(
          path: RouteNames.profileBasics,
          builder: (context, state) => const _RequireAccess(
              roles: ['customer', 'admin_super'], child: ProfileBasicsPage())),
      GoRoute(
          path: RouteNames.locationSelection,
          builder: (context, state) => const _RequireAccess(
              roles: ['customer', 'admin_super'],
              child: LocationSelectionPage())),
      GoRoute(
          path: RouteNames.myAddresses,
          builder: (context, state) => const _RequireAccess(
              roles: ['customer', 'admin_super'], child: MyAddressesPage())),
      GoRoute(
          path: RouteNames.vehicles,
          builder: (context, state) => const _RequireAccess(
              roles: ['customer', 'admin_super'], child: VehiclesPage())),
      GoRoute(
          path: RouteNames.addVehicle,
          builder: (context, state) => const _RequireAccess(
              roles: ['customer', 'admin_super'], child: AddVehiclePage())),
      GoRoute(
          path: RouteNames.setupComplete,
          builder: (context, state) => const _RequireAccess(
              roles: ['customer', 'admin_super'], child: SetupCompletePage())),
      GoRoute(
          path: RouteNames.providerType,
          builder: (context, state) => const ProviderTypePage()),
      GoRoute(
          path: RouteNames.providerOrganization,
          builder: (context, state) => const ProviderOrganizationPage()),
      GoRoute(
          path: RouteNames.providerBranch,
          builder: (context, state) => const ProviderBranchPage()),
      GoRoute(
          path: RouteNames.providerProfile,
          builder: (context, state) => const ProviderProfilePage()),
      GoRoute(
          path: RouteNames.providerBankAccount,
          builder: (context, state) => const ProviderBankAccountPage()),
      GoRoute(
          path: RouteNames.providerBusinessHours,
          builder: (context, state) => const ProviderBusinessHoursPage()),
      GoRoute(
          path: RouteNames.providerDocuments,
          builder: (context, state) => const ProviderDocumentsPage()),
      GoRoute(
          path: RouteNames.providerStatus,
          builder: (context, state) => const ProviderStatusPage()),
      GoRoute(
          path: RouteNames.marketplaceHome,
          builder: (context, state) => const MarketplaceHomePage()),
      GoRoute(
          path: RouteNames.marketplaceSearch,
          builder: (context, state) => MarketplaceSearchPage(
              initialCategoryId: state.uri.queryParameters['categoryId'],
              initialCategoryName: state.uri.queryParameters['categoryName'])),
      GoRoute(
          path: '${RouteNames.listingDetail}/:id',
          builder: (context, state) =>
              ListingDetailPage(listingId: state.pathParameters['id']!)),
      GoRoute(
          path: RouteNames.marketplaceCategories,
          builder: (context, state) => const CategoriesPage()),
      GoRoute(
          path: '${RouteNames.marketplaceProviderProfile}/:id',
          builder: (context, state) => MarketplaceProviderProfilePage(
              providerId: state.pathParameters['id']!,
              providerName: state.uri.queryParameters['providerName'] ?? '',
              providerTypeLabel:
                  state.uri.queryParameters['providerTypeLabel'] ?? 'مزود',
              serviceLabel: state.uri.queryParameters['serviceLabel'] ?? 'خدمة',
              cityName: state.uri.queryParameters['cityName'],
              listingTitle: state.uri.queryParameters['listingTitle'],
              listingId: state.uri.queryParameters['listingId'])),
      GoRoute(
          path: '${RouteNames.providerReviews}/:id',
          builder: (context, state) => ProviderReviewsPage(
              providerId: state.pathParameters['id']!,
              providerName:
                  state.uri.queryParameters['providerName'] ?? 'المزود')),
      GoRoute(
          path: RouteNames.compareOffers,
          builder: (context, state) => _RequireAccess(
              roles: const ['customer', 'admin_super'],
              child: CompareOffersPage(
                  query: state.uri.queryParameters['q'] ?? '',
                  selectedListingId: state.uri.queryParameters['listingId']))),
      GoRoute(
          path: RouteNames.marketplaceFavorites,
          builder: (context, state) => const _RequireAccess(
              roles: ['customer', 'admin_super'], child: FavoritesPage())),
      GoRoute(
          path: RouteNames.cart,
          builder: (context, state) => const _RequireAccess(
              roles: ['customer', 'admin_super'], child: CartPage())),
      GoRoute(
          path: RouteNames.checkoutPreview,
          builder: (context, state) => const _RequireAccess(
              roles: ['customer', 'admin_super'],
              child: CheckoutPreviewPage())),
      GoRoute(
          path: RouteNames.customerCoupons,
          builder: (context, state) => const _RequireAccess(
              roles: ['customer', 'admin_super'],
              child: CustomerCouponsPage())),
      GoRoute(
          path: '${RouteNames.paymentResult}/:id',
          builder: (context, state) => _RequireAccess(
              roles: const ['customer', 'admin_super'],
              child: PaymentResultPage(orderId: state.pathParameters['id']!))),
      GoRoute(
          path: RouteNames.myOrders,
          builder: (context, state) => const _RequireAccess(
              roles: ['customer', 'admin_super'], child: MyOrdersPage())),
      GoRoute(
          path: '/orders/:id',
          builder: (context, state) => _RequireAccess(
              roles: const ['customer', 'admin_super'],
              child: OrderDetailsPage(orderId: state.pathParameters['id']!))),
      GoRoute(
          path: '/orders/:id/payment',
          builder: (context, state) => _RequireAccess(
              roles: const ['customer', 'admin_super'],
              child:
                  PaymentSelectionPage(orderId: state.pathParameters['id']!))),
      GoRoute(
          path: '/payments/:id/status',
          builder: (context, state) => _RequireAccess(
              roles: const ['customer', 'admin_super'],
              child:
                  PaymentStatusPage(paymentId: state.pathParameters['id']!))),
      GoRoute(
          path: '${RouteNames.orderDetail}/:id',
          builder: (context, state) => _RequireAccess(
              roles: const ['customer', 'admin_super'],
              child: OrderDetailPage(orderId: state.pathParameters['id']!))),
      GoRoute(
          path: '${RouteNames.orderReturn}/:id',
          builder: (context, state) => _RequireAccess(
              roles: const ['customer', 'admin_super'],
              child: OrderReturnPage(orderId: state.pathParameters['id']!))),
      GoRoute(
          path: '${RouteNames.orderCancel}/:id',
          builder: (context, state) => _RequireAccess(
              roles: const ['customer', 'admin_super'],
              child: OrderCancelPage(orderId: state.pathParameters['id']!))),
      GoRoute(
          path: '${RouteNames.customerOrderReview}/:id',
          builder: (context, state) => _RequireAccess(
              roles: const ['customer', 'admin_super'],
              child: CustomerOrderReviewPage(
                  orderId: state.pathParameters['id']!))),
      GoRoute(
          path: '${RouteNames.orderDispute}/:id',
          builder: (context, state) => _RequireAccess(
              roles: const ['customer', 'admin_super'],
              child: OrderDisputePage(orderId: state.pathParameters['id']!))),
      GoRoute(
          path: RouteNames.customerDisputes,
          builder: (context, state) => const _RequireAccess(
              roles: ['customer', 'admin_super'],
              child: CustomerDisputesPage())),
      GoRoute(
          path: '${RouteNames.customerDisputeDetail}/:id',
          builder: (context, state) => _RequireAccess(
              roles: const ['customer', 'admin_super'],
              child: CustomerDisputeDetailPage(
                  disputeId: state.pathParameters['id']!))),
      GoRoute(
          path: RouteNames.customerCenter,
          builder: (context, state) => const _RequireAccess(
              roles: ['customer', 'admin_super'], child: CustomerCenterPage())),
      GoRoute(
          path: RouteNames.customerProfile,
          builder: (context, state) => const _RequireAccess(
              roles: ['customer', 'admin_super'],
              child: CustomerProfilePage())),
      GoRoute(
          path: RouteNames.customerSettings,
          builder: (context, state) => const _RequireAccess(
              roles: ['customer', 'admin_super'],
              child: CustomerSettingsPage())),
      GoRoute(
          path: RouteNames.customerAddresses,
          builder: (context, state) => const _RequireAccess(
              roles: ['customer', 'admin_super'], child: AddressPage())),
      GoRoute(
          path: RouteNames.customerRewards,
          builder: (context, state) => const _RequireAccess(
              roles: ['customer', 'admin_super'],
              child: CustomerRewardsPage())),
      GoRoute(
          path: RouteNames.customerSupport,
          builder: (context, state) => const _RequireAccess(
              roles: ['customer', 'admin_super'], child: SupportPage())),
      GoRoute(
          path: RouteNames.customerChat,
          builder: (context, state) => _RequireAccess(
              roles: const ['customer', 'admin_super'],
              child: CustomerChatPage(
                  listingId: state.uri.queryParameters['listingId'] ?? '',
                  listingTitle: state.uri.queryParameters['listingTitle'] ??
                      'استفسار عن قطعة',
                  providerName:
                      state.uri.queryParameters['providerName'] ?? 'مزود',
                  providerTypeLabel:
                      state.uri.queryParameters['providerTypeLabel'] ?? 'مزود',
                  serviceLabel: state.uri.queryParameters['serviceLabel'] ??
                      'خدمة غير محددة'))),
      GoRoute(
          path: RouteNames.customerVehicle,
          builder: (context, state) => const _RequireAccess(
              roles: ['customer', 'admin_super'],
              child: CustomerVehicleSelectorPage())),
      GoRoute(
        path: RouteNames.customerParts,
        builder: (context, state) => const _RequireAccess(
          roles: ['customer', 'admin_super'],
          child: CustomerPartsPage(),
        ),
      ),
      GoRoute(
          path: RouteNames.customerTracking,
          builder: (context, state) => const _RequireAccess(
              roles: ['customer', 'admin_super'],
              child: CustomerOrderTrackingPage())),
      GoRoute(
          path: RouteNames.customerMaintenance,
          builder: (context, state) => const _RequireAccess(
              roles: ['customer', 'admin_super'],
              child: CustomerMaintenancePage())),
      GoRoute(
          path: RouteNames.customerShipments,
          builder: (context, state) => const _RequireAccess(
              roles: ['customer', 'admin_super'], child: ShipmentsPage())),
      GoRoute(
          path: RouteNames.customerNotifications,
          builder: (context, state) => const _RequireAccess(roles: [
                'customer',
                'admin_super',
                'merchant_owner',
                'workshop_owner',
                'support_agent'
              ], child: NotificationsCenterPage())),
      GoRoute(
          path: RouteNames.customerWallet,
          builder: (context, state) => const _RequireAccess(
              roles: ['customer', 'admin_super'], child: WalletPage())),
      GoRoute(
          path: RouteNames.customerLoyalty,
          builder: (context, state) => const _RequireAccess(
              roles: ['customer', 'admin_super'], child: LoyaltyPage())),
      GoRoute(
          path: RouteNames.customerReferrals,
          builder: (context, state) => const _RequireAccess(
              roles: ['customer', 'admin_super'],
              child: ReferralDashboardPage())),
      GoRoute(
          path: RouteNames.adminCoupons,
          builder: (context, state) => const _RequireAccess(
              permissions: ['coupons.manage', 'manage_system'],
              child: AdminCouponsPage())),
      GoRoute(
          path: RouteNames.customerSupportTickets,
          builder: (context, state) => const _RequireAccess(
              roles: ['customer', 'admin_super'], child: SupportTicketsPage())),
      GoRoute(
          path: '/customer/support-tickets/:id',
          builder: (context, state) => _RequireAccess(
                  roles: const [
                    'customer',
                    'support_agent',
                    'admin_super',
                    'admin_operations'
                  ],
                  child: TicketDetailsPage(
                      ticketId: state.pathParameters['id']!))),
      GoRoute(
          path: RouteNames.customerComplaints,
          builder: (context, state) => const _RequireAccess(
              roles: ['customer', 'admin_super'], child: ComplaintsPage())),
      GoRoute(
          path: RouteNames.customerReviews,
          builder: (context, state) => const _RequireAccess(
              roles: ['customer', 'admin_super'], child: ReviewsPage())),
      GoRoute(
          path: RouteNames.settings,
          builder: (context, state) => const SettingsPage()),
      GoRoute(
          path: RouteNames.merchantHub,
          builder: (context, state) => const _RequireAccess(
              roles: ['merchant_owner', 'admin_super', 'admin_operations'],
              approvedOrganizationTypes: ['MERCHANT'],
              child: merchant_market.MerchantHubPage())),
      GoRoute(
          path: RouteNames.merchantListings,
          builder: (context, state) => const _RequireAccess(
              roles: ['merchant_owner', 'admin_super', 'admin_operations'],
              approvedOrganizationTypes: ['MERCHANT'],
              child: merchant_market.MerchantListingsPage())),
      GoRoute(
          path: RouteNames.createListing,
          builder: (context, state) => const _RequireAccess(
              roles: ['merchant_owner', 'admin_super', 'admin_operations'],
              approvedOrganizationTypes: ['MERCHANT'],
              child: merchant_market.CreateListingPage())),
      GoRoute(
          path: '/merchant/listings/:id/details',
          builder: (context, state) => _RequireAccess(
                  roles: const [
                    'merchant_owner',
                    'admin_super',
                    'admin_operations'
                  ],
                  approvedOrganizationTypes: const [
                    'MERCHANT'
                  ],
                  child: merchant_market.MerchantListingDetailsPage(
                      listingId: state.pathParameters['id']!))),
      GoRoute(
          path: '/merchant/listings/:id/edit',
          builder: (context, state) => _RequireAccess(
                  roles: const [
                    'merchant_owner',
                    'admin_super',
                    'admin_operations'
                  ],
                  approvedOrganizationTypes: const [
                    'MERCHANT'
                  ],
                  child: merchant_market.EditListingPage(
                      listingId: state.pathParameters['id']!))),
      GoRoute(
          path: RouteNames.merchantInventory,
          builder: (context, state) => const _RequireAccess(
              roles: ['merchant_owner', 'admin_super', 'admin_operations'],
              approvedOrganizationTypes: ['MERCHANT'],
              child: merchant_market.MerchantInventoryPage())),
      GoRoute(
          path: RouteNames.merchantBranches,
          builder: (context, state) => const _RequireAccess(
              roles: ['merchant_owner', 'admin_super', 'admin_operations'],
              approvedOrganizationTypes: ['MERCHANT'],
              child: merchant_market.MerchantBranchesPage())),
      GoRoute(
          path: RouteNames.createMerchantBranch,
          builder: (context, state) => const _RequireAccess(
              roles: ['merchant_owner', 'admin_super', 'admin_operations'],
              approvedOrganizationTypes: ['MERCHANT'],
              child: merchant_market.CreateMerchantBranchPage())),
      GoRoute(
          path: '/merchant/branches/:id/details',
          builder: (context, state) => _RequireAccess(
                  roles: const [
                    'merchant_owner',
                    'admin_super',
                    'admin_operations'
                  ],
                  approvedOrganizationTypes: const [
                    'MERCHANT'
                  ],
                  child: merchant_market.MerchantBranchDetailsPage(
                      branchId: state.pathParameters['id']!))),
      GoRoute(
          path: '/merchant/branches/:id/edit',
          builder: (context, state) => _RequireAccess(
                  roles: const [
                    'merchant_owner',
                    'admin_super',
                    'admin_operations'
                  ],
                  approvedOrganizationTypes: const [
                    'MERCHANT'
                  ],
                  child: merchant_market.MerchantBranchEditLoaderPage(
                      branchId: state.pathParameters['id']!))),
      GoRoute(
          path: RouteNames.merchantTeam,
          builder: (context, state) => const _RequireAccess(
              roles: ['merchant_owner', 'admin_super', 'admin_operations'],
              approvedOrganizationTypes: ['MERCHANT'],
              child: merchant_market.MerchantTeamPage())),
      GoRoute(
          path: RouteNames.merchantEmployees,
          builder: (context, state) => const _RequireAccess(
              roles: ['merchant_owner', 'admin_super', 'admin_operations'],
              approvedOrganizationTypes: ['MERCHANT'],
              child: merchant_market.MerchantEmployeesPage())),
      GoRoute(
          path: RouteNames.merchantRolesPermissions,
          builder: (context, state) => const _RequireAccess(
              roles: ['merchant_owner', 'admin_super', 'admin_operations'],
              approvedOrganizationTypes: ['MERCHANT'],
              child: merchant_market.MerchantRolesPermissionsPage())),
      GoRoute(
          path: RouteNames.merchantAuditLog,
          builder: (context, state) => const _RequireAccess(
              roles: ['merchant_owner', 'admin_super', 'admin_operations'],
              approvedOrganizationTypes: ['MERCHANT'],
              child: merchant_market.MerchantAuditLogPage())),
      GoRoute(
          path: RouteNames.productImports,
          builder: (context, state) => const _RequireAccess(roles: [
                'merchant_owner',
                'workshop_owner',
                'warehouse_owner',
                'admin_super',
                'admin_operations'
              ], approvedOrganizationTypes: [
                'MERCHANT',
                'WORKSHOP',
                'WAREHOUSE'
              ], child: ProductImportsPage())),
      GoRoute(
          path: RouteNames.branchEmployeeManagement,
          builder: (context, state) => const _RequireAccess(roles: [
                'merchant_owner',
                'workshop_owner',
                'warehouse_owner',
                'admin_super',
                'admin_operations'
              ], approvedOrganizationTypes: [
                'MERCHANT',
                'WORKSHOP',
                'WAREHOUSE'
              ], child: BranchEmployeeManagementPage())),
      GoRoute(
          path: RouteNames.merchantCategoriesManager,
          builder: (context, state) => const _RequireAccess(
              roles: ['merchant_owner', 'admin_super', 'admin_operations'],
              approvedOrganizationTypes: ['MERCHANT'],
              child: merchant_market.MerchantCategoriesManagerPage())),
      GoRoute(
          path: RouteNames.merchantCompatibilityManager,
          builder: (context, state) => const _RequireAccess(
              roles: ['merchant_owner', 'admin_super', 'admin_operations'],
              approvedOrganizationTypes: ['MERCHANT'],
              child: merchant_market.MerchantCompatibilityManagerPage())),
      GoRoute(
          path: RouteNames.merchantDataQuality,
          builder: (context, state) => const _RequireAccess(
              roles: ['merchant_owner', 'admin_super', 'admin_operations'],
              approvedOrganizationTypes: ['MERCHANT'],
              child: merchant_market.MerchantDataQualityPage())),
      GoRoute(
          path: RouteNames.merchantBulkImport,
          builder: (context, state) => const _RequireAccess(
              roles: ['merchant_owner', 'admin_super', 'admin_operations'],
              approvedOrganizationTypes: ['MERCHANT'],
              child: merchant_market.MerchantBulkImportPage())),
      GoRoute(
          path: RouteNames.merchantOrders,
          builder: (context, state) => const _RequireAccess(
              roles: ['merchant_owner', 'admin_super', 'admin_operations'],
              approvedOrganizationTypes: ['MERCHANT'],
              child: merchant_market.MerchantOrdersPage())),
      GoRoute(
          path: '/merchant/orders/:id',
          builder: (context, state) => _RequireAccess(
                  roles: const [
                    'merchant_owner',
                    'admin_super',
                    'admin_operations'
                  ],
                  approvedOrganizationTypes: const [
                    'MERCHANT'
                  ],
                  child: merchant_market.MerchantOrderDetailsPage(
                      orderId: state.pathParameters['id']!))),
      GoRoute(
          path: RouteNames.merchantReturns,
          builder: (context, state) => const _RequireAccess(
              roles: ['merchant_owner', 'admin_super', 'admin_operations'],
              approvedOrganizationTypes: ['MERCHANT'],
              child: merchant_market.MerchantReturnsPage())),
      GoRoute(
          path: RouteNames.merchantDisputes,
          builder: (context, state) => const _RequireAccess(
              roles: ['merchant_owner', 'admin_super', 'admin_operations'],
              approvedOrganizationTypes: ['MERCHANT'],
              child: merchant_market.MerchantDisputesPage())),
      GoRoute(
          path: RouteNames.merchantReviews,
          builder: (context, state) => const _RequireAccess(
              roles: ['merchant_owner', 'admin_super', 'admin_operations'],
              approvedOrganizationTypes: ['MERCHANT'],
              child: merchant_market.MerchantReviewsPage())),
      GoRoute(
          path: RouteNames.merchantCustomerChats,
          builder: (context, state) => const _RequireAccess(
              roles: ['merchant_owner', 'admin_super', 'admin_operations'],
              approvedOrganizationTypes: ['MERCHANT'],
              child: merchant_market.MerchantCustomerChatsPage())),
      GoRoute(
          path: RouteNames.merchantFulfillment,
          builder: (context, state) => const _RequireAccess(
              roles: ['merchant_owner', 'admin_super', 'admin_operations'],
              approvedOrganizationTypes: ['MERCHANT'],
              child: MerchantFulfillmentHubPage())),
      GoRoute(
          path: RouteNames.merchantPayments,
          builder: (context, state) => const _RequireAccess(
              roles: ['merchant_owner', 'admin_super', 'admin_operations'],
              permissions: ['finance.payments.review'],
              approvedOrganizationTypes: ['MERCHANT'],
              child: merchant_market.MerchantPaymentsPage())),
      GoRoute(
          path: RouteNames.merchantShipments,
          builder: (context, state) => const _RequireAccess(
              roles: ['merchant_owner', 'admin_super', 'admin_operations'],
              approvedOrganizationTypes: ['MERCHANT'],
              child: merchant_market.MerchantShipmentsPage())),
      GoRoute(
          path: RouteNames.merchantFinanceOverview,
          builder: (context, state) => const _RequireAccess(
              roles: ['merchant_owner', 'admin_super', 'admin_operations'],
              permissions: ['finance.payments.review'],
              approvedOrganizationTypes: ['MERCHANT'],
              child: merchant_market.MerchantFinanceOverviewPage())),
      GoRoute(
          path: RouteNames.merchantWallet,
          builder: (context, state) => const _RequireAccess(
              roles: ['merchant_owner', 'admin_super', 'admin_operations'],
              approvedOrganizationTypes: ['MERCHANT'],
              child: merchant_market.MerchantWalletPage())),
      GoRoute(
          path: RouteNames.merchantSettlements,
          builder: (context, state) => const _RequireAccess(
              roles: ['merchant_owner', 'admin_super', 'admin_operations'],
              permissions: ['finance.payments.review'],
              approvedOrganizationTypes: ['MERCHANT'],
              child: merchant_market.MerchantSettlementsPage())),
      GoRoute(
          path: RouteNames.merchantInvoices,
          builder: (context, state) => const _RequireAccess(
              roles: ['merchant_owner', 'admin_super', 'admin_operations'],
              permissions: ['finance.payments.review'],
              approvedOrganizationTypes: ['MERCHANT'],
              child: merchant_market.MerchantInvoicesPage())),
      GoRoute(
          path: RouteNames.merchantReports,
          builder: (context, state) => const _RequireAccess(
              roles: ['merchant_owner', 'admin_super', 'admin_operations'],
              approvedOrganizationTypes: ['MERCHANT'],
              child: merchant_market.MerchantReportsPage())),
      GoRoute(
          path: RouteNames.merchantPromotions,
          builder: (context, state) => const _RequireAccess(
              roles: ['merchant_owner', 'admin_super', 'admin_operations'],
              approvedOrganizationTypes: ['MERCHANT'],
              child: merchant_market.MerchantPromotionsPage())),
      GoRoute(
          path: RouteNames.merchantNotifications,
          builder: (context, state) => const _RequireAccess(
              roles: ['merchant_owner', 'admin_super', 'admin_operations'],
              approvedOrganizationTypes: ['MERCHANT'],
              child: merchant_market.MerchantNotificationsPage())),
      GoRoute(
          path: RouteNames.merchantNotificationSettings,
          builder: (context, state) => const _RequireAccess(
              roles: ['merchant_owner', 'admin_super', 'admin_operations'],
              approvedOrganizationTypes: ['MERCHANT'],
              child: merchant_market.MerchantNotificationSettingsPage())),
      GoRoute(
          path: RouteNames.merchantSettings,
          builder: (context, state) => const _RequireAccess(
              roles: ['merchant_owner', 'admin_super', 'admin_operations'],
              approvedOrganizationTypes: ['MERCHANT'],
              child: merchant_market.MerchantSettingsPage())),
      GoRoute(
          path: RouteNames.merchantStatus,
          builder: (context, state) => const _RequireAccess(
              roles: ['merchant_owner', 'admin_super', 'admin_operations'],
              approvedOrganizationTypes: ['MERCHANT'],
              child: merchant_market.MerchantStatusPage())),
      GoRoute(
          path: RouteNames.merchantStoreProfile,
          builder: (context, state) => const _RequireAccess(
              roles: ['merchant_owner', 'admin_super', 'admin_operations'],
              approvedOrganizationTypes: ['MERCHANT'],
              child: merchant_market.MerchantStoreProfilePage())),
      GoRoute(
          path: RouteNames.merchantPolicies,
          builder: (context, state) => const _RequireAccess(
              roles: ['merchant_owner', 'admin_super', 'admin_operations'],
              approvedOrganizationTypes: ['MERCHANT'],
              child: merchant_market.MerchantPoliciesPage())),
      GoRoute(
          path: RouteNames.merchantVerification,
          builder: (context, state) => const _RequireAccess(
              roles: ['merchant_owner', 'admin_super', 'admin_operations'],
              approvedOrganizationTypes: ['MERCHANT'],
              child: merchant_market.MerchantVerificationPage())),
      GoRoute(
          path: RouteNames.driverDeliveries,
          builder: (context, state) => const _RequireAccess(
              permissions: ['delivery.shipments.manage'],
              child: ShipmentsPage(driverMode: true))),
      GoRoute(
          path: RouteNames.adminDeliveryManagement,
          builder: (context, state) => const _RequireAccess(
              permissions: ['delivery.shipments.manage'],
              child: ShipmentsPage(adminMode: true))),
      GoRoute(
          path: RouteNames.merchantRetention,
          builder: (context, state) => const _RequireAccess(
              permissions: ['manage_retention'],
              child: RetentionCampaignsPage())),
      GoRoute(
          path: RouteNames.workshopOperationsHub,
          builder: (context, state) => const _RequireAccess(
              roles: ['workshop_owner', 'admin_super', 'admin_operations'],
              approvedOrganizationTypes: ['WORKSHOP'],
              child: WorkshopOperationsHubPage())),
      GoRoute(
          path: RouteNames.workshopOperationsServices,
          builder: (context, state) => const _RequireAccess(
              permissions: ['manage_workshop_services'],
              approvedOrganizationTypes: ['WORKSHOP'],
              child: WorkshopServicesManagementPage())),
      GoRoute(
          path: RouteNames.workshopOperationsBookings,
          builder: (context, state) => const _RequireAccess(
              permissions: ['manage_workshop_bookings'],
              approvedOrganizationTypes: ['WORKSHOP'],
              child: WorkshopBookingsManagementPage())),
      GoRoute(
          path: RouteNames.workshopOperationsServiceOrders,
          builder: (context, state) => const _RequireAccess(
              permissions: ['manage_service_orders'],
              approvedOrganizationTypes: ['WORKSHOP'],
              child: WorkshopServiceOrdersPage())),
      GoRoute(
          path: RouteNames.warehouseHub,
          builder: (context, state) => const _RequireAccess(
              roles: ['warehouse_owner', 'admin_super', 'admin_operations'],
              approvedOrganizationTypes: ['WAREHOUSE'],
              child: WarehouseHubPage())),
      GoRoute(
          path: RouteNames.supportCenter,
          redirect: (context, state) => RouteNames.supportOperations),
      GoRoute(
          path: RouteNames.supportOperations,
          builder: (context, state) => const _RequireAccess(
              permissions: AuthState.supportConsolePermissions,
              child: SupportOperationsHubPage())),
      GoRoute(
          path: RouteNames.helpCenter,
          builder: (context, state) => const HelpCenterPage()),
      GoRoute(
          path: RouteNames.supportTickets,
          builder: (context, state) => const _RequireAccess(permissions: [
                'support.tickets.manage',
                'manage_support',
                'manage_system',
              ], child: SupportTicketsPage(manageMode: true))),
      GoRoute(
          path: '/support/tickets/:id',
          builder: (context, state) => _RequireAccess(
                  permissions: const [
                    'support.tickets.manage',
                    'manage_support',
                    'manage_system',
                  ],
                  child: TicketDetailsPage(
                      ticketId: state.pathParameters['id']!))),
      GoRoute(
          path: RouteNames.supportComplaints,
          builder: (context, state) => const _RequireAccess(permissions: [
                'manage_complaints',
                'manage_support',
                'manage_system',
              ], child: ComplaintsPage(manageMode: true))),
      GoRoute(
          path: RouteNames.supportReviews,
          builder: (context, state) => const _RequireAccess(permissions: [
                'manage_reviews',
                'manage_support',
                'manage_system',
              ], child: ReviewsPage(manageMode: true))),
      GoRoute(
          path: RouteNames.financeReview,
          builder: (context, state) => const _RequireAccess(
              permissions: ['finance.payments.review', 'manage_system'],
              child: FinanceReviewPage())),
      GoRoute(
          path: RouteNames.financeRefunds,
          builder: (context, state) => const _RequireAccess(
              permissions: ['finance.payments.review', 'manage_system'],
              child: FinanceRefundsPage())),
      GoRoute(
          path: RouteNames.financeSettlements,
          builder: (context, state) => const _RequireAccess(
              permissions: ['finance.payments.review', 'manage_system'],
              child: FinanceSettlementsPage())),
      GoRoute(
          path: RouteNames.financeAccounting,
          builder: (context, state) => const _RequireAccess(
              permissions: ['finance.accounting.manage', 'manage_system'],
              child: FinanceAccountingPage())),
      GoRoute(
          path: RouteNames.adminControlCenter,
          builder: (context, state) => const _RequireAccess(
              permissions: ['view_admin_panel', 'manage_system'],
              child: AdminControlCenterPage())),
      GoRoute(
          path: RouteNames.adminOperations,
          builder: (context, state) => const _RequireAccess(
              permissions: ['view_admin_panel', 'manage_system'],
              child: AdminControlCenterPage())),
      GoRoute(
          path: RouteNames.adminDashboard,
          builder: (context, state) => const _RequireAccess(
              permissions: ['view_admin_panel', 'manage_system'],
              child: AdminDashboardPage())),
      GoRoute(
          path: RouteNames.adminAnalytics,
          builder: (context, state) => const _RequireAccess(
              permissions: ['view_reports', 'manage_system'],
              child: AdminAnalyticsPage())),
      GoRoute(
          path: RouteNames.adminUsers,
          builder: (context, state) => const _RequireAccess(
              permissions: ['manage_users', 'manage_system'],
              child: AdminUsersPage())),
      GoRoute(
          path: RouteNames.adminVerifications,
          builder: (context, state) => const _RequireAccess(
              permissions: ['review_verifications', 'manage_system'],
              child: AdminVerificationsPage())),
      GoRoute(
          path: RouteNames.adminLocations,
          builder: (context, state) => const _RequireAccess(
              permissions: ['manage_location', 'manage_system'],
              child: AdminLocationsPage())),
      GoRoute(
          path: RouteNames.adminOrders,
          builder: (context, state) => const _RequireAccess(
              permissions: ['admin.orders.view', 'manage_system'],
              child: AdminOrdersPage())),
      GoRoute(
          path: '/admin/orders/:id',
          builder: (context, state) => _RequireAccess(
              permissions: const ['admin.orders.view', 'manage_system'],
              child:
                  AdminOrderDetailsPage(orderId: state.pathParameters['id']!))),
      GoRoute(
          path: RouteNames.adminAuditLogs,
          builder: (context, state) => const _RequireAccess(
              permissions: ['view_audit_logs', 'manage_system'],
              child: AdminAuditLogsPage())),
      GoRoute(
          path: RouteNames.adminSettings,
          builder: (context, state) => const _RequireAccess(
              permissions: ['manage_settings', 'manage_system'],
              child: AdminSettingsPage())),
      GoRoute(
          path: RouteNames.adminTranslations,
          builder: (context, state) => const _RequireAccess(
              permissions: ['manage_settings', 'manage_system'],
              child: AdminTranslationsPage())),
      GoRoute(
          path: RouteNames.adminSystemHardening,
          builder: (context, state) => const _RequireAccess(
              permissions: ['manage_settings', 'manage_system'],
              child: AdminSystemHardeningPage())),
      GoRoute(
          path: RouteNames.adminQualityRelease,
          builder: (context, state) => const _RequireAccess(
              permissions: ['release.manage', 'manage_system'],
              child: AdminQualityReleasePage())),
    ],
  );
});

String _providerOrUnauthorized(AuthState authState, String type) {
  if (authState.hasPendingProviderOrganization) {
    return RouteNames.providerStatus;
  }
  if (!authState.hasApprovedOrganization(type)) {
    return RouteNames.providerStatus;
  }
  return RouteNames.unauthorized;
}

class _RequireAccess extends ConsumerWidget {
  final List<String> roles;
  final List<String> permissions;
  final List<String> approvedOrganizationTypes;
  final Widget child;
  const _RequireAccess({
    this.roles = const [],
    this.permissions = const [],
    this.approvedOrganizationTypes = const [],
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PermissionGuard(
      roles: roles,
      permissions: permissions,
      approvedOrganizationTypes: approvedOrganizationTypes,
      child: child,
    );
  }
}

class _RouterRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}
