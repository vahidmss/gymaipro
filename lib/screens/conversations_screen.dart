import 'package:flutter/material.dart';
import 'dart:async';
import 'package:gymaipro/models/chat_message.dart';
import 'package:gymaipro/services/chat_service.dart';
import 'package:gymaipro/services/supabase_service.dart';
import 'package:gymaipro/screens/chat_screen.dart';
import 'package:gymaipro/theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({Key? key}) : super(key: key);

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  late ChatService _chatService;
  List<ChatConversation> _conversations = [];
  bool _isLoading = true;
  StreamSubscription? _conversationsSubscription;

  @override
  void initState() {
    super.initState();
    _chatService = ChatService(
      supabaseService: Provider.of<SupabaseService>(context, listen: false),
    );
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
      setState(() {
        _isLoading = true;
      });

      final conversations = await _chatService.getConversations();

      if (mounted) {
        setState(() {
          _conversations = conversations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
    setState(() {
      // Check if the conversation already exists
      final index = _conversations.indexWhere(
        (conv) => conv.otherUserId == newConversation.otherUserId,
      );

      if (index >= 0) {
        // Update existing conversation
        _conversations[index] = newConversation;
      } else {
        // Add new conversation
        _conversations.add(newConversation);
      }

      // Sort conversations by last message time (newest first)
      _conversations.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('گفتگوها'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadConversations,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? _buildEmptyState()
              : _buildConversationsList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showContactsDialog(),
        tooltip: 'گفتگوی جدید',
        child: const Icon(Icons.message),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'هنوز گفتگویی شروع نشده است',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'برای شروع گفتگو با دکمه پایین صفحه یک مخاطب را انتخاب کنید',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationsList() {
    return RefreshIndicator(
      onRefresh: _loadConversations,
      child: ListView.builder(
        itemCount: _conversations.length,
        itemBuilder: (context, index) {
          final conversation = _conversations[index];
          return _buildConversationTile(conversation);
        },
      ),
    );
  }

  Widget _buildConversationTile(ChatConversation conversation) {
    final timeString = _formatLastMessageTime(conversation.lastMessageAt);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primary,
        backgroundImage: conversation.otherUserAvatar != null
            ? NetworkImage(conversation.otherUserAvatar!)
            : null,
        child: conversation.otherUserAvatar == null
            ? Text(
                conversation.otherUserName.isNotEmpty
                    ? conversation.otherUserName[0].toUpperCase()
                    : '?',
                style: const TextStyle(color: Colors.white),
              )
            : null,
      ),
      title: Text(
        conversation.otherUserName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        conversation.lastMessageText ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            timeString,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          if (conversation.hasUnread)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Text(
                '',
                style: TextStyle(fontSize: 8),
              ),
            ),
        ],
      ),
      onTap: () => _navigateToChatScreen(conversation),
    );
  }

  String _formatLastMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return DateFormat.Hm().format(dateTime); // Format as hour:minute
    } else if (messageDate == yesterday) {
      return 'دیروز';
    } else if (now.difference(dateTime).inDays < 7) {
      // Show day of week for messages within the last week
      final List<String> weekdays = [
        'یکشنبه',
        'دوشنبه',
        'سه‌شنبه',
        'چهارشنبه',
        'پنج‌شنبه',
        'جمعه',
        'شنبه'
      ];
      return weekdays[dateTime.weekday % 7]; // Convert to Persian weekday
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
          otherUserAvatar: conversation.otherUserAvatar,
        ),
      ),
    );
  }

  Future<void> _showContactsDialog() async {
    try {
      final supabaseService =
          Provider.of<SupabaseService>(context, listen: false);
      final userProfile = await supabaseService.getProfileByAuthId();

      List<Map<String, dynamic>> contacts = [];

      if (userProfile != null && userProfile.role == 'trainer') {
        // If user is a trainer, show their clients
        contacts = await _chatService.getClients();
      } else {
        // If user is a client, show their trainers
        contacts = await _chatService.getTrainers();
      }

      if (!mounted) return;

      if (contacts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'مخاطبی برای گفتگو یافت نشد. لطفاً ابتدا مربی یا شاگرد اضافه کنید.',
            ),
          ),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('انتخاب مخاطب'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                final contact = contacts[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary,
                    backgroundImage: contact['avatar'] != null
                        ? NetworkImage(contact['avatar'])
                        : null,
                    child: contact['avatar'] == null
                        ? Text(
                            contact['name'].isNotEmpty
                                ? contact['name'][0].toUpperCase()
                                : '?',
                            style: const TextStyle(color: Colors.white),
                          )
                        : null,
                  ),
                  title: Text(contact['name']),
                  onTap: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          otherUserId: contact['id'],
                          otherUserName: contact['name'],
                          otherUserAvatar: contact['avatar'],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('لغو'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در بارگذاری مخاطبین: $e')),
      );
    }
  }
}
