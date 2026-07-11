import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AddCommentFormWidget extends StatefulWidget {
  const AddCommentFormWidget({
    required this.onSubmit,
    super.key,
    this.initialContent,
    this.initialRating,
    this.isLoading = false,
    this.focusNode,
  });
  final Future<bool> Function(String content, int? rating) onSubmit;
  final String? initialContent;
  final int? initialRating;
  final bool isLoading;
  final FocusNode? focusNode;

  @override
  State<AddCommentFormWidget> createState() => _AddCommentFormWidgetState();
}

class _AddCommentFormWidgetState extends State<AddCommentFormWidget> {
  final _contentController = TextEditingController();
  int? _selectedRating;
  bool _showRating = false;

  @override
  void initState() {
    super.initState();
    _contentController.text = widget.initialContent ?? '';
    _selectedRating = widget.initialRating;
    _showRating = widget.initialRating != null;
    _contentController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _contentController
      ..removeListener(_onTextChanged)
      ..dispose();
    super.dispose();
  }

  void _onTextChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canSend = _contentController.text.trim().isNotEmpty && !widget.isLoading;
    final fieldFill = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.04);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_showRating) ...[
            _buildStarSelector(),
            SizedBox(height: 8.h),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: fieldFill,
                    borderRadius: BorderRadius.circular(24.r),
                  ),
                  padding: EdgeInsets.only(right: 6.w, left: 12.w),
                  child: Row(
                    children: [
                      _buildRatingToggle(),
                      Expanded(
                        child: TextField(
                          controller: _contentController,
                          focusNode: widget.focusNode,
                          enabled: !widget.isLoading,
                          minLines: 1,
                          maxLines: 4,
                          maxLength: 500,
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
                            counterText: '',
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
                    ],
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              _buildSendButton(canSend: canSend),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingToggle() {
    final active = _showRating || _selectedRating != null;
    return IconButton(
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: BoxConstraints(minWidth: 34.w, minHeight: 34.h),
      tooltip: 'امتیاز',
      onPressed: () => setState(() => _showRating = !_showRating),
      icon: Icon(
        active ? Icons.star_rounded : Icons.star_outline_rounded,
        size: 20.sp,
        color: active
            ? AppTheme.goldColor
            : context.textSecondary.withValues(alpha: 0.7),
      ),
    );
  }

  Widget _buildSendButton({required bool canSend}) {
    return GestureDetector(
      onTap: canSend ? _submitForm : null,
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
        child: widget.isLoading
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
                color: canSend ? Colors.black : Colors.black.withValues(alpha: 0.5),
              ),
      ),
    );
  }

  Widget _buildStarSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : AppTheme.goldColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          Text(
            'امتیازت',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: context.textSecondary,
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          ...List.generate(5, (index) {
            final filled = index < (_selectedRating ?? 0);
            return GestureDetector(
              onTap: () => setState(() {
                _selectedRating = _selectedRating == index + 1 ? null : index + 1;
              }),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 2.w),
                child: Icon(
                  filled ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 24.sp,
                  color: filled
                      ? AppTheme.goldColor
                      : context.textSecondary.withValues(alpha: 0.4),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _submitForm() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) return;

    final ok = await widget.onSubmit(content, _selectedRating);
    if (!ok || !mounted) return;

    _contentController.clear();
    setState(() {
      _selectedRating = null;
      _showRating = false;
    });
  }
}
