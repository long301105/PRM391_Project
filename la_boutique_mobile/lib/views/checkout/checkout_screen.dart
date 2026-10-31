import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/order_provider.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';
import 'order_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();

  String _paymentMethod = 'COD'; // 'COD' or 'BANKING' (mapped to BANK_TRANSFER for BE)
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autofillUserData();
    });
  }

  void _autofillUserData() {
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      if (_nameController.text.isEmpty) _nameController.text = user.name;
      if (_phoneController.text.isEmpty) _phoneController.text = user.phone;
      if (_emailController.text.isEmpty) _emailController.text = user.email;
      if (_addressController.text.isEmpty) _addressController.text = user.address;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _showRequireLoginDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.sand50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.lock_outline, color: AppColors.clay500),
            SizedBox(width: 8),
            Text('Yêu Cầu Đăng Nhập', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: const Text(
          'Để bảo vệ quyền lợi và theo dõi tiến trình đơn hàng, bạn vui lòng đăng nhập tài khoản trước khi đặt hàng.',
          style: TextStyle(fontSize: 13, color: AppColors.mute, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ĐỂ SAU', style: TextStyle(color: AppColors.mute)),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.clay500),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()))
                  .then((_) => _autofillUserData());
            },
            child: const Text('ĐĂNG KÝ', style: TextStyle(color: AppColors.clay600, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.clay500,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()))
                  .then((_) => _autofillUserData());
            },
            child: const Text('ĐĂNG NHẬP', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _submitOrder() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      _showRequireLoginDialog();
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final cart = context.read<CartProvider>();
    if (cart.cartItemsList.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final orderId = await context.read<OrderProvider>().createOrder(
            customerName: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            email: _emailController.text.trim(),
            address: _addressController.text.trim(),
            note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
            items: cart.cartItemsList,
            subtotal: cart.subtotal,
            discount: cart.discountAmount,
            shippingFee: cart.shippingFee,
            total: cart.totalAmount,
            paymentMethod: _paymentMethod,
          );

      if (!mounted) return;

      // Add in-app notification
      context.read<NotificationProvider>().addOrderNotification(orderId);

      final total = cart.totalAmount;
      final name = _nameController.text.trim();

      cart.clearCart();

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OrderSuccessScreen(
            orderId: orderId,
            totalAmount: total,
            customerName: name,
            paymentMethod: _paymentMethod,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      final message = e is ApiException ? e.message : 'Đặt hàng không thành công. Vui lòng thử lại.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.sand50,
      appBar: AppBar(
        title: const Text('THANH TOÁN ĐƠN HÀNG'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Guest Warning Banner if not logged in
              if (!auth.isAuthenticated) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.amber.shade900, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Bạn chưa đăng nhập tài khoản',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.amber.shade900),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Để đồng bộ đơn hàng với hệ thống máy chủ, bạn nên đăng nhập trước khi xác nhận đơn.',
                        style: TextStyle(fontSize: 12, color: AppColors.mute, height: 1.3),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.clay500,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()))
                                  .then((_) => _autofillUserData());
                            },
                            child: const Text('ĐĂNG NHẬP'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.clay500),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()))
                                  .then((_) => _autofillUserData());
                            },
                            child: const Text('ĐĂNG KÝ', style: TextStyle(color: AppColors.clay600)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              // Delivery Info Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.sand200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, color: AppColors.clay500, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'THÔNG TIN GIAO HÀNG',
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Họ và tên người nhận *',
                        prefixIcon: Icon(Icons.person_outline, size: 20),
                      ),
                      validator: (val) =>
                          val == null || val.trim().isEmpty ? 'Vui lòng nhập họ tên' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Số điện thoại liên hệ *',
                        prefixIcon: Icon(Icons.phone_outlined, size: 20),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Vui lòng nhập số điện thoại';
                        }
                        if (val.trim().length < 9) {
                          return 'Số điện thoại không hợp lệ';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Địa chỉ Email (để nhận hóa đơn điện tử)',
                        prefixIcon: Icon(Icons.email_outlined, size: 20),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Địa chỉ nhận hàng chi tiết *',
                        prefixIcon: Icon(Icons.home_outlined, size: 20),
                      ),
                      validator: (val) =>
                          val == null || val.trim().isEmpty ? 'Vui lòng nhập địa chỉ' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _noteController,
                      decoration: const InputDecoration(
                        labelText: 'Ghi chú cho shipper (tùy chọn)',
                        prefixIcon: Icon(Icons.note_alt_outlined, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Payment Methods
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.sand200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.payment_outlined, color: AppColors.clay500, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'PHƯƠNG THỨC THANH TOÁN',
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    RadioGroup<String>(
                      groupValue: _paymentMethod,
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _paymentMethod = val);
                        }
                      },
                      child: Column(
                        children: [
                          RadioListTile<String>(
                            value: 'COD',
                            activeColor: AppColors.clay500,
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Thanh toán khi nhận hàng (COD)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: const Text('Nàng kiểm tra hàng và thanh toán tiền mặt cho shipper', style: TextStyle(fontSize: 12, color: AppColors.mute)),
                          ),
                          const Divider(height: 12, color: AppColors.sand200),
                          RadioListTile<String>(
                            value: 'BANKING',
                            activeColor: AppColors.clay500,
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Thanh toán qua VNPay Sandbox', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: const Text('Mở cổng VNPay — hỗ trợ thẻ ATM nội địa, Visa, MasterCard', style: TextStyle(fontSize: 12, color: AppColors.mute)),
                          ),
                        ],
                      ),
                    ),

                    // Dynamic VNPay Sandbox Box
                    if (_paymentMethod == 'BANKING') ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.payment_rounded, color: Colors.blue.shade800, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Cổng thanh toán VNPay Sandbox',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Colors.blue.shade900),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '• Sau khi xác nhận đơn, bạn sẽ được chuyển tới cổng VNPay để nhập thông tin thẻ test.\n• Hạn thanh toán: 15 phút từ lúc đặt đơn (quá hạn đơn sẽ tự huỷ).',
                              style: TextStyle(fontSize: 12, color: AppColors.ink, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Order Summary Breakdown
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.sand200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TỔNG KẾT ĐƠN HÀNG (${cart.itemCount} sản phẩm)',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tạm tính', style: TextStyle(color: AppColors.mute, fontSize: 13)),
                        Text(Formatters.formatCurrency(cart.subtotal), style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    if (cart.discountAmount > 0) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Voucher giảm giá', style: TextStyle(color: AppColors.success, fontSize: 13)),
                          Text('-${Formatters.formatCurrency(cart.discountAmount)}',
                              style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Phí giao hàng', style: TextStyle(color: AppColors.mute, fontSize: 13)),
                        Text(
                          cart.shippingFee == 0 ? 'MIỄN PHÍ' : Formatters.formatCurrency(cart.shippingFee),
                          style: TextStyle(
                            color: cart.shippingFee == 0 ? AppColors.success : AppColors.ink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20, color: AppColors.sand200),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tổng thanh toán', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text(
                          Formatters.formatCurrency(cart.totalAmount),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.clay600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _isSubmitting ? null : _submitOrder,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'XÁC NHẬN ĐẶT HÀNG (${Formatters.formatCurrency(cart.totalAmount)})',
                          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
