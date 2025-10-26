import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ProfileStatsWidgets {
  static Widget buildStatsGrid(Map<String, dynamic> profileData) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppTheme.goldColor.withAlpha(30)),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            Text(
              'آمار پروفایل',
              style: GoogleFonts.vazirmatn(
                color: AppTheme.goldColor,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                buildStatCard(
                  'قد',
                  profileData['height']?.toString(),
                  'سانتی‌متر',
                  LucideIcons.ruler,
                ),
                buildStatCard(
                  'وزن',
                  _getWeightDisplayValue(profileData),
                  'کیلوگرم',
                  LucideIcons.scale,
                ),
                // روزهای عضویت
                buildStatCard(
                  'روزهای عضویت',
                  _getMembershipDays(profileData),
                  'روز',
                  LucideIcons.calendar,
                ),
                buildStatCard(
                  'دور بازو',
                  profileData['arm_circumference']?.toString(),
                  'سانتی‌متر',
                  LucideIcons.circle,
                ),
                buildStatCard(
                  'دور سینه',
                  profileData['chest_circumference']?.toString(),
                  'سانتی‌متر',
                  LucideIcons.heart,
                ),
                buildStatCard(
                  'دور کمر',
                  profileData['waist_circumference']?.toString(),
                  'سانتی‌متر',
                  LucideIcons.circle,
                ),
                buildStatCard(
                  'دور باسن',
                  profileData['hip_circumference']?.toString(),
                  'سانتی‌متر',
                  LucideIcons.circle,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _getWeightDisplayValue(Map<String, dynamic> profileData) {
    // ابتدا از وزن پروفایل استفاده کن، اگر نبود از آخرین وزن ثبت شده استفاده کن
    double? weightValue;

    // اگر وزن در پروفایل موجود است
    if (profileData['weight'] != null &&
        profileData['weight'].toString().isNotEmpty) {
      weightValue = double.tryParse(profileData['weight'].toString());
    }

    // اگر وزن در پروفایل نبود، از آخرین وزن ثبت شده استفاده کن
    if (weightValue == null && profileData['latest_weight'] != null) {
      weightValue = double.tryParse(profileData['latest_weight'].toString());
    }

    return weightValue != null ? weightValue.toStringAsFixed(1) : '--';
  }

  static String _getMembershipDays(Map<String, dynamic> profileData) {
    try {
      final createdAtRaw = profileData['created_at']?.toString();
      if (createdAtRaw == null || createdAtRaw.isEmpty) return '--';
      final createdAt = DateTime.tryParse(createdAtRaw);
      if (createdAt == null) return '--';
      final days = DateTime.now().difference(createdAt).inDays;
      return days >= 0 ? days.toString() : '--';
    } catch (_) {
      return '--';
    }
  }

  static Widget buildStatCard(
    String title,
    String? value,
    String unit,
    IconData icon,
  ) {
    final displayValue = value != null && value.isNotEmpty ? value : '--';

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppTheme.goldColor.withAlpha(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.goldColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.vazirmatn(
                    color: Colors.grey,
                    fontSize: 12.sp,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                displayValue,
                style: GoogleFonts.vazirmatn(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: GoogleFonts.vazirmatn(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
