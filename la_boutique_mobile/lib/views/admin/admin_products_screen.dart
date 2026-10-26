import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/admin_models.dart';
import '../../models/product.dart';
import '../../providers/admin/admin_category_provider.dart';
import '../../providers/admin/admin_product_provider.dart';
import 'admin_product_form_screen.dart';
import 'admin_widgets.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProductProvider>().fetchProducts();
      context.read<AdminCategoryProvider>().fetchCategories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openForm({String? productId}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AdminProductFormScreen(productId: productId)),
    );
    if (!mounted) return;
    await context.read<AdminProductProvider>().fetchProducts(
          page: context.read<AdminProductProvider>().pageData.page,
        );
  }

  Future<void> _delete(AdminProduct product) async {
    final provider = context.read<AdminProductProvider>();
    final ok = await adminConfirm(
      context,
      title: 'Xoá ${product.name}?',
      message: 'Sản phẩm sẽ không còn hiện ở shop. Đơn hàng cũ vẫn giữ nguyên thông tin đã chụp '
          'lúc đặt (tên, ảnh, giá), nên hoá đơn cũ không bị ảnh hưởng.',
    );
    if (!ok || !mounted) return;

    await adminRun(
      context,
      provider,
      () => provider.deleteProduct(product.id),
      successMessage: 'Đã xoá sản phẩm.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProductProvider>();
    final products = provider.products;

    return Scaffold(
      backgroundColor: AppColors.sand50,
      appBar: AppBar(title: const Text('SẢN PHẨM')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.clay500,
        onPressed: () => _openForm(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          AdminErrorBar(message: provider.errorMessage, onDismiss: provider.clearError),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: provider.setQuery,
              decoration: InputDecoration(
                hintText: 'Tìm theo tên hoặc SKU (trong trang này)',
                prefixIcon: const Icon(Icons.search, size: 19),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          if (provider.isLoading && provider.pageData.isEmpty)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (products.isEmpty)
            const Expanded(
              child: AdminEmptyState(
                icon: Icons.inventory_2_outlined,
                title: 'Không có sản phẩm nào',
                subtitle: 'Bấm dấu + để thêm sản phẩm. Cần có danh mục trước khi thêm.',
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => provider.fetchProducts(page: provider.pageData.page),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: products.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _productCard(products[index]),
                ),
              ),
            ),
          AdminPagingBar(
            page: provider.pageData.page,
            totalPages: provider.pageData.totalPages,
            totalElements: provider.pageData.totalElements,
            isLoading: provider.isLoading,
            onGoToPage: (p) => provider.fetchProducts(page: p),
          ),
        ],
      ),
    );
  }

  Widget _productCard(AdminProduct product) {
    final imagePath = Product.resolveImage(product.thumbnail);
    final isNetwork = imagePath.startsWith('http');
    final placeholder = Container(
      color: AppColors.sand100,
      alignment: Alignment.center,
      child: const Icon(Icons.image_outlined, size: 20, color: AppColors.sand300),
    );

    return InkWell(
      onTap: () => _openForm(productId: product.id),
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
                width: 56,
                height: 70,
                child: (product.thumbnail == null || product.thumbnail!.isEmpty)
                    ? placeholder
                    : (isNetwork
                        ? Image.network(imagePath, fit: BoxFit.cover, errorBuilder: (_, _, _) => placeholder)
                        : Image.asset(imagePath, fit: BoxFit.cover, errorBuilder: (_, _, _) => placeholder)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.ink, height: 1.25),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'SKU ${product.sku.isEmpty ? '—' : product.sku} · ${product.categoryName ?? 'chưa có danh mục'}',
                    style: const TextStyle(fontSize: 11.5, color: AppColors.mute),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    Formatters.formatCurrency(product.price),
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.clay600),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      AdminStatusChip(product.statusText, tone: product.isActive ? 1 : 2),
                      if (product.thumbnail == null || product.thumbnail!.isEmpty)
                        const AdminStatusChip('CHƯA CÓ ẢNH BÌA', tone: 3),
                      if (product.isFeatured) const AdminStatusChip('NỔI BẬT'),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 19),
              color: Colors.red.shade600,
              onPressed: () => _delete(product),
            ),
          ],
        ),
      ),
    );
  }
}
