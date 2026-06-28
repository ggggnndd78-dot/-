class MerchantBankAccountModel {
  const MerchantBankAccountModel({
    required this.id,
    required this.bankName,
    required this.accountName,
    required this.accountNumber,
    this.iban,
    required this.isPrimary,
  });

  final String id;
  final String bankName;
  final String accountName;
  final String accountNumber;
  final String? iban;
  final bool isPrimary;

  factory MerchantBankAccountModel.fromMap(Map<String, dynamic> map) {
    return MerchantBankAccountModel(
      id: (map['id'] ?? '').toString(),
      bankName: (map['bank_name'] ?? map['bankName'] ?? '').toString(),
      accountName: (map['account_name'] ?? map['accountName'] ?? '').toString(),
      accountNumber:
          (map['account_number'] ?? map['accountNumber'] ?? '').toString(),
      iban: (map['iban'] ?? '').toString().trim().isEmpty
          ? null
          : (map['iban'] ?? '').toString(),
      isPrimary: map['is_primary'] == true || map['isPrimary'] == true,
    );
  }
}

class MerchantVerificationRequestModel {
  const MerchantVerificationRequestModel({
    required this.id,
    required this.status,
    this.notes,
    this.reviewSummary,
    this.submittedAt,
    this.reviewedAt,
    this.submittedBy,
    this.reviewedBy,
    this.documents = const [],
    this.reviewNotes = const [],
    this.statusHistory = const [],
  });

  final String id;
  final String status;
  final String? notes;
  final String? reviewSummary;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String? submittedBy;
  final String? reviewedBy;
  final List<MerchantVerificationDocumentModel> documents;
  final List<Map<String, dynamic>> reviewNotes;
  final List<Map<String, dynamic>> statusHistory;

  factory MerchantVerificationRequestModel.fromMap(Map<String, dynamic> map) {
    final docs = map['documents'];
    final notes = map['review_notes'] ?? map['reviewNotes'];
    final history = map['status_history'] ?? map['statusHistory'];
    return MerchantVerificationRequestModel(
      id: (map['id'] ?? '').toString(),
      status: (map['status'] ?? '').toString(),
      notes: map['notes']?.toString(),
      reviewSummary:
          (map['review_summary'] ?? map['reviewSummary'])?.toString(),
      submittedAt: DateTime.tryParse(
          (map['submitted_at'] ?? map['submittedAt'] ?? '').toString()),
      reviewedAt: DateTime.tryParse(
          (map['reviewed_at'] ?? map['reviewedAt'] ?? '').toString()),
      submittedBy: (map['submitted_by'] ?? map['submittedBy'])?.toString(),
      reviewedBy: (map['reviewed_by'] ?? map['reviewedBy'])?.toString(),
      documents: docs is List
          ? docs
              .whereType<Map>()
              .map((e) => MerchantVerificationDocumentModel.fromMap(
                  Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      reviewNotes: notes is List
          ? notes
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : const [],
      statusHistory: history is List
          ? history
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : const [],
    );
  }
}

class MerchantVerificationDocumentModel {
  const MerchantVerificationDocumentModel({
    required this.id,
    required this.documentType,
    required this.fileName,
    required this.fileUrl,
    this.mimeType,
    this.notes,
  });

  final String id;
  final String documentType;
  final String fileName;
  final String fileUrl;
  final String? mimeType;
  final String? notes;

  factory MerchantVerificationDocumentModel.fromMap(Map<String, dynamic> map) {
    return MerchantVerificationDocumentModel(
      id: (map['id'] ?? '').toString(),
      documentType:
          (map['document_type'] ?? map['documentType'] ?? '').toString(),
      fileName: (map['file_name'] ?? map['fileName'] ?? '').toString(),
      fileUrl: (map['file_url'] ?? map['fileUrl'] ?? '').toString(),
      mimeType: (map['mime_type'] ?? map['mimeType'])?.toString(),
      notes: map['notes']?.toString(),
    );
  }
}

class MerchantReadinessItemModel {
  const MerchantReadinessItemModel({
    required this.code,
    required this.title,
    required this.done,
    this.description,
  });

  final String code;
  final String title;
  final bool done;
  final String? description;

  factory MerchantReadinessItemModel.fromMap(Map<String, dynamic> map) {
    return MerchantReadinessItemModel(
      code: (map['code'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      done: map['done'] == true,
      description: map['description']?.toString(),
    );
  }
}

class MerchantReadinessModel {
  const MerchantReadinessModel({required this.percent, required this.items});

  final int percent;
  final List<MerchantReadinessItemModel> items;

  factory MerchantReadinessModel.fromMap(Map<String, dynamic> map) {
    final rawItems = map['items'];
    return MerchantReadinessModel(
      percent: int.tryParse((map['percent'] ?? 0).toString()) ?? 0,
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map((e) => MerchantReadinessItemModel.fromMap(
                  Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }
}
