import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../services/chat_service.dart';
import '../services/supabase_service.dart';
import 'package:provider/provider.dart';

class ChatNotificationBadge extends StatefulWidget {
  const ChatNotificationBadge({Key? key}) : super(key: key);

  @override
  State<ChatNotificationBadge> createState() => _ChatNotificationBadgeState();
}

class _ChatNotificationBadgeState extends State<ChatNotificationBadge> {
  int _unreadCount = 0;
  late ChatService _chatService;

  @override
  void initState() {
    super.initState();
    _chatService = ChatService(
      supabaseService: Provider.of<SupabaseService>(context, listen: false),
    );
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final conversations = await _chatService.getConversations();
      final unreadCount = conversations.where((conv) => conv.hasUnread).length;

      if (mounted) {
        setState(() {
          _unreadCount = unreadCount;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_unreadCount == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(left: 8),
      child: Stack(
        children: [
          const Icon(
            LucideIcons.messageCircle,
            color: AppTheme.goldColor,
            size: 20,
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.backgroundColor, width: 1),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
