import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/config/api_endpoints.dart';
import 'package:ghiyarak/core/network/api_client.dart';
import 'package:ghiyarak/features/logistics/data/models/logistics_models.dart';

final logisticsRepositoryProvider = Provider<LogisticsRepository>((ref) {
  return LogisticsRepository(ref.watch(apiClientProvider));
});

class LogisticsRepository {
  final ApiClient _apiClient;
  LogisticsRepository(this._apiClient);

  List<Map<String, dynamic>> _dataList(dynamic responseData) {
    final data = responseData is Map ? responseData['data'] : null;
    final list = data is List ? data : const <dynamic>[];
    return list
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<List<PaymentTransactionModel>> getOrderTransactions(
      String orderId) async {
    final response =
        await _apiClient.get(ApiEndpoints.orderPaymentTransactions(orderId));
    return _dataList(response.data)
        .map(PaymentTransactionModel.fromMap)
        .toList();
  }

  Future<Map<String, dynamic>> paymentMethods() async {
    final response = await _apiClient.get(ApiEndpoints.paymentMethods);
    return Map<String, dynamic>.from((response.data ?? {}) as Map);
  }

  Future<Map<String, dynamic>> createPaymentIntent(String orderId,
      {required String methodCode}) async {
    final response =
        await _apiClient.post(ApiEndpoints.orderPaymentIntent(orderId), data: {
      'paymentMethodCode': methodCode,
      'idempotencyKey': 'order-$orderId-$methodCode',
    });
    return Map<String, dynamic>.from((response.data['data'] ?? {}) as Map);
  }

  Future<void> createBankTransferPayment(String orderId) async {
    await createPaymentIntent(orderId, methodCode: 'BANK_TRANSFER');
  }

  Future<void> uploadPaymentProof(String paymentId,
      {required String fileUrl,
      String? referenceNumber,
      double? amount}) async {
    await _apiClient.post(ApiEndpoints.paymentProofs(paymentId), data: {
      'fileUrl': fileUrl,
      if ((referenceNumber ?? '').isNotEmpty)
        'referenceNumber': referenceNumber,
      if (amount != null) 'amount': amount,
    });
  }

  Future<List<PaymentTransactionModel>> myPayments() async {
    final response = await _apiClient.get(ApiEndpoints.myPayments);
    return _dataList(response.data)
        .map(PaymentTransactionModel.fromMap)
        .toList();
  }

  Future<List<Map<String, dynamic>>> financePayments({String? status}) async {
    final response = await _apiClient.get(ApiEndpoints.financePayments,
        queryParameters: {if ((status ?? '').isNotEmpty) 'status': status});
    return _dataList(response.data);
  }

  Future<List<Map<String, dynamic>>> financePaymentProofs(
      {String? status}) async {
    final response = await _apiClient.get(ApiEndpoints.financePaymentProofs,
        queryParameters: {if ((status ?? '').isNotEmpty) 'status': status});
    return _dataList(response.data);
  }

  Future<void> approvePaymentProof(String proofId, {String? note}) async {
    await _apiClient.post(ApiEndpoints.financeApprovePaymentProof(proofId),
        data: {if ((note ?? '').isNotEmpty) 'note': note});
  }

  Future<void> rejectPaymentProof(String proofId, {String? note}) async {
    await _apiClient.post(ApiEndpoints.financeRejectPaymentProof(proofId),
        data: {if ((note ?? '').isNotEmpty) 'note': note});
  }

  Future<List<Map<String, dynamic>>> financeRefunds({String? status}) async {
    final response = await _apiClient.get(ApiEndpoints.financeRefunds,
        queryParameters: {if ((status ?? '').isNotEmpty) 'status': status});
    return _dataList(response.data);
  }

  Future<void> approveRefund(String refundId) async {
    await _apiClient.post(ApiEndpoints.financeApproveRefund(refundId));
  }

  Future<void> rejectRefund(String refundId, {String? note}) async {
    await _apiClient.post(ApiEndpoints.financeRejectRefund(refundId),
        data: {if ((note ?? '').isNotEmpty) 'note': note});
  }

  Future<void> markRefunded(String refundId) async {
    await _apiClient.post(ApiEndpoints.financeMarkRefunded(refundId));
  }

  Future<List<Map<String, dynamic>>> financeSettlements(
      {String? status}) async {
    final response = await _apiClient.get(ApiEndpoints.financeSettlements,
        queryParameters: {if ((status ?? '').isNotEmpty) 'status': status});
    return _dataList(response.data);
  }

  Future<void> approveSettlement(String settlementId) async {
    await _apiClient.post(ApiEndpoints.financeApproveSettlement(settlementId));
  }

  Future<void> markSettlementPaid(String settlementId) async {
    await _apiClient.post(ApiEndpoints.financeMarkSettlementPaid(settlementId));
  }

  Future<void> markPaymentPaid(String transactionId) async {
    await _apiClient
        .patch(ApiEndpoints.paymentTransactionPaid(transactionId), data: {
      'note': 'تم اعتماد الدفع من واجهة العمليات',
    });
  }

  Future<List<Map<String, dynamic>>> accountingAccounts() async {
    final response = await _apiClient.get(ApiEndpoints.accountingAccounts);
    return _dataList(response.data);
  }

  Future<List<Map<String, dynamic>>> accountingJournalEntries() async {
    final response =
        await _apiClient.get(ApiEndpoints.accountingJournalEntries);
    return _dataList(response.data);
  }

  Future<List<Map<String, dynamic>>> accountingFinancialTransactions() async {
    final response =
        await _apiClient.get(ApiEndpoints.accountingFinancialTransactions);
    return _dataList(response.data);
  }

  Future<List<Map<String, dynamic>>> accountingMerchantBalances() async {
    final response =
        await _apiClient.get(ApiEndpoints.accountingMerchantBalances);
    return _dataList(response.data);
  }

  Future<List<ShipmentModel>> getMyShipments() async {
    final response = await _apiClient.get(ApiEndpoints.myShipments);
    return _dataList(response.data).map(ShipmentModel.fromMap).toList();
  }

  Future<List<ShipmentModel>> getMerchantShipments() async {
    final response = await _apiClient.get(ApiEndpoints.merchantShipments);
    return _dataList(response.data).map(ShipmentModel.fromMap).toList();
  }

  Future<List<ShipmentModel>> getDriverShipments() async {
    final response = await _apiClient.get(ApiEndpoints.driverShipments);
    return _dataList(response.data).map(ShipmentModel.fromMap).toList();
  }

  Future<List<ShipmentModel>> getAdminShipments() async {
    final response = await _apiClient.get(ApiEndpoints.adminShipments);
    return _dataList(response.data).map(ShipmentModel.fromMap).toList();
  }

  Future<List<Map<String, dynamic>>> getDrivers() async {
    final response = await _apiClient.get(ApiEndpoints.deliveryDrivers);
    return _dataList(response.data);
  }

  Future<List<Map<String, dynamic>>> getShippingCompanies() async {
    final response =
        await _apiClient.get(ApiEndpoints.deliveryShippingCompanies);
    return _dataList(response.data);
  }

  Future<List<Map<String, dynamic>>> getDeliveryFeeRules() async {
    final response = await _apiClient.get(ApiEndpoints.deliveryFeeRules);
    return _dataList(response.data);
  }

  Future<void> assignShipment(
      {required String shipmentId,
      String? driverId,
      String? shippingCompanyId,
      String? trackingNumber}) async {
    await _apiClient.patch(ApiEndpoints.shipmentAssign(shipmentId), data: {
      if ((driverId ?? '').isNotEmpty) 'driverId': int.tryParse(driverId!),
      if ((shippingCompanyId ?? '').isNotEmpty)
        'shippingCompanyId': int.tryParse(shippingCompanyId!),
      if ((trackingNumber ?? '').isNotEmpty) 'trackingNumber': trackingNumber,
      'note': 'تم تعيين الشحنة من تطبيق غيارك',
    });
  }

  Future<void> acceptDriverShipment(String shipmentId) async {
    await _apiClient.patch(ApiEndpoints.shipmentDriverAccept(shipmentId),
        data: {'note': 'تم قبول الشحنة من السائق'});
  }

  Future<void> createShipment(
      {required String orderId,
      required String courierName,
      required double deliveryFee,
      String? notes}) async {
    await _apiClient.post(ApiEndpoints.orderShipment(orderId), data: {
      'courierName': courierName,
      'deliveryFee': deliveryFee,
      if ((notes ?? '').isNotEmpty) 'notes': notes,
    });
  }

  Future<void> updateShipmentStatus(
      {required String shipmentId, required String status}) async {
    await _apiClient.patch(ApiEndpoints.shipmentStatus(shipmentId), data: {
      'status': status,
      'note': 'تحديث حالة من تطبيق غيارك',
    });
  }

  Future<List<NotificationModel>> getNotifications() async {
    final response = await _apiClient.get(ApiEndpoints.myNotifications);
    return _dataList(response.data).map(NotificationModel.fromMap).toList();
  }

  Future<void> markNotificationRead(String id) async {
    await _apiClient.patch(ApiEndpoints.notificationRead(id));
  }

  Future<void> markAllNotificationsRead() async {
    await _apiClient.patch(ApiEndpoints.notificationsReadAll);
  }
}
