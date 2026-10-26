import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/admin_models.dart';
import '../../models/collection.dart';
import '../../models/product.dart';
import '../../providers/admin/admin_collection_provider.dart';
import 'admin_collection_form_screen.dart';
import 'admin_widgets.dart';

class AdminCollectionsScreen extends StatefulWidget {
  const AdminCollectionsScreen({super.key});

  @override
  State<AdminCollectionsScreen> createState() => _AdminCollectionsScreenState();
}

class _AdminCollectionsScreenState extends State<AdminCollectionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminCollectionProvider>().fetchCollections();
    });
  }

  Future<void> _openForm({String? collectionId}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AdminCollectionFormScreen(collectionId: collectionId)),
    );
    if (!mounted) return;
    final provider = context.read<AdminCollectionProvider>();
    await provider.fetchCollections(page: provider.pageData.page);
  }

  Future<void> _togglePublish(CollectionModel collection) async {
    final provider = context.read<AdminCollectionProvider>();
    final version = collection.version;

    if (version == null) {
      adminToast(context, 'Thiếu số hiệu phiên bản, hãy tải lại danh sách.', success: false);
      return;
    }

    if (collection.isActive) {
      await adminRun(
        context,
        provider,
        () => provider.hide(collection.id, expectedVersion: version),
        successMessage: 'Đã ẩn bộ sưu tập.',
      );
      return;
    }

    if (!collection.hasCover) {
      adminToast(
        context,
        'Phải có ảnh bìa mới cho bộ sưu tập hiện ra shop. Mở bộ này để tải ảnh bìa.',
        success: false,
      );
      return;
    }

    await adminRun(
      context,
      provider,
      () => provider.publish(collection.id, expectedVersion: version),
      successMessage: 'Bộ sưu tập đã hiện ở shop.',
    );
  }

  Future<void> _delete(CollectionModel collection) async {
    final provider = context.read<AdminCollectionProvider>();
    final version = collection.version;
    if (version == null) return;

    final ok = await adminConfirm(
      context,
      title: 'Xoá ${collection.collectionName}?',
      message: 'Bộ sưu tập sẽ không còn ở shop. Các sản phẩm bên trong KHÔNG bị xoá, chỉ bỏ ra '
          'khỏi bộ này.',
    );
    if (!ok || !mounted) return;

    await adminRun(
      context,
      provider,
      () => provider.deleteCollection(collection.id, expectedVersion: version),
      successMessage: 'Đã xoá bộ sưu tập.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminCollectionProvider>();

    return Scaffold(
      backgroundColor: AppColors.sand50,
      appBar: AppBar(title: const Text('BỘ SƯU TẬP')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.clay500,
        onPressed: () => _openForm(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          AdminErrorBar(message: provider.errorMessage, onDismiss: provider.clearError),
          if (provider.isLoading && provider.pageData.isEmpty)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (provider.collections.isEmpty)
            const Expanded(
              child: AdminEmptyState(
                icon: Icons.collections_bookmark_outlined,
                title: 'Chưa có bộ sưu tập nào',
                subtitle: 'Mỗi bộ cần ít nhất một sản phẩm, nên hãy tạo sản phẩm trước.',
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => provider.fetchCollections(page: provider.pageData.page),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.collections.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _collectionCard(provider.collections[index]),
                ),
              ),
            ),
          AdminPagingBar(
            page: provider.pageData.page,
            totalPages: provider.pageData.totalPages,
            totalElements: provider.pageData.totalElements,
            isLoading: provider.isLoading,
            onGoToPage: (p) => provider.fetchCollections(page: p),
          ),
        ],
      ),
    );
  }

  Widget _collectionCard(CollectionModel collection) {
    final path = Product.resolveImage(collection.coverImageUrl);
    final isNetwork = path.startsWith('http');
    final placeholder = Container(
      color: AppColors.sand100,
      alignment: Alignment.center,
      child: const Icon(Icons.image_outlined, size: 20, color: AppColors.sand300),
    );

    return InkWell(
      onTap: () => _openForm(collectionId: collection.id),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.sand200),
        ),
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 70,
                height: 56,
                child: !collection.hasCover
                    ? placeholder
                    : (isNetwork
                        ? Image.network(path, fit: BoxFit.cover, errorBuilder: (_, _, _) => placeholder)
                        : Image.asset(path, fit: BoxFit.cover, errorBuilder: (_, _, _) => placeholder)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    collection.collectionName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.ink),
                  ),
                  const SizedBox(height: 3),
                  Text('/${collection.slug}',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.mute)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      AdminStatusChip(
                        RecordStatusX.label(collection.status),
                        tone: collection.isActive ? 1 : 2,
                      ),
                      if (!collection.hasCover) const AdminStatusChip('CHƯA CÓ ẢNH BÌA', tone: 3),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20, color: AppColors.mute),
              onSelected: (value) {
                switch (value) {
                  case 'toggle':
                    _togglePublish(collection);
                  case 'edit':
                    _openForm(collectionId: collection.id);
                  case 'delete':
                    _delete(collection);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'toggle',
                  child: Text(collection.isActive ? 'Ẩn khỏi shop' : 'Cho hiện ở shop'),
                ),
                const PopupMenuItem(value: 'edit', child: Text('Sửa nội dung')),
                const PopupMenuItem(value: 'delete', child: Text('Xoá bộ sưu tập')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
