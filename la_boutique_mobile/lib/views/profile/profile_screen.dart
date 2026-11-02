import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../auth/forgot_password_screen.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';
import '../admin/admin_home_screen.dart';
import '../chat/chat_screen.dart';
import '../map/store_map_screen.dart';
import '../order/my_orders_screen.dart';
import '../order/order_lookup_screen.dart';
import 'change_email_screen.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    // Tài khoản Google thuần chưa có mật khẩu ⇒ hiện "Đặt mật khẩu" (dẫn luồng quên mật khẩu).
    final needsSetPassword = auth.accountInfo != null && !auth.accountInfo!.hasPassword;

    return Scaffold(
      backgroundColor: AppColors.sand50,
      appBar: AppBar(
        title: const Text('TÀI KHOẢN CỦA TÔI'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // If user is NOT logged in: Show Guest Banner with separate Login & Register buttons
            if (user == null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.sand200.withValues(alpha: 0.8)),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 65,
                      height: 65,
                      decoration: const BoxDecoration(
                        color: AppColors.clay50,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.person_outline, size: 36, color: AppColors.clay500),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'CHÀO MỪNG NÀNG THƠ',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Đăng nhập hoặc đăng ký để quản lý đơn hàng, lưu các thiết kế yêu thích và nhận ưu đãi riêng.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12.5, color: AppColors.mute, height: 1.4),
                    ),
                    const SizedBox(height: 20),

                    // Dedicated Login & Register buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.clay500,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 2,
                            ),
                            onPressed: () {
                              // Navigate to dedicated Login page
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const LoginScreen()),
                              );
                            },
                            child: const Text('ĐĂNG NHẬP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              side: const BorderSide(color: AppColors.clay500, width: 1.2),
                              foregroundColor: AppColors.clay600,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              // Navigate to dedicated Register page
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const RegisterScreen()),
                              );
                            },
                            child: const Text('ĐĂNG KÝ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Logged in Profile Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.sand200.withValues(alpha: 0.8)),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: AppColors.clay100,
                          backgroundImage: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                              ? NetworkImage(user.avatarUrl!)
                              : null,
                          child: (user.avatarUrl == null || user.avatarUrl!.isEmpty)
                              ? Text(
                                  user.name.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.clay600,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      user.fullName.isNotEmpty ? user.fullName : user.username,
                                      style: GoogleFonts.playfairDisplay(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.ink,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (user.roleName != null) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.clay100,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        user.roleName!,
                                        style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.clay700),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '@${user.username} • ${user.email}',
                                style: const TextStyle(fontSize: 11.5, color: AppColors.mute),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (user.phone.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  user.phone,
                                  style: const TextStyle(fontSize: 11.5, color: AppColors.clay600, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1, color: AppColors.sand200),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              side: const BorderSide(color: AppColors.sand300),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.edit_outlined, size: 15, color: AppColors.clay600),
                            label: const Text('Sửa hồ sơ', style: TextStyle(fontSize: 12, color: AppColors.ink)),
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              side: const BorderSide(color: AppColors.sand300),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.lock_outline, size: 15, color: AppColors.clay600),
                            label: Text(
                              needsSetPassword ? 'Đặt mật khẩu' : 'Đổi mật khẩu',
                              style: const TextStyle(fontSize: 12, color: AppColors.ink),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => needsSetPassword
                                      ? ForgotPasswordScreen(
                                          prefillEmail: user.email,
                                          setPasswordMode: true,
                                        )
                                      : const ChangePasswordScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          side: const BorderSide(color: AppColors.sand300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.alternate_email, size: 15, color: AppColors.clay600),
                        label: const Text('Đổi email đăng nhập', style: TextStyle(fontSize: 12, color: AppColors.ink)),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangeEmailScreen()));
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),

            // Admin section — chỉ hiện với tài khoản có role ADMIN
            if ((context.watch<AuthProvider>().accountInfo?.roleName ?? '').toUpperCase() ==
                'ADMIN') ...[
              _buildSectionCard(
                title: 'QUẢN TRỊ VIÊN',
                color: AppColors.sand200,
                children: [
                  _buildMenuItem(
                    icon: Icons.admin_panel_settings_outlined,
                    title: 'Khu quản trị',
                    subtitle: 'Đơn hàng, sản phẩm, danh mục, cửa hàng, hội thoại, hoàn tiền',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminHomeScreen()));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ],

            // Orders and Features Section
            _buildSectionCard(
              title: 'QUẢN LÝ ĐƠN HÀNG & MUA SẮM',
              children: [
                _buildMenuItem(
                  icon: Icons.inventory_2_outlined,
                  title: 'Đơn hàng của tôi (My Orders)',
                  subtitle: 'Theo dõi tiến trình 5 bước các đơn hàng bạn đã đặt',
                  badge: user != null ? 'Trực tuyến' : null,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const MyOrdersScreen()));
                  },
                ),
                _buildMenuItem(
                  icon: Icons.manage_search_outlined,
                  title: 'Tra cứu nhanh mã đơn hàng',
                  subtitle: 'Tìm đơn qua Mã đơn (LB-xxxxx) hoặc Số điện thoại',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderLookupScreen()));
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Services & Showroom
            _buildSectionCard(
              title: 'DỊCH VỤ & THƯƠNG HIỆU',
              children: [
                _buildMenuItem(
                  icon: Icons.storefront_outlined,
                  title: 'Hệ thống showroom La Boutique',
                  subtitle: 'Bản đồ showroom Flagship & chỉ đường tại Quận 1',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const StoreMapScreen()));
                  },
                ),
                _buildMenuItem(
                  icon: Icons.support_agent_outlined,
                  title: 'Tư vấn viên trực tuyến (Live Chat)',
                  subtitle: 'Hỏi đáp kích thước và chất liệu thời trang 24/7',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen()));
                  },
                ),
                _buildMenuItem(
                  icon: Icons.straighten_outlined,
                  title: 'Bảng quy đổi kích cỡ (Size Guide)',
                  subtitle: 'Chuẩn số đo phom dáng nữ La Boutique S, M, L',
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Bảng chuẩn kích thước'),
                        content: const Text(
                          '• Size S: Dưới 48kg (Vòng 1 < 84cm, Vòng 2 < 66cm)\n'
                          '• Size M: 48 - 54kg (Vòng 1: 85-88cm, Vòng 2: 67-72cm)\n'
                          '• Size L: 55 - 62kg (Vòng 1: 89-94cm, Vòng 2: 73-78cm)',
                          style: TextStyle(height: 1.5),
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),

            if (user != null) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.red.shade300),
                        foregroundColor: Colors.red.shade700,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.logout, size: 16),
                      label: const Text('Đăng xuất', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      onPressed: () async {
                        await auth.logout();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã đăng xuất thiết bị hiện tại')),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.red.shade400),
                        foregroundColor: Colors.red.shade800,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.phonelink_erase, size: 16),
                      label: const Text('Đăng xuất tất cả', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      onPressed: () async {
                        await auth.logoutAll();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã đăng xuất khỏi tất cả thiết bị')),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required List<Widget> children, Color? color}) {
    return Material(
      color: color ?? AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.sand200.withValues(alpha: 0.8), width: 0.8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: AppColors.mute,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    String? badge,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.sand100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.clay500, size: 20),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.ink),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                badge,
                style: const TextStyle(color: AppColors.success, fontSize: 9.5, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.mute)),
      trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.mute),
      onTap: onTap,
    );
  }
}
