import 'package:flutter/foundation.dart';
import '../core/constants/api_constants.dart';
import '../data/mock_data.dart';
import '../models/category_model.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class ProductProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Product> _products = [];
  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  String _selectedCategory = 'all'; // 'all', 'sunset', 'ao', 'quan'
  String _searchQuery = '';
  String _sortBy = 'newest'; // 'newest', 'price_asc', 'price_desc'
  double? _minPrice;
  double? _maxPrice;
  String? _selectedSize; // null or 'S', 'M', 'L'
  String? _selectedCollection; // null or 'SUNSET', 'REGULAR'
  String? _selectedMaterial; // null or một từ khóa trong materialOptions
  final Set<String> _wishlistIds = {};

  /// Các từ khóa chất liệu để lọc. Vì field `material` là mô tả dài (vd "Lụa tơ tằm & linen"),
  /// ta lọc theo "có chứa từ khóa" chứ không so khớp tuyệt đối.
  static const List<String> materialOptions = ['Lụa', 'Linen', 'Cotton', 'Đũi', 'Voan', 'Xô'];

  List<Product> get allProducts => _products;
  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  String get sortBy => _sortBy;
  double? get minPrice => _minPrice;
  double? get maxPrice => _maxPrice;
  String? get selectedSize => _selectedSize;
  String? get selectedCollection => _selectedCollection;
  String? get selectedMaterial => _selectedMaterial;
  Set<String> get wishlistIds => _wishlistIds;

  ProductProvider() {
    // Start with mock products for instant UI display
    _products = List.from(MockData.initialProducts);
    _initData();
  }

  Future<void> _initData() async {
    await fetchCategories();
    await fetchProducts();
  }

  bool isFavorite(String productId) => _wishlistIds.contains(productId);

  void toggleFavorite(String productId) {
    if (_wishlistIds.contains(productId)) {
      _wishlistIds.remove(productId);
    } else {
      _wishlistIds.add(productId);
    }
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
    fetchProducts();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSortBy(String sort) {
    _sortBy = sort;
    notifyListeners();
    fetchProducts();
  }

  void setPriceRange(double? min, double? max) {
    _minPrice = min;
    _maxPrice = max;
    notifyListeners();
    fetchProducts();
  }

  void setSizeFilter(String? size) {
    _selectedSize = size;
    notifyListeners();
  }

  void setCollectionFilter(String? collection) {
    _selectedCollection = collection;
    notifyListeners();
  }

  void setMaterialFilter(String? material) {
    _selectedMaterial = material;
    notifyListeners();
  }

  void setMultiFilters({
    String? category,
    double? minPrice,
    double? maxPrice,
    String? size,
    String? collection,
    String? material,
  }) {
    if (category != null) _selectedCategory = category;
    _minPrice = minPrice;
    _maxPrice = maxPrice;
    _selectedSize = size;
    _selectedCollection = collection;
    _selectedMaterial = material;
    notifyListeners();
    fetchProducts();
  }

  void clearFilters() {
    _selectedCategory = 'all';
    _searchQuery = '';
    _sortBy = 'newest';
    _minPrice = null;
    _maxPrice = null;
    _selectedSize = null;
    _selectedCollection = null;
    _selectedMaterial = null;
    notifyListeners();
    fetchProducts();
  }

  Future<void> fetchCategories() async {
    try {
      final result = await _api.get(
        ApiConstants.categories,
        queryParams: {'size': 50, 'sort': 'createdAt,desc'},
        requiresAuth: false,
      );

      if (result != null && result is Map<String, dynamic> && result['content'] is List) {
        final list = (result['content'] as List)
            .map((c) => CategoryModel.fromJson(c as Map<String, dynamic>))
            .toList();
        if (list.isNotEmpty) {
          _categories = list;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('[ProductProvider] fetchCategories fallback: $e');
    }
  }

  Future<void> fetchProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      final queryParams = <String, dynamic>{
        'size': 50,
      };

      if (_selectedCategory == 'sunset') {
        queryParams['collection'] = 'sunset';
      } else if (_selectedCategory != 'all' && _selectedCategory.isNotEmpty) {
        queryParams['category'] = _selectedCategory;
      }

      if (_searchQuery.trim().isNotEmpty) {
        queryParams['search'] = _searchQuery.trim();
      }

      if (_minPrice != null && _minPrice! > 0) {
        queryParams['minPrice'] = _minPrice!.toInt();
      }
      if (_maxPrice != null && _maxPrice! > 0) {
        queryParams['maxPrice'] = _maxPrice!.toInt();
      }

      if (_sortBy == 'price_asc') {
        queryParams['sort'] = 'price,asc';
      } else if (_sortBy == 'price_desc') {
        queryParams['sort'] = 'price,desc';
      } else {
        queryParams['sort'] = 'createdAt,desc';
      }

      final result = await _api.get(
        ApiConstants.products,
        queryParams: queryParams,
        requiresAuth: false,
      );

      if (result != null && result is Map<String, dynamic> && result['content'] is List) {
        final list = (result['content'] as List)
            .map((p) => Product.fromJson(p as Map<String, dynamic>))
            .toList();

        if (list.isNotEmpty) {
          _products = list;
        }
      }
    } catch (e) {
      debugPrint('[ProductProvider] fetchProducts BE offline, using local data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Product?> fetchProductDetail(String idOrSlug) async {
    try {
      final isUuid = idOrSlug.length > 20 && idOrSlug.contains('-');
      final endpoint = isUuid
          ? ApiConstants.productById(idOrSlug)
          : ApiConstants.productBySlug(idOrSlug);

      final result = await _api.get(endpoint, requiresAuth: false);
      if (result != null && result is Map<String, dynamic>) {
        return Product.fromJson(result);
      }
    } catch (e) {
      debugPrint('[ProductProvider] fetchProductDetail error: $e');
    }

    // Fallback to in-memory product
    try {
      return _products.firstWhere((p) => p.id == idOrSlug || p.slug == idOrSlug);
    } catch (_) {
      return null;
    }
  }

  List<Product> get filteredProducts {
    List<Product> list = List.from(_products);

    // 1. Filter by Category / Collection
    if (_selectedCategory == 'sunset') {
      list = list.where((p) => p.collection.toUpperCase() == 'SUNSET').toList();
    } else if (_selectedCategory != 'all' && _selectedCategory.isNotEmpty) {
      list = list.where((p) => p.type.toLowerCase() == _selectedCategory.toLowerCase()).toList();
    }

    // 2. Filter by Search Query
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((p) {
        return p.name.toLowerCase().contains(q) ||
            (p.description?.toLowerCase().contains(q) ?? false) ||
            (p.tag?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    // 3. Filter by Collection (if specifically set from Multi-Filter)
    if (_selectedCollection != null && _selectedCollection != 'all') {
      list = list.where((p) => p.collection.toUpperCase() == _selectedCollection!.toUpperCase()).toList();
    }

    // 4. Filter by Size
    if (_selectedSize != null && _selectedSize != 'all') {
      list = list.where((p) => p.isSizeInStock(_selectedSize!)).toList();
    }

    // 4b. Filter by Material (khớp theo từ khóa chứa trong mô tả chất liệu)
    if (_selectedMaterial != null && _selectedMaterial!.isNotEmpty) {
      final m = _selectedMaterial!.toLowerCase();
      list = list.where((p) => p.material?.toLowerCase().contains(m) ?? false).toList();
    }

    // 5. Filter by Price Range
    if (_minPrice != null) {
      list = list.where((p) => p.price >= _minPrice!).toList();
    }
    if (_maxPrice != null) {
      list = list.where((p) => p.price <= _maxPrice!).toList();
    }

    // 6. Sort
    if (_sortBy == 'price_asc') {
      list.sort((a, b) => a.price.compareTo(b.price));
    } else if (_sortBy == 'price_desc') {
      list.sort((a, b) => b.price.compareTo(a.price));
    }

    return list;
  }

  List<Product> get sunsetCollection {
    return _products.where((p) => p.collection.toUpperCase() == 'SUNSET').toList();
  }

  List<Product> get featuredProducts {
    return _products.where((p) => p.isFeatured || (p.tag != null)).toList();
  }

  Product? getProductById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
