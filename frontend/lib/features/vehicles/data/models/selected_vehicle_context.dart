class SelectedVehicleContext {
  final int makeId;
  final String makeName;
  final int modelId;
  final String modelName;
  final int year;
  final String? vin;

  const SelectedVehicleContext({
    required this.makeId,
    required this.makeName,
    required this.modelId,
    required this.modelName,
    required this.year,
    this.vin,
  });

  String get displayName => '$makeName $modelName $year';

  factory SelectedVehicleContext.fromJson(Map<String, dynamic> json) {
    return SelectedVehicleContext(
      makeId: int.parse(json['makeId'].toString()),
      makeName: (json['makeName'] ?? '').toString(),
      modelId: int.parse(json['modelId'].toString()),
      modelName: (json['modelName'] ?? '').toString(),
      year: int.parse(json['year'].toString()),
      vin: json['vin']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'makeId': makeId,
        'makeName': makeName,
        'modelId': modelId,
        'modelName': modelName,
        'year': year,
        'vin': vin,
      };
}
