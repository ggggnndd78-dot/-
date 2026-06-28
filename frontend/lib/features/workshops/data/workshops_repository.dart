import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/config/api_endpoints.dart';
import 'package:ghiyarak/core/network/api_client.dart';
import 'package:ghiyarak/features/workshops/data/models/workshop_models.dart';

final workshopsRepositoryProvider = Provider<WorkshopsRepository>((ref) {
  return WorkshopsRepository(ref.watch(apiClientProvider));
});

class WorkshopsRepository {
  final ApiClient _apiClient;
  WorkshopsRepository(this._apiClient);

  List<Map<String, dynamic>> _dataList(dynamic responseData) {
    final data = responseData is Map ? responseData['data'] : null;
    final list = data is List ? data : const <dynamic>[];
    return list
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<List<WorkshopServiceCategoryModel>> getServiceCategories() async {
    final response =
        await _apiClient.get(ApiEndpoints.workshopServiceCategories);
    return _dataList(response.data)
        .map(WorkshopServiceCategoryModel.fromMap)
        .toList();
  }

  Future<List<BookingSlotModel>> getBookingSlots({
    required String workshopServiceId,
    required DateTime date,
    String? branchId,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.workshopBookingSlots,
      queryParameters: {
        'workshopServiceId': int.parse(workshopServiceId),
        'date': date.toIso8601String().substring(0, 10),
        if ((branchId ?? '').isNotEmpty) 'branchId': int.parse(branchId!),
      },
    );
    return _dataList(response.data).map(BookingSlotModel.fromMap).toList();
  }

  Future<List<WorkshopServiceModel>> getWorkshopServices({String? q}) async {
    final response = await _apiClient.get(
      ApiEndpoints.workshopServices,
      queryParameters: {if ((q ?? '').isNotEmpty) 'q': q},
    );
    return _dataList(response.data).map(WorkshopServiceModel.fromMap).toList();
  }

  Future<List<WorkshopBookingModel>> getMyBookings() async {
    final response = await _apiClient.get(ApiEndpoints.myWorkshopBookings);
    return _dataList(response.data).map(WorkshopBookingModel.fromMap).toList();
  }

  Future<List<MaintenanceRecordModel>> getMyMaintenanceRecords() async {
    final response = await _apiClient.get(ApiEndpoints.myMaintenanceRecords);
    return _dataList(response.data)
        .map(MaintenanceRecordModel.fromMap)
        .toList();
  }

  Future<void> createBooking({
    required String serviceId,
    String? bookingSlotId,
    String? customerVehicleId,
    DateTime? preferredDate,
    String? preferredTimeWindow,
    String? problemDescription,
  }) async {
    final preferred =
        preferredDate ?? DateTime.now().add(const Duration(days: 1));
    await _apiClient.post(
      ApiEndpoints.workshopBookings,
      data: {
        'workshopServiceId': int.parse(serviceId),
        if ((bookingSlotId ?? '').isNotEmpty)
          'bookingSlotId': int.parse(bookingSlotId!),
        if ((customerVehicleId ?? '').isNotEmpty)
          'customerVehicleId': int.parse(customerVehicleId!),
        'preferredDate': preferred.toIso8601String(),
        if ((preferredTimeWindow ?? '').isNotEmpty)
          'preferredTimeWindow': preferredTimeWindow,
        'customerProblemDescription':
            problemDescription ?? 'طلب حجز خدمة من تطبيق غيارك',
      },
    );
  }

  Future<void> cancelBooking(String bookingId, {String? reason}) async {
    await _apiClient.patch(
      ApiEndpoints.cancelWorkshopBooking(bookingId),
      data: {if ((reason ?? '').isNotEmpty) 'reason': reason},
    );
  }

  Future<void> submitBookingRating({
    required String bookingId,
    required int rating,
    String? title,
    String? body,
  }) async {
    await _apiClient.post(
      ApiEndpoints.rateWorkshopBooking(bookingId),
      data: {
        'rating': rating,
        if ((title ?? '').isNotEmpty) 'title': title,
        if ((body ?? '').isNotEmpty) 'body': body,
      },
    );
  }

  Future<List<WorkshopServiceModel>> getMyWorkshopServices() async {
    final response =
        await _apiClient.get(ApiEndpoints.workshopOperationsServices);
    return _dataList(response.data).map(WorkshopServiceModel.fromMap).toList();
  }

  Future<List<WorkshopBookingModel>> getWorkshopBookings() async {
    final response =
        await _apiClient.get(ApiEndpoints.workshopOperationsBookings);
    return _dataList(response.data).map(WorkshopBookingModel.fromMap).toList();
  }

  Future<List<ServiceOrderModel>> getServiceOrders() async {
    final response =
        await _apiClient.get(ApiEndpoints.workshopOperationsServiceOrders);
    return _dataList(response.data).map(ServiceOrderModel.fromMap).toList();
  }

  Future<String?> firstWorkshopOrganizationPublicId() async {
    final response = await _apiClient.get(ApiEndpoints.organizationsMine);
    final data = response.data is Map ? response.data['data'] : null;
    final list = data is List ? data : const <dynamic>[];
    for (final item in list.whereType<Map>()) {
      final map = Map<String, dynamic>.from(item);
      final type =
          (map['organization_type'] ?? map['organizationType']).toString();
      if (type == 'WORKSHOP') return (map['id'] ?? map['publicId']).toString();
    }
    return null;
  }

  Future<List<BookingSlotModel>> getWorkshopBookingSlots() async {
    final response =
        await _apiClient.get(ApiEndpoints.workshopOperationsBookingSlots);
    return _dataList(response.data).map(BookingSlotModel.fromMap).toList();
  }

  Future<void> createBookingSlot({
    required String workshopServiceId,
    required DateTime date,
    required String startTime,
    required String endTime,
    int capacity = 1,
  }) async {
    await _apiClient.post(
      ApiEndpoints.workshopOperationsBookingSlots,
      data: {
        'workshopServiceId': int.parse(workshopServiceId),
        'date': date.toIso8601String().substring(0, 10),
        'startTime': startTime,
        'endTime': endTime,
        'capacity': capacity,
      },
    );
  }

  Future<void> createWorkshopService({
    required String nameAr,
    required String categoryCode,
    String? description,
    int estimatedDurationMinutes = 30,
    double basePrice = 0,
    bool requiresDiagnosis = true,
  }) async {
    final organizationId = await firstWorkshopOrganizationPublicId();
    if (organizationId == null || organizationId.isEmpty) {
      throw Exception('لا توجد ورشة مرتبطة بحسابك');
    }
    await _apiClient.post(
      ApiEndpoints.workshopOperationsServices,
      data: {
        'organizationPublicId': organizationId,
        'nameAr': nameAr,
        'categoryCode': categoryCode,
        if ((description ?? '').isNotEmpty) 'description': description,
        'estimatedDurationMinutes': estimatedDurationMinutes,
        'basePrice': basePrice,
        'requiresDiagnosis': requiresDiagnosis,
      },
    );
  }

  Future<void> updateBookingStatus({
    required String bookingId,
    required String status,
    String? note,
  }) async {
    await _apiClient.patch(
      ApiEndpoints.workshopOperationsBookingStatus(bookingId),
      data: {'status': status, if (note != null) 'note': note},
    );
  }

  Future<void> createServiceOrderFromBooking(String bookingId) async {
    await _apiClient.post(
      ApiEndpoints.workshopOperationsBookingServiceOrder(bookingId),
      data: {'priority': 'NORMAL'},
    );
  }

  Future<void> updateServiceOrderStatus({
    required String serviceOrderId,
    required String status,
    String? note,
  }) async {
    await _apiClient.patch(
      ApiEndpoints.workshopOperationsServiceOrderStatus(serviceOrderId),
      data: {'status': status, if (note != null) 'note': note},
    );
  }

  Future<void> addDiagnosticReport(String serviceOrderId) async {
    await _apiClient.post(
      ApiEndpoints.workshopOperationsDiagnostics(serviceOrderId),
      data: {
        'findings': 'تم فحص السيارة وتحديد سبب المشكلة بشكل مبدئي.',
        'recommendedActions': 'ينصح بإكمال الصيانة حسب تقرير الفني.',
        'estimatedRepairCost': 5000,
        'requiresParts': false,
      },
    );
  }
}
