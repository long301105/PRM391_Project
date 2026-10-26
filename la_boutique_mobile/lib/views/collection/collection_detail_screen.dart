import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/collection.dart';
import '../../models/product.dart';
import '../../providers/collection_provider.dart';
import '../../providers/product_provider.dart';
import '../product/product_detail_screen.dart';

class CollectionDetailScreen extends StatefulWidget {
  final CollectionModel collection;

  const CollectionDetailScreen({super.key, required this.collection});

  @override
  State<CollectionDetailScreen> createState() => _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends State<CollectionDetailScreen> {
  CollectionModel? _detail;
  bool _isLoading = true;
  bool _isOpeningProduct = false;
  int _page = 0;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _detail = context.read<CollectionProvider>().cached(widget.collection.slug);
    _load();
  }

  Future<void> _load({int? page}) async {
    setState(() => _isLoading = true);
    final target = page ?? _page;
    final result = await context
        .read<CollectionProvider>()
        .fetchCollectionBySlug(widget.collection.slug, page: target, size: _pageSize);

    if (!mounted) return;
    setState(() {
      if (result != null) {
        _detail = result;
        _page = target;
      }
      _isLoading = false;
    });
  }

  Future<void> _openProduct(CollectionProductModel item) async {
    final key = item.productSlug?.isNotEmpty == true ? item.productSlug! : item.productId;
    setState(() => _isOpeningProduct = true);

    final product = await context.read<ProductProvider>().fetchProductDetail(key);

    if (!mounted) return;
    setState(() => _isOpeningProduct = false);

    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không mở được sản phẩm này. Vui lòng thử lại.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail ?? widget.collection;
    final products = detail.products;
    final hasMorePages = detail.totalProducts > (_page + 1) * _pageSize;

    return Scaffold(
      backgroundColor: AppColors.sand50,
      appBar: AppBar(title: Text(detail.collectionName.toUpperCase())),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => _load(page: 0),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildCover(detail)),
                if (_isLoading && products.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (products.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.sand300),
                          const SizedBox(height: 12),
                          Text(
                            context.read<CollectionProvider>().errorMessage ??
                                'Bộ sưu tập này chưa có sản phẩm nào đang bán.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13, color: AppColors.mute, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        '${detail.totalProducts} sản phẩm trong bộ',
                        style: const TextStyle(fontSize: 12.5, color: AppColors.mute),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 14,
                        childAspectRatio: 0.62,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _CollectionProductTile(
                          item: products[index],
                          onTap: () => _openProduct(products[index]),
                        ),
                        childCount: products.length,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: _page > 0 && !_isLoading ? () => _load(page: _page - 1) : null,
                            child: const Text('← Trang trước'),
                          ),
                          Text('Trang ${_page + 1}', style: const TextStyle(fontSize: 12.5, color: AppColors.mute)),
                          TextButton(
                            onPressed: hasMorePages && !_isLoading ? () => _load(page: _page + 1) : null,
                            child: const Text('Trang sau →'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_isOpeningProduct)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x33000000),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCover(CollectionModel detail) {
    if (!detail.hasCover) return const SizedBox(height: 8);

    final imagePath = Product.resolveImage(detail.coverImageUrl);
    final isNetwork = imagePath.startsWith('http');
    final placeholder = Container(color: AppColors.sand100);

    return SizedBox(
      height: 200,
      width: double.infinity,
      child: isNetwork
          ? Image.network(imagePath, fit: BoxFit.cover, errorBuilder: (_, _, _) => placeholder)
          : Image.asset(imagePath, fit: BoxFit.cover, errorBuilder: (_, _, _) => placeholder),
    );
  }
}

class _CollectionProductTile extends StatelessWidget {
  final CollectionProductModel item;
  final VoidCallback onTap;

  const _CollectionProductTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final imagePath = Product.resolveImage(item.thumbnail);
    final isNetwork = imagePath.startsWith('http');
    final placeholder = Container(
      color: AppColors.sand100,
      alignment: Alignment.center,
      child: const Icon(Icons.image_outlined, color: AppColors.sand300),
    );

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  SizedBox.expand(
                    child: isNetwork
                        ? Image.network(imagePath, fit: BoxFit.cover, errorBuilder: (_, _, _) => placeholder)
                        : Image.asset(imagePath, fit: BoxFit.cover, errorBuilder: (_, _, _) => placeholder),
                  ),
                  if (item.tag != null && item.tag!.trim().isNotEmpty)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.clay500,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item.tag!.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.productName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink, height: 1.25),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              if (item.price != null)
                Text(
                  Formatters.formatCurrency(item.price!),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.clay600),
                ),
              if (item.hasDiscount) ...[
                const SizedBox(width: 6),
                Text(
                  Formatters.formatCurrency(item.originalPrice!),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.mute,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
