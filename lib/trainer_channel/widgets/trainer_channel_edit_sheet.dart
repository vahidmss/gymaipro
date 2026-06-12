import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/trainer_channel/constants/trainer_channel_constants.dart';
import 'package:gymaipro/trainer_channel/models/trainer_channel_post.dart';
import 'package:gymaipro/trainer_channel/utils/trainer_channel_text_utils.dart';

/// ویرایش متن پست یا کپشن زیر رسانه
Future<String?> showTrainerChannelEditSheet({
  required BuildContext context,
  required TrainerChannelPost post,
}) {
  final initial = post.contentType == TrainerChannelContentType.text
      ? (post.textContent ?? '')
      : post.displayCaption;
  final isCaption = post.hasMedia && post.contentType != TrainerChannelContentType.text;

  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).cardColor,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
    ),
    builder: (ctx) {
      final controller = TextEditingController(text: initial);
      final focus = FocusNode()..requestFocus();
      final isDark = Theme.of(ctx).brightness == Brightness.dark;

      return Padding(
        padding: EdgeInsets.only(
          left: 16.w,
          right: 16.w,
          top: 12.h,
          bottom: MediaQuery.viewInsetsOf(ctx).bottom + 16.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              isCaption ? 'ویرایش کپشن' : 'ویرایش پیام',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isCaption) ...[
              SizedBox(height: 4.h),
              Text(
                'این متن زیر ${post.contentType == TrainerChannelContentType.image ? 'عکس' : post.contentType == TrainerChannelContentType.video ? 'ویدیو' : post.contentType == TrainerChannelContentType.audio ? 'فایل صوتی' : 'صدا'} است',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12.sp,
                  color: AppTheme.lightTextSecondary,
                ),
              ),
            ],
            SizedBox(height: 12.h),
            TextField(
              controller: controller,
              focusNode: focus,
              maxLines: 8,
              minLines: 3,
              maxLength: TrainerChannelConstants.maxTextLength,
              textDirection: TrainerChannelTextUtils.textDirectionFor(initial),
              textAlign: TrainerChannelTextUtils.textAlignFor(initial),
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 15.sp,
                color: isDark ? AppTheme.darkTextColor : AppTheme.lightTextColor,
              ),
              decoration: InputDecoration(
                hintText: isCaption ? 'کپشن…' : 'متن پیام…',
                filled: true,
                fillColor: isDark
                    ? AppTheme.veryDarkBackground
                    : const Color(0xFFF4F6F8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('انصراف'),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final text = controller.text.trim();
                      if (post.contentType == TrainerChannelContentType.text &&
                          text.isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('متن نمی‌تواند خالی باشد')),
                        );
                        return;
                      }
                      Navigator.pop(ctx, text);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.goldColor,
                      foregroundColor: AppTheme.onGoldColor,
                    ),
                    child: const Text('ذخیره'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
