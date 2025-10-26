import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/trainer_dashboard/services/user_search_service.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AthleteRequestWidget extends StatefulWidget {
  const AthleteRequestWidget({required this.onAthleteSelected, super.key});
  final Function(Map<String, dynamic>) onAthleteSelected;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _usernameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'یوزرنیم ورزشکار را وارد کنید',
                      hintStyle: const TextStyle(color: Colors.amber),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16.r)),
                      ),
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
                            color: Colors.amber,
                          ),
                        )
                      : const Icon(LucideIcons.send, color: Colors.amber),
                  onPressed: _isLoading ? null : _sendRequest,
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
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.alertCircle, color: Colors.red, size: 16.sp),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
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
                color: Colors.green[300],
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
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
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.lightbulb,
                      color: Colors.amber,
                      size: 16.sp,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'نکات مهم:',
                      style: TextStyle(
                        color: Colors.amber[200],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• یوزرنیم ورزشکاری که می‌شناسید را وارد کنید\n• درخواست برای ورزشکار ارسال می‌شود\n• ورزشکار درخواست را تایید یا رد می‌کند',
                  style: TextStyle(color: Colors.amber[300], fontSize: 12),
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(16.w),
        leading: CircleAvatar(
          backgroundColor: Colors.green[700],
          child: Text(
            _getSafeInitial(athlete['username'] as String?),
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          _getDisplayName(athlete),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '@${athlete['username']}',
              style: TextStyle(color: Colors.green[300], fontSize: 12),
            ),
            if (athlete['bio'] != null) ...[
              const SizedBox(height: 4),
              Text(
                athlete['bio'] as String,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () => widget.onAthleteSelected(athlete),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[700],
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          child: const Text('ارسال درخواست'),
        ),
      ),
    );
  }
}
