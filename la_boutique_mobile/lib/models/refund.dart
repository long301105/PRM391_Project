/// Một dòng hoàn tiền phía admin — khớp RefundAdminResponse của BE:
/// { id, orderNumber, customerName, amount, reason, status, createdAt }.
class RefundModel {
  final String id;
  final String orderNumber;
  final String customerName;
  final double amount;
  final String reason;
  final String status; // PENDING | REFUNDED | REJECTED
  final DateTime? createdAt;

  const RefundModel({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.amount,
    required this.reason,
    required this.status,
    required this.createdAt,
  });

  /// PENDING = "cần hoàn" (chưa chuyển tiền), KHÔNG phải "đã hoàn".
  String get statusText {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Cần hoàn';
      case 'REFUNDED':
        return 'Đã hoàn';
      case 'REJECTED':
        return 'Từ chối';
      default:
        return status;
    }
  }

  factory RefundModel.fromJson(Map<String, dynamic> json) {
    final rawDate = (json['createdAt'] ?? '').toString();
    return RefundModel(
      id: json['id']?.toString() ?? '',
      orderNumber: (json['orderNumber'] ?? '').toString(),
      customerName: (json['customerName'] ?? '').toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      reason: (json['reason'] ?? '').toString(),
      status: (json['status'] ?? 'PENDING').toString(),
      createdAt: rawDate.isEmpty ? null : DateTime.tryParse(rawDate)?.toLocal(),
    );
  }
}
