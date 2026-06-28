class CustomerPaymentSummary {
  final String orderId;
  final String orderNumber;
  final String paymentId;
  final String paymentStatus;
  final String paymentMethod;
  final double amount;
  final String currency;
  final String resultTitle;
  final String resultMessage;
  final bool canUploadProof;
  final bool canRetry;
  final bool canPayFromWallet;
  final List<String> instructions;
  final List<CustomerPaymentAttempt> attempts;
  final List<CustomerPaymentProof> proofs;

  const CustomerPaymentSummary({
    required this.orderId,
    required this.orderNumber,
    required this.paymentId,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.amount,
    required this.currency,
    required this.resultTitle,
    required this.resultMessage,
    this.canUploadProof = false,
    this.canRetry = false,
    this.canPayFromWallet = false,
    this.instructions = const [],
    this.attempts = const [],
    this.proofs = const [],
  });

  factory CustomerPaymentSummary.fromMap(Map<String, dynamic> map) {
    return CustomerPaymentSummary(
      orderId: (map['orderId'] ?? map['order_id'] ?? '').toString(),
      orderNumber: (map['orderNumber'] ?? map['order_number'] ?? '').toString(),
      paymentId: (map['paymentId'] ?? map['payment_id'] ?? '').toString(),
      paymentStatus:
          (map['paymentStatus'] ?? map['payment_status'] ?? '').toString(),
      paymentMethod:
          (map['paymentMethod'] ?? map['payment_method'] ?? '').toString(),
      amount: double.tryParse((map['amount'] ?? 0).toString()) ?? 0,
      currency: (map['currency'] ?? 'YER').toString(),
      resultTitle: (map['resultTitle'] ?? map['result_title'] ?? '').toString(),
      resultMessage:
          (map['resultMessage'] ?? map['result_message'] ?? '').toString(),
      canUploadProof: _bool(map['canUploadProof'] ?? map['can_upload_proof']),
      canRetry: _bool(map['canRetry'] ?? map['can_retry']),
      canPayFromWallet:
          _bool(map['canPayFromWallet'] ?? map['can_pay_from_wallet']),
      instructions: (map['instructions'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .toList(),
      attempts: (map['attempts'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) =>
              CustomerPaymentAttempt.fromMap(Map<String, dynamic>.from(item)))
          .toList(),
      proofs: (map['proofs'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) =>
              CustomerPaymentProof.fromMap(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }

  bool get isSuccess =>
      ['CONFIRMED', 'PAID', 'COMPLETED'].contains(paymentStatus.toUpperCase());
  bool get isPending => ['PENDING', 'REVIEW', 'UNDER_REVIEW', 'PENDING_REVIEW']
      .contains(paymentStatus.toUpperCase());
  bool get isFailed =>
      ['FAILED', 'REJECTED', 'CANCELLED'].contains(paymentStatus.toUpperCase());
}

class CustomerPaymentAttempt {
  final String status;
  final int attemptNumber;
  final String createdAt;
  final String message;

  const CustomerPaymentAttempt({
    required this.status,
    required this.attemptNumber,
    required this.createdAt,
    required this.message,
  });

  factory CustomerPaymentAttempt.fromMap(Map<String, dynamic> map) {
    return CustomerPaymentAttempt(
      status: (map['status'] ?? '').toString(),
      attemptNumber: int.tryParse(
              (map['attemptNumber'] ?? map['attempt_number'] ?? 0)
                  .toString()) ??
          0,
      createdAt: (map['createdAt'] ?? map['created_at'] ?? '').toString(),
      message: (map['message'] ?? map['error_message'] ?? '').toString(),
    );
  }
}

class CustomerPaymentProof {
  final String id;
  final String status;
  final String reference;
  final String proofUrl;
  final String createdAt;

  const CustomerPaymentProof({
    required this.id,
    required this.status,
    required this.reference,
    required this.proofUrl,
    required this.createdAt,
  });

  factory CustomerPaymentProof.fromMap(Map<String, dynamic> map) {
    return CustomerPaymentProof(
      id: (map['id'] ?? map['publicId'] ?? map['public_id'] ?? '').toString(),
      status: (map['status'] ?? '').toString(),
      reference:
          (map['reference'] ?? map['transaction_reference'] ?? '').toString(),
      proofUrl: (map['proofUrl'] ?? map['proof_url'] ?? '').toString(),
      createdAt: (map['createdAt'] ?? map['created_at'] ?? '').toString(),
    );
  }
}

bool _bool(Object? value) {
  if (value == null) return false;
  if (value is bool) return value;
  final text = value.toString().toLowerCase();
  return text == 'true' || text == '1' || text == 'yes';
}
