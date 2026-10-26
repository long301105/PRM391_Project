import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/order.dart';
import '../../providers/admin/admin_order_provider.dart';
import 'admin_widgets.dart';

class AdminOrderDetailScreen extends StatefulWidget {
  final String orderId;
  final OrderModel? preloaded;

  const AdminOrderDetailScreen({super.key, required this.orderId, this.preloaded});

  @override
  State<AdminOrderDetailScreen> createState() => _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState extends State<AdminOrderDetailScreen> {
  OrderModel? _order;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _order = widget.preloaded;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final order = await context.read<AdminOrderProvider>().fetchOrderById(widget.orderId);
    if (!mounted) return;
    setState(() {
      if (order != null) _order = order;
      _loading = false;
    });
  }

  Future<void> _changeStatus(String next) async {
    final order = _order;
    if (order == null) return;

    final isCancel = next == 'CANCELLED';
    final ok = await adminConfirm(
      context,
      title: isCancel ? 'Huỷ đơn #${order.displayOrderNumber}?' : 'Chuyển sang "${AdminOrderProvider.statusLabel(next)}"?',
      message: isCancel
          ? 'Toàn bộ hàng trong đơn sẽ được trả về kho ngay. Đơn đã huỷ thì không chuyển sang '
              'trạng thái nào khác được nữa.'
          : 'Đơn sẽ chuyển sang "${AdminOrderProvider.statusLabel(next)}". '
              'Khách nhận được thông báo về thay đổi này.',
      confirmLabel: isCancel ? 'HUỶ ĐƠN' : 'ĐỒNG Ý',
      destructive: isCancel,
    );
    if (!ok || !mounted) return;

    final provider = context.read<AdminOrderProvider>();
    final success = await adminRun(
      context,
      provider,
      () => provider.updateStatus(order.id, next),
      successMessage: isCancel ? 'Đã huỷ đơn và hoàn kho.' : 'Đã đổi trạng thái đơn.',
    );
    if (success && mounted) await _load();
  }

  void _copyCode(String code) {
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: code));
    adminToast(context, 'Đã sao chép mã đơn #$code');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminOrderProvider>();
    final order = _order;

    return Scaffold(
      backgroundColor: AppColors.sand50,
      appBar: AppBar(title: const Text('CHI TIẾT ĐƠN')),
      body: order == null
          ? (_loading
              ? const Center(child: CircularProgressIndicator())
              : AdminEmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'Không tải được đơn',
                  subtitle: provider.errorMessage ?? 'Thử quay lại và mở đơn này lần nữa.',
                ))
          : Column(
              children: [
                AdminErrorBar(message: provider.errorMessage, onDismiss: provider.clearError),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _card(
                          title: 'TRẠNG THÁI',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => _copyCode(order.displayOrderNumber),
                                      child: Row(
                                        children: [
                                          Text(
                                            '#${order.displayOrderNumber}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: AppColors.ink),
                                          ),
                                          const SizedBox(width: 6),
                                          const Icon(Icons.copy_rounded,
                                              size: 14, color: AppColors.mute),
                                        ],
                                      ),
                                    ),
                                  ),
                                  AdminStatusChip(order.statusText,
                                      tone: switch (order.status.toUpperCase()) {
                                        'COMPLETED' => 1,
                                        'CANCELLED' => 3,
                                        'PENDING' => 2,
                                        _ => 0,
                                      }),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Đặt lúc ${Formatters.formatDate(order.createdAt)}',
                                style: const TextStyle(fontSize: 12, color: AppColors.mute),
                              ),
                              if (order.cancelReason?.trim().isNotEmpty ?? false) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Lý do huỷ: ${order.cancelReason}',
                                  style: TextStyle(fontSize: 12.5, color: Colors.red.shade700),
                                ),
                              ],
                              const SizedBox(height: 14),
                              _buildTransitions(order),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        _card(
                          title: 'NGƯỜI NHẬN',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _row('Tên', order.customerName),
                              _row('Điện thoại', order.phone),
                              if (order.email?.trim().isNotEmpty ?? false)
                                _row('Email', order.email!),
                              _row('Địa chỉ', order.address),
                              if (order.note?.trim().isNotEmpty ?? false) _row('Ghi chú', order.note!),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        _card(
                          title: 'HÀNG TRONG ĐƠN',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (order.orderItems.isEmpty)
                                const Text(
                                  'Đơn này không có dòng hàng nào.',
                                  style: TextStyle(fontSize: 12.5, color: AppColors.mute),
                                )
                              else
                                ...order.orderItems.map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.productName,
                                                style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.ink),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Size ${item.size} · ${item.quantity} × ${Formatters.formatCurrency(item.unitPrice)}',
                                                style: const TextStyle(
                                                    fontSize: 11.5, color: AppColors.mute),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          Formatters.formatCurrency(item.lineTotal),
                                          style: const TextStyle(
                                              fontSize: 12.5, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              const Divider(height: 18),
                              _money('Tạm tính', order.subtotal),
                              _money('Phí giao hàng', order.shippingFee),
                              if (order.discount > 0) _money('Giảm giá', -order.discount),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Expanded(
                                    child: Text('Tổng cộng',
                                        style: TextStyle(
                                            fontSize: 13.5, fontWeight: FontWeight.bold)),
                                  ),
                                  Text(
                                    Formatters.formatCurrency(order.total),
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.clay600),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                order.paymentMethodText,
                                style: const TextStyle(fontSize: 12, color: AppColors.mute),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTransitions(OrderModel order) {
    final options = AdminOrderProvider.nextStatuses(order.status);

    if (options.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.sand100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          order.status.toUpperCase() == 'COMPLETED'
              ? 'Đơn đã hoàn thành — không chuyển trạng thái được nữa.'
              : 'Đơn đã huỷ — không chuyển trạng thái được nữa.',
          style: const TextStyle(fontSize: 12, color: AppColors.mute, height: 1.35),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chuyển sang:',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.mute),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((next) {
            final isCancel = next == 'CANCELLED';
            return ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isCancel ? Colors.red.shade50 : AppColors.clay500,
                foregroundColor: isCancel ? Colors.red.shade700 : Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              onPressed: () => _changeStatus(next),
              child: Text(
                AdminOrderProvider.statusLabel(next),
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.mute)),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: const TextStyle(fontSize: 12.5, color: AppColors.ink, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _money(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.mute)),
          ),
          Text(
            Formatters.formatCurrency(amount),
            style: const TextStyle(fontSize: 12.5, color: AppColors.ink),
          ),
        ],
      ),
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.sand200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.mute, letterSpacing: 0.8),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
