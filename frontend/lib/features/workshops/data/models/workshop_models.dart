class WorkshopServiceModel {
  final String id;
  final String name;
  final String? organizationName;
  final String? branchName;
  final String categoryCode;
  final String? description;
  final int? durationMinutes;
  final double? basePrice;
  final String currency;
  final bool requiresDiagnosis;
  final bool supportsMobileService;
  final String status;

  const WorkshopServiceModel({
    required this.id,
    required this.name,
    this.organizationName,
    this.branchName,
    required this.categoryCode,
    this.description,
    this.durationMinutes,
    this.basePrice,
    required this.currency,
    required this.requiresDiagnosis,
    required this.supportsMobileService,
    required this.status,
  });

  factory WorkshopServiceModel.fromMap(Map<String, dynamic> map) {
    return WorkshopServiceModel(
      id: (map['id'] ?? map['public_id'] ?? '').toString(),
      name: (map['name_ar'] ?? map['nameAr'] ?? 'خدمة ورشة').toString(),
      organizationName:
          (map['organization_name'] ?? map['organization']?['displayName'])
              ?.toString(),
      branchName:
          (map['branch_name'] ?? map['branch']?['branchName'])?.toString(),
      categoryCode:
          (map['category_code'] ?? map['categoryCode'] ?? 'general').toString(),
      description: (map['description'])?.toString(),
      durationMinutes: int.tryParse((map['estimated_duration_minutes'] ??
              map['estimatedDurationMinutes'] ??
              '')
          .toString()),
      basePrice: double.tryParse(
          (map['base_price'] ?? map['basePrice'] ?? '').toString()),
      currency: (map['currency'] ?? 'YER').toString(),
      requiresDiagnosis:
          map['requires_diagnosis'] == true || map['requiresDiagnosis'] == true,
      supportsMobileService: map['supports_mobile_service'] == true ||
          map['supportsMobileService'] == true,
      status: (map['status'] ?? 'ACTIVE').toString(),
    );
  }
}

class WorkshopBookingModel {
  final String id;
  final String status;
  final String serviceName;
  final String workshopName;
  final String preferredDate;
  final String? timeWindow;
  final double? estimatedAmount;

  const WorkshopBookingModel({
    required this.id,
    required this.status,
    required this.serviceName,
    required this.workshopName,
    required this.preferredDate,
    this.timeWindow,
    this.estimatedAmount,
  });

  factory WorkshopBookingModel.fromMap(Map<String, dynamic> map) {
    return WorkshopBookingModel(
      id: (map['id'] ?? map['publicId'] ?? '').toString(),
      status: (map['status'] ?? 'REQUESTED').toString(),
      serviceName: (map['workshopService']?['nameAr'] ??
              map['workshop_service']?['name_ar'] ??
              'خدمة ورشة')
          .toString(),
      workshopName: (map['organization']?['displayName'] ??
              map['organization_name'] ??
              'ورشة')
          .toString(),
      preferredDate:
          (map['preferredDate'] ?? map['preferred_date'] ?? '').toString(),
      timeWindow: (map['preferredTimeWindow'] ?? map['preferred_time_window'])
          ?.toString(),
      estimatedAmount: double.tryParse(
          (map['estimatedAmount'] ?? map['estimated_amount'] ?? '').toString()),
    );
  }
}

class ServiceOrderModel {
  final String id;
  final String number;
  final String status;
  final String serviceName;
  final String customerName;
  final double? estimatedAmount;
  final double? finalAmount;

  const ServiceOrderModel({
    required this.id,
    required this.number,
    required this.status,
    required this.serviceName,
    required this.customerName,
    this.estimatedAmount,
    this.finalAmount,
  });

  factory ServiceOrderModel.fromMap(Map<String, dynamic> map) {
    return ServiceOrderModel(
      id: (map['id'] ?? map['publicId'] ?? '').toString(),
      number: (map['serviceOrderNumber'] ?? map['service_order_number'] ?? '')
          .toString(),
      status: (map['status'] ?? 'OPEN').toString(),
      serviceName:
          (map['workshopService']?['nameAr'] ?? 'أمر صيانة').toString(),
      customerName: (map['user']?['displayName'] ??
              map['user']?['phoneNormalized'] ??
              'عميل')
          .toString(),
      estimatedAmount:
          double.tryParse((map['estimatedAmount'] ?? '').toString()),
      finalAmount: double.tryParse((map['finalAmount'] ?? '').toString()),
    );
  }
}

class MaintenanceRecordModel {
  final String id;
  final String title;
  final String serviceDate;
  final String vehicleName;
  final double? costAmount;

  const MaintenanceRecordModel({
    required this.id,
    required this.title,
    required this.serviceDate,
    required this.vehicleName,
    this.costAmount,
  });

  factory MaintenanceRecordModel.fromMap(Map<String, dynamic> map) {
    final vehicle = map['customerVehicle'];
    final vehicleName = vehicle is Map
        ? '${vehicle['make']?['nameAr'] ?? ''} ${vehicle['model']?['nameAr'] ?? ''} ${vehicle['yearValue'] ?? ''}'
        : 'مركبة';
    return MaintenanceRecordModel(
      id: (map['id'] ?? map['publicId'] ?? '').toString(),
      title: (map['title'] ?? 'صيانة').toString(),
      serviceDate: (map['serviceDate'] ?? '').toString(),
      vehicleName: vehicleName.trim().isEmpty ? 'مركبة' : vehicleName.trim(),
      costAmount: double.tryParse((map['costAmount'] ?? '').toString()),
    );
  }
}

class WorkshopServiceCategoryModel {
  final String id;
  final String code;
  final String name;
  final String? description;

  const WorkshopServiceCategoryModel({
    required this.id,
    required this.code,
    required this.name,
    this.description,
  });

  factory WorkshopServiceCategoryModel.fromMap(Map<String, dynamic> map) {
    return WorkshopServiceCategoryModel(
      id: (map['id'] ?? map['publicId'] ?? '').toString(),
      code: (map['code'] ?? '').toString(),
      name: (map['name_ar'] ?? map['nameAr'] ?? map['name'] ?? 'تصنيف')
          .toString(),
      description: (map['description'])?.toString(),
    );
  }
}

class BookingSlotModel {
  final String id;
  final String status;
  final String startAt;
  final String endAt;
  final int capacity;
  final int bookedCount;
  final String? branchName;
  final String? technicianName;

  const BookingSlotModel({
    required this.id,
    required this.status,
    required this.startAt,
    required this.endAt,
    required this.capacity,
    required this.bookedCount,
    this.branchName,
    this.technicianName,
  });

  bool get isAvailable => status == 'AVAILABLE' && bookedCount < capacity;

  factory BookingSlotModel.fromMap(Map<String, dynamic> map) {
    return BookingSlotModel(
      id: (map['id'] ?? map['publicId'] ?? '').toString(),
      status: (map['status'] ?? 'AVAILABLE').toString(),
      startAt: (map['startAt'] ?? map['start_at'] ?? '').toString(),
      endAt: (map['endAt'] ?? map['end_at'] ?? '').toString(),
      capacity: int.tryParse((map['capacity'] ?? '1').toString()) ?? 1,
      bookedCount: int.tryParse(
              (map['bookedCount'] ?? map['booked_count'] ?? '0').toString()) ??
          0,
      branchName:
          (map['branch']?['branchName'] ?? map['branch_name'])?.toString(),
      technicianName: (map['technician']?['fullName'] ?? map['technician_name'])
          ?.toString(),
    );
  }
}
