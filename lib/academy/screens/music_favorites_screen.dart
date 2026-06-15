import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/academy/models/workout_music.dart';
import 'package:gymaipro/academy/services/music_favorite_service.dart';
import 'package:gymaipro/academy/services/music_player_service.dart';
import 'package:gymaipro/academy/widgets/music_player_widget.dart';
import 'package:gymaipro/academy/widgets/playlist_item_widget.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

class MusicFavoritesScreen extends StatefulWidget {
  const MusicFavoritesScreen({super.key});

  @override
  State<MusicFavoritesScreen> createState() => _MusicFavoritesScreenState();
}

class _MusicFavoritesScreenState extends State<MusicFavoritesScreen> {
  List<WorkoutMusic> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    try {
      final favorites = await MusicFavoriteService().getFavorites();
      if (mounted) {
        setState(() {
          _favorites = favorites;
          _isLoading = false;
        });
        // Set playlist in player service
        final playerService = MusicPlayerService();
        playerService.setPlaylist(favorites);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در بارگیری مورد علاقه‌ها: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: MusicPlayerService(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('موزیک‌های مورد علاقه'),
          actions: [
            if (_favorites.isNotEmpty)
              IconButton(
                icon: const Icon(LucideIcons.trash2),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('حذف همه'),
                      content: const Text(
                        'آیا می‌خواهید همه مورد علاقه‌ها را حذف کنید؟',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('لغو'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('حذف'),
                        ),
                      ],
                    ),
                  );
                  if (confirm ?? false) {
                    await MusicFavoriteService().clearFavorites();
                    _loadFavorites();
                  }
                },
              ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.goldColor),
              )
            : _favorites.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.heartOff,
                      size: 64.sp,
                      color: context.textSecondary,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'مورد علاقه‌ای وجود ندارد',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 14.sp,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  // Music Player Widget
                  const MusicPlayerWidget(),

                  // Playlist Header
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.heart,
                          size: 20.sp,
                          color: AppTheme.goldColor,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'مورد علاقه‌ها',
                          style: AppTheme.headingStyle.copyWith(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_favorites.length} موزیک',
                          style: AppTheme.bodyStyle.copyWith(
                            fontSize: 12.sp,
                            color: context.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Playlist
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      itemCount: _favorites.length,
                      itemBuilder: (context, index) {
                        return PlaylistItemWidget(
                          music: _favorites[index],
                          index: index,
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
