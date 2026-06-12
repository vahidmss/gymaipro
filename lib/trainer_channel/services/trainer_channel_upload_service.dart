import 'dart:io';

import 'package:gymaipro/academy/services/cover_upload_service.dart';
import 'package:gymaipro/academy/services/music_upload_service.dart';
import 'package:gymaipro/services/coach_video_upload_service.dart';
import 'package:gymaipro/trainer_channel/constants/trainer_channel_constants.dart';
import 'package:gymaipro/trainer_channel/utils/trainer_channel_media_utils.dart';
import 'package:image_picker/image_picker.dart';

/// آپلود رسانه کانال مربی روی هاست دانلود (dl.gymaipro.ir)
class TrainerChannelUploadService {
  TrainerChannelUploadService({
    CoverUploadService? coverUploadService,
    CoachVideoUploadService? videoUploadService,
    MusicUploadService? musicUploadService,
  })  : _coverUpload = coverUploadService ?? CoverUploadService(),
        _videoUpload = videoUploadService ?? CoachVideoUploadService(),
        _musicUpload = musicUploadService ?? MusicUploadService();

  final CoverUploadService _coverUpload;
  final CoachVideoUploadService _videoUpload;
  final MusicUploadService _musicUpload;

  static const String _ctx = TrainerChannelConstants.uploadContext;

  Future<String> uploadImage(
    XFile file, {
    void Function(double progress)? onProgress,
  }) async {
    final local = await TrainerChannelMediaUtils.ensureLocalFile(file);
    return _coverUpload.uploadCover(
      local,
      onProgress: onProgress,
      uploadContext: _ctx,
      maxFileSizeBytes: 8 * 1024 * 1024,
    );
  }

  Future<String> uploadVideo(
    XFile file, {
    void Function(double progress)? onProgress,
  }) async {
    final local = await TrainerChannelMediaUtils.ensureLocalFile(file);
    final size = await local.length();
    const maxBytes =
        TrainerChannelConstants.maxVideoSizeMb * 1024 * 1024;
    if (size > maxBytes) {
      throw Exception(
        'حجم ویدیو بیش از ${TrainerChannelConstants.maxVideoSizeMb} مگابایت است',
      );
    }
    return _videoUpload.uploadVideo(
      local,
      onProgress: onProgress,
      uploadContext: _ctx,
    );
  }

  Future<String> uploadVoice(
    XFile file, {
    void Function(double progress)? onProgress,
  }) async {
    final local = await TrainerChannelMediaUtils.ensureLocalFile(file);
    return _musicUpload.uploadMusic(
      local,
      onProgress: onProgress,
      uploadContext: _ctx,
    );
  }

  Future<String> uploadVoiceFile(
    File file, {
    void Function(double progress)? onProgress,
  }) async {
    return _musicUpload.uploadMusic(
      file,
      onProgress: onProgress,
      uploadContext: _ctx,
    );
  }

  /// فایل صوتی از گالری/فایل‌ها (mp3, m4a, …)
  Future<String> uploadAudioFile(
    File file, {
    void Function(double progress)? onProgress,
  }) async {
    final size = await file.length();
    const maxBytes =
        TrainerChannelConstants.maxAudioFileSizeMb * 1024 * 1024;
    if (size > maxBytes) {
      throw Exception(
        'حجم فایل بیش از ${TrainerChannelConstants.maxAudioFileSizeMb} مگابایت است',
      );
    }
    return _musicUpload.uploadMusic(
      file,
      onProgress: onProgress,
      uploadContext: _ctx,
    );
  }
}
