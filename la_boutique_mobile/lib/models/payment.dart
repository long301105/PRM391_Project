/// Response từ POST /payments/me/{orderNumber}/vnpay
class VnpayPaymentUrlResponse {
  final String paymentUrl;
  final String txnRef;
  final double amount;
  final String status; // PENDING
  final DateTime? expiresAt;

  VnpayPaymentUrlResponse({
    required this.paymentUrl,
    required this.txnRef,
    required this.amount,
    required this.status,
    this.expiresAt,
  });

  factory VnpayPaymentUrlResponse.fromJson(Map<String, dynamic> json) {
    return VnpayPaymentUrlResponse(
      paymentUrl: (json['paymentUrl'] ?? '') as String,
      txnRef: (json['txnRef'] ?? '') as String,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: (json['status'] ?? 'PENDING') as String,
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paymentUrl': paymentUrl,
      'txnRef': txnRef,
      'amount': amount,
      'status': status,
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }
}

/// Response từ GET /payments/me/{orderNumber}
class PaymentStatusResponse {
  final String id;
  final String orderNumber;
  final String? txnRef;
  final int attemptNo;
  final String status; // PENDING, PAID, FAILED, EXPIRED, CANCELLED
  final double amount;
  final DateTime? expiresAt;
  final DateTime? paidAt;
  final String? bankCode;
  final DateTime createdAt;
  final DateTime updatedAt;

  PaymentStatusResponse({
    required this.id,
    required this.orderNumber,
    this.txnRef,
    required this.attemptNo,
    required this.status,
    required this.amount,
    this.expiresAt,
    this.paidAt,
    this.bankCode,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPaid => status.toUpperCase() == 'PAID';
  bool get isFailed => status.toUpperCase() == 'FAILED';
  bool get isExpired => status.toUpperCase() == 'EXPIRED';
  bool get isCancelled => status.toUpperCase() == 'CANCELLED';
  bool get isPending => status.toUpperCase() == 'PENDING';
  bool get isTerminal => isPaid || isExpired || isCancelled;

  /// Còn có thể thanh toán/thử lại không? (PENDING hoặc FAILED, chưa quá hạn)
  bool get canRetry => (isPending || isFailed) && !_isExpiredByTime;

  bool get _isExpiredByTime =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  String get statusText {
    switch (status.toUpperCase()) {
      case 'PAID':
        return 'Đã thanh toán';
      case 'FAILED':
        return 'Thất bại — thử lại';
      case 'EXPIRED':
        return 'Hết hạn';
      case 'CANCELLED':
        return 'Đã huỷ';
      case 'PENDING':
      default:
        return 'Chờ thanh toán';
    }
  }

  factory PaymentStatusResponse.fromJson(Map<String, dynamic> json) {
    return PaymentStatusResponse(
      id: json['id']?.toString() ?? '',
      orderNumber: (json['orderNumber'] ?? '') as String,
      txnRef: json['txnRef'] as String?,
      attemptNo: (json['attemptNo'] as num?)?.toInt() ?? 1,
      status: (json['status'] ?? 'PENDING') as String,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'] as String)
          : null,
      paidAt: json['paidAt'] != null
          ? DateTime.tryParse(json['paidAt'] as String)
          : null,
      bankCode: json['bankCode'] as String?,
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now())
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? (DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'txnRef': txnRef,
      'attemptNo': attemptNo,
      'status': status,
      'amount': amount,
      'expiresAt': expiresAt?.toIso8601String(),
      'paidAt': paidAt?.toIso8601String(),
      'bankCode': bankCode,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
