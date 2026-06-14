import 'package:gymaipro/config/app_config.dart';

/// App imagery paths — decorative assets ship in the bundled [images/] folder.
class AppAssetConfig {
  AppAssetConfig._();

  /// Optional CDN base (unused while all assets are bundled locally).
  static String get cdnBaseUrl {
    const fromEnv = String.fromEnvironment('APP_ASSETS_CDN_BASE');
    if (fromEnv.isNotEmpty) {
      return fromEnv.replaceFirst(RegExp(r'/$'), '');
    }
    final fromDotenv = AppConfig.dotenvValue('APP_ASSETS_CDN_BASE');
    if (fromDotenv != null && fromDotenv.isNotEmpty) {
      return fromDotenv.replaceFirst(RegExp(r'/$'), '');
    }
    return '${AppConfig.wordpressApiOrigin}/static/app-images';
  }

  /// Filenames loaded from CDN instead of APK. Empty = همه از [images/] لوکال.
  static const remoteFileNames = <String>{};

  /// Normalizes `images/foo.png` → `foo.png`.
  static String fileNameFromPath(String path) {
    final trimmed = path.trim();
    if (trimmed.startsWith('images/')) {
      return trimmed.substring('images/'.length);
    }
    return trimmed;
  }

  static bool isRemotePath(String path) {
    return remoteFileNames.contains(fileNameFromPath(path));
  }

  static String bundledAssetPath(String path) {
    final fileName = fileNameFromPath(path);
    return 'images/$fileName';
  }

  static String remoteUrl(String path) {
    return '$cdnBaseUrl/${fileNameFromPath(path)}';
  }

  static String resolveUrl(String path) {
    if (isRemotePath(path)) {
      return remoteUrl(path);
    }
    return bundledAssetPath(path);
  }
}
