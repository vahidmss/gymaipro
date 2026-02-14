import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/academy/models/workout_music.dart';
import 'package:gymaipro/academy/services/music_player_service.dart';
import 'package:gymaipro/academy/services/workout_music_service.dart';
import 'package:gymaipro/academy/widgets/music_player_widget.dart';
import 'package:gymaipro/academy/widgets/playlist_item_widget.dart';
import 'package:gymaipro/academy/services/music_favorite_service.dart';
import 'package:gymaipro/academy/services/music_cache_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:gymaipro/trainer_dashboard/services/trainer_client_service.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

class MusicListScreen extends StatefulWidget {
  const MusicListScreen({super.key, this.initialMusicToPlay});

  /// وقتی از کاروسل یا جاهای دیگر باز می‌شود، این موزیک را بعد از لود لیست پخش کن
  final WorkoutMusic? initialMusicToPlay;

  @override
  State<MusicListScreen> createState() => _MusicListScreenState();
}

class _MusicListScreenState extends State<MusicListScreen>
    with WidgetsBindingObserver {
  List<WorkoutMusic> _musicList = [];
  List<WorkoutMusic> _allMusics = [];
  bool _isLoading = true;
  int _selectedTab = 0;
  bool _didPlayInitial = false;
  final _cacheService = MusicCacheService();
  final ScrollController _scrollController = ScrollController();
  final _trainerClientService = TrainerClientService();
  Set<String>? _myTrainerIds; // شناسه مربی‌های کاربر

  // Avoid noisy refreshes caused by transient focus changes (e.g. notification shade).
  AppLifecycleState? _lastLifecycleState;

  // Prevent repeated refreshes from MediaQuery/Insets dependency changes.
  bool _didAutoRefreshOnce = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadMyTrainers();
    _loadMusic();
    // Initialize music player service
    final playerService = MusicPlayerService();
    playerService.init();
  }

  /// بارگذاری لیست مربی‌های کاربر
  Future<void> _loadMyTrainers() async {
    try {
      // استفاده از SimpleProfileService برای دریافت profiles.id (مثل کیف پول)
      final profile = await SimpleProfileService.getCurrentProfile();
      final userId = profile?['id'] as String?;
      if (userId != null && userId.isNotEmpty) {
        final trainerRelationships = await _trainerClientService.getClientTrainers(userId);
        
        // باید auth_user_id مربی را بگیریم چون custom_music.created_by به auth.users.id اشاره می‌کند
        _myTrainerIds = <String>{};
        for (final rel in trainerRelationships) {
          final status = rel['status'] as String?;
          if (status == null || status == 'active') {
            final trainerProfile = rel['trainer'] as Map<String, dynamic>?;
            if (trainerProfile != null) {
              // اولویت: auth_user_id (برای custom_music که به auth.users.id اشاره می‌کند)
              final authUserId = trainerProfile['auth_user_id'] as String?;
              if (authUserId != null && authUserId.isNotEmpty) {
                _myTrainerIds!.add(authUserId);
              } else {
                // Fallback: اگر auth_user_id ندارند، از profiles.id استفاده می‌کنیم
                // (در legacy schema که profiles.id == auth.users.id)
                final profileId = trainerProfile['id'] as String?;
                if (profileId != null && profileId.isNotEmpty) {
                  _myTrainerIds!.add(profileId);
                }
              }
            }
          }
        }
      } else {
        _myTrainerIds = null;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading trainers: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      _myTrainerIds = null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // IMPORTANT:
      // Pulling down the Android notification shade can cause focus changes and
      // repeated "resumed" signals in some setups. Only refresh if we truly
      // come back from background (paused/detached).
      final shouldRefresh =
          _lastLifecycleState == AppLifecycleState.paused ||
          _lastLifecycleState == AppLifecycleState.detached;

      if (shouldRefresh && mounted && !_isLoading) {
        _loadMusic(refresh: true);
      }
    }

    _lastLifecycleState = state;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This can be triggered by insets/mediaQuery changes (including notification shade).
    // We only want a single "visibility refresh" for musics.
    if (_didAutoRefreshOnce) return;

    final shouldRefresh = _allMusics.isEmpty;
    if (!shouldRefresh) {
      _didAutoRefreshOnce = true;
      return;
    }

    _didAutoRefreshOnce = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isLoading) return;
      _loadMusic(refresh: true);
    });
  }

  Future<void> _updateFilteredList() async {
    switch (_selectedTab) {
      case 0: // همه
        setState(() {
          // مرتب کردن بر اساس تعداد لایک‌ها (بیشترین به کمترین)
          _musicList = List.from(_allMusics)
            ..sort((a, b) => (b.likes).compareTo(a.likes));
        });
        // Set playlist to filtered list
        final playerService = MusicPlayerService();
        playerService.setPlaylist(_musicList);
        break;
      case 1: // مورد علاقه
        await _loadFavorites();
        break;
      case 2: // مربی - فقط موزیک‌های مربی‌هایی که کاربر شاگرد آن‌هاست
        await _loadTrainerMusics();
        break;
      case 3: // دانلود شده
        await _loadDownloaded();
        break;
    }
  }

  Future<void> _loadDownloaded() async {
    try {
      // Get only explicitly downloaded musics (not auto-cached)
      final downloadedUrls = await _cacheService.getDownloadedUrls(_allMusics);
      final downloadedUrlSet = downloadedUrls.toSet();
      _musicList = _allMusics.where((m) {
        final normalizedUrl = WorkoutMusic.normalizeAudioUrl(m.audioUrl);
        return downloadedUrlSet.contains(normalizedUrl);
      }).toList();
      setState(() {});
      // Set playlist to filtered list
      final playerService = MusicPlayerService();
      playerService.setPlaylist(_musicList);
    } catch (e) {
      debugPrint('Error loading downloaded musics: $e');
      _musicList = [];
      setState(() {});
      // Set playlist to filtered list (empty)
      final playerService = MusicPlayerService();
      playerService.setPlaylist(_musicList);
    }
  }

  Future<void> _loadFavorites() async {
    try {
      final favorites = await MusicFavoriteService().getFavorites();
      // Match favorites with current music list by ID
      final favoriteIds = favorites.map((f) => f.id).toSet();
      _musicList = _allMusics.where((m) => favoriteIds.contains(m.id)).toList();
      setState(() {});
      // Set playlist to filtered list
      final playerService = MusicPlayerService();
      playerService.setPlaylist(_musicList);
    } catch (e) {
      debugPrint('Error loading favorites: $e');
      _musicList = [];
      setState(() {});
      // Set playlist to filtered list (empty)
      final playerService = MusicPlayerService();
      playerService.setPlaylist(_musicList);
    }
  }

  /// بارگذاری موزیک‌های مربی‌هایی که کاربر شاگرد آن‌هاست
  Future<void> _loadTrainerMusics() async {
    try {
      // اگر لیست مربی‌ها لود نشده، ابتدا لود می‌کنیم
      if (_myTrainerIds == null) {
        await _loadMyTrainers();
      }

      setState(() {
        if (_myTrainerIds != null && _myTrainerIds!.isNotEmpty) {
          // فقط موزیک‌هایی که created_by آن‌ها در لیست مربی‌های کاربر است
          _musicList = _allMusics
              .where((m) => 
                  m.createdBy != null && 
                  _myTrainerIds!.contains(m.createdBy))
              .toList();
        } else {
          _musicList = [];
        }
      });
      
      // Set playlist to filtered list
      final playerService = MusicPlayerService();
      playerService.setPlaylist(_musicList);
    } catch (e) {
      debugPrint('Error loading trainer musics: $e');
      _musicList = [];
      setState(() {});
      final playerService = MusicPlayerService();
      playerService.setPlaylist(_musicList);
    }
  }

  Future<void> _loadMusic({bool refresh = false}) async {
    setState(() => _isLoading = true);
    try {
      // اگر refresh است، لیست مربی‌ها را هم دوباره لود می‌کنیم
      if (refresh) {
        await _loadMyTrainers();
      }
      
      final music = await WorkoutMusicService.fetchMusic(forceRefresh: refresh);
      if (mounted) {
        setState(() {
          _allMusics = music;
          _isLoading = false;
        });
        await _updateFilteredList();
        // اگر از کاروسل با موزیک خاصی باز شده، فقط بار اول بعد از لود پخش کن
        if (!_didPlayInitial &&
            widget.initialMusicToPlay != null &&
            mounted) {
          _didPlayInitial = true;
          final initial = widget.initialMusicToPlay!;
          final idx = _musicList.indexWhere(
            (m) =>
                WorkoutMusic.normalizeAudioUrl(m.audioUrl) ==
                    WorkoutMusic.normalizeAudioUrl(initial.audioUrl) ||
                m.id == initial.id,
          );
          if (idx >= 0) {
            final player = MusicPlayerService();
            await player.playMusic(initial, index: idx);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطا در بارگیری موزیک: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: MusicPlayerService(),
      child: Container(
        color: context.backgroundColor,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.goldColor),
              )
            : RefreshIndicator(
                onRefresh: () => _loadMusic(refresh: true),
                color: AppTheme.goldColor,
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    // Main Player Widget
                    SliverToBoxAdapter(
                      child: const MusicPlayerWidget(compact: true),
                    ),

                    // Minimal Tab Bar
                    SliverToBoxAdapter(child: _buildMinimalTabBar(context)),

                    // Playlist
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      sliver: _musicList.isEmpty
                          ? SliverToBoxAdapter(child: _buildEmptyState(context))
                          : SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                // Use index from filtered list (not all musics)
                                final music = _musicList[index];
                                return PlaylistItemWidget(
                                  key: ValueKey(
                                    '${music.id}_${music.audioUrl}_${_selectedTab}',
                                  ),
                                  music: music,
                                  index: index, // Use index from filtered list
                                );
                              }, childCount: _musicList.length),
                            ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildMinimalTabBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.grey[900]?.withValues(alpha: 0.5)
                : Colors.grey[200]?.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: constraints.maxWidth - 32.w,
              ),
              child: IntrinsicWidth(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTabChip(
                      context: context,
                      label: 'همه',
                      index: 0,
                      icon: LucideIcons.music,
                    ),
                    SizedBox(width: 4.w),
                    _buildTabChip(
                      context: context,
                      label: 'مورد علاقه',
                      index: 1,
                      icon: LucideIcons.bookmark,
                    ),
                    SizedBox(width: 4.w),
                    _buildTabChip(
                      context: context,
                      label: 'مربی',
                      index: 2,
                      icon: LucideIcons.user,
                    ),
                    SizedBox(width: 4.w),
                    _buildTabChip(
                      context: context,
                      label: 'دانلود شده',
                      index: 3,
                      icon: LucideIcons.download,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabChip({
    required BuildContext context,
    required String label,
    required int index,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedTab == index;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedTab = index;
            });
            _updateFilteredList();
          },
          borderRadius: BorderRadius.circular(8.r),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(vertical: 7.h, horizontal: 8.w),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.goldColor : Colors.transparent,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 13.sp,
                  color: isSelected
                      ? Colors.black
                      : (isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
                SizedBox(width: 4.w),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 11.sp,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? Colors.black
                          : (isDark ? Colors.grey[400] : Colors.grey[600]),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String message;
    IconData icon;

    switch (_selectedTab) {
      case 1:
        message = 'مورد علاقه‌ای وجود ندارد';
        icon = LucideIcons.heart;
        break;
      case 2:
        message = 'موزیک مربی یافت نشد';
        icon = LucideIcons.user;
        break;
      case 3:
        message = 'موزیک دانلود شده‌ای وجود ندارد';
        icon = LucideIcons.download;
        break;
      default:
        message = 'موزیکی یافت نشد';
        icon = LucideIcons.music;
    }

    return Container(
      padding: EdgeInsets.symmetric(vertical: 48.h),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 48.sp,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          SizedBox(height: 16.h),
          Text(
            message,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 14.sp,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
