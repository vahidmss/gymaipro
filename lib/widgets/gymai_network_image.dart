import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gymaipro/core/web_proxy_url.dart';

/// Network image that works on Flutter Web (CORS) via Supabase proxy when needed.
///
/// After [loadTimeout] without success/error, shows [errorWidget] so broken /
/// filtered hosts (e.g. dead Unsplash links) do not spin forever.
class GymaiNetworkImage extends StatefulWidget {
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
    this.loadTimeout = const Duration(seconds: 10),
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

  /// If the image neither loads nor errors within this duration, show error UI.
  final Duration loadTimeout;

  @override
  State<GymaiNetworkImage> createState() => _GymaiNetworkImageState();
}

class _GymaiNetworkImageState extends State<GymaiNetworkImage> {
  Timer? _timeoutTimer;
  bool _timedOut = false;
  bool _settled = false;

  @override
  void initState() {
    super.initState();
    _armTimeout();
  }

  @override
  void didUpdateWidget(covariant GymaiNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _settled = false;
      _timedOut = false;
      _armTimeout();
    }
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _armTimeout() {
    _timeoutTimer?.cancel();
    if (widget.imageUrl.isEmpty || widget.loadTimeout <= Duration.zero) {
      return;
    }
    _timeoutTimer = Timer(widget.loadTimeout, () {
      if (!mounted || _settled) return;
      setState(() => _timedOut = true);
    });
  }

  void _markSettled() {
    if (_settled) return;
    _settled = true;
    _timeoutTimer?.cancel();
  }

  Widget _fallbackError() =>
      widget.errorWidget ?? const Icon(Icons.broken_image_outlined);

  Widget _fallbackPlaceholder() =>
      widget.placeholder ??
      SizedBox(
        width: widget.width,
        height: widget.height,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrl.isEmpty || _timedOut) {
      _markSettled();
      return _fallbackError();
    }

    final resolved = WebProxyUrl.resolve(widget.imageUrl);

    final dpr = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 2.0;
    final int? effMemWidth = widget.memCacheWidth ??
        (widget.width != null && widget.width!.isFinite
            ? (widget.width! * dpr).round()
            : null);
    final int? effMemHeight = widget.memCacheHeight ??
        (effMemWidth == null &&
                widget.height != null &&
                widget.height!.isFinite
            ? (widget.height! * dpr).round()
            : null);

    if (kIsWeb) {
      return Image.network(
        resolved,
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        cacheWidth: effMemWidth,
        cacheHeight: effMemHeight,
        filterQuality: widget.filterQuality,
        loadingBuilder: (context, child, progress) {
          if (progress == null) {
            _markSettled();
            return child;
          }
          return _fallbackPlaceholder();
        },
        errorBuilder: (_, __, ___) {
          _markSettled();
          return _fallbackError();
        },
      );
    }

    return CachedNetworkImage(
      imageUrl: resolved,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      filterQuality: widget.filterQuality,
      memCacheWidth: effMemWidth,
      memCacheHeight: effMemHeight,
      maxWidthDiskCache: effMemWidth,
      maxHeightDiskCache: effMemHeight,
      fadeInDuration: const Duration(milliseconds: 180),
      placeholder: (_, __) => _fallbackPlaceholder(),
      errorWidget: (_, __, ___) {
        _markSettled();
        return _fallbackError();
      },
      imageBuilder: (context, imageProvider) {
        _markSettled();
        return Image(
          image: imageProvider,
          fit: widget.fit,
          width: widget.width,
          height: widget.height,
          filterQuality: widget.filterQuality,
        );
      },
    );
  }
}
