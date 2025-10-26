import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymaipro/payment/services/discount_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

class DiscountInput extends StatefulWidget {
  const DiscountInput({
    required this.originalAmount,
    required this.onDiscountApplied,
    required this.onDiscountRemoved,
    super.key,
  });
  final int originalAmount;
  final void Function(Map<String, dynamic>) onDiscountApplied;
  final VoidCallback onDiscountRemoved;

  @override
  State<DiscountInput> createState() => _DiscountInputState();
}

class _DiscountInputState extends State<DiscountInput> {
  final TextEditingController _controller = TextEditingController();
  final DiscountService _discountService = DiscountService();

  bool _isApplying = false;
  bool _hasDiscount = false;
  String? _discountMessage;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _applyDiscount() async {
    final code = _controller.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isApplying = true;
      _errorMessage = null;
    });

    try {
      final result = await _discountService.validateDiscountCode(
        code: code,
        originalAmount: widget.originalAmount,
      );

      if (result['valid'] == true) {
        setState(() {
          _hasDiscount = true;
          _discountMessage = result['message'] as String?;
          _errorMessage = null;
        });
        widget.onDiscountApplied(result);
      } else {
        setState(() {
          _errorMessage = result['error'] as String?;
          _hasDiscount = false;
          _discountMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'خطا در بررسی کد تخفیف';
        _hasDiscount = false;
        _discountMessage = null;
      });
    } finally {
      setState(() {
        _isApplying = false;
      });
    }
  }

  void _removeDiscount() {
    setState(() {
      _hasDiscount = false;
      _discountMessage = null;
      _errorMessage = null;
      _controller.clear();
    });
    widget.onDiscountRemoved();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: _hasDiscount
              ? Colors.green.withValues(alpha: 0.5)
              : _errorMessage != null
              ? Colors.red.withValues(alpha: 0.5)
              : Colors.white24,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.ticket, color: AppTheme.goldColor, size: 20.sp),
              const SizedBox(width: 8),
              Text(
                'کد تخفیف',
                style: GoogleFonts.vazirmatn(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.goldColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (!_hasDiscount) ...[
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _controller,
                    style: GoogleFonts.vazirmatn(
                      fontSize: 14.sp,
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                      hintText: 'کد تخفیف را وارد کنید',
                      hintStyle: GoogleFonts.vazirmatn(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 12.h,
                      ),
                    ),
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _applyDiscount(),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 80.w,
                  height: 44.h,
                  child: ElevatedButton(
                    onPressed: _isApplying ? null : _applyDiscount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.goldColor,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: _isApplying
                        ? SizedBox(
                            width: 16.w,
                            height: 16.h,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.black,
                              ),
                            ),
                          )
                        : Text(
                            'اعمال',
                            style: GoogleFonts.vazirmatn(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.checkCircle,
                    color: Colors.green,
                    size: 20.sp,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'کد "${_controller.text}" اعمال شد',
                          style: GoogleFonts.vazirmatn(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        if (_discountMessage != null)
                          Text(
                            _discountMessage!,
                            style: GoogleFonts.vazirmatn(
                              fontSize: 12.sp,
                              color: Colors.green.shade300,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _removeDiscount,
                    icon: Icon(LucideIcons.x, color: Colors.green, size: 18.sp),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.alertCircle, color: Colors.red, size: 16.sp),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.vazirmatn(
                        fontSize: 12.sp,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
