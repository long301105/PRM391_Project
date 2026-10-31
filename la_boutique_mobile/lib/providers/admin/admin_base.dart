import 'package:flutter/foundation.dart';
import '../../core/network/api_exception.dart';
import '../../services/api_service.dart';

abstract class AdminProviderBase extends ChangeNotifier {
  final ApiService api = ApiService();

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  @protected
  Future<T?> guard<T>(Future<T> Function() action, {String? fallbackMessage}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      return await action();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return null;
    } catch (e, stackTrace) {
      debugPrint('[$runtimeType] $e');
      debugPrintStack(stackTrace: stackTrace);
      _errorMessage = fallbackMessage ?? 'Thao tác không thành công. Vui lòng thử lại.';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

class PagedList<T> {
  final List<T> items;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool first;
  final bool last;

  const PagedList({
    this.items = const [],
    this.page = 0,
    this.size = 20,
    this.totalElements = 0,
    this.totalPages = 0,
    this.first = true,
    this.last = true,
  });

  bool get isEmpty => items.isEmpty;

  static PagedList<T> from<T>(dynamic result, T Function(Map<String, dynamic>) parse) {
    if (result is! Map<String, dynamic> || result['content'] is! List) {
      return PagedList<T>();
    }
    return PagedList<T>(
      items: (result['content'] as List).whereType<Map<String, dynamic>>().map(parse).toList(),
      page: (result['page'] as num?)?.toInt() ?? 0,
      size: (result['size'] as num?)?.toInt() ?? 20,
      totalElements: (result['totalElements'] as num?)?.toInt() ?? 0,
      totalPages: (result['totalPages'] as num?)?.toInt() ?? 0,
      first: result['first'] as bool? ?? true,
      last: result['last'] as bool? ?? true,
    );
  }
}
