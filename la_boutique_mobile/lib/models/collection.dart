class CollectionModel {
  final String id;
  final String collectionName;
  final String slug;
  final String? coverImageUrl;

  final String? status;

  final int? version;

  final List<CollectionProductModel> products;

  final int visibleProductCount;

  final int totalProducts;

  const CollectionModel({
    required this.id,
    required this.collectionName,
    required this.slug,
    this.coverImageUrl,
    this.status,
    this.version,
    this.products = const [],
    this.visibleProductCount = 0,
    this.totalProducts = 0,
  });

  bool get isActive => (status ?? 'ACTIVE').toUpperCase() == 'ACTIVE';
  bool get hasCover => coverImageUrl != null && coverImageUrl!.trim().isNotEmpty;

  String get statusText {
    switch ((status ?? '').toUpperCase()) {
      case 'ACTIVE':
        return 'Đang hiển thị';
      case 'HIDDEN':
        return 'Đang ẩn';
      case 'DELETED':
        return 'Đã xoá';
      default:
        return '—';
    }
  }

  factory CollectionModel.fromJson(Map<String, dynamic> json) {
    final rawProducts = json['products'];

    List<CollectionProductModel> parsed = const [];
    int total = 0;

    if (rawProducts is Map<String, dynamic>) {
      final content = rawProducts['content'];
      if (content is List) {
        parsed = content
            .whereType<Map<String, dynamic>>()
            .map(CollectionProductModel.fromJson)
            .toList();
      }
      total = (rawProducts['totalElements'] as num?)?.toInt() ?? parsed.length;
    } else if (rawProducts is List) {
      parsed = rawProducts
          .whereType<Map<String, dynamic>>()
          .map(CollectionProductModel.fromJson)
          .toList();
      total = parsed.length;
    }

    return CollectionModel(
      id: json['id']?.toString() ?? '',
      collectionName: (json['collectionName'] ?? '') as String,
      slug: (json['slug'] ?? '') as String,
      coverImageUrl: json['coverImageUrl'] as String?,
      status: json['status'] as String?,
      version: (json['version'] as num?)?.toInt(),
      products: parsed,
      visibleProductCount: (json['visibleProductCount'] as num?)?.toInt() ?? 0,
      totalProducts: total,
    );
  }
}

class CollectionProductModel {
  final String productId;
  final String productName;
  final String? productSlug;
  final String? thumbnail;
  final double? price;
  final double? originalPrice;
  final String? tag;
  final String? status;
  final int? sortOrder;

  const CollectionProductModel({
    required this.productId,
    required this.productName,
    this.productSlug,
    this.thumbnail,
    this.price,
    this.originalPrice,
    this.tag,
    this.status,
    this.sortOrder,
  });

  bool get hasDiscount => originalPrice != null && price != null && originalPrice! > price!;

  factory CollectionProductModel.fromJson(Map<String, dynamic> json) => CollectionProductModel(
        productId: json['productId']?.toString() ?? '',
        productName: (json['productName'] ?? '') as String,
        productSlug: json['productSlug'] as String?,
        thumbnail: json['thumbnail'] as String?,
        price: (json['price'] as num?)?.toDouble(),
        originalPrice: (json['originalPrice'] as num?)?.toDouble(),
        tag: json['tag'] as String?,
        status: json['status'] as String?,
        sortOrder: (json['sortOrder'] as num?)?.toInt(),
      );
}
