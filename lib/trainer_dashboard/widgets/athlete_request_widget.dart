import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/trainer_dashboard/services/user_search_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AthleteRequestWidget extends StatefulWidget {
  const AthleteRequestWidget({required this.onAthleteSelected, super.key});
  final void Function(Map<String, dynamic>) onAthleteSelected;

  @override
  State<AthleteRequestWidget> createState() => _AthleteRequestWidgetState();
}

class _AthleteRequestWidgetState extends State<AthleteRequestWidget> {
  final UserSearchService _searchService = UserSearchService();
  final TextEditingController _usernameController = TextEditingController();

  bool _isLoading = false;
  Map<String, dynamic>? _foundAthlete;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _sendRequest() async {
    if (_usernameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'لطفاً یوزرنیم را وارد کنید';
        _foundAthlete = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _foundAthlete = null;
    });

    try {
      final athlete = await _searchService.getUserProfile(
        _usernameController.text.trim(),
      );

      if (athlete != null && athlete['role'] == 'athlete') {
        setState(() {
          _foundAthlete = athlete;
        });
      } else {
        setState(() {
          _errorMessage = 'یوزرنیم یافت نشد یا ورزشکار نیست';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'خطا در بررسی یوزرنیم: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8.h),
          DecoratedBox(
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: context.separatorColor),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _usernameController,
                    style: TextStyle(
                      color: context.textColor,
                      fontFamily: AppTheme.fontFamily,
                    ),
                    decoration: InputDecoration(
                      hintText: 'یوزرنیم ورزشکار را وارد کنید',
                      hintStyle: TextStyle(
                        color: context.textSecondary,
                        fontFamily: AppTheme.fontFamily,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                    ),
                    onSubmitted: (_) => _sendRequest(),
                  ),
                ),
                IconButton(
                  icon: _isLoading
                      ? SizedBox(
                          width: 20.w,
                          height: 20.h,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.goldColor,
                          ),
                        )
                      : const Icon(LucideIcons.send, color: AppTheme.goldColor),
                  onPressed: _isLoading ? null : _sendRequest,
                  tooltip: 'جستجوی ورزشکار',
                ),
              ],
            ),
          ),

          // پیام خطا
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppTheme.errorColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.alertCircle,
                    color: AppTheme.errorColor,
                    size: 18.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: AppTheme.errorColor,
                        fontSize: 13.sp,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),

          // نتیجه جستجو
          if (_foundAthlete != null) ...[
            Text(
              'ورزشکار یافت شد - درخواست ارسال کنید:',
              style: TextStyle(
                color: AppTheme.successColor,
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
            const SizedBox(height: 12),
            _buildAthleteCard(_foundAthlete!),
          ],
          const SizedBox(height: 20),

          // راهنمای پایین
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppTheme.goldColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: AppTheme.goldColor.withValues(alpha: 0.22),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.lightbulb,
                      color: AppTheme.goldColor,
                      size: 18.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'نکات مهم:',
                      style: TextStyle(
                        color: context.textColor,
                        fontWeight: FontWeight.bold,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• یوزرنیم ورزشکاری که می‌شناسید را وارد کنید\n• درخواست برای ورزشکار ارسال می‌شود\n• ورزشکار درخواست را تایید یا رد می‌کند',
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 12.sp,
                    height: 1.7,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getDisplayName(Map<String, dynamic> athlete) {
    final firstName = athlete['first_name'] as String?;
    final lastName = athlete['last_name'] as String?;

    if (firstName != null && firstName.isNotEmpty) {
      if (lastName != null && lastName.isNotEmpty) {
        return '$firstName $lastName';
      }
      return firstName;
    }

    return athlete['username'] as String;
  }

  String _getSafeInitial(String? username) {
    if (username == null || username.isEmpty) {
      return 'U';
    }
    return username.substring(0, 1).toUpperCase();
  }

  Widget _buildAthleteCard(Map<String, dynamic> athlete) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppTheme.successColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22.r,
                backgroundColor: AppTheme.successColor.withValues(alpha: 0.16),
                child: Text(
                  _getSafeInitial(athlete['username'] as String?),
                  style: const TextStyle(
                    color: AppTheme.successColor,
                    fontWeight: FontWeight.bold,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getDisplayName(athlete),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.textColor,
                        fontWeight: FontWeight.bold,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      '@${athlete['username']}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTheme.successColor,
                        fontSize: 12.sp,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (athlete['bio'] != null) ...[
            SizedBox(height: 10.h),
            Text(
              athlete['bio'] as String,
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 12.sp,
                fontFamily: AppTheme.fontFamily,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          SizedBox(height: 14.h),
          SizedBox(
            height: 48.h,
            child: FilledButton.icon(
              onPressed: () => widget.onAthleteSelected(athlete),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.successColor,
                foregroundColor: AppTheme.onGoldColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
              icon: Icon(LucideIcons.send, size: 18.sp),
              label: const Text(
                'ارسال درخواست',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
