class SupportTicketModel {
  final int id;
  final String ticketNumber;
  final String subject;
  final String status;
  final String priority;
  final String category;
  final String? organizationName;

  SupportTicketModel(
      {required this.id,
      required this.ticketNumber,
      required this.subject,
      required this.status,
      required this.priority,
      required this.category,
      this.organizationName});

  factory SupportTicketModel.fromMap(Map<String, dynamic> map) {
    final org = map['organization'];
    return SupportTicketModel(
      id: int.tryParse(map['id'].toString()) ?? 0,
      ticketNumber: map['ticketNumber']?.toString() ??
          map['ticket_number']?.toString() ??
          '-',
      subject: map['subject']?.toString() ?? '-',
      status: map['status']?.toString() ?? '-',
      priority: map['priority']?.toString() ?? '-',
      category: map['category']?.toString() ?? '-',
      organizationName: org is Map ? org['displayName']?.toString() : null,
    );
  }
}

class ComplaintModel {
  final int id;
  final String complaintNumber;
  final String subject;
  final String status;
  final String severity;

  ComplaintModel(
      {required this.id,
      required this.complaintNumber,
      required this.subject,
      required this.status,
      required this.severity});

  factory ComplaintModel.fromMap(Map<String, dynamic> map) => ComplaintModel(
        id: int.tryParse(map['id'].toString()) ?? 0,
        complaintNumber: map['complaintNumber']?.toString() ??
            map['complaint_number']?.toString() ??
            '-',
        subject: map['subject']?.toString() ?? '-',
        status: map['status']?.toString() ?? '-',
        severity: map['severity']?.toString() ?? '-',
      );
}

class HelpCenterCategoryModel {
  final int id;
  final String code;
  final String title;
  final String description;

  HelpCenterCategoryModel(
      {required this.id,
      required this.code,
      required this.title,
      required this.description});

  factory HelpCenterCategoryModel.fromMap(Map<String, dynamic> map) =>
      HelpCenterCategoryModel(
        id: int.tryParse(map['id'].toString()) ?? 0,
        code: map['code']?.toString() ?? '-',
        title: map['titleAr']?.toString() ?? map['title_ar']?.toString() ?? '-',
        description: map['descriptionAr']?.toString() ??
            map['description_ar']?.toString() ??
            '',
      );
}

class HelpArticleModel {
  final int id;
  final String slug;
  final String title;
  final String summary;
  final String body;
  final bool featured;

  HelpArticleModel(
      {required this.id,
      required this.slug,
      required this.title,
      required this.summary,
      required this.body,
      required this.featured});

  factory HelpArticleModel.fromMap(Map<String, dynamic> map) =>
      HelpArticleModel(
        id: int.tryParse(map['id'].toString()) ?? 0,
        slug: map['slug']?.toString() ?? '-',
        title: map['titleAr']?.toString() ?? map['title_ar']?.toString() ?? '-',
        summary:
            map['summaryAr']?.toString() ?? map['summary_ar']?.toString() ?? '',
        body: map['bodyAr']?.toString() ?? map['body_ar']?.toString() ?? '',
        featured: map['isFeatured'] == true || map['is_featured'] == true,
      );
}

class FaqModel {
  final int id;
  final String question;
  final String answer;

  FaqModel({required this.id, required this.question, required this.answer});

  factory FaqModel.fromMap(Map<String, dynamic> map) => FaqModel(
        id: int.tryParse(map['id'].toString()) ?? 0,
        question: map['questionAr']?.toString() ??
            map['question_ar']?.toString() ??
            '-',
        answer:
            map['answerAr']?.toString() ?? map['answer_ar']?.toString() ?? '',
      );
}

class WhatsappSupportLinkModel {
  final int id;
  final String department;
  final String title;
  final String phone;
  final String url;

  WhatsappSupportLinkModel(
      {required this.id,
      required this.department,
      required this.title,
      required this.phone,
      required this.url});

  factory WhatsappSupportLinkModel.fromMap(Map<String, dynamic> map) =>
      WhatsappSupportLinkModel(
        id: int.tryParse(map['id'].toString()) ?? 0,
        department: map['department']?.toString() ?? 'GENERAL',
        title: map['titleAr']?.toString() ?? map['title_ar']?.toString() ?? '-',
        phone: map['phoneE164']?.toString() ??
            map['phone_e164']?.toString() ??
            '-',
        url: map['url']?.toString() ?? '',
      );
}

class ReviewModel {
  final int id;
  final int rating;
  final String title;
  final String body;
  final String status;
  final String targetType;
  final int repliesCount;
  final int mediaCount;

  ReviewModel(
      {required this.id,
      required this.rating,
      required this.title,
      required this.body,
      required this.status,
      required this.targetType,
      required this.repliesCount,
      required this.mediaCount});

  factory ReviewModel.fromMap(Map<String, dynamic> map, {String? targetType}) {
    final replies = map['replies'] is List ? map['replies'] as List : const [];
    final media = map['media'] is List ? map['media'] as List : const [];
    return ReviewModel(
      id: int.tryParse(map['id'].toString()) ?? 0,
      rating: int.tryParse(map['rating'].toString()) ?? 0,
      title: map['title']?.toString() ?? 'تقييم',
      body: map['body']?.toString() ?? '',
      status: map['status']?.toString() ?? '-',
      targetType: targetType ??
          map['targetType']?.toString() ??
          map['target_type']?.toString() ??
          '-',
      repliesCount: replies.length,
      mediaCount: media.length,
    );
  }
}

class ReputationSummaryModel {
  final String targetType;
  final int targetId;
  final double averageRating;
  final int totalReviews;
  final double reputationScore;

  ReputationSummaryModel(
      {required this.targetType,
      required this.targetId,
      required this.averageRating,
      required this.totalReviews,
      required this.reputationScore});

  factory ReputationSummaryModel.fromMap(Map<String, dynamic> map) =>
      ReputationSummaryModel(
        targetType: map['targetType']?.toString() ??
            map['target_type']?.toString() ??
            '-',
        targetId: int.tryParse(map['targetId']?.toString() ??
                map['target_id']?.toString() ??
                '0') ??
            0,
        averageRating: double.tryParse(map['averageRating']?.toString() ??
                map['average_rating']?.toString() ??
                '0') ??
            0,
        totalReviews: int.tryParse(map['totalReviews']?.toString() ??
                map['total_reviews']?.toString() ??
                '0') ??
            0,
        reputationScore: double.tryParse(map['reputationScore']?.toString() ??
                map['reputation_score']?.toString() ??
                '0') ??
            0,
      );
}
