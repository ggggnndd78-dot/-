class LocationItem {
  final int id;
  final String name;

  const LocationItem({required this.id, required this.name});

  factory LocationItem.fromJson(Map<String, dynamic> json) {
    return LocationItem(
      id: json['id'] as int,
      name:
          (json['nameAr'] ?? json['name_ar'] ?? json['name'] ?? '').toString(),
    );
  }
}
