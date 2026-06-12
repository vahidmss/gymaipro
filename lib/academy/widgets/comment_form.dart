import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CommentForm extends StatefulWidget {
  const CommentForm({required this.onSubmit, super.key});

  final Future<void> Function(String comment) onSubmit;

  @override
  State<CommentForm> createState() => _CommentFormState();
}

class _CommentFormState extends State<CommentForm> {
  final TextEditingController _commentCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _isSubmitting = true);
    _commentCtrl.clear();
    try {
      await widget.onSubmit(text);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppTheme.goldColor.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.goldColor.withValues(alpha: 0.08),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.messageSquarePlus,
                size: 18.sp,
                color: AppTheme.goldColor,
              ),
              SizedBox(width: 8.w),
              Text(
                'ثبت نظر جدید',
                style: AppTheme.headingStyle.copyWith(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          SizedBox(height: 12.h),
          TextField(
            controller: _commentCtrl,
            minLines: 3,
            maxLines: 6,
            textDirection: TextDirection.rtl,
            enabled: !_isSubmitting,
            decoration: InputDecoration(
              hintText: 'نظر خود را اینجا بنویسید...',
              hintStyle: AppTheme.bodyStyle.copyWith(
                color: context.textSecondary,
                fontSize: 13.sp,
              ),
              filled: true,
              fillColor: context.backgroundColor,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 14.w,
                vertical: 12.h,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: BorderSide(
                  color: AppTheme.goldColor.withValues(alpha: 0.2),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: BorderSide(
                  color: AppTheme.goldColor.withValues(alpha: 0.2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: BorderSide(color: AppTheme.goldColor, width: 1.5),
              ),
            ),
            style: AppTheme.bodyStyle.copyWith(fontSize: 13.sp, height: 1.5),
          ),
          SizedBox(height: 12.h),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: _isSubmitting ? null : _handleSubmit,
              style: AppTheme.primaryButtonStyle.copyWith(
                padding: WidgetStateProperty.all(
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                ),
              ),
              icon: _isSubmitting
                  ? SizedBox(
                      width: 16.w,
                      height: 16.h,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : Icon(LucideIcons.send, size: 18.sp),
              label: Text(
                _isSubmitting ? 'در حال ارسال...' : 'ارسال نظر',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
