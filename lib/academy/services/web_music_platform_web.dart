import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart';

/// In-browser blob URLs for downloaded coach music (Flutter Web / iOS PWA).
class WebMusicPlatform {
  static final Map<String, String> _blobUrls = {};

  static bool get supported => true;

  static String? blobUrlForKey(String key) => _blobUrls[key];

  static String storeBlob(String key, Uint8List bytes, {String? fileName}) {
    revoke(key);
    final blob = Blob([bytes.toJS].toJS);
    final url = URL.createObjectURL(blob);
    _blobUrls[key] = url;
    return url;
  }

  static void revoke(String key) {
    final existing = _blobUrls.remove(key);
    if (existing != null) {
      URL.revokeObjectURL(existing);
    }
  }

  static Future<void> saveToDownloads(
    Uint8List bytes, {
    required String fileName,
  }) async {
    final blob = Blob([bytes.toJS].toJS);
    final url = URL.createObjectURL(blob);
    final anchor = HTMLAnchorElement()
      ..href = url
      ..download = fileName;
    document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    URL.revokeObjectURL(url);
  }
}
