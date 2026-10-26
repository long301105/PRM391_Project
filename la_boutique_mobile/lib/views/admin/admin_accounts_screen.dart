import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/admin_models.dart';
import '../../providers/admin/admin_account_provider.dart';
import '../../providers/admin/admin_role_provider.dart';
import 'admin_widgets.dart';

class AdminAccountsScreen extends StatefulWidget {
  const AdminAccountsScreen({super.key});

  @override
  State<AdminAccountsScreen> createState() => _AdminAccountsScreenState();
}

class _AdminAccountsScreenState extends State<AdminAccountsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminAccountProvider>().fetchAccounts();
      context.read<AdminRoleProvider>().fetchRoles();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openCreateForm() async {
    final provider = context.read<AdminAccountProvider>();
    final roles = context.read<AdminRoleProvider>().roles;

    if (roles.isEmpty) {
      adminToast(context, 'Chưa tải được danh sách role. Thử lại sau.', success: false);
      return;
    }

    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String roleId = roles.first.id;
    final formKey = GlobalKey<FormState>();

    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Tạo tài khoản'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AdminField(
                    controller: emailController,
                    label: 'Email',
                    required: true,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      final v = (value ?? '').trim();
                      if (v.isEmpty) return 'Không được để trống';
                      return v.contains('@') ? null : 'Email không hợp lệ';
                    },
                  ),
                  AdminField(
                    controller: passwordController,
                    label: 'Mật khẩu',
                    obscure: true,
                    required: true,
                    helper: 'Tối thiểu 8 ký tự, phải có chữ hoa, chữ thường và số.',
                    validator: (value) {
                      final v = value ?? '';
                      if (v.length < 8) return 'Tối thiểu 8 ký tự';
                      if (!RegExp(r'(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(v)) {
                        return 'Cần có chữ hoa, chữ thường và số';
                      }
                      return null;
                    },
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: roleId,
                    decoration: const InputDecoration(
                      labelText: 'Role *',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: roles
                        .map((r) => DropdownMenuItem(value: r.id, child: Text(r.roleName)))
                        .toList(),
                    onChanged: (value) => setDialogState(() => roleId = value ?? roleId),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Tài khoản tạo ở đây dùng được ngay, không phải xác minh OTP email như '
                    'luồng khách tự đăng ký.',
                    style: TextStyle(fontSize: 11.5, color: AppColors.mute, height: 1.35),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Thôi'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) Navigator.of(dialogContext).pop(true);
              },
              child: const Text('TẠO'),
            ),
          ],
        ),
      ),
    );

    final email = emailController.text;
    final password = passwordController.text;
    emailController.dispose();
    passwordController.dispose();

    if (submitted != true || !mounted) return;

    await adminRun(
      context,
      provider,
      () => provider.createAccount(email: email, password: password, roleId: roleId),
      successMessage: 'Đã tạo tài khoản.',
    );
  }

  Future<void> _openEditForm(AdminAccount account) async {
    final provider = context.read<AdminAccountProvider>();
    final roles = context.read<AdminRoleProvider>().roles;
    final emailController = TextEditingController(text: account.email);
    String? roleId = account.roleId ?? (roles.isNotEmpty ? roles.first.id : null);
    final formKey = GlobalKey<FormState>();

    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Sửa tài khoản'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AdminField(
                    controller: emailController,
                    label: 'Email',
                    required: true,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  if (roles.isNotEmpty)
                    DropdownButtonFormField<String>(
                      initialValue: roles.any((r) => r.id == roleId) ? roleId : roles.first.id,
                      decoration: const InputDecoration(
                        labelText: 'Role',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: roles
                          .map((r) => DropdownMenuItem(value: r.id, child: Text(r.roleName)))
                          .toList(),
                      onChanged: (value) => setDialogState(() => roleId = value ?? roleId),
                    ),
                  const SizedBox(height: 10),
                  const Text(
                    'Đổi role sẽ đá tài khoản này ra khỏi mọi thiết bị đang đăng nhập — quyền nằm '
                    'trong access token nên phải cấp lại token mới.',
                    style: TextStyle(fontSize: 11.5, color: AppColors.mute, height: 1.35),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tên, số điện thoại và địa chỉ thuộc hồ sơ cá nhân, chỉ chính chủ sửa được.',
                    style: TextStyle(fontSize: 11.5, color: AppColors.mute, height: 1.35),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Thôi'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) Navigator.of(dialogContext).pop(true);
              },
              child: const Text('LƯU'),
            ),
          ],
        ),
      ),
    );

    final email = emailController.text;
    emailController.dispose();

    if (submitted != true || !mounted) return;

    await adminRun(
      context,
      provider,
      () => provider.updateAccount(account.id, email: email, roleId: roleId),
      successMessage: 'Đã cập nhật tài khoản.',
    );
  }

  Future<void> _changeStatus(AdminAccount account) async {
    final provider = context.read<AdminAccountProvider>();
    String status = account.status.toUpperCase();
    DateTime? lockedUntil = account.lockedUntil;

    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Đổi trạng thái'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(account.email, style: const TextStyle(fontSize: 12.5, color: AppColors.mute)),
              const SizedBox(height: 12),
              ...['ACTIVE', 'DISABLED', 'LOCKED'].map(
                (s) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    status == s ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    size: 20,
                    color: status == s ? AppColors.clay500 : AppColors.sand400,
                  ),
                  title: Text(_statusLabel(s), style: const TextStyle(fontSize: 13.5)),
                  subtitle: Text(_statusHint(s),
                      style: const TextStyle(fontSize: 11.5, color: AppColors.mute)),
                  onTap: () => setDialogState(() => status = s),
                ),
              ),
              if (status == 'LOCKED') ...[
                const SizedBox(height: 6),
                OutlinedButton.icon(
                  icon: const Icon(Icons.schedule, size: 16),
                  label: Text(
                    lockedUntil == null
                        ? 'Chọn thời điểm mở khoá'
                        : 'Mở khoá: ${Formatters.formatDate(lockedUntil!)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  onPressed: () async {
                    final now = DateTime.now();
                    final current = lockedUntil;
                    final picked = await showDatePicker(
                      context: dialogContext,
                      initialDate: (current != null && current.isAfter(now))
                          ? current
                          : now.add(const Duration(days: 1)),
                      firstDate: now,
                      lastDate: now.add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setDialogState(() => lockedUntil =
                          DateTime(picked.year, picked.month, picked.day, 23, 59));
                    }
                  },
                ),
                const SizedBox(height: 4),
                const Text(
                  'Phải là mốc trong tương lai. Để trống thì khoá cho tới khi admin mở lại.',
                  style: TextStyle(fontSize: 11, color: AppColors.mute),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Thôi'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('LƯU'),
            ),
          ],
        ),
      ),
    );

    if (submitted != true || !mounted) return;

    await adminRun(
      context,
      provider,
      () => provider.updateStatus(
        account.id,
        status,
        lockedUntil: status == 'LOCKED' ? lockedUntil : null,
      ),
      successMessage: 'Đã đổi trạng thái tài khoản.',
    );
  }

  Future<void> _delete(AdminAccount account) async {
    final provider = context.read<AdminAccountProvider>();
    final ok = await adminConfirm(
      context,
      title: 'Xoá tài khoản?',
      message: '${account.email} sẽ không đăng nhập được nữa. '
          'Đơn hàng cũ của tài khoản này vẫn được giữ lại.',
    );
    if (!ok || !mounted) return;

    await adminRun(
      context,
      provider,
      () => provider.deleteAccount(account.id),
      successMessage: 'Đã xoá tài khoản.',
    );
  }

  static String _statusLabel(String s) {
    switch (s) {
      case 'ACTIVE':
        return 'Đang hoạt động';
      case 'DISABLED':
        return 'Vô hiệu hoá';
      default:
        return 'Khoá tạm';
    }
  }

  static String _statusHint(String s) {
    switch (s) {
      case 'ACTIVE':
        return 'Đăng nhập bình thường';
      case 'DISABLED':
        return 'Chặn hẳn, không hẹn mở lại';
      default:
        return 'Chặn tới một thời điểm đã định';
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminAccountProvider>();
    final accounts = provider.accounts;

    return Scaffold(
      backgroundColor: AppColors.sand50,
      appBar: AppBar(title: const Text('TÀI KHOẢN')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.clay500,
        onPressed: _openCreateForm,
        child: const Icon(Icons.person_add_alt_1, color: Colors.white),
      ),
      body: Column(
        children: [
          AdminErrorBar(message: provider.errorMessage, onDismiss: provider.clearError),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: provider.setQuery,
                  decoration: InputDecoration(
                    hintText: 'Tìm theo email hoặc role',
                    prefixIcon: const Icon(Icons.search, size: 19),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 4),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Máy chủ chưa hỗ trợ tìm kiếm, nên ô này chỉ lọc trong trang đang xem.',
                    style: TextStyle(fontSize: 11, color: AppColors.mute),
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip(provider, null, 'Tất cả'),
                      _filterChip(provider, 'ACTIVE', 'Hoạt động'),
                      _filterChip(provider, 'DISABLED', 'Vô hiệu'),
                      _filterChip(provider, 'LOCKED', 'Bị khoá'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (provider.isLoading && provider.pageData.isEmpty)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (accounts.isEmpty)
            const Expanded(
              child: AdminEmptyState(
                icon: Icons.manage_accounts_outlined,
                title: 'Không có tài khoản nào khớp',
                subtitle: 'Thử xoá từ khoá tìm kiếm hoặc sang trang khác.',
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => provider.fetchAccounts(page: provider.pageData.page),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: accounts.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _accountCard(accounts[index]),
                ),
              ),
            ),
          AdminPagingBar(
            page: provider.pageData.page,
            totalPages: provider.pageData.totalPages,
            totalElements: provider.pageData.totalElements,
            isLoading: provider.isLoading,
            onGoToPage: (p) => provider.fetchAccounts(page: p),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(AdminAccountProvider provider, String? value, String label) {
    final selected = provider.statusFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: selected,
        onSelected: (_) => provider.setStatusFilter(value),
      ),
    );
  }

  Widget _accountCard(AdminAccount account) {
    final statusTone = switch (account.status.toUpperCase()) {
      'ACTIVE' => 1,
      'LOCKED' => 3,
      _ => 2,
    };

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.sand200),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.email,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.ink),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    AdminStatusChip(account.roleName ?? 'KHÔNG ROLE',
                        tone: account.isAdmin ? 2 : 0),
                    AdminStatusChip(account.statusText, tone: statusTone),
                    if (account.isGoogle) const AdminStatusChip('GOOGLE'),
                    if (!account.hasPassword) const AdminStatusChip('CHƯA CÓ MẬT KHẨU'),
                  ],
                ),
                if (account.status.toUpperCase() == 'LOCKED' && account.lockedUntil != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Mở khoá lúc ${Formatters.formatDate(account.lockedUntil!)}',
                    style: const TextStyle(fontSize: 11.5, color: AppColors.mute),
                  ),
                ],
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20, color: AppColors.mute),
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _openEditForm(account);
                case 'status':
                  _changeStatus(account);
                case 'delete':
                  _delete(account);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Sửa email / role')),
              PopupMenuItem(value: 'status', child: Text('Đổi trạng thái')),
              PopupMenuItem(value: 'delete', child: Text('Xoá tài khoản')),
            ],
          ),
        ],
      ),
    );
  }
}
