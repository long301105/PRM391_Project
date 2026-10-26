import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import 'admin_accounts_screen.dart';
import 'admin_categories_screen.dart';
import 'admin_collections_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_products_screen.dart';
import 'admin_roles_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAdmin = (auth.accountInfo?.roleName ?? '').toUpperCase() == 'ADMIN';

    return Scaffold(
      backgroundColor: AppColors.sand50,
      appBar: AppBar(title: const Text('QUẢN TRỊ')),
      body: !isAdmin
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline, size: 48, color: AppColors.sand300),
                    SizedBox(height: 12),
                    Text(
                      'Tài khoản này không có quyền quản trị',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Đăng nhập bằng tài khoản có role ADMIN để vào khu này.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12.5, color: AppColors.mute, height: 1.4),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Đang đăng nhập: ${auth.accountInfo?.email ?? '—'}',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.mute),
                ),
                const SizedBox(height: 16),
                const _SectionLabel('BÁN HÀNG'),
                _AdminTile(
                  icon: Icons.receipt_long_outlined,
                  title: 'Đơn hàng',
                  subtitle: 'Xem, tra theo mã, đổi trạng thái, huỷ đơn (tự hoàn kho)',
                  onTap: () => _go(context, const AdminOrdersScreen()),
                ),
                _AdminTile(
                  icon: Icons.inventory_2_outlined,
                  title: 'Sản phẩm',
                  subtitle: 'Thêm/sửa/xoá, ảnh gallery, thumbnail, tồn kho theo size',
                  onTap: () => _go(context, const AdminProductsScreen()),
                ),
                _AdminTile(
                  icon: Icons.sell_outlined,
                  title: 'Danh mục',
                  subtitle: 'Thêm/sửa/xoá danh mục sản phẩm',
                  onTap: () => _go(context, const AdminCategoriesScreen()),
                ),
                _AdminTile(
                  icon: Icons.collections_bookmark_outlined,
                  title: 'Bộ sưu tập',
                  subtitle: 'Tạo bộ, chọn sản phẩm, ảnh bìa, cho hiện / ẩn',
                  onTap: () => _go(context, const AdminCollectionsScreen()),
                ),
                const SizedBox(height: 10),
                const _SectionLabel('NGƯỜI DÙNG'),
                _AdminTile(
                  icon: Icons.manage_accounts_outlined,
                  title: 'Tài khoản',
                  subtitle: 'Tạo tài khoản, đổi email/role, khoá hoặc vô hiệu hoá',
                  onTap: () => _go(context, const AdminAccountsScreen()),
                ),
                _AdminTile(
                  icon: Icons.badge_outlined,
                  title: 'Role',
                  subtitle: 'Thêm/sửa/xoá role. Không xoá được role đang có người dùng',
                  onTap: () => _go(context, const AdminRolesScreen()),
                ),
              ],
            ),
    );
  }

  void _go(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.mute,
            letterSpacing: 0.8,
          ),
        ),
      );
}

class _AdminTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AdminTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.sand200),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.clay50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.clay600, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: AppColors.ink),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: AppColors.mute, height: 1.3),
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.sand400),
      ),
    );
  }
}
