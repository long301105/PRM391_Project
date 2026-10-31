import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_exception.dart';
import '../models/payment.dart';
import '../services/api_service.dart';

class PaymentProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  PaymentStatusResponse? _paymentStatus;
  VnpayPaymentUrlResponse? _vnpayResponse;
  bool _isLoading = false;
  bool _isPolling = false;
  String? _errorMessage;

  PaymentStatusResponse? get paymentStatus => _paymentStatus;
  VnpayPaymentUrlResponse? get vnpayResponse => _vnpayResponse;
  bool get isLoading => _isLoading;
  bool get isPolling => _isPolling;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearState() {
    _paymentStatus = null;
    _vnpayResponse = null;
    _isLoading = false;
    _isPolling = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Khởi tạo phiên thanh toán VNPay: POST /payments/me/{orderNumber}/vnpay
  /// Trả về VnpayPaymentUrlResponse chứa paymentUrl để mở WebView
  Future<VnpayPaymentUrlResponse?> createVnpayPayment(String orderNumber) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.post(
        ApiConstants.paymentVnpay(orderNumber.trim().toUpperCase()),
        requiresAuth: true,
      );

      if (res is Map<String, dynamic>) {
        _vnpayResponse = VnpayPaymentUrlResponse.fromJson(res);
        return _vnpayResponse;
      }
      throw ApiException(
        statusCode: 0,
        message: 'Dữ liệu phản hồi thanh toán không đúng định dạng.',
      );
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return null;
    } catch (e) {
      debugPrint('[PaymentProvider] createVnpayPayment error: $e');
      _errorMessage = 'Không thể tạo liên kết thanh toán VNPay. Vui lòng thử lại.';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Lấy trạng thái thanh toán hiện tại: GET /payments/me/{orderNumber}
  Future<PaymentStatusResponse?> fetchPaymentStatus(String orderNumber) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.get(
        ApiConstants.paymentStatus(orderNumber.trim().toUpperCase()),
        requiresAuth: true,
      );

      if (res is Map<String, dynamic>) {
        _paymentStatus = PaymentStatusResponse.fromJson(res);
        return _paymentStatus;
      }
      return null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return null;
    } catch (e) {
      debugPrint('[PaymentProvider] fetchPaymentStatus error: $e');
      _errorMessage = 'Không thể kiểm tra trạng thái thanh toán.';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Poll trạng thái thanh toán sau khi rời WebView:
  /// Gọi mỗi 2s, tối đa 15 lần (30s) hoặc dừng ngay khi status không còn PENDING (PAID, FAILED, EXPIRED, CANCELLED).
  Future<PaymentStatusResponse?> pollPaymentStatus(
    String orderNumber, {
    int maxAttempts = 15,
    Duration interval = const Duration(seconds: 2),
  }) async {
    _isPolling = true;
    _errorMessage = null;
    notifyListeners();

    try {
      for (int i = 0; i < maxAttempts; i++) {
        final res = await _api.get(
          ApiConstants.paymentStatus(orderNumber.trim().toUpperCase()),
          requiresAuth: true,
        );

        if (res is Map<String, dynamic>) {
          final statusResp = PaymentStatusResponse.fromJson(res);
          _paymentStatus = statusResp;
          notifyListeners();

          // Nếu trạng thái đã chốt (PAID / FAILED / EXPIRED / CANCELLED), dừng polling
          if (!statusResp.isPending) {
            return statusResp;
          }
        }

        // Chờ lượt tiếp theo
        if (i < maxAttempts - 1) {
          await Future.delayed(interval);
        }
      }

      return _paymentStatus;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return _paymentStatus;
    } catch (e) {
      debugPrint('[PaymentProvider] pollPaymentStatus error: $e');
      _errorMessage = 'Lỗi kết nối khi đồng bộ trạng thái thanh toán.';
      return _paymentStatus;
    } finally {
      _isPolling = false;
      notifyListeners();
    }
  }
}
