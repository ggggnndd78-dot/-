class MerchantNotificationResult {
  final List<MerchantNotificationModel> items;
  final int unreadCount;
  final int urgentCount;

  const MerchantNotificationResult({
    required this.items,
    required this.unreadCount,
    required this.urgentCount,
  });

  factory MerchantNotificationResult.fromMap(Map<String, dynamic> map) {
    final rawItems = map['items'];
    return MerchantNotificationResult(
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map(
                (item) => MerchantNotificationModel.fromMap(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
          : const [],
      unreadCount: int.tryParse((map['unread_count'] ?? 0).toString()) ?? 0,
      urgentCount: int.tryParse((map['urgent_count'] ?? 0).toString()) ?? 0,
    );
  }
}

class MerchantNotificationModel {
  final String key;
  final String category;
  final String type;
  final String title;
  final String message;
  final String? targetId;
  final String? targetNumber;
  final DateTime? createdAt;
  final bool isRead;
  final bool isUrgent;

  const MerchantNotificationModel({
    required this.key,
    required this.category,
    required this.type,
    required this.title,
    required this.message,
    this.targetId,
    this.targetNumber,
    this.createdAt,
    required this.isRead,
    required this.isUrgent,
  });

  factory MerchantNotificationModel.fromMap(Map<String, dynamic> map) {
    return MerchantNotificationModel(
      key: (map['key'] ?? '').toString(),
      category: (map['category'] ?? '').toString(),
      type: (map['type'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      message: (map['message'] ?? '').toString(),
      targetId: map['target_id']?.toString(),
      targetNumber: map['target_number']?.toString(),
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? ''),
      isRead: map['is_read'] == true,
      isUrgent: map['is_urgent'] == true,
    );
  }
}
