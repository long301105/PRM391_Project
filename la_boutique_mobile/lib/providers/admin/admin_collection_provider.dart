import '../../core/constants/admin_endpoints.dart';
import '../../models/collection.dart';
import 'admin_base.dart';

class AdminCollectionProvider extends AdminProviderBase {
  PagedList<CollectionModel> _page = const PagedList<CollectionModel>();
  CollectionModel? _selected;

  PagedList<CollectionModel> get pageData => _page;
  List<CollectionModel> get collections => _page.items;
  CollectionModel? get selected => _selected;

  void clearSelected() => _selected = null;

  Future<void> fetchCollections({int page = 0, int size = 20}) async {
    final result = await guard(() => api.get(
          AdminEndpoints.collections,
          queryParams: {'page': page, 'size': size, 'sort': 'createdAt,desc'},
        ));
    if (result != null) {
      _page = PagedList.from(result, CollectionModel.fromJson);
      notifyListeners();
    }
  }

  Future<CollectionModel?> fetchCollection(String id) async {
    final result = await guard(() => api.get(AdminEndpoints.collection(id)));
    if (result is Map<String, dynamic>) {
      _selected = CollectionModel.fromJson(result);
      notifyListeners();
      return _selected;
    }
    return null;
  }

  Future<String?> createCollection({
    required String collectionName,
    String? slug,
    String? coverImageUrl,
    required List<String> productIds,
  }) async {
    final result = await guard(() => api.post(AdminEndpoints.collections, body: {
          'collectionName': collectionName.trim(),
          if (slug != null && slug.trim().isNotEmpty) 'slug': slug.trim(),
          if (coverImageUrl != null && coverImageUrl.trim().isNotEmpty)
            'coverImageUrl': coverImageUrl.trim(),
          'productIds': productIds,
        }));

    if (result is Map<String, dynamic>) {
      _selected = CollectionModel.fromJson(result);
      await fetchCollections();
      return _selected!.id;
    }
    return null;
  }

  Future<bool> updateCollection(
    String id, {
    required int expectedVersion,
    String? collectionName,
    String? slug,
    String? coverImageUrl,
    bool? clearCoverImage,
  }) async {
    final result = await guard(() => api.patch(AdminEndpoints.collection(id), body: {
          'expectedVersion': expectedVersion,
          if (collectionName != null && collectionName.trim().isNotEmpty)
            'collectionName': collectionName.trim(),
          if (slug != null && slug.trim().isNotEmpty) 'slug': slug.trim(),
          if (coverImageUrl != null && coverImageUrl.trim().isNotEmpty)
            'coverImageUrl': coverImageUrl.trim(),
          if (clearCoverImage == true) 'clearCoverImage': true,
        }));
    return await _afterWrite(id, result);
  }

  Future<bool> replaceProducts(
    String id, {
    required int expectedVersion,
    required List<String> productIds,
  }) async {
    final result = await guard(() => api.put(AdminEndpoints.collectionProducts(id), body: {
          'expectedVersion': expectedVersion,
          'productIds': productIds,
        }));
    return await _afterWrite(id, result);
  }

  Future<bool> uploadCover(
    String id,
    String filePath, {
    required int expectedVersion,
    List<int>? fileBytes,
    String? fileName,
  }) async {
    final result = await guard(() => api.sendFile(
          'PUT',
          AdminEndpoints.collectionCover(id),
          filePath: filePath,
          fileBytes: fileBytes,
          fileName: fileName,
          metadata: {'expectedVersion': expectedVersion},
        ));
    return await _afterWrite(id, result);
  }

  Future<bool> publish(String id, {required int expectedVersion}) async {
    final result = await guard(() => api.patch(
          AdminEndpoints.collectionPublish(id),
          body: {'expectedVersion': expectedVersion},
        ));
    return await _afterWrite(id, result);
  }

  Future<bool> hide(String id, {required int expectedVersion}) async {
    final result = await guard(() => api.patch(
          AdminEndpoints.collectionHide(id),
          body: {'expectedVersion': expectedVersion},
        ));
    return await _afterWrite(id, result);
  }

  Future<bool> deleteCollection(String id, {required int expectedVersion}) async {
    final result = await guard(() => api.delete(
          AdminEndpoints.collection(id),
          queryParams: {'expectedVersion': expectedVersion},
        ));
    if (result == null && hasError) return false;
    _selected = null;
    await fetchCollections(page: _page.page);
    return true;
  }

  Future<bool> _afterWrite(String id, dynamic result) async {
    if (result is Map<String, dynamic>) {
      _selected = CollectionModel.fromJson(result);
      await fetchCollections(page: _page.page);
      return true;
    }
    return false;
  }
}
