class AdminEndpoints {
  AdminEndpoints._();

  static const String accounts = '/accounts';

  static String account(String id) => '/accounts/$id';

  static String accountStatus(String id) => '/accounts/$id/status';

  static const String roles = '/roles';

  static String role(String id) => '/roles/$id';

  static const String products = '/products/admin';

  static String product(String id) => '/products/admin/$id';

  static String productImages(String id) => '/products/admin/$id/images';

  static String productImage(String id, String imageId) => '/products/admin/$id/images/$imageId';

  static String productThumbnailUpload(String id) => '/products/admin/$id/thumbnail';

  static String productThumbnailSelect(String id) => '/products/admin/$id/thumbnail';

  static String productVariants(String id) => '/products/admin/$id/variants';

  static String productVariant(String id, String variantId) =>
      '/products/admin/$id/variants/$variantId';

  static const String categories = '/categories/admin';

  static String category(String id) => '/categories/admin/$id';

  static const String collections = '/collections/admin';

  static String collection(String id) => '/collections/admin/$id';

  static String collectionCover(String id) => '/collections/admin/$id/cover';

  static String collectionProducts(String id) => '/collections/admin/$id/products';

  static String collectionPublish(String id) => '/collections/admin/$id/publish';

  static String collectionHide(String id) => '/collections/admin/$id/hide';

  static const String orders = '/orders';

  static String order(String id) => '/orders/$id';

  static String orderByNumber(String orderNumber) => '/orders/number/$orderNumber';

  static String orderStatus(String id) => '/orders/$id/status';
}
