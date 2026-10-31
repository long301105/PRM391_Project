import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/constants/admin_endpoints.dart';
import '../../core/network/api_exception.dart';
import '../../models/chat_message.dart';
import 'admin_base.dart';

/// Một dòng trong danh sách hội thoại của admin — khớp ConversationSummaryResponse của BE:
/// { id, accountId, customerName, customerEmail, lastMessageAt, lastMessagePreview, unreadByAdmin }.
class AdminConversationSummary {
  final String id;
  final String accountId;
  final String customerName;
  final String customerEmail;
  final DateTime? lastMessageAt;
  final String lastMessagePreview;
  final int unreadByAdmin;

  const AdminConversationSummary({
    required this.id,
    required this.accountId,
    required this.customerName,
    required this.customerEmail,
    required this.lastMessageAt,
    required this.lastMessagePreview,
    required this.unreadByAdmin,
  });

  /// Tên để hiển thị: ưu tiên tên, không có thì rơi về email, cuối cùng là "Khách".
  String get displayName {
    if (customerName.trim().isNotEmpty) return customerName.trim();
    if (customerEmail.trim().isNotEmpty) return customerEmail.trim();
    return 'Khách';
  }

  factory AdminConversationSummary.fromJson(Map<String, dynamic> json) {
    final rawDate = (json['lastMessageAt'] ?? '').toString();
    return AdminConversationSummary(
      id: json['id']?.toString() ?? '',
      accountId: json['accountId']?.toString() ?? '',
      customerName: (json['customerName'] ?? '').toString(),
      customerEmail: (json['customerEmail'] ?? '').toString(),
      lastMessageAt: rawDate.isEmpty ? null : DateTime.tryParse(rawDate)?.toLocal(),
      lastMessagePreview: (json['lastMessagePreview'] ?? '').toString(),
      unreadByAdmin: (json['unreadByAdmin'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Chat phía shop: danh sách hội thoại + thread của từng khách.
/// Dùng chung cơ chế POLLING như [ChatProvider] của khách, chỉ khác bộ endpoint `/conversations/admin`.
class AdminConversationProvider extends AdminProviderBase {
  // ── Danh sách hội thoại ──
  PagedList<AdminConversationSummary> _page = const PagedList<AdminConversationSummary>();
  int _unreadTotal = 0;

  PagedList<AdminConversationSummary> get pageData => _page;
  List<AdminConversationSummary> get conversations => _page.items;
  int get unreadTotal => _unreadTotal;

  // ── Thread đang mở ──
  String? _activeId;
  final List<ChatMessage> _messages = [];
  bool _threadLoading = false;
  Timer? _poll;
  DateTime? _sinceUtc;

  String? get activeConversationId => _activeId;
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get threadLoading => _threadLoading;

  // ───────────────────────── Danh sách ─────────────────────────

  Future<void> fetchConversations({int page = 0, int size = 20}) async {
    final result = await guard(() => api.get(
          AdminEndpoints.conversations,
          queryParams: {'page': page, 'size': size},
        ));
    if (result != null) {
      _page = PagedList.from(result, AdminConversationSummary.fromJson);
      notifyListeners();
    }
  }

  /// Tổng số hội thoại đang chờ admin đọc — để gắn badge ở màn Quản trị.
  Future<void> fetchUnreadCount() async {
    try {
      final r = await api.get(AdminEndpoints.conversationsUnreadCount, requiresAuth: true);
      if (r is Map<String, dynamic>) {
        _unreadTotal = (r['unreadCount'] as num?)?.toInt() ?? 0;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[AdminConversationProvider] unread-count error: $e');
    }
  }

  // ───────────────────────── Thread ─────────────────────────

  /// Mở hội thoại của một khách: tải lịch sử + đánh dấu đã đọc + bắt đầu hỏi tin mới mỗi 3 giây.
  Future<void> openConversation(String conversationId) async {
    _activeId = conversationId;
    _messages.clear();
    _sinceUtc = null;
    await _loadHistory();
    await markRead();
    startPolling();
  }

  Future<void> _loadHistory() async {
    if (_activeId == null) return;
    _threadLoading = true;
    notifyListeners();
    try {
      final result = await api.get(
        AdminEndpoints.conversationMessages(_activeId!),
        queryParams: {'size': 50},
        requiresAuth: true,
      );
      if (result is Map<String, dynamic> && result['content'] is List) {
        final list = (result['content'] as List)
            .whereType<Map<String, dynamic>>()
            .map(ChatMessage.fromJson)
            .toList()
            .reversed // BE trả mới→cũ, đảo lại cũ→mới để hiển thị
            .toList();
        _messages
          ..clear()
          ..addAll(list);
        _updateSince();
      }
    } catch (e) {
      debugPrint('[AdminConversationProvider] loadHistory error: $e');
    } finally {
      _threadLoading = false;
      notifyListeners();
    }
  }

  void _updateSince() {
    if (_messages.isNotEmpty) _sinceUtc = _messages.last.timestamp.toUtc();
  }

  void startPolling() {
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 3), (_) => _pollNew());
  }

  void stopPolling() {
    _poll?.cancel();
    _poll = null;
  }

  Future<void> _pollNew() async {
    if (_activeId == null) return;
    try {
      final qp = <String, dynamic>{};
      if (_sinceUtc != null) qp['since'] = _sinceUtc!.toIso8601String();
      final result = await api.get(
        AdminEndpoints.conversationMessagesNew(_activeId!),
        queryParams: qp.isEmpty ? null : qp,
        requiresAuth: true,
      );
      if (result is List && result.isNotEmpty) {
        var changed = false;
        for (final e in result) {
          final msg = ChatMessage.fromJson(e as Map<String, dynamic>);
          if (!_messages.any((m) => m.id == msg.id)) {
            _messages.add(msg);
            changed = true;
          }
        }
        if (changed) {
          _updateSince();
          await markRead();
          notifyListeners();
        }
      }
    } on ApiException catch (e) {
      // Token không còn quyền (đổi tài khoản / hết phiên) -> dừng hẳn, đừng spam 403 mỗi 3 giây.
      // Lưu ý: 401 do access token hết hạn đã được ApiService tự refresh + gọi lại TRƯỚC khi tới
      // đây; chỉ khi refresh cũng hỏng (phiên chết thật) hoặc 403 (mất quyền) mới rơi vào nhánh này.
      if (e.statusCode == 401 || e.statusCode == 403) {
        debugPrint('[AdminConversationProvider] poll stopped (status ${e.statusCode})');
        closeThread();
      } else {
        debugPrint('[AdminConversationProvider] poll error: ${e.message}');
      }
    } catch (e) {
      debugPrint('[AdminConversationProvider] poll error: $e');
    }
  }

  /// Shop trả lời khách. Tin trả về (senderType = ADMIN) được chèn ngay để UI mượt.
  Future<void> sendReply(String text) async {
    final content = text.trim();
    if (content.isEmpty || _activeId == null) return;
    try {
      final result = await api.post(
        AdminEndpoints.conversationMessages(_activeId!),
        body: {'content': content},
        requiresAuth: true,
      );
      if (result is Map<String, dynamic>) {
        final msg = ChatMessage.fromJson(result);
        if (!_messages.any((m) => m.id == msg.id)) {
          _messages.add(msg);
          _updateSince();
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('[AdminConversationProvider] sendReply error: $e');
    }
  }

  Future<void> markRead() async {
    if (_activeId == null) return;
    try {
      await api.patch(AdminEndpoints.conversationRead(_activeId!), requiresAuth: true);
    } catch (_) {
      // không quan trọng nếu lỗi
    }
  }

  /// Đóng thread: ngừng hỏi, xoá tin của thread hiện tại.
  void closeThread() {
    stopPolling();
    _activeId = null;
    _messages.clear();
    _sinceUtc = null;
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
