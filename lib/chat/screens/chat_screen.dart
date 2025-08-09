// صفحه چت - نسخه بهبود یافته

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../theme/app_theme.dart';
import '../../../services/chat_service.dart';
import '../../../services/supabase_service.dart';
import '../../../models/chat_message.dart';
import '../../../widgets/chat_message_bubble.dart';
import '../../../utils/safe_set_state.dart';

class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;

  const ChatScreen({
    Key? key,
    required this.otherUserId,
    required this.otherUserName,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  late ChatService _chatService;
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isLoadingMore = false;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Real-time subscriptions
  StreamSubscription<ChatMessage>? _messageSubscription;

  // User state
  String? _currentUserId;
  String? _otherUserRole;
  bool _isOtherUserOnline = false;
  DateTime? _otherUserLastSeen;

  // Error handling
  String? _errorMessage;
  bool _hasMoreMessages = true;
  int _currentPage = 0;
  static const int _messagesPerPage = 20;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeChat();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _scrollController.dispose();
    _messageSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _updateUserPresence(true);
    } else if (state == AppLifecycleState.paused) {
      _updateUserPresence(false);
    }
  }

  Future<void> _initializeChat() async {
    try {
      _chatService = ChatService(supabaseService: SupabaseService());
      _currentUserId = Supabase.instance.client.auth.currentUser?.id;

      if (_currentUserId == null) {
        throw Exception('کاربر احراز هویت نشده');
      }

      // Load data in parallel
      await Future.wait([
        _loadOtherUserInfo(),
        _loadMessages(),
        _setupPresence(),
      ]);

      _subscribeToMessages();
      _markConversationAsRead();
    } catch (e) {
      SafeSetState.call(this, () {
        _isLoading = false;
        _errorMessage = 'خطا در راه‌اندازی چت: $e';
      });
    }
  }

  Future<void> _loadOtherUserInfo() async {
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('role, last_seen_at')
          .eq('id', widget.otherUserId)
          .single();

      SafeSetState.call(this, () {
        _otherUserRole = response['role'] as String?;
        _otherUserLastSeen = response['last_seen_at'] != null
            ? DateTime.parse(response['last_seen_at'])
            : null;
        _updateOnlineStatus();
      });
    } catch (e) {
      debugPrint('Error loading other user info: $e');
    }
  }

  void _updateOnlineStatus() {
    if (_otherUserLastSeen == null) {
      _isOtherUserOnline = false;
      return;
    }

    final now = DateTime.now();
    final difference = now.difference(_otherUserLastSeen!);
    _isOtherUserOnline =
        difference.inMinutes < 5; // Online if seen in last 5 minutes
  }

  Future<void> _setupPresence() async {
    try {
      // Simple presence tracking - just update last_seen
      await _updateUserPresence(true);
    } catch (e) {
      debugPrint('Error setting up presence: $e');
    }
  }

  Future<void> _updateUserPresence(bool isOnline) async {
    try {
      if (_currentUserId != null) {
        await Supabase.instance.client.from('profiles').update({
          'last_seen_at': DateTime.now().toIso8601String(),
          'is_online': isOnline,
        }).eq('id', _currentUserId!);
      }
    } catch (e) {
      debugPrint('Error updating presence: $e');
    }
  }

  Future<void> _loadMessages() async {
    try {
      SafeSetState.call(this, () {
        _isLoading = true;
        _errorMessage = null;
      });

      final messages = await _chatService.getMessages(
        widget.otherUserId,
        limit: _messagesPerPage,
        offset: 0,
      );

      SafeSetState.call(this, () {
        _messages = messages;
        _isLoading = false;
        _currentPage = 1;
        _hasMoreMessages = messages.length >= _messagesPerPage;
      });

      _scrollToBottom();
    } catch (e) {
      SafeSetState.call(this, () {
        _isLoading = false;
        _errorMessage = 'خطا در بارگیری پیام‌ها';
      });
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore || !_hasMoreMessages) return;

    try {
      SafeSetState.call(this, () => _isLoadingMore = true);

      final moreMessages = await _chatService.getMessages(
        widget.otherUserId,
        limit: _messagesPerPage,
        offset: _currentPage * _messagesPerPage,
      );

      if (moreMessages.isNotEmpty) {
        SafeSetState.call(this, () {
          _messages.insertAll(0, moreMessages);
          _currentPage++;
          _hasMoreMessages = moreMessages.length >= _messagesPerPage;
        });
      } else {
        SafeSetState.call(this, () {
          _hasMoreMessages = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading more messages: $e');
    } finally {
      SafeSetState.call(this, () => _isLoadingMore = false);
    }
  }

  void _subscribeToMessages() {
    _messageSubscription =
        _chatService.subscribeToMessages(widget.otherUserId).listen(
      (message) {
        // Only add if message is not already in the list
        if (!_messages.any((m) => m.id == message.id)) {
          SafeSetState.call(this, () {
            _messages.add(message);
          });
          _scrollToBottom();
          _markConversationAsRead();
        }
      },
      onError: (error) {
        debugPrint('Message subscription error: $error');
      },
    );
  }

  Future<void> _markConversationAsRead() async {
    try {
      await _chatService.markConversationAsRead(widget.otherUserId);
    } catch (e) {
      debugPrint('Error marking conversation as read: $e');
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSending) return;

    // Create optimistic message
    final tempMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: _currentUserId!,
      receiverId: widget.otherUserId,
      message: message,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    SafeSetState.call(this, () {
      _isSending = true;
      _messages.add(tempMessage);
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      final sentMessage = await _chatService.sendMessage(
        receiverId: widget.otherUserId,
        message: message,
      );

      // Replace temp message with real message
      SafeSetState.call(this, () {
        final index = _messages.indexWhere((m) => m.id == tempMessage.id);
        if (index != -1) {
          _messages[index] = sentMessage;
        }
      });
    } catch (e) {
      // Remove temp message on error
      SafeSetState.call(this, () {
        _messages.removeWhere((m) => m.id == tempMessage.id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در ارسال پیام: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'تلاش مجدد',
              textColor: Colors.white,
              onPressed: () => _sendMessage(),
            ),
          ),
        );
      }
    } finally {
      SafeSetState.call(this, () => _isSending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _refreshMessages() async {
    await _loadMessages();
  }

  Future<void> _deleteMessage(ChatMessage message) async {
    try {
      await _chatService.deleteMessage(message.id);

      // Update local state immediately
      SafeSetState.call(this, () {
        _messages.removeWhere((m) => m.id == message.id);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در حذف پیام: $e')),
        );
      }
    }
  }

  Future<void> _editMessage(ChatMessage message, String newText) async {
    try {
      await _chatService.editMessage(message.id, newText);

      // Update local state immediately
      SafeSetState.call(this, () {
        final index = _messages.indexWhere((m) => m.id == message.id);
        if (index != -1) {
          _messages[index] = _messages[index].copyWith(
            message: newText,
            updatedAt: DateTime.now(),
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در ویرایش پیام: $e')),
        );
      }
    }
  }

  String _getStatusText() {
    if (_isOtherUserOnline) {
      return 'آنلاین';
    } else if (_otherUserLastSeen != null) {
      final now = DateTime.now();
      final difference = now.difference(_otherUserLastSeen!);

      if (difference.inMinutes < 1) {
        return 'چند لحظه پیش';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} دقیقه پیش';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} ساعت پیش';
      } else {
        return '${difference.inDays} روز پیش';
      }
    } else {
      return 'آفلاین';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: _buildMessagesList(),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.cardColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(LucideIcons.arrowRight, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              LucideIcons.user,
              color: Colors.blue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.otherUserName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (_otherUserRole != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _otherUserRole == 'trainer'
                              ? Colors.purple.withValues(alpha: 0.2)
                              : Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _otherUserRole == 'trainer' ? 'مربی' : 'کاربر',
                          style: TextStyle(
                            color: _otherUserRole == 'trainer'
                                ? Colors.purple
                                : Colors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _isOtherUserOnline ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _getStatusText(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.phone, color: Colors.white),
          onPressed: () {
            // TODO: Implement voice call
          },
        ),
        IconButton(
          icon: const Icon(LucideIcons.video, color: Colors.white),
          onPressed: () {
            // TODO: Implement video call
          },
        ),
        IconButton(
          icon: const Icon(LucideIcons.moreVertical, color: Colors.white),
          onPressed: () {
            _showChatOptions();
          },
        ),
      ],
    );
  }

  Widget _buildMessagesList() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.goldColor),
            SizedBox(height: 16),
            Text(
              'در حال بارگذاری پیام‌ها...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.alertCircle,
              color: Colors.red.withValues(alpha: 0.5),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadMessages,
              icon: const Icon(LucideIcons.refreshCw),
              label: const Text('تلاش مجدد'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.goldColor,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      );
    }

    if (_messages.isEmpty) {
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
                LucideIcons.messageCircle,
                color: AppTheme.goldColor.withValues(alpha: 0.5),
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'هنوز پیامی ارسال نشده',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'شروع به گفتگو کنید',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshMessages,
      color: AppTheme.goldColor,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _messages.length + (_hasMoreMessages ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == 0 && _hasMoreMessages) {
            return _buildLoadMoreIndicator();
          }

          final messageIndex = _hasMoreMessages ? index - 1 : index;
          final message = _messages[messageIndex];
          final isMe = message.senderId == _currentUserId;

          return ChatMessageBubble(
            message: message,
            isMe: isMe,
            onLongPress: () => _showMessageOptions(message),
          );
        },
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: _isLoadingMore
            ? const CircularProgressIndicator(color: AppTheme.goldColor)
            : TextButton.icon(
                onPressed: _loadMoreMessages,
                icon: const Icon(LucideIcons.chevronUp,
                    color: AppTheme.goldColor),
                label: const Text(
                  'بارگذاری پیام‌های بیشتر',
                  style: TextStyle(color: AppTheme.goldColor),
                ),
              ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(LucideIcons.plus, color: Colors.blue),
              onPressed: () {
                _showAttachmentOptions();
              },
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'پیام خود را بنویسید...',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(24),
              ),
              child: IconButton(
                icon: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        LucideIcons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                onPressed: _isSending ? null : _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.search, color: Colors.blue),
              title: const Text('جستجو در گفتگو',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement search
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.bell, color: Colors.blue),
              title: const Text('تنظیمات اعلان',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement notification settings
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.trash2, color: Colors.red),
              title:
                  const Text('حذف گفتگو', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteConversation();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMessageOptions(ChatMessage message) {
    if (message.senderId != _currentUserId) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.edit, color: Colors.blue),
              title:
                  const Text('ویرایش', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _editMessageDialog(message);
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.copy, color: Colors.blue),
              title: const Text('کپی', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement copy
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.trash2, color: Colors.red),
              title: const Text('حذف', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteMessage(message);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _editMessageDialog(ChatMessage message) {
    final editController = TextEditingController(text: message.message);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text('ویرایش پیام', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: editController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لغو'),
          ),
          TextButton(
            onPressed: () async {
              final newText = editController.text.trim();
              if (newText.isNotEmpty && newText != message.message) {
                Navigator.pop(context);
                await _editMessage(message, newText);
              }
            },
            child: const Text('ذخیره'),
          ),
        ],
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.image, color: Colors.blue),
              title: const Text('عکس', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement image picker
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.file, color: Colors.blue),
              title: const Text('فایل', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement file picker
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.mic, color: Colors.blue),
              title: const Text('صوت', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement voice recording
              },
            ),
          ],
        ),
      ),
    );
  }

  void _deleteConversation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text('حذف گفتگو', style: TextStyle(color: Colors.white)),
        content: const Text(
          'آیا مطمئن هستید که می‌خواهید این گفتگو را حذف کنید؟',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لغو'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // TODO: Implement conversation deletion
              Navigator.of(context).pop();
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
