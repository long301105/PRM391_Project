import '../../core/constants/admin_endpoints.dart';
import '../../models/refund.dart';
import 'admin_base.dart';

/// Quản trị thanh toán phía admin:
/// - Danh sách hoàn tiền `GET /payments/admin/refunds` (lọc theo status nếu có).
/// - Xác nhận đã thu tiền COD `POST /payments/cod/{orderNumber}/confirm` (idempotent).
class AdminPaymentProvider extends AdminProviderBase {
  PagedList<RefundModel> _refunds = const PagedList<RefundModel>();
  String? _statusFilter; // null = tất cả; hoặc PENDING/REFUNDED/REJECTED

  PagedList<RefundModel> get refundsPage => _refunds;
  List<RefundModel> get refunds => _refunds.items;
  String? get statusFilter => _statusFilter;

  void setStatusFilter(String? status) {
    _statusFilter = status;
    notifyListeners();
    fetchRefunds();
  }

  Future<void> fetchRefunds({int page = 0, int size = 20}) async {
    final result = await guard(() => api.get(
          AdminEndpoints.paymentsRefunds,
          queryParams: {
            'page': page,
            'size': size,
            if (_statusFilter != null) 'status': _statusFilter,
          },
        ));
    if (result != null) {
      _refunds = PagedList.from(result, RefundModel.fromJson);
      notifyListeners();
    }
  }

  /// Shop xác nhận đã thu tiền mặt cho một đơn COD. Gọi nhiều lần không sao (BE idempotent).
  Future<bool> confirmCod(String orderNumber) async {
    final result = await guard(() => api.post(
          AdminEndpoints.codConfirm(orderNumber.trim().toUpperCase()),
        ));
    return result != null;
  }
}
