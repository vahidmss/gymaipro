import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/academy/models/custom_music.dart';
import 'package:gymaipro/academy/services/custom_music_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/trainer_dashboard/screens/custom_music_editor_screen.dart';
import 'package:gymaipro/utils/widget_safety_utils.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// تب موزیک‌های اختصاصی در داشبورد مربی
class CustomMusicsTab extends StatefulWidget {
  const CustomMusicsTab({super.key});

  @override
  State<CustomMusicsTab> createState() => _CustomMusicsTabState();
}

class _CustomMusicsTabState extends State<CustomMusicsTab> {
  final CustomMusicService _service = CustomMusicService();
  List<CustomMusic> _musics = [];
  bool _isLoading = true;
  String _filter = 'all'; // all, private, public
  bool _isLoadingMusics = false; // Prevent concurrent loads

  @override
  void initState() {
    super.initState();
    _loadMusics();
  }

  Future<void> _loadMusics() async {
    // Prevent concurrent loads
    if (_isLoadingMusics) {
      debugPrint('CustomMusicsTab: Load already in progress, skipping...');
      return;
    }

    _isLoadingMusics = true;
    WidgetSafetyUtils.safeSetState(this, () => _isLoading = true);
    
    try {
      debugPrint('CustomMusicsTab: Loading musics...');
      final musics = await _service.getTrainerMusics();
      debugPrint('CustomMusicsTab: Loaded ${musics.length} musics');
      
      if (mounted) {
        WidgetSafetyUtils.safeSetState(this, () {
          _musics = musics;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('CustomMusicsTab: Error loading musics: $e');
      debugPrint('CustomMusicsTab: Stack trace: $stackTrace');
      
      if (mounted) {
        WidgetSafetyUtils.safeSetState(this, () => _isLoading = false);
        WidgetSafetyUtils.safeShowSnackBar(
          context,
          'خطا در بارگذاری موزیک‌ها: $e',
          backgroundColor: Colors.red,
        );
      }
    } finally {
      _isLoadingMusics = false;
    }
  }

  List<CustomMusic> get _filteredMusics {
    if (_filter == 'all') return _musics;
    if (_filter == 'private') {
      return _musics.where((m) => m.visibility == 'private').toList();
    }
    return _musics.where((m) => m.visibility == 'public').toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Header با دکمه ساخت جدید
          _buildHeader(isDark),

          // فیلتر
          _buildFilterBar(isDark),

          // لیست موزیک‌ها
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: AppTheme.goldColor),
                  )
                : _filteredMusics.isEmpty
                ? _buildEmptyState(isDark)
                : _buildMusicsList(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'موزیک‌های اختصاصی',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${_musics.length} موزیک',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 14.sp,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push<CustomMusic?>(
                context,
                MaterialPageRoute(
                  builder: (_) => const CustomMusicEditorScreen(),
                ),
              );
              if (result != null) {
                _loadMusics();
              }
            },
            icon: Icon(LucideIcons.plus, size: 18.sp),
            label: const Text('موزیک جدید'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.goldColor,
              foregroundColor: Colors.black,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          _buildFilterChip(isDark, 'all', 'همه', _filter == 'all'),
          SizedBox(width: 8.w),
          _buildFilterChip(isDark, 'private', 'خصوصی', _filter == 'private'),
          SizedBox(width: 8.w),
          _buildFilterChip(isDark, 'public', 'عمومی', _filter == 'public'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    bool isDark,
    String value,
    String label,
    bool selected,
  ) {
    return FilterChip(
      selected: selected,
      label: Text(label),
      onSelected: (selected) {
        WidgetSafetyUtils.safeSetState(this, () => _filter = value);
      },
      selectedColor: AppTheme.goldColor.withValues(alpha: 0.3),
      checkmarkColor: AppTheme.goldColor,
      labelStyle: TextStyle(
        color: selected
            ? AppTheme.goldColor
            : (isDark ? Colors.grey[300] : Colors.grey[700]),
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.music,
            size: 64.sp,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          SizedBox(height: 16.h),
          Text(
            'هنوز موزیکی نساخته‌اید',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 18.sp,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'برای ساخت اولین موزیک اختصاصی روی دکمه بالا کلیک کنید',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 14.sp,
              color: isDark ? Colors.grey[500] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMusicsList(bool isDark) {
    return RefreshIndicator(
      onRefresh: _loadMusics,
      color: AppTheme.goldColor,
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: _filteredMusics.length,
        itemBuilder: (context, index) {
          final music = _filteredMusics[index];
          return _buildMusicCard(isDark, music);
        },
      ),
    );
  }

  Widget _buildMusicCard(bool isDark, CustomMusic music) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(
          color: music.visibility == 'public'
              ? AppTheme.goldColor.withValues(alpha: 0.5)
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push<CustomMusic?>(
            context,
            MaterialPageRoute(
              builder: (_) => CustomMusicEditorScreen(music: music),
            ),
          );
          if (result != null) {
            _loadMusics();
          }
        },
        onLongPress: () => _showDeleteDialog(music),
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              // تصویر کاور
              Container(
                width: 60.w,
                height: 60.w,
                decoration: BoxDecoration(
                  color: AppTheme.goldColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: music.coverImageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
                        child: Image.network(
                          music.coverImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            LucideIcons.music,
                            color: AppTheme.goldColor,
                            size: 24.sp,
                          ),
                        ),
                      )
                    : Icon(
                        LucideIcons.music,
                        color: AppTheme.goldColor,
                        size: 24.sp,
                      ),
              ),
              SizedBox(width: 12.w),

              // اطلاعات
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            music.title,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (music.visibility == 'public')
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.goldColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.globe,
                                  size: 12.sp,
                                  color: AppTheme.goldColor,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  'عمومی',
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontSize: 10.sp,
                                    color: AppTheme.goldColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      music.artist,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12.sp,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        if (music.category != null && music.category!.isNotEmpty) ...[
                          Icon(
                            LucideIcons.folder,
                            size: 12.sp,
                            color: isDark ? Colors.grey[500] : Colors.grey[500],
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            music.category!,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 11.sp,
                              color: isDark ? Colors.grey[500] : Colors.grey[500],
                            ),
                          ),
                          SizedBox(width: 12.w),
                        ],
                        if (music.duration > 0) ...[
                          Icon(
                            LucideIcons.clock,
                            size: 12.sp,
                            color: isDark ? Colors.grey[500] : Colors.grey[500],
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            '${(music.duration / 60).floor()}:${(music.duration % 60).toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 11.sp,
                              color: isDark ? Colors.grey[500] : Colors.grey[500],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // آیکون ویرایش
              Icon(
                LucideIcons.chevronLeft,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                size: 20.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteDialog(CustomMusic music) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف موزیک'),
        content: Text('آیا از حذف "${music.title}" اطمینان دارید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    WidgetSafetyUtils.safeSetState(this, () => _isLoading = true);

    try {
      final success = await _service.deleteMusic(music.id);
      if (mounted) {
        if (success) {
          WidgetSafetyUtils.safeShowSnackBar(
            context,
            'موزیک با موفقیت حذف شد',
            backgroundColor: Colors.green,
          );
          _loadMusics();
        } else {
          WidgetSafetyUtils.safeShowSnackBar(
            context,
            'خطا در حذف موزیک',
            backgroundColor: Colors.red,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        WidgetSafetyUtils.safeShowSnackBar(
          context,
          'خطا: $e',
          backgroundColor: Colors.red,
        );
      }
    } finally {
      WidgetSafetyUtils.safeSetState(this, () => _isLoading = false);
    }
  }
}

