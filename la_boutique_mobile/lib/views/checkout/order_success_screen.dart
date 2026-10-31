import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/payment_provider.dart';
import '../home/home_screen.dart';
import '../order/order_detail_screen.dart';
import '../payment/payment_result_screen.dart';
import '../payment/vnpay_webview_screen.dart';

class OrderSuccessScreen extends StatefulWidget {
  final String orderId;
  final double totalAmount;
  final String customerName;
  final String paymentMethod;

  const OrderSuccessScreen({
    super.key,
    required this.orderId,
    required this.totalAmount,
    required this.customerName,
    required this.paymentMethod,
  });

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen> {
  bool _isOpeningPayment = false;

  bool get _isVnpay =>
      widget.paymentMethod == 'BANKING' ||
      widget.paymentMethod == 'BANK_TRANSFER' ||
      widget.paymentMethod.toUpperCase() == 'VNPAY';

  Future<void> _openVnpayPayment() async {
    setState(() => _isOpeningPayment = true);
    final paymentProv = context.read<PaymentProvider>();
    final vnpayResp = await paymentProv.createVnpayPayment(widget.orderId);

    if (!mounted) return;
    setState(() => _isOpeningPayment = false);

    if (vnpayResp != null) {
      final completed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => VnpayWebviewScreen(
            paymentUrl: vnpayResp.paymentUrl,
            orderNumber: widget.orderId,
          ),
        ),
      );

      if (completed == true && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentResultScreen(orderNumber: widget.orderId),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(paymentProv.errorMessage ?? 'Không thể mở liên kết thanh toán VNPay.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sand50,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Success icon
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  color: AppColors.clay500.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.check_circle_rounded, size: 56, color: AppColors.clay500),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'ĐẶT HÀNG THÀNH CÔNG!',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                  letterSpacing: 0.8,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              Text(
                'Cảm ơn ${widget.customerName} đã tin yêu lựa chọn La Boutique VN.',
                style: const TextStyle(fontSize: 13.5, color: AppColors.mute, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Order detail card
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Mã đơn hàng', style: TextStyle(color: AppColors.mute, fontSize: 13)),
                        Text(
                          '#${widget.orderId}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.clay600),
                        ),
                      ],
                    ),
                    const Divider(height: 20, color: AppColors.sand200),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tổng thanh toán', style: TextStyle(color: AppColors.mute, fontSize: 13)),
                        Text(
                          Formatters.formatCurrency(widget.totalAmount),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.ink),
                        ),
                      ],
                    ),
                    const Divider(height: 20, color: AppColors.sand200),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Phương thức', style: TextStyle(color: AppColors.mute, fontSize: 13)),
                        Text(
                          _isVnpay ? 'VNPay Sandbox' : 'Thanh toán khi nhận hàng (COD)',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ],
                    ),
                    const Divider(height: 20, color: AppColors.sand200),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Trạng thái', style: TextStyle(color: AppColors.mute, fontSize: 13)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.amber.shade300),
                          ),
                          child: Text(
                            'Chờ xác nhận',
                            style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // VNPay warning and CTA button
              if (_isVnpay) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.timer_outlined, color: Colors.amber.shade900, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Đơn hàng có hạn thanh toán 15 phút',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.amber.shade900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Vui lòng nhấn Thanh toán ngay để hoàn tất qua cổng VNPay. Quá hạn hệ thống sẽ tự động huỷ đơn.',
                              style: TextStyle(fontSize: 12, color: AppColors.ink, height: 1.35),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.clay500,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _isOpeningPayment ? null : _openVnpayPayment,
                    icon: _isOpeningPayment
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.payment_rounded, size: 20),
                    label: Text(
                      _isOpeningPayment ? 'ĐANG MỞ CỔNG VNPAY...' : 'THANH TOÁN VNPAY NGAY',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 16),
                const Text(
                  'Nhân viên CSKH của La Boutique sẽ sớm liên hệ xác nhận đơn hàng qua số điện thoại của bạn.',
                  style: TextStyle(fontSize: 12, color: AppColors.mute, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 14),

              // Button View order detail
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    side: const BorderSide(color: AppColors.sand300),
                  ),
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => OrderDetailScreen(orderNumber: widget.orderId),
                      ),
                    );
                  },
                  child: const Text('XEM CHI TIẾT ĐƠN HÀNG', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 10),

              // Continue shopping
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (route) => false,
                  );
                },
                child: const Text('Tiếp tục mua sắm', style: TextStyle(color: AppColors.mute, fontSize: 13)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
