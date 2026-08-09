import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Central haptic + in-app chat sound feedback.
///
/// Design rules:
/// - Haptics for light UI confirmation (list open, attach, selection).
/// - Sounds only for meaningful chat events (send / receive), not every tap.
/// - Respects prefs + iOS silent switch (ambient session).
class AppFeedbackService {
  AppFeedbackService._();

  static final AppFeedbackService instance = AppFeedbackService._();

  static const String soundEnabledKey = 'sound_enabled';
  static const String vibrationEnabledKey = 'vibration_enabled';
  static const String chatInAppSoundsKey = 'chat_in_app_sounds_enabled';

  AudioPlayer? _player;
  bool _audioReady = false;
  bool _audioInitFailed = false;

  DateTime? _lastReceiveAt;
  static const Duration _receiveDebounce = Duration(milliseconds: 420);

  Future<void> ensureInitialized() async {
    if (_audioReady || _audioInitFailed || kIsWeb) return;
    try {
      final player = AudioPlayer();
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setVolume(0.45);
      // Ambient respects the iOS silent switch; keeps chat FX out of music ducking.
      await player.setAudioContext(
        AudioContext(
          // Ambient respects the hardware silent switch on iOS.
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.ambient,
          ),
          android: const AudioContextAndroid(
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.assistanceSonification,
            audioFocus: AndroidAudioFocus.none,
          ),
        ),
      );
      _player = player;
      _audioReady = true;
    } catch (e) {
      _audioInitFailed = true;
      if (kDebugMode) {
        debugPrint('AppFeedbackService audio init failed: $e');
      }
    }
  }

  Future<bool> isSoundEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(soundEnabledKey) ?? true;
  }

  Future<bool> isVibrationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(vibrationEnabledKey) ?? true;
  }

  Future<bool> isChatInAppSoundsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(chatInAppSoundsKey) ?? true;
  }

  Future<void> setChatInAppSoundsEnabled({required bool enabled}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(chatInAppSoundsKey, enabled);
  }

  /// Soft selection for opening a conversation / light controls.
  Future<void> selection() async {
    if (!await isVibrationEnabled()) return;
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }

  /// Light confirmation (send press companion, attach, success-ish taps).
  Future<void> lightImpact() async {
    if (!await isVibrationEnabled()) return;
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  Future<void> mediumImpact() async {
    if (!await isVibrationEnabled()) return;
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Message successfully queued/sent from composer.
  Future<void> messageSent() async {
    unawaited(lightImpact());
    unawaited(_playChatSound('sounds/message_sent.wav'));
  }

  /// Peer message appeared while user is inside the thread.
  Future<void> messageReceived() async {
    final now = DateTime.now();
    if (_lastReceiveAt != null &&
        now.difference(_lastReceiveAt!) < _receiveDebounce) {
      return;
    }
    _lastReceiveAt = now;
    unawaited(selection());
    unawaited(_playChatSound('sounds/message_received.wav'));
  }

  Future<void> _playChatSound(String assetPath) async {
    if (kIsWeb) return;
    if (!await isSoundEnabled()) return;
    if (!await isChatInAppSoundsEnabled()) return;

    await ensureInitialized();
    final player = _player;
    if (player == null) return;

    try {
      await player.stop();
      await player.play(AssetSource(assetPath));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AppFeedbackService play failed ($assetPath): $e');
      }
    }
  }

  Future<void> silence() async {
    try {
      await _player?.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await _player?.dispose();
    _player = null;
    _audioReady = false;
  }
}
