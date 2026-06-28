class VehicleModel {
  final String id;
  final int makeId;
  final String make;
  final int modelId;
  final String model;
  final int? variantId;
  final String? variantName;
  final int year;
  final bool isDefault;

  const VehicleModel({
    required this.id,
    required this.makeId,
    required this.make,
    required this.modelId,
    required this.model,
    this.variantId,
    this.variantName,
    required this.year,
    this.isDefault = false,
  });

  factory VehicleModel.fromApi(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'].toString(),
      makeId: json['make_id'] as int,
      make: json['make_name'].toString(),
      modelId: json['model_id'] as int,
      model: json['model_name'].toString(),
      variantId: json['variant_id'] as int?,
      variantName: json['variant_name']?.toString(),
      year: json['year_value'] as int,
      isDefault: json['is_default'] == true,
    );
  }
}
