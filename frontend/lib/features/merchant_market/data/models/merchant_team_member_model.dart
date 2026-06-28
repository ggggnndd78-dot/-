class MerchantTeamMemberModel {
  final int memberId;
  final String id;
  final String userId;
  final String name;
  final String? username;
  final String? phone;
  final String? email;
  final String status;
  final String role;
  final List<String> permissions;
  final List<MerchantMemberBranchAccessModel> branchAccess;
  final DateTime? joinedAt;

  const MerchantTeamMemberModel({
    required this.memberId,
    required this.id,
    required this.userId,
    required this.name,
    this.username,
    this.phone,
    this.email,
    required this.status,
    required this.role,
    this.permissions = const [],
    this.branchAccess = const [],
    this.joinedAt,
  });

  factory MerchantTeamMemberModel.fromMap(Map<String, dynamic> map) {
    final rawPermissions = map['permissions'] ?? map['permission_codes'];
    final rawBranches = map['branch_access'] ?? map['branchAccess'];
    final parsedMemberId =
        int.tryParse((map['member_id'] ?? map['id'] ?? 0).toString()) ?? 0;
    return MerchantTeamMemberModel(
      memberId: parsedMemberId,
      id: (map['id'] ?? parsedMemberId).toString(),
      userId: (map['user_id'] ?? map['userId'] ?? '').toString(),
      name: (map['display_name'] ??
              map['displayName'] ??
              map['username'] ??
              map['phone'] ??
              'مستخدم')
          .toString(),
      username: map['username']?.toString(),
      phone: (map['phone'] ?? map['phone_normalized'])?.toString(),
      email: map['email']?.toString(),
      status: (map['status'] ?? 'ACTIVE').toString().toUpperCase(),
      role: (map['member_role'] ?? map['memberRole'] ?? 'staff').toString(),
      permissions: rawPermissions is List
          ? rawPermissions.map((item) => item.toString()).toList()
          : const [],
      branchAccess: rawBranches is List
          ? rawBranches
              .whereType<Map>()
              .map((item) => MerchantMemberBranchAccessModel.fromMap(
                  Map<String, dynamic>.from(item)))
              .toList()
          : const [],
      joinedAt: DateTime.tryParse(
          (map['created_at'] ?? map['joined_at'] ?? map['createdAt'] ?? '')
              .toString()),
    );
  }

  bool get isActive => status == 'ACTIVE';
  bool get isSuspended => status == 'SUSPENDED';
  bool get isOwner => role.toLowerCase() == 'owner';

  String get contactLabel {
    final items = [phone, email]
        .where((value) => (value ?? '').trim().isNotEmpty)
        .map((value) => value!)
        .toList();
    return items.isEmpty ? 'لا توجد بيانات تواصل' : items.join(' • ');
  }
}

class MerchantMemberBranchAccessModel {
  final String branchId;
  final String branchName;
  final bool canView;
  final bool canManage;

  const MerchantMemberBranchAccessModel({
    required this.branchId,
    required this.branchName,
    required this.canView,
    required this.canManage,
  });

  factory MerchantMemberBranchAccessModel.fromMap(Map<String, dynamic> map) {
    return MerchantMemberBranchAccessModel(
      branchId: (map['branch_id'] ?? map['branchId'] ?? '').toString(),
      branchName: (map['branch_name'] ?? map['branchName'] ?? 'فرع').toString(),
      canView: map['can_view'] != false && map['canView'] != false,
      canManage: map['can_manage'] == true || map['canManage'] == true,
    );
  }
}

class MerchantPermissionOptionModel {
  final String code;
  final String name;
  final String module;

  const MerchantPermissionOptionModel({
    required this.code,
    required this.name,
    required this.module,
  });

  factory MerchantPermissionOptionModel.fromMap(Map<String, dynamic> map) {
    return MerchantPermissionOptionModel(
      code: (map['code'] ?? '').toString(),
      name: (map['name'] ?? map['code'] ?? '').toString(),
      module: (map['module_code'] ?? map['moduleCode'] ?? '').toString(),
    );
  }
}
