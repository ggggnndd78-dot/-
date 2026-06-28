class LookupItem {
  final int id;
  final String label;

  const LookupItem({required this.id, required this.label});

  factory LookupItem.fromJson(Map<String, dynamic> json) {
    return LookupItem(
      id: json['id'] as int,
      label: (json['name_ar'] ??
              json['nameAr'] ??
              json['trim_name'] ??
              json['trimName'] ??
              json['label'] ??
              '')
          .toString(),
    );
  }
}
