import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

class TrainerSearchFilterWidget extends StatefulWidget {
  const TrainerSearchFilterWidget({
    required this.searchController,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.selectedSpecialization,
    super.key,
    this.minRating,
    this.maxHourlyRate,
    this.isOnline,
  });
  final TextEditingController searchController;
  final Function(String) onSearchChanged;
  final Function({
    String? specialization,
    double? minRating,
    double? maxHourlyRate,
    bool? isOnline,
  })
  onFilterChanged;

  final String selectedSpecialization;
  final double? minRating;
  final double? maxHourlyRate;
  final bool? isOnline;

  @override
  State<TrainerSearchFilterWidget> createState() =>
      _TrainerSearchFilterWidgetState();
}

class _TrainerSearchFilterWidgetState extends State<TrainerSearchFilterWidget> {
  bool _showFilters = false;

  final List<String> _specializations = [
    'بدنسازی',
    'کاردیو',
    'یوگا',
    'پیلاتس',
    'کیک‌بوکسینگ',
    'شنا',
    'دویدن',
    'کشتی',
    'تنیس',
    'فوتبال',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          // جستجو
          TextField(
            controller: widget.searchController,
            onChanged: widget.onSearchChanged,
            style: GoogleFonts.vazirmatn(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'جستجوی مربی...',
              hintStyle: GoogleFonts.vazirmatn(color: Colors.grey[400]),
              prefixIcon: const Icon(
                LucideIcons.search,
                color: AppTheme.goldColor,
              ),
              suffixIcon: IconButton(
                onPressed: () {
                  widget.searchController.clear();
                  widget.onSearchChanged('');
                },
                icon: const Icon(LucideIcons.x, color: Colors.grey),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: Colors.grey[600]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: Colors.grey[600]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: AppTheme.goldColor, width: 2.w),
              ),
              filled: true,
              fillColor: const Color(0xFF2A2A2A),
            ),
          ),
          const SizedBox(height: 12),

          // دکمه فیلتر
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _showFilters = !_showFilters;
                    });
                  },
                  icon: Icon(
                    _showFilters ? LucideIcons.chevronUp : LucideIcons.filter,
                    color: Colors.white,
                  ),
                  label: Text(
                    'فیلترها',
                    style: GoogleFonts.vazirmatn(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.goldColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(LucideIcons.refreshCw, color: Colors.white),
                label: Text(
                  'پاک کردن',
                  style: GoogleFonts.vazirmatn(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ],
          ),

          // پنل فیلترها
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                const SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppTheme.goldColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'فیلترها',
                        style: GoogleFonts.vazirmatn(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // تخصص
                      Text(
                        'تخصص',
                        style: GoogleFonts.vazirmatn(
                          color: Colors.grey[300],
                          fontSize: 14.sp,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _specializations.map((spec) {
                          final isSelected =
                              widget.selectedSpecialization == spec;
                          return FilterChip(
                            label: Text(
                              spec,
                              style: GoogleFonts.vazirmatn(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey[300],
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              widget.onFilterChanged(
                                specialization: selected ? spec : '',
                              );
                            },
                            backgroundColor: const Color(0xFF3A3A3A),
                            selectedColor: AppTheme.goldColor,
                            checkmarkColor: Colors.white,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // امتیاز
                      Text(
                        'حداقل امتیاز',
                        style: GoogleFonts.vazirmatn(
                          color: Colors.grey[300],
                          fontSize: 14.sp,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Slider(
                        value: widget.minRating ?? 0.0,
                        max: 5,
                        divisions: 10,
                        activeColor: AppTheme.goldColor,
                        inactiveColor: Colors.grey[600],
                        onChanged: (value) {
                          widget.onFilterChanged(minRating: value);
                        },
                      ),
                      Text(
                        '${(widget.minRating ?? 0.0).toStringAsFixed(1)} ستاره',
                        style: GoogleFonts.vazirmatn(
                          color: AppTheme.goldColor,
                          fontSize: 12.sp,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // قیمت
                      Text(
                        'حداکثر قیمت ساعتی',
                        style: GoogleFonts.vazirmatn(
                          color: Colors.grey[300],
                          fontSize: 14.sp,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Slider(
                        value: widget.maxHourlyRate ?? 1000000.0,
                        min: 100000,
                        max: 1000000,
                        divisions: 9,
                        activeColor: AppTheme.goldColor,
                        inactiveColor: Colors.grey[600],
                        onChanged: (value) {
                          widget.onFilterChanged(maxHourlyRate: value);
                        },
                      ),
                      Text(
                        '${(widget.maxHourlyRate ?? 1000000.0).toStringAsFixed(0)} تومان',
                        style: GoogleFonts.vazirmatn(
                          color: AppTheme.goldColor,
                          fontSize: 12.sp,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // آنلاین
                      Row(
                        children: [
                          Checkbox(
                            value: widget.isOnline ?? false,
                            onChanged: (value) {
                              widget.onFilterChanged(isOnline: value);
                            },
                            activeColor: AppTheme.goldColor,
                          ),
                          Text(
                            'فقط آنلاین',
                            style: GoogleFonts.vazirmatn(
                              color: Colors.grey[300],
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            crossFadeState: _showFilters
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  void _clearFilters() {
    widget.searchController.clear();
    widget.onSearchChanged('');
    widget.onFilterChanged(
      specialization: '',
      minRating: null,
      maxHourlyRate: null,
      isOnline: null,
    );
  }
}
