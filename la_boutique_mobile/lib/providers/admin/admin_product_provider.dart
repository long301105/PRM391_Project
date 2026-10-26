import '../../core/constants/admin_endpoints.dart';
import '../../models/admin_models.dart';
import 'admin_base.dart';

class AdminProductProvider extends AdminProviderBase {
  PagedList<AdminProduct> _page = const PagedList<AdminProduct>();
  AdminProduct? _selected;
  List<AdminVariant> _variants = const [];
  String _query = '';

  PagedList<AdminProduct> get pageData => _page;
  AdminProduct? get selected => _selected;
  List<AdminVariant> get variants => _variants;
  String get query => _query;

  List<AdminProduct> get products {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _page.items;
    return _page.items
        .where((p) => p.name.toLowerCase().contains(q) || p.sku.toLowerCase().contains(q))
        .toList();
  }

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  Future<void> fetchProducts({int page = 0, int size = 20}) async {
    final result = await guard(() => api.get(
          AdminEndpoints.products,
          queryParams: {'page': page, 'size': size, 'sort': 'createdAt,desc'},
        ));
    if (result != null) {
      _page = PagedList.from(result, AdminProduct.fromJson);
      notifyListeners();
    }
  }

  Future<AdminProduct?> fetchProduct(String id) async {
    final result = await guard(() => api.get(AdminEndpoints.product(id)));
    if (result is Map<String, dynamic>) {
      _selected = AdminProduct.fromJson(result);
      _variants = _selected!.variants;
      notifyListeners();
      return _selected;
    }
    return null;
  }

  void clearSelected() {
    _selected = null;
    _variants = const [];
  }

  Map<String, dynamic> _productBody({
    String? name,
    String? slug,
    String? sku,
    double? price,
    double? originalPrice,
    String? description,
    String? material,
    String? careInstructions,
    String? tag,
    String? thumbnail,
    bool? isSummer,
    bool? isFeatured,
    String? status,
    String? categoryId,
    required bool isCreate,
  }) {
    String? clean(String? v) => (v == null || v.trim().isEmpty) ? null : v.trim();
    return {
      if (isCreate || name != null) 'name': clean(name),
      'slug': clean(slug),
      if (isCreate || sku != null) 'sku': clean(sku),
      if (isCreate || price != null) 'price': price,
      'originalPrice': originalPrice,
      'description': clean(description),
      'material': clean(material),
      'careInstructions': clean(careInstructions),
      'tag': clean(tag),
      'thumbnail': clean(thumbnail),
      if (isCreate || isSummer != null) 'isSummer': isSummer ?? false,
      if (isCreate || isFeatured != null) 'isFeatured': isFeatured ?? false,
      if (status != null) 'status': status,
      if (isCreate || categoryId != null) 'categoryId': categoryId,
    };
  }

  Future<String?> createProduct({
    required String name,
    String? slug,
    required String sku,
    required double price,
    double? originalPrice,
    String? description,
    String? material,
    String? careInstructions,
    String? tag,
    String? thumbnail,
    bool isSummer = false,
    bool isFeatured = false,
    String? status,
    required String categoryId,
  }) async {
    final result = await guard(() => api.post(
          AdminEndpoints.products,
          body: _productBody(
            name: name,
            slug: slug,
            sku: sku,
            price: price,
            originalPrice: originalPrice,
            description: description,
            material: material,
            careInstructions: careInstructions,
            tag: tag,
            thumbnail: thumbnail,
            isSummer: isSummer,
            isFeatured: isFeatured,
            status: status,
            categoryId: categoryId,
            isCreate: true,
          ),
        ));

    if (result is Map<String, dynamic>) {
      _selected = AdminProduct.fromJson(result);
      await fetchProducts();
      return _selected!.id;
    }
    return null;
  }

