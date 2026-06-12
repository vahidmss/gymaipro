import 'package:gymaipro/config/app_config.dart';

/// Bundled vs CDN-backed app imagery for smaller APK size.
///
/// Heavy decorative assets live on [cdnBaseUrl]. Small UI icons stay in APK.
class AppAssetConfig {
  AppAssetConfig._();

  /// Base URL without trailing slash, e.g. `https://gymaipro.ir/static/app-images`.
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

  /// Filenames served from CDN (not bundled in APK).
  static const remoteFileNames = <String>{
    'bronze.png',
    'silver.png',
    'gold.png',
    'platinum.png',
    'diamond.png',
    'poster1.png',
    'poster2.png',
    'poster3.png',
    'poster4.png',
    'poster5.png',
    'gymai_body_front_premium.png',
    'gymai_body_back_premium.png',
    'gymai_anatomy_body_front_back.png',
    'ai_robot.png',
  };

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
