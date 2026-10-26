import '../../core/constants/admin_endpoints.dart';
import '../../models/admin_models.dart';
import 'admin_base.dart';

class AdminAccountProvider extends AdminProviderBase {
  PagedList<AdminAccount> _page = const PagedList<AdminAccount>();
  String _query = '';
  String? _statusFilter;

  PagedList<AdminAccount> get pageData => _page;
  String get query => _query;
  String? get statusFilter => _statusFilter;

  List<AdminAccount> get accounts {
    final q = _query.trim().toLowerCase();
    return _page.items.where((a) {
      final matchQuery = q.isEmpty ||
          a.email.toLowerCase().contains(q) ||
          (a.roleName ?? '').toLowerCase().contains(q);
      final matchStatus = _statusFilter == null || a.status.toUpperCase() == _statusFilter;
      return matchQuery && matchStatus;
    }).toList();
  }

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void setStatusFilter(String? status) {
    _statusFilter = status;
    notifyListeners();
  }

  Future<void> fetchAccounts({int page = 0, int size = 20}) async {
    final result = await guard(() => api.get(
          AdminEndpoints.accounts,
          queryParams: {'page': page, 'size': size, 'sort': 'createdAt,desc'},
        ));
    if (result != null) {
      _page = PagedList.from(result, AdminAccount.fromJson);
      notifyListeners();
    }
  }

  Future<AdminAccount?> fetchAccount(String id) async {
    final result = await guard(() => api.get(AdminEndpoints.account(id)));
    if (result is Map<String, dynamic>) return AdminAccount.fromJson(result);
    return null;
  }

  Future<bool> createAccount({
    required String email,
    required String password,
    required String roleId,
  }) async {
    final result = await guard(() => api.post(AdminEndpoints.accounts, body: {
          'email': email.trim(),
          'password': password,
          'roleId': roleId,
        }));
    if (result == null) return false;
    await fetchAccounts(page: _page.page);
    return true;
  }

  Future<bool> updateAccount(String id, {String? email, String? roleId}) async {
    final result = await guard(() => api.patch(AdminEndpoints.account(id), body: {
          if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
          if (roleId != null && roleId.isNotEmpty) 'roleId': roleId,
        }));
    if (result == null) return false;
    await fetchAccounts(page: _page.page);
    return true;
  }

  Future<bool> updateStatus(String id, String status, {DateTime? lockedUntil}) async {
    final result = await guard(() => api.patch(AdminEndpoints.accountStatus(id), body: {
          'status': status,
          if (lockedUntil != null) 'lockedUntil': lockedUntil.toUtc().toIso8601String(),
        }));
    if (result == null) return false;
    await fetchAccounts(page: _page.page);
    return true;
  }

  Future<bool> deleteAccount(String id) async {
    final result = await guard(() => api.delete(AdminEndpoints.account(id)));
    if (result == null && hasError) return false;
    await fetchAccounts(page: _page.page);
    return true;
  }
}
