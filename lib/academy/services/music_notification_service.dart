import 'dart:async';
import 'dart:io' show Platform;

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:gymaipro/academy/models/workout_music.dart';

class MusicNotificationService {
  factory MusicNotificationService() => _instance;
  MusicNotificationService._internal();
  static final MusicNotificationService _instance =
      MusicNotificationService._internal();

  AudioHandler? _audioHandler;
  _MusicAudioHandler? _handler;
  bool _isInitialized = false;
  String? _currentMediaId;

  // Callbacks
  VoidCallback? onPlayPause;
  VoidCallback? onNext;
  VoidCallback? onPrevious;
  VoidCallback? onStop;
  ValueChanged<Duration>? onSeek;

  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('✅ Audio service already initialized');
      return;
    }
    if (kIsWeb) {
      debugPrint('ℹ️ Audio foreground service skipped on web');
      _isInitialized = true;
      return;
    }
    if (!Platform.isAndroid) {
      debugPrint('⚠️ Audio service only works on Android');
      return;
    }

    try {
      debugPrint('🔄 Initializing audio service...');
      _handler = _MusicAudioHandler(
        onPlayPause: () {
          debugPrint('📱 Notification: Play/Pause pressed');
          onPlayPause?.call();
        },
        onNext: () {
          debugPrint('📱 Notification: Next pressed');
          onNext?.call();
        },
        onPrevious: () {
          debugPrint('📱 Notification: Previous pressed');
          onPrevious?.call();
        },
        onStop: () {
          debugPrint('📱 Notification: Stop pressed');
          onStop?.call();
        },
      );

      _audioHandler = await AudioService.init(
        builder: () => _handler!,
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'music_player_channel',
          androidNotificationChannelName: 'پخش موزیک',
          androidNotificationChannelDescription:
              'کنترل پخش موزیک در notification panel',
          androidNotificationOngoing:
              true, // true برای نمایش مداوم notification
        ),
      );
      _isInitialized = true;
      debugPrint('✅ Audio service initialized successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ Error initializing audio service: $e');
      debugPrint('❌ Stack trace: $stackTrace');
    }
  }

  void _updateCallbacks() {
    if (_handler != null) {
      _handler!.onPlayPause = onPlayPause;
      _handler!.onNext = onNext;
      _handler!.onPrevious = onPrevious;
      _handler!.onStop = onStop;
      _handler!.onSeek = onSeek;
    }
  }

  // Public method to update callbacks (used by MusicPlayerService)
  void updateCallbacks() {
    _updateCallbacks();
  }

  Future<void> showMediaNotification({
    required WorkoutMusic music,
    required bool isPlaying,
    required Duration position,
    required Duration duration,
  }) async {
    debugPrint('🎵 Showing media notification: ${music.title}');
    if (!_isInitialized) {
      debugPrint('🔄 Initializing audio service...');
      await initialize();
    }
    if (_audioHandler == null) {
      debugPrint('❌ Audio handler is null');
      return;
    }

    try {
      // Update callbacks before showing notification
      _updateCallbacks();

      // ساخت subtitle بهتر: خواننده + مربی (اگر وجود داشته باشد)
      String subtitle = music.artist;
      if (music.author != null &&
          music.author!.trim().isNotEmpty &&
          music.author != 'مربی ناشناس' &&
          music.author != music.artist) {
        subtitle = '${music.artist} • ${music.author!.trim()}';
      }

      final mediaItem = MediaItem(
        id: WorkoutMusic.normalizeAudioUrl(music.audioUrl),
        title: music.title,
        artist: subtitle, // نمایش خواننده + مربی در artist
        album: music.category ?? 'موزیک', // دسته‌بندی در album
        genre: music.category ?? 'موزیک',
        artUri: music.coverImageUrl.isNotEmpty
            ? Uri.parse(music.coverImageUrl)
            : null,
        duration: duration,
        extras: {
          'author': music.author ?? '',
          'category': music.category ?? '',
          'likes': music.likes.toString(),
        },
      );

      // پیاده‌سازی حرفه‌ای و بدون lag:
      // - فقط وقتی ترک عوض می‌شود mediaItem/queue را ست می‌کنیم
      // - در هر update فقط playbackState را ست می‌کنیم
      final isTrackChanged = _currentMediaId != mediaItem.id;
      if (isTrackChanged) {
        _currentMediaId = mediaItem.id;
        _handler?.setNowPlaying(mediaItem);
      }
      _handler?.setPlayback(
        isPlaying: isPlaying,
        position: position,
        duration: duration,
      );

      debugPrint('✅ Media notification shown successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ Error showing media notification: $e');
      debugPrint('❌ Stack trace: $stackTrace');
    }
  }

  Future<void> updateNotification({
    required WorkoutMusic music,
    required bool isPlaying,
    required Duration position,
    required Duration duration,
  }) async {
    if (!_isInitialized || _audioHandler == null) return;

    try {
      // ساخت subtitle بهتر: خواننده + مربی (اگر وجود داشته باشد)
      String subtitle = music.artist;
      if (music.author != null &&
          music.author!.trim().isNotEmpty &&
          music.author != 'مربی ناشناس' &&
          music.author != music.artist) {
        subtitle = '${music.artist} • ${music.author!.trim()}';
      }

      final mediaItem = MediaItem(
        id: WorkoutMusic.normalizeAudioUrl(music.audioUrl),
        title: music.title,
        artist: subtitle, // نمایش خواننده + مربی در artist
        album: music.category ?? 'موزیک', // دسته‌بندی در album
        genre: music.category ?? 'موزیک',
        artUri: music.coverImageUrl.isNotEmpty
            ? Uri.parse(music.coverImageUrl)
            : null,
        duration: duration,
        extras: {
          'author': music.author ?? '',
          'category': music.category ?? '',
          'likes': music.likes.toString(),
        },
      );

      _updateCallbacks();

      final isTrackChanged = _currentMediaId != mediaItem.id;
      if (isTrackChanged) {
        _currentMediaId = mediaItem.id;
        _handler?.setNowPlaying(mediaItem);
      }
      _handler?.setPlayback(
        isPlaying: isPlaying,
        position: position,
        duration: duration,
      );
    } catch (e) {
      debugPrint('Error updating media notification: $e');
    }
  }

  Future<void> hideNotification() async {
    if (_audioHandler != null) {
      await _audioHandler!.stop();
    }
    debugPrint('✅ Notification hidden');
  }

  void dispose() {
    _audioHandler?.stop();
  }
}

