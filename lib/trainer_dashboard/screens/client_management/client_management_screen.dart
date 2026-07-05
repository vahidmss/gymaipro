import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/widgets/gymai_network_image.dart';
import 'package:gymaipro/trainer_dashboard/services/trainer_client_service.dart';
import 'package:gymaipro/trainer_dashboard/services/user_search_service.dart';
import 'package:gymaipro/trainer_dashboard/widgets/athlete_request_widget.dart';
import 'package:gymaipro/trainer_dashboard/widgets/client_search_widget.dart';
import 'package:gymaipro/trainer_dashboard/widgets/relationship_stats_widget.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ClientManagementScreen extends StatefulWidget {
  const ClientManagementScreen({super.key, this.embedded = false});
  final bool embedded;

  @override
  State<ClientManagementScreen> createState() => _ClientManagementScreenState();
}

class _ClientManagementScreenState extends State<ClientManagementScreen>
    with SingleTickerProviderStateMixin {
  final TrainerClientService _clientService = TrainerClientService();
  final UserSearchService _searchService = UserSearchService();

  late TabController _tabController;
  List<Map<String, dynamic>> _clients = [];
  List<Map<String, dynamic>> _displayedClients = [];
  Map<String, int> _relationshipStats = {};
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        _currentUserId = user.id;

        // دریافت لیست شاگردان
        final clients = await _clientService.getTrainerClients(user.id);

        // دریافت آمار
        final stats = await _clientService.getRelationshipStats(user.id);

        if (mounted) {
          setState(() {
            _clients = clients;
            _displayedClients = clients;
            _relationshipStats = stats;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        final isDark = Theme.of(context).brightness == Brightness.dark;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطا در بارگذاری اطلاعات: $e',
              style: TextStyle(
                color: context.textColor,
                fontWeight: FontWeight.w600,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
            backgroundColor: isDark
                ? AppTheme.errorColor.withValues(alpha: 0.2)
                : AppTheme.errorColor.withValues(alpha: 0.15),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
              side: BorderSide(
                color: AppTheme.errorColor.withValues(alpha: 0.5),
              ),
            ),
          ),
        );
      }
    }
  }

  Future<void> _addNewClient(Map<String, dynamic> athlete) async {
    if (_currentUserId == null) return;

    try {
      // بررسی وجود هر نوع رابطه
      final existingRelationship = await _searchService.getAnyRelationship(
        trainerId: _currentUserId!,
        clientId: athlete['id'] as String,
      );

      if (existingRelationship != null) {
        final status = existingRelationship['status'] as String;
        String message;

        switch (status) {
          case 'active':
            message = 'این ورزشکار قبلاً شاگرد فعال شما است';
          case 'pending':
            message = 'درخواست شما برای این ورزشکار در انتظار تایید است';
          case 'inactive':
            message = 'این ورزشکار قبلاً شاگرد شما بوده و غیرفعال است';
          case 'blocked':
            message = 'این ورزشکار مسدود شده است';
          default:
            message = 'رابطه‌ای با این ورزشکار وجود دارد';
        }

        if (mounted) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                message,
                style: TextStyle(
                  color: context.textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: status == 'pending'
                  ? (isDark
                        ? Colors.orange.withValues(alpha: 0.2)
                        : Colors.orange.withValues(alpha: 0.15))
                  : (isDark
                        ? AppTheme.errorColor.withValues(alpha: 0.2)
                        : AppTheme.errorColor.withValues(alpha: 0.15)),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
                side: BorderSide(
                  color: status == 'pending'
                      ? Colors.orange.withValues(alpha: 0.5)
                      : AppTheme.errorColor.withValues(alpha: 0.5),
                ),
              ),
            ),
          );
        }
        return;
      }

      // ایجاد رابطه جدید
      await _clientService.createTrainerClientRelationship(
        trainerId: _currentUserId!,
        clientId: athlete['id'] as String,
      );

      if (mounted) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'درخواست برای شاگرد ارسال شد - در انتظار تایید',
              style: TextStyle(
                color: context.textColor,
                fontWeight: FontWeight.w600,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
            backgroundColor: isDark
                ? AppTheme.successColor.withValues(alpha: 0.2)
                : AppTheme.successColor.withValues(alpha: 0.15),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
              side: BorderSide(
                color: AppTheme.successColor.withValues(alpha: 0.5),
              ),
            ),
          ),
        );
        _loadData(); // بارگذاری مجدد اطلاعات
      }
    } catch (e) {
      if (mounted) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطا در اضافه کردن شاگرد: $e',
              style: TextStyle(
                color: context.textColor,
                fontWeight: FontWeight.w600,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
            backgroundColor: isDark
                ? AppTheme.errorColor.withValues(alpha: 0.2)
                : AppTheme.errorColor.withValues(alpha: 0.15),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
              side: BorderSide(
                color: AppTheme.errorColor.withValues(alpha: 0.5),
              ),
            ),
          ),
        );
      }
    }
  }

  void _onSearchResultsChanged(List<Map<String, dynamic>> filteredClients) {
    setState(() {
      _displayedClients = filteredClients;
    });
  }

  Future<void> _removeClient(String clientId) async {
    if (_currentUserId == null) return;

    try {
      await _clientService.endRelationship(
        trainerId: _currentUserId!,
        clientId: clientId,
      );

      if (mounted) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'شاگرد با موفقیت حذف شد',
              style: TextStyle(
                color: context.textColor,
                fontWeight: FontWeight.w600,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
            backgroundColor: isDark
                ? AppTheme.successColor.withValues(alpha: 0.2)
                : AppTheme.successColor.withValues(alpha: 0.15),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
              side: BorderSide(
                color: AppTheme.successColor.withValues(alpha: 0.5),
              ),
            ),
          ),
        );
        _loadData(); // بارگذاری مجدد اطلاعات
      }
    } catch (e) {
      if (mounted) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطا در حذف شاگرد: $e',
              style: TextStyle(
                color: context.textColor,
                fontWeight: FontWeight.w600,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
            backgroundColor: isDark
                ? AppTheme.errorColor.withValues(alpha: 0.2)
                : AppTheme.errorColor.withValues(alpha: 0.15),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
              side: BorderSide(
                color: AppTheme.errorColor.withValues(alpha: 0.5),
              ),
            ),
          ),
        );
      }
    }
  }

  Future<void> _blockClient(String clientId) async {
    if (_currentUserId == null) return;

    try {
      await _clientService.updateRelationshipStatus(
        trainerId: _currentUserId!,
        clientId: clientId,
        status: 'blocked',
      );

      if (mounted) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'شاگرد مسدود شد',
              style: TextStyle(
                color: context.textColor,
                fontWeight: FontWeight.w600,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
            backgroundColor: isDark
                ? AppTheme.errorColor.withValues(alpha: 0.2)
                : AppTheme.errorColor.withValues(alpha: 0.15),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
              side: BorderSide(
                color: AppTheme.errorColor.withValues(alpha: 0.5),
              ),
            ),
          ),
        );
        _loadData(); // بارگذاری مجدد اطلاعات
      }
    } catch (e) {
      if (mounted) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطا در مسدود کردن شاگرد: $e',
              style: TextStyle(
                color: context.textColor,
                fontWeight: FontWeight.w600,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
            backgroundColor: isDark
                ? AppTheme.errorColor.withValues(alpha: 0.2)
                : AppTheme.errorColor.withValues(alpha: 0.15),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
              side: BorderSide(
                color: AppTheme.errorColor.withValues(alpha: 0.5),
              ),
            ),
          ),
        );
      }
    }
  }

  Future<void> _unblockClient(String clientId) async {
    if (_currentUserId == null) return;

    try {
      await _clientService.updateRelationshipStatus(
        trainerId: _currentUserId!,
        clientId: clientId,
        status: 'active',
      );

      if (mounted) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'مسدودیت شاگرد رفع شد',
              style: TextStyle(
                color: context.textColor,
                fontWeight: FontWeight.w600,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
            backgroundColor: isDark
                ? AppTheme.successColor.withValues(alpha: 0.2)
                : AppTheme.successColor.withValues(alpha: 0.15),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
              side: BorderSide(
                color: AppTheme.successColor.withValues(alpha: 0.5),
              ),
            ),
          ),
        );
        _loadData(); // بارگذاری مجدد اطلاعات
      }
    } catch (e) {
      if (mounted) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطا در رفع مسدودیت شاگرد: $e',
              style: TextStyle(
                color: context.textColor,
                fontWeight: FontWeight.w600,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
            backgroundColor: isDark
                ? AppTheme.errorColor.withValues(alpha: 0.2)
                : AppTheme.errorColor.withValues(alpha: 0.15),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
              side: BorderSide(
                color: AppTheme.errorColor.withValues(alpha: 0.5),
              ),
            ),
          ),
        );
      }
    }
  }

  void _onClientTap(Map<String, dynamic> clientProfile) {
    final String? userId = clientProfile['id'] as String?;
    if (userId == null || userId.isEmpty) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'شناسه کاربر نامعتبر است',
            style: TextStyle(
              color: context.textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: isDark
              ? AppTheme.errorColor.withValues(alpha: 0.2)
              : AppTheme.errorColor.withValues(alpha: 0.15),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
            side: BorderSide(
              color: AppTheme.errorColor.withValues(alpha: 0.5),
            ),
          ),
        ),
      );
      return;
    }
    Navigator.pushNamed(context, '/trainer-profile', arguments: userId);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppTheme.goldColor,
          strokeWidth: 3,
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClientSearchWidget(
            allClients: _clients,
            onSearchResultsChanged: _onSearchResultsChanged,
          ),
          SizedBox(height: 16.h),
          RelationshipStatsWidget(stats: _relationshipStats),
          SizedBox(height: 20.h),
          _buildClientsTab(),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color baseColor;
    String statusText;

    switch (status) {
      case 'active':
        baseColor = AppTheme.successColor;
        statusText = 'فعال';
      case 'pending':
        baseColor = Colors.amber;
        statusText = 'در انتظار';
      case 'inactive':
        baseColor = Colors.grey;
        statusText = 'غیرفعال';
      case 'blocked':
        baseColor = AppTheme.errorColor;
        statusText = 'مسدود';
      default:
        baseColor = Colors.grey;
        statusText = 'نامشخص';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: baseColor,
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
          fontFamily: AppTheme.fontFamily,
        ),
      ),
    );
  }

  String _getDisplayName(Map<String, dynamic> profile) {
    final firstName = profile['first_name'] as String?;
    final lastName = profile['last_name'] as String?;

    if (firstName != null && firstName.isNotEmpty) {
      if (lastName != null && lastName.isNotEmpty) {
        return '$firstName $lastName';
      }
      return firstName;
    }

    return profile['username'] as String;
  }

  Widget _buildClientsTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_displayedClients.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 40.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: AppTheme.goldColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.users,
                size: 48.sp,
                color: AppTheme.goldColor.withValues(alpha: 0.5),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'هنوز شاگردی ندارید',
              style: TextStyle(
                color: context.textColor,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'برای شروع، اولین شاگرد خود را اضافه کنید',
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 12.sp,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
            SizedBox(height: 20.h),
            OutlinedButton.icon(
              onPressed: _openAddClientSheet,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: AppTheme.goldColor.withValues(alpha: 0.5),
                  width: 1.5,
                ),
                foregroundColor: AppTheme.goldColor,
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              icon: Icon(LucideIcons.userPlus, size: 16.sp),
              label: Text(
                'افزودن شاگرد جدید',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...List.generate(
          _displayedClients.length,
          (index) {
            final client = _displayedClients[index];
            final clientProfile = client['client'] as Map<String, dynamic>?;

            if (clientProfile == null) return const SizedBox.shrink();

            final status = client['status'] as String? ?? 'pending';
            final isActive = status == 'active';

            return Container(
              margin: EdgeInsets.only(bottom: 10.h),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isActive
                      ? AppTheme.successColor.withValues(alpha: isDark ? 0.25 : 0.15)
                      : AppTheme.goldColor.withValues(alpha: isDark ? 0.15 : 0.1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.2)
                        : AppTheme.goldColor.withValues(alpha: 0.05),
                    blurRadius: 8.r,
                    offset: Offset(0, 2.h),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isActive ? () => _onClientTap(clientProfile) : null,
                  borderRadius: BorderRadius.circular(16.r),
                  child: Padding(
                    padding: EdgeInsets.all(14.w),
                    child: Row(
                      children: [
                        _ClientAvatar(profile: clientProfile),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _getDisplayName(clientProfile),
                                      style: TextStyle(
                                        color: context.textColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15.sp,
                                        fontFamily: AppTheme.fontFamily,
                                      ),
                                    ),
                                  ),
                                  _buildStatusChip(status),
                                ],
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                '@${clientProfile['username']}',
                                style: TextStyle(
                                  color: context.textSecondary,
                                  fontSize: 12.sp,
                                  fontFamily: AppTheme.fontFamily,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8.w),
                        PopupMenuButton<String>(
                          icon: Icon(
                            LucideIcons.moreVertical,
                            color: context.textSecondary,
                            size: 18.sp,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          onSelected: (value) {
                            switch (value) {
                              case 'remove':
                                _removeClient(clientProfile['id'] as String);
                              case 'block':
                                _blockClient(clientProfile['id'] as String);
                              case 'unblock':
                                _unblockClient(clientProfile['id'] as String);
                            }
                          },
                          itemBuilder: (context) {
                            final status = client['status'] as String? ?? 'pending';
                            final items = <PopupMenuItem<String>>[];

                            if (status == 'blocked') {
                              items.add(
                                PopupMenuItem(
                                  value: 'unblock',
                                  child: Row(
                                    children: [
                                      Icon(
                                        LucideIcons.userCheck,
                                        color: AppTheme.successColor,
                                        size: 16.sp,
                                      ),
                                      SizedBox(width: 10.w),
                                      Text(
                                        'رفع مسدودیت',
                                        style: TextStyle(
                                          color: context.textColor,
                                          fontSize: 13.sp,
                                          fontFamily: AppTheme.fontFamily,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            } else {
                              items.add(
                                PopupMenuItem(
                                  value: 'block',
                                  child: Row(
                                    children: [
                                      Icon(
                                        LucideIcons.userMinus,
                                        color: AppTheme.errorColor,
                                        size: 16.sp,
                                      ),
                                      SizedBox(width: 10.w),
                                      Text(
                                        'مسدود کردن',
                                        style: TextStyle(
                                          color: context.textColor,
                                          fontSize: 13.sp,
                                          fontFamily: AppTheme.fontFamily,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            items.add(
                              PopupMenuItem(
                                value: 'remove',
                                child: Row(
                                  children: [
                                    Icon(
                                      LucideIcons.trash2,
                                      color: AppTheme.errorColor,
                                      size: 16.sp,
                                    ),
                                    SizedBox(width: 10.w),
                                    Text(
                                      'حذف شاگرد',
                                      style: TextStyle(
                                        color: context.textColor,
                                        fontSize: 13.sp,
                                        fontFamily: AppTheme.fontFamily,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );

                            return items;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        SizedBox(height: 12.h),
        OutlinedButton.icon(
          onPressed: _openAddClientSheet,
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: AppTheme.goldColor.withValues(alpha: 0.4),
              width: 1.5,
            ),
            foregroundColor: AppTheme.goldColor,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          icon: Icon(LucideIcons.userPlus, size: 16.sp),
          label: Text(
            'افزودن شاگرد جدید',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
        ),
        SizedBox(height: 16.h),
      ],
    );
  }

  void _openAddClientSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            border: Border(
              top: BorderSide(
                color: AppTheme.goldColor.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.85,
                child: Column(
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 12.h, bottom: 8.h),
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: context.textSecondary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.userPlus,
                            color: AppTheme.goldColor,
                            size: 22.sp,
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            'افزودن شاگرد جدید',
                            style: TextStyle(
                              color: context.textColor,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                              fontFamily: AppTheme.fontFamily,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: Icon(
                              LucideIcons.x,
                              color: context.textSecondary,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      color: context.separatorColor,
                      height: 1,
                      thickness: 1,
                    ),
                    Expanded(
                      child: AthleteRequestWidget(
                        onAthleteSelected: (athlete) {
                          Navigator.pop(context);
                          _addNewClient(athlete);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ClientAvatar extends StatelessWidget {
  const _ClientAvatar({required this.profile});
  final Map<String, dynamic> profile;

  @override
  Widget build(BuildContext context) {
    final String? avatarUrl =
        (profile['avatar_url'] ??
                profile['avatarUrl'] ??
                profile['profile_image_url'])
            as String?;
    final String initials = _initialsFromProfile(profile);

    return Container(
      width: 48.w,
      height: 48.h,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: ClipOval(
        child: (avatarUrl != null && avatarUrl.isNotEmpty)
            ? GymaiNetworkImage(
                imageUrl: avatarUrl,
                errorWidget: _Initials(initials: initials),
                placeholder: ColoredBox(
                  color: context.cardColor,
                  child: Center(
                    child: SizedBox(
                      width: 18.w,
                      height: 18.h,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.goldColor,
                      ),
                          ),
                        ),
                      ),
              )
            : _Initials(initials: initials),
      ),
    );
  }

  String _initialsFromProfile(Map<String, dynamic> p) {
    final first = (p['first_name'] as String?)?.trim() ?? '';
    final last = (p['last_name'] as String?)?.trim() ?? '';
    final combined = '$first $last'.trim();
    if (combined.isNotEmpty) return combined.characters.first;
    final username = (p['username'] as String?)?.trim();
    if (username != null && username.isNotEmpty) {
      return username.characters.first;
    }
    return '?';
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.goldColor.withValues(alpha: 0.15),
      ),
      child: Center(
        child: Text(
          initials.toUpperCase(),
          style: TextStyle(
            color: AppTheme.goldColor,
            fontWeight: FontWeight.w600,
            fontSize: 18.sp,
            fontFamily: AppTheme.fontFamily,
          ),
        ),
      ),
    );
  }
}
