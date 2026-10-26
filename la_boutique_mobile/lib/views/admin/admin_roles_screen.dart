import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/admin_models.dart';
import '../../providers/admin/admin_role_provider.dart';
import 'admin_widgets.dart';

class AdminRolesScreen extends StatefulWidget {
  const AdminRolesScreen({super.key});

  @override
  State<AdminRolesScreen> createState() => _AdminRolesScreenState();
}

class _AdminRolesScreenState extends State<AdminRolesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminRoleProvider>().fetchRoles();
    });
  }

  Future<void> _openForm({AdminRole? role}) async {
    final provider = context.read<AdminRoleProvider>();
    final nameController = TextEditingController(text: role?.roleName ?? '');
    final descController = TextEditingController(text: role?.description ?? '');
    final formKey = GlobalKey<FormState>();

    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(role == null ? 'Thêm role' : 'Sửa role'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AdminField(
                controller: nameController,
                label: 'Tên role',
                hint: 'VD: STAFF',
                helper: 'BE tự viết HOA. Tên phải duy nhất, trùng là báo lỗi.',
                required: true,
              ),
              AdminField(
                controller: descController,
                label: 'Mô tả',
                maxLines: 2,
              ),
            ],
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
    );

    if (submitted != true) {
      nameController.dispose();
      descController.dispose();
      return;
    }

    final name = nameController.text;
    final desc = descController.text;
    nameController.dispose();
    descController.dispose();

    if (!mounted) return;
    await adminRun(
      context,
      provider,
      () => role == null
          ? provider.createRole(roleName: name, description: desc)
          : provider.updateRole(role.id, roleName: name, description: desc),
      successMessage: role == null ? 'Đã thêm role.' : 'Đã cập nhật role.',
    );
  }

  Future<void> _delete(AdminRole role) async {
    final provider = context.read<AdminRoleProvider>();
    final ok = await adminConfirm(
      context,
      title: 'Xoá role ${role.roleName}?',
      message: 'Nếu còn tài khoản nào đang dùng role này, máy chủ sẽ từ chối xoá. '
          'Hãy đổi role của những tài khoản đó trước.',
    );
    if (!ok || !mounted) return;

    await adminRun(
      context,
      provider,
      () => provider.deleteRole(role.id),
      successMessage: 'Đã xoá role.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminRoleProvider>();

    return Scaffold(
      backgroundColor: AppColors.sand50,
      appBar: AppBar(title: const Text('ROLE')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.clay500,
        onPressed: () => _openForm(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          AdminErrorBar(message: provider.errorMessage, onDismiss: provider.clearError),
          if (provider.isLoading && provider.roles.isEmpty)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (provider.roles.isEmpty)
            const Expanded(
              child: AdminEmptyState(
                icon: Icons.badge_outlined,
                title: 'Chưa có role nào',
                subtitle: 'Bấm dấu + để thêm role đầu tiên.',
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => provider.fetchRoles(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.roles.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final role = provider.roles[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.sand200),
                      ),
                      child: ListTile(
                        title: Row(
                          children: [
                            Text(
                              role.roleName,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink),
                            ),
                            const SizedBox(width: 8),
                            if (role.roleName.toUpperCase() == 'ADMIN')
                              const AdminStatusChip('HỆ THỐNG', tone: 2),
                          ],
                        ),
                        subtitle: Text(
                          (role.description?.trim().isNotEmpty ?? false)
                              ? role.description!
                              : 'Không có mô tả',
                          style: const TextStyle(fontSize: 12.5, color: AppColors.mute),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 19),
                              color: AppColors.clay600,
                              onPressed: () => _openForm(role: role),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 19),
                              color: Colors.red.shade600,
                              onPressed: () => _delete(role),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          AdminPagingBar(
            page: provider.pageData.page,
            totalPages: provider.pageData.totalPages,
            totalElements: provider.pageData.totalElements,
            isLoading: provider.isLoading,
            onGoToPage: (p) => provider.fetchRoles(page: p),
          ),
        ],
      ),
    );
  }
}
