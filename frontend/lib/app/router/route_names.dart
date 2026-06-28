class RouteNames {
  static const splash = '/splash';
  static const entry = '/entry';
  static const login = '/login';
  static const register = '/register';
  static const otp = '/otp';
  static const emailLink = '/email-link';
  static const emailLinkCallback = '/auth/email-link-callback';
  static const unauthorized = '/unauthorized';
  static const settings = '/settings';

  static const profileBasics = '/profile-basics';
  static const locationSelection = '/location-selection';
  static const myAddresses = '/locations/addresses';
  static const vehicles = '/vehicles';
  static const addVehicle = '/vehicles/add';
  static const setupComplete = '/setup-complete';

  static const providerType = '/provider-onboarding/type';
  static const providerOrganization = '/provider-onboarding/organization';
  static const providerBranch = '/provider-onboarding/branch';
  static const providerProfile = '/provider-onboarding/profile';
  static const providerBankAccount = '/provider-onboarding/bank-account';
  static const providerBusinessHours = '/provider-onboarding/business-hours';
  static const providerDocuments = '/provider-onboarding/documents';
  static const providerStatus = '/provider-onboarding/status';

  static const marketplaceHome = '/marketplace';
  static const marketplaceSearch = '/marketplace/search';
  static const listingDetail = '/marketplace/listing';
  static const cart = '/marketplace/cart';
  static const checkoutPreview = '/marketplace/checkout-preview';
  static const myOrders = '/orders/my';
  static String orderDetails(String id) => '/orders/$id';
  static String orderPayment(String id) => '/orders/$id/payment';
  static String paymentStatus(String id) => '/payments/$id/status';

  static const customerCenter = '/customer/center';
  static const customerVehicle = '/customer/vehicles';
  static const customerParts = '/customer/parts';
  static const customerTracking = '/customer/tracking';
  static const customerMaintenance = '/customer/maintenance';
  static const customerShipments = '/customer/shipments';
  static const customerNotifications = '/customer/notifications';
  static const customerWallet = '/customer/wallet';
  static const customerLoyalty = '/customer/loyalty';
  static const customerReferrals = '/customer/referrals';
  static const adminCoupons = '/admin/coupons';
  static const customerSupportTickets = '/customer/support-tickets';
  static String customerSupportTicketDetails(String id) =>
      '/customer/support-tickets/$id';
  static const customerComplaints = '/customer/complaints';
  static const customerReviews = '/customer/reviews';

  static const merchantHub = '/merchant/hub';
  static const merchantListings = '/merchant/listings';
  static const createListing = '/merchant/listings/create';
  static const productImports = '/product-imports';
  static const branchEmployeeManagement = '/organization/branches-employees';
  static const merchantOrders = '/merchant/orders';
  static String merchantOrderDetails(String id) => '/merchant/orders/$id';
  static const merchantFulfillment = '/merchant/fulfillment';
  static const merchantPayments = '/merchant/payments';
  static const financeReview = '/finance/review';
  static const financeRefunds = '/finance/refunds';
  static const financeSettlements = '/finance/settlements';
  static const financeAccounting = '/finance/accounting';
  static const merchantShipments = '/merchant/shipments';
  static const driverDeliveries = '/driver/deliveries';
  static const adminDeliveryManagement = '/admin/delivery';
  static const merchantRetention = '/merchant/retention';

  static const workshopOperationsHub = '/workshop/operations';
  static const workshopOperationsServices = '/workshop/operations/services';
  static const workshopOperationsBookings = '/workshop/operations/bookings';
  static const workshopOperationsServiceOrders =
      '/workshop/operations/service-orders';

  static const warehouseHub = '/warehouse/hub';

  static const supportOperations = '/support/operations';
  static const supportCenter = '/support/center';
  static const supportTickets = '/support/tickets';
  static String supportTicketDetails(String id) => '/support/tickets/$id';
  static const supportComplaints = '/support/complaints';
  static const supportReviews = '/support/reviews';
  static const helpCenter = '/help-center';
  static const supportKnowledgeManagement = '/support/knowledge';

  static const adminControlCenter = '/admin/control-center';
  static const adminOperations = '/admin/operations';
  static const adminDashboard = '/admin/dashboard';
  static const adminAnalytics = '/admin/analytics';
  static const adminUsers = '/admin/users';
  static const adminVerifications = '/admin/verifications';
  static const adminLocations = '/admin/locations';
  static const adminOrders = '/admin/orders';
  static String adminOrderDetails(String id) => '/admin/orders/$id';
  static const adminAuditLogs = '/admin/audit-logs';
  static const adminSettings = '/admin/settings';
  static const adminTranslations = '/admin/translations';
  static const adminSystemHardening = '/admin/system-hardening';
  static const adminQualityRelease = '/admin/quality-release';

  // Merged route names from older feature packs (customer/merchant marketplace).
  static String editVehicle(String id) => '/vehicles/$id/edit';
  static const marketplaceProviderProfile = '/marketplace/provider';
  static const providerReviews = '/marketplace/provider/reviews';
  static const compareOffers = '/marketplace/compare';
  static const marketplaceFavorites = '/marketplace/favorites';
  static const customerCoupons = '/marketplace/coupons';
  static const paymentResult = '/marketplace/payment-result';
  static const orderDetail = '/marketplace/my-orders/detail';
  static const orderReturn = '/marketplace/my-orders/return';
  static const orderCancel = '/marketplace/my-orders/cancel';
  static const orderDispute = '/marketplace/my-orders/dispute';
  static const customerDisputes = '/marketplace/my-orders/disputes';
  static const customerDisputeDetail = '/marketplace/my-orders/disputes/detail';
  static const customerProfile = '/customer/profile';
  static const customerSettings = '/customer/settings';
  static const customerAddresses = '/customer/addresses';
  static const customerChat = '/customer/chat';
  static const notifications = '/customer/notifications';
  static const customerRewards = '/customer/rewards';
  static const customerOrderReview = '/marketplace/my-orders/review';
  static const customerSupport = '/customer/support';
  static String editMerchantListing(String id) => '/merchant/listings/$id/edit';
  static String merchantListingDetails(String id) =>
      '/merchant/listings/$id/details';
  static const merchantInventory = '/merchant/inventory';
  static const merchantBranches = '/merchant/branches';
  static const createMerchantBranch = '/merchant/branches/create';
  static String merchantBranchDetails(String id) =>
      '/merchant/branches/$id/details';
  static String editMerchantBranch(String id) => '/merchant/branches/$id/edit';
  static const merchantTeam = '/merchant/team';
  static const merchantReports = '/merchant/reports';
  static const merchantNotifications = '/merchant/notifications';
  static const merchantSettings = '/merchant/settings';
  static const merchantStatus = '/merchant/status';
  static const merchantStoreProfile = '/merchant/store-profile';
  static const merchantPolicies = '/merchant/policies';
  static const merchantVerification = '/merchant/verification';
  static const merchantRolesPermissions = '/merchant/roles-permissions';
  static const merchantEmployees = '/merchant/employees';
  static const merchantAuditLog = '/merchant/audit-log';
  static const merchantCategoriesManager = '/merchant/categories-manager';
  static const merchantCompatibilityManager = '/merchant/compatibility-manager';
  static const merchantDataQuality = '/merchant/data-quality';
  static const merchantBulkImport = '/merchant/bulk-import';
  static const merchantPromotions = '/merchant/promotions';
  static const merchantNotificationSettings = '/merchant/notification-settings';
  static const merchantReturns = '/merchant/returns';
  static const merchantDisputes = '/merchant/disputes';
  static const merchantReviews = '/merchant/reviews';
  static const merchantCustomerChats = '/merchant/customer-chats';
  static const merchantFinanceOverview = '/merchant/finance';
  static const merchantWallet = '/merchant/wallet';
  static const merchantSettlements = '/merchant/settlements';
  static const merchantInvoices = '/merchant/invoices';
  static const customerRegister = '/register/customer';
  static const merchantRegister = '/register/merchant';
  static const workshopRegister = '/register/workshop';
  static const workshopDashboard = '/workshop';
  static const workshopStatus = '/workshop/status';
  static const marketplaceCategories = '/marketplace/categories';
  static const merchantProductEdit = '/merchant/products/:id/edit';
  static const merchantOrderDetail = '/merchant/orders/:id';
  static String merchantProductEditPath(String id) =>
      '/merchant/products/$id/edit';
}
