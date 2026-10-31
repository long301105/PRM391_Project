import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/payment.dart';
import '../../providers/payment_provider.dart';
import '../home/home_screen.dart';
import '../order/order_detail_screen.dart';
import 'vnpay_webview_screen.dart';

class PaymentResultScreen extends StatefulWidget {
  final String orderNumber;

  const PaymentResultScreen({
    super.key,
    required this.orderNumber,
  });

  @override
  State<PaymentResultScreen> createState() => _PaymentResultScreenState();
}

class _PaymentResultScreenState extends State<PaymentResultScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startPolling();
    });
  }

  void _startPolling() {
    context.read<PaymentProvider>().pollPaymentStatus(widget.orderNumber);
  }

  Future<void> _retryPayment() async {
    final paymentProv = context.read<PaymentProvider>();
    final vnpayResp = await paymentProv.createVnpayPayment(widget.orderNumber);

    if (!mounted) return;

    if (vnpayResp != null) {
      final completed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => VnpayWebviewScreen(
            paymentUrl: vnpayResp.paymentUrl,
            orderNumber: widget.orderNumber,
          ),
        ),
      );

      if (completed == true && mounted) {
        _startPolling();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(paymentProv.errorMessage ?? 'Không thể mở lại liên kết thanh toán.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentProv = context.watch<PaymentProvider>();
    final status = paymentProv.paymentStatus;
    final isPolling = paymentProv.isPolling;

    return Scaffold(
      backgroundColor: AppColors.sand50,
      appBar: AppBar(
        title: const Text('KẾT QUẢ THANH TOÁN'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined),
            tooltip: 'Trang chủ',
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: isPolling
              ? _buildPollingState()
              : _buildResultState(status),
        ),
      ),
    );
  }

  Widget _buildPollingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.clay50,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.clay200),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              color: AppColors.clay500,
              strokeWidth: 3,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'ĐANG XÁC NHẬN THANH TOÁN...',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.ink,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const Text(
          'Hệ thống đang đồng bộ kết quả từ cổng VNPay Sandbox.\nQuá trình này thường mất từ 2 đến 10 giây.',
          style: TextStyle(fontSize: 13.5, color: AppColors.mute, height: 1.4),
          textAlign: TextAlign.center,
        ),
        const Spacer(),
        Text(
          'Mã đơn hàng: #${widget.orderNumber}',
          style: const TextStyle(fontSize: 12, color: AppColors.mute, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildResultState(PaymentStatusResponse? status) {
    if (status == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 54, color: AppColors.mute),
            const SizedBox(height: 16),
            const Text(
              'Chưa nhận được phản hồi trạng thái',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vui lòng kiểm tra lại kết nối mạng hoặc thử làm mới.',
              style: TextStyle(color: AppColors.mute, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _startPolling,
              child: const Text('KIỂM TRA LẠI'),
            ),
          ],
        ),
      );
    }

    if (status.isPaid) {
      return _buildPaidView(status);
    } else if (status.isFailed) {
      return _buildFailedView(status);
    } else if (status.isExpired) {
      return _buildExpiredView(status);
    } else {
      // Vẫn PENDING sau timeout polling
      return _buildPendingTimeoutView(status);
    }
  }

  Widget _buildPaidView(PaymentStatusResponse status) {
    return Column(
      children: [
        const Spacer(),
        Container(
          width: 86,
          height: 86,
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.green.shade200, width: 2),
          ),
          child: Icon(Icons.check_circle_rounded, size: 56, color: Colors.green.shade600),
        ),
        const SizedBox(height: 20),
        Text(
          'THANH TOÁN THÀNH CÔNG!',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.ink,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Đơn hàng của bạn đã được ghi nhận thanh toán qua cổng VNPay.',
          style: TextStyle(fontSize: 13.5, color: AppColors.mute),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        // Detail card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.sand200),
            boxShadow: AppColors.cardShadow,
          ),
          child: Column(
            children: [
              _buildDetailRow('Mã đơn hàng', '#${status.orderNumber}'),
              const Divider(height: 18, color: AppColors.sand200),
              _buildDetailRow('Số tiền thanh toán', Formatters.formatCurrency(status.amount), isHighlight: true),
              if (status.bankCode != null && status.bankCode!.isNotEmpty) ...[
                const Divider(height: 18, color: AppColors.sand200),
                _buildDetailRow('Ngân hàng thanh toán', status.bankCode!),
              ],
              if (status.paidAt != null) ...[
                const Divider(height: 18, color: AppColors.sand200),
                _buildDetailRow('Thời gian', Formatters.formatDateTime(status.paidAt!)),
              ],
            ],
          ),
        ),

        const Spacer(),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => OrderDetailScreen(orderNumber: widget.orderNumber),
                ),
              );
            },
            child: const Text('XEM TIẾN TRÌNH ĐƠN HÀNG', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AppColors.sand300),
            ),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
            },
            child: const Text('TIẾP TỤC MUA SẮM', style: TextStyle(color: AppColors.ink)),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildFailedView(PaymentStatusResponse status) {
    return Column(
      children: [
        const Spacer(),
        Container(
          width: 86,
          height: 86,
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.red.shade200, width: 2),
          ),
          child: Icon(Icons.cancel_rounded, size: 56, color: Colors.red.shade600),
        ),
        const SizedBox(height: 20),
        Text(
          'THANH TOÁN THẤT BẠI',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.red.shade800,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Giao dịch không thành công hoặc bạn đã hủy trong quá trình thanh toán.',
          style: TextStyle(fontSize: 13, color: AppColors.mute, height: 1.3),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),

        if (status.canRetry) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber.shade900, size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Đơn hàng vẫn đang được giữ trong vòng 15 phút. Bạn có thể nhấn Thử lại để thực hiện thanh toán.',
                    style: TextStyle(fontSize: 12, color: AppColors.ink, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        ],

        const Spacer(),

        if (status.canRetry) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.clay500,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _retryPayment,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('THỬ THANH TOÁN LẠI', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
        ],

        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AppColors.sand300),
            ),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => OrderDetailScreen(orderNumber: widget.orderNumber),
                ),
              );
            },
            child: const Text('XEM CHI TIẾT ĐƠN HÀNG', style: TextStyle(color: AppColors.ink)),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildExpiredView(PaymentStatusResponse status) {
    return Column(
      children: [
        const Spacer(),
        Container(
          width: 86,
          height: 86,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade300, width: 2),
          ),
          child: Icon(Icons.timer_off_outlined, size: 50, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 20),
        Text(
          'ĐƠN HÀNG ĐÃ HẾT HẠN',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.ink,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Thời hạn thanh toán 15 phút của đơn hàng đã trôi qua. Đơn hàng đã tự động bị huỷ và hoàn tồn kho.',
          style: TextStyle(fontSize: 13, color: AppColors.mute, height: 1.4),
          textAlign: TextAlign.center,
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
            },
            child: const Text('TIẾP TỤC MUA SẮM ĐƠN MỚI', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPendingTimeoutView(PaymentStatusResponse status) {
    return Column(
      children: [
        const Spacer(),
        Container(
          width: 86,
          height: 86,
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.amber.shade300, width: 2),
          ),
          child: Icon(Icons.hourglass_top_rounded, size: 50, color: Colors.amber.shade800),
        ),
        const SizedBox(height: 20),
        Text(
          'ĐANG CHỜ XÁC NHẬN TỪ CỔNG',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.ink,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Giao dịch của bạn đã hoàn tất trên cổng VNPay nhưng hệ thống đang đối soát dữ liệu IPN.\nVui lòng không thực hiện thanh toán lại.',
          style: TextStyle(fontSize: 13, color: AppColors.mute, height: 1.4),
          textAlign: TextAlign.center,
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.clay500,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _startPolling,
            icon: const Icon(Icons.sync_rounded),
            label: const Text('CẬP NHẬT LẠI TRẠNG THÁI', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => OrderDetailScreen(orderNumber: widget.orderNumber),
                ),
              );
            },
            child: const Text('VÀO CHI TIẾT ĐƠN HÀNG'),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.mute, fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isHighlight ? 15 : 13.5,
            color: isHighlight ? AppColors.clay600 : AppColors.ink,
          ),
        ),
      ],
    );
  }
}
