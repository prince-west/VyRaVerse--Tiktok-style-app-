import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

/// Helper utility for normalizing and building video URLs consistently
class VideoUrlHelper {
  /// Normalize a video URL to ensure it's absolute
  /// Handles relative URLs, null values, and invalid formats
  static String? normalizeVideoUrl(String? videoUrl) {
    if (videoUrl == null || videoUrl.isEmpty) {
      debugPrint('VideoUrlHelper: videoUrl is null or empty');
      return null;
    }

    String url = videoUrl.trim();

    // Skip invalid URLs
    if (url == 'null' || url.toLowerCase() == 'none' || url.isEmpty) {
      debugPrint('VideoUrlHelper: Invalid URL format: $url');
      return null;
    }

    // If already absolute, return as-is
    if (url.startsWith('http://') || url.startsWith('https://')) {
      debugPrint('VideoUrlHelper: Already absolute URL: $url');
      return url;
    }

    // Handle relative URLs
    // Backend might return URLs like:
    // - /media/videos/file.mp4 (full path)
    // - /videos/file.mp4 (relative to media)
    // - videos/file.mp4 (no leading slash)
    String finalUrl;
    
    if (url.startsWith('/media/')) {
      // Already has /media/ prefix, use base URL without /media
      final base = AppConfig.mediaUrl.replaceAll('/media', '');
      finalUrl = '$base$url';
    } else if (url.startsWith('/videos/')) {
      // Has /videos/ prefix, add /media before it
      finalUrl = '${AppConfig.mediaUrl}$url';
    } else if (url.startsWith('/')) {
      // Starts with / but not /media/ or /videos/, try with /media prefix
      finalUrl = '${AppConfig.mediaUrl}$url';
    } else {
      // No leading slash, assume it's a video file and add /media/videos/
      if (url.contains('/')) {
        // Has path separators, just prepend media URL
        finalUrl = '${AppConfig.mediaUrl}/$url';
      } else {
        // Just filename, assume it's in /media/videos/
        finalUrl = '${AppConfig.mediaUrl}/videos/$url';
      }
    }

    debugPrint('VideoUrlHelper: Normalized "$videoUrl" -> "$finalUrl"');
    return finalUrl;
  }

  /// Check if a video URL is valid
  static bool isValidVideoUrl(String? videoUrl) {
    if (videoUrl == null || videoUrl.isEmpty) {
      return false;
    }

    final url = videoUrl.trim();
    return url != 'null' && 
           url.toLowerCase() != 'none' && 
           (url.startsWith('http://') || url.startsWith('https://') || url.startsWith('/'));
  }
}

