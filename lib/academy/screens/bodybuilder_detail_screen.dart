import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/academy/models/professional_bodybuilder.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/widgets/gymai_network_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

class BodybuilderDetailScreen extends StatelessWidget {
  const BodybuilderDetailScreen({required this.bodybuilder, super.key});

  final ProfessionalBodybuilder bodybuilder;

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: context.backgroundColor,
        elevation: 0,
        title: Text(
          bodybuilder.name,
          style: AppTheme.headingStyle.copyWith(fontSize: 18.sp),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Image
            Container(
              width: double.infinity,
              height: 300.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    context.backgroundColor,
                  ],
                ),
              ),
              child: Stack(
                children: [
                  GymaiNetworkImage(
                    imageUrl: bodybuilder.profileImageUrl,
                    width: double.infinity,
                    height: double.infinity,
                    errorWidget: const ColoredBox(
                      color: Colors.black26,
                      child: Icon(
                        LucideIcons.user,
                        color: Colors.white54,
                        size: 64,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Info Section
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and Category
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          bodybuilder.name,
                          style: AppTheme.headingStyle.copyWith(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.goldColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          _getCategoryLabel(bodybuilder.category),
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 12.sp,
                            color: AppTheme.goldColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  // Basic Info
                  _buildInfoRow(
                    context,
                    icon: LucideIcons.mapPin,
                    label: 'ملیت',
                    value: bodybuilder.nationality,
                  ),
                  SizedBox(height: 12.h),
                  _buildInfoRow(
                    context,
                    icon: LucideIcons.cake,
                    label: 'سن',
                    value: '${bodybuilder.age} سال',
                  ),
                  if (bodybuilder.height != null) ...[
                    SizedBox(height: 12.h),
                    _buildInfoRow(
                      context,
                      icon: LucideIcons.ruler,
                      label: 'قد',
                      value: '${bodybuilder.height!.toStringAsFixed(0)} سانتی‌متر',
                    ),
                  ],
                  if (bodybuilder.weight != null) ...[
                    SizedBox(height: 12.h),
                    _buildInfoRow(
                      context,
                      icon: LucideIcons.scale,
                      label: 'وزن',
                      value: '${bodybuilder.weight!.toStringAsFixed(0)} کیلوگرم',
                    ),
                  ],

                  SizedBox(height: 24.h),

                  // Biography
                  _buildSectionTitle('زندگی‌نامه'),
                  SizedBox(height: 12.h),
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: context.separatorColor,
                      ),
                    ),
                    child: Text(
                      bodybuilder.biography,
                      style: AppTheme.bodyStyle.copyWith(
                        fontSize: 14.sp,
                        height: 1.8,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  ),

                  // Achievements
                  if (bodybuilder.achievements.isNotEmpty) ...[
                    SizedBox(height: 24.h),
                    _buildSectionTitle('دستاوردها'),
                    SizedBox(height: 12.h),
                    ...bodybuilder.achievements.map((achievement) => Padding(
                          padding: EdgeInsets.only(bottom: 8.h),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: EdgeInsets.only(top: 6.h, left: 8.w),
                                width: 6.w,
                                height: 6.w,
                                decoration: const BoxDecoration(
                                  color: AppTheme.goldColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  achievement,
                                  style: AppTheme.bodyStyle.copyWith(
                                    fontSize: 14.sp,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],

                  // Social Media Links
                  if (bodybuilder.instagramHandle != null ||
                      bodybuilder.youtubeChannel != null ||
                      bodybuilder.website != null) ...[
                    SizedBox(height: 24.h),
                    _buildSectionTitle('لینک‌های مرتبط'),
                    SizedBox(height: 12.h),
                    Wrap(
                      spacing: 12.w,
                      runSpacing: 12.h,
                      children: [
                        if (bodybuilder.instagramHandle != null)
                          _buildSocialButton(
                            context,
                            icon: LucideIcons.share2,
                            label: 'اینستاگرام',
                            onTap: () => _launchUrl(
                              'https://instagram.com/${bodybuilder.instagramHandle}',
                            ),
                          ),
                        if (bodybuilder.youtubeChannel != null)
                          _buildSocialButton(
                            context,
                            icon: LucideIcons.video,
                            label: 'یوتیوب',
                            onTap: () => _launchUrl(bodybuilder.youtubeChannel!),
                          ),
                        if (bodybuilder.website != null)
                          _buildSocialButton(
                            context,
                            icon: LucideIcons.globe,
                            label: 'وب‌سایت',
                            onTap: () => _launchUrl(bodybuilder.website!),
                          ),
                      ],
                    ),
                  ],

                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20.sp, color: AppTheme.goldColor),
        SizedBox(width: 12.w),
        Text(
          '$label: ',
          style: AppTheme.bodyStyle.copyWith(
            fontSize: 14.sp,
            color: context.textSecondary,
          ),
        ),
        Text(
          value,
          style: AppTheme.bodyStyle.copyWith(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTheme.headingStyle.copyWith(
        fontSize: 18.sp,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildSocialButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: context.separatorColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18.sp, color: AppTheme.goldColor),
            SizedBox(width: 8.w),
            Text(
              label,
              style: AppTheme.bodyStyle.copyWith(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'classic':
        return 'کلاسیک';
      case 'bodybuilding':
        return 'بدنسازی';
      case 'physique':
        return 'فیزیک';
      case 'wellness':
        return 'ولنس';
      default:
        return category;
    }
  }
}

