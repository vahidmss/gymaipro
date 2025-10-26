import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/trainer_ranking/services/trainer_ranking_service.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReviewSubmissionWidget extends StatefulWidget {
  const ReviewSubmissionWidget({
    required this.trainerId,
    required this.onReviewSubmitted,
    super.key,
  });

  final String trainerId;
  final VoidCallback onReviewSubmitted;

  @override
  State<ReviewSubmissionWidget> createState() => _ReviewSubmissionWidgetState();
}

class _ReviewSubmissionWidgetState extends State<ReviewSubmissionWidget> {
  final TrainerRankingService _service = TrainerRankingService();
  final TextEditingController _commentController = TextEditingController();

  double _rating = 5;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_commentController.text.trim().isEmpty) {
      _showErrorDialog('لطفاً نظر خود را بنویسید');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        _showErrorDialog('لطفاً ابتدا وارد حساب کاربری خود شوید');
        return;
      }

      final success = await _service.addTrainerReview(
        trainerId: widget.trainerId,
        clientId: currentUser.id,
        rating: _rating,
        comment: _commentController.text.trim(),
      );

      if (success) {
        if (mounted) {
          Navigator.of(context).pop();
          widget.onReviewSubmitted();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'نظر شما با موفقیت ثبت شد',
                style: GoogleFonts.vazirmatn(),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        _showErrorDialog('خطا در ثبت نظر. لطفاً دوباره تلاش کنید');
      }
    } catch (e) {
      _showErrorDialog('خطا در ثبت نظر: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('خطا', style: GoogleFonts.vazirmatn()),
        content: Text(message, style: GoogleFonts.vazirmatn()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('باشه', style: GoogleFonts.vazirmatn()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // عنوان
            Text(
              'نظر خود را ثبت کنید',
              style: GoogleFonts.vazirmatn(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20.h),

            // امتیازدهی
            Text(
              'امتیاز شما:',
              style: GoogleFonts.vazirmatn(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 10.h),

            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _rating,
                    min: 1,
                    max: 5,
                    divisions: 4,
                    activeColor: AppTheme.goldColor,
                    inactiveColor: Colors.grey[600],
                    onChanged: (value) {
                      setState(() {
                        _rating = value;
                      });
                    },
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.goldColor,
                        AppTheme.goldColor.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.star,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        _rating.toStringAsFixed(1),
                        style: GoogleFonts.vazirmatn(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),

            // متن نظر
            Text(
              'نظر شما:',
              style: GoogleFonts.vazirmatn(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 10.h),

            TextField(
              controller: _commentController,
              maxLines: 4,
              style: GoogleFonts.vazirmatn(
                color: Colors.white,
                fontSize: 14.sp,
              ),
              decoration: InputDecoration(
                hintText: 'نظر خود را در مورد این مربی بنویسید...',
                hintStyle: GoogleFonts.vazirmatn(
                  color: Colors.grey[400],
                  fontSize: 14.sp,
                ),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(
                    color: AppTheme.goldColor.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(
                    color: AppTheme.goldColor.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: AppTheme.goldColor, width: 2.w),
                ),
              ),
            ),
            SizedBox(height: 20.h),

            // دکمه‌ها
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text(
                      'انصراف',
                      style: GoogleFonts.vazirmatn(
                        color: Colors.grey[400],
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.goldColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      elevation: 4,
                    ),
                    child: _isSubmitting
                        ? SizedBox(
                            width: 20.w,
                            height: 20.h,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'ثبت نظر',
                            style: GoogleFonts.vazirmatn(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
