import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/store.dart';
import '../../providers/admin/admin_store_provider.dart';
import 'admin_store_form_screen.dart';
import 'admin_widgets.dart';

/// Danh sách cửa hàng cho admin: thêm / sửa / xoá / ẩn-hiện chi nhánh.
class AdminStoresScreen extends StatefulWidget {
  const AdminStoresScreen({super.key});

  @override
  State<AdminStoresScreen> createState() => _AdminStoresScreenState();
}

class _AdminStoresScreenState extends State<AdminStoresScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminStoreProvider>().fetchStores();
    });
  }

  Future<void> _openForm([StoreModel? store]) async {
    // Provider tự refetch sau khi tạo/sửa thành công nên không cần xử lý kết quả trả về.
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AdminStoreFormScreen(store: store)),
    );
  }

  Future<void> _confirmDelete(StoreModel store) async {
    final ok = await adminConfirm(
      context,
      title: 'Xoá cửa hàng?',
      message: 'Xoá "${store.storeName}" khỏi hệ thống? Khách sẽ không còn thấy chi nhánh này.',
    );
    if (!ok || !mounted) return;
    final provider = context.read<AdminStoreProvider>();
    await adminRun(context, provider, () => provider.deleteStore(store.id),
        successMessage: 'Đã xoá cửa hàng.');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminStoreProvider>();

    return Scaffold(
      backgroundColor: AppColors.sand50,
      appBar: AppBar(title: const Text('CỬA HÀNG')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.clay500,
        foregroundColor: Colors.white,
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Thêm'),
      ),
      body: Column(
        children: [
          AdminErrorBar(message: provider.errorMessage, onDismiss: provider.clearError),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => provider.fetchStores(page: provider.pageData.page),
              color: AppColors.clay500,
              child: (provider.isLoading && provider.stores.isEmpty)
                  ? const Center(child: CircularProgressIndicator(color: AppColors.clay500))
                  : provider.stores.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 120),
                            AdminEmptyState(
                              icon: Icons.store_mall_directory_outlined,
                              title: 'Chưa có cửa hàng',
                              subtitle: 'Bấm "Thêm" để tạo chi nhánh đầu tiên.',
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.only(top: 8, bottom: 88),
                          itemCount: provider.stores.length + 1,
                          separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.sand200),
                          itemBuilder: (context, index) {
                            if (index == provider.stores.length) {
                              final p = provider.pageData;
                              return AdminPagingBar(
                                page: p.page,
                                totalPages: p.totalPages,
                                totalElements: p.totalElements,
                                isLoading: provider.isLoading,
                                onGoToPage: (pg) => provider.fetchStores(page: pg),
                              );
                            }
                            final s = provider.stores[index];
                            final active = s.status.toUpperCase() == 'ACTIVE';
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              leading: const CircleAvatar(
                                backgroundColor: AppColors.clay50,
                                child: Icon(Icons.store_outlined, color: AppColors.clay600),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(s.storeName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  ),
                                  const SizedBox(width: 8),
                                  AdminStatusChip(active ? 'Hiển thị' : 'Ẩn', tone: active ? 1 : 0),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(s.address,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12.5, color: AppColors.mute)),
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (v) {
                                  if (v == 'edit') {
                                    _openForm(s);
                                  } else if (v == 'delete') {
                                    _confirmDelete(s);
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(value: 'edit', child: Text('Sửa')),
                                  PopupMenuItem(value: 'delete', child: Text('Xoá')),
                                ],
                              ),
                              onTap: () => _openForm(s),
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
