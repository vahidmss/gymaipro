import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/admin/services/admin_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// صفحه مشاهده عکس‌ها و فایل‌های آپلود شده
class AdminImagesScreen extends StatefulWidget {
  const AdminImagesScreen({super.key});

  @override
  State<AdminImagesScreen> createState() => _AdminImagesScreenState();
}

class _AdminImagesScreenState extends State<AdminImagesScreen> {
  final AdminService _adminService = AdminService();
  List<Map<String, dynamic>> _images = [];
  bool _isLoading = false;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    setState(() => _isLoading = true);
    try {
      final images = await _adminService.getAllUploadedImages();
      if (mounted) {
        setState(() {
          _images = images
              .where((img) {
                if (_selectedFilter == 'all') return true;
                return img['type'] == _selectedFilter;
              })
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در بارگذاری عکس‌ها: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImageFullScreen(String imageUrl, String imageName) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (context, url, error) => const Icon(
                    LucideIcons.imageOff,
                    size: 64,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40.h,
              right: 20.w,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  LucideIcons.x,
                  color: Colors.white,
                  size: 32,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                ),
              ),
            ),
            Positioned(
              bottom: 40.h,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(16.w),
                color: Colors.black54,
                child: Text(
                  imageName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getImageTypeLabel(String type) {
    switch (type) {
      case 'chat_attachment':
        return 'پیوست چت';
      case 'avatar':
        return 'آواتار';
      case 'body_photo':
        return 'عکس بدنی';
      default:
        return type;
    }
  }

  Color _getImageTypeColor(String type) {
    switch (type) {
      case 'chat_attachment':
        return Colors.blue;
      case 'avatar':
        return Colors.green;
      case 'body_photo':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        // فیلتر
        Container(
          padding: EdgeInsets.all(16.w),
          color: isDark ? AppTheme.darkCardColor : AppTheme.lightCardColor,
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedFilter,
                  decoration: InputDecoration(
                    labelText: 'فیلتر نوع',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('همه')),
                    DropdownMenuItem(value: 'chat_attachment', child: Text('پیوست چت')),
                    DropdownMenuItem(value: 'avatar', child: Text('آواتار')),
                    DropdownMenuItem(value: 'body_photo', child: Text('عکس بدنی')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedFilter = value);
                      _loadImages();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        // گرید عکس‌ها
        Expanded(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.goldColor,
                  ),
                )
              : _images.isEmpty
                  ? Center(
                      child: Text(
                        'عکسی یافت نشد',
                        style: TextStyle(
                          color: isDark
                              ? AppTheme.darkTextColor.withValues(alpha: 0.7)
                              : AppTheme.lightTextSecondary,
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadImages,
                      color: AppTheme.goldColor,
                      child: GridView.builder(
                        padding: EdgeInsets.all(16.w),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12.w,
                          mainAxisSpacing: 12.h,
                          childAspectRatio: 0.8,
                        ),
                        itemCount: _images.length,
                        itemBuilder: (context, index) {
                          final image = _images[index];
                          final imageUrl = image['url'] as String? ?? '';
                          final imageName = image['name'] as String? ?? 'عکس';
                          final imageType = image['type'] as String? ?? '';

                          return Card(
                            color: isDark ? AppTheme.darkCardColor : AppTheme.lightCardColor,
                            child: InkWell(
                              onTap: () => _showImageFullScreen(imageUrl, imageName),
                              borderRadius: BorderRadius.circular(12.r),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(12.r),
                                      ),
                                      child: CachedNetworkImage(
                                        imageUrl: imageUrl,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        placeholder: (context, url) => Container(
                                          color: AppTheme.goldColor.withValues(alpha: 0.1),
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              color: AppTheme.goldColor,
                                            ),
                                          ),
                                        ),
                                        errorWidget: (context, url, error) => Container(
                                          color: Colors.grey.withValues(alpha: 0.2),
                                          child: const Icon(
                                            LucideIcons.imageOff,
                                            size: 32,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(8.w),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          imageName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: isDark
                                                ? AppTheme.darkTextColor
                                                : AppTheme.lightTextColor,
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 4.h),
                                        Chip(
                                          label: Text(
                                            _getImageTypeLabel(imageType),
                                            style: TextStyle(
                                              color: _getImageTypeColor(imageType),
                                              fontSize: 10.sp,
                                            ),
                                          ),
                                          backgroundColor:
                                              _getImageTypeColor(imageType).withValues(alpha: 0.2),
                                          padding: EdgeInsets.zero,
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}

