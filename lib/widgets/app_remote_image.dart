import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gymaipro/config/app_asset_config.dart';
import 'package:shimmer/shimmer.dart';

/// Loads app images from bundled [images/] assets (or CDN when listed in [AppAssetConfig.remoteFileNames]).
class AppRemoteImage extends StatelessWidget {
  const AppRemoteImage({
    required this.path,
    this.fit = BoxFit.contain,
    this.width,
    this.height,
    this.filterQuality = FilterQuality.low,
    this.gaplessPlayback = false,
    this.placeholder,
    this.errorWidget,
    super.key,
  });

  final String path;
  final BoxFit fit;
  final double? width;
  final double? height;
  final FilterQuality filterQuality;
  final bool gaplessPlayback;
  final Widget? placeholder;
  final Widget? errorWidget;

  @override
  Widget build(BuildContext context) {
    if (!AppAssetConfig.isRemotePath(path)) {
      return Image.asset(
        AppAssetConfig.bundledAssetPath(path),
        fit: fit,
        width: width,
        height: height,
        filterQuality: filterQuality,
        gaplessPlayback: gaplessPlayback,
        errorBuilder: (_, __, ___) =>
            errorWidget ?? _defaultError(context),
      );
    }

    return CachedNetworkImage(
      imageUrl: AppAssetConfig.remoteUrl(path),
      fit: fit,
      width: width,
      height: height,
      filterQuality: filterQuality,
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder: (_, __) => placeholder ?? _defaultPlaceholder(context),
      errorWidget: (_, __, ___) =>
          errorWidget ?? _defaultError(context),
    );
  }

  Widget _defaultPlaceholder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.white12 : Colors.black12,
      highlightColor: isDark ? Colors.white24 : Colors.black26,
      child: ColoredBox(
        color: isDark ? Colors.white10 : Colors.black12,
        child: SizedBox(width: width, height: height),
      ),
    );
  }

  Widget _defaultError(BuildContext context) {
    return ColoredBox(
      color: Colors.black12,
      child: Icon(
        Icons.image_not_supported_outlined,
        size: (width ?? height ?? 32) * 0.45,
        color: Colors.white38,
      ),
    );
  }
}
