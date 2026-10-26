class RecordStatusX {
  RecordStatusX._();

  static const String active = 'ACTIVE';
  static const String hidden = 'HIDDEN';
  static const String deleted = 'DELETED';

  static const List<String> editable = [active, hidden];

  static String label(String? status) {
    switch ((status ?? '').toUpperCase()) {
      case active:
        return 'Đang bán';
      case hidden:
        return 'Đang ẩn';
      case deleted:
        return 'Đã xoá';
      default:
        return '—';
    }
  }
}

class AdminAccount {
  final String id;
  final String email;
  final String? roleId;
  final String? roleName;

  final String status;

  final String provider;
  final bool hasPassword;

  final DateTime? lockedUntil;
  final DateTime? createdAt;

  const AdminAccount({
    required this.id,
    required this.email,
    this.roleId,
    this.roleName,
    required this.status,
    required this.provider,
    required this.hasPassword,
    this.lockedUntil,
    this.createdAt,
  });

  bool get isGoogle => provider.toUpperCase() == 'GOOGLE';
  bool get isAdmin => (roleName ?? '').toUpperCase() == 'ADMIN';

  String get statusText {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return 'Đang hoạt động';
      case 'DISABLED':
        return 'Đã vô hiệu';
      case 'LOCKED':
        return 'Đang bị khoá';
      default:
        return status;
    }
  }

  factory AdminAccount.fromJson(Map<String, dynamic> json) => AdminAccount(
        id: json['id']?.toString() ?? '',
        email: (json['email'] ?? '') as String,
        roleId: json['roleId']?.toString(),
        roleName: json['roleName'] as String?,
        status: (json['status'] ?? 'ACTIVE') as String,
        provider: (json['provider'] ?? 'LOCAL') as String,
        hasPassword: json['hasPassword'] as bool? ?? true,
        lockedUntil: _date(json['lockedUntil']),
        createdAt: _date(json['createdAt']),
      );
}

class AdminRole {
  final String id;
  final String roleName;
  final String? description;
  final DateTime? createdAt;

  const AdminRole({
    required this.id,
    required this.roleName,
    this.description,
    this.createdAt,
  });

  factory AdminRole.fromJson(Map<String, dynamic> json) => AdminRole(
        id: json['id']?.toString() ?? '',
        roleName: (json['roleName'] ?? '') as String,
        description: json['description'] as String?,
        createdAt: _date(json['createdAt']),
      );
}

class AdminCategory {
  final String id;
  final String categoryName;
  final String slug;
  final String status;
  final DateTime? createdAt;

  const AdminCategory({
    required this.id,
    required this.categoryName,
    required this.slug,
    required this.status,
    this.createdAt,
  });

  String get statusText => RecordStatusX.label(status);

  factory AdminCategory.fromJson(Map<String, dynamic> json) => AdminCategory(
        id: json['id']?.toString() ?? '',
        categoryName: (json['categoryName'] ?? '') as String,
        slug: (json['slug'] ?? '') as String,
        status: (json['status'] ?? RecordStatusX.active) as String,
        createdAt: _date(json['createdAt']),
      );
}

class AdminProductImage {
  final String id;
  final String imageUrl;
  final int? sortOrder;

  const AdminProductImage({required this.id, required this.imageUrl, this.sortOrder});

  factory AdminProductImage.fromJson(Map<String, dynamic> json) => AdminProductImage(
        id: json['id']?.toString() ?? '',
        imageUrl: (json['imageUrl'] ?? '') as String,
        sortOrder: (json['sortOrder'] as num?)?.toInt(),
      );
}

class AdminVariant {
  final String id;
  final String size;
  final int stockQuantity;
  final int version;

  const AdminVariant({
    required this.id,
    required this.size,
    required this.stockQuantity,
    required this.version,
  });

  factory AdminVariant.fromJson(Map<String, dynamic> json) => AdminVariant(
        id: json['id']?.toString() ?? '',
        size: (json['size'] ?? '') as String,
        stockQuantity: (json['stockQuantity'] as num?)?.toInt() ?? 0,
        version: (json['version'] as num?)?.toInt() ?? 0,
      );
}

class AdminProduct {
  final String id;
  final String name;
  final String slug;
  final String sku;
  final double price;
  final double? originalPrice;
  final String? description;
  final String? material;
  final String? careInstructions;
  final String? tag;
  final String? thumbnail;
  final bool isSummer;
  final bool isFeatured;
  final String status;
  final String? categoryId;
  final String? categoryName;
  final String? categorySlug;
  final List<AdminProductImage> gallery;
  final List<AdminVariant> variants;
  final DateTime? createdAt;

  const AdminProduct({
    required this.id,
    required this.name,
    required this.slug,
    required this.sku,
    required this.price,
    this.originalPrice,
    this.description,
    this.material,
    this.careInstructions,
    this.tag,
    this.thumbnail,
    this.isSummer = false,
    this.isFeatured = false,
    required this.status,
    this.categoryId,
    this.categoryName,
    this.categorySlug,
    this.gallery = const [],
    this.variants = const [],
    this.createdAt,
  });

  String get statusText => RecordStatusX.label(status);
  bool get isActive => status.toUpperCase() == RecordStatusX.active;
  int get totalStock => variants.fold(0, (sum, v) => sum + v.stockQuantity);

  List<String> get missingSizes {
    final had = variants.map((v) => v.size.toUpperCase()).toSet();
    return ['S', 'M', 'L'].where((s) => !had.contains(s)).toList();
  }

  factory AdminProduct.fromJson(Map<String, dynamic> json) => AdminProduct(
        id: json['id']?.toString() ?? '',
        name: (json['name'] ?? '') as String,
        slug: (json['slug'] ?? '') as String,
        sku: (json['sku'] ?? '') as String,
        price: (json['price'] as num?)?.toDouble() ?? 0,
        originalPrice: (json['originalPrice'] as num?)?.toDouble(),
        description: json['description'] as String?,
        material: json['material'] as String?,
        careInstructions: json['careInstructions'] as String?,
        tag: json['tag'] as String?,
        thumbnail: json['thumbnail'] as String?,
        isSummer: json['isSummer'] as bool? ?? false,
        isFeatured: json['isFeatured'] as bool? ?? false,
        status: (json['status'] ?? RecordStatusX.active) as String,
        categoryId: json['categoryId']?.toString(),
        categoryName: json['categoryName'] as String?,
        categorySlug: json['categorySlug'] as String?,
        gallery: (json['gallery'] is List)
            ? (json['gallery'] as List)
                .whereType<Map<String, dynamic>>()
                .map(AdminProductImage.fromJson)
                .toList()
            : const [],
        variants: (json['variants'] is List)
            ? (json['variants'] as List)
                .whereType<Map<String, dynamic>>()
                .map(AdminVariant.fromJson)
                .toList()
            : const [],
        createdAt: _date(json['createdAt']),
      );
}

DateTime? _date(dynamic raw) {
  if (raw == null) return null;
  return DateTime.tryParse(raw.toString());
}
