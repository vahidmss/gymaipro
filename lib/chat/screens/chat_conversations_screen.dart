import 'package:flutter/material.dart';
import 'dart:async';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/chat_message.dart';
import '../../services/chat_service.dart';
import '../../services/supabase_service.dart';
import 'chat_screen.dart';
import '../../theme/app_theme.dart';
import '../../utils/safe_set_state.dart';
import '../widgets/chat_stats_widget.dart';
import '../../widgets/user_role_badge.dart';
import 'package:intl/intl.dart';

class ChatConversationsScreen extends StatefulWidget {
  const ChatConversationsScreen({Key? key}) : super(key: key);

  @override
  State<ChatConversationsScreen> createState() =>
      _ChatConversationsScreenState();
}

class _ChatConversationsScreenState extends State<ChatConversationsScreen> {
  late ChatService _chatService;
  List<ChatConversation> _conversations = [];
  List<ChatConversation> _filteredConversations = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'all';
  StreamSubscription? _conversationsSubscription;

  @override
  void initState() {
    super.initState();
    _chatService = ChatService(supabaseService: SupabaseService());
    _loadConversations();
    _subscribeToConversations();
  }

  @override
  void dispose() {
    _conversationsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    try {
      SafeSetState.call(this, () => _isLoading = true);
      final conversations = await _chatService.getConversations();
      SafeSetState.call(this, () {
        _conversations = conversations;
        _filterConversations();
        _isLoading = false;
      });
    } catch (e) {
      SafeSetState.call(this, () => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در بارگذاری گفتگوها: $e')),
        );
      }
    }
  }

  void _subscribeToConversations() {
    try {
      final stream = _chatService.subscribeToConversations();
      _conversationsSubscription = stream.listen((conversation) {
        _updateConversation(conversation);
      });
    } catch (e) {
      debugPrint('Error subscribing to conversations: $e');
    }
  }

  void _updateConversation(ChatConversation newConversation) {
    SafeSetState.call(this, () {
      final index = _conversations.indexWhere(
        (conv) => conv.otherUserId == newConversation.otherUserId,
      );

      if (index >= 0) {
        _conversations[index] = newConversation;
      } else {
        _conversations.add(newConversation);
      }

      _conversations.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
      _filterConversations();
    });
  }

  void _filterConversations() {
    List<ChatConversation> filtered = _conversations;

    // اعمال فیلتر
    switch (_selectedFilter) {
      case 'unread':
        filtered = filtered.where((c) => c.hasUnread).toList();
        break;
      case 'trainers':
        filtered = filtered.where((c) => c.isTrainer).toList();
        break;
      case 'clients':
        filtered = filtered.where((c) => !c.isTrainer).toList();
        break;
    }

    // اعمال جستجو
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((c) =>
              c.otherUserName
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              (c.lastMessageText
                      ?.toLowerCase()
                      .contains(_searchQuery.toLowerCase()) ??
                  false))
          .toList();
    }

    _filteredConversations = filtered;
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _filterConversations();
    });
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
      _filterConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilterSection(),
        if (_conversations.isNotEmpty) _buildStatsSection(),
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.goldColor))
              : _filteredConversations.isEmpty
                  ? _buildEmptyState()
                  : _buildConversationsList(),
        ),
      ],
    );
  }

  Widget _buildFilterSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.goldColor.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedFilter,
                  dropdownColor: AppTheme.cardColor,
                  style: const TextStyle(color: Colors.white),
                  icon:
                      const Icon(LucideIcons.filter, color: AppTheme.goldColor),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('همه')),
                    DropdownMenuItem(value: 'unread', child: Text('نخوانده')),
                    DropdownMenuItem(value: 'trainers', child: Text('مربی‌ها')),
                    DropdownMenuItem(value: 'clients', child: Text('شاگردها')),
                  ],
                  onChanged: (value) {
                    if (value != null) _onFilterChanged(value);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    final unreadCount = _conversations.where((c) => c.hasUnread).length;
    final totalMessages =
        _conversations.fold<int>(0, (sum, c) => sum + c.unreadCount);

    return ChatStatsWidget(
      totalMessages: totalMessages,
      unreadMessages: unreadCount,
      activeConversations: _conversations.length,
    );
  }

  Widget _buildEmptyState() {
    String message;
    String subtitle;
    IconData icon;

    if (_searchQuery.isNotEmpty || _selectedFilter != 'all') {
      message = 'نتیجه‌ای یافت نشد';
      subtitle = 'جستجو یا فیلتر خود را تغییر دهید';
      icon = LucideIcons.search;
    } else {
      message = 'هنوز گفتگویی شروع نشده است';
      subtitle = 'برای شروع گفتگو با مربیان یا سایر کاربران چت کنید';
      icon = LucideIcons.messageCircle;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              size: 64,
              color: AppTheme.goldColor.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildConversationsList() {
    return RefreshIndicator(
      onRefresh: _loadConversations,
      color: AppTheme.goldColor,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filteredConversations.length,
        itemBuilder: (context, index) {
          final conversation = _filteredConversations[index];
          return _buildConversationTile(conversation);
        },
      ),
    );
  }

  Widget _buildConversationTile(ChatConversation conversation) {
    final timeString = _formatLastMessageTime(conversation.lastMessageAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: conversation.hasUnread
              ? AppTheme.goldColor.withValues(alpha: 0.3)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToChatScreen(conversation),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // آواتار
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: conversation.isTrainer
                        ? Colors.purple.withValues(alpha: 0.2)
                        : Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: conversation.otherUserAvatar != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Image.network(
                            conversation.otherUserAvatar!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                conversation.isTrainer
                                    ? LucideIcons.userCheck
                                    : LucideIcons.user,
                                color: conversation.isTrainer
                                    ? Colors.purple
                                    : Colors.green,
                                size: 28,
                              );
                            },
                          ),
                        )
                      : Icon(
                          conversation.isTrainer
                              ? LucideIcons.userCheck
                              : LucideIcons.user,
                          color: conversation.isTrainer
                              ? Colors.purple
                              : Colors.green,
                          size: 28,
                        ),
                ),
                const SizedBox(width: 16),

                // محتوا
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              conversation.otherUserName,
                              style: TextStyle(
                                color: conversation.hasUnread
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.9),
                                fontSize: 16,
                                fontWeight: conversation.hasUnread
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (conversation.isTrainer)
                            const UserRoleBadge(
                              role: 'trainer',
                              fontSize: 10,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        conversation.lastMessageText ?? 'بدون پیام',
                        style: TextStyle(
                          color: conversation.hasUnread
                              ? Colors.white.withValues(alpha: 0.9)
                              : Colors.white.withValues(alpha: 0.6),
                          fontSize: 14,
                          fontWeight: conversation.hasUnread
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // زمان و تعداد نخوانده
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      timeString,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (conversation.hasUnread)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${conversation.unreadCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatLastMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return DateFormat.Hm().format(dateTime);
    } else if (messageDate == yesterday) {
      return 'دیروز';
    } else if (now.difference(dateTime).inDays < 7) {
      final List<String> weekdays = [
        'یکشنبه',
        'دوشنبه',
        'سه‌شنبه',
        'چهارشنبه',
        'پنج‌شنبه',
        'جمعه',
        'شنبه'
      ];
      return weekdays[dateTime.weekday % 7];
    } else {
      return DateFormat('yyyy/MM/dd').format(dateTime);
    }
  }

  void _navigateToChatScreen(ChatConversation conversation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          otherUserId: conversation.otherUserId,
          otherUserName: conversation.otherUserName,
        ),
      ),
    );
  }
}
