import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/admin/admin_conversation_provider.dart';
import 'admin_chat_thread_screen.dart';
import 'admin_widgets.dart';

/// Hộp thư hội thoại của shop: danh sách khách đã nhắn, kèm tin cuối + số chưa đọc.
class AdminConversationsScreen extends StatefulWidget {
  const AdminConversationsScreen({super.key});

  @override
  State<AdminConversationsScreen> createState() => _AdminConversationsScreenState();
}

class _AdminConversationsScreenState extends State<AdminConversationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    final provider = context.read<AdminConversationProvider>();
    await provider.fetchConversations();
    await provider.fetchUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminConversationProvider>();

    return Scaffold(
      backgroundColor: AppColors.sand50,
      appBar: AppBar(title: const Text('HỘI THOẠI KHÁCH')),
      body: Column(
        children: [
          AdminErrorBar(message: provider.errorMessage, onDismiss: provider.clearError),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              color: AppColors.clay500,
              child: (provider.isLoading && provider.conversations.isEmpty)
                  ? const Center(child: CircularProgressIndicator(color: AppColors.clay500))
                  : provider.conversations.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 120),
                            AdminEmptyState(
                              icon: Icons.forum_outlined,
                              title: 'Chưa có hội thoại nào',
                              subtitle: 'Khi khách nhắn tin cho shop, cuộc trò chuyện sẽ hiện ở đây.',
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: provider.conversations.length,
                          separatorBuilder: (_, _) =>
                              const Divider(height: 1, indent: 72, color: AppColors.sand200),
                          itemBuilder: (context, index) =>
                              _ConversationTile(item: provider.conversations[index]),
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final AdminConversationSummary item;

  const _ConversationTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final hasUnread = item.unreadByAdmin > 0;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: AppColors.clay50,
        child: Text(
          item.displayName.characters.first.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.clay600),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              item.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                fontSize: 14,
                color: AppColors.ink,
              ),
            ),
          ),
          if (item.lastMessageAt != null)
            Text(
              Formatters.formatDateShort(item.lastMessageAt!),
              style: const TextStyle(fontSize: 11, color: AppColors.mute),
            ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          item.lastMessagePreview.isEmpty ? 'Chưa có tin nhắn' : item.lastMessagePreview,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12.5,
            color: hasUnread ? AppColors.ink : AppColors.mute,
            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
      trailing: hasUnread
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: const BoxDecoration(color: AppColors.clay500, shape: BoxShape.rectangle, borderRadius: BorderRadius.all(Radius.circular(20))),
              constraints: const BoxConstraints(minWidth: 20),
              child: Text(
                item.unreadByAdmin > 99 ? '99+' : '${item.unreadByAdmin}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            )
          : const Icon(Icons.chevron_right_rounded, color: AppColors.sand400),
      onTap: () {
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => AdminChatThreadScreen(conversation: item)))
            .then((_) {
          if (context.mounted) {
            final provider = context.read<AdminConversationProvider>();
            provider.fetchConversations();
            provider.fetchUnreadCount();
          }
        });
      },
    );
  }
}
