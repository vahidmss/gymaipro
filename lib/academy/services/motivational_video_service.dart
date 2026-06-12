import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:gymaipro/academy/models/motivational_video.dart';
import 'package:gymaipro/utils/cache_service.dart';
import 'package:http/http.dart' as http;

class MotivationalVideoService {
  static const String _baseUrl = 'https://gymaipro.ir/wp-json/wp/v2/video';
  static const String _cacheKey = 'academy_motivational_videos';
  static const Duration _cacheExpiry = Duration(minutes: 30);

  static Future<List<MotivationalVideo>> fetchVideos({
    bool forceRefresh = false,
  }) async {
    // Check cache
    if (!forceRefresh) {
      final lastUpdate = await CacheService.getUpdatedAt(_cacheKey);
      if (lastUpdate != null &&
          DateTime.now().difference(lastUpdate) < _cacheExpiry) {
        final cachedData = await CacheService.getJsonList(_cacheKey);
        if (cachedData != null) {
          return cachedData
              .cast<Map<String, dynamic>>()
              .map(MotivationalVideo.fromJson)
              .toList();
        }
      }
    }

    try {
      // Try multiple WordPress REST API endpoints
      final endpoints = [
        'https://gymaipro.ir/wp-json/wp/v2/video?per_page=100&_embed=true',
        'https://gymaipro.ir/wp-json/wp/v2/posts?per_page=100&_embed=true',
      ];

      for (final endpointUrl in endpoints) {
        try {
          final uri = Uri.parse(endpointUrl);
          final response = await http
              .get(uri, headers: {'Accept': 'application/json'})
              .timeout(const Duration(seconds: 15));

          if (response.statusCode == 200) {
            final body = utf8.decode(response.bodyBytes);
            try {
              final List<dynamic> decoded = json.decode(body) as List<dynamic>;

              if (decoded.isNotEmpty) {
                final videos = <MotivationalVideo>[];

                for (final item in decoded) {
                  try {
                    final itemMap = item as Map<String, dynamic>;

                    // Check if this post has video content
                    final hasVideo = _hasVideoContent(itemMap);
                    if (!hasVideo) {
                      continue; // Skip posts without video
                    }

                    final video = MotivationalVideo.fromWordPressJson(itemMap);
                    // Only add videos that have a valid video URL
                    if (video.videoUrl.isNotEmpty) {
                      videos.add(video);
                    }
                  } catch (e) {
                    if (kDebugMode) {
                      debugPrint('VideoService: Error parsing video item: $e');
                    }
                    // Skip invalid items
                    continue;
                  }
                }

                if (videos.isNotEmpty) {
                  // Cache
                  final jsonData = videos.map((v) => v.toJson()).toList();
                  await CacheService.setJson(_cacheKey, jsonData);
                  return videos;
                }
              }
            } catch (e) {
              if (kDebugMode) {
                debugPrint(
                  'VideoService: JSON parsing failed for $endpointUrl: $e',
                );
              }
              // If JSON parsing fails, try next endpoint
              continue;
            }
          } else {
            if (kDebugMode) {
              debugPrint(
                'VideoService: HTTP ${response.statusCode} for $endpointUrl',
              );
            }
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('VideoService: Error fetching $endpointUrl: $e');
          }
          // Try next endpoint
          continue;
        }
      }

      if (kDebugMode) {
        debugPrint(
          'VideoService: All REST API endpoints failed, trying HTML parsing',
        );
      }

      // If REST API doesn't work or returns empty, try parsing the HTML page
      return await _fetchFromHtmlPage();
    } catch (e) {
      // Fallback to cache if available
      final cachedData = await CacheService.getJsonList(_cacheKey);
      if (cachedData != null) {
        return cachedData
            .cast<Map<String, dynamic>>()
            .map(MotivationalVideo.fromJson)
            .toList();
      }
      // If cache also fails, try HTML parsing
      try {
        if (kDebugMode) {
          debugPrint('VideoService: Trying HTML parsing as last resort');
        }
        return await _fetchFromHtmlPage();
      } catch (htmlError) {
        if (kDebugMode) {
          debugPrint(
            'VideoService: All methods failed. API error: $e, HTML error: $htmlError',
          );
        }
        // Return empty list instead of throwing to show empty state
        return [];
      }
    }
  }

