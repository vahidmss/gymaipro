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
  void initState() {
    super.initState();
    _commentCtrl.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _commentCtrl
      ..removeListener(_onTextChanged)
      ..dispose();
    super.dispose();
  }

  void _onTextChanged() => setState(() {});

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canSend = _commentCtrl.text.trim().isNotEmpty && !_isSubmitting;
    final fieldFill = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.04);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: fieldFill,
                borderRadius: BorderRadius.circular(24.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: TextField(
                controller: _commentCtrl,
                enabled: !_isSubmitting,
                minLines: 1,
                maxLines: 4,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                textInputAction: TextInputAction.newline,
                keyboardType: TextInputType.multiline,
                cursorColor: AppTheme.goldColor,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: context.textColor,
                  fontSize: 14.sp,
                  height: 1.5,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'نظرت رو بنویس…',
                  hintStyle: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: context.textSecondary,
                    fontSize: 13.5.sp,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10.h),
                ),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          GestureDetector(
            onTap: canSend ? _handleSubmit : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: canSend
                    ? AppTheme.goldColor
                    : AppTheme.goldColor.withValues(alpha: 0.25),
              ),
              alignment: Alignment.center,
              child: _isSubmitting
                  ? SizedBox(
                      width: 18.w,
                      height: 18.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                  : Icon(
                      LucideIcons.send,
                      size: 18.sp,
                      color: canSend
                          ? Colors.black
                          : Colors.black.withValues(alpha: 0.5),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
