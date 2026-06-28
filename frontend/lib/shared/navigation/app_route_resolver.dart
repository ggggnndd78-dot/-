import 'package:ghiyarak/app/router/route_names.dart';
import 'package:ghiyarak/features/auth/logic/auth_state.dart';

class AppRouteResolver {
  const AppRouteResolver._();

  static const Set<String> authEntryRoutes = <String>{
    RouteNames.entry,
    RouteNames.login,
    RouteNames.register,
    RouteNames.otp,
    RouteNames.emailLink,
    RouteNames.emailLinkCallback,
  };

  static const Set<String> publicRoutes = <String>{
    RouteNames.splash,
    RouteNames.entry,
    RouteNames.login,
    RouteNames.register,
    RouteNames.otp,
    RouteNames.emailLink,
    RouteNames.emailLinkCallback,
    RouteNames.unauthorized,
    RouteNames.marketplaceHome,
    RouteNames.marketplaceSearch,
    RouteNames.marketplaceCategories,
    RouteNames.helpCenter,
  };

  static const Set<String> customerProtectedExactRoutes = <String>{
    RouteNames.profileBasics,
    RouteNames.locationSelection,
    RouteNames.myAddresses,
    RouteNames.vehicles,
    RouteNames.addVehicle,
    RouteNames.setupComplete,
    RouteNames.cart,
    RouteNames.checkoutPreview,
    RouteNames.customerCoupons,
    RouteNames.marketplaceFavorites,
    RouteNames.compareOffers,
    RouteNames.myOrders,
    RouteNames.customerDisputes,
  };

  static bool isAuthEntryPath(String path) => authEntryRoutes.contains(path);

  static bool isPublicPath(String path) {
    if (publicRoutes.contains(path)) {
      return true;
    }
    if (path.startsWith('${RouteNames.listingDetail}/')) {
      return true;
    }
    if (path.startsWith('${RouteNames.marketplaceProviderProfile}/')) {
      return true;
    }
    if (path.startsWith('${RouteNames.providerReviews}/')) {
      return true;
    }
    return false;
  }

  static bool isGuestAccessiblePath(String route) {
    final uri = Uri.tryParse(route);
    final path = uri?.path ?? route;
    return path == '/' || isAuthEntryPath(path) || isPublicPath(path);
  }

  static bool isCustomerProtectedPath(String path) {
    if (path.startsWith('/customer')) return true;
    if (path.startsWith('/orders/')) return true;
    if (customerProtectedExactRoutes.contains(path)) return true;
    return path.startsWith('${RouteNames.paymentResult}/') ||
        path.startsWith('${RouteNames.orderDetail}/') ||
        path.startsWith('${RouteNames.orderReturn}/') ||
        path.startsWith('${RouteNames.orderCancel}/') ||
        path.startsWith('${RouteNames.orderDispute}/') ||
        path.startsWith('${RouteNames.customerOrderReview}/') ||
        path.startsWith('${RouteNames.customerDisputeDetail}/');
  }

  static bool isProtectedPath(String path) {
    return isCustomerProtectedPath(path) ||
        path.startsWith('/admin') ||
        path.startsWith('/merchant') ||
        path.startsWith('/workshop') ||
        path.startsWith('/warehouse') ||
        path.startsWith('/support') ||
        path.startsWith('/product-imports') ||
        path.startsWith('/provider-onboarding') ||
        path.startsWith('/finance');
  }

  static String loginRouteForNext(String target) {
    return '${RouteNames.login}?next=${Uri.encodeComponent(target)}';
  }

  static String landingRouteFor(AuthState authState) {
    if (authState.isSuperAdmin) return RouteNames.adminControlCenter;
    if (authState.isAdminOperations) return RouteNames.adminControlCenter;
    if (authState.isSupportAgent) return RouteNames.supportOperations;
    if (authState.canAccessAdminConsole) return RouteNames.adminControlCenter;
    if (authState.canOpenSupportConsole) return RouteNames.supportOperations;
    if (authState.hasPendingProviderOrganization) {
      return RouteNames.providerStatus;
    }
    if (authState.hasApprovedWorkshopOrganization) {
      return RouteNames.workshopOperationsHub;
    }
    if (authState.hasApprovedWarehouseOrganization) {
      return RouteNames.warehouseHub;
    }
    if (authState.hasApprovedMerchantOrganization)
      return RouteNames.merchantHub;
    if (authState.isAuthenticated) return RouteNames.customerCenter;
    return RouteNames.marketplaceHome;
  }

  static String mapBackendDashboardRoute(String? route) {
    switch (route) {
      case '/admin/control-center':
      case '/admin':
      case '/system-control-center':
        return RouteNames.adminControlCenter;
      case '/admin/operations':
        return RouteNames.adminOperations;
      case '/merchant/dashboard':
      case '/merchant/hub':
        return RouteNames.merchantHub;
      case '/workshop/dashboard':
      case '/workshop/operations':
        return RouteNames.workshopOperationsHub;
      case '/warehouse/dashboard':
      case '/warehouse/hub':
        return RouteNames.warehouseHub;
      case '/support/operations':
      case '/support/center':
      case '/support':
        return RouteNames.supportOperations;
      case '/finance/dashboard':
        return RouteNames.financeReview;
      case '/driver/shipments':
        return RouteNames.driverDeliveries;
      case '/application-status':
      case '/provider-onboarding/status':
        return RouteNames.providerStatus;
      case '/customer/dashboard':
      case '/customer/center':
        return RouteNames.customerCenter;
      case '/marketplace':
        return RouteNames.marketplaceHome;
      default:
        return RouteNames.marketplaceHome;
    }
  }

  static String resolvePostAuthRoute(
    AuthState authState, {
    String? nextRoute,
  }) {
    final requested = nextRoute?.trim();
    if (requested != null && requested.isNotEmpty) {
      final requestedPath = Uri.tryParse(requested)?.path ?? requested;
      if (!isAuthEntryPath(requestedPath) &&
          _isRouteAllowedForAuth(authState, requestedPath)) {
        return requested;
      }
    }

    final rawDashboardRoute = authState.user?.dashboardRoute.trim() ?? '';
    if (rawDashboardRoute.isNotEmpty) {
      final dashboardRoute = mapBackendDashboardRoute(rawDashboardRoute);
      final dashboardPath = Uri.tryParse(dashboardRoute)?.path ?? dashboardRoute;
      if (_isRouteAllowedForAuth(authState, dashboardPath)) {
        return dashboardRoute;
      }
    }

    return landingRouteFor(authState);
  }

  static bool _isRouteAllowedForAuth(AuthState authState, String path) {
    if (!authState.isAuthenticated) return isGuestAccessiblePath(path);

    if (authState.canAccessAdminConsole) {
      return path.startsWith('/admin') ||
          path.startsWith('/finance') ||
          path.startsWith('/support');
    }

    if (authState.canOpenSupportConsole) {
      return path.startsWith('/support');
    }

    if (authState.canOpenMerchantConsole) {
      return path.startsWith('/merchant') ||
          path.startsWith('/product-imports') ||
          path.startsWith('/finance');
    }

    if (authState.canOpenWorkshopConsole) {
      return path.startsWith('/workshop');
    }

    if (authState.canOpenWarehouseConsole) {
      return path.startsWith('/warehouse');
    }

    if (authState.hasPendingProviderOrganization) {
      return path.startsWith('/provider-onboarding');
    }

    if (authState.isCustomer) {
      return isCustomerProtectedPath(path) || isPublicPath(path);
    }

    return false;
  }
}
