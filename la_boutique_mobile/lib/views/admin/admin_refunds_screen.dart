import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/admin/admin_payment_provider.dart';
import 'admin_widgets.dart';

/// Danh sách hoàn tiền cho admin. Đợt này BE chỉ sinh trạng thái PENDING ("cần hoàn").
class AdminRefundsScreen extends StatefulWidget {
  const AdminRefundsScreen({super.key});

  @override
  State<AdminRefundsScreen> createState() => _AdminRefundsScreenState();
}

class _AdminRefundsScreenState extends State<AdminRefundsScreen> {
  static const _filters = <String, String?>{
    'Tất cả': null,
    'Cần hoàn': 'PENDING',
    'Đã hoàn': 'REFUNDED',
    'Từ chối': 'REJECTED',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminPaymentProvider>().fetchRefunds();
    });
  }

  int _tone(String status) {
    switch (status.toUpperCase()) {
      case 'REFUNDED':
        return 1; // xanh
      case 'REJECTED':
        return 3; // đỏ
      default:
        return 2; // vàng (PENDING)
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminPaymentProvider>();

    return Scaffold(
      backgroundColor: AppColors.sand50,
      appBar: AppBar(title: const Text('HOÀN TIỀN')),
      body: Column(
        children: [
          AdminErrorBar(message: provider.errorMessage, onDismiss: provider.clearError),
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: _filters.entries.map((e) {
                final selected = provider.statusFilter == e.value;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(e.key),
                    selected: selected,
                    selectedColor: AppColors.clay500,
                    labelStyle: TextStyle(
                      fontSize: 12.5,
                      color: selected ? Colors.white : AppColors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) => provider.setStatusFilter(e.value),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => provider.fetchRefunds(page: provider.refundsPage.page),
              color: AppColors.clay500,
              child: (provider.isLoading && provider.refunds.isEmpty)
                  ? const Center(child: CircularProgressIndicator(color: AppColors.clay500))
                  : provider.refunds.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 120),
                            AdminEmptyState(
                              icon: Icons.account_balance_wallet_outlined,
                              title: 'Không có khoản hoàn tiền',
                              subtitle: 'Hoàn tiền phát sinh khi một đơn đã thanh toán VNPay bị huỷ.',
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.only(top: 4, bottom: 16),
                          itemCount: provider.refunds.length + 1,
                          separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.sand200),
                          itemBuilder: (context, index) {
                            if (index == provider.refunds.length) {
                              final p = provider.refundsPage;
                              return AdminPagingBar(
                                page: p.page,
                                totalPages: p.totalPages,
                                totalElements: p.totalElements,
                                isLoading: provider.isLoading,
                                onGoToPage: (pg) => provider.fetchRefunds(page: pg),
                              );
                            }
                            final r = provider.refunds[index];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text('#${r.orderNumber}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  ),
                                  const SizedBox(width: 8),
                                  AdminStatusChip(r.statusText, tone: _tone(r.status)),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  '${r.customerName.isEmpty ? 'Khách' : r.customerName}'
                                  '${r.createdAt != null ? ' · ${Formatters.formatDate(r.createdAt!)}' : ''}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.mute),
                                ),
                              ),
                              trailing: Text(
                                Formatters.formatCurrency(r.amount),
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.clay600),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
