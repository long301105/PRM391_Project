import 'package:flutter/foundation.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_exception.dart';
import '../models/collection.dart';
import '../services/api_service.dart';

class CollectionProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<CollectionModel> _collections = const [];
  bool _isLoading = false;
  String? _errorMessage;

  final Map<String, CollectionModel> _details = {};

  List<CollectionModel> get collections => _collections;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  CollectionModel? cached(String slug) => _details[slug];

  Future<void> fetchCollections() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _api.get(
        ApiConstants.collections,
        queryParams: {'size': 50, 'sort': 'createdAt,desc'},
        requiresAuth: false,
      );

      if (result is Map<String, dynamic> && result['content'] is List) {
        _collections = (result['content'] as List)
            .whereType<Map<String, dynamic>>()
            .map(CollectionModel.fromJson)
            .toList();
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      debugPrint('[CollectionProvider] fetchCollections error: $e');
      _errorMessage = 'Không tải được danh sách bộ sưu tập.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<CollectionModel?> fetchCollectionBySlug(String slug, {int page = 0, int size = 20}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _api.get(
        ApiConstants.collectionBySlug(slug),
        queryParams: {'page': page, 'size': size},
        requiresAuth: false,
      );

      if (result is Map<String, dynamic>) {
        final detail = CollectionModel.fromJson(result);
        _details[slug] = detail;
        return detail;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      debugPrint('[CollectionProvider] fetchCollectionBySlug error: $e');
      _errorMessage = 'Không tải được bộ sưu tập này.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return _details[slug];
  }
}
