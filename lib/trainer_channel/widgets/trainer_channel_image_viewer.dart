import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';

/// نمایش تمام‌صفحه تصویر با zoom — مثل تلگرام
class TrainerChannelImageViewer extends StatefulWidget {
  const TrainerChannelImageViewer({
    required this.url,
    this.heroTag,
    this.caption,
    super.key,
  });

  final String url;
  final String? heroTag;
  final String? caption;

  @override
  State<TrainerChannelImageViewer> createState() =>
      _TrainerChannelImageViewerState();
}

class _TrainerChannelImageViewerState
    extends State<TrainerChannelImageViewer> {
  final _transformController = TransformationController();
  bool _showUi = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _transformController.dispose();
    super.dispose();
  }

  void _toggleUi() => setState(() => _showUi = !_showUi);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleUi,
        child: Stack(
          fit: StackFit.expand,
          children: [
            InteractiveViewer(
              transformationController: _transformController,
              maxScale: 5,
              child: Hero(
                tag: widget.heroTag ?? widget.url,
                child: CachedNetworkImage(
                  imageUrl: widget.url,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.goldColor,
                    ),
                  ),
                  errorWidget: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image, color: Colors.white38, size: 64),
                  ),
                ),
              ),
            ),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _showUi ? 1 : 0,
              child: Column(
                children: [
                  SafeArea(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 4.h,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (widget.caption != null &&
                      widget.caption!.trim().isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black87, Colors.transparent],
                        ),
                      ),
                      child: Text(
                        widget.caption!.trim(),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          height: 1.4,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
