import 'dart:async';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/api_constants.dart';
import '../../models/collection.dart';
import '../../models/product.dart';
import '../../services/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../cart/cart_screen.dart';
import '../widgets/product_card.dart';
import '../widgets/shimmer_loading.dart';

class ProductListScreen extends StatefulWidget {
  final String? initialCategory;
  final bool isActive;

  const ProductListScreen({super.key, this.initialCategory, this.isActive = true});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _collectionApi = ApiService();
  List<CollectionModel> _publicCollections = const [];
  Timer? _collectionTimer;
  bool _refreshingCollections = false;
  bool _foreground = true;
  bool _initialSelectionPending = true;

  bool get _canRefresh => mounted && widget.isActive && _foreground &&
      (ModalRoute.of(context)?.isCurrent ?? true);

  Future<void> _refreshCollections() async {
    if (!_canRefresh || _refreshingCollections) return;
    _refreshingCollections = true;
    try {
      final fetched = <CollectionModel>[];
      var page = 0;
      var totalPages = 1;
      do {
        final response = await _collectionApi.get(
          ApiConstants.collections,
          queryParams: {'page': page, 'size': 100, 'sort': 'createdAt,desc'},
          requiresAuth: false,
        );
        if (response is! Map<String, dynamic> || response['content'] is! List ||
            response['totalPages'] is! num) {
          throw StateError('Invalid collection page');
        }
        fetched.addAll((response['content'] as List)
            .whereType<Map<String, dynamic>>()
            .map(CollectionModel.fromJson));
        totalPages = (response['totalPages'] as num).toInt();
        page++;
      } while (page < totalPages);
      if (!mounted || !_canRefresh) return;
      final provider = context.read<ProductProvider>();
      setState(() => _publicCollections = fetched);
      if (_initialSelectionPending) {
        _initialSelectionPending = false;
        final initial = widget.initialCategory;
        if (initial == 'sunset') {
          if (fetched.any((item) => item.slug == initial)) {
            provider.selectPublicCollection(initial!);
          } else {
            provider.setCategory('all');
          }
        } else if (initial != null) {
          provider.setCategory(initial);
        }
      }
      final selected = provider.publicCollectionSlug;
      if (selected != null && !fetched.any((item) => item.slug == selected)) {
        provider.setCategory('all');
      }
    } catch (e) {
      debugPrint('[PublicCollections] refresh failed: $e');
    } finally {
      _refreshingCollections = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) _refreshCollections();
  }

