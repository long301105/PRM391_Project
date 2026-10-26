import '../../core/constants/admin_endpoints.dart';
import '../../models/order.dart';
import 'admin_base.dart';

class AdminOrderProvider extends AdminProviderBase {
  PagedList<OrderModel> _page = const PagedList<OrderModel>();
  String? _statusFilter;
  OrderModel? _selected;

  PagedList<OrderModel> get pageData => _page;
  List<OrderModel> get orders => _page.items;
  String? get statusFilter => _statusFilter;
  OrderModel? get selected => _selected;

  static const List<String> statuses = [
    'PENDING',
    'CONFIRMED',
    'SHIPPING',
    'COMPLETED',
    'CANCELLED',
  ];

  static List<String> nextStatuses(String current) {
    switch (current.toUpperCase()) {
      case 'PENDING':
        return const ['CONFIRMED', 'CANCELLED'];
      case 'CONFIRMED':
        return const ['SHIPPING', 'CANCELLED'];
      case 'SHIPPING':
        return const ['COMPLETED'];
      default:
        return const [];
    }
  }

  static String statusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Chờ xác nhận';
      case 'CONFIRMED':
        return 'Đã xác nhận';
      case 'SHIPPING':
        return 'Đang giao';
      case 'COMPLETED':
        return 'Hoàn thành';
      case 'CANCELLED':
        return 'Đã huỷ';
      default:
        return status;
    }
  }

  void setStatusFilter(String? status) {
    _statusFilter = status;
    notifyListeners();
    fetchOrders();
  }

  Future<void> fetchOrders({int page = 0, int size = 20}) async {
    final result = await guard(() => api.get(
          AdminEndpoints.orders,
          queryParams: {
            'page': page,
            'size': size,
            'sort': 'createdAt,desc',
            if (_statusFilter != null) 'status': _statusFilter,
          },
        ));
    if (result != null) {
      _page = PagedList.from(result, OrderModel.fromJson);
      notifyListeners();
    }
  }

  Future<OrderModel?> fetchOrderById(String id) async {
    final result = await guard(() => api.get(AdminEndpoints.order(id)));
    if (result is Map<String, dynamic>) {
      _selected = OrderModel.fromJson(result);
      notifyListeners();
      return _selected;
    }
    return null;
  }

  Future<OrderModel?> fetchOrderByNumber(String orderNumber) async {
    final result = await guard(() => api.get(
          AdminEndpoints.orderByNumber(orderNumber.trim().toUpperCase()),
        ));
    if (result is Map<String, dynamic>) {
      _selected = OrderModel.fromJson(result);
      notifyListeners();
      return _selected;
    }
    return null;
  }

  Future<bool> updateStatus(String orderId, String status) async {
    final result = await guard(() => api.patch(
          AdminEndpoints.orderStatus(orderId),
          body: {'status': status},
        ));
    if (result is Map<String, dynamic>) {
      _selected = OrderModel.fromJson(result);
      await fetchOrders(page: _page.page);
      return true;
    }
    return false;
  }
}
