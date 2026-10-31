import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_exception.dart';
import '../core/storage/token_store.dart';

/// Lớp mạng trung tâm của app, dựng trên **Dio**.
/// Giữ nguyên interface cũ (`get/post/patch/delete`, `setTokens`, `clearTokens`...) để các
/// provider khác (product, order, auth) không phải đổi. Điểm nâng cấp (GĐ 2):
/// - Token lưu bằng **secure storage** (xem [TokenStore]).
/// - Tự **refresh token khi 401** + **chống đua** (nhiều request 401 cùng lúc chỉ refresh 1 lần).
/// - Refresh token **xoay vòng**: luôn lưu đè cả access lẫn refresh mới.
/// - **Thu hồi phiên**: refresh thất bại ⇒ xoá token + gọi [onSessionExpired].
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
      // Tự xử mọi status code (kể cả 4xx/5xx) thay vì để Dio ném — ta parse envelope tay.
      validateStatus: (_) => true,
      headers: {
        'Accept': 'application/json',
        'X-Client-Type': 'mobile', // 🔴 toàn cục: BE trả token trong body cho mobile
      },
    ));
  }

  late final Dio _dio;
  final TokenStore _store = TokenStore.instance;

  // Cache trong RAM để getter đọc đồng bộ; nguồn gốc vẫn là secure storage.
  String? _accessToken;
  String? _refreshToken;

  /// Gọi khi phiên bị thu hồi / refresh thất bại (token đã bị xoá). UI tự cập nhật về trạng thái khách.
  void Function()? onSessionExpired;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  bool get hasToken => _accessToken != null && _accessToken!.isNotEmpty;

  Future<void> init() async {
    _accessToken = await _store.accessToken;
    _refreshToken = await _store.refreshToken;
  }

  Future<void> setTokens({required String accessToken, required String refreshToken}) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    await _store.save(accessToken: accessToken, refreshToken: refreshToken);
  }

  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    await _store.clear();
  }

  // --- Public API giữ nguyên chữ ký cũ ---

  Future<dynamic> get(String path, {Map<String, dynamic>? queryParams, bool requiresAuth = true}) =>
      _send('GET', path, queryParams: queryParams, requiresAuth: requiresAuth);

  Future<dynamic> post(String path, {dynamic body, bool requiresAuth = true}) =>
      _send('POST', path, body: body, requiresAuth: requiresAuth);

  Future<dynamic> patch(String path, {dynamic body, bool requiresAuth = true}) =>
      _send('PATCH', path, body: body, requiresAuth: requiresAuth);

  Future<dynamic> put(String path, {dynamic body, bool requiresAuth = true}) =>
      _send('PUT', path, body: body, requiresAuth: requiresAuth);

  Future<dynamic> delete(String path, {Map<String, dynamic>? queryParams, bool requiresAuth = true}) =>
      _send('DELETE', path, queryParams: queryParams, requiresAuth: requiresAuth);

  // --- Lõi ---

  Future<Response<dynamic>> _rawCall(
    String method,
    String path, {
    Map<String, dynamic>? queryParams,
    dynamic body,
    required bool requiresAuth,
  }) {
    final headers = <String, dynamic>{};
    if (requiresAuth && (_accessToken?.isNotEmpty ?? false)) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    // Lọc query null để không gửi "key=" thừa.
    final cleanQuery = queryParams == null
        ? null
        : (Map<String, dynamic>.from(queryParams)..removeWhere((_, v) => v == null));

    return _dio.request(
      path,
      data: body,
      queryParameters: cleanQuery,
      options: Options(method: method, headers: headers.isEmpty ? null : headers),
    );
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, dynamic>? queryParams,
    dynamic body,
    bool requiresAuth = true,
  }) async {
    try {
      var resp = await _rawCall(method, path, queryParams: queryParams, body: body, requiresAuth: requiresAuth);

      // 401 ở endpoint cần auth (trừ chính luồng /auth/) ⇒ thử refresh 1 lần rồi gọi lại.
      final isAuthFlow = path.startsWith('/auth/');
      if (resp.statusCode == 401 && requiresAuth && !isAuthFlow && (_refreshToken?.isNotEmpty ?? false)) {
        final refreshed = await _attemptRefreshToken();
        if (refreshed) {
          resp = await _rawCall(method, path, queryParams: queryParams, body: body, requiresAuth: requiresAuth);
        }
      }

      return _processResponse(resp);
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      debugPrint('[ApiService] network error: ${e.message}');
      throw ApiException(statusCode: 0, message: 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra mạng hoặc khởi động BE.');
    }
  }

  dynamic _processResponse(Response<dynamic> resp) {
    final status = resp.statusCode ?? 0;
    final body = resp.data;

    if (status >= 200 && status < 300) {
      if (body is Map<String, dynamic> && body.containsKey('result')) {
        return body['result'];
      }
      return body;
    }

    String message = 'Yêu cầu không thành công ($status)';
    Map<String, String>? fieldErrors;
    if (body is Map) {
      if (body['message'] != null) {
        message = body['message'].toString();
      } else if (body['error'] != null) {
        message = body['error'].toString();
      }
      if (body['errors'] is Map) {
        fieldErrors = (body['errors'] as Map).map((k, v) => MapEntry(k.toString(), v.toString()));
      }
    }
    throw ApiException(statusCode: status, message: message, fieldErrors: fieldErrors);
  }

  Future<dynamic> sendFile(
    String method,
    String path, {
    required String filePath,
    String field = 'file',
    List<int>? fileBytes,
    String? fileName,
    Map<String, dynamic>? metadata,
  }) async {
    Future<FormData> buildForm() async => FormData.fromMap({
          if (metadata != null)
            'metadata': MultipartFile.fromString(
              jsonEncode(metadata),
              contentType: DioMediaType('application', 'json'),
            ),
          field: fileBytes != null
              ? MultipartFile.fromBytes(
                  fileBytes,
                  filename: fileName,
                  contentType: DioMediaType('application', 'octet-stream'),
                )
              : await MultipartFile.fromFile(
                  filePath,
                  filename: filePath.split(RegExp(r'[\\/]')).last,
                ),
        });

    Future<Response<dynamic>> call() async => _dio.request(
          path,
          data: await buildForm(),
          options: Options(
            method: method,
            contentType: 'multipart/form-data',
            headers: (_accessToken?.isNotEmpty ?? false)
                ? {'Authorization': 'Bearer $_accessToken'}
                : null,
          ),
        );

    try {
      var resp = await call();

      if (resp.statusCode == 401 && (_refreshToken?.isNotEmpty ?? false)) {
        final refreshed = await _attemptRefreshToken();
        if (refreshed) resp = await call();
      }

      return _processResponse(resp);
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      debugPrint('[ApiService] upload error: ${e.message}');
      throw ApiException(statusCode: 0, message: 'Không tải được ảnh lên. Vui lòng kiểm tra mạng.');
    }
  }

  // --- Refresh token: chống đua bằng một Future dùng chung ---

  Future<bool>? _refreshing;

  Future<bool> _attemptRefreshToken() {
    // Mọi request 401 cùng lúc chờ CHUNG một lần refresh; xong thì reset để lần sau refresh lại được.
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<bool> _doRefresh() async {
    if (_refreshToken == null || _refreshToken!.isEmpty) return false;
    try {
      final resp = await _dio.post(
        ApiConstants.refresh,
        data: {'token': _refreshToken}, // 🔴 field 'token' theo hợp đồng BE
        options: Options(headers: {'X-Client-Type': 'mobile'}),
      );
      if (resp.statusCode == 200 && resp.data is Map) {
        final result = (resp.data as Map)['result'];
        if (result is Map && result['accessToken'] != null) {
          await setTokens(
            accessToken: result['accessToken'] as String,
            refreshToken: (result['refreshToken'] as String?) ?? _refreshToken!,
          );
          return true;
        }
      }
    } catch (e) {
      debugPrint('[ApiService] refresh failed: $e');
    }

    // Refresh hỏng = hết đường cứu: xoá token + báo UI về trạng thái khách.
    await clearTokens();
    onSessionExpired?.call();
    return false;
  }
}
