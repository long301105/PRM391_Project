import '../../core/constants/admin_endpoints.dart';
import '../../models/store.dart';
import 'admin_base.dart';

/// Quản trị cửa hàng/chi nhánh: CRUD trên `/stores/admin`.
///
/// Khác phía khách (`GET /stores` chỉ trả chi nhánh ACTIVE), danh sách admin trả cả bản ghi
/// đang ẩn (HIDDEN), chỉ loại bản đã xoá (DELETED). Ảnh là URL ngoài (không upload Cloudinary).
class AdminStoreProvider extends AdminProviderBase {
  PagedList<StoreModel> _page = const PagedList<StoreModel>();

  PagedList<StoreModel> get pageData => _page;
  List<StoreModel> get stores => _page.items;

  Future<void> fetchStores({int page = 0, int size = 20}) async {
    final result = await guard(() => api.get(
          AdminEndpoints.stores,
          queryParams: {'page': page, 'size': size, 'sort': 'storeName,asc'},
        ));
    if (result != null) {
      _page = PagedList.from(result, StoreModel.fromJson);
      notifyListeners();
    }
  }

  Future<bool> createStore(Map<String, dynamic> body) async {
    final result = await guard(() => api.post(AdminEndpoints.stores, body: body));
    if (result == null) return false;
    await fetchStores(page: _page.page);
    return true;
  }

  Future<bool> updateStore(String id, Map<String, dynamic> body) async {
    final result = await guard(() => api.patch(AdminEndpoints.store(id), body: body));
    if (result == null) return false;
    await fetchStores(page: _page.page);
    return true;
  }

  Future<bool> deleteStore(String id) async {
    final result = await guard(() => api.delete(AdminEndpoints.store(id)));
    if (result == null) return false;
    await fetchStores(page: _page.page);
    return true;
  }
}
