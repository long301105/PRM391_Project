import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/order.dart';
import '../../providers/order_provider.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderNumber;

  const OrderDetailScreen({super.key, required this.orderNumber});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  OrderModel? _order;
  bool _isLoading = true;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    setState(() => _isLoading = true);
    final order = await context.read<OrderProvider>().fetchOrderDetail(widget.orderNumber);
    if (mounted) {
      setState(() {
        _order = order;
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelOrder() async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Huỷ đơn hàng?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Đơn #${widget.orderNumber} sẽ được huỷ và không thể hoàn lại. '
              'Hàng trong đơn được trả về kho ngay.',
              style: const TextStyle(fontSize: 13.5, height: 1.4),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: reasonController,
              maxLength: 300,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Lý do huỷ (không bắt buộc)',
                hintText: 'VD: Em đặt nhầm size',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Giữ đơn'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('HUỶ ĐƠN'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      reasonController.dispose();
      return;
    }

    final reason = reasonController.text;
    reasonController.dispose();

    setState(() => _isCancelling = true);
    final orderProvider = context.read<OrderProvider>();
    final ok = await orderProvider.cancelMyOrder(widget.orderNumber, reason: reason);

    if (!mounted) return;
    setState(() => _isCancelling = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Đã huỷ đơn #${widget.orderNumber}. Hàng đã được trả về kho.'
            : (orderProvider.errorMessage ?? 'Huỷ đơn không thành công.')),
        backgroundColor: ok ? AppColors.success : Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );

    if (ok) await _loadOrder();
  }

  void _copyOrderNumber(String code) {
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép mã đơn #$code 📋'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _launchExternal(Uri uri, String errorMsg) async {
    HapticFeedback.lightImpact();
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  int _getStatusStep(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
      case 'CHỜ XÁC NHẬN':
        return 0;
      case 'CONFIRMED':
      case 'ĐÃ XÁC NHẬN':
      case 'ĐANG XỬ LÝ':
        return 1;
      case 'SHIPPING':
      case 'ĐANG GIAO HÀNG':
        return 2;
      case 'COMPLETED':
      case 'HOÀN THÀNH':
        return 3;
      case 'CANCELLED':
      case 'ĐÃ HỦY':
        return -1;
      default:
        return 0;
    }
  }

  Widget _buildStatusTracker(String status, {String? cancelReason}) {
    final step = _getStatusStep(status);
    final isCancelled = step == -1;

    if (isCancelled) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.cancel, color: Colors.red.shade700, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Đơn hàng này đã bị hủy',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade800),
                  ),
                  if (cancelReason != null && cancelReason.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Lý do: $cancelReason',
                      style: TextStyle(fontSize: 12.5, color: Colors.red.shade700, height: 1.35),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    final steps = ['Chờ xác nhận', 'Đã xác nhận', 'Đang giao', 'Hoàn thành'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.sand200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TIẾN TRÌNH ĐƠN HÀNG', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.mute)),
          const SizedBox(height: 16),
          Row(
            children: List.generate(steps.length * 2 - 1, (index) {
              if (index.isOdd) {
                // Divider line between steps
                final lineIdx = index ~/ 2;
                final isCompleted = lineIdx < step;
                return Expanded(
                  child: Container(
                    height: 2.5,
                    color: isCompleted ? AppColors.clay500 : AppColors.sand300,
                  ),
                );
              }

              final stepIdx = index ~/ 2;
              final isReached = stepIdx <= step;
              final isCurrent = stepIdx == step;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isReached ? AppColors.clay500 : AppColors.sand200,
                      border: isCurrent
                          ? Border.all(color: AppColors.clay300, width: 3)
                          : null,
                    ),
                    child: Center(
                      child: Icon(
                        isReached ? Icons.check : Icons.circle,
                        size: 12,
                        color: isReached ? Colors.white : AppColors.mute,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    steps[stepIdx],
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCurrent ? AppColors.clay700 : AppColors.mute,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.sand50,
        appBar: AppBar(title: Text(widget.orderNumber)),
        body: const Center(child: CircularProgressIndicator(color: AppColors.clay500)),
      );
    }

    if (_order == null) {
      return Scaffold(
        backgroundColor: AppColors.sand50,
        appBar: AppBar(title: const Text('CHI TIẾT ĐƠN HÀNG')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 50, color: Colors.red),
              const SizedBox(height: 12),
              const Text('Không tìm thấy thông tin đơn hàng này'),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('QUAY LẠI')),
            ],
          ),
        ),
      );
    }

    final order = _order!;

    return Scaffold(
      backgroundColor: AppColors.sand50,
      appBar: AppBar(
        title: Text('ĐƠN HÀNG #${order.displayOrderNumber}'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 20),
            tooltip: 'Sao chép mã đơn hàng',
            onPressed: () => _copyOrderNumber(order.displayOrderNumber),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status tracker
            _buildStatusTracker(order.status, cancelReason: order.cancelReason),
            const SizedBox(height: 14),

            // Receiver Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.sand200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.location_on_outlined, color: AppColors.clay500, size: 18),
                      SizedBox(width: 8),
                      Text('ĐỊA CHỈ NHẬN HÀNG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.ink)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('${order.customerName} • ${order.phone}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  const SizedBox(height: 4),
                  Text(order.address, style: const TextStyle(fontSize: 12.5, color: AppColors.mute, height: 1.35)),
                  if (order.note != null && order.note!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text('Ghi chú: ${order.note}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.clay600)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Ordered items list
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.sand200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DANH SÁCH MÓN HÀNG (${order.totalItems} MÓN)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.mute)),
                  const SizedBox(height: 12),
                  ...order.items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 55,
                              height: 70,
                              child: item.product.assetPath.startsWith('http')
                                  ? Image.network(item.product.assetPath, fit: BoxFit.cover)
                                  : Image.asset(item.product.assetPath, fit: BoxFit.cover),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 2),
                                const SizedBox(height: 3),
                                Text('Size: ${item.size} • Số lượng: ${item.quantity}', style: const TextStyle(fontSize: 11.5, color: AppColors.mute)),
                                const SizedBox(height: 4),
                                Text(Formatters.formatCurrency(item.totalPrice), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.clay600, fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Invoice Breakdown
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.sand200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CHI TIẾT THANH TOÁN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.mute)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tạm tính', style: TextStyle(color: AppColors.mute, fontSize: 13)),
                      Text(Formatters.formatCurrency(order.subtotal), style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  if (order.discount > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Giảm giá', style: TextStyle(color: AppColors.success, fontSize: 13)),
                        Text('-${Formatters.formatCurrency(order.discount)}', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Phí giao hàng', style: TextStyle(color: AppColors.mute, fontSize: 13)),
                      Text(
                        order.shippingFee == 0 ? 'MIỄN PHÍ' : Formatters.formatCurrency(order.shippingFee),
                        style: TextStyle(color: order.shippingFee == 0 ? AppColors.success : AppColors.ink, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const Divider(height: 20, color: AppColors.sand200),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tổng thanh toán', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(
                        Formatters.formatCurrency(order.total),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.clay600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Phương thức: ${order.paymentMethodText}', style: const TextStyle(fontSize: 12, color: AppColors.mute)),
                ],
              ),
            ),
            const SizedBox(height: 14),

            if (order.canCustomerCancel) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _isCancelling ? null : _cancelOrder,
                  icon: _isCancelling
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.close_rounded, size: 18),
                  label: Text(
                    _isCancelling ? 'ĐANG HUỶ...' : 'HUỶ ĐƠN HÀNG NÀY',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Chỉ huỷ được khi đơn còn ở trạng thái "Chờ xác nhận".',
                style: TextStyle(fontSize: 11.5, color: AppColors.mute),
              ),
              const SizedBox(height: 14),
            ],

            // Hỗ trợ đơn hàng: gọi hotline hoặc chat Zalo
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.sand200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.support_agent_outlined, color: AppColors.clay500, size: 18),
                      SizedBox(width: 8),
                      Text('CẦN HỖ TRỢ ĐƠN HÀNG?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.ink)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Liên hệ bộ phận CSKH nếu nàng cần đổi/hủy đơn hoặc hỏi về tình trạng giao hàng.',
                    style: TextStyle(fontSize: 12, color: AppColors.mute, height: 1.35),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.clay600,
                            side: const BorderSide(color: AppColors.clay500),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => _launchExternal(
                            Uri(scheme: 'tel', path: AppConfig.supportHotline),
                            'Không mở được ứng dụng gọi điện',
                          ),
                          icon: const Icon(Icons.phone_outlined, size: 18),
                          label: const Text('Gọi hotline', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.clay500,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => _launchExternal(
                            Uri.parse(AppConfig.supportZaloUrl),
                            'Không mở được Zalo',
                          ),
                          icon: const Icon(Icons.chat_bubble_outline, size: 18),
                          label: const Text('Chat Zalo', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