  @override
  void didUpdateWidget(covariant ProductListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _refreshCollections());
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshCollections());
    _collectionTimer = Timer.periodic(const Duration(seconds: 15), (_) => _refreshCollections());
  }

  @override
  void dispose() {
    _collectionTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterSheet(BuildContext context, ProductProvider provider) {
    HapticFeedback.lightImpact();
    double? tempMin = provider.minPrice;
    double? tempMax = provider.maxPrice;
    String? tempSize = provider.selectedSize;
    String? tempCollection = provider.selectedCollection;
    String? tempMaterial = provider.selectedMaterial;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.sand300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Bộ Lọc Sản Phẩm',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.ink,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const Divider(height: 20, color: AppColors.sand200),

                    // Section: Mức giá
                    const Text('Khoảng giá', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.ink)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildFilterOptionChip(
                          label: 'Tất cả giá',
                          isSelected: tempMin == null && tempMax == null,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setSheetState(() {
                              tempMin = null;
                              tempMax = null;
                            });
                          },
                        ),
                        _buildFilterOptionChip(
                          label: '< 500.000₫',
                          isSelected: tempMin == null && tempMax == 500000,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setSheetState(() {
                              tempMin = null;
                              tempMax = 500000;
                            });
                          },
                        ),
                        _buildFilterOptionChip(
                          label: '500.000₫ - 1.000.000₫',
                          isSelected: tempMin == 500000 && tempMax == 1000000,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setSheetState(() {
                              tempMin = 500000;
                              tempMax = 1000000;
                            });
                          },
                        ),
                        _buildFilterOptionChip(
                          label: '> 1.000.000₫',
                          isSelected: tempMin == 1000000 && tempMax == null,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setSheetState(() {
                              tempMin = 1000000;
                              tempMax = null;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Section: Kích thước (Size)
                    const Text('Kích thước (Size)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.ink)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildFilterOptionChip(
                          label: 'Tất cả size',
                          isSelected: tempSize == null || tempSize == 'all',
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setSheetState(() => tempSize = null);
                          },
                        ),
                        ...['S', 'M', 'L'].map((size) {
                          return _buildFilterOptionChip(
                            label: 'Size $size',
                            isSelected: tempSize == size,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setSheetState(() => tempSize = (tempSize == size ? null : size));
                            },
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Section: Bộ sưu tập
                    const Text('Bộ sưu tập', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.ink)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildFilterOptionChip(
                          label: 'Tất cả BST',
                          isSelected: tempCollection == null || tempCollection == 'all',
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setSheetState(() => tempCollection = null);
                          },
                        ),
                        ..._publicCollections.map((collection) => _buildFilterOptionChip(
                          label: collection.collectionName,
                          isSelected: tempCollection == collection.slug,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setSheetState(() => tempCollection =
                                tempCollection == collection.slug ? null : collection.slug);
                          },
                        )),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Section: Chất liệu
                    const Text('Chất liệu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.ink)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildFilterOptionChip(
                          label: 'Tất cả chất liệu',
                          isSelected: tempMaterial == null,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setSheetState(() => tempMaterial = null);
                          },
                        ),
                        ...ProductProvider.materialOptions.map((mat) {
                          return _buildFilterOptionChip(
                            label: mat,
                            isSelected: tempMaterial == mat,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setSheetState(() => tempMaterial = (tempMaterial == mat ? null : mat));
                            },
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: AppColors.sand300),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              provider.clearFilters();
                              Navigator.pop(ctx);
                            },
                            child: const Text('Thiết lập lại'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.clay500,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              provider.setMultiFilters(
                                minPrice: tempMin,
                                maxPrice: tempMax,
                                size: tempSize,
                                collection: tempCollection,
                                material: tempMaterial,
                              );
                              Navigator.pop(ctx);
                            },
                            child: const Text('Áp dụng bộ lọc', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterOptionChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.clay500,
      backgroundColor: AppColors.sand100,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.ink,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        fontSize: 12.5,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: isSelected ? AppColors.clay500 : AppColors.sand200),
      ),
      showCheckmark: false,
    );
  }

  String _formatFilterPrice(double? min, double? max) {
    if (min == null && max != null) return '< 500k';
    if (min != null && max != null) return '500k - 1tr';
    if (min != null && max == null) return '> 1tr';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final cart = context.watch<CartProvider>();
    final products = productProvider.filteredProducts;
    final hasPriceFilter = productProvider.minPrice != null || productProvider.maxPrice != null;
    final hasSizeFilter = productProvider.selectedSize != null && productProvider.selectedSize != 'all';
    final hasMaterialFilter = productProvider.selectedMaterial != null && productProvider.selectedMaterial!.isNotEmpty;
    final isAnyFilterActive = hasPriceFilter || hasSizeFilter || hasMaterialFilter;

    final List<Map<String, String>> categories = [
      {'id': 'all', 'label': 'Tất cả'},
      ..._publicCollections.map((item) => {
        'id': 'collection:${item.slug}',
        'label': item.collectionName,
      }),
    ];

    if (productProvider.categories.isNotEmpty) {
      for (final cat in productProvider.categories) {
        categories.add({'id': cat.slug, 'label': cat.name});
      }
    } else {
      categories.addAll([
        {'id': 'ao', 'label': 'Áo thiết kế'},
        {'id': 'quan', 'label': 'Quần & Váy'},
      ]);
    }

    final selectedSlug = productProvider.publicCollectionSlug;
    CollectionModel? selectedCollection;
    for (final collection in _publicCollections) {
      if (collection.slug == selectedSlug) selectedCollection = collection;
    }
    final cover = selectedCollection?.coverImageUrl;

    return Stack(
      children: [
        Positioned.fill(child: ColoredBox(color: AppColors.sand50)),
        if (cover != null && cover.isNotEmpty)
          Positioned(
            top: 0, left: 0, right: 0, height: 340,
            child: IgnorePointer(
              child: ClipRect(
                child: Stack(fit: StackFit.expand, children: [
                  ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                    child: cover.startsWith('http')
                        ? Image.network(cover, fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox.shrink())
                        : Image.asset(Product.resolveImage(cover), fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox.shrink()),
                  ),
                  const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Color(0x85FAF8F5), Color(0xADFAF8F5), AppColors.sand50],
                    stops: [0, 0.55, 1],
                  ))),
                ]),
              ),
            ),
          ),
        Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('LA BOUTIQUE VN'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_bag_outlined),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CartScreen()),
                  );
                },
              ),
              if (cart.itemCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.clay500,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '${cart.itemCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar & Sort
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.sand200.withValues(alpha: 0.8)),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => productProvider.setSearchQuery(val),
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm đầm, áo yếm, chân váy...',
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.mute, size: 20),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  productProvider.setSearchQuery('');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.sand200.withValues(alpha: 0.8)),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: const Icon(Icons.tune_rounded, color: AppColors.ink, size: 20),
                  ),
                  tooltip: 'Sắp xếp',
                  initialValue: productProvider.sortBy,
                  onSelected: (val) => productProvider.setSortBy(val),
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'newest', child: Text('Mới nhất')),
                    const PopupMenuItem(value: 'price_asc', child: Text('Giá: Thấp đến Cao')),
                    const PopupMenuItem(value: 'price_desc', child: Text('Giá: Cao đến Thấp')),
                  ],
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showFilterSheet(context, productProvider),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isAnyFilterActive ? AppColors.clay500 : AppColors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isAnyFilterActive ? AppColors.clay500 : AppColors.sand200.withValues(alpha: 0.8),
                      ),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: Icon(
                      Icons.filter_list_rounded,
                      color: isAnyFilterActive ? Colors.white : AppColors.ink,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Category Chips Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: categories.map((cat) {
                final id = cat['id']!;
                final isCollection = id.startsWith('collection:');
                final isSelected = isCollection
                    ? productProvider.publicCollectionSlug == id.substring('collection:'.length)
                    : productProvider.publicCollectionSlug == null && productProvider.selectedCategory == id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat['label']!),
                    selected: isSelected,
                    onSelected: (_) {
                      if (isCollection) {
                        productProvider.selectPublicCollection(id.substring('collection:'.length));
                      } else {
                        productProvider.setCategory(id);
                      }
                    },
                    selectedColor: AppColors.clay500,
                    backgroundColor: AppColors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.ink,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? AppColors.clay500 : AppColors.sand200,
                        width: 0.8,
                      ),
                    ),
                    showCheckmark: false,
                  ),
                );
              }).toList(),
            ),
          ),

          // Active Filter Chips Row if any
          if (isAnyFilterActive)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  if (hasPriceFilter)
                    _buildActiveTag(
                      label: 'Giá: ${_formatFilterPrice(productProvider.minPrice, productProvider.maxPrice)}',
                      onRemove: () {
                        HapticFeedback.lightImpact();
                        productProvider.setPriceRange(null, null);
                      },
                    ),
                  if (hasSizeFilter)
                    _buildActiveTag(
                      label: 'Size: ${productProvider.selectedSize}',
                      onRemove: () {
                        HapticFeedback.lightImpact();
                        productProvider.setSizeFilter(null);
                      },
                    ),
                  if (hasMaterialFilter)
                    _buildActiveTag(
                      label: 'Chất liệu: ${productProvider.selectedMaterial}',
                      onRemove: () {
                        HapticFeedback.lightImpact();
                        productProvider.setMaterialFilter(null);
                      },
                    ),
                  TextButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      productProvider.clearFilters();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Xóa tất cả', style: TextStyle(fontSize: 11.5, color: Colors.red)),
                  ),
                ],
              ),
            ),

          // Product Count Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${products.length} thiết kế',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.mute, fontWeight: FontWeight.w500),
                ),
                Text(
                  productProvider.sortBy == 'price_asc'
                      ? 'Giá: Thấp → Cao'
                      : (productProvider.sortBy == 'price_desc' ? 'Giá: Cao → Thấp' : 'Mới nhất'),
                  style: const TextStyle(fontSize: 11.5, color: AppColors.clay600, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          // Product Grid or Shimmer Loading
          Expanded(
            child: productProvider.isLoading
                ? GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.57,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 14,
                    ),
                    itemCount: 6,
                    itemBuilder: (context, index) => const ProductCardSkeleton(),
                  )
                : products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off_rounded, size: 56, color: AppColors.sand300),
                            const SizedBox(height: 12),
                            const Text(
                              'Không tìm thấy sản phẩm phù hợp',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Thử tìm từ khóa khác hoặc xóa bộ lọc',
                              style: TextStyle(fontSize: 12, color: AppColors.mute),
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                _searchController.clear();
                                productProvider.clearFilters();
                              },
                              child: const Text('Xem tất cả sản phẩm'),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.57,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 14,
                        ),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          return ProductCard(
                            product: products[index],
                            heroPrefix: 'list',
                          );
                        },
                      ),
          ),
        ],
      ),
        ),
      ],
    );
  }

  Widget _buildActiveTag({required String label, required VoidCallback onRemove}) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.clay100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11.5, color: AppColors.clay700, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 14, color: AppColors.clay700),
          ),
        ],
      ),
    );
  }
}
