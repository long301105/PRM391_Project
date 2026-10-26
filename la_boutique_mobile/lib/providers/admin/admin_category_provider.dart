import '../../core/constants/admin_endpoints.dart';
import '../../models/admin_models.dart';
import 'admin_base.dart';

class AdminCategoryProvider extends AdminProviderBase {
  PagedList<AdminCategory> _page = const PagedList<AdminCategory>();

  PagedList<AdminCategory> get pageData => _page;
  List<AdminCategory> get categories => _page.items;

  List<AdminCategory> get selectable =>
      _page.items.where((c) => c.status.toUpperCase() != RecordStatusX.deleted).toList();

  Future<void> fetchCategories({int page = 0, int size = 50}) async {
    final result = await guard(() => api.get(
          AdminEndpoints.categories,
          queryParams: {'page': page, 'size': size, 'sort': 'createdAt,desc'},
        ));
    if (result != null) {
      _page = PagedList.from(result, AdminCategory.fromJson);
      notifyListeners();
    }
  }

  Future<bool> createCategory({required String categoryName, String? slug}) async {
    final result = await guard(() => api.post(AdminEndpoints.categories, body: {
          'categoryName': categoryName.trim(),
          if (slug != null && slug.trim().isNotEmpty) 'slug': slug.trim(),
        }));
    if (result == null) return false;
    await fetchCategories();
    return true;
  }

  Future<bool> updateCategory(
    String id, {
    String? categoryName,
    String? slug,
    String? status,
  }) async {
    final result = await guard(() => api.patch(AdminEndpoints.category(id), body: {
          if (categoryName != null && categoryName.trim().isNotEmpty)
            'categoryName': categoryName.trim(),
          if (slug != null) 'slug': slug.trim(),
          if (status != null) 'status': status,
        }));
    if (result == null) return false;
    await fetchCategories(page: _page.page);
    return true;
  }

  Future<bool> deleteCategory(String id) async {
    final result = await guard(() => api.delete(AdminEndpoints.category(id)));
    if (result == null && hasError) return false;
    await fetchCategories(page: _page.page);
    return true;
  }
}
