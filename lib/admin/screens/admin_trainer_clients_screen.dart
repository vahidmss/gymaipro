import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/admin/services/admin_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// صفحه مدیریت روابط مربی-شاگرد
class AdminTrainerClientsScreen extends StatefulWidget {
  const AdminTrainerClientsScreen({super.key});

  @override
  State<AdminTrainerClientsScreen> createState() => _AdminTrainerClientsScreenState();
}

class _AdminTrainerClientsScreenState extends State<AdminTrainerClientsScreen> {
  final AdminService _adminService = AdminService();
  List<Map<String, dynamic>> _relationships = [];
  bool _isLoading = false;
  String _selectedStatusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadRelationships();
  }

  Future<void> _loadRelationships() async {
    setState(() => _isLoading = true);
    try {
      final relationships = await _adminService.getAllTrainerClients(
        statusFilter: _selectedStatusFilter == 'all' ? null : _selectedStatusFilter,
      );
      if (mounted) {
        setState(() {
          _relationships = relationships;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در بارگذاری روابط: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateStatus(String relationshipId, String newStatus) async {
    final success = await _adminService.updateTrainerClientStatus(
      relationshipId,
      newStatus,
    );
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('وضعیت با موفقیت تغییر کرد'),
            backgroundColor: Colors.green,
          ),
        );
        _loadRelationships();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خطا در تغییر وضعیت'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'در انتظار';
      case 'active':
        return 'فعال';
      case 'rejected':
        return 'رد شده';
      case 'ended':
        return 'پایان یافته';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'active':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'ended':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16.w),
          color: isDark ? AppTheme.darkCardColor : AppTheme.lightCardColor,
          child: DropdownButtonFormField<String>(
            value: _selectedStatusFilter,
            decoration: InputDecoration(
              labelText: 'فیلتر وضعیت',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('همه')),
              DropdownMenuItem(value: 'pending', child: Text('در انتظار')),
              DropdownMenuItem(value: 'active', child: Text('فعال')),
              DropdownMenuItem(value: 'rejected', child: Text('رد شده')),
              DropdownMenuItem(value: 'ended', child: Text('پایان یافته')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedStatusFilter = value);
                _loadRelationships();
              }
            },
          ),
        ),
        Expanded(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.goldColor,
                  ),
                )
              : _relationships.isEmpty
                  ? Center(
                      child: Text(
                        'رابطه‌ای یافت نشد',
                        style: TextStyle(
                          color: isDark
                              ? AppTheme.darkTextColor.withValues(alpha: 0.7)
                              : AppTheme.lightTextSecondary,
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadRelationships,
                      color: AppTheme.goldColor,
                      child: ListView.builder(
                        itemCount: _relationships.length,
                        itemBuilder: (context, index) {
                          final relationship = _relationships[index];
                          final trainer = relationship['trainer'] as Map<String, dynamic>?;
                          final client = relationship['client'] as Map<String, dynamic>?;
                          final status = relationship['status'] as String? ?? 'pending';

                          return Card(
                            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                            color: isDark ? AppTheme.darkCardColor : AppTheme.lightCardColor,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.goldColor.withValues(alpha: 0.2),
                                child: const Icon(LucideIcons.userCheck),
                              ),
                              title: Text(
                                '${_getUserName(trainer)} ↔ ${_getUserName(client)}',
                                style: TextStyle(
                                  color: isDark ? AppTheme.darkTextColor : AppTheme.lightTextColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Chip(
                                    label: Text(_getStatusLabel(status)),
                                    backgroundColor: _getStatusColor(status).withValues(alpha: 0.2),
                                    labelStyle: TextStyle(
                                      color: _getStatusColor(status),
                                      fontSize: 12.sp,
                                    ),
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ],
                              ),
                              trailing: PopupMenuButton<void>(
                                icon: const Icon(LucideIcons.moreVertical),
                                itemBuilder: (context) => [
                                  if (status != 'active')
                                    PopupMenuItem<void>(
                                      child: const Row(
                                        children: [
                                          Icon(LucideIcons.check, size: 18),
                                          SizedBox(width: 8),
                                          Text('فعال کردن'),
                                        ],
                                      ),
                                      onTap: () => _updateStatus(
                                        relationship['id'] as String,
                                        'active',
                                      ),
                                    ),
                                  if (status != 'rejected')
                                    PopupMenuItem<void>(
                                      child: Row(
                                        children: [
                                          Icon(LucideIcons.x, size: 18, color: Colors.red),
                                          SizedBox(width: 8.w),
                                          Text(
                                            'رد کردن',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ],
                                      ),
                                      onTap: () => _updateStatus(
                                        relationship['id'] as String,
                                        'rejected',
                                      ),
                                    ),
                                  if (status == 'active')
                                    PopupMenuItem<void>(
                                      child: Row(
                                        children: [
                                          Icon(LucideIcons.stopCircle, size: 18, color: Colors.orange),
                                          SizedBox(width: 8.w),
                                          Text(
                                            'پایان دادن',
                                            style: TextStyle(color: Colors.orange),
                                          ),
                                        ],
                                      ),
                                      onTap: () => _updateStatus(
                                        relationship['id'] as String,
                                        'ended',
                                      ),
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

