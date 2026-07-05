import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gymaipro/core/web_proxy_url.dart';

/// Network image that works on Flutter Web (CORS) via Supabase proxy when needed.
class GymaiNetworkImage extends StatelessWidget {
  const GymaiNetworkImage({
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.filterQuality = FilterQuality.low,
    this.placeholder,
    this.errorWidget,
    this.memCacheWidth,
    this.memCacheHeight,
    super.key,
  });

  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final FilterQuality filterQuality;
  final Widget? placeholder;
  final Widget? errorWidget;

  /// حداکثر پهنای دیکد در حافظه (پیکسل). مقدار پیش‌فرض از [width] محاسبه می‌شود
  /// تا تصاویر بزرگ بی‌دلیل با رزولوشن کامل decode/دانلود نشوند.
  final int? memCacheWidth;
  final int? memCacheHeight;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return errorWidget ?? const SizedBox.shrink();
    }

    final resolved = WebProxyUrl.resolve(imageUrl);

    // رزولوشن دیکد را به اندازهٔ نمایش محدود می‌کنیم تا نه حافظه هدر برود و نه
    // تصویر با کیفیت کامل بی‌دلیل دانلود/decode شود. بر اساس پهنا تا نسبت تصویر
    // حفظ شود؛ فقط اگر پهنا موجود نبود از ارتفاع استفاده می‌کنیم.
    final dpr = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 2.0;
    final int? effMemWidth = memCacheWidth ??
        (width != null && width!.isFinite ? (width! * dpr).round() : null);
    final int? effMemHeight = memCacheHeight ??
        (effMemWidth == null && height != null && height!.isFinite
            ? (height! * dpr).round()
            : null);

    if (kIsWeb) {
      return Image.network(
        resolved,
        fit: fit,
        width: width,
        height: height,
        cacheWidth: effMemWidth,
        cacheHeight: effMemHeight,
        filterQuality: filterQuality,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return placeholder ??
              SizedBox(
                width: width,
                height: height,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
        },
        errorBuilder: (_, __, ___) =>
            errorWidget ?? const Icon(Icons.broken_image_outlined),
      );
    }

    return CachedNetworkImage(
      imageUrl: resolved,
      fit: fit,
      width: width,
      height: height,
      filterQuality: filterQuality,
      memCacheWidth: effMemWidth,
      memCacheHeight: effMemHeight,
      maxWidthDiskCache: effMemWidth,
      maxHeightDiskCache: effMemHeight,
      placeholder: (_, __) =>
          placeholder ??
          SizedBox(
            width: width,
            height: height,
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
      errorWidget: (_, __, ___) =>
          errorWidget ?? const Icon(Icons.broken_image_outlined),
    );
  }
}
