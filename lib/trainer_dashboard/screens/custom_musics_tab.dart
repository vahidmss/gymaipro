import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/academy/models/custom_music.dart';
import 'package:gymaipro/academy/services/custom_music_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/trainer_dashboard/screens/custom_music_editor_screen.dart';
import 'package:gymaipro/utils/widget_safety_utils.dart';
import 'package:gymaipro/widgets/gymai_network_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// تب موزیک‌های اختصاصی در داشبورد مربی — هم‌سبک با تب تمرین‌ها
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
  bool _isLoadingMusics = false;

  @override
  void initState() {
    super.initState();
    _loadMusics();
  }

  Future<void> _loadMusics() async {
    if (_isLoadingMusics) return;
    _isLoadingMusics = true;
    WidgetSafetyUtils.safeSetState(this, () => _isLoading = true);

    try {
      final musics = await _service.getTrainerMusics();
      if (mounted) {
        WidgetSafetyUtils.safeSetState(this, () {
          _musics = musics;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        WidgetSafetyUtils.safeSetState(this, () => _isLoading = false);
        WidgetSafetyUtils.safeShowSnackBar(
          context,
          'خطا در بارگذاری موزیک‌ها: $e',
          backgroundColor: AppTheme.errorColor,
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

  Future<void> _openEditor({CustomMusic? music}) async {
    final result = await Navigator.push<CustomMusic?>(
      context,
      MaterialPageRoute(
        builder: (_) => CustomMusicEditorScreen(music: music),
      ),
    );
    if (result != null) {
      _loadMusics();
    }
  }

  Color _muted(bool isDark) =>
      isDark ? Colors.grey[400]! : const Color(0xFF5A5A5A);

  Color _body(bool isDark) =>
      isDark ? AppTheme.darkTextColor : AppTheme.veryDarkBackground;

  String _durationLabel(int seconds) {
    if (seconds <= 0) return '';
    final m = seconds ~/ 60;
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          _buildHeader(isDark),
          _buildFilterBar(isDark),
          Expanded(
            child: _isLoading
                ? const Center(
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
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 4.h),
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
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: _body(isDark),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${_musics.length} موزیک',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 13.sp,
                    color: _muted(isDark),
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => _openEditor(),
            icon: Icon(LucideIcons.plus, size: 16.sp),
            label: const Text('موزیک جدید'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.goldColor,
              side: BorderSide(
                color: AppTheme.goldColor.withValues(alpha: 0.55),
              ),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(bool isDark) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 4.h),
      child: Row(
        children: [
          _buildFilterChip(isDark, 'all', 'همه'),
          SizedBox(width: 8.w),
          _buildFilterChip(isDark, 'private', 'خصوصی'),
          SizedBox(width: 8.w),
          _buildFilterChip(isDark, 'public', 'عمومی'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(bool isDark, String value, String label) {
    final selected = _filter == value;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () =>
            WidgetSafetyUtils.safeSetState(this, () => _filter = value),
        borderRadius: BorderRadius.circular(20.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.goldColor.withValues(alpha: isDark ? 0.22 : 0.16)
                : (isDark
                    ? AppTheme.veryDarkBackground.withValues(alpha: 0.35)
                    : Colors.white),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: selected
                  ? AppTheme.goldColor
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.grey.shade300),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(LucideIcons.check, size: 14.sp, color: AppTheme.goldColor),
                SizedBox(width: 4.w),
              ],
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12.5.sp,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? _body(isDark) : _muted(isDark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    final muted = _muted(isDark);
    final hasAny = _musics.isNotEmpty;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 28.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88.w,
              height: 88.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.goldColor.withValues(alpha: 0.28),
                    AppTheme.goldColor.withValues(alpha: 0.06),
                  ],
                ),
                border: Border.all(
                  color: AppTheme.goldColor.withValues(alpha: 0.35),
                ),
              ),
              child: Icon(
                LucideIcons.music,
                size: 36.sp,
                color: AppTheme.goldColor,
              ),
            ),
            SizedBox(height: 18.h),
            Text(
              hasAny
                  ? 'موزیکی با این فیلتر نیست'
                  : 'اولین موزیک اختصاصی‌ات را بساز',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 17.sp,
                fontWeight: FontWeight.bold,
                color: _body(isDark),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              hasAny
                  ? 'فیلتر را عوض کن یا موزیک جدید بساز.'
                  : 'عنوان، فایل صوتی و کاور را اضافه کن و ذخیره کن.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 13.sp,
                height: 1.45,
                color: muted,
              ),
            ),
            SizedBox(height: 20.h),
            ElevatedButton.icon(
              onPressed: () => _openEditor(),
              icon: Icon(LucideIcons.plus, size: 18.sp),
              label: const Text('ساخت موزیک جدید'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.goldColor,
                foregroundColor: AppTheme.veryDarkBackground,
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMusicsList(bool isDark) {
    return RefreshIndicator(
      onRefresh: _loadMusics,
      color: AppTheme.goldColor,
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
        itemCount: _filteredMusics.length,
        itemBuilder: (context, index) {
          return _buildMusicCard(isDark, _filteredMusics[index]);
        },
      ),
    );
  }

  Widget _buildMusicCard(bool isDark, CustomMusic music) {
    final muted = _muted(isDark);
    final duration = _durationLabel(music.duration);

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Material(
        color: isDark ? AppTheme.darkCardColor : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: InkWell(
          onTap: () => _openEditor(music: music),
          onLongPress: () => _showDeleteDialog(music),
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Row(
              children: [
                _buildThumb(isDark, music),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        music.title,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 14.5.sp,
                          fontWeight: FontWeight.bold,
                          color: _body(isDark),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        music.artist.isEmpty ? 'بدون هنرمند' : music.artist,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 12.sp,
                          color: muted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 8.h),
                      Wrap(
                        spacing: 6.w,
                        runSpacing: 6.h,
                        children: [
                          _miniChip(
                            icon: music.visibility == 'public'
                                ? LucideIcons.globe
                                : LucideIcons.lock,
                            label: music.visibility == 'public'
                                ? 'عمومی'
                                : 'خصوصی',
                            isDark: isDark,
                          ),
                          if (music.category != null &&
                              music.category!.isNotEmpty)
                            _miniChip(
                              icon: LucideIcons.folder,
                              label: music.category!,
                              isDark: isDark,
                            ),
                          if (duration.isNotEmpty)
                            _miniChip(
                              icon: LucideIcons.clock,
                              label: duration,
                              isDark: isDark,
                            ),
                          if (music.audioUrl.isNotEmpty)
                            _miniChip(
                              icon: LucideIcons.music,
                              label: 'فایل آماده',
                              isDark: isDark,
                              accent: true,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  LucideIcons.chevronLeft,
                  color: muted,
                  size: 20.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumb(bool isDark, CustomMusic music) {
    return Container(
      width: 72.w,
      height: 72.w,
      decoration: BoxDecoration(
        color: AppTheme.goldColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14.r),
      ),
      clipBehavior: Clip.antiAlias,
      child: music.coverImageUrl.isNotEmpty
          ? GymaiNetworkImage(
              imageUrl: music.coverImageUrl,
              errorWidget: Icon(
                LucideIcons.music,
                color: AppTheme.goldColor,
                size: 28.sp,
              ),
            )
          : Icon(
              LucideIcons.music,
              color: AppTheme.goldColor,
              size: 28.sp,
            ),
    );
  }

  Widget _miniChip({
    required IconData icon,
    required String label,
    required bool isDark,
    bool accent = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: accent
            ? AppTheme.goldColor.withValues(alpha: isDark ? 0.18 : 0.12)
            : (isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 11.sp,
            color: accent ? AppTheme.goldColor : _muted(isDark),
          ),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 10.5.sp,
              fontWeight: accent ? FontWeight.w700 : FontWeight.w500,
              color: accent ? AppTheme.goldColor : _muted(isDark),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteDialog(CustomMusic music) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف موزیک'),
        content: Text('آیا از حذف «${music.title}» اطمینان دارید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
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
            backgroundColor: AppTheme.successColor,
          );
          _loadMusics();
        } else {
          WidgetSafetyUtils.safeShowSnackBar(
            context,
            'خطا در حذف موزیک',
            backgroundColor: AppTheme.errorColor,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        WidgetSafetyUtils.safeShowSnackBar(
          context,
          'خطا: $e',
          backgroundColor: AppTheme.errorColor,
        );
      }
    } finally {
      WidgetSafetyUtils.safeSetState(this, () => _isLoading = false);
    }
  }
}
