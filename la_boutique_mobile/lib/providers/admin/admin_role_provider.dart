import '../../core/constants/admin_endpoints.dart';
import '../../models/admin_models.dart';
import 'admin_base.dart';

class AdminRoleProvider extends AdminProviderBase {
  PagedList<AdminRole> _page = const PagedList<AdminRole>();

  PagedList<AdminRole> get pageData => _page;
  List<AdminRole> get roles => _page.items;

  Future<void> fetchRoles({int page = 0, int size = 50}) async {
    final result = await guard(() => api.get(
          AdminEndpoints.roles,
          queryParams: {'page': page, 'size': size, 'sort': 'roleName,asc'},
        ));
    if (result != null) {
      _page = PagedList.from(result, AdminRole.fromJson);
      notifyListeners();
    }
  }

  Future<bool> createRole({required String roleName, String? description}) async {
    final result = await guard(() => api.post(AdminEndpoints.roles, body: {
          'roleName': roleName.trim(),
          'description': (description?.trim().isEmpty ?? true) ? null : description!.trim(),
        }));
    if (result == null) return false;
    await fetchRoles();
    return true;
  }

  Future<bool> updateRole(String id, {String? roleName, String? description}) async {
    final result = await guard(() => api.patch(AdminEndpoints.role(id), body: {
          if (roleName != null && roleName.trim().isNotEmpty) 'roleName': roleName.trim(),
          if (description != null) 'description': description.trim(),
        }));
    if (result == null) return false;
    await fetchRoles();
    return true;
  }

  Future<bool> deleteRole(String id) async {
    final result = await guard(() => api.delete(AdminEndpoints.role(id)));
    if (result == null && hasError) return false;
    await fetchRoles();
    return true;
  }
}
