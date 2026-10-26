class ProductVariant {
  final String size;
  final int stockQuantity;

  ProductVariant({
    required this.size,
    required this.stockQuantity,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      size: (json['size'] ?? '') as String,
      stockQuantity: (json['stockQuantity'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'size': size,
      'stockQuantity': stockQuantity,
    };
  }
}

class Product {
  final String id;
  final String name;
  final String slug;
  final String sku;
  final double price;
  final double? originalPrice;
  final String type; // Category slug e.g. 'ao' or 'quan'
  final bool isSummer;
  final bool isFeatured;
  final String collection; // 'SUNSET' or 'REGULAR'
  final String img;
  final List<String> gallery;
  final List<ProductVariant> variants;
  final String? tag;
  final String? description;
  final String? material;
  final String? careInstructions;
  final String? categoryId;
  final String? categoryName;
  final String? categorySlug;

  Product({
    required this.id,
    required this.name,
    required this.slug,
    this.sku = '',
    required this.price,
    this.originalPrice,
    required this.type,
    this.isSummer = false,
    this.isFeatured = false,
    required this.collection,
    required this.img,
    required this.gallery,
    this.variants = const [],
    this.tag,
    this.description,
    this.material,
    this.careInstructions,
    this.categoryId,
    this.categoryName,
    this.categorySlug,
  });

  int get discountPercentage {
    if (originalPrice == null || originalPrice! <= price) return 0;
    return (((originalPrice! - price) / originalPrice!) * 100).round();
  }

  int getStockForSize(String size) {
    if (variants.isEmpty) return 99; // Default fallback if no variants specified
    final v = variants.firstWhere(
      (element) => element.size.toUpperCase() == size.toUpperCase(),
      orElse: () => ProductVariant(size: size, stockQuantity: 0),
    );
    return v.stockQuantity;
  }

  bool isSizeInStock(String size) {
    return getStockForSize(size) > 0;
  }

  List<String> get availableSizes {
    if (variants.isNotEmpty) {
      return variants.map((v) => v.size).toSet().toList();
    }
    return const ['S', 'M', 'L'];
  }

  int get totalStock {
    if (variants.isEmpty) return 99;
    return variants.fold(0, (sum, v) => sum + v.stockQuantity);
  }

  // Convert image path from web (/images/products/...) to flutter asset or network URL
  String get assetPath => _resolveImagePath(img);

  List<String> get assetGallery {
    if (gallery.isEmpty) return [assetPath];
    return gallery.map((g) => _resolveImagePath(g)).toList();
  }

  static String resolveImage(String? path) => _resolveImagePath(path ?? '');

  static String _resolveImagePath(String path) {
    if (path.isEmpty) return 'assets/images/products/sunset-main-1.jpg';
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    if (path.startsWith('assets/')) {
      return path;
    }

    final cleaned = path.startsWith('/') ? path.substring(1) : path;
    if (cleaned.startsWith('assets/')) {
      return cleaned;
    }
    if (cleaned.startsWith('images/products/')) {
      return 'assets/$cleaned';
    }
    if (cleaned.startsWith('images/')) {
      return 'assets/$cleaned';
    }
    return 'assets/images/products/$cleaned';
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawId = json['id']?.toString() ?? '';
    final thumbnail = (json['thumbnail'] ?? json['img'] ?? '') as String;

    List<String> parsedGallery = [];
    if (json['gallery'] is List) {
      for (var item in (json['gallery'] as List)) {
        if (item is String) {
          parsedGallery.add(item);
        } else if (item is Map && item['imageUrl'] != null) {
          parsedGallery.add(item['imageUrl'].toString());
        }
      }
    }
    if (parsedGallery.isEmpty && thumbnail.isNotEmpty) {
      parsedGallery.add(thumbnail);
    }

    List<ProductVariant> parsedVariants = [];
    if (json['variants'] is List) {
      parsedVariants = (json['variants'] as List)
          .map((v) => ProductVariant.fromJson(v as Map<String, dynamic>))
          .toList();
    } else {
      // Default sizes if BE didn't return variants in list mode
      parsedVariants = [
        ProductVariant(size: 'S', stockQuantity: 10),
        ProductVariant(size: 'M', stockQuantity: 15),
        ProductVariant(size: 'L', stockQuantity: 8),
      ];
    }

    final catSlug = (json['categorySlug'] ?? json['type'] ?? 'ao') as String;
    final catName = (json['categoryName'] ?? (catSlug == 'quan' ? 'Quần & Váy' : 'Áo & Đầm')) as String;

    return Product(
      id: rawId,
      name: (json['name'] ?? '') as String,
      slug: (json['slug'] ?? '') as String,
      sku: (json['sku'] ?? '') as String,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      originalPrice: (json['originalPrice'] as num?)?.toDouble(),
      type: catSlug,
      isSummer: json['isSummer'] as bool? ?? false,
      isFeatured: json['isFeatured'] as bool? ?? false,
      collection: (json['collection'] as String?)?.toUpperCase() ??
          (((json['isSummer'] as bool?) ?? false) ? 'SUNSET' : 'REGULAR'),
      img: thumbnail,
      gallery: parsedGallery,
      variants: parsedVariants,
      tag: json['tag'] as String?,
      description: json['description'] as String?,
      material: json['material'] as String?,
      careInstructions: json['careInstructions'] as String?,
      categoryId: json['categoryId']?.toString(),
      categoryName: catName,
      categorySlug: catSlug,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'sku': sku,
      'price': price,
      'originalPrice': originalPrice,
      'type': type,
      'isSummer': isSummer,
      'isFeatured': isFeatured,
      'collection': collection,
      'img': img,
      'gallery': gallery,
      'variants': variants.map((v) => v.toJson()).toList(),
      'tag': tag,
      'description': description,
      'material': material,
      'careInstructions': careInstructions,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'categorySlug': categorySlug,
    };
  }
}
