import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/order.dart';
import '../../providers/admin/admin_order_provider.dart';
import 'admin_order_detail_screen.dart';
import 'admin_widgets.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final TextEditingController _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminOrderProvider>().fetchOrders();
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _lookupByCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    final provider = context.read<AdminOrderProvider>();
    final order = await provider.fetchOrderByNumber(code);
    if (!mounted) return;

    if (order == null) {
      adminToast(context, provider.errorMessage ?? 'Không tìm thấy đơn $code.', success: false);
      return;
    }

    await _openDetail(order.id, preloaded: order);
  }

  Future<void> _openDetail(String orderId, {OrderModel? preloaded}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminOrderDetailScreen(orderId: orderId, preloaded: preloaded),
      ),
    );
    if (!mounted) return;
    final provider = context.read<AdminOrderProvider>();
    await provider.fetchOrders(page: provider.pageData.page);
  }

  static int _tone(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return 1;
      case 'CANCELLED':
        return 3;
      case 'PENDING':
        return 2;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminOrderProvider>();

    return Scaffold(
      backgroundColor: AppColors.sand50,
      appBar: AppBar(title: const Text('ĐƠN HÀNG')),
      body: Column(
        children: [
          AdminErrorBar(message: provider.errorMessage, onDismiss: provider.clearError),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    onSubmitted: (_) => _lookupByCode(),
                    decoration: InputDecoration(
                      hintText: 'Tra theo mã đơn',
                      prefixIcon: const Icon(Icons.qr_code_2, size: 19),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: provider.isLoading ? null : _lookupByCode,
                  child: const Text('TRA'),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _filterChip(provider, null, 'Tất cả'),
                ...AdminOrderProvider.statuses.map(
                  (s) => _filterChip(provider, s, AdminOrderProvider.statusLabel(s)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          if (provider.isLoading && provider.pageData.isEmpty)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (provider.orders.isEmpty)
            const Expanded(
              child: AdminEmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Không có đơn nào',
                subtitle: 'Thử bỏ bộ lọc trạng thái, hoặc chờ khách đặt đơn đầu tiên.',
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => provider.fetchOrders(page: provider.pageData.page),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                  itemCount: provider.orders.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _orderCard(provider.orders[index]),
                ),
              ),
            ),
          AdminPagingBar(
            page: provider.pageData.page,
            totalPages: provider.pageData.totalPages,
            totalElements: provider.pageData.totalElements,
            isLoading: provider.isLoading,
            onGoToPage: (p) => provider.fetchOrders(page: p),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(AdminOrderProvider provider, String? value, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: provider.statusFilter == value,
        onSelected: (_) => provider.setStatusFilter(value),
      ),
    );
  }

  Widget _orderCard(OrderModel order) {
    return InkWell(
      onTap: () => _openDetail(order.id),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.sand200),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '#${order.displayOrderNumber}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.ink),
                  ),
                ),
                AdminStatusChip(order.statusText, tone: _tone(order.status)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              order.customerName.isEmpty ? 'Không có tên người nhận' : order.customerName,
              style: const TextStyle(fontSize: 12.5, color: AppColors.ink),
            ),
            const SizedBox(height: 2),
            Text(
              '${order.totalItems} món · ${order.paymentMethodText}',
              style: const TextStyle(fontSize: 11.5, color: AppColors.mute),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    Formatters.formatDate(order.createdAt),
                    style: const TextStyle(fontSize: 11.5, color: AppColors.mute),
                  ),
                ),
                Text(
                  Formatters.formatCurrency(order.total),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.clay600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
