import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/workout_plan/models/workout_questionnaire_models.dart';
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
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppTheme.goldColor.withValues(alpha: 0.1),
            blurRadius: 8.r,
            offset: Offset(0.w, 2.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان سوال
          Text(
            widget.question.questionText,
            style: GoogleFonts.vazirmatn(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 20.h),

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

    return ListView.builder(
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
            margin: const EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.goldColor.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: isSelected
                    ? AppTheme.goldColor
                    : Colors.grey.withValues(alpha: 0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 20.w,
                  height: 20.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppTheme.goldColor : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? AppTheme.goldColor : Colors.grey,
                      width: 2.w,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          LucideIcons.check,
                          size: 12.sp,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    option,
                    style: GoogleFonts.vazirmatn(
                      fontSize: 16.sp,
                      color: Colors.black,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
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

    return ListView.builder(
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
            margin: const EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.goldColor.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: isSelected
                    ? AppTheme.goldColor
                    : Colors.grey.withValues(alpha: 0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 20.w,
                  height: 20.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4.r),
                    color: isSelected ? AppTheme.goldColor : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? AppTheme.goldColor : Colors.grey,
                      width: 2.w,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          LucideIcons.check,
                          size: 12.sp,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    option,
                    style: GoogleFonts.vazirmatn(
                      fontSize: 16.sp,
                      color: Colors.black,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
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
      style: GoogleFonts.vazirmatn(fontSize: 16.sp, color: Colors.black),
      textDirection: TextDirection.rtl, // جهت راست به چپ
      decoration: InputDecoration(
        hintText: 'پاسخ خود را وارد کنید...',
        hintStyle: GoogleFonts.vazirmatn(color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppTheme.goldColor, width: 2),
        ),
        contentPadding: EdgeInsets.all(16.w),
      ),
      maxLines: 3,
      textInputAction: TextInputAction.done,
      onSubmitted: (value) {
        // مخفی کردن کیبورد پس از ارسال
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

    return Column(
      children: [
        Text(
          '${(_answerNumber ?? min.toDouble()).toInt()}',
          style: GoogleFonts.vazirmatn(
            fontSize: 32.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.goldColor,
          ),
        ),
        SizedBox(height: 20.h),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  final current = (_answerNumber ?? min.toDouble()).toInt();
                  if (current > min) {
                    setState(() {
                      _answerNumber = (current - 1).toDouble();
                    });
                    widget.onAnswerChanged(_answerNumber);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.goldColor.withValues(alpha: 0.1),
                  foregroundColor: AppTheme.goldColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Icon(LucideIcons.minus),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  final current = (_answerNumber ?? min.toDouble()).toInt();
                  if (current < max) {
                    setState(() {
                      _answerNumber = (current + 1).toDouble();
                    });
                    widget.onAnswerChanged(_answerNumber);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.goldColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Icon(LucideIcons.plus),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        Slider(
          value: _answerNumber ?? min.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          activeColor: AppTheme.goldColor,
          onChanged: (value) {
            setState(() {
              _answerNumber = value;
            });
            widget.onAnswerChanged(_answerNumber);
          },
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
      children: [
        Text(
          '${(_answerNumber ?? min.toDouble()).toInt()}',
          style: GoogleFonts.vazirmatn(
            fontSize: 32.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.goldColor,
          ),
        ),
        SizedBox(height: 20.h),
        Slider(
          value: _answerNumber ?? min.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          activeColor: AppTheme.goldColor,
          onChanged: (value) {
            setState(() {
              _answerNumber = value;
            });
            widget.onAnswerChanged(_answerNumber);
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              min.toString(),
              style: GoogleFonts.vazirmatn(color: Colors.grey),
            ),
            Text(
              max.toString(),
              style: GoogleFonts.vazirmatn(color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }

  List<String> _getOptions() {
    final options = widget.question.options;
    if (options == null) return [];

    // options یک Map<String, dynamic> است
    // برای سوالات single_choice و multiple_choice، options باید یک List باشد
    // که در JSON به صورت ["گزینه1", "گزینه2"] ذخیره می‌شود

    // اگر options یک List است (که باید باشد)
    if (options is List) {
      return List<String>.from(options);
    }

    return [];
  }
}