  Future<bool> updateProduct(
    String id, {
    String? name,
    String? slug,
    String? sku,
    double? price,
    double? originalPrice,
    String? description,
    String? material,
    String? careInstructions,
    String? tag,
    String? thumbnail,
    bool? isSummer,
    bool? isFeatured,
    String? status,
    String? categoryId,
  }) async {
    final result = await guard(() => api.patch(
          AdminEndpoints.product(id),
          body: _productBody(
            name: name,
            slug: slug,
            sku: sku,
            price: price,
            originalPrice: originalPrice,
            description: description,
            material: material,
            careInstructions: careInstructions,
            tag: tag,
            thumbnail: thumbnail,
            isSummer: isSummer,
            isFeatured: isFeatured,
            status: status,
            categoryId: categoryId,
            isCreate: false,
          ),
        ));

    if (result is Map<String, dynamic>) {
      _selected = AdminProduct.fromJson(result);
      _variants = _selected!.variants;
      await fetchProducts(page: _page.page);
      return true;
    }
    return false;
  }

  Future<bool> deleteProduct(String id) async {
    final result = await guard(() => api.delete(AdminEndpoints.product(id)));
    if (result == null && hasError) return false;
    await fetchProducts(page: _page.page);
    return true;
  }

  Future<void> fetchVariants(String productId) async {
    final result = await guard(() => api.get(AdminEndpoints.productVariants(productId)));
    if (result is List) {
      _variants = result.whereType<Map<String, dynamic>>().map(AdminVariant.fromJson).toList();
      notifyListeners();
    }
  }

  Future<bool> addVariant(String productId, {required String size, required int stock}) async {
    final result = await guard(() => api.post(
          AdminEndpoints.productVariants(productId),
          body: {'size': size, 'stockQuantity': stock},
        ));
    if (result == null) return false;
    await fetchProduct(productId);
    return true;
  }

  Future<bool> updateVariant(
    String productId,
    String variantId, {
    required int stock,
    required int expectedVersion,
  }) async {
    final result = await guard(() => api.patch(
          AdminEndpoints.productVariant(productId, variantId),
          body: {'stockQuantity': stock, 'expectedVersion': expectedVersion},
        ));
    if (result == null) return false;
    await fetchProduct(productId);
    return true;
  }

  Future<bool> removeVariant(String productId, String variantId) async {
    final result = await guard(() => api.delete(AdminEndpoints.productVariant(productId, variantId)));
    if (result == null && hasError) return false;
    await fetchProduct(productId);
    return true;
  }

  Future<bool> addImage(String productId, String filePath) async {
    final result = await guard(() => api.sendFile(
          'POST',
          AdminEndpoints.productImages(productId),
          filePath: filePath,
        ));
    if (result == null) return false;
    await fetchProduct(productId);
    return true;
  }

  Future<bool> replaceImage(String productId, String imageId, String filePath) async {
    final result = await guard(() => api.sendFile(
          'PUT',
          AdminEndpoints.productImage(productId, imageId),
          filePath: filePath,
        ));
    if (result == null) return false;
    await fetchProduct(productId);
    return true;
  }

  Future<bool> removeImage(String productId, String imageId) async {
    final result = await guard(() => api.delete(AdminEndpoints.productImage(productId, imageId)));
    if (result == null && hasError) return false;
    await fetchProduct(productId);
    return true;
  }

  Future<bool> uploadThumbnail(String productId, String filePath) async {
    final result = await guard(() => api.sendFile(
          'PUT',
          AdminEndpoints.productThumbnailUpload(productId),
          filePath: filePath,
        ));
    if (result == null) return false;
    await fetchProduct(productId);
    return true;
  }

  Future<bool> selectThumbnail(String productId, String imageId) async {
    final result = await guard(() => api.patch(
          AdminEndpoints.productThumbnailSelect(productId),
          body: {'imageId': imageId},
        ));
    if (result == null) return false;
    await fetchProduct(productId);
    return true;
  }
}
