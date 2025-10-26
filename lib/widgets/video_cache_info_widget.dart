import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/services/video_cache_service.dart';

class VideoCacheInfoWidget extends StatefulWidget {
  const VideoCacheInfoWidget({super.key});

  @override
  State<VideoCacheInfoWidget> createState() => _VideoCacheInfoWidgetState();
}

class _VideoCacheInfoWidgetState extends State<VideoCacheInfoWidget> {
  final VideoCacheService _videoCacheService = VideoCacheService();
  int _cacheSize = 0;
  int _cachedFilesCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCacheInfo();
  }

  Future<void> _loadCacheInfo() async {
    try {
      final size = await _videoCacheService.getCacheSize();
      final count = await _videoCacheService.getCachedFilesCount();

      if (mounted) {
        setState(() {
          _cacheSize = size;
          _cachedFilesCount = count;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _clearCache() async {
    try {
      await _videoCacheService.clearCache();
      await _loadCacheInfo();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('کش ویدیو پاک شد'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در پاک‌سازی کش: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.w),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.video_library, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'کش ویدیو',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (!_isLoading)
                  IconButton(
                    onPressed: _clearCache,
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'پاک‌سازی کش',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.storage, size: 16.sp, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text('اندازه: ${_formatFileSize(_cacheSize)}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.video_file, size: 16.sp, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text('تعداد فایل‌ها: $_cachedFilesCount'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.info, size: 16.sp, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'ویدیوها پس از مشاهده در کش ذخیره می‌شوند تا دفعات بعد نیازی به دانلود مجدد نباشد.',
                          style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
