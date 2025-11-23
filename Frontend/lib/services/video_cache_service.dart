import 'dart:io';
import 'dart:async';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

/// Video caching service with LRU cache strategy
/// Maximum cache size: 500MB
/// Preloads videos for smooth playback
class VideoCacheService {
  static final VideoCacheService _instance = VideoCacheService._internal();
  factory VideoCacheService() => _instance;
  VideoCacheService._internal();

  static const int maxCacheSize = 500 * 1024 * 1024; // 500MB
  static const int maxCacheAge = 30; // 30 days
  
  late DefaultCacheManager _cacheManager;
  final Set<String> _preloadingUrls = {};
  final Map<String, File?> _cachedFiles = {};

  /// Initialize cache manager
  void initialize() {
    _cacheManager = DefaultCacheManager();
  }

  /// Get cached file for video URL
  /// Returns cached file if available, otherwise downloads and caches
  Future<File?> getCachedFile(String videoUrl) async {
    if (videoUrl.isEmpty) return null;
    
    try {
      // Check if already cached in memory
      if (_cachedFiles.containsKey(videoUrl) && _cachedFiles[videoUrl] != null) {
        final file = _cachedFiles[videoUrl]!;
        if (await file.exists()) {
          return file;
        }
      }

      // Get from cache manager
      final file = await _cacheManager.getSingleFile(
        videoUrl,
        headers: {'Cache-Control': 'max-age=31536000'},
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Cache download timeout');
        },
      );

      // Store in memory cache
      _cachedFiles[videoUrl] = file;
      
      // Cleanup old cache if needed
      _cleanupCacheIfNeeded();
      
      return file;
    } catch (e) {
      debugPrint('Error caching video: $e');
      return null;
    }
  }

  /// Preload multiple videos
  Future<void> preloadVideos(List<String> videoUrls) async {
    final urlsToPreload = videoUrls
        .where((url) => url.isNotEmpty && !_preloadingUrls.contains(url))
        .take(3) // Limit to 3 videos at a time
        .toList();

    for (final url in urlsToPreload) {
      _preloadingUrls.add(url);
      getCachedFile(url).then((_) {
        _preloadingUrls.remove(url);
      }).catchError((e) {
        debugPrint('Error preloading video $url: $e');
        _preloadingUrls.remove(url);
      });
    }
  }

  /// Preload next videos for smooth scrolling
  Future<void> preloadNextVideos(List<String> allUrls, int currentIndex) async {
    final preloadUrls = <String>[];
    
    // Preload next 2 videos
    for (int i = 1; i <= 2 && (currentIndex + i) < allUrls.length; i++) {
      preloadUrls.add(allUrls[currentIndex + i]);
    }
    
    // Preload previous 1 video
    if (currentIndex > 0) {
      preloadUrls.add(allUrls[currentIndex - 1]);
    }
    
    await preloadVideos(preloadUrls);
  }

  /// Cleanup cache if size exceeds limit
  Future<void> _cleanupCacheIfNeeded() async {
    try {
      final cacheDir = await _getCacheDirectory();
      if (cacheDir == null) return;

      final files = cacheDir.listSync(recursive: true);
      int totalSize = 0;
      final fileInfo = <File, int>{}; // File -> size

      for (final file in files) {
        if (file is File) {
          final size = await file.length();
          totalSize += size;
          fileInfo[file] = size;
        }
      }

      if (totalSize > maxCacheSize) {
        // Sort by modification time (oldest first)
        final sortedFiles = fileInfo.entries.toList()
          ..sort((a, b) => a.key.lastModifiedSync().compareTo(b.key.lastModifiedSync()));

        // Delete oldest files until under limit
        int deletedSize = 0;
        for (final entry in sortedFiles) {
          if (totalSize - deletedSize <= maxCacheSize * 0.8) break; // Keep 80% of limit
          
          try {
            await entry.key.delete();
            deletedSize += entry.value;
            _cachedFiles.removeWhere((url, file) => file?.path == entry.key.path);
          } catch (e) {
            debugPrint('Error deleting cache file: $e');
          }
        }
        
        debugPrint('Cleaned up ${deletedSize ~/ (1024 * 1024)}MB from video cache');
      }
    } catch (e) {
      debugPrint('Error cleaning cache: $e');
    }
  }

  /// Get cache directory
  Future<Directory?> _getCacheDirectory() async {
    try {
      if (kIsWeb) return null;
      final cacheDir = await getTemporaryDirectory();
      return Directory('${cacheDir.path}/video_cache');
    } catch (e) {
      debugPrint('Error getting cache directory: $e');
      return null;
    }
  }

  /// Clear all cached videos
  Future<void> clearCache() async {
    try {
      await _cacheManager.emptyCache();
      _cachedFiles.clear();
      _preloadingUrls.clear();
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  /// Get cache size in MB
  Future<double> getCacheSize() async {
    try {
      final cacheDir = await _getCacheDirectory();
      if (cacheDir == null) return 0;

      int totalSize = 0;
      await for (final entity in cacheDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }

      return totalSize / (1024 * 1024); // Convert to MB
    } catch (e) {
      debugPrint('Error getting cache size: $e');
      return 0;
    }
  }
}

