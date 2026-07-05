import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/admin/services/admin_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/widgets/gymai_network_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// صفحه مدیریت چت‌های خصوصی
class AdminChatManagementScreen extends StatefulWidget {
  const AdminChatManagementScreen({super.key});

  @override
  State<AdminChatManagementScreen> createState() => _AdminChatManagementScreenState();
}

class _AdminChatManagementScreenState extends State<AdminChatManagementScreen> {
  final AdminService _adminService = AdminService();
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);
    try {
      final conversations = await _adminService.getAllPrivateConversations();
      if (mounted) {
        setState(() {
          _conversations = conversations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در بارگذاری مکالمات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteConversation(String conversationId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف مکالمه'),
        content: const Text('آیا مطمئن هستید که می‌خواهید این مکالمه را حذف کنید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('لغو'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await _adminService.deletePrivateConversation(conversationId);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('مکالمه با موفقیت حذف شد'),
            backgroundColor: Colors.green,
          ),
        );
        _loadConversations();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خطا در حذف مکالمه'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendWarning(String conversationId) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ارسال هشدار'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'متن هشدار را وارد کنید...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لغو'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: const Text('ارسال'),
          ),
        ],
      ),
    );

    if (confirmed == null || confirmed.isEmpty) return;

    final warningMessage = confirmed;

    final success = await _adminService.sendWarningToConversation(
      conversationId,
      warningMessage,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('هشدار با موفقیت ارسال شد'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خطا در ارسال هشدار'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showConversationDetails(Map<String, dynamic> conversation) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildConversationDetailsSheet(conversation),
    );
  }

  Widget _buildConversationDetailsSheet(Map<String, dynamic> conversation) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user1 = conversation['user1'] as Map<String, dynamic>?;
    final user2 = conversation['user2'] as Map<String, dynamic>?;
    
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardColor : AppTheme.lightCardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'جزئیات مکالمه',
                      style: TextStyle(
                        color: isDark ? AppTheme.darkTextColor : AppTheme.lightTextColor,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${_getUserName(user1)} ↔ ${_getUserName(user2)}',
                      style: TextStyle(
                        color: isDark
                            ? AppTheme.darkTextColor.withValues(alpha: 0.7)
                            : AppTheme.lightTextSecondary,
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(LucideIcons.x),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _adminService.getConversationMessages(conversation['id'] as String),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SizedBox(
                  height: 400.h,
                  child: const Center(child: CircularProgressIndicator()),
                );
              }

              final messages = snapshot.data ?? [];
              if (messages.isEmpty) {
                return SizedBox(
                  height: 200.h,
                  child: Center(
                    child: Text(
                      'پیامی در این مکالمه وجود ندارد',
                      style: TextStyle(
                        color: isDark
                            ? AppTheme.darkTextColor.withValues(alpha: 0.7)
                            : AppTheme.lightTextSecondary,
                      ),
                    ),
                  ),
                );
              }

              return SizedBox(
                height: 500.h,
                child: ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final senderId = message['sender_id'] as String?;
                    final senderName = message['sender_name'] as String? ?? 'کاربر ناشناس';
                    final messageText = message['message'] as String? ?? '';
                    final messageType = message['message_type'] as String?;
                    final isAdminWarning = messageType == 'admin_warning';
                    final isUser1 = senderId == (conversation['user1_id'] as String?);
                    final attachmentUrl = message['attachment_url'] as String?;
                    final attachmentType = message['attachment_type'] as String?;

                    return Container(
                      margin: EdgeInsets.only(bottom: 12.h),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: isUser1
                            ? MainAxisAlignment.start
                            : MainAxisAlignment.end,
                        children: [
                          if (isUser1) ...[
                            CircleAvatar(
                              radius: 16.r,
                              backgroundColor: AppTheme.goldColor.withValues(alpha: 0.2),
                              child: Text(
                                senderName.isNotEmpty ? senderName[0].toUpperCase() : '?',
                                style: TextStyle(
                                  color: AppTheme.goldColor,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                          ],
                          Flexible(
                            child: Container(
                              padding: EdgeInsets.all(12.w),
                              decoration: BoxDecoration(
                                color: isAdminWarning
                                    ? Colors.orange.withValues(alpha: 0.2)
                                    : (isUser1
                                        ? AppTheme.goldColor.withValues(alpha: 0.1)
                                        : (isDark
                                            ? AppTheme.darkGreySeparator
                                            : Colors.grey.shade200)),
                                borderRadius: BorderRadius.circular(12.r),
                                border: isAdminWarning
                                    ? Border.all(color: Colors.orange)
                                    : null,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      if (isAdminWarning)
                                        Icon(
                                          LucideIcons.shield,
                                          size: 14.sp,
                                          color: Colors.orange,
                                        ),
                                      if (isAdminWarning) SizedBox(width: 4.w),
                                      Text(
                                        senderName,
                                        style: TextStyle(
                                          color: isAdminWarning
                                              ? Colors.orange
                                              : (isDark
                                                  ? AppTheme.darkTextColor
                                                  : AppTheme.lightTextColor),
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4.h),
                                  if (attachmentUrl != null && attachmentType == 'image')
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8.r),
                                      child: GymaiNetworkImage(
                                        imageUrl: attachmentUrl,
                                        width: 200.w,
                                        height: 200.h,
                                        errorWidget:
                                            const Icon(LucideIcons.imageOff),
                                      ),
                                    )
                                  else
                                    Text(
                                      messageText,
                                      style: TextStyle(
                                        color: isDark
                                            ? AppTheme.darkTextColor
                                            : AppTheme.lightTextColor,
                                        fontSize: 14.sp,
                                      ),
                                    ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    _formatDate(message['created_at'] as String?),
                                    style: TextStyle(
                                      color: isDark
                                          ? AppTheme.darkTextColor.withValues(alpha: 0.5)
                                          : AppTheme.lightTextSecondary,
                                      fontSize: 10.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (!isUser1) ...[
                            SizedBox(width: 8.w),
                            CircleAvatar(
                              radius: 16.r,
                              backgroundColor: AppTheme.goldColor.withValues(alpha: 0.2),
                              child: Text(
                                senderName.isNotEmpty ? senderName[0].toUpperCase() : '?',
                                style: TextStyle(
                                  color: AppTheme.goldColor,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.year}/${date.month}/${date.day} ${date.hour}:${date.minute}';
    } catch (e) {
      return dateString;
    }
  }

  String _getUserName(Map<String, dynamic>? user) {
    if (user == null) return 'کاربر ناشناس';
    final firstName = user['first_name'] as String?;
    final lastName = user['last_name'] as String?;
    final username = user['username'] as String?;

    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    } else if (firstName != null) {
      return firstName;
    } else if (username != null) {
      return username;
    }
    return 'کاربر ناشناس';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _isLoading
        ? const Center(
            child: CircularProgressIndicator(
              color: AppTheme.goldColor,
            ),
          )
        : _conversations.isEmpty
            ? Center(
                child: Text(
                  'مکالمه‌ای یافت نشد',
                  style: TextStyle(
                    color: isDark
                        ? AppTheme.darkTextColor.withValues(alpha: 0.7)
                        : AppTheme.lightTextSecondary,
                  ),
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadConversations,
                color: AppTheme.goldColor,
                child: ListView.builder(
                  itemCount: _conversations.length,
                  itemBuilder: (context, index) {
                    final conversation = _conversations[index];
                    final user1 = conversation['user1'] as Map<String, dynamic>?;
                    final user2 = conversation['user2'] as Map<String, dynamic>?;

                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      color: isDark ? AppTheme.darkCardColor : AppTheme.lightCardColor,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.goldColor.withValues(alpha: 0.2),
                          child: const Icon(LucideIcons.messageSquare),
                        ),
                        title: Text(
                          '${_getUserName(user1)} ↔ ${_getUserName(user2)}',
                          style: TextStyle(
                            color: isDark ? AppTheme.darkTextColor : AppTheme.lightTextColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (conversation['last_message'] != null)
                              Text(
                                conversation['last_message'] as String,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isDark
                                      ? AppTheme.darkTextColor.withValues(alpha: 0.7)
                                      : AppTheme.lightTextSecondary,
                                ),
                              ),
                            Text(
                              'تعداد پیام: ${conversation['message_count'] ?? 0}',
                              style: TextStyle(
                                color: isDark
                                    ? AppTheme.darkTextColor.withValues(alpha: 0.5)
                                    : AppTheme.lightTextSecondary,
                                fontSize: 12.sp,
                              ),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          icon: const Icon(LucideIcons.moreVertical),
                          itemBuilder: (context) => [
                            PopupMenuItem<void>(
                              child: const Row(
                                children: [
                                  Icon(LucideIcons.eye, size: 18),
                                  SizedBox(width: 8),
                                  Text('مشاهده پیام‌ها'),
                                ],
                              ),
                              onTap: () => _showConversationDetails(conversation),
                            ),
                            PopupMenuItem<void>(
                              child: const Row(
                                children: [
                                  Icon(LucideIcons.alertTriangle, size: 18),
                                  SizedBox(width: 8),
                                  Text('ارسال هشدار'),
                                ],
                              ),
                              onTap: () => _sendWarning(conversation['id'] as String),
                            ),
                            PopupMenuItem<void>(
                              child: Row(
                                children: [
                                  const Icon(LucideIcons.trash2, size: 18, color: Colors.red),
                                  SizedBox(width: 8.w),
                                  const Text(
                                    'حذف مکالمه',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                              onTap: () => _deleteConversation(conversation['id'] as String),
                            ),
                          ],
                        ),
                        onTap: () => _showConversationDetails(conversation),
                      ),
                    );
                  },
                ),
              );
  }
}

