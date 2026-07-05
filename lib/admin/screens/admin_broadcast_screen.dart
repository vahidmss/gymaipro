import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/admin/services/admin_broadcast_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/widget_safety_utils.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// صفحه ارسال نوتیفیکیشن همگانی
class AdminBroadcastScreen extends StatefulWidget {
  const AdminBroadcastScreen({super.key});

  @override
  State<AdminBroadcastScreen> createState() => _AdminBroadcastScreenState();
}

class _AdminBroadcastScreenState extends State<AdminBroadcastScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AdminBroadcastService _broadcastService = AdminBroadcastService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final TextEditingController _topicController = TextEditingController(text: 'all');
  final TextEditingController _imageUrlController = TextEditingController();

  String _selectedTargetType = 'all'; // all, inactive_7d, topic
  Color _selectedBackgroundColor = AppTheme.goldColor;
  bool _isSending = false;
  List<Map<String, dynamic>> _history = [];
  bool _isLoadingHistory = false;

  // رنگ‌های پیشنهادی
  final List<Color> _presetColors = [
    AppTheme.goldColor,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    Colors.amber,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHistory();
    _titleController.addListener(() => setState(() {}));
    _bodyController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _bodyController.dispose();
    _topicController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    WidgetSafetyUtils.safeSetState(this, () => _isLoadingHistory = true);
    try {
      final history = await _broadcastService.getBroadcastHistory();
      if (mounted) {
        WidgetSafetyUtils.safeSetState(this, () {
          _history = history;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) {
        WidgetSafetyUtils.safeSetState(this, () => _isLoadingHistory = false);
        WidgetSafetyUtils.safeShowSnackBar(
          context,
          'خطا در بارگذاری تاریخچه: $e',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  Future<void> _sendNotification() async {
    if (_titleController.text.trim().isEmpty ||
        _bodyController.text.trim().isEmpty) {
      WidgetSafetyUtils.safeShowSnackBar(
        context,
        'لطفاً عنوان و متن را وارد کنید',
        backgroundColor: Colors.orange,
      );
      return;
    }

    if (_selectedTargetType == 'topic' && _topicController.text.trim().isEmpty) {
      WidgetSafetyUtils.safeShowSnackBar(
        context,
        'لطفاً نام تاپیک را وارد کنید',
        backgroundColor: Colors.orange,
      );
      return;
    }

    WidgetSafetyUtils.safeSetState(this, () => _isSending = true);

    try {
      Map<String, dynamic> result;

      final backgroundColorHex =
          '#${_selectedBackgroundColor.toARGB32().toRadixString(16).substring(2)}';

      switch (_selectedTargetType) {
        case 'all':
          result = await _broadcastService.sendToAll(
            title: _titleController.text.trim(),
            body: _bodyController.text.trim(),
            backgroundColor: backgroundColorHex,
            imageUrl: _imageUrlController.text.trim().isEmpty
                ? null
                : _imageUrlController.text.trim(),
          );
        case 'inactive_7d':
          result = await _broadcastService.sendToInactiveUsers(
            title: _titleController.text.trim(),
            body: _bodyController.text.trim(),
            backgroundColor: backgroundColorHex,
            imageUrl: _imageUrlController.text.trim().isEmpty
                ? null
                : _imageUrlController.text.trim(),
          );
        case 'topic':
          result = await _broadcastService.sendToTopic(
            topic: _topicController.text.trim(),
            title: _titleController.text.trim(),
            body: _bodyController.text.trim(),
            backgroundColor: backgroundColorHex,
            imageUrl: _imageUrlController.text.trim().isEmpty
                ? null
                : _imageUrlController.text.trim(),
          );
        default:
          result = {'success': false, 'error': 'نوع ارسال نامعتبر'};
      }

      if (mounted) {
        if (result['success'] == true) {
          WidgetSafetyUtils.safeShowSnackBar(
            context,
            (result['message'] as String?) ?? 'ارسال موفق',
            backgroundColor: Colors.green,
          );
          // پاک کردن فیلدها
          _titleController.clear();
          _bodyController.clear();
          _imageUrlController.clear();
          // بارگذاری مجدد تاریخچه
          _loadHistory();
        } else {
          WidgetSafetyUtils.safeShowSnackBar(
            context,
            (result['error'] as String?) ?? 'خطا در ارسال',
            backgroundColor: Colors.red,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        WidgetSafetyUtils.safeShowSnackBar(
          context,
          'خطا: $e',
          backgroundColor: Colors.red,
        );
      }
    } finally {
      if (mounted) {
        WidgetSafetyUtils.safeSetState(this, () => _isSending = false);
      }
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'sent':
        return 'ارسال شده';
      case 'queued':
        return 'در صف';
      case 'failed':
        return 'ناموفق';
      default:
        return 'نامشخص';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'sent':
        return Colors.green;
      case 'queued':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getTargetTypeText(String? targetType, String? topic) {
    switch (targetType) {
      case 'all':
        return 'همه کاربران';
      case 'inactive_7d':
        return 'کاربران غیرفعال 7 روزه';
      case 'topic':
        return 'تاپیک: ${topic ?? "نامشخص"}';
      default:
        return 'نامشخص';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.darkBackgroundColor
          : AppTheme.lightBackgroundColor,
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.goldColor,
            labelColor: AppTheme.goldColor,
            unselectedLabelColor: isDark
                ? AppTheme.darkTextColor.withValues(alpha: 0.6)
                : AppTheme.lightTextSecondary,
            tabs: const [
              Tab(icon: Icon(LucideIcons.send), text: 'ارسال نوتیفیکیشن'),
              Tab(icon: Icon(LucideIcons.history), text: 'تاریخچه'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSendTab(isDark),
                _buildHistoryTab(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSendTab(bool isDark) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // پیش‌نمایش نوتیفیکیشن
          _buildPreviewCard(isDark),

          SizedBox(height: 24.h),

          // فیلد عنوان
          Text(
            'عنوان نوتیفیکیشن',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? AppTheme.darkTextColor : AppTheme.lightTextColor,
            ),
          ),
          SizedBox(height: 8.h),
          TextField(
            controller: _titleController,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              color: isDark ? AppTheme.darkTextColor : AppTheme.lightTextColor,
            ),
            decoration: InputDecoration(
              hintText: 'مثال: اطلاعیه مهم',
              hintTextDirection: TextDirection.rtl,
              filled: true,
              fillColor: isDark ? AppTheme.darkCardColor : AppTheme.lightCardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: isDark
                      ? AppTheme.darkGreySeparator
                      : AppTheme.lightDividerColor,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: isDark
                      ? AppTheme.darkGreySeparator
                      : AppTheme.lightDividerColor,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(color: AppTheme.goldColor, width: 2),
              ),
            ),
          ),

          SizedBox(height: 16.h),

          // فیلد متن
          Text(
            'متن نوتیفیکیشن',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? AppTheme.darkTextColor : AppTheme.lightTextColor,
            ),
          ),
          SizedBox(height: 8.h),
          TextField(
            controller: _bodyController,
            textDirection: TextDirection.rtl,
            maxLines: 4,
            style: TextStyle(
              color: isDark ? AppTheme.darkTextColor : AppTheme.lightTextColor,
            ),
            decoration: InputDecoration(
              hintText: 'متن کامل نوتیفیکیشن را اینجا بنویسید...',
              hintTextDirection: TextDirection.rtl,
              filled: true,
              fillColor: isDark ? AppTheme.darkCardColor : AppTheme.lightCardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: isDark
                      ? AppTheme.darkGreySeparator
                      : AppTheme.lightDividerColor,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: isDark
                      ? AppTheme.darkGreySeparator
                      : AppTheme.lightDividerColor,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(color: AppTheme.goldColor, width: 2),
              ),
            ),
          ),

          SizedBox(height: 24.h),

          // انتخاب نوع ارسال
          Text(
            'نوع ارسال',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? AppTheme.darkTextColor : AppTheme.lightTextColor,
            ),
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              _buildTargetTypeChip('all', 'همه کاربران', LucideIcons.users, isDark),
              _buildTargetTypeChip(
                  'inactive_7d', 'غیرفعال 7 روزه', LucideIcons.userX, isDark),
              _buildTargetTypeChip('topic', 'تاپیک خاص', LucideIcons.hash, isDark),
            ],
          ),

          if (_selectedTargetType == 'topic') ...[
            SizedBox(height: 16.h),
            TextField(
              controller: _topicController,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                labelText: 'نام تاپیک',
                hintText: 'مثال: all, fa, premium',
                hintTextDirection: TextDirection.rtl,
                filled: true,
                fillColor: isDark ? AppTheme.darkCardColor : AppTheme.lightCardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                prefixIcon: const Icon(LucideIcons.hash),
              ),
            ),
          ],

          SizedBox(height: 24.h),

          // انتخاب رنگ پس‌زمینه
          Text(
            'رنگ پس‌زمینه',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? AppTheme.darkTextColor : AppTheme.lightTextColor,
            ),
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: _presetColors.map((color) {
              return GestureDetector(
                onTap: () => setState(() => _selectedBackgroundColor = color),
                child: Container(
                  width: 48.w,
                  height: 48.w,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _selectedBackgroundColor == color
                          ? AppTheme.goldColor
                          : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: _selectedBackgroundColor == color
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: _selectedBackgroundColor == color
                      ? Icon(Icons.check, color: Colors.white, size: 24.sp)
                      : null,
                ),
              );
            }).toList(),
          ),

          SizedBox(height: 24.h),

          // فیلد تصویر (اختیاری)
          Text(
            'آدرس تصویر (اختیاری)',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? AppTheme.darkTextColor : AppTheme.lightTextColor,
            ),
          ),
          SizedBox(height: 8.h),
          TextField(
            controller: _imageUrlController,
            textDirection: TextDirection.rtl,
            decoration: InputDecoration(
              hintText: 'https://example.com/image.jpg',
              hintTextDirection: TextDirection.rtl,
              filled: true,
              fillColor: isDark ? AppTheme.darkCardColor : AppTheme.lightCardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              prefixIcon: const Icon(LucideIcons.image),
            ),
          ),

          SizedBox(height: 32.h),

          // دکمه ارسال
          SizedBox(
            width: double.infinity,
            height: 56.h,
            child: ElevatedButton(
              onPressed: _isSending ? null : _sendNotification,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.goldColor,
                foregroundColor: AppTheme.onGoldColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 4,
              ),
              child: _isSending
                  ? SizedBox(
                      width: 24.w,
                      height: 24.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.onGoldColor,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.send, size: 20.sp),
                        SizedBox(width: 8.w),
                        Text(
                          'ارسال نوتیفیکیشن',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  Widget _buildPreviewCard(bool isDark) {
    final hasContent = _titleController.text.trim().isNotEmpty ||
        _bodyController.text.trim().isNotEmpty;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: _selectedBackgroundColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: _selectedBackgroundColor,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.notifications,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'پیش‌نمایش نوتیفیکیشن',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.darkTextColor : AppTheme.lightTextColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          if (hasContent)
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: _selectedBackgroundColor,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_titleController.text.trim().isNotEmpty)
                    Text(
                      _titleController.text.trim(),
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  if (_titleController.text.trim().isNotEmpty &&
                      _bodyController.text.trim().isNotEmpty)
                    SizedBox(height: 8.h),
                  if (_bodyController.text.trim().isNotEmpty)
                    Text(
                      _bodyController.text.trim(),
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                ],
              ),
            )
          else
            Text(
              'پیش‌نمایش پس از وارد کردن عنوان و متن نمایش داده می‌شود',
              style: TextStyle(
                fontSize: 12.sp,
                color: isDark
                    ? AppTheme.darkTextColor.withValues(alpha: 0.6)
                    : AppTheme.lightTextSecondary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTargetTypeChip(
    String value,
    String label,
    IconData icon,
    bool isDark,
  ) {
    final isSelected = _selectedTargetType == value;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16.sp),
          SizedBox(width: 4.w),
          Text(label),
        ],
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedTargetType = value);
        }
      },
      selectedColor: AppTheme.goldColor.withValues(alpha: 0.2),
      checkmarkColor: AppTheme.goldColor,
      side: BorderSide(
        color: isSelected
            ? AppTheme.goldColor
            : (isDark
                ? AppTheme.darkGreySeparator
                : AppTheme.lightDividerColor),
      ),
    );
  }

  Widget _buildHistoryTab(bool isDark) {
    if (_isLoadingHistory) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.goldColor),
      );
    }

    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.inbox,
              size: 64.sp,
              color: isDark
                  ? AppTheme.darkTextColor.withValues(alpha: 0.3)
                  : AppTheme.lightTextSecondary,
            ),
            SizedBox(height: 16.h),
            Text(
              'تاریخچه‌ای وجود ندارد',
              style: TextStyle(
                fontSize: 16.sp,
                color: isDark
                    ? AppTheme.darkTextColor.withValues(alpha: 0.6)
                    : AppTheme.lightTextSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      color: AppTheme.goldColor,
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: _history.length,
        itemBuilder: (context, index) {
          final item = _history[index];
          final status = item['status'] as String?;
          final targetType = item['target_type'] as String?;
          final topic = item['topic'] as String?;
          final title = item['title'] as String? ?? '';
          final body = item['body'] as String? ?? '';
          final createdAt = item['created_at'] as String?;

          DateTime? dateTime;
          if (createdAt != null) {
            try {
              dateTime = DateTime.parse(createdAt);
            } catch (e) {
              // ignore
            }
          }

          return Card(
            margin: EdgeInsets.only(bottom: 12.h),
            color: isDark ? AppTheme.darkCardColor : AppTheme.lightCardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppTheme.darkTextColor
                                : AppTheme.lightTextColor,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          _getStatusText(status),
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: _getStatusColor(status),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (body.isNotEmpty) ...[
                    SizedBox(height: 8.h),
                    Text(
                      body,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: isDark
                            ? AppTheme.darkTextColor.withValues(alpha: 0.8)
                            : AppTheme.lightTextSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.users,
                        size: 14.sp,
                        color: isDark
                            ? AppTheme.darkTextColor.withValues(alpha: 0.6)
                            : AppTheme.lightTextSecondary,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        _getTargetTypeText(targetType, topic),
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: isDark
                              ? AppTheme.darkTextColor.withValues(alpha: 0.6)
                              : AppTheme.lightTextSecondary,
                        ),
                      ),
                      const Spacer(),
                      if (dateTime != null)
                        Text(
                          '${dateTime.year}/${dateTime.month}/${dateTime.day} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: isDark
                                ? AppTheme.darkTextColor.withValues(alpha: 0.6)
                                : AppTheme.lightTextSecondary,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

