import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../services/broadcast_service.dart';
import '../../services/supabase_service.dart';
import '../../utils/safe_set_state.dart';
import '../../widgets/user_role_badge.dart';

class BroadcastMessagesScreen extends StatefulWidget {
  const BroadcastMessagesScreen({Key? key}) : super(key: key);

  @override
  State<BroadcastMessagesScreen> createState() =>
      _BroadcastMessagesScreenState();
}

class _BroadcastMessagesScreenState extends State<BroadcastMessagesScreen> {
  final BroadcastService _broadcastService = BroadcastService();
  final SupabaseService _supabaseService = SupabaseService();
  final TextEditingController _messageController = TextEditingController();

  List<Map<String, dynamic>> _broadcastMessages = [];
  List<Map<String, dynamic>> _clients = [];
  final List<String> _selectedClientIds = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _currentUserId;
  String? _userRole;
  String _recipientType = 'all'; // 'all' or 'specific'

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = await _supabaseService.getProfileByAuthId();
      if (user != null) {
        setState(() {
          _currentUserId = user.id;
          _userRole = user.role;
        });
        await Future.wait([
          _loadBroadcastMessages(),
          _loadClients(),
        ]);
      }
    } catch (e) {
      debugPrint('Error loading user info: $e');
    }
  }

  Future<void> _loadBroadcastMessages() async {
    try {
      SafeSetState.call(this, () => _isLoading = true);
      final messages =
          await _broadcastService.getBroadcastMessages(_currentUserId!);
      SafeSetState.call(this, () {
        _broadcastMessages = messages;
        _isLoading = false;
      });
    } catch (e) {
      SafeSetState.call(this, () => _isLoading = false);
      debugPrint('Error loading broadcast messages: $e');
    }
  }

  Future<void> _loadClients() async {
    try {
      if (_userRole == 'trainer') {
        final response =
            await Supabase.instance.client.from('trainer_clients').select('''
              *,
              client:profiles!trainer_clients_client_id_fkey(
                id,
                username,
                first_name,
                last_name,
                avatar_url,
                role
              )
            ''').eq('trainer_id', _currentUserId!).eq('status', 'active');

        _clients = response.map((data) {
          final clientProfile = data['client'] as Map<String, dynamic>;
          return {
            'id': data['client_id'],
            'name': '${clientProfile['first_name'] ?? ''} ${clientProfile['last_name'] ?? ''}'
                    .trim()
                    .isNotEmpty
                ? '${clientProfile['first_name'] ?? ''} ${clientProfile['last_name'] ?? ''}'
                    .trim()
                : clientProfile['username'] ?? 'کاربر',
            'avatar': clientProfile['avatar_url'],
            'role': clientProfile['role'] ?? 'athlete',
          };
        }).toList();
      }
    } catch (e) {
      debugPrint('Error loading clients: $e');
    }
  }

  Future<void> _sendBroadcastMessage() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً پیام خود را وارد کنید')),
      );
      return;
    }

    if (_recipientType == 'specific' && _selectedClientIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً حداقل یک شاگرد را انتخاب کنید')),
      );
      return;
    }

    try {
      SafeSetState.call(this, () => _isSending = true);

      bool success;
      if (_recipientType == 'all') {
        success = await _broadcastService.sendBroadcastToAll(
          _currentUserId!,
          _messageController.text.trim(),
        );
      } else {
        success = await _broadcastService.sendBroadcastToSpecific(
          _currentUserId!,
          _messageController.text.trim(),
          _selectedClientIds,
        );
      }

      if (success) {
        _messageController.clear();
        _selectedClientIds.clear();
        await _loadBroadcastMessages();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('پیام با موفقیت ارسال شد')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('خطا در ارسال پیام')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error sending broadcast: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در ارسال پیام: $e')),
        );
      }
    } finally {
      SafeSetState.call(this, () => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userRole != 'trainer') {
      return Scaffold(
        appBar: AppBar(
          title: const Text('پیام‌های عمومی'),
          backgroundColor: AppTheme.goldColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('این بخش فقط برای مربیان در دسترس است'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('پیام‌های عمومی'),
        backgroundColor: AppTheme.goldColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildSendMessageSection(),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.goldColor))
                : _broadcastMessages.isEmpty
                    ? _buildEmptyState()
                    : _buildMessagesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSendMessageSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recipient type selector
          Row(
            children: [
              const Text('ارسال به:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
              ChoiceChip(
                label: const Text('همه شاگردان'),
                selected: _recipientType == 'all',
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _recipientType = 'all';
                      _selectedClientIds.clear();
                    });
                  }
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('شاگردان خاص'),
                selected: _recipientType == 'specific',
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _recipientType = 'specific';
                    });
                  }
                },
              ),
            ],
          ),

          // Client selection for specific recipients
          if (_recipientType == 'specific') ...[
            const SizedBox(height: 12),
            const Text('انتخاب شاگردان:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _clients.length,
                itemBuilder: (context, index) {
                  final client = _clients[index];
                  final isSelected = _selectedClientIds.contains(client['id']);

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedClientIds.remove(client['id']);
                          } else {
                            _selectedClientIds.add(client['id']);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.goldColor
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.goldColor
                                : Colors.grey[300]!,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundImage: client['avatar'] != null
                                  ? NetworkImage(client['avatar'])
                                  : null,
                              child: client['avatar'] == null
                                  ? Text(client['name'][0].toUpperCase())
                                  : null,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              client['name'],
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Message input
          TextField(
            controller: _messageController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'پیام خود را بنویسید...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.goldColor),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Send button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSending ? null : _sendBroadcastMessage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.goldColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isSending
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('ارسال پیام'),
            ),
          ),
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
            LucideIcons.messageCircle,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'هنوز پیام عمومی‌ای ارسال نکرده‌اید',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'پیام‌های عمومی برای همه شاگردان شما قابل مشاهده خواهد بود',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _broadcastMessages.length,
      itemBuilder: (context, index) {
        final message = _broadcastMessages[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: message['sender_avatar'] != null
                          ? NetworkImage(message['sender_avatar'])
                          : null,
                      child: message['sender_avatar'] == null
                          ? Text(message['sender_name'][0].toUpperCase())
                          : null,
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
                                  message['sender_name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              UserRoleBadge(
                                role: message['sender_role'],
                                fontSize: 10,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            message['recipient_type'] == 'all'
                                ? 'ارسال شده به همه شاگردان'
                                : 'ارسال شده به شاگردان خاص',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!message['is_read'])
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  message['message'],
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatDate(message['created_at']),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays} روز پیش';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} ساعت پیش';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} دقیقه پیش';
      } else {
        return 'همین الان';
      }
    } catch (e) {
      return dateString;
    }
  }
}
