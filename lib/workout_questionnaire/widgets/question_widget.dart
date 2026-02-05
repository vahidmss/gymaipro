import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/workout_questionnaire/models/workout_questionnaire_models.dart';
import 'package:lucide_icons/lucide_icons.dart';

class QuestionWidget extends StatefulWidget {
  const QuestionWidget({
    required this.question,
    required this.onAnswerChanged,
    super.key,
    this.initialAnswer,
  });
  final WorkoutQuestion question;
  final dynamic initialAnswer;
  final void Function(dynamic) onAnswerChanged;

  @override
  State<QuestionWidget> createState() => _QuestionWidgetState();
}

class _QuestionWidgetState extends State<QuestionWidget> {
  // نگهداری مقدار پاسخ به صورت type-safe بر اساس نوع سوال
  String? _answerText;
  double? _answerNumber;
  List<String> _answerChoices = <String>[];
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // مقدار اولیه را بر اساس نوع سوال ست می‌کنیم
    switch (widget.question.questionType) {
      case QuestionType.text:
      case QuestionType.singleChoice:
        _answerText = widget.initialAnswer?.toString();
      case QuestionType.number:
      case QuestionType.slider:
        _answerNumber = switch (widget.initialAnswer) {
          final num n => n.toDouble(),
          _ => null,
        };
      case QuestionType.multipleChoice:
        if (widget.initialAnswer is List) {
          _answerChoices = List<String>.from(widget.initialAnswer as List);
        }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: isDark
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.lightGradientStart.withValues(alpha: 0.15),
                  context.cardColor,
                  AppTheme.lightGradientEnd.withValues(alpha: 0.1),
                ],
              ),
        color: isDark ? context.cardColor : null,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: isDark ? 0.3 : 0.5),
          width: 1.5.w,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.goldColor.withValues(alpha: isDark ? 0.15 : 0.35),
            blurRadius: 16.r,
            offset: Offset(0.w, 6.h),
            spreadRadius: 1.r,
          ),
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.5)
                : AppTheme.lightTextColor.withValues(alpha: 0.08),
            blurRadius: 8.r,
            offset: Offset(0.w, 2.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // عنوان سوال
          Text(
            widget.question.questionText,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 17.sp,
              fontWeight: FontWeight.w600,
              color: context.textColor,
              height: 1.4,
            ),
          ),
          SizedBox(height: 16.h),

          // محتوای سوال بر اساس نوع
          Expanded(child: _buildQuestionContent()),
        ],
      ),
    );
  }

  Widget _buildQuestionContent() {
    switch (widget.question.questionType) {
      case QuestionType.singleChoice:
        return _buildSingleChoice();
      case QuestionType.multipleChoice:
        return _buildMultipleChoice();
      case QuestionType.text:
        return _buildTextInput();
      case QuestionType.number:
        return _buildNumberInput();
      case QuestionType.slider:
        return _buildSlider();
    }
  }

  Widget _buildSingleChoice() {
    final options = _getOptions();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: options.length,
      itemBuilder: (context, index) {
        final option = options[index];
        final isSelected = _answerText == option;

        return GestureDetector(
          onTap: () {
            setState(() {
              _answerText = option;
            });
            widget.onAnswerChanged(_answerText);
          },
          child: Container(
            margin: EdgeInsets.only(bottom: 10.h),
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.goldColor.withValues(alpha: isDark ? 0.2 : 0.12)
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.03)),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: isSelected
                    ? AppTheme.goldColor
                    : AppTheme.goldColor.withValues(alpha: 0.2),
                width: isSelected ? 1.5.w : 1.w,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 18.w,
                  height: 18.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppTheme.goldColor : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.goldColor
                          : (isDark
                                ? Colors.white.withValues(alpha: 0.3)
                                : Colors.black.withValues(alpha: 0.2)),
                      width: 1.5.w,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          LucideIcons.check,
                          size: 10.sp,
                          color: Colors.white,
                        )
                      : null,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    option,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 14.sp,
                      color: context.textColor,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMultipleChoice() {
    final options = _getOptions();
    final selectedOptions = List<String>.from(_answerChoices);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: options.length,
      itemBuilder: (context, index) {
        final option = options[index];
        final isSelected = selectedOptions.contains(option);

        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                selectedOptions.remove(option);
              } else {
                selectedOptions.add(option);
              }
              _answerChoices = List<String>.from(selectedOptions);
            });
            widget.onAnswerChanged(_answerChoices);
          },
          child: Container(
            margin: EdgeInsets.only(bottom: 10.h),
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.goldColor.withValues(alpha: isDark ? 0.2 : 0.12)
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.03)),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: isSelected
                    ? AppTheme.goldColor
                    : AppTheme.goldColor.withValues(alpha: 0.2),
                width: isSelected ? 1.5.w : 1.w,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 18.w,
                  height: 18.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4.r),
                    color: isSelected ? AppTheme.goldColor : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.goldColor
                          : (isDark
                                ? Colors.white.withValues(alpha: 0.3)
                                : Colors.black.withValues(alpha: 0.2)),
                      width: 1.5.w,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          LucideIcons.check,
                          size: 10.sp,
                          color: Colors.white,
                        )
                      : null,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    option,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 14.sp,
                      color: context.textColor,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextInput() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextField(
      controller: TextEditingController(text: _answerText ?? ''),
      onChanged: (value) {
        _answerText = value;
        // debounce برای جلوگیری از ذخیره‌سازی مکرر
        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(milliseconds: 500), () {
          widget.onAnswerChanged(_answerText);
        });
      },
      style: TextStyle(
        fontFamily: AppTheme.fontFamily,
        fontSize: 14.sp,
        color: context.textColor,
      ),
      textDirection: TextDirection.rtl,
      decoration: InputDecoration(
        hintText: 'پاسخ خود را وارد کنید...',
        hintStyle: TextStyle(
          fontFamily: AppTheme.fontFamily,
          color: context.textSecondary,
          fontSize: 14.sp,
        ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.02),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(
            color: AppTheme.goldColor.withValues(alpha: 0.2),
            width: 1.w,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(
            color: AppTheme.goldColor.withValues(alpha: 0.2),
            width: 1.w,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: AppTheme.goldColor, width: 1.5.w),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      ),
      maxLines: 3,
      textInputAction: TextInputAction.done,
      onSubmitted: (value) {
        FocusScope.of(context).unfocus();
      },
    );
  }

  Widget _buildNumberInput() {
    final Map<String, dynamic>? opts = widget.question.options is Map
        ? Map<String, dynamic>.from(widget.question.options as Map)
        : null;
    final int min = (opts?['min'] as num?)?.toInt() ?? 0;
    final int max = (opts?['max'] as num?)?.toInt() ?? 100;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${(_answerNumber ?? min.toDouble()).toInt()}',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 36.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.goldColor,
            height: 1.2,
          ),
        ),
        SizedBox(height: 24.h),
        Row(
          children: [
            Expanded(
              child: _buildMinimalButton(
                icon: LucideIcons.minus,
                onPressed: () {
                  final current = (_answerNumber ?? min.toDouble()).toInt();
                  if (current > min) {
                    setState(() {
                      _answerNumber = (current - 1).toDouble();
                    });
                    widget.onAnswerChanged(_answerNumber);
                  }
                },
                isDark: isDark,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildMinimalButton(
                icon: LucideIcons.plus,
                onPressed: () {
                  final current = (_answerNumber ?? min.toDouble()).toInt();
                  if (current < max) {
                    setState(() {
                      _answerNumber = (current + 1).toDouble();
                    });
                    widget.onAnswerChanged(_answerNumber);
                  }
                },
                isDark: isDark,
                isPrimary: true,
              ),
            ),
          ],
        ),
        SizedBox(height: 20.h),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppTheme.goldColor,
            inactiveTrackColor: AppTheme.goldColor.withValues(alpha: 0.2),
            thumbColor: AppTheme.goldColor,
            overlayColor: AppTheme.goldColor.withValues(alpha: 0.1),
            trackHeight: 3.h,
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8.r),
          ),
          child: Slider(
            value: _answerNumber ?? min.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
            onChanged: (value) {
              setState(() {
                _answerNumber = value;
              });
              widget.onAnswerChanged(_answerNumber);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSlider() {
    final Map<String, dynamic>? opts = widget.question.options is Map
        ? Map<String, dynamic>.from(widget.question.options as Map)
        : null;
    final int min = (opts?['min'] as num?)?.toInt() ?? 0;
    final int max = (opts?['max'] as num?)?.toInt() ?? 100;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${(_answerNumber ?? min.toDouble()).toInt()}',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 36.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.goldColor,
            height: 1.2,
          ),
        ),
        SizedBox(height: 24.h),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppTheme.goldColor,
            inactiveTrackColor: AppTheme.goldColor.withValues(alpha: 0.2),
            thumbColor: AppTheme.goldColor,
            overlayColor: AppTheme.goldColor.withValues(alpha: 0.1),
            trackHeight: 3.h,
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8.r),
          ),
          child: Slider(
            value: _answerNumber ?? min.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
            onChanged: (value) {
              setState(() {
                _answerNumber = value;
              });
              widget.onAnswerChanged(_answerNumber);
            },
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              min.toString(),
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: context.textSecondary,
                fontSize: 12.sp,
              ),
            ),
            Text(
              max.toString(),
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: context.textSecondary,
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMinimalButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isDark,
    bool isPrimary = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: isPrimary
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.goldColor, AppTheme.darkGold],
              )
            : null,
        color: isPrimary
            ? null
            : AppTheme.goldColor.withValues(alpha: isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: isPrimary ? 1 : 0.3),
          width: 1.w,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: Icon(
              icon,
              color: isPrimary ? Colors.white : AppTheme.goldColor,
              size: 18.sp,
            ),
          ),
        ),
      ),
    );
  }

  List<String> _getOptions() {
    final options = widget.question.options;
    if (options == null) return [];

    if (options is List) {
      return List<String>.from(options);
    }

    return [];
  }
}
