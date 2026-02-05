import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/admin/services/admin_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/chat/widgets/user_avatar_widget.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// صفحه مدیریت و تایید مدارک مربیان
class AdminCertificatesScreen extends StatefulWidget {
  const AdminCertificatesScreen({super.key});

  @override
  State<AdminCertificatesScreen> createState() => _AdminCertificatesScreenState();
}

class _AdminCertificatesScreenState extends State<AdminCertificatesScreen> {
  final AdminService _adminService = AdminService();
  List<Map<String, dynamic>> _certificates = [];
  bool _isLoading = false;
  String? _selectedStatus; // Filter for status
  String? _selectedType; // Filter for type
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadCertificates();
    _loadStats();
  }

  Future<void> _loadCertificates() async {
    setState(() => _isLoading = true);
    try {
      final certificates = await _adminService.getAllCertificates(
        statusFilter: _selectedStatus,
        typeFilter: _selectedType,
      );
      if (mounted) {
        setState(() {
          _certificates = certificates;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در بارگذاری مدارک: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _adminService.getCertificateStats();
      if (mounted) {
        setState(() => _stats = stats);
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
    }
  }

  String _getCertificateTypeTitle(String? type) {
    switch (type) {
      case 'coaching':
        return 'مربیگری';
      case 'championship':
        return 'قهرمانی';
      case 'education':
        return 'تحصیلات';
      case 'specialization':
        return 'تخصص';
      case 'achievement':
        return 'دستاورد';
      case 'other':
        return 'سایر';
      default:
        return 'نامشخص';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return AppTheme.goldColor;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'approved':
        return 'تایید شده';
      case 'rejected':
        return 'رد شده';
      case 'pending':
        return 'در انتظار تایید';
      default:
        return 'نامشخص';
    }
  }

  String _getUserDisplayName(Map<String, dynamic>? user) {
    if (user == null) return 'ناشناس';
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
    return 'ناشناس';
  }

  Future<void> _approveCertificate(String certificateId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تایید مدرک'),
        content: const Text('آیا از تایید این مدرک اطمینان دارید؟'),
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

    try {
      final success = await _adminService.approveCertificate(certificateId);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('مدرک با موفقیت تایید شد'),
              backgroundColor: Colors.green,
            ),
          );
          _loadCertificates();
          _loadStats();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('خطا در تایید مدرک'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در تایید مدرک: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectCertificate(String certificateId) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('رد مدرک'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('لطفاً دلیل رد مدرک را وارد کنید:'),
            SizedBox(height: 16.h),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'دلیل رد',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('لغو'),
          ),
          TextButton(
            onPressed: () {
              if (reasonController.text.isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('رد'),
          ),
        ],
      ),
    );

    if (confirmed != true || reasonController.text.isEmpty) return;

    try {
      final success = await _adminService.rejectCertificate(
        certificateId,
        reasonController.text,
      );
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('مدرک رد شد'),
              backgroundColor: Colors.orange,
            ),
          );
          _loadCertificates();
          _loadStats();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('خطا در رد مدرک'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در رد مدرک: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCertificateImage(String imageUrl) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => const CircularProgressIndicator(),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        // آمار کلی
        Container(
          padding: EdgeInsets.all(16.w),
          color: isDark ? AppTheme.darkCardColor : AppTheme.lightCardColor,
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  'کل مدارک',
                  '${_stats['total'] ?? 0}',
                  LucideIcons.fileText,
                  Colors.blue,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildStatCard(
                  context,
                  'در انتظار',
                  '${_stats['pending'] ?? 0}',
                  LucideIcons.clock,
                  AppTheme.goldColor,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildStatCard(
                  context,
                  'تایید شده',
                  '${_stats['approved'] ?? 0}',
                  LucideIcons.checkCircle,
                  Colors.green,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildStatCard(
                  context,
                  'رد شده',
                  '${_stats['rejected'] ?? 0}',
                  LucideIcons.xCircle,
                  Colors.red,
                ),
              ),
            ],
          ),
        ),
        // فیلترها
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          color: isDark ? AppTheme.darkCardColor : AppTheme.lightCardColor,
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: InputDecoration(
                    labelText: 'وضعیت',
                    border: const OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('همه')),
                    DropdownMenuItem(value: 'pending', child: Text('در انتظار')),
                    DropdownMenuItem(value: 'approved', child: Text('تایید شده')),
                    DropdownMenuItem(value: 'rejected', child: Text('رد شده')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value;
                    });
                    _loadCertificates();
                  },
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: InputDecoration(
                    labelText: 'نوع مدرک',
                    border: const OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('همه')),
                    DropdownMenuItem(value: 'coaching', child: Text('مربیگری')),
                    DropdownMenuItem(value: 'championship', child: Text('قهرمانی')),
                    DropdownMenuItem(value: 'education', child: Text('تحصیلات')),
                    DropdownMenuItem(value: 'specialization', child: Text('تخصص')),
                    DropdownMenuItem(value: 'achievement', child: Text('دستاورد')),
                    DropdownMenuItem(value: 'other', child: Text('سایر')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value;
                    });
                    _loadCertificates();
                  },
                ),
              ),
            ],
          ),
        ),
        // لیست مدارک
        Expanded(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.goldColor,
                  ),
                )
              : _certificates.isEmpty
                  ? Center(
                      child: Text(
                        'هیچ مدرکی یافت نشد',
                        style: TextStyle(
                          color: isDark
                              ? AppTheme.darkTextColor.withValues(alpha: 0.7)
                              : AppTheme.lightTextSecondary,
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadCertificates,
                      color: AppTheme.goldColor,
                      child: ListView.builder(
                        itemCount: _certificates.length,
                        itemBuilder: (context, index) {
                          final cert = _certificates[index];
                          final trainer = cert['trainer'] as Map<String, dynamic>?;
                          final status = cert['status'] as String? ?? 'pending';
                          final type = cert['type'] as String?;
                          final title = cert['title'] as String? ?? 'بدون عنوان';
                          final certificateUrl = cert['certificate_url'] as String?;
                          final createdAt = DateTime.tryParse(
                            cert['created_at']?.toString() ?? '',
                          );
                          final rejectionReason = cert['rejection_reason'] as String?;

                          return Card(
                            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                            color: isDark ? AppTheme.darkCardColor : AppTheme.lightCardColor,
                            child: Padding(
                              padding: EdgeInsets.all(16.w),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // هدر با وضعیت
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12.w,
                                          vertical: 6.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(status).withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(8.r),
                                          border: Border.all(
                                            color: _getStatusColor(status),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          _getStatusText(status),
                                          style: TextStyle(
                                            color: _getStatusColor(status),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12.sp,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8.w),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12.w,
                                          vertical: 6.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.goldColor.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(8.r),
                                        ),
                                        child: Text(
                                          _getCertificateTypeTitle(type),
                                          style: TextStyle(
                                            color: AppTheme.goldColor,
                                            fontSize: 12.sp,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      if (createdAt != null)
                                        Text(
                                          DateFormat('yyyy/MM/dd HH:mm').format(createdAt),
                                          style: TextStyle(
                                            color: isDark
                                                ? AppTheme.darkTextColor.withValues(alpha: 0.6)
                                                : AppTheme.lightTextSecondary,
                                            fontSize: 12.sp,
                                          ),
                                        ),
                                    ],
                                  ),
                                  SizedBox(height: 12.h),
                                  // اطلاعات مربی
                                  Row(
                                    children: [
                                      if (trainer?['avatar_url'] != null)
                                        Padding(
                                          padding: EdgeInsetsDirectional.only(end: 8.w),
                                          child: UserAvatarWidget(
                                            avatarUrl: trainer!['avatar_url'] as String,
                                            size: 40.sp,
                                            showOnlineStatus: false,
                                          ),
                                        ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _getUserDisplayName(trainer),
                                              style: TextStyle(
                                                color: isDark
                                                    ? AppTheme.darkTextColor
                                                    : AppTheme.lightTextColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16.sp,
                                              ),
                                            ),
                                            if (trainer?['username'] != null)
                                              Text(
                                                '@${trainer!['username']}',
                                                style: TextStyle(
                                                  color: isDark
                                                      ? AppTheme.darkTextColor.withValues(alpha: 0.6)
                                                      : AppTheme.lightTextSecondary,
                                                  fontSize: 12.sp,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12.h),
                                  // عنوان مدرک
                                  Text(
                                    title,
                                    style: TextStyle(
                                      color: isDark
                                          ? AppTheme.darkTextColor
                                          : AppTheme.lightTextColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16.sp,
                                    ),
                                  ),
                                  // تصویر مدرک
                                  if (certificateUrl != null) ...[
                                    SizedBox(height: 12.h),
                                    GestureDetector(
                                      onTap: () => _showCertificateImage(certificateUrl),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8.r),
                                        child: CachedNetworkImage(
                                          imageUrl: certificateUrl,
                                          width: double.infinity,
                                          height: 200.h,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Container(
                                            height: 200.h,
                                            color: isDark
                                                ? AppTheme.darkGreySeparator
                                                : AppTheme.lightDividerColor,
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                color: AppTheme.goldColor,
                                              ),
                                            ),
                                          ),
                                          errorWidget: (context, url, error) => Container(
                                            height: 200.h,
                                            color: isDark
                                                ? AppTheme.darkGreySeparator
                                                : AppTheme.lightDividerColor,
                                            child: const Icon(Icons.error),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                  // دلیل رد
                                  if (status == 'rejected' && rejectionReason != null) ...[
                                    SizedBox(height: 12.h),
                                    Container(
                                      padding: EdgeInsets.all(12.w),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8.r),
                                        border: Border.all(
                                          color: Colors.red.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            LucideIcons.alertCircle,
                                            color: Colors.red,
                                            size: 20.sp,
                                          ),
                                          SizedBox(width: 8.w),
                                          Expanded(
                                            child: Text(
                                              'دلیل رد: $rejectionReason',
                                              style: TextStyle(
                                                color: Colors.red,
                                                fontSize: 13.sp,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  // دکمه‌های عملیات
                                  if (status == 'pending') ...[
                                    SizedBox(height: 12.h),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () => _approveCertificate(
                                              cert['id'] as String,
                                            ),
                                            icon: const Icon(LucideIcons.check),
                                            label: const Text('تایید'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 8.w),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () => _rejectCertificate(
                                              cert['id'] as String,
                                            ),
                                            icon: const Icon(LucideIcons.x),
                                            label: const Text('رد'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
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

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBackgroundColor : AppTheme.lightBackgroundColor,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24.sp),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            title,
            style: TextStyle(
              color: isDark
                  ? AppTheme.darkTextColor.withValues(alpha: 0.7)
                  : AppTheme.lightTextSecondary,
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }
}

