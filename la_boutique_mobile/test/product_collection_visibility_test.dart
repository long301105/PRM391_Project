import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:la_boutique_mobile/core/constants/api_constants.dart';
import 'package:la_boutique_mobile/providers/product_provider.dart';

class _DirectHttpOverrides extends HttpOverrides {}

Map<String, dynamic> _product(String id) => {
  'id': id,
  'name': id,
  'slug': id,
  'price': 100,
  'categorySlug': 'ao',
  'status': 'ACTIVE',
};

Future<void> _waitUntil(bool Function() condition) async {
  final end = DateTime.now().add(const Duration(seconds: 5));
  while (!condition()) {
    if (DateTime.now().isAfter(end)) throw TimeoutException('Waiting for provider');
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late HttpServer server;
  late HttpOverrides? previousOverrides;
  var hidden = false;
  var productRequests = 0;
  Map<String, String> lastProductQuery = {};

  setUpAll(() async {
    previousOverrides = HttpOverrides.current;
    HttpOverrides.global = _DirectHttpOverrides();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    ApiConstants.baseUrl = 'http://127.0.0.1:${server.port}';
    server.listen((request) async {
      request.response.headers.contentType = ContentType.json;
      if (request.uri.path == '/categories') {
        request.response.write(jsonEncode({'result': {'content': []}}));
      } else if (request.uri.path == '/products') {
        productRequests++;
        lastProductQuery = request.uri.queryParameters;
        final slug = request.uri.queryParameters['collection'];
        if (slug == 'network-error') {
          request.response.statusCode = 503;
          request.response.write('{}');
          await request.response.close();
          return;
        }
        if (slug == 'slow') await Future<void>.delayed(const Duration(milliseconds: 150));
        final page = int.tryParse(request.uri.queryParameters['page'] ?? '0') ?? 0;
        final content = slug == 'sunset' && hidden
            ? <Map<String, dynamic>>[]
            : [_product(slug == 'paged' ? 'paged-$page' : slug == null ? 'all-product' : '$slug-product')];
        request.response.write(jsonEncode({'result': {
          'content': content,
          'totalPages': slug == 'paged' ? 2 : 1,
        }}));
      } else {
        request.response.statusCode = 404;
        request.response.write('{}');
      }
      await request.response.close();
    });
  });

  tearDownAll(() async {
    await server.close(force: true);
    HttpOverrides.global = previousOverrides;
  });

  test('empty collection response clears previously visible products', () async {
    hidden = false;
    final before = productRequests;
    final provider = ProductProvider();
    await _waitUntil(() => productRequests > before && !provider.isLoading);
    provider.selectPublicCollection('sunset');
    await _waitUntil(() => !provider.isLoading);
    expect(provider.filteredProducts.map((p) => p.id), ['sunset-product']);

    hidden = true;
    await provider.fetchProducts();
    expect(provider.filteredProducts, isEmpty);
    provider.dispose();
  });

  test('older collection response cannot overwrite the selected all tab', () async {
    hidden = false;
    final before = productRequests;
    final provider = ProductProvider();
    await _waitUntil(() => productRequests > before && !provider.isLoading);
    provider.selectPublicCollection('slow');
    provider.setCategory('all');
    await _waitUntil(() => !provider.isLoading);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    expect(provider.publicCollectionSlug, isNull);
    expect(provider.filteredProducts.map((p) => p.id), ['all-product']);
    provider.dispose();
  });
  test('a failed new collection request does not show previous products', () async {
    hidden = false;
    final before = productRequests;
    final provider = ProductProvider();
    await _waitUntil(() => productRequests > before && !provider.isLoading);
    provider.selectPublicCollection('sunset');
    await _waitUntil(() => !provider.isLoading);
    expect(provider.filteredProducts.map((p) => p.id), ['sunset-product']);
    provider.selectPublicCollection('network-error');
    await _waitUntil(() => !provider.isLoading);
    expect(provider.filteredProducts, isEmpty);
    provider.dispose();
  });

  test('advanced filters can combine a category and a collection', () async {
    hidden = false;
    final before = productRequests;
    final provider = ProductProvider();
    await _waitUntil(() => productRequests > before && !provider.isLoading);
    provider.setMultiFilters(category: 'ao', collection: 'sunset');
    await _waitUntil(() => !provider.isLoading);
    expect(lastProductQuery['collection'], 'sunset');
    expect(lastProductQuery['category'], 'ao');
    expect(provider.filteredProducts.map((p) => p.id), ['sunset-product']);
    provider.dispose();
  });

  test('collection products are fetched across all pages', () async {
    final before = productRequests;
    final provider = ProductProvider();
    await _waitUntil(() => productRequests > before && !provider.isLoading);
    provider.selectPublicCollection('paged');
    await _waitUntil(() => !provider.isLoading);
    expect(provider.filteredProducts.map((p) => p.id), ['paged-0', 'paged-1']);
    provider.dispose();
  });

}
