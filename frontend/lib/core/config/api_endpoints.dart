class ApiEndpoints {
  static const health = '/health';

  static const authLoginStart = '/auth/login/start';
  static const authVerifyDeviceOtp = '/auth/login/verify-device-otp';
  static const registerCustomer = '/auth/register/customer';
  static const registerBusiness = '/auth/register/business';
  static const validateSession = '/auth/session/validate';
  static const trustedDevices = '/auth/devices';
  static String trustedDevice(String id) => '/auth/devices/$id';
  static const logoutAllDevices = '/auth/logout-all-devices';
  static const requestOtp = '/auth/request-otp';
  static const verifyOtp = '/auth/verify-otp';
  static const logout = '/auth/logout';
  static const refreshToken = '/auth/refresh';
  static const guestSessions = '/auth/guest-sessions';
  static const guestSessionLocation = '/auth/guest-sessions/location';

  static const me = '/me';
  static const meProfile = '/me/profile';
  static const meLocation = '/me/location';
  static const meLocale = '/me/locale';
  static const localization = '/system/localization';
  static const translationCatalog = '/system/translations/catalog';

  static const countries = '/locations/countries';
  static const states = '/locations/states';
  static const cities = '/locations/cities';
  static const districts = '/locations/districts';
  static const areas = '/locations/areas';
  static const deliveryFees = '/locations/delivery-fees';
  static const deliveryZones = '/locations/delivery-zones';
  static const myAddresses = '/locations/addresses/my';
  static const addresses = '/locations/addresses';
  static String addressDetail(String id) => '/locations/addresses/$id';
  static const adminLocationCities = '/locations/admin/cities';
  static String adminLocationCity(String id) => '/locations/admin/cities/$id';
  static String adminLocationCityDistricts(String id) =>
      '/locations/admin/cities/$id/districts';
  static String adminLocationDistrict(String id) =>
      '/locations/admin/districts/$id';
  static String adminLocationCityDeliveryFee(String id) =>
      '/locations/admin/cities/$id/delivery-fee';
  static const adminDeliveryZones = '/locations/admin/delivery-zones';
  static String adminDeliveryZone(String id) =>
      '/locations/admin/delivery-zones/$id';

  static const vehicleMakes = '/vehicles/makes';
  static const vehicleModels = '/vehicles/models';
  static const vehicleVariants = '/vehicles/variants';
  static const vehicleYears = '/vehicles/years';
  static const vehicleTrims = '/vehicles/trims';
  static const vehicleEngines = '/vehicles/engines';
  static const myVehicles = '/me/vehicles';

  static const organizations = '/organizations';
  static const organizationsMine = '/organizations/me';
  static String organizationDetail(String id) => '/organizations/$id';
  static String organizationBranches(String id) =>
      '/organizations/$id/branches';
  static String organizationBusinessHours(String id) =>
      '/organizations/$id/business-hours';
  static String organizationMerchantProfile(String id) =>
      '/organizations/$id/merchant-profile';
  static String organizationWorkshopProfile(String id) =>
      '/organizations/$id/workshop-profile';
  static String organizationBankAccounts(String id) =>
      '/organizations/$id/bank-accounts';
  static String organizationVerificationRequests(String id) =>
      '/organizations/$id/verification-requests';
  static String verificationRequest(String id) => '/verification-requests/$id';
  static String verificationRequestDocuments(String id) =>
      '/verification-requests/$id/documents';

  static const catalogCategories = '/catalog/categories';
  static const catalogBrands = '/catalog/part-brands';
  static const catalogProducts = '/catalog/products';
  static String catalogProductDetail(String id) => '/catalog/products/$id';

  static const searchListings = '/listings';
  static String listingDetail(String id) => '/listings/$id';
  static String listingCompare(String productId) =>
      '/listings/compare/$productId';
  static String listingSimilar(String id) => '/listings/$id/similar';

  static const cart = '/cart';
  static const cartItems = '/cart/items';
  static String cartItem(String id) => '/cart/items/$id';
  static const checkoutPreview = '/checkout/preview';

  static const orders = '/orders';
  static const myOrders = '/orders/my';
  static String myOrderDetail(String id) => '/orders/$id';
  static String cancelOrder(String id) => '/orders/$id/cancel';

  static const merchantOrders = '/merchant/orders';
  static String merchantOrderDetail(String id) => '/merchant/orders/$id';
  static String merchantOrderStatus(String id) => '/merchant/orders/$id/status';

  static const merchantListings = '/merchant/listings';
  static String merchantListingDetail(String id) => '/merchant/listings/$id';
  static String merchantListingStatus(String id) =>
      '/merchant/listings/$id/status';

  static const productImportTemplate = '/product-imports/template';
  static const productImportJobs = '/product-imports/jobs';
  static const productImportUpload = '/product-imports/jobs/upload';
  static String productImportJob(String id) => '/product-imports/jobs/$id';
  static String productImportRows(String id) =>
      '/product-imports/jobs/$id/rows';
  static String productImportErrors(String id) =>
      '/product-imports/jobs/$id/errors';
  static String productImportConfirm(String id) =>
      '/product-imports/jobs/$id/confirm';

  static const workshopServiceCategories = '/workshops/service-categories';
  static const workshopCatalogServices = '/workshops/catalog-services';
  static const workshopServices = '/workshops/services';
  static String workshopServiceDetail(String id) => '/workshops/services/$id';
  static const workshopBookingSlots = '/workshops/booking-slots';
  static const workshopBookings = '/workshops/bookings';
  static const myWorkshopBookings = '/workshops/bookings/my';
  static String workshopBookingDetail(String id) => '/workshops/bookings/$id';
  static String cancelWorkshopBooking(String id) =>
      '/workshops/bookings/$id/cancel';
  static String rateWorkshopBooking(String id) =>
      '/workshops/bookings/$id/rating';
  static const myMaintenanceRecords = '/workshops/maintenance-records/my';

  static const workshopOperationsServices = '/workshop/operations/services';
  static String workshopOperationsService(String id) =>
      '/workshop/operations/services/$id';
  static String workshopOperationsServiceStatus(String id) =>
      '/workshop/operations/services/$id/status';
  static const workshopOperationsTechnicians =
      '/workshop/operations/technicians';
  static const workshopOperationsBookingSlots =
      '/workshop/operations/booking-slots';
  static const workshopOperationsBookings = '/workshop/operations/bookings';
  static String workshopOperationsBookingStatus(String id) =>
      '/workshop/operations/bookings/$id/status';
  static String workshopOperationsBookingServiceOrder(String id) =>
      '/workshop/operations/bookings/$id/service-order';
  static const workshopOperationsServiceOrders =
      '/workshop/operations/service-orders';
  static String workshopOperationsServiceOrderStatus(String id) =>
      '/workshop/operations/service-orders/$id/status';
  static String workshopOperationsDiagnostics(String id) =>
      '/workshop/operations/service-orders/$id/diagnostics';
  static String workshopOperationsMaintenanceRecord(String id) =>
      '/workshop/operations/service-orders/$id/maintenance-record';

  static const paymentMethods = '/payments/methods';
  static String orderPaymentIntent(String id) => '/payments/orders/$id/intents';
  static String orderPaymentTransactions(String id) =>
      '/payments/orders/$id/transactions';
  static const myPayments = '/payments/my';
  static String paymentProofs(String id) => '/payments/$id/proofs';
  static String paymentTransactionPaid(String id) =>
      '/payments/transactions/$id/paid';
  static String paymentTransactionFailed(String id) =>
      '/payments/transactions/$id/failed';
  static const financePayments = '/finance/payments';
  static const financePaymentProofs = '/finance/payment-proofs';
  static String financeApprovePaymentProof(String id) =>
      '/finance/payment-proofs/$id/approve';
  static String financeRejectPaymentProof(String id) =>
      '/finance/payment-proofs/$id/reject';
  static const refunds = '/refunds';
  static const financeRefunds = '/finance/refunds';
  static String financeApproveRefund(String id) =>
      '/finance/refunds/$id/approve';
  static String financeRejectRefund(String id) => '/finance/refunds/$id/reject';
  static String financeMarkRefunded(String id) =>
      '/finance/refunds/$id/mark-refunded';
  static const financeSettlements = '/finance/settlements';
  static String financeApproveSettlement(String id) =>
      '/finance/settlements/$id/approve';
  static String financeMarkSettlementPaid(String id) =>
      '/finance/settlements/$id/mark-paid';
  static const accountingAccounts = '/finance/accounting/accounts';
  static const accountingJournalEntries = '/finance/accounting/journal-entries';
  static const accountingFinancialTransactions =
      '/finance/accounting/financial-transactions';
  static const accountingMerchantBalances =
      '/finance/accounting/merchant-balances';
  static String accountingAccountLedger(String id) =>
      '/finance/accounting/accounts/$id/ledger';

  static const deliveryMethods = '/delivery/methods';
  static const myShipments = '/delivery/shipments/my';
  static const merchantShipments = '/delivery/merchant/shipments';
  static const driverShipments = '/delivery/driver/shipments';
  static const adminShipments = '/delivery/admin/shipments';
  static const deliveryDrivers = '/delivery/drivers';
  static const deliveryShippingCompanies = '/delivery/shipping-companies';
  static const deliveryFeeRules = '/delivery/fees';
  static String orderShipment(String id) => '/delivery/orders/$id/shipments';
  static String shipmentDetail(String id) => '/delivery/shipments/$id';
  static String shipmentStatus(String id) => '/delivery/shipments/$id/status';
  static String shipmentAssign(String id) => '/delivery/shipments/$id/assign';
  static String shipmentDriverAccept(String id) =>
      '/delivery/shipments/$id/driver-accept';

  static const walletMe = '/wallet/me';
  static const walletLedger = '/wallet/me/ledger';
  static const walletTopups = '/wallet/me/topups';
  static const loyaltyMe = '/loyalty/me';
  static const loyaltyTransactions = '/loyalty/me/transactions';
  static const loyaltyRedeemToWallet = '/loyalty/redeem-to-wallet';
  static const loyaltyCoupons = '/loyalty/coupons';
  static const loyaltyCouponsManage = '/loyalty/coupons/manage';
  static const loyaltyCouponValidate = '/loyalty/coupons/validate';
  static String loyaltyCouponStatus(String id) => '/loyalty/coupons/$id/status';
  static const referralsMe = '/referrals/me';
  static const referralCode = '/referrals/me/code';
  static const referralApply = '/referrals/apply';
  static String referralQualify(String id) => '/referrals/$id/qualify';

  static const myNotifications = '/notifications/my';
  static const notificationsUnreadCount = '/notifications/unread-count';
  static const notificationDevices = '/notifications/devices';
  static String notificationDevice(String id) => '/notifications/devices/$id';
  static String notificationRead(String id) => '/notifications/$id/read';
  static const notificationsReadAll = '/notifications/read-all';
  static const notificationTest = '/notifications/test';

  static const supportTickets = '/support/tickets';
  static const mySupportTickets = '/support/tickets/my';
  static const manageSupportTickets = '/support/tickets/manage';
  static String supportTicketDetail(String id) => '/support/tickets/$id';
  static String supportTicketMessages(String id) =>
      '/support/tickets/$id/messages';
  static String supportTicketStatus(String id) => '/support/tickets/$id/status';
  static String supportTicketAssign(String id) => '/support/tickets/$id/assign';
  static String supportTicketReopen(String id) => '/support/tickets/$id/reopen';

  static const helpCategories = '/support/help/categories';
  static const manageHelpCategories = '/support/help/categories/manage';
  static const helpArticles = '/support/help/articles';
  static const manageHelpArticles = '/support/help/articles/manage';
  static String helpArticle(String slug) => '/support/help/articles/$slug';
  static const faqs = '/support/faqs';
  static const manageFaqs = '/support/faqs/manage';
  static const whatsappSupportLinks = '/support/whatsapp-links';
  static const manageWhatsappSupportLinks = '/support/whatsapp-links/manage';

  static const complaints = '/support/complaints';
  static const myComplaints = '/support/complaints/my';
  static const manageComplaints = '/support/complaints/manage';
  static String complaintStatus(String id) => '/support/complaints/$id/status';

  static const productReviews = '/reviews/products';
  static const merchantReviews = '/reviews/merchants';
  static const workshopReviews = '/reviews/workshops';
  static const serviceReviews = '/reviews/services';
  static const myReviews = '/reviews/my';
  static const adminReviews = '/reviews/admin';
  static const reviewReply = '/reviews/reply';
  static const reviewReport = '/reviews/report';
  static const reviewModeration = '/reviews/moderation';
  static String productReviewsFor(String productId) =>
      '/reviews/products/$productId';
  static String merchantReviewsFor(String organizationId) =>
      '/reviews/merchants/$organizationId';
  static String workshopReviewsFor(String organizationId) =>
      '/reviews/workshops/$organizationId';
  static String serviceReviewsFor(String workshopServiceId) =>
      '/reviews/services/$workshopServiceId';
  static String reputation(String targetType, String targetId) =>
      '/reviews/reputation/$targetType/$targetId';
  static String moderateReview(String type, String id) =>
      '/support/reviews/$type/$id/status';

  static const adminSystemHardeningOverview =
      '/admin/system-hardening/overview';
  static const adminSystemHardeningNaming = '/admin/system-hardening/naming';
  static const adminSystemHardeningModules = '/admin/system-hardening/modules';
  static String adminResolveSystemFinding(String id) =>
      '/admin/system-hardening/findings/$id/resolve';
  static const adminI18nCatalog = '/admin/i18n/catalog';
  static String adminI18nCatalogEntry(String key) => '/admin/i18n/catalog/$key';
  static const adminAnalyticsSnapshots = '/admin/analytics/snapshots';
  static const adminRefreshAnalyticsSnapshots =
      '/admin/analytics/snapshots/refresh';
  static const adminAuditIntegrityCheckpoint =
      '/admin/audit-logs/integrity-checkpoint';

  static const adminControlCenterData = '/admin/control-center';
  static const adminEnterpriseAnalytics = '/admin/analytics/enterprise';
  static const adminLocalization = '/admin/localization';
  static const adminFeatureFlags = '/admin/feature-flags';
  static String adminFeatureFlag(String key) => '/admin/feature-flags/$key';
  static const adminDashboardSummary = '/admin/dashboard/summary';
  static const adminAnalyticsOrders = '/admin/analytics/orders';
  static const adminAnalyticsRevenue = '/admin/analytics/revenue';
  static const adminAnalyticsSupport = '/admin/analytics/support';
  static const adminAnalyticsMerchants = '/admin/analytics/merchants';
  static const adminUsers = '/admin/users';
  static String adminUser(String id) => '/admin/users/$id';
  static String adminUserStatus(String id) => '/admin/users/$id/status';
  static const adminRoles = '/admin/roles';
  static const adminPermissions = '/admin/permissions';
  static const adminVerifications = '/admin/verifications';
  static String adminVerificationDetail(String id) =>
      '/admin/verifications/$id';
  static String adminVerificationApprove(String id) =>
      '/admin/verifications/$id/approve';
  static String adminVerificationReject(String id) =>
      '/admin/verifications/$id/reject';
  static String adminVerificationRequireDocuments(String id) =>
      '/admin/verifications/$id/require-documents';
  static String adminVerificationSuspend(String id) =>
      '/admin/verifications/$id/suspend';
  static const adminOrders = '/admin/orders';
  static String adminOrderDetail(String id) => '/admin/orders/$id';
  static String adminOrderStatus(String id) => '/admin/orders/$id/status';
  static const adminAuditLogs = '/admin/audit-logs';
  static const adminSettings = '/admin/settings';
  static const qualityReadiness = '/quality/readiness';
  static const qualityRuns = '/quality/runs';
  static String qualityRun(String id) => '/quality/runs/$id';
  static String qualityRunResults(String id) => '/quality/runs/$id/results';
  static const releaseChecklist = '/quality/release-checklist';
  static String releaseChecklistItem(String id) =>
      '/quality/release-checklist/$id';
  static const deploymentRuns = '/quality/deployments';
  static String deploymentComplete(String id) =>
      '/quality/deployments/$id/complete';
  static String adminSetting(String key) => '/admin/settings/$key';

  // Merged API endpoints from older feature packs.
  static const login = '/auth/login';
  static const register = '/auth/register';
  static const devLogin = '/auth/dev-login';
  static const meDeleteRequest = '/me/delete-request';
  static const meSettings = '/me/settings';
  static const meSessions = '/me/sessions';
  static String meSession(String id) => '/me/sessions/$id';
  static const meAddresses = '/me/addresses';
  static String meAddress(String id) => '/me/addresses/$id';
  static String meAddressDefault(String id) => '/me/addresses/$id/default';
  static const meFavorites = '/me/favorites';
  static String meFavoriteListing(String id) => '/me/favorites/listings/$id';
  static String meFavoriteListingStatus(String id) =>
      '/me/favorites/listings/$id/status';
  static String meFavoriteListingPreferences(String id) =>
      '/me/favorites/listings/$id/preferences';
  static const meFollowedProviders = '/me/followed-providers';
  static String meFollowedProvider(String id) => '/me/followed-providers/$id';
  static String meFollowedProviderStatus(String id) =>
      '/me/followed-providers/$id/status';
  static const notifications = '/notifications/my';
  static const notificationReadAll = '/notifications/read-all';
  static const notificationRegisterDevice = '/notifications/devices';
  static String notificationDelete(String id) => '/notifications/$id';
  static const loyaltySummary = '/rewards/loyalty/summary';
  static const loyaltyRedeem = '/rewards/loyalty/redeem';
  static const referralUse = '/rewards/referrals/use';
  static const wallet = '/rewards/wallet';
  static const walletTransactions = '/rewards/wallet/transactions';
  static const customerChats = '/me/chats';
  static const customerChatsOpen = '/me/chats/open';
  static String customerChat(String id) => '/me/chats/$id';
  static String customerChatMessages(String id) => '/me/chats/$id/messages';
  static String customerChatRead(String id) => '/me/chats/$id/read';
  static String customerChatStatus(String id) => '/me/chats/$id/status';
  static String supportTicket(String id) => '/support/tickets/$id';
  static const supportComplaints = '/support/complaints';
  static const helpFaqs = '/help/faqs';
  static const helpWhatsappLinks = '/help/whatsapp-links';
  static String reviews(String type, String targetId) =>
      '/reviews/$type/$targetId';
  static String organizationBranch(String organizationId, String branchId) =>
      '/organizations/$organizationId/branches/$branchId';
  static String organizationBranchBusinessHours(
          String organizationId, String branchId) =>
      '/organizations/$organizationId/branches/$branchId/business-hours';
  static String organizationBankAccount(String id, String bankId) =>
      '/organizations/$id/bank-accounts/$bankId';
  static String organizationReadiness(String id) =>
      '/organizations/$id/readiness';
  static String organizationRoles(String id) => '/organizations/$id/roles';
  static String organizationInvitations(String id) =>
      '/organizations/$id/employees';
  static String organizationMemberPermissions(String id, String memberId) =>
      '/organizations/$id/employees/$memberId/permissions';
  static String organizationMember(String id, String memberId) =>
      '/organizations/$id/employees/$memberId';
  static String organizationMemberBranchAccess(String id, String memberId) =>
      '/organizations/$id/employees/$memberId/branch-access';
  static String organizationRole(String id, String roleId) =>
      '/organizations/$id/roles/$roleId';
  static String organizationInvitation(String id, String invitationId) =>
      '/organizations/$id/employees/invitations/$invitationId';
  static String organizationAuditLogs(String id) =>
      '/organizations/$id/audit-logs';
  static String organizationPermissions(String id) =>
      '/organizations/$id/employees/available-permissions';
  static const customerHome = '/listings/customer-home';
  static const compareListings = '/listings/compare';
  static String listingCompatibility(String id) =>
      '/listings/$id/compatibility';
  static const cartCheckoutPreview = '/checkout/preview';
  static const customerCoupons = '/me/coupons';
  static const customerCouponValidate = '/me/coupons/validate';
  static String orderReturnOptions(String id) => '/orders/$id/return-options';
  static String orderReturnRequest(String id) => '/orders/$id/return-request';
  static const customerReturns = '/me/returns';
  static String customerReturnDetail(String id) => '/me/returns/$id';
  static String customerOrderDisputeOptions(String id) =>
      '/orders/$id/dispute-options';
  static String customerOrderDisputeRequest(String id) =>
      '/orders/$id/dispute-request';
  static const customerDisputes = '/me/disputes';
  static String customerDisputeDetail(String id) => '/me/disputes/$id';
  static String customerDisputeMessages(String id) =>
      '/me/disputes/$id/messages';
  static String customerDisputeReopen(String id) => '/me/disputes/$id/reopen';
  static String customerDisputeClose(String id) => '/me/disputes/$id/close';
  static String customerOrderCancellationOptions(String id) =>
      '/orders/$id/cancellation-options';
  static String customerOrderCancel(String id) => '/orders/$id/cancel';
  static String customerOrderReorder(String id) => '/orders/$id/reorder';
  static String customerOrderPayment(String id) => '/orders/$id/payment';
  static String customerOrderPaymentProof(String id) =>
      '/orders/$id/payment/proof';
  static String customerOrderPaymentRetry(String id) =>
      '/orders/$id/payment/retry';
  static String customerOrderInvoice(String id) => '/orders/$id/invoice';
  static String customerOrderShipment(String id) => '/orders/$id/shipment';
  static String customerOrderShipmentReschedule(String id) =>
      '/orders/$id/shipment/reschedule';
  static String customerOrderReviewOptions(String id) =>
      '/orders/$id/review-options';
  static String customerOrderReviews(String id) => '/orders/$id/reviews';
  static const customerReviewHistory = '/me/reviews';
  static String merchantOrderInvoice(String id) =>
      '/merchant/orders/$id/invoice';
  static const merchantDashboardSummary = '/merchant/dashboard/summary';
  static const merchantInventory = '/merchant/inventory';
  static String merchantInventoryAdjust(String organizationId) =>
      '/merchant/organizations/$organizationId/inventory/adjust';
  static String merchantInventoryMovements(String inventoryId) =>
      '/merchant/inventory/$inventoryId/movements';
  static String merchantInventoryReorderLevel(String inventoryId) =>
      '/merchant/inventory/$inventoryId/reorder-level';
  static String merchantInventoryTransfer(String organizationId) =>
      '/merchant/organizations/$organizationId/inventory/transfer';
  static const merchantBranches = '/merchant/branches';
  static String merchantImportJobs(String organizationId) =>
      '/merchant/organizations/$organizationId/import-jobs';
  static const merchantProductImages = '/merchant/product-images';
  static const merchantProductLookup = '/merchant/products/lookup';
  static const merchantProducts = '/merchant/products';
  static const merchantReports = '/merchant/reports';
  static const merchantReportsExport = '/merchant/reports/export';
  static const merchantNotifications = '/merchant/notifications';
  static const merchantCoupons = '/merchant/coupons';
  static const merchantReturns = '/merchant/returns';
  static String merchantReturnDetail(String id) => '/merchant/returns/$id';
  static String merchantReturnStatus(String id) =>
      '/merchant/returns/$id/status';
  static String merchantReturnDecision(String id) =>
      '/merchant/returns/$id/decision';
  static String merchantReturnReceive(String id) =>
      '/merchant/returns/$id/receive';
  static String merchantReturnRefund(String id) =>
      '/merchant/returns/$id/refund';
  static const merchantDisputes = '/merchant/disputes';
  static String merchantDisputeDetail(String id) => '/merchant/disputes/$id';
  static String merchantDisputeStatus(String id) =>
      '/merchant/disputes/$id/status';
  static String merchantDisputeMessage(String id) =>
      '/merchant/disputes/$id/messages';
  static String merchantDisputeResolve(String id) =>
      '/merchant/disputes/$id/resolve';
  static const merchantSupportTickets = '/merchant/support-tickets';
  static String merchantSupportTicketDetail(String id) =>
      '/merchant/support-tickets/$id';
  static String merchantSupportTicketMessages(String id) =>
      '/merchant/support-tickets/$id/messages';
  static String merchantSupportTicketRead(String id) =>
      '/merchant/support-tickets/$id/read';
  static String merchantSupportTicketStatus(String id) =>
      '/merchant/support-tickets/$id/status';
  static const merchantReviewsDashboard = '/merchant/reviews';
  static String merchantReviewReply(String type, String id) =>
      '/merchant/reviews/$type/$id/replies';
  static const merchantFinanceSummary = '/merchant/finance/summary';
  static const merchantFinanceLedger = '/merchant/finance/ledger';
  static const merchantFinanceStatement = '/merchant/finance/statement';
  static const merchantWithdrawals = '/merchant/withdrawals';
  static const merchantWallets = '/merchant/wallets';
  static String merchantWalletTransactions(String walletId) =>
      '/merchant/wallets/$walletId/transactions';
  static const merchantPayments = '/merchant/payments';
  static const merchantSettlements = '/merchant/settlements';
  static const merchantInvoices = '/merchant/invoices';
  static String merchantShipmentDetail(String id) => '/delivery/shipments/$id';
  static String merchantShipmentAssign(String id) =>
      '/delivery/shipments/$id/assign';
  static String merchantShipmentReschedule(String id) =>
      '/delivery/shipments/$id/reschedule';
  static String merchantShipmentStatus(String id) =>
      '/delivery/shipments/$id/status';
  static const merchantNotificationRead = '/merchant/notifications/read';
  static const merchantNotificationsReadAll =
      '/merchant/notifications/read-all';
  static const merchantNotificationPreferences =
      '/merchant/notifications/preferences';
  static const adminCoupons = '/admin/coupons';
  static const adminComplaints = '/admin/support/complaints';
  static const auditLogs = '/admin/system/audit-logs';
  static const eventLogs = '/admin/system/event-logs';
  static String organizationMembers(String id) =>
      '/organizations/$id/employees';
  static const registerMerchant = '/auth/register/merchant';
  static String merchantInventoryListingMovements(String id) =>
      '/merchant/inventory/$id/movements';
}
