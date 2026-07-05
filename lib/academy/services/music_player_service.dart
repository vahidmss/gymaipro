import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:gymaipro/academy/models/workout_music.dart';
import 'package:gymaipro/academy/services/music_cache_service.dart';
import 'package:gymaipro/academy/services/music_media_url_service.dart';
import 'package:gymaipro/academy/services/music_notification_service.dart';
import 'package:gymaipro/academy/services/web_music_platform.dart';
import 'package:http/http.dart' as http;

enum MusicRepeatMode { none, one, all }

class MusicPlayerService extends ChangeNotifier {
  factory MusicPlayerService() => _instance;
  MusicPlayerService._internal();
  static final MusicPlayerService _instance = MusicPlayerService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer(
    playerId: 'gymaipro_music_player',
  );
  final MusicCacheService _cacheService = MusicCacheService();
  final MusicNotificationService _notificationService =
      MusicNotificationService();
  List<WorkoutMusic> _playlist = [];
  int _currentIndex = -1;
  WorkoutMusic? _currentMusic; // نگه‌داری موزیک فعلی حتی اگر در playlist نباشد
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isShuffled = false;
  MusicRepeatMode _repeatMode = MusicRepeatMode.none;
  List<int> _shuffledIndices = [];
  bool _isInitialized = false;
  bool _isInitializing = false;

  // Lock mechanism to prevent concurrent operations
  bool _isOperationInProgress = false;
  Completer<void>? _operationCompleter;
  String?
  _currentPlayingUrl; // Track what's currently playing to avoid duplicates
  bool _isCancelled = false; // Flag to track if operation was cancelled

  // Debounce timer for notification updates
  Timer? _notificationUpdateTimer;
  static const Duration _notificationUpdateInterval = Duration(seconds: 2);

  // Track if notification was shown for current track
  String? _lastNotificationUrl;

  // Flag to prevent recursive stop() calls
  bool _isStopping = false;
  bool _isCachingCurrentTrack = false;

  // Flag to prevent listener from interfering with toggle operations
  bool _isToggling = false;

  // Debounce mechanism for play requests (only for streaming, not local files)
  DateTime? _lastPlayRequest;
  String? _lastPlayRequestUrl;
  static const Duration _playRequestDebounce = Duration(milliseconds: 150);

  // Getters
  WorkoutMusic? get currentMusic => _currentMusic;

  List<WorkoutMusic> get playlist => _playlist;
  int get currentIndex => _currentIndex;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  Duration get duration => _duration;
  Duration get position => _position;
  bool get isShuffled => _isShuffled;
  MusicRepeatMode get repeatMode => _repeatMode;

  bool get hasNext => _getNextIndex() != null;
  bool get hasPrevious => _getPreviousIndex() != null;

  /// Whether [music] is the track currently loaded in the player (by id or URL).
  bool isCurrentTrack(WorkoutMusic music) {
    final current = _currentMusic;
    if (current == null) return false;
    final targetUrl = WorkoutMusic.normalizeAudioUrl(music.audioUrl);
    final currentUrl = WorkoutMusic.normalizeAudioUrl(current.audioUrl);
    return current.id == music.id || currentUrl == targetUrl;
  }

  /// Stop playback when the app process is being torn down (swipe from recents).
  Future<void> handleAppDetached() async {
    if (!_isPlaying && _currentMusic == null) return;
    debugPrint('⏹️ App detached — stopping music playback');
    await stop(clearSelection: true);
  }

  // Helper method to safely handle PlatformException and other errors
  void _handleError(Object error, String context) {
    if (error is PlatformException) {
      debugPrint(
        '⚠️ PlatformException in $context: ${error.code} - ${error.message}',
      );
    } else {
      debugPrint('⚠️ Error in $context: $error');
    }
  }

  Future<bool> _localFileExists(String? path) async {
    if (path == null || path.isEmpty) return false;
    if (kIsWeb) return path.startsWith('blob:');
    return File(path).exists();
  }

  bool _isWebBlobPath(String? path) =>
      kIsWeb && path != null && path.startsWith('blob:');

  UrlSource _streamingSource(String normalizedUrl) => UrlSource(
        MusicMediaUrlService.playbackUrl(normalizedUrl),
        mimeType: 'audio/mpeg',
      );

  Source _localSource(String path) {
    if (_isWebBlobPath(path)) {
      return UrlSource(path, mimeType: 'audio/mpeg');
    }
    return DeviceFileSource(path);
  }

  Source _playbackSource({
    required String normalizedUrl,
    required bool useLocalFile,
    String? sourcePath,
  }) {
    if (useLocalFile && sourcePath != null) {
      return _localSource(sourcePath);
    }
    return _streamingSource(normalizedUrl);
  }

