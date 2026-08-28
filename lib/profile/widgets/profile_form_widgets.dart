import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ProfileFormWidgets {
  static String _getDisplayName(String value) {
    switch (value) {
      case 'male':
        return 'مرد';
      case 'female':
        return 'زن';
      case 'other':
        return 'سایر';
      case 'sedentary':
        return 'بی‌تحرک';
      case 'light':
        return 'کم';
      case 'moderate':
        return 'متوسط';
      case 'active':
        return 'فعال';
      case 'very_active':
        return 'خیلی فعال';
      default:
        return value;
    }
  }

  static Widget buildFormSection(String title, List<Widget> children) {
    return Builder(
      builder: (context) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
          padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 8.h),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: context.separatorColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: context.textColor,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 10.h),
              ...children,
            ],
          ),
        );
      },
    );
  }

  static Widget buildTextField(
    String key,
    String label,
    IconData icon,
    Map<String, dynamic> profileData,
    void Function(String) onChanged,
  ) {
    return Builder(
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: 16.h),
          child: TextFormField(
            initialValue: profileData[key]?.toString() ?? '',
            onChanged: onChanged,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: context.textColor,
              fontSize: 14.sp,
            ),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: context.textSecondary,
                fontSize: 12.sp,
              ),
              prefixIcon: Icon(icon, color: AppTheme.goldColor),
              filled: true,
              fillColor: context.veryDarkBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: context.separatorColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: context.separatorColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(
                  color: AppTheme.goldColor,
                  width: 2,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget buildTextArea(
    String key,
    String label,
    IconData icon,
    Map<String, dynamic> profileData,
    void Function(String) onChanged,
  ) {
    return Builder(
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: 16.h),
          child: TextFormField(
            initialValue: profileData[key]?.toString() ?? '',
            onChanged: onChanged,
            maxLines: 3,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: context.textColor,
              fontSize: 14.sp,
            ),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: context.textSecondary,
                fontSize: 12.sp,
              ),
              prefixIcon: Icon(icon, color: AppTheme.goldColor),
              filled: true,
              fillColor: context.veryDarkBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: context.separatorColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: context.separatorColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(
                  color: AppTheme.goldColor,
                  width: 2,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget buildNumberField(
    String key,
    String label,
    IconData icon,
    Map<String, dynamic> profileData,
    void Function(String) onChanged,
  ) {
    return Builder(
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: 16.h),
          child: TextFormField(
            initialValue: profileData[key]?.toString() ?? '',
            onChanged: (value) {
              // فقط اعداد و نقطه مجاز
              final cleanValue = value.replaceAll(RegExp('[^0-9.]'), '');
              onChanged(cleanValue);
            },
            keyboardType: TextInputType.number,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: context.textColor,
              fontSize: 14.sp,
            ),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: context.textSecondary,
                fontSize: 12.sp,
              ),
              prefixIcon: Icon(icon, color: AppTheme.goldColor),
              filled: true,
              fillColor: context.veryDarkBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: context.separatorColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: context.separatorColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(
                  color: AppTheme.goldColor,
                  width: 2,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget buildDropdownField(
    String key,
    String label,
    IconData icon,
    List<String> options,
    Map<String, dynamic> profileData,
    void Function(String?) onChanged,
  ) {
    final currentValue = profileData[key]?.toString() ?? '';
    final validOptions = options.where((option) => option.isNotEmpty).toList();

    return Builder(
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: 16.h),
          child: DropdownButtonFormField<String>(
            initialValue: validOptions.contains(currentValue)
                ? currentValue
                : null,
            onChanged: onChanged,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: context.textColor,
              fontSize: 14.sp,
            ),
            dropdownColor: context.cardColor,
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: context.textSecondary,
                fontSize: 12.sp,
              ),
              prefixIcon: Icon(icon, color: AppTheme.goldColor),
              filled: true,
              fillColor: context.veryDarkBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: context.separatorColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: context.separatorColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(
                  color: AppTheme.goldColor,
                  width: 2,
                ),
              ),
            ),
            items: validOptions.map((String option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(
                  _getDisplayName(option),
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: context.textColor,
                    fontSize: 14.sp,
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  static Widget buildWeightField(
    String key,
    String label,
    IconData icon,
    Map<String, dynamic> profileData,
    VoidCallback onTap,
  ) {
    // ابتدا از وزن پروفایل استفاده کن، اگر نبود از آخرین وزن ثبت شده استفاده کن
    double? weightValue;

    // اگر وزن در پروفایل موجود است
    if (profileData[key] != null && profileData[key].toString().isNotEmpty) {
      weightValue = double.tryParse(profileData[key].toString());
    }

    // اگر وزن در پروفایل نبود، از آخرین وزن ثبت شده استفاده کن
    if (weightValue == null && profileData['latest_weight'] != null) {
      weightValue = double.tryParse(profileData['latest_weight'].toString());
    }

    final displayValue = weightValue != null
        ? '${weightValue.toStringAsFixed(1)} کیلوگرم'
        : 'ثبت نشده';

    return Builder(
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: 16.h),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12.r),
            child: Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: AppTheme.goldColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  Icon(icon, color: AppTheme.goldColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            color: context.textSecondary,
                            fontSize: 12.sp,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          displayValue,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            color: weightValue != null
                                ? context.textColor
                                : context.textSecondary,
                            fontSize: 16.sp,
                            fontWeight: weightValue != null
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    LucideIcons.edit3,
                    color: AppTheme.goldColor,
                    size: 20.sp,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget buildMultiSelectField(
    String key,
    String label,
    IconData icon,
    List<String> options,
    Map<String, dynamic> profileData,
    void Function(List<String>) onChanged,
  ) {
    return _MultiSelectField(
      fieldKey: key,
      label: label,
      icon: icon,
      options: options,
      profileData: profileData,
      onChanged: onChanged,
    );
  }
}

class _MultiSelectField extends StatefulWidget {
  const _MultiSelectField({
    required this.fieldKey,
    required this.label,
    required this.icon,
    required this.options,
    required this.profileData,
    required this.onChanged,
  });
  final String fieldKey;
  final String label;
  final IconData icon;
  final List<String> options;
  final Map<String, dynamic> profileData;
  final void Function(List<String>) onChanged;

  @override
  State<_MultiSelectField> createState() => _MultiSelectFieldState();
}

class _MultiSelectFieldState extends State<_MultiSelectField> {
  late List<String> currentValues;

  @override
  void initState() {
    super.initState();
    _initializeValues();
  }

  void _initializeValues() {
    currentValues = [];
    if (widget.profileData[widget.fieldKey] != null) {
      if (widget.profileData[widget.fieldKey] is List) {
        currentValues = List<String>.from(
          widget.profileData[widget.fieldKey] as Iterable<dynamic>,
        );
      } else if (widget.profileData[widget.fieldKey] is String) {
        currentValues = [widget.profileData[widget.fieldKey] as String];
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final validOptions = widget.options
        .where((option) => option.isNotEmpty)
        .toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: context.textSecondary,
              fontSize: 14.sp,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: AppTheme.goldColor.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: validOptions.map((option) {
                final isSelected = currentValues.contains(option);
                return CheckboxListTile(
                  title: Text(
                    option,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: context.textColor,
                      fontSize: 14.sp,
                    ),
                  ),
                  value: isSelected,
                  onChanged: (bool? value) {
                    setState(() {
                      if (value ?? false) {
                        if (!currentValues.contains(option)) {
                          currentValues.add(option);
                        }
                      } else {
                        currentValues.remove(option);
                      }
                    });

                    // به‌روزرسانی profileData
                    widget.profileData[widget.fieldKey] = List<String>.from(
                      currentValues,
                    );
                    widget.onChanged(List<String>.from(currentValues));
                  },
                  activeColor: AppTheme.goldColor,
                  checkColor: Colors.white,
                  contentPadding: EdgeInsets.zero,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