class _MusicAudioHandler extends BaseAudioHandler {

  _MusicAudioHandler({
    this.onPlayPause,
    this.onNext,
    this.onPrevious,
    this.onStop,
  });
  VoidCallback? onPlayPause;
  VoidCallback? onNext;
  VoidCallback? onPrevious;
  VoidCallback? onStop;
  ValueChanged<Duration>? onSeek;

  Duration _lastPosition = Duration.zero;
  Duration _lastDuration = Duration.zero;

  void setNowPlaying(MediaItem item) {
    // استاندارد: برای نمایش درست MediaStyle notification باید queue + mediaItem ست شوند.
    queue.add([item]);
    mediaItem.add(item);
  }

  void setPlayback({
    required bool isPlaying,
    required Duration position,
    required Duration duration,
  }) {
    _lastPosition = position;
    _lastDuration = duration;
    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          if (isPlaying) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [
          0,
          1,
          2,
        ], // نمایش 3 دکمه در compact view
        processingState: AudioProcessingState.ready,
        playing: isPlaying,
        updatePosition: position,
        updateTime: DateTime.now(),
        queueIndex: 0,
      ),
    );
  }

  @override
  Future<void> play() async {
    debugPrint('▶️ AudioHandler: play() called');
    onPlayPause?.call();
  }

  @override
  Future<void> pause() async {
    debugPrint('⏸️ AudioHandler: pause() called');
    onPlayPause?.call();
  }

  @override
  Future<void> skipToNext() async {
    debugPrint('⏭️ AudioHandler: skipToNext() called');
    onNext?.call();
  }

  @override
  Future<void> skipToPrevious() async {
    debugPrint('⏮️ AudioHandler: skipToPrevious() called');
    onPrevious?.call();
  }

  @override
  Future<void> stop() async {
    debugPrint('⏹️ AudioHandler: stop() called');
    onStop?.call();
    // بسیار مهم: اگر super.stop() را صدا نزنیم، audio_service سرویس foreground را کامل
    // متوقف نمی‌کند و ممکن است notification به حالت عمومی "App is running" باقی بماند.
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    debugPrint('⏩ AudioHandler: seek() called to $position');
    onSeek?.call(position);
  }

  @override
  Future<void> fastForward() async {
    const step = Duration(seconds: 10);
    final max = _lastDuration > Duration.zero ? _lastDuration : null;
    var next = _lastPosition + step;
    if (max != null && next > max) next = max;
    debugPrint('⏩ AudioHandler: fastForward() to $next');
    onSeek?.call(next);
  }

  @override
  Future<void> rewind() async {
    const step = Duration(seconds: 10);
    var next = _lastPosition - step;
    if (next < Duration.zero) next = Duration.zero;
    debugPrint('⏪ AudioHandler: rewind() to $next');
    onSeek?.call(next);
  }
}
