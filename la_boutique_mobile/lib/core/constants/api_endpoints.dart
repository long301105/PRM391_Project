/// Tập trung toàn bộ đường dẫn API (tương đối, KHÔNG kèm /api/v1 — phần đó nằm ở baseUrl).
///
/// Lấy theo hợp đồng backend: PRM_BE/tai_lieu_auth_cho_fe/HUONG_DAN_FE_FLUTTER.md
class ApiEndpoints {
  ApiEndpoints._();

  // --- Auth (công khai, không cần token) ---
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

  // --- Accounts / Profiles (cần token) ---
  static const String accountMe = '/accounts/me';
  static const String accountMePassword = '/accounts/me/password';
  static const String profileMe = '/profiles/me';

  // --- Dữ liệu thương mại (đã dùng sẵn ở app) ---
  static const String categories = '/categories';
  static const String products = '/products';
  static const String orders = '/orders';
  static const String myOrders = '/orders/me';
  static String paymentVnpay(String orderNumber) => '/payments/me/$orderNumber/vnpay';
  static String paymentStatus(String orderNumber) => '/payments/me/$orderNumber';
}