  static Future<List<MotivationalVideo>> _fetchFromHtmlPage() async {
    try {
      final uri = Uri.parse(
        'https://gymaipro.ir/%d9%81%db%8c%d9%84%d9%85-%d9%87%d8%a7%db%8c-%d8%a7%d9%86%da%af%db%8c%d8%b2%d8%b4%db%8c/',
      );
      final response = await http
          .get(uri, headers: {'Accept': 'text/html'})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final htmlContent = utf8.decode(response.bodyBytes);
        final List<MotivationalVideo> videoList = [];

        // Method 1: Try to find JSON data in script tags
        final jsonPattern1 = RegExp(
          '<script[^>]*type="application/json"[^>]*>(.*?)</script>',
          dotAll: true,
        );
        final jsonPattern2 = RegExp(
          "<script[^>]*type='application/json'[^>]*>(.*?)</script>",
          dotAll: true,
        );

        RegExpMatch? jsonMatch = jsonPattern1.firstMatch(htmlContent);
        jsonMatch ??= jsonPattern2.firstMatch(htmlContent);

        if (jsonMatch != null && jsonMatch.groupCount > 0) {
          try {
            final jsonString = jsonMatch.group(1);
            if (jsonString != null) {
              final jsonData = json.decode(jsonString);
              if (jsonData is List) {
                final videos = jsonData
                    .map(
                      (item) => MotivationalVideo.fromWordPressJson(
                        item as Map<String, dynamic>,
                      ),
                    )
                    .toList();

                if (videos.isNotEmpty) {
                  final jsonDataToCache = videos
                      .map((v) => v.toJson())
                      .toList();
                  await CacheService.setJson(_cacheKey, jsonDataToCache);
                  return videos;
                }
              }
            }
          } catch (e) {
            // Continue to try other methods
          }
        }

        // Method 2: Try to find video elements and extract data
        // Look for both self-closing and full video tags
        final videoPattern = RegExp(
          '<video[^>]*(?:>.*?</video>|/?>)',
          dotAll: true,
          caseSensitive: false,
        );
        final videoMatches = videoPattern.allMatches(htmlContent);

        for (final match in videoMatches) {
          final videoHtml = match.group(0) ?? '';

          String videoUrl = '';
          String thumbnailUrl = '';
          String title = 'ویدیو انگیزشی';

          // Extract src attribute from video tag
          final srcPattern1 = RegExp(
            r'src\s*=\s*"([^"]+)"',
            caseSensitive: false,
          );
          final srcPattern2 = RegExp(
            r"src\s*=\s*'([^']+)'",
            caseSensitive: false,
          );
          RegExpMatch? srcMatch = srcPattern1.firstMatch(videoHtml);
          srcMatch ??= srcPattern2.firstMatch(videoHtml);
          videoUrl = srcMatch?.group(1) ?? '';

          // Try to find source tag inside video
          if (videoUrl.isEmpty) {
            final sourcePattern1 = RegExp(
              r'<source[^>]*src\s*=\s*"([^"]+)"',
              caseSensitive: false,
            );
            final sourcePattern2 = RegExp(
              r"<source[^>]*src\s*=\s*'([^']+)'",
              caseSensitive: false,
            );
            RegExpMatch? sourceMatch = sourcePattern1.firstMatch(videoHtml);
            sourceMatch ??= sourcePattern2.firstMatch(videoHtml);
            videoUrl = sourceMatch?.group(1) ?? '';
          }

          // Extract poster/thumbnail
          final posterPattern1 = RegExp(
            r'poster\s*=\s*"([^"]+)"',
            caseSensitive: false,
          );
          final posterPattern2 = RegExp(
            r"poster\s*=\s*'([^']+)'",
            caseSensitive: false,
          );
          RegExpMatch? posterMatch = posterPattern1.firstMatch(videoHtml);
          posterMatch ??= posterPattern2.firstMatch(videoHtml);
          thumbnailUrl = posterMatch?.group(1) ?? '';

          // Extract title from data attributes or nearby content
          final titlePattern1 = RegExp(
            r'data-title\s*=\s*"([^"]+)"',
            caseSensitive: false,
          );
          final titlePattern2 = RegExp(
            r"data-title\s*=\s*'([^']+)'",
            caseSensitive: false,
          );
          RegExpMatch? titleMatch = titlePattern1.firstMatch(videoHtml);
          titleMatch ??= titlePattern2.firstMatch(videoHtml);
          title = titleMatch?.group(1) ?? title;

          // Try to find title from nearby heading or article
          if (title == 'ویدیو انگیزشی') {
            // Look for heading before video tag
            final headingPattern = RegExp(
              '<h[1-6][^>]*>(.*?)</h[1-6]>',
              dotAll: true,
              caseSensitive: false,
            );
            final headingMatches = headingPattern.allMatches(htmlContent);
            for (final headingMatch in headingMatches) {
              final headingPos = headingMatch.start;
              final videoPos = match.start;
              // If heading is within 500 characters before video
              if (headingPos < videoPos && (videoPos - headingPos) < 500) {
                final headingText = headingMatch.group(1) ?? '';
                // Remove HTML tags from heading
                final cleanHeading = headingText
                    .replaceAll(RegExp('<[^>]+>'), '')
                    .trim();
                if (cleanHeading.isNotEmpty && cleanHeading.length < 100) {
                  title = cleanHeading;
                  break;
                }
              }
            }
          }

          // Only add if we have a valid video URL
          if (videoUrl.isNotEmpty) {
            // Make sure URL is absolute
            if (!videoUrl.startsWith('http')) {
              if (videoUrl.startsWith('//')) {
                videoUrl = 'https:$videoUrl';
              } else if (videoUrl.startsWith('/')) {
                videoUrl = 'https://gymaipro.ir$videoUrl';
              }
            }

            // Make thumbnail URL absolute if needed
            if (thumbnailUrl.isNotEmpty && !thumbnailUrl.startsWith('http')) {
              if (thumbnailUrl.startsWith('//')) {
                thumbnailUrl = 'https:$thumbnailUrl';
              } else if (thumbnailUrl.startsWith('/')) {
                thumbnailUrl = 'https://gymaipro.ir$thumbnailUrl';
              }
            }

            videoList.add(
              MotivationalVideo(
                id: videoList.length + 1,
                title: title,
                videoUrl: videoUrl,
                thumbnailUrl: thumbnailUrl.isNotEmpty
                    ? thumbnailUrl
                    : 'https://via.placeholder.com/1280x720?text=Video',
                duration: 0, // Will be determined when playing
                category: 'general',
              ),
            );
          }
        }

        // Method 3: Try to find video URLs in iframe embeds (YouTube, Vimeo, etc.)
        if (videoList.isEmpty) {
          final iframePattern1 = RegExp(
            r'<iframe[^>]*src\s*=\s*"([^"]+)"',
            caseSensitive: false,
          );
          final iframePattern2 = RegExp(
            r"<iframe[^>]*src\s*=\s*'([^']+)'",
            caseSensitive: false,
          );
          final iframeMatches1 = iframePattern1.allMatches(htmlContent);
          final iframeMatches2 = iframePattern2.allMatches(htmlContent);

          for (final match in iframeMatches1) {
            final embedUrl = match.group(1) ?? '';
            if (embedUrl.contains('youtube.com') ||
                embedUrl.contains('youtu.be') ||
                embedUrl.contains('vimeo.com')) {
              videoList.add(
                MotivationalVideo(
                  id: videoList.length + 1,
                  title: 'ویدیو انگیزشی ${videoList.length + 1}',
                  videoUrl: embedUrl,
                  thumbnailUrl:
                      'https://via.placeholder.com/1280x720?text=Video',
                  duration: 0,
                  category: 'general',
                ),
              );
            }
          }

          for (final match in iframeMatches2) {
            final embedUrl = match.group(1) ?? '';
            if (embedUrl.contains('youtube.com') ||
                embedUrl.contains('youtu.be') ||
                embedUrl.contains('vimeo.com')) {
              // Check if already added
              if (!videoList.any((v) => v.videoUrl == embedUrl)) {
                videoList.add(
                  MotivationalVideo(
                    id: videoList.length + 1,
                    title: 'ویدیو انگیزشی ${videoList.length + 1}',
                    videoUrl: embedUrl,
                    thumbnailUrl:
                        'https://via.placeholder.com/1280x720?text=Video',
                    duration: 0,
                    category: 'general',
                  ),
                );
              }
            }
          }
        }

        // If we found any videos, cache and return it
        if (videoList.isNotEmpty) {
          if (kDebugMode) {
            debugPrint(
              'VideoService: Found ${videoList.length} videos from HTML parsing',
            );
          }
          final jsonDataToCache = videoList.map((v) => v.toJson()).toList();
          await CacheService.setJson(_cacheKey, jsonDataToCache);
          return videoList;
        }

        if (kDebugMode) {
          debugPrint('VideoService: No videos found in HTML');
        }
        // If no videos found, return empty list
        return [];
      }
      if (kDebugMode) {
        debugPrint(
          'VideoService: HTML page returned status ${response.statusCode}',
        );
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('VideoService: HTML parsing error: $e');
      }
      // Return empty list on error
      return [];
    }
  }

  static Future<MotivationalVideo?> fetchVideoById(int id) async {
    try {
      final uri = Uri.parse('$_baseUrl/$id?_embed=true');
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> decoded =
            json.decode(utf8.decode(response.bodyBytes))
                as Map<String, dynamic>;
        return MotivationalVideo.fromWordPressJson(decoded);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<void> incrementViewCount(int id) async {
    try {
      // WordPress REST API doesn't have built-in view count increment
      // This would need to be handled via a custom endpoint or meta field update
      // For now, we'll just ignore errors silently
    } catch (_) {
      // Ignore errors
    }
  }

  static Future<void> clearCache() async {
    await CacheService.clear(_cacheKey);
  }

  // Helper method to check if a post has video content
  static bool _hasVideoContent(Map<String, dynamic> json) {
    // Check meta fields
    final meta = json['meta'] as Map<String, dynamic>? ?? {};
    final acf = json['acf'] as Map<String, dynamic>? ?? {};

    if (meta['video_url'] != null || acf['video_url'] != null) {
      return true;
    }

    // Check content for video URLs
    final contentObj = json['content'];
    final content = contentObj is Map
        ? (contentObj['rendered'] as String? ?? '')
        : (contentObj as String? ?? '');

    if (content.contains('video') ||
        content.contains('.mp4') ||
        content.contains('.webm') ||
        content.contains('youtube.com') ||
        content.contains('youtu.be') ||
        content.contains('vimeo.com')) {
      return true;
    }

    // Check embedded media
    if (json['_embedded'] != null) {
      final embedded = json['_embedded'] as Map<String, dynamic>;
      final featuredMedia = embedded['wp:featuredmedia'] as List?;
      if (featuredMedia != null && featuredMedia.isNotEmpty) {
        final media = featuredMedia[0] as Map<String, dynamic>;
        final mimeType = media['mime_type'] as String? ?? '';
        if (mimeType.startsWith('video/')) {
          return true;
        }
      }
    }

    return false;
  }
}
