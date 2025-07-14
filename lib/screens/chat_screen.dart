// صفحه چت

import 'package:flutter/material.dart';
import 'package:gymaipro/models/chat_message.dart';
import 'package:gymaipro/services/chat_service.dart';
import 'package:gymaipro/services/supabase_service.dart';
import 'package:gymaipro/theme/app_colors.dart';
import '../widgets/message_bubble.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;

  const ChatScreen({
    Key? key,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late ChatService _chatService;
  late String _currentUserId;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _canLoadMore = true;
  bool _isLoadingMore = false;
  int _currentOffset = 0;
  final int _pageSize = 20;
  StreamSubscription? _messageSubscription;

  @override
  void initState() {
    super.initState();
    _chatService = ChatService(
      supabaseService: Provider.of<SupabaseService>(context, listen: false),
    );

    _currentUserId = Supabase.instance.client.auth.currentUser!.id;

    _loadMessages();
    _subscribeToMessages();

    // Mark messages as read when opening the chat
    _markMessagesAsRead();

    // Add scroll listener for pagination
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _messageSubscription?.cancel();
    super.dispose();
  }

  void _scrollListener() {
    // Load more messages when user scrolls to the top
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        _canLoadMore &&
        !_isLoadingMore) {
      _loadMoreMessages();
    }
  }

  Future<void> _loadMessages() async {
    try {
      setState(() {
        _isLoading = true;
        _currentOffset = 0;
      });

      final messages = await _chatService.getMessages(
        widget.otherUserId,
        limit: _pageSize,
        offset: _currentOffset,
      );

      if (mounted) {
        setState(() {
          _messages.clear();
          _messages.addAll(messages);
          _isLoading = false;
          _canLoadMore = messages.length == _pageSize;
          _currentOffset += messages.length;
        });

        // Scroll to bottom after messages load
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(0);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در بارگذاری پیام‌ها: $e')),
        );
      }
    }
  }

  Future<void> _loadMoreMessages() async {
    if (!_canLoadMore || _isLoadingMore) return;

    try {
      setState(() {
        _isLoadingMore = true;
      });

      final messages = await _chatService.getMessages(
        widget.otherUserId,
        limit: _pageSize,
        offset: _currentOffset,
      );

      if (mounted) {
        setState(() {
          _messages.addAll(messages);
          _isLoadingMore = false;
          _canLoadMore = messages.length == _pageSize;
          _currentOffset += messages.length;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در بارگذاری پیام‌های بیشتر: $e')),
        );
      }
    }
  }

  void _subscribeToMessages() {
    try {
      final stream = _chatService.subscribeToMessages(widget.otherUserId);
      _messageSubscription = stream.listen((message) {
        _addNewMessage(message);

        // Mark message as read if it's from the other user
        if (message.senderId != _currentUserId) {
          _markMessagesAsRead();
        }
      });
    } catch (e) {
      debugPrint('Error subscribing to messages: $e');
    }
  }

  void _addNewMessage(ChatMessage newMessage) {
    // Check if message already exists to avoid duplicates
    final exists = _messages.any((msg) => msg.id == newMessage.id);
    if (!exists) {
      setState(() {
        _messages.insert(0, newMessage);
      });
    }
  }

  Future<void> _markMessagesAsRead() async {
    try {
      await _chatService.markMessagesAsRead(widget.otherUserId);
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _isSending = true;
    });

    try {
      _messageController.clear();

      await _chatService.sendMessage(
        receiverId: widget.otherUserId,
        message: message,
      );

      // No need to add manually as it will come through the subscription

      setState(() {
        _isSending = false;
      });
    } catch (e) {
      setState(() {
        _isSending = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در ارسال پیام: $e')),
        );
      }
    }
  }

  String _formatMessageDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'امروز ${DateFormat.Hm().format(date)}';
    } else if (messageDate == yesterday) {
      return 'دیروز ${DateFormat.Hm().format(date)}';
    } else {
      return DateFormat('yyyy/MM/dd HH:mm').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
              backgroundImage: widget.otherUserAvatar != null
                  ? NetworkImage(widget.otherUserAvatar!)
                  : null,
              child: widget.otherUserAvatar == null
                  ? Text(
                      widget.otherUserName.isNotEmpty
                          ? widget.otherUserName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Text(widget.otherUserName),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMessages,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : _buildMessagesList(),
          ),
          _buildInputArea(),
        ],
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
            'هنوز پیامی ارسال نشده است',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'اولین پیام خود را ارسال کنید',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    // Group messages by date
    final Map<String, List<ChatMessage>> groupedMessages = {};

    for (final message in _messages) {
      final dateStr = DateFormat('yyyy-MM-dd').format(message.createdAt);
      if (!groupedMessages.containsKey(dateStr)) {
        groupedMessages[dateStr] = [];
      }
      groupedMessages[dateStr]!.add(message);
    }

    final sortedDates = groupedMessages.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      controller: _scrollController,
      reverse: true, // Latest messages at the bottom
      padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
      itemCount: sortedDates.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (_isLoadingMore && index == 0) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        final actualIndex = _isLoadingMore ? index - 1 : index;
        final date = sortedDates[actualIndex];
        final messagesForDate = groupedMessages[date]!;

        return Column(
          children: [
            _buildDateHeader(date),
            ...messagesForDate.map((message) => _buildMessageBubble(message)),
          ],
        );
      },
    );
  }

  Widget _buildDateHeader(String dateStr) {
    final date = DateTime.parse(dateStr);
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          _formatMessageDate(date),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isCurrentUser = message.senderId == _currentUserId;

    return ChatMessageBubble(
      message: message,
      isCurrentUser: isCurrentUser,
      onLongPress: isCurrentUser ? () => _showDeleteDialog(message) : null,
    );
  }

  void _showDeleteDialog(ChatMessage message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف پیام'),
        content: const Text('آیا از حذف این پیام اطمینان دارید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لغو'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMessage(message);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMessage(ChatMessage message) async {
    try {
      await _chatService.deleteMessage(message.id);

      setState(() {
        _messages.remove(message);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در حذف پیام: $e')),
        );
      }
    }
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: () {
              // TODO: Implement attachment functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('این قابلیت در آینده اضافه خواهد شد')),
              );
            },
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'پیام خود را بنویسید...',
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: _isSending
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send, color: AppColors.primary),
            onPressed: _isSending ? null : _sendMessage,
          ),
        ],
      ),
    );
  }
}
