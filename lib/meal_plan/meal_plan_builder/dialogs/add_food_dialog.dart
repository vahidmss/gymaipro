import 'package:flutter/material.dart';
// دیالوگ افزودن غذا (AddFoodDialog) مخصوص meal plan
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/models/food.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AddFoodDialog extends StatefulWidget {
  const AddFoodDialog({required this.foods, super.key});
  final List<Food> foods;

  @override
  State<AddFoodDialog> createState() => _AddFoodDialogState();
}

class _AddFoodDialogState extends State<AddFoodDialog> {
  Food? _selectedFood;
  String? _selectedUnit;
  double? _amount;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.foods
        .where((f) => f.title.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    final nutrition = _selectedFood?.nutrition;
    final double factor = ((_amount ?? 0) <= 0) ? 0 : ((_amount ?? 0) / 100.0);

    double parse(String s) =>
        double.tryParse(s.trim().replaceAll(',', '.')) ?? 0;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.all(20.w),
          constraints: const BoxConstraints(maxWidth: 520),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.25),
              width: 1.2.w,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 18.r,
                offset: Offset(0.w, 8.h),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: const Color(
                            0xFFD4AF37,
                          ).withValues(alpha: 0.35),
                        ),
                      ),
                      child: Icon(
                        LucideIcons.utensils,
                        color: const Color(0xFFD4AF37),
                        size: 18.sp,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'افزودن غذا',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: IconButton(
                        icon: Icon(
                          LucideIcons.x,
                          color: Colors.white70,
                          size: 18.sp,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Search
                TextField(
                  decoration: InputDecoration(
                    hintText: 'جستجو ...',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    prefixIcon: Icon(
                      LucideIcons.search,
                      color: const Color(0xFFD4AF37),
                      size: 18.sp,
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.06),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(
                        color: const Color(0xFFD4AF37),
                        width: 1.2.w,
                      ),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 10.h,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (v) => setState(() => _query = v),
                ),
                const SizedBox(height: 16),
                // List
                SizedBox(
                  height: 220.h,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, idx) {
                        final food = filtered[idx];
                        final bool isSelected = _selectedFood?.id == food.id;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedFood = food;
                              _selectedUnit = 'گرم';
                              _amount = null;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 10.h,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(
                                      0xFFD4AF37,
                                    ).withValues(alpha: 0.10)
                                  : Colors.transparent,
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.06),
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                if (food.imageUrl.isNotEmpty)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8.r),
                                    child: Image.network(
                                      food.imageUrl,
                                      width: 40.w,
                                      height: 40.h,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                else
                                  const Icon(
                                    LucideIcons.image,
                                    color: Colors.white54,
                                  ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    food.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    LucideIcons.check,
                                    color: const Color(0xFFD4AF37),
                                    size: 16.sp,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_selectedFood != null) ...[
                  Row(
                    children: [
                      if (_selectedFood!.imageUrl.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18.r),
                          child: Image.network(
                            _selectedFood!.imageUrl,
                            width: 48.w,
                            height: 48.h,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        Icon(
                          LucideIcons.image,
                          size: 36.sp,
                          color: Colors.white54,
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'جزئیات غذا',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'مقدار',
                            labelStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                            hintText: 'بر حسب گرم',
                            hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.06),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(12.r),
                              ),
                              borderSide: BorderSide(
                                color: const Color(0xFFD4AF37),
                                width: 1.2.w,
                              ),
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                          onChanged: (v) => setState(
                            () => _amount = double.tryParse(
                              v.replaceAll(',', '.'),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      DropdownButtonHideUnderline(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 8.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          child: DropdownButton<String>(
                            value: _selectedUnit,
                            dropdownColor: const Color(0xFF1E1E1E),
                            items: ['گرم', 'عدد', 'لیوان']
                                .map(
                                  (u) => DropdownMenuItem(
                                    value: u,
                                    child: Text(u),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setState(() => _selectedUnit = v),
                            icon: Icon(
                              LucideIcons.chevronDown,
                              color: Colors.white70,
                              size: 16.sp,
                            ),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if ((_amount ?? 0) > 0) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          'کالری: ${((parse(nutrition?.calories ?? '0')) * factor).toStringAsFixed(0)}',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12.sp,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'پروتئین: ${((parse(nutrition?.protein ?? '0')) * factor).toStringAsFixed(1)}g',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(LucideIcons.check),
                          label: const Text('تایید'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD4AF37),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: _selectedFood != null && (_amount ?? 0) > 0
                              ? () {
                                  Navigator.of(context).pop({
                                    'food': _selectedFood,
                                    'amount': _amount,
                                    'unit': _selectedUnit,
                                  });
                                }
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFD4AF37),
                            side: const BorderSide(color: Color(0xFFD4AF37)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('انصراف'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
