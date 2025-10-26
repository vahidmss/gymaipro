import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';

class CommentForm extends StatefulWidget {
  const CommentForm({required this.onSubmit, super.key});

  final void Function(String comment) onSubmit;

  @override
  State<CommentForm> createState() => _CommentFormState();
}

class _CommentFormState extends State<CommentForm> {
  final TextEditingController _commentCtrl = TextEditingController();

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white10),
      ),
      padding: EdgeInsets.all(12.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'ثبت نظر',
            style: AppTheme.headingStyle.copyWith(fontSize: 16.sp),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _commentCtrl,
            minLines: 2,
            maxLines: 5,
            textDirection: TextDirection.rtl,
            decoration: AppTheme.textFieldDecoration(
              'نظر خود را وارد کنید...',
              hint: 'نظر خود را وارد کنید...',
            ),
            style: AppTheme.bodyStyle,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton.icon(
              onPressed: () {
                final text = _commentCtrl.text.trim();
                if (text.isEmpty) return;
                widget.onSubmit(text);
                _commentCtrl.clear();
              },
              style: AppTheme.primaryButtonStyle.copyWith(
                padding: WidgetStateProperty.all(
                  EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                ),
              ),
              icon: const Icon(Icons.send, size: 18),
              label: const Text('ارسال'),
            ),
          ),
        ],
      ),
    );
  }
}
