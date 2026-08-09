import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gymaipro/chat/models/user_chat_message.dart';
import 'package:gymaipro/chat/widgets/chat_video_viewer.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/trainer_channel/widgets/trainer_channel_image_viewer.dart';
import 'package:gymaipro/utils/widget_safety_utils.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Open chat attachments (image / video / file) for sender and receiver.
class ChatAttachmentActions {
  ChatAttachmentActions._();

  static Future<void> open(BuildContext context, ChatMessage message) async {
    final url = message.attachmentUrl?.trim();
    if (url == null || url.isEmpty) {
      if (context.mounted) {
        WidgetSafetyUtils.safeShowSnackBar(context, 'پیوست در دسترس نیست');
      }
      return;
    }

    final name = message.attachmentName ?? _nameFromUrl(url);
    final kind = _classify(message, name);

    switch (kind) {
      case _AttachmentKind.image:
        await _openImage(context, url: url, caption: message.message, heroTag: 'chat_img_${message.id}');
      case _AttachmentKind.video:
        await _openVideo(context, url: url, title: name);
      case _AttachmentKind.file:
        await _openFile(context, url: url, fileName: name);
    }
  }

  static Future<void> _openImage(
    BuildContext context, {
    required String url,
    required String heroTag,
    String? caption,
  }) async {
    if (!context.mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => TrainerChannelImageViewer(
          url: url,
          heroTag: heroTag,
          caption: caption,
        ),
      ),
    );
  }

  static Future<void> _openVideo(
    BuildContext context, {
    required String url,
    required String title,
  }) async {
    if (!context.mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ChatVideoViewer(url: url, title: title),
      ),
    );
  }

  static Future<void> _openFile(
    BuildContext context, {
    required String url,
    required String fileName,
  }) async {
    if (kIsWeb) {
      final uri = Uri.tryParse(url);
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }

    if (!context.mounted) return;
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const PopScope(
          canPop: false,
          child: Center(
            child: Card(
              color: Colors.black87,
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppTheme.goldColor),
                    SizedBox(height: 12),
                    Text(
                      'در حال آماده‌سازی فایل…',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    try {
      final localPath = await _downloadToCache(url: url, fileName: fileName);
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
      if (localPath == null) {
        if (context.mounted) {
          WidgetSafetyUtils.safeShowSnackBar(context, 'دانلود فایل ناموفق بود');
        }
        return;
      }
      final result = await OpenFilex.open(localPath);
      if (result.type != ResultType.done && context.mounted) {
        // Fallback: open remote URL in browser / external app
        final uri = Uri.tryParse(url);
        if (uri != null) {
          final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (!ok && context.mounted) {
            WidgetSafetyUtils.safeShowSnackBar(
              context,
              'برنامه‌ای برای باز کردن این فایل پیدا نشد',
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        WidgetSafetyUtils.safeShowSnackBar(context, 'خطا در باز کردن فایل');
      }
      debugPrint('ChatAttachmentActions.openFile: $e');
    }
  }

  static Future<String?> _downloadToCache({
    required String url,
    required String fileName,
  }) async {
    final safeName = fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final dir = await getTemporaryDirectory();
    final cacheDir = Directory(p.join(dir.path, 'chat_attachments'));
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    final outPath = p.join(cacheDir.path, safeName);
    final existing = File(outPath);
    if (await existing.exists() && await existing.length() > 0) {
      return outPath;
    }

    final client = http.Client();
    try {
      final response = await client.get(Uri.parse(url));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      await existing.writeAsBytes(response.bodyBytes, flush: true);
      return outPath;
    } finally {
      client.close();
    }
  }

  static _AttachmentKind _classify(ChatMessage message, String name) {
    if (message.isImage) return _AttachmentKind.image;
    if (message.messageType == 'video') return _AttachmentKind.video;

    final ext = _extensionOf(name).toLowerCase();
    const images = {
      'jpg',
      'jpeg',
      'png',
      'gif',
      'webp',
      'heic',
      'heif',
      'bmp',
    };
    const videos = {
      'mp4',
      'mov',
      'm4v',
      'webm',
      'mkv',
      'avi',
      '3gp',
    };

    final type = (message.attachmentType ?? '').toLowerCase();
    if (type.startsWith('image/') || images.contains(ext)) {
      return _AttachmentKind.image;
    }
    if (type.startsWith('video/') || videos.contains(ext)) {
      return _AttachmentKind.video;
    }
    return _AttachmentKind.file;
  }

  static String _extensionOf(String name) {
    final dot = name.lastIndexOf('.');
    if (dot < 0 || dot >= name.length - 1) return '';
    return name.substring(dot + 1);
  }

  static String _nameFromUrl(String url) {
    try {
      final path = Uri.parse(url).pathSegments;
      if (path.isNotEmpty && path.last.isNotEmpty) return path.last;
    } catch (_) {}
    return 'attachment';
  }
}

enum _AttachmentKind { image, video, file }
