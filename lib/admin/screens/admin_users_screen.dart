import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/admin/services/admin_service.dart';
import 'package:gymaipro/profile/models/user_profile.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// صفحه مدیریت کاربران
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final AdminService _adminService = AdminService();
  final TextEditingController _searchController = TextEditingController();
  List<UserProfile> _users = [];
  bool _isLoading = false;
  String _selectedRoleFilter = 'all';
  int _currentPage = 0;
  final int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers({bool reset = false}) async {
    if (reset) {
      _currentPage = 0;
    }

    setState(() => _isLoading = true);
    try {
      final users = await _adminService.getAllUsers(
        searchQuery: _searchController.text.isEmpty ? null : _searchController.text,
        roleFilter: _selectedRoleFilter == 'all' ? null : _selectedRoleFilter,
        limit: _pageSize,
        offset: _currentPage * _pageSize,
      );

      if (mounted) {
        setState(() {
          if (reset) {
            _users = users;
          } else {
            _users.addAll(users);
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در بارگذاری کاربران: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateUserRole(UserProfile user, String newRole) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تغییر نقش کاربر'),
        content: Text('آیا مطمئن هستید که می‌خواهید نقش ${user.username} را به $newRole تغییر دهید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('لغو'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تایید'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await _adminService.updateUserRole(user.id!, newRole);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('نقش کاربر با موفقیت تغییر کرد'),
            backgroundColor: Colors.green,
          ),
        );
        _loadUsers(reset: true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خطا در تغییر نقش کاربر'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteUserAccount(UserProfile user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف اکانت کاربر'),
        content: Text(
          'آیا مطمئن هستید که می‌خواهید اکانت ${user.username} را حذف کنید؟\n\nاین عمل غیرقابل بازگشت است!',
        ),
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

    final success = await _adminService.deleteUserAccount(user.id!);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('اکانت کاربر با موفقیت حذف شد'),
            backgroundColor: Colors.green,
          ),
        );
        _loadUsers(reset: true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خطا در حذف اکانت کاربر'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showUserDetails(UserProfile user) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildUserDetailsSheet(user),
    );
  }

  Widget _buildUserDetailsSheet(UserProfile user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
              Text(
                'اطلاعات کاربر',
                style: TextStyle(
                  color: isDark ? AppTheme.darkTextColor : AppTheme.lightTextColor,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(LucideIcons.x),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildDetailRow('نام کاربری', user.username),
          if (user.firstName != null) _buildDetailRow('نام', user.firstName!),
          if (user.lastName != null) _buildDetailRow('نام خانوادگی', user.lastName!),
          if (user.phoneNumber != null) _buildDetailRow('شماره تلفن', user.phoneNumber!),
          _buildDetailRow('نقش', _getRoleDisplayName(user.role)),
          if (user.createdAt != null)
            _buildDetailRow('تاریخ عضویت', _formatDate(user.createdAt!)),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100.w,
            child: Text(
              '$label:',
              style: TextStyle(
                color: isDark
                    ? AppTheme.darkTextColor.withValues(alpha: 0.7)
                    : AppTheme.lightTextSecondary,
                fontSize: 14.sp,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isDark ? AppTheme.darkTextColor : AppTheme.lightTextColor,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'athlete':
        return 'ورزشکار';
      case 'trainer':
        return 'مربی';
      case 'admin':
        return 'ادمین';
      default:
        return role;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        // جستجو و فیلتر
        Container(
          padding: EdgeInsets.all(16.w),
          color: isDark ? AppTheme.darkCardColor : AppTheme.lightCardColor,
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'جستجوی کاربر...',
                  prefixIcon: const Icon(LucideIcons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(LucideIcons.x),
                          onPressed: () {
                            _searchController.clear();
                            _loadUsers(reset: true);
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                onSubmitted: (_) => _loadUsers(reset: true),
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedRoleFilter,
                      decoration: InputDecoration(
                        labelText: 'فیلتر نقش',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('همه')),
                        DropdownMenuItem(value: 'athlete', child: Text('ورزشکار')),
                        DropdownMenuItem(value: 'trainer', child: Text('مربی')),
                        DropdownMenuItem(value: 'admin', child: Text('ادمین')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedRoleFilter = value);
                          _loadUsers(reset: true);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // لیست کاربران
        Expanded(
          child: _isLoading && _users.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.goldColor,
                  ),
                )
              : _users.isEmpty
                  ? Center(
                      child: Text(
                        'کاربری یافت نشد',
                        style: TextStyle(
                          color: isDark
                              ? AppTheme.darkTextColor.withValues(alpha: 0.7)
                              : AppTheme.lightTextSecondary,
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => _loadUsers(reset: true),
                      color: AppTheme.goldColor,
                      child: ListView.builder(
                        itemCount: _users.length + (_isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _users.length) {
                            return Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.w),
                                child: const CircularProgressIndicator(
                                  color: AppTheme.goldColor,
                                ),
                              ),
                            );
                          }

                          final user = _users[index];
                          return _buildUserCard(user);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildUserCard(UserProfile user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      color: isDark ? AppTheme.darkCardColor : AppTheme.lightCardColor,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.goldColor.withValues(alpha: 0.2),
          child: Text(
            user.username.isNotEmpty ? user.username[0].toUpperCase() : 'U',
            style: const TextStyle(
              color: AppTheme.goldColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          user.username,
          style: TextStyle(
            color: isDark ? AppTheme.darkTextColor : AppTheme.lightTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.fullName.isNotEmpty ? user.fullName : 'بدون نام',
              style: TextStyle(
                color: isDark
                    ? AppTheme.darkTextColor.withValues(alpha: 0.7)
                    : AppTheme.lightTextSecondary,
              ),
            ),
            Chip(
              label: Text(_getRoleDisplayName(user.role)),
              backgroundColor: _getRoleColor(user.role).withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: _getRoleColor(user.role),
                fontSize: 12.sp,
              ),
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                  Text('مشاهده جزئیات'),
                ],
              ),
              onTap: () => _showUserDetails(user),
            ),
            PopupMenuItem<void>(
              child: const Row(
                children: [
                  Icon(LucideIcons.userCog, size: 18),
                  SizedBox(width: 8),
                  Text('تغییر نقش'),
                ],
              ),
              onTap: () => _showRoleChangeDialog(user),
            ),
            PopupMenuItem<void>(
              child: Row(
                children: [
                  const Icon(LucideIcons.trash2, size: 18, color: Colors.red),
                  SizedBox(width: 8.w),
                  const Text(
                    'حذف اکانت',
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ),
              onTap: () => _deleteUserAccount(user),
            ),
          ],
        ),
        onTap: () => _showUserDetails(user),
      ),
    );
  }

  void _showRoleChangeDialog(UserProfile user) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تغییر نقش کاربر'),
        content: RadioGroup<String>(
          groupValue: user.role,
          onChanged: (value) {
            if (value != null) {
              Navigator.pop(context);
              _updateUserRole(user, value);
            }
          },
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('ورزشکار'),
                leading: Radio<String>(value: 'athlete'),
              ),
              ListTile(
                title: Text('مربی'),
                leading: Radio<String>(value: 'trainer'),
              ),
              ListTile(
                title: Text('ادمین'),
                leading: Radio<String>(value: 'admin'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'athlete':
        return Colors.green;
      case 'trainer':
        return Colors.orange;
      case 'admin':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}

