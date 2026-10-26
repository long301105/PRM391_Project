import 'package:flutter/foundation.dart';

class ApiConstants {
  // Configurable base URL:
  // - Android emulator: 10.0.2.2
  // - iOS simulator / Web / Desktop: localhost
  // - Physical device: set to your LAN IP (e.g. http://192.168.1.x:8088/api/v1)
  static String get defaultBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:8088/api/v1';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8088/api/v1';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      default:
        return 'http://localhost:8088/api/v1';
    }
  }

  // Ưu tiên API_BASE_URL truyền qua --dart-define / dart_define.json (để đổi host khi chạy
  // máy thật hoặc deploy mà KHÔNG sửa code). Không truyền thì dùng mặc định theo nền tảng ở trên
  // (tiện cho dev trên emulator).
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');
  static String baseUrl = _envBaseUrl.isNotEmpty ? _envBaseUrl : defaultBaseUrl;

  // Auth endpoints
  static const String register = '/auth/register';
  static const String verifyRegistration = '/auth/verify-registration';
  static const String login = '/auth/login';
  static const String google = '/auth/google';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String logoutAll = '/auth/logout-all';
  static const String forgotPassword = '/auth/forgot-password';
  static const String verifyOtp = '/auth/verify-otp';
  static const String resetPassword = '/auth/reset-password';

  // Account endpoints
  static const String accounts = '/accounts';
  static const String accountMe = '/accounts/me';
  static const String changePassword = '/accounts/me/password';
  static const String emailChangeRequest = '/accounts/me/email/request';
  static const String emailChangeConfirm = '/accounts/me/email/confirm';

  // Profile endpoints
  static const String profileMe = '/profiles/me';

  // Notification endpoints (đều cần đăng nhập)
  static const String notifications = '/notifications/me';
  static const String notificationsUnreadCount = '/notifications/me/unread-count';
  static const String notificationsReadAll = '/notifications/me/read-all';
  static String notificationRead(String id) => '/notifications/me/$id/read';
  static String notificationById(String id) => '/notifications/me/$id';

  // Conversation / chat endpoints (đều cần đăng nhập)
  static const String conversationMe = '/conversations/me';
  static const String conversationMessages = '/conversations/me/messages';
  static const String conversationMessagesNew = '/conversations/me/messages/new';
  static const String conversationSend = '/conversations/me/messages';
  static const String conversationRead = '/conversations/me/read';

  // Store endpoints (công khai, không cần đăng nhập)
  static const String stores = '/stores';
  static String storeById(String id) => '/stores/id/$id';

  // Category endpoints
  static const String categories = '/categories';

  // Product endpoints
  static const String products = '/products';
  static String productById(String id) => '/products/id/$id';
  static String productBySlug(String slug) => '/products/slug/$slug';

  // Order endpoints
  static const String orders = '/orders';
  static const String myOrders = '/orders/me';
  static String myOrderByNumber(String orderNumber) => '/orders/me/$orderNumber';

  static String cancelMyOrder(String orderNumber) => '/orders/me/$orderNumber/cancel';

  static const String collections = '/collections';
  static String collectionBySlug(String slug) => '/collections/slug/$slug';
}
