import 'package:flutter/material.dart';
// دیالوگ افزودن مکمل/دارو (AddSupplementDialog) مخصوص meal plan
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/models/meal_plan.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AddSupplementDialog extends StatefulWidget {
  const AddSupplementDialog({super.key});

  @override
  State<AddSupplementDialog> createState() => _AddSupplementDialogState();
}

class _AddSupplementDialogState extends State<AddSupplementDialog> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  double? _amount;
  String? _unit = 'عدد';
  String? _time;
  String? _note;
  String _type = 'مکمل';
  double? _protein;
  double? _carbs;
  final List<String> _typeOptions = ['مکمل', 'دارو'];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2C1810), Color(0xFF3D2317), Color(0xFF4A2C1A)],
            ),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: Colors.amber[700]!.withValues(alpha: 0.4),
              width: 2.w,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 20.r,
                offset: Offset(0.w, 8.h),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: Colors.amber[700]?.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          child: Icon(
                            LucideIcons.pill,
                            color: Colors.amber[700],
                            size: 28.sp,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'افزودن مکمل/دارو',
                            style: TextStyle(
                              color: Colors.amber[200],
                              fontSize: 22.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.amber[700]?.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: Colors.amber[700]!.withValues(alpha: 0.3),
                              width: 1.5.w,
                            ),
                          ),
                          child: IconButton(
                            icon: Icon(LucideIcons.x, color: Colors.amber[700]),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // نوع مکمل/دارو
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: Colors.amber[700]!.withValues(alpha: 0.3),
                        ),
                      ),
                      child: DropdownButtonFormField<String>(
                        initialValue: _type,
                        dropdownColor: const Color(0xFF2C1810),
                        style: TextStyle(color: Colors.amber[200]),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 12.h,
                          ),
                        ),
                        items: _typeOptions.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Row(
                              children: [
                                Icon(
                                  type == 'مکمل'
                                      ? LucideIcons.pill
                                      : LucideIcons.heartPulse,
                                  color: type == 'مکمل'
                                      ? Colors.purple[400]
                                      : Colors.red[400],
                                  size: 18.sp,
                                ),
                                const SizedBox(width: 8),
                                Text(type),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setState(() => _type = val ?? 'مکمل'),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // نام مکمل/دارو
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'نام',
                        labelStyle: TextStyle(color: Colors.amber[300]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      style: TextStyle(color: Colors.amber[200]),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'نام را وارد کنید'
                          : null,
                      onChanged: (v) => setState(() => _name = v),
                    ),
                    const SizedBox(height: 16),
                    // مقدار و واحد
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'مقدار',
                              labelStyle: TextStyle(color: Colors.amber[300]),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            onChanged: (v) =>
                                setState(() => _amount = double.tryParse(v)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        DropdownButton<String>(
                          value: _unit,
                          items: ['عدد', 'گرم', 'میلی‌لیتر']
                              .map(
                                (u) =>
                                    DropdownMenuItem(value: u, child: Text(u)),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _unit = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // پروتئین و کربوهیدرات (اختیاری)
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'پروتئین (اختیاری)',
                              labelStyle: TextStyle(color: Colors.green[300]),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            onChanged: (v) =>
                                setState(() => _protein = double.tryParse(v)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'کربوهیدرات (اختیاری)',
                              labelStyle: TextStyle(color: Colors.blue[300]),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            onChanged: (v) =>
                                setState(() => _carbs = double.tryParse(v)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // زمان مصرف
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'زمان مصرف (اختیاری)',
                        labelStyle: TextStyle(color: Colors.amber[300]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      style: TextStyle(color: Colors.amber[200]),
                      onChanged: (v) => setState(() => _time = v),
                    ),
                    const SizedBox(height: 16),
                    // یادداشت
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'یادداشت (اختیاری)',
                        labelStyle: TextStyle(color: Colors.amber[300]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      style: TextStyle(color: Colors.amber[200]),
                      onChanged: (v) => setState(() => _note = v),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(LucideIcons.check),
                            label: const Text('تایید'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber[700],
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            onPressed: () {
                              if (_formKey.currentState?.validate() != true) {
                                return;
                              }
                              Navigator.of(context).pop(
                                SupplementEntry(
                                  name: _name,
                                  amount: _amount,
                                  unit: _unit,
                                  time: _time,
                                  note: _note,
                                  supplementType: _type,
                                  protein: _protein,
                                  carbs: _carbs,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.amber[200],
                              side: BorderSide(color: Colors.amber[700]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('انصراف'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
