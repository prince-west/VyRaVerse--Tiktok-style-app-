/// Video constants and configuration
class VideoConstants {
  // Video limits
  static const int maxVideoDurationSeconds = 60;
  static const int maxVideoSizeBytes = 20 * 1024 * 1024; // 20MB
  static const int minVideoDurationSeconds = 3;
  
  // Video formats
  static const List<String> supportedFormats = ['mp4', 'mov', 'avi', 'mkv'];
  
  // Compression
  static const int targetVideoSizeBytes = 20 * 1024 * 1024; // 20MB
  static const bool autoCompress = true;
  static const int thumbnailTimeMs = 3000; // 3 seconds
  static const int thumbnailQuality = 75;
  
  // Cache
  static const int maxCacheSizeBytes = 500 * 1024 * 1024; // 500MB
  static const int cacheMaxAgeDays = 30;
  static const bool enablePreloading = true;
  static const int preloadNextCount = 2;
  static const int preloadPreviousCount = 1;
  
  // Player
  static const int videoInitTimeoutSeconds = 10;
  static const double visibilityThreshold = 0.7; // 70% visible to play
  static const bool autoPlay = true;
  static const bool loopVideos = true;
  
  // Upload
  static const int uploadTimeoutSeconds = 300; // 5 minutes
  static const int maxRetryAttempts = 3;
}

// Alias for backward compatibility
class VideoConfig {
  static const int maxVideoSizeBytes = VideoConstants.maxVideoSizeBytes;
  static const int maxVideoDurationSeconds = VideoConstants.maxVideoDurationSeconds;
  static const int minVideoDurationSeconds = VideoConstants.minVideoDurationSeconds;
  static const int targetVideoSizeBytes = VideoConstants.targetVideoSizeBytes;
  static const bool autoCompress = VideoConstants.autoCompress;
  static const int thumbnailTimeMs = VideoConstants.thumbnailTimeMs;
  static const int thumbnailQuality = VideoConstants.thumbnailQuality;
  static const int maxCacheSizeBytes = VideoConstants.maxCacheSizeBytes;
  static const int cacheMaxAgeDays = VideoConstants.cacheMaxAgeDays;
  static const bool enablePreloading = VideoConstants.enablePreloading;
  static const int preloadNextCount = VideoConstants.preloadNextCount;
  static const int preloadPreviousCount = VideoConstants.preloadPreviousCount;
  static const int videoInitTimeoutSeconds = VideoConstants.videoInitTimeoutSeconds;
  static const double visibilityThreshold = VideoConstants.visibilityThreshold;
  static const bool autoPlay = VideoConstants.autoPlay;
  static const bool loopVideos = VideoConstants.loopVideos;
  static const int uploadTimeoutSeconds = VideoConstants.uploadTimeoutSeconds;
  static const int maxRetryAttempts = VideoConstants.maxRetryAttempts;
}

