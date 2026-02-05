import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/admin/services/admin_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// صفحه مدیریت چت عمومی
class AdminPublicChatScreen extends StatefulWidget {
  const AdminPublicChatScreen({super.key});

  @override
  State<AdminPublicChatScreen> createState() => _AdminPublicChatScreenState();
}

class _AdminPublicChatScreenState extends State<AdminPublicChatScreen> {
  final AdminService _adminService = AdminService();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  bool _showDeleted = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final messages = await _adminService.getAllPublicChatMessages(
        includeDeleted: _showDeleted,
      );
      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در بارگذاری پیام‌ها: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteMessage(String messageId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف پیام'),
        content: const Text('آیا مطمئن هستید که می‌خواهید این پیام را حذف کنید؟'),
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

    final success = await _adminService.deletePublicChatMessage(messageId);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('پیام با موفقیت حذف شد'),
            backgroundColor: Colors.green,
          ),
        );
        _loadMessages();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خطا در حذف پیام'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _restoreMessage(String messageId) async {
    final success = await _adminService.restorePublicChatMessage(messageId);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('پیام با موفقیت بازیابی شد'),
            backgroundColor: Colors.green,
          ),
        );
        _loadMessages();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خطا در بازیابی پیام'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getSenderName(Map<String, dynamic> message) {
    final sender = message['sender'] as Map<String, dynamic>?;
    if (sender == null) return 'کاربر ناشناس';

    final firstName = sender['first_name'] as String?;
    final lastName = sender['last_name'] as String?;
    final username = sender['username'] as String?;

    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    } else if (firstName != null) {
      return firstName;
    } else if (username != null) {
      return username;
    }
    return 'کاربر ناشناس';
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        // فیلتر
        Container(
          padding: EdgeInsets.all(16.w),
          color: isDark ? AppTheme.darkCardColor : AppTheme.lightCardColor,
          child: Row(
            children: [
              Expanded(
                child: SwitchListTile(
                  title: const Text('نمایش پیام‌های حذف شده'),
                  value: _showDeleted,
                  onChanged: (value) {
                    setState(() => _showDeleted = value);
                    _loadMessages();
                  },
                ),
              ),
            ],
          ),
        ),
        // لیست پیام‌ها
        Expanded(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.goldColor,
                  ),
                )
              : _messages.isEmpty
                  ? Center(
                      child: Text(
                        'پیامی یافت نشد',
                        style: TextStyle(
                          color: isDark
                              ? AppTheme.darkTextColor.withValues(alpha: 0.7)
                              : AppTheme.lightTextSecondary,
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadMessages,
                      color: AppTheme.goldColor,
                      child: ListView.builder(
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isDeleted = message['is_deleted'] as bool? ?? false;

                          return Card(
                            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                            color: isDark ? AppTheme.darkCardColor : AppTheme.lightCardColor,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isDeleted
                                    ? Colors.grey.withValues(alpha: 0.2)
                                    : AppTheme.goldColor.withValues(alpha: 0.2),
                                child: Icon(
                                  isDeleted ? LucideIcons.trash2 : LucideIcons.messageCircle,
                                  color: isDeleted ? Colors.grey : AppTheme.goldColor,
                                ),
                              ),
                              title: Text(
                                _getSenderName(message),
                                style: TextStyle(
                                  color: isDark ? AppTheme.darkTextColor : AppTheme.lightTextColor,
                                  fontWeight: FontWeight.bold,
                                  decoration: isDeleted ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message['message'] as String? ?? '',
                                    style: TextStyle(
                                      color: isDeleted
                                          ? Colors.grey
                                          : (isDark
                                              ? AppTheme.darkTextColor.withValues(alpha: 0.7)
                                              : AppTheme.lightTextSecondary),
                                      decoration: isDeleted ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    _formatDate(message['created_at'] as String?),
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
                                  if (isDeleted)
                                    PopupMenuItem<void>(
                                      child: const Row(
                                        children: [
                                          Icon(LucideIcons.rotateCcw, size: 18),
                                          SizedBox(width: 8),
                                          Text('بازیابی'),
                                        ],
                                      ),
                                      onTap: () => _restoreMessage(message['id'] as String),
                                    )
                                  else
                                    PopupMenuItem<void>(
                                      child: Row(
                                        children: [
                                          Icon(LucideIcons.trash2, size: 18, color: Colors.red),
                                          SizedBox(width: 8.w),
                                          Text(
                                            'حذف',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ],
                                      ),
                                      onTap: () => _deleteMessage(message['id'] as String),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}

