import 'package:flutter/foundation.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_exception.dart';
import '../models/order.dart';
import '../models/cart_item.dart';
import '../services/api_service.dart';

class OrderProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  final List<OrderModel> _orders = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<OrderModel> get orders => [..._orders];
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearOrders() {
    _orders.clear();
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> fetchMyOrders() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _api.get(
        ApiConstants.myOrders,
        queryParams: {'size': 50, 'sort': 'createdAt,desc'},
        requiresAuth: true,
      );

      if (result is Map<String, dynamic> && result['content'] is List) {
        final list = (result['content'] as List)
            .whereType<Map<String, dynamic>>()
            .map(OrderModel.fromJson)
            .toList();

        _orders
          ..clear()
          ..addAll(list);
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      debugPrint('[OrderProvider] fetchMyOrders error: $e');
      _errorMessage = 'Không tải được danh sách đơn hàng.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<OrderModel?> fetchOrderDetail(String orderNumber) async {
    _errorMessage = null;
    try {
      final result = await _api.get(
        ApiConstants.myOrderByNumber(orderNumber.trim().toUpperCase()),
        requiresAuth: true,
      );

      if (result is Map<String, dynamic>) {
        final detailedOrder = OrderModel.fromJson(result);
        final index = _orders.indexWhere((o) => o.orderNumber == detailedOrder.orderNumber);
        if (index != -1) {
          _orders[index] = detailedOrder;
        } else {
          _orders.insert(0, detailedOrder);
        }
        notifyListeners();
        return detailedOrder;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
    } catch (e) {
      debugPrint('[OrderProvider] fetchOrderDetail error: $e');
      _errorMessage = 'Không tải được chi tiết đơn hàng.';
      notifyListeners();
    }

    return getOrderByNumber(orderNumber);
  }

  Future<String> createOrder({
    required String customerName,
    required String phone,
    String? email,
    required String address,
    String? note,
    required List<CartItem> items,
    required double subtotal,
    required double discount,
    required double shippingFee,
    required double total,
    required String paymentMethod,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final bePaymentMethod =
        (paymentMethod == 'BANKING' || paymentMethod == 'BANK_TRANSFER') ? 'BANK_TRANSFER' : 'COD';

    final orderBody = {
      'receiverName': customerName.trim(),
      'phone': phone.trim(),
      'email': (email != null && email.trim().isNotEmpty) ? email.trim() : null,
      'address': address.trim(),
      'note': (note != null && note.trim().isNotEmpty) ? note.trim() : null,
      'paymentMethod': bePaymentMethod,
      'items': items
          .map((item) => {
                'productId': item.product.id,
                'size': item.size.toUpperCase(),
                'quantity': item.quantity,
              })
          .toList(),
    };

    try {
      final result = await _api.post(ApiConstants.orders, body: orderBody, requiresAuth: true);

      if (result is! Map<String, dynamic>) {
        throw ApiException(statusCode: 0, message: 'Máy chủ trả dữ liệu đơn không đúng định dạng.');
      }

      final createdOrder = OrderModel.fromJson(result);
      _orders.insert(0, createdOrder);
      return createdOrder.orderNumber;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      rethrow;
    } catch (e) {
      debugPrint('[OrderProvider] createOrder error: $e');
      _errorMessage = 'Đặt hàng không thành công. Vui lòng thử lại.';
      throw ApiException(statusCode: 0, message: _errorMessage!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> cancelMyOrder(String orderNumber, {String? reason}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _api.post(
        ApiConstants.cancelMyOrder(orderNumber.trim().toUpperCase()),
        body: (reason != null && reason.trim().isNotEmpty) ? {'reason': reason.trim()} : null,
        requiresAuth: true,
      );

      if (result is Map<String, dynamic>) {
        final cancelled = OrderModel.fromJson(result);
        final index = _orders.indexWhere((o) => o.orderNumber == cancelled.orderNumber);
        if (index != -1) {
          _orders[index] = cancelled;
        }
      }
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      debugPrint('[OrderProvider] cancelMyOrder error: $e');
      _errorMessage = 'Huỷ đơn không thành công. Vui lòng thử lại.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<OrderModel> searchOrdersByPhone(String phone) {
    final clean = phone.trim().replaceAll(' ', '');
    if (clean.isEmpty) return const [];
    return _orders.where((o) => o.phone.replaceAll(' ', '').contains(clean)).toList();
  }

  OrderModel? getOrderByNumber(String orderIdOrNumber) {
    final clean = orderIdOrNumber.trim().toUpperCase();
    if (clean.isEmpty) return null;
    for (final o in _orders) {
      if (o.id.toUpperCase() == clean || o.orderNumber.toUpperCase() == clean) return o;
    }
    return null;
  }

  OrderModel? getOrderById(String orderId) => getOrderByNumber(orderId);
}
