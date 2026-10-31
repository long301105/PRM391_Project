import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/admin/admin_conversation_provider.dart';

/// Thread 1-1 giữa shop và một khách. Admin là "mình" (bong bóng bên phải),
/// khách ở bên trái. Poll tin mới mỗi 3 giây giống màn chat của khách.
class AdminChatThreadScreen extends StatefulWidget {
  final AdminConversationSummary conversation;

  const AdminChatThreadScreen({super.key, required this.conversation});

  @override
  State<AdminChatThreadScreen> createState() => _AdminChatThreadScreenState();
}

class _AdminChatThreadScreenState extends State<AdminChatThreadScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _lastCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AdminConversationProvider>().openConversation(widget.conversation.id);
    });
  }

  @override
  void dispose() {
    // Không read<Provider> trong dispose vì context có thể đã rời cây — gọi trực tiếp instance.
    AdminConversationProvider? provider;
    try {
      provider = context.read<AdminConversationProvider>();
    } catch (_) {
      provider = null;
    }
    provider?.closeThread();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send() {
    final text = _textController.text;
    if (text.trim().isEmpty) return;
    context.read<AdminConversationProvider>().sendReply(text);
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminConversationProvider>();
    final messages = provider.messages;

    if (messages.length != _lastCount) {
      _lastCount = messages.length;
      _scrollToBottom();
    }

    return Scaffold(
      backgroundColor: AppColors.sand50,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.conversation.displayName,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            if (widget.conversation.customerEmail.trim().isNotEmpty)
              Text(widget.conversation.customerEmail,
                  style: const TextStyle(fontSize: 11, color: AppColors.mute)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: (provider.threadLoading && messages.isEmpty)
                ? const Center(child: CircularProgressIndicator(color: AppColors.clay500))
                : messages.isEmpty
                    ? const Center(
                        child: Text('Chưa có tin nhắn trong hội thoại này.',
                            style: TextStyle(fontSize: 13, color: AppColors.mute)),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          // Admin là "mình": tin của shop (ADMIN) nằm bên phải, tin khách bên trái.
                          final isMe = !msg.isFromUser;
                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              constraints:
                                  BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isMe ? AppColors.clay500 : AppColors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(14),
                                  topRight: const Radius.circular(14),
                                  bottomLeft:
                                      isMe ? const Radius.circular(14) : const Radius.circular(2),
                                  bottomRight:
                                      isMe ? const Radius.circular(2) : const Radius.circular(14),
                                ),
                                border: isMe
                                    ? null
                                    : Border.all(color: AppColors.sand200.withValues(alpha: 0.8)),
                                boxShadow: [
                                  BoxShadow(
                                      color: AppColors.ink.withValues(alpha: 0.04),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1)),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  Text(msg.text,
                                      style: TextStyle(
                                          color: isMe ? Colors.white : AppColors.ink,
                                          fontSize: 13,
                                          height: 1.4)),
                                  const SizedBox(height: 4),
                                  Text(
                                    Formatters.formatDate(msg.timestamp),
                                    style: TextStyle(
                                      color: isMe
                                          ? Colors.white.withValues(alpha: 0.7)
                                          : AppColors.mute.withValues(alpha: 0.7),
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.white,
              border: Border(top: BorderSide(color: AppColors.sand200)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      maxLength: 2000,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: 'Trả lời khách...',
                        hintStyle: const TextStyle(fontSize: 13, color: AppColors.mute),
                        filled: true,
                        fillColor: AppColors.sand50,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: AppColors.clay500,
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 18),
                      onPressed: _send,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