  /// When HTML audio cannot stream cross-origin, fetch via Supabase proxy and play blob.
  Future<bool> _tryWebProxyBlobPlayback(String normalizedUrl) async {
    if (!kIsWeb) return false;
    try {
      debugPrint('🌐 Web fallback: loading via music-proxy blob...');
      final response = await http
          .get(
            MusicMediaUrlService.fetchUri(normalizedUrl),
            headers: MusicMediaUrlService.fetchHeaders(),
          )
          .timeout(const Duration(minutes: 3));

      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        debugPrint(
          'Web proxy fetch failed: HTTP ${response.statusCode}',
        );
        return false;
      }

      final blobUrl = WebMusicPlatform.storeBlob(
        MusicCacheService.storageKey(normalizedUrl),
        response.bodyBytes,
      );
      await _audioPlayer
          .setSource(UrlSource(blobUrl, mimeType: 'audio/mpeg'))
          .timeout(const Duration(seconds: 30));
      debugPrint('✅ Web blob playback ready');
      return true;
    } catch (e) {
      _handleError(e, 'web proxy blob playback');
      return false;
    }
  }

  // Cleanup method called when operation is cancelled
  void _cleanupAfterCancellation() {
    _isLoading = false;
    _isPlaying = false;
    // Don't clear _currentMusic or _currentIndex - keep selection for retry
    notifyListeners();
  }

  Future<void> init() async {
    if (_isInitialized) {
      return;
    }
    if (_isInitializing) {
      // Wait for ongoing initialization
      while (_isInitializing) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      return;
    }

    _isInitializing = true;
    try {
      if (!kIsWeb) {
        // Setup notification callbacks (Android foreground service only)
        _notificationService.onPlayPause = () {
          togglePlayPause().catchError((Object e) {
            debugPrint('❌ Error in notification play/pause: $e');
          });
        };
        _notificationService.onNext = () {
          next().catchError((Object e) {
            debugPrint('❌ Error in notification next: $e');
          });
        };
        _notificationService.onPrevious = () {
          previous().catchError((Object e) {
            debugPrint('❌ Error in notification previous: $e');
          });
        };
        _notificationService.onStop = () {
          close().catchError((Object e) {
            debugPrint('❌ Error in notification stop: $e');
          });
        };
        _notificationService.onSeek = (position) {
          seek(position).catchError((Object e) {
            debugPrint('❌ Error in notification seek: $e');
          });
        };

        await _notificationService.initialize();
      }
      await _audioPlayer.setPlayerMode(PlayerMode.mediaPlayer);
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);

      // Setup listeners
      _audioPlayer.onPlayerStateChanged.listen((state) {
        // Don't update state if we're in the middle of a toggle operation
        if (_isToggling) {
          return;
        }

        final wasPlaying = _isPlaying;
        _isPlaying = state == PlayerState.playing;
        if (wasPlaying != _isPlaying) {
          // Play/Pause icon must update immediately in the notification.
          _notificationUpdateTimer?.cancel();
          _updateNotificationNow();
          notifyListeners();
        }
      });

      _audioPlayer.onDurationChanged.listen((duration) {
        if (duration != _duration) {
          _duration = duration;
          _debouncedNotificationUpdate();
          notifyListeners();
        }
      });

      _audioPlayer.onPositionChanged.listen((position) {
        _position = position;
        notifyListeners();
        if (position.inSeconds % 3 == 0) {
          _debouncedNotificationUpdate();
        }
      });

      _audioPlayer.onPlayerComplete.listen((_) {
        _onTrackComplete();
      });

      _isInitialized = true;
      debugPrint('✅ MusicPlayerService initialized');
    } catch (e, stackTrace) {
      debugPrint('❌ Error initializing MusicPlayerService: $e');
      debugPrint('❌ Stack trace: $stackTrace');
    } finally {
      _isInitializing = false;
    }
  }

  void _debouncedNotificationUpdate() {
    _notificationUpdateTimer?.cancel();
    _notificationUpdateTimer = Timer(_notificationUpdateInterval, _updateNotification);
  }

  void _updateNotification() {
    if (kIsWeb) return;
    final music = currentMusic;
    if (music != null &&
        _lastNotificationUrl ==
            WorkoutMusic.normalizeAudioUrl(music.audioUrl)) {
      // Only update if notification was already shown for this track
      _notificationService.updateNotification(
        music: music,
        isPlaying: _isPlaying,
        position: _position,
        duration: _duration,
      );
    }
  }

  void _updateNotificationNow() {
    if (kIsWeb) return;
    final music = currentMusic;
    if (music == null) return;
    if (_lastNotificationUrl != WorkoutMusic.normalizeAudioUrl(music.audioUrl)) {
      return;
    }
    _notificationService.updateNotification(
      music: music,
      isPlaying: _isPlaying,
      position: _position,
      duration: _duration,
    );
  }

  void setPlaylist(List<WorkoutMusic> musicList) {
    final currentUrl = _currentPlayingUrl;
    final currentId = _currentMusic?.id;

    _playlist = List.from(musicList);
    if (_isShuffled) {
      _generateShuffledIndices();
    } else {
      _shuffledIndices.clear();
    }

    if (currentUrl != null || currentId != null) {
      int? foundIndex;
      for (int i = 0; i < _playlist.length; i++) {
        final music = _playlist[i];
        final norm = WorkoutMusic.normalizeAudioUrl(music.audioUrl);
        if (currentUrl != null && norm == currentUrl) {
          foundIndex = i;
          break;
        } else if (currentId != null && music.id == currentId) {
          foundIndex = i;
          break;
        }
      }

      if (foundIndex != null) {
        _currentIndex = foundIndex;
        _currentMusic = _playlist[foundIndex];
      } else {
        // Keep playing the current track but do NOT inject it into tab lists.
        _currentIndex = -1;
      }
    } else if (_currentIndex >= _playlist.length) {
      _currentIndex = -1;
      if (!_isPlaying) {
        _currentMusic = null;
      }
    }

    notifyListeners();
  }

  Future<void> _waitForOperation() async {
    if (_isOperationInProgress && _operationCompleter != null) {
      final waitingCompleter = _operationCompleter!;
      try {
        // IMPORTANT:
        // Some devices take >5s to prepare local files (even if already downloaded).
        // Never "unlock" by force without stopping, otherwise we create overlapping
        // operations that fight each other and break playback.
        await waitingCompleter.future.timeout(const Duration(seconds: 60));
      } on TimeoutException catch (_) {
        debugPrint('⚠️ Operation wait timeout (60s). Forcing stop/unlock...');
        // Force-cancel the stuck operation safely.
        _isCancelled = true;
        try {
          await _audioPlayer.stop().timeout(const Duration(seconds: 2));
        } catch (_) {
          // Ignore stop errors
        }
        // Complete the previous completer if it's still pending.
        if (!waitingCompleter.isCompleted) {
          waitingCompleter.complete();
        }
        if (identical(_operationCompleter, waitingCompleter)) {
          _operationCompleter = null;
        }
        _isOperationInProgress = false;
        _isLoading = false;
        // Do NOT clear selection here; user should still be able to retry.
        notifyListeners();
      } catch (e) {
        // On any unexpected error, unlock safely but keep selection.
        debugPrint('⚠️ Error while waiting for operation: $e');
        if (!waitingCompleter.isCompleted) {
          waitingCompleter.complete();
        }
        if (identical(_operationCompleter, waitingCompleter)) {
          _operationCompleter = null;
        }
        _isOperationInProgress = false;
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> playMusic(WorkoutMusic music, {int? index}) async {
    final normalizedUrl = WorkoutMusic.normalizeAudioUrl(music.audioUrl);
    
    // Check if we have local file - skip debounce for local files (instant playback)
    final localPath = await _cacheService.getBestLocalPathForPlayback(normalizedUrl);
    final hasLocalFile = localPath != null;
    
    // Debounce only for streaming (not local files) to prevent rapid requests
    if (!hasLocalFile) {
      final now = DateTime.now();
      if (_lastPlayRequest != null &&
          _lastPlayRequestUrl == normalizedUrl &&
          now.difference(_lastPlayRequest!) < _playRequestDebounce) {
        debugPrint('⏭️ Skipping duplicate play request (debounced)');
        return;
      }
      _lastPlayRequest = now;
      _lastPlayRequestUrl = normalizedUrl;
    }
    
    // Resolve index robustly:
    // - UI may pass an index from a filtered list
    // - We might have injected the current track at playlist[0]
    // So we must not trust the provided index blindly.
    int targetIndex = -1;
    if (index != null &&
        index >= 0 &&
        index < _playlist.length &&
        WorkoutMusic.normalizeAudioUrl(_playlist[index].audioUrl) ==
            normalizedUrl) {
      targetIndex = index;
    } else {
      targetIndex = _playlist.indexWhere(
        (m) =>
            WorkoutMusic.normalizeAudioUrl(m.audioUrl) == normalizedUrl ||
            m.id == music.id,
      );
    }
    if (targetIndex < 0) {
      // Play without polluting the tab-filtered playlist shown in the UI.
      targetIndex = -1;
    }

    // Cancel any ongoing operation if user wants to play different music
    if (_isOperationInProgress && _operationCompleter != null) {
      final currentUrl = _currentPlayingUrl;
      if (currentUrl != null && currentUrl != normalizedUrl) {
        // User wants to play different music, cancel previous operation
        debugPrint('🔄 Cancelling previous operation to play: ${music.title}');
        _isCancelled = true;
        
        // Stop and reset player properly before cancelling
        try {
          await _audioPlayer.stop().timeout(const Duration(seconds: 2));
        } catch (_) {
          // Ignore stop errors
        }
        
        // Note: We don't dispose the AudioPlayer here as it's a singleton
        // Just ensure it's stopped and state is reset
        
        // Complete previous completer
        if (!_operationCompleter!.isCompleted) {
          _operationCompleter!.complete();
        }
        _operationCompleter = null;
        _isOperationInProgress = false;
        
        // Minimal delay only if needed (local files don't need this)
        await Future<void>.delayed(const Duration(milliseconds: 50));
        
        // Reinitialize if needed
        if (!_isInitialized) {
          try {
            await init();
          } catch (e) {
            debugPrint('⚠️ Failed to reinitialize after cancel: $e');
          }
        }
      } else {
        // Same music, wait for operation
        await _waitForOperation();
      }
    } else {
      await _waitForOperation();
    }

    // Reset cancellation flag at the start of new operation
    _isCancelled = false;

      // Check if the same track is already playing, do nothing (UI should call togglePlayPause)
    if (_currentPlayingUrl == normalizedUrl &&
        isCurrentTrack(music) &&
        _isPlaying &&
        !_isLoading) {
      debugPrint('ℹ️ Already playing (no reload): ${music.title}');
      return;
    }

    // Ensure service is initialized
    if (!_isInitialized) {
      try {
        await init();
      } catch (e) {
        debugPrint('❌ Failed to initialize player: $e');
        return;
      }
    }

    // Validate input
    if (normalizedUrl.isEmpty) {
      debugPrint('❌ Empty audio URL for music: ${music.title}');
      return;
    }

    if (!_isValidUrl(normalizedUrl)) {
      debugPrint('❌ Invalid URL: $normalizedUrl');
      return;
    }

    // Reset cancellation flag at the start of new operation (after waiting for previous)
    _isCancelled = false;

    // Set operation lock
    _isOperationInProgress = true;
    final opCompleter = Completer<void>();
    _operationCompleter = opCompleter;

    _currentIndex = targetIndex;
    // Keep selection immediately (even if loading takes time), so UI + notification
    // never end up with "no music selected" during a slow prepare.
    _currentMusic = music;
    _isLoading = true;
    _duration = Duration.zero;
    _position = Duration.zero;
    notifyListeners();

    try {
      // Check if cancelled before starting
      if (_isCancelled) {
        debugPrint('⚠️ Operation cancelled before starting');
        _cleanupAfterCancellation();
        return;
      }

      // Check if we have local file for faster processing
      String? localPath;
      try {
        localPath = await _cacheService.getBestLocalPathForPlayback(normalizedUrl);
      } catch (e) {
        debugPrint('⚠️ Error getting local path: $e');
      }
      final hasLocalFile = await _localFileExists(localPath);
      
      // Stop current playback - faster for local files
      try {
        // For local files, just stop immediately without pause
        if (hasLocalFile) {
          await _audioPlayer.stop().timeout(
            const Duration(milliseconds: 100),
            onTimeout: () {
              debugPrint('⚠️ Stop timeout, continuing');
            },
          );
        } else {
          // For streaming, pause first then stop
          try {
            await _audioPlayer.pause().timeout(const Duration(milliseconds: 100));
          } catch (_) {
            // Ignore pause errors
          }
          
          await _audioPlayer.stop().timeout(
            const Duration(seconds: 1),
            onTimeout: () {
              debugPrint('⚠️ Stop timeout, continuing');
            },
          );
        }
      } catch (e) {
        _handleError(e, 'stopping player');
      }

      // Check if cancelled after stop
      if (_isCancelled) {
        debugPrint('⚠️ Operation cancelled after stop');
        _cleanupAfterCancellation();
        return;
      }

      // Minimal delay only for streaming (local files don't need this)
      if (!hasLocalFile) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }

      // Check if cancelled before loading
      if (_isCancelled) {
        debugPrint('⚠️ Operation cancelled before loading');
        _cleanupAfterCancellation();
        return;
      }

      // Use the localPath we already checked (or get it if not checked)
      if (localPath == null) {
        try {
          localPath = await _cacheService.getBestLocalPathForPlayback(normalizedUrl);
        } catch (e) {
          debugPrint('⚠️ Error getting local path: $e');
        }
      }

      bool useLocalFile = false;
      String? sourcePath;
      final useWebBlob = _isWebBlobPath(localPath);

      if (useWebBlob) {
        sourcePath = localPath;
        useLocalFile = true;
        debugPrint('✅ Using web blob: ${music.title}');
      } else if (localPath != null && !kIsWeb) {
        try {
          final file = File(localPath);
          if (await file.exists()) {
            final fileSize = await file.length();
            if (fileSize > 0) {
              sourcePath = localPath;
              useLocalFile = true;
              debugPrint('✅ Using local file: ${music.title}');
            }
          }
        } catch (e) {
          debugPrint('⚠️ Error checking local file: $e');
        }
      }

      // Load source - prioritize cached/downloaded files, then stream
      bool sourceLoaded = false;
      
      // First priority: use cached or downloaded file if available
      //
      // NOTE:
      // روی بعضی دستگاه‌ها/فایل‌های بزرگ، آماده‌سازی فایل لوکال ممکنه چندین ثانیه طول بکشه.
      // اگر زود timeout کنیم و retry/reset بزنیم، عملاً جلوی پخش رو می‌گیریم.
      if (useLocalFile && sourcePath != null) {
        if (!useWebBlob) {
          // Validate file before attempting to load
          try {
            final file = File(sourcePath);
            if (!await file.exists()) {
              debugPrint('⚠️ File does not exist: $sourcePath');
              useLocalFile = false;
            } else {
              final fileSize = await file.length();
              if (fileSize == 0) {
                debugPrint('⚠️ File is empty: $sourcePath');
                useLocalFile = false;
              } else {
                try {
                  final randomAccessFile = await file.open();
                  await randomAccessFile.setPosition(0);
                  await randomAccessFile.read(1024);
                  await randomAccessFile.close();
                  debugPrint('✅ File validated: $sourcePath ($fileSize bytes)');
                } catch (e) {
                  debugPrint('⚠️ File is not readable: $sourcePath - $e');
                  useLocalFile = false;
                }
              }
            }
          } catch (e) {
            debugPrint('⚠️ Error validating file: $sourcePath - $e');
            useLocalFile = false;
          }
        }

        if (useLocalFile) {
          final localPlaybackSource = _localSource(sourcePath);
          if (useWebBlob) {
            try {
              await _audioPlayer
                  .setSource(localPlaybackSource)
                  .timeout(const Duration(seconds: 30));
              sourceLoaded = true;
              debugPrint('✅ Web blob source set successfully');
            } catch (e) {
              _handleError(e, 'loading web blob');
            }
          } else {
            const int fileRetries = 2;
            for (int retry = 0; retry < fileRetries && !sourceLoaded; retry++) {
              try {
                if (retry > 0) {
                  debugPrint('🔄 Retrying file load: $retry/$fileRetries');
                  await Future<void>.delayed(const Duration(milliseconds: 50));
                }

                await _audioPlayer
                    .setSource(localPlaybackSource)
                    .timeout(
                      const Duration(seconds: 45),
                      onTimeout: () {
                        throw TimeoutException('File load timeout');
                      },
                    );

                sourceLoaded = true;
                debugPrint('✅ File source set successfully');
                break;
              } catch (e) {
                _handleError(e, 'loading file (attempt ${retry + 1})');
              }
            }

            if (!sourceLoaded) {
              try {
                final file = File(sourcePath);
                if (await file.exists() && await file.length() > 0) {
                  debugPrint('🔁 Trying direct play from local file: $sourcePath');
                  await _audioPlayer
                      .play(localPlaybackSource)
                      .timeout(const Duration(seconds: 10));
                  sourceLoaded = true;
                  debugPrint('✅ Direct local play started');
                }
              } catch (e) {
                _handleError(e, 'direct local play fallback');
              }
            }
          }
        }
      }

      // Second priority: stream from URL (no download before play)
      if (!sourceLoaded) {
        final streamUrl = MusicMediaUrlService.playbackUrl(normalizedUrl);
        debugPrint('🌐 Streaming from URL: ${music.title} ($streamUrl)');
        const int maxRetries = 2;
        for (int retry = 0; retry <= maxRetries && !sourceLoaded; retry++) {
          try {
            if (retry > 0) {
              debugPrint('🔄 Retry streaming: $retry/$maxRetries');
              await Future<void>.delayed(Duration(milliseconds: 500 * retry));
            }

            await _audioPlayer
                .setSource(_streamingSource(normalizedUrl))
                .timeout(
                  const Duration(seconds: 30),
                  onTimeout: () {
                    throw TimeoutException('URL load timeout');
                  },
                );

            sourceLoaded = true;
            debugPrint('✅ Streaming started successfully');

            // Cache in background for next time (after playback completes)
            // This will be triggered when music finishes playing
          } catch (e) {
            _handleError(e, 'streaming URL (attempt ${retry + 1})');
            if (retry == maxRetries && localPath != null && useLocalFile && !useWebBlob) {
              // Last resort: try local file one more time with longer timeout
              try {
                final file = File(localPath);
                if (await file.exists() && await file.length() > 0) {
                  // Stop player first
                  try {
                    await _audioPlayer.stop().timeout(const Duration(seconds: 1));
                    await Future<void>.delayed(const Duration(milliseconds: 150));
                  } catch (_) {
                    // Ignore stop errors
                  }

                  await _audioPlayer
                      .setSource(_localSource(localPath))
                      .timeout(const Duration(seconds: 10));
                  sourceLoaded = true;
                  debugPrint('✅ Fallback to local file successful');
                }
              } catch (e2) {
                _handleError(e2, 'local file fallback');
              }
            }
          }
        }

        if (!sourceLoaded && kIsWeb) {
          sourceLoaded = await _tryWebProxyBlobPlayback(normalizedUrl);
        }
      }

      if (!sourceLoaded) {
        // Don't throw, just log and return gracefully
        debugPrint('❌ All loading methods failed for: ${music.title}');
        _isLoading = false;
        _isPlaying = false;
        notifyListeners();
        return;
      }

      // Wait for duration to be available - faster for local files
      int durationWaitAttempts = 0;
      final maxAttempts = useLocalFile ? 5 : 20; // Local files should be faster
      final delayMs = useLocalFile ? 20 : 100; // Shorter delay for local files
      while (_duration == Duration.zero && durationWaitAttempts < maxAttempts) {
        await Future<void>.delayed(Duration(milliseconds: delayMs));
        durationWaitAttempts++;
      }

      // Seek to start - skip for local files (they start at 0 automatically)
      if (!useLocalFile) {
        try {
          await _audioPlayer
              .seek(Duration.zero)
              .timeout(
                const Duration(seconds: 2),
                onTimeout: () {
                  debugPrint('⚠️ Seek timeout');
                },
              );
        } catch (e) {
          _handleError(e, 'seeking to start');
        }
      }

      // Start playback - optimized for local files
      bool playbackStarted = false;
      try {
        // For local files, use play() directly (faster)
        if (useLocalFile && sourcePath != null) {
          try {
            final source = _localSource(sourcePath);
            await _audioPlayer
                .play(source)
                .timeout(
                  const Duration(seconds: 3), // Shorter timeout for local files
                  onTimeout: () {
                    throw TimeoutException('Play timeout');
                  },
                );

            // For local files, verify playback started immediately
            // Check state right away without delay
            if (_audioPlayer.state == PlayerState.playing) {
              playbackStarted = true;
              _isPlaying = true;
              _isLoading = false; // Set loading false immediately
              notifyListeners(); // Update UI instantly
              debugPrint('✅ Playback started instantly (local file)');
            } else {
              // Small delay only if not playing yet
              await Future<void>.delayed(const Duration(milliseconds: 50));
              if (_isPlaying || _audioPlayer.state == PlayerState.playing) {
                playbackStarted = true;
                _isPlaying = true;
                _isLoading = false;
                notifyListeners();
                debugPrint('✅ Playback started (local file)');
              }
            }
          } catch (playError) {
            _handleError(playError, 'play() method (local)');
          }
        }
        
        // If local play didn't work or it's streaming, try resume first
        if (!playbackStarted) {
          try {
            await _audioPlayer.resume().timeout(
              const Duration(seconds: 5),
              onTimeout: () {
                throw TimeoutException('Resume timeout');
              },
            );

            // Shorter delay for streaming
            await Future<void>.delayed(const Duration(milliseconds: 200));
            if (_isPlaying || _audioPlayer.state == PlayerState.playing) {
              playbackStarted = true;
              _isPlaying = true;
              debugPrint('✅ Playback started with resume');
            }
          } catch (resumeError) {
            _handleError(resumeError, 'resume playback');
          }
        }

        // If resume didn't work, try play() as fallback
        if (!playbackStarted) {
          try {
            await _audioPlayer.stop().timeout(const Duration(milliseconds: 100));
            // No delay needed here
            final source = _playbackSource(
              normalizedUrl: normalizedUrl,
              useLocalFile: useLocalFile,
              sourcePath: sourcePath,
            );
            await _audioPlayer
                .play(source)
                .timeout(
                  const Duration(seconds: 5),
                  onTimeout: () {
                    throw TimeoutException('Play timeout');
                  },
                );

            await Future<void>.delayed(const Duration(milliseconds: 200));
            if (_isPlaying || _audioPlayer.state == PlayerState.playing) {
              playbackStarted = true;
              _isPlaying = true;
              debugPrint('✅ Playback started with play()');
            }
          } catch (playError) {
            _handleError(playError, 'play() method');
          }
        }

        if (!playbackStarted) {
          // Don't throw, just log and return gracefully
          debugPrint('⚠️ Playback could not be started');
          _isLoading = false;
          _isPlaying = false;
          notifyListeners();
          return;
        }
      } catch (e) {
        _handleError(e, 'playback start');
        _isLoading = false;
        _isPlaying = false;
        notifyListeners();
        return;
      }

      // Check if cancelled before updating state
      if (_isCancelled) {
        debugPrint('⚠️ Operation cancelled before completion');
        _cleanupAfterCancellation();
        return;
      }

      // Update state
      _currentPlayingUrl = normalizedUrl;
      _currentMusic = music; // به‌روزرسانی موزیک فعلی
      _isLoading = false;

      // Show notification once (only if not already shown for this track)
      // For local files, show notification immediately (no delay needed)
      if (_lastNotificationUrl != normalizedUrl && !_isCancelled) {
        // Only delay for streaming, local files are instant
        if (!useLocalFile) {
          await Future<void>.delayed(const Duration(milliseconds: 300));
        }
        if (!_isCancelled) {
          final currentTrack = currentMusic;
          if (currentTrack != null && _currentPlayingUrl == normalizedUrl) {
            _lastNotificationUrl = normalizedUrl;
            try {
              await _notificationService.showMediaNotification(
                music: currentTrack,
                isPlaying: _isPlaying,
                position: _position,
                duration: _duration,
              );
            } catch (e) {
              _handleError(e, 'showing notification');
            }
          }
        }
      }

      if (!_isCancelled) {
        notifyListeners();
      }

      if (!opCompleter.isCompleted) {
        opCompleter.complete();
      }
    } catch (e) {
      // Don't log cancellation as error
      if (e.toString().contains('Cancelled') || _isCancelled) {
        debugPrint('ℹ️ Operation was cancelled');
        return;
      }

      // Handle all errors gracefully - never crash
      _handleError(e, 'playMusic');
      if (e is PlatformException) {
        debugPrint(
          '⚠️ PlatformException details: code=${e.code}, message=${e.message}',
        );
      }

      _isLoading = false;
      _isPlaying = false;
      _position = Duration.zero;
      _currentPlayingUrl = null;
      _lastNotificationUrl = null;
      notifyListeners();

      // Complete completer without error to prevent crashes
      if (!opCompleter.isCompleted) {
        opCompleter.complete();
      }
    } finally {
      _isOperationInProgress = false;
      if (identical(_operationCompleter, opCompleter)) {
        _operationCompleter = null;
      }
    }
  }

  Future<void> playAtIndex(int index) async {
    if (_playlist.isEmpty) {
      return;
    }

    try {
      if (_isShuffled) {
        if (index < 0 || index >= _shuffledIndices.length) {
          return;
        }
        final actualIndex = _shuffledIndices[index];
        if (actualIndex < 0 || actualIndex >= _playlist.length) {
          return;
        }
        await playMusic(_playlist[actualIndex], index: actualIndex);
      } else {
        if (index < 0 || index >= _playlist.length) {
          return;
        }
        await playMusic(_playlist[index], index: index);
      }
    } catch (e) {
      _handleError(e, 'playAtIndex');
    }
  }

  Future<void> togglePlayPause() async {
    // استفاده از currentMusic به جای _currentIndex برای چک کردن
    final music = currentMusic;
    if (music == null) {
      debugPrint('⚠️ Cannot toggle: no music selected');
      return;
    }

    if (_isLoading) {
      debugPrint('⚠️ Cannot toggle: music is loading');
      return;
    }

    // Prevent concurrent toggle operations
    if (_isToggling) {
      debugPrint('⚠️ Toggle already in progress');
      return;
    }

    _isToggling = true;

    try {
      if (_isPlaying) {
        // Pause - ساده و مستقیم
        debugPrint('⏸️ Pausing playback');

        // Set state immediately to prevent race conditions
        _isPlaying = false;
        notifyListeners();
        // Update notification immediately so the icon changes instantly.
        _notificationUpdateTimer?.cancel();
        _updateNotificationNow();

        // Pause the player
        try {
          await _audioPlayer.pause().timeout(
            const Duration(seconds: 1),
            onTimeout: () {
              debugPrint('⚠️ Pause timeout, continuing');
            },
          );
        } catch (e) {
          _handleError(e, 'pausing player');
        }

        // Small delay to let state settle
        await Future<void>.delayed(const Duration(milliseconds: 150));

        // Verify and ensure we're paused
        final currentState = _audioPlayer.state;
        if (currentState == PlayerState.playing) {
          // Still playing, try again
          try {
            await _audioPlayer.pause();
            _isPlaying = false;
          } catch (e) {
            _handleError(e, 'retry pause');
          }
        } else {
          // Confirm we're paused
          _isPlaying = false;
        }

        notifyListeners();
        _debouncedNotificationUpdate();
      } else {
        // Resume - ساده و مستقیم
        debugPrint('▶️ Resuming playback');

        try {
          // Optimistically update notification immediately (best UX),
          // then we correct if resume fails.
          _isPlaying = true;
          notifyListeners();
          _notificationUpdateTimer?.cancel();
          _updateNotificationNow();

          // Try resume first
          await _audioPlayer.resume().timeout(
            const Duration(seconds: 2),
            onTimeout: () {
              throw TimeoutException('Resume timeout');
            },
          );

          // Small delay to let state settle
          await Future<void>.delayed(const Duration(milliseconds: 200));

          // Check if actually playing
          final currentState = _audioPlayer.state;
          if (currentState == PlayerState.playing) {
            _isPlaying = true;
            notifyListeners();
            _debouncedNotificationUpdate();
          } else {
            // Resume didn't work, try play() with seek
            debugPrint('⚠️ Resume did not start, fallback to play()+seek()');
            // Reflect actual state until playback is confirmed.
            _isPlaying = false;
            notifyListeners();
            _notificationUpdateTimer?.cancel();
            _updateNotificationNow();

            final normalizedUrl = WorkoutMusic.normalizeAudioUrl(
              music.audioUrl,
            );
            final savedPosition = _position;

            String? localPath;
            try {
              localPath =
                  await _cacheService.getBestLocalPathForPlayback(normalizedUrl);
            } catch (e) {
              _handleError(e, 'getBestLocalPathForPlayback in togglePlayPause');
            }

            Source source = _streamingSource(normalizedUrl);
            if (localPath != null) {
              if (_isWebBlobPath(localPath)) {
                source = _localSource(localPath);
              } else {
                final file = File(localPath);
                if (await file.exists() && await file.length() > 0) {
                  try {
                    final randomAccessFile = await file.open();
                    await randomAccessFile.setPosition(0);
                    await randomAccessFile.read(1024);
                    await randomAccessFile.close();
                    source = DeviceFileSource(localPath);
                  } catch (e) {
                    debugPrint('⚠️ Cached file not readable in togglePlayPause: $e');
                  }
                }
              }
            }

            try {
              await _audioPlayer
                  .play(source)
                  .timeout(
                    const Duration(seconds: 10), // Increased timeout
                    onTimeout: () {
                      throw TimeoutException('Fallback play timeout');
                    },
                  );

              await Future<void>.delayed(const Duration(milliseconds: 200));

              // Restore position if we have one
              if (savedPosition > Duration.zero) {
                try {
                  await _audioPlayer
                      .seek(savedPosition)
                      .timeout(const Duration(seconds: 1));
                } catch (e) {
                  _handleError(e, 'seek after fallback play');
                }
              }

              _isPlaying = true;
              notifyListeners();
              _debouncedNotificationUpdate();
            } catch (e) {
              _handleError(e, 'fallback play');
              _isPlaying = false;
              notifyListeners();
              _notificationUpdateTimer?.cancel();
              _updateNotificationNow();
            }
          }
        } catch (e) {
          _handleError(e, 'resume playback');
          _isPlaying = false;
          notifyListeners();
          _notificationUpdateTimer?.cancel();
          _updateNotificationNow();
        }
      }
    } catch (e) {
      _handleError(e, 'togglePlayPause');
      // Ensure state is consistent
      _isPlaying = _audioPlayer.state == PlayerState.playing;
      notifyListeners();
    } finally {
      _isToggling = false;
    }
  }

  Future<void> next() async {
    if (_isOperationInProgress) {
      return;
    }

    try {
      final nextIndex = _getNextIndex();
      if (nextIndex != null) {
        await playAtIndex(nextIndex);
      }
    } catch (e) {
      _handleError(e, 'next');
    }
  }

  Future<void> previous() async {
    if (_isOperationInProgress) {
      return;
    }

    try {
      final prevIndex = _getPreviousIndex();
      if (prevIndex != null) {
        await playAtIndex(prevIndex);
      }
    } catch (e) {
      _handleError(e, 'previous');
    }
  }

  Future<void> seek(Duration position) async {
    try {
      // Optimistic UI update
      _position = position;
      notifyListeners();
      _updateNotificationNow();
      await _audioPlayer
          .seek(position)
          .timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              debugPrint('⚠️ Seek timeout');
            },
          );
    } catch (e) {
      _handleError(e, 'seeking');
    }
  }

  /// Closes the player UI completely (also clears the current selection).
  Future<void> close() async {
    await stop(clearSelection: true);
  }

  void toggleShuffle() {
    _isShuffled = !_isShuffled;
    if (_isShuffled) {
      _generateShuffledIndices();
    } else {
      _shuffledIndices.clear();
    }
    notifyListeners();
  }

  void toggleRepeat() {
    switch (_repeatMode) {
      case MusicRepeatMode.none:
        _repeatMode = MusicRepeatMode.all;
      case MusicRepeatMode.all:
        _repeatMode = MusicRepeatMode.one;
      case MusicRepeatMode.one:
        _repeatMode = MusicRepeatMode.none;
    }
    notifyListeners();
  }

  int? _getNextIndex() {
    if (_playlist.isEmpty) return null;
    
    // اگر موزیک فعلی در playlist نیست، از ابتدای playlist شروع کن
    if (_currentIndex < 0 || _currentIndex >= _playlist.length) {
      if (_playlist.isNotEmpty) {
        return 0;
      }
      return null;
    }

    if (_isShuffled) {
      final currentShuffledIndex = _shuffledIndices.indexOf(_currentIndex);
      if (currentShuffledIndex < 0) {
        // اگر در shuffled indices نیست، از ابتدا شروع کن
        return 0;
      }

      if (currentShuffledIndex < _shuffledIndices.length - 1) {
        return currentShuffledIndex + 1;
      } else if (_repeatMode == MusicRepeatMode.all) {
        return 0;
      }
    } else {
      if (_currentIndex < _playlist.length - 1) {
        return _currentIndex + 1;
      } else if (_repeatMode == MusicRepeatMode.all) {
        return 0;
      }
    }
    return null;
  }

  int? _getPreviousIndex() {
    if (_playlist.isEmpty) return null;
    
    // اگر موزیک فعلی در playlist نیست، از انتهای playlist شروع کن
    if (_currentIndex < 0 || _currentIndex >= _playlist.length) {
      if (_playlist.isNotEmpty) {
        return _playlist.length - 1;
      }
      return null;
    }

    if (_isShuffled) {
      final currentShuffledIndex = _shuffledIndices.indexOf(_currentIndex);
      if (currentShuffledIndex < 0) {
        // اگر در shuffled indices نیست، از انتها شروع کن
        return _shuffledIndices.length - 1;
      }

      if (currentShuffledIndex > 0) {
        return currentShuffledIndex - 1;
      } else if (_repeatMode == MusicRepeatMode.all) {
        return _shuffledIndices.length - 1;
      }
    } else {
      if (_currentIndex > 0) {
        return _currentIndex - 1;
      } else if (_repeatMode == MusicRepeatMode.all) {
        return _playlist.length - 1;
      }
    }
    return null;
  }

  void _cacheCurrentTrackInBackground() {
    if (_isCachingCurrentTrack || kIsWeb) return;
    
    final music = currentMusic;
    if (music == null) return;
    
    final normalizedUrl = WorkoutMusic.normalizeAudioUrl(music.audioUrl);
    
    // Don't auto-cache if it's explicitly downloaded already.
    _cacheService.getDownloadedPath(normalizedUrl).then((downloadedPath) {
      if (downloadedPath != null) return;

      _cacheService.getCachedPath(normalizedUrl).then((cachedPath) {
        if (cachedPath != null) return;

        _isCachingCurrentTrack = true;
        // Cache in background (non-blocking)
        _cacheService.cacheMusic(normalizedUrl).then((_) {
          _isCachingCurrentTrack = false;
          debugPrint('✅ Music cached in background: ${music.title}');
        }).catchError((Object e) {
          _isCachingCurrentTrack = false;
          debugPrint('⚠️ Background cache failed: $e');
        });
      });
    });
  }

  void _onTrackComplete() {
    try {
      // Auto-cache only after a full listen (Wi‑Fi only, handled in cache service).
      // Avoids double-download while still streaming.
      final listenedEnough = _duration.inMilliseconds <= 0 ||
          _position.inMilliseconds / _duration.inMilliseconds >= 0.85;
      if (listenedEnough) {
        _cacheCurrentTrackInBackground();
      }

      if (_repeatMode == MusicRepeatMode.one) {
        final replay = _currentIndex >= 0 && _currentIndex < _playlist.length
            ? _playlist[_currentIndex]
            : _currentMusic;
        if (replay != null) {
          playMusic(
            replay,
            index: _currentIndex >= 0 ? _currentIndex : null,
          ).catchError((Object e) {
            debugPrint('❌ Error replaying track: $e');
            _isPlaying = false;
            _position = Duration.zero;
            notifyListeners();
          });
        } else {
          _isPlaying = false;
          _position = Duration.zero;
          notifyListeners();
        }
      } else if (_repeatMode == MusicRepeatMode.all) {
        // Play next or loop to start
        final nextIndex = _getNextIndex();
        if (nextIndex != null) {
          playAtIndex(nextIndex).catchError((Object e) {
            debugPrint('❌ Error playing next: $e');
            // Try first track
            if (_playlist.isNotEmpty) {
              playAtIndex(0).catchError((Object e2) {
                debugPrint('❌ Error playing first: $e2');
                _isPlaying = false;
                _position = Duration.zero;
                notifyListeners();
              });
            }
          });
        } else if (_playlist.isNotEmpty) {
          playAtIndex(0).catchError((Object e) {
            debugPrint('❌ Error playing first: $e');
            _isPlaying = false;
            _position = Duration.zero;
            notifyListeners();
          });
        }
      } else {
        // MusicRepeatMode.none - Play next or stop
        final nextIndex = _getNextIndex();
        if (nextIndex != null) {
          playAtIndex(nextIndex).catchError((Object e) {
            debugPrint('❌ Error playing next: $e');
            _isPlaying = false;
            _position = Duration.zero;
            notifyListeners();
          });
        } else {
          _isPlaying = false;
          _position = Duration.zero;
          notifyListeners();
        }
      }
    } catch (e) {
      _handleError(e, '_onTrackComplete');
      _isPlaying = false;
      _position = Duration.zero;
      notifyListeners();
    }
  }

  void _generateShuffledIndices() {
    if (_playlist.isEmpty) {
      _shuffledIndices = [];
      return;
    }

    _shuffledIndices = List.generate(_playlist.length, (i) => i)..shuffle();

    // Keep current track in place
    if (_currentIndex >= 0 && _currentIndex < _playlist.length) {
      final currentPosition = _shuffledIndices.indexOf(_currentIndex);
      if (currentPosition > 0) {
        _shuffledIndices.removeAt(currentPosition);
        _shuffledIndices.insert(0, _currentIndex);
      } else if (currentPosition < 0) {
        _shuffledIndices.insert(0, _currentIndex);
      }
    }
  }

  bool _isValidUrl(String url) {
    if (url.isEmpty) return false;
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (_) {
      return false;
    }
  }

  /// Stops playback and hides the Android media notification.
  /// By default we DO NOT clear the selected track, so the user can hit play again
  /// (e.g. from UI) without getting "no music selected".
  Future<void> stop({bool clearSelection = false}) async {
    // Prevent recursive calls
    if (_isStopping) {
      debugPrint('⚠️ stop() already in progress, ignoring recursive call');
      return;
    }

    _isStopping = true;
    debugPrint('⏹️ Stopping playback');

    try {
      // Cancel any ongoing operation
      if (_isOperationInProgress && _operationCompleter != null) {
        _isCancelled = true;
        _isOperationInProgress = false;
        if (!_operationCompleter!.isCompleted) {
          _operationCompleter!.complete();
        }
        _operationCompleter = null;
      }

      // Temporarily clear onStop callback to prevent recursive calls
      final originalOnStop = _notificationService.onStop;
      _notificationService.onStop = null;
      _notificationService.updateCallbacks();

      try {
        // Stop audio player and release native resources (prevents ghost playback).
        try {
          await _audioPlayer.stop().timeout(
            const Duration(seconds: 2),
            onTimeout: () {
              debugPrint('⚠️ Stop timeout, continuing');
            },
          );
          await _audioPlayer.release().timeout(
            const Duration(seconds: 2),
            onTimeout: () {},
          );
        } catch (e) {
          _handleError(e, 'stopping player in stop()');
        }

        // Reset all state
        _isPlaying = false;
        _isLoading = false;
        _position = Duration.zero;
        if (clearSelection) {
          _currentIndex = -1;
          _currentMusic = null; // پاک کردن موزیک فعلی
        }
        _currentPlayingUrl = null;
        _lastNotificationUrl = null;
        _isCancelled = false;

        // Hide notification (this will call _audioHandler.stop() but onStop is null now)
        try {
          await _notificationService.hideNotification();
        } catch (e) {
          _handleError(e, 'hiding notification');
        }

        // Restore onStop callback
        _notificationService.onStop = originalOnStop;
        _notificationService.updateCallbacks();

        // Update UI
        notifyListeners();
        debugPrint('✅ Playback stopped');
      } catch (e) {
        // Restore onStop callback even on error
        _notificationService.onStop = originalOnStop;
        _notificationService.updateCallbacks();
        rethrow;
      }
    } catch (e) {
      _handleError(e, 'stop');
      // Ensure state is reset even on error
      _isPlaying = false;
      _isLoading = false;
      _position = Duration.zero;
      _isOperationInProgress = false;
      notifyListeners();
    } finally {
      _isStopping = false;
    }
  }

  @override
  void dispose() {
    _notificationUpdateTimer?.cancel();
    _notificationService.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
}
