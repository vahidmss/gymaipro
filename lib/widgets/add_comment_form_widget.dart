import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';

class AddCommentFormWidget extends StatefulWidget {
  const AddCommentFormWidget({
    required this.onSubmit,
    super.key,
    this.initialContent,
    this.initialRating,
    this.isLoading = false,
  });
  final Function(String content, int? rating) onSubmit;
  final String? initialContent;
  final int? initialRating;
  final bool isLoading;

  @override
  State<AddCommentFormWidget> createState() => _AddCommentFormWidgetState();
}

class _AddCommentFormWidgetState extends State<AddCommentFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  int? _selectedRating;
  bool _showRating = false;

  @override
  void initState() {
    super.initState();
    _contentController.text = widget.initialContent ?? '';
    _selectedRating = widget.initialRating;
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(
                    Icons.comment,
                    color: AppTheme.goldColor,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'نظر خود را بنویسید',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Content Input
              TextFormField(
                controller: _contentController,
                maxLines: 4,
                maxLength: 500,
                textInputAction: TextInputAction.done,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  hintText: 'نظر خود را اینجا بنویسید...',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  filled: true,
                  fillColor: Colors.black.withValues(alpha: 0.2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: AppTheme.goldColor,
                      width: 2.w,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                ),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'لطفاً نظر خود را بنویسید';
                  }
                  if (value.trim().length < 10) {
                    return 'نظر باید حداقل 10 کاراکتر باشد';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Rating Toggle
              Row(
                children: [
                  Text(
                    'امتیاز دهید:',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14.sp,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: _showRating,
                    onChanged: (value) {
                      setState(() {
                        _showRating = value;
                        if (!value) _selectedRating = null;
                      });
                    },
                    activeThumbColor: AppTheme.goldColor,
                  ),
                ],
              ),

              // Rating Stars
              if (_showRating) ...[
                const SizedBox(height: 12),
                _buildRatingStars(),
                const SizedBox(height: 16),
              ],

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton(
                  onPressed: widget.isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.goldColor,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 0,
                  ),
                  child: widget.isLoading
                      ? SizedBox(
                          width: 24.w,
                          height: 24.h,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.black,
                            ),
                          ),
                        )
                      : Text(
                          'ارسال نظر',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingStars() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedRating = index + 1;
            });
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              index < (_selectedRating ?? 0) ? Icons.star : Icons.star_border,
              color: AppTheme.goldColor,
              size: 32.sp,
            ),
          ),
        );
      }),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final content = _contentController.text.trim();
      widget.onSubmit(content, _selectedRating);

      // Clear form after submission
      _contentController.clear();
      setState(() {
        _selectedRating = null;
        _showRating = false;
      });
    }
  }
}
