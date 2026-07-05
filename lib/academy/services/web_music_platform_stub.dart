import 'dart:typed_data';

/// No-op on mobile/desktop native.
class WebMusicPlatform {
  static bool get supported => false;

  static String? blobUrlForKey(String key) => null;

  static String storeBlob(String key, Uint8List bytes, {String? fileName}) =>
      throw UnsupportedError('WebMusicPlatform only on web');

  static void revoke(String key) {}

  static Future<void> saveToDownloads(
    Uint8List bytes, {
    required String fileName,
  }) async {}
}
