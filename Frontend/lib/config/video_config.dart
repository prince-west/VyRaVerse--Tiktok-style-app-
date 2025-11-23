import '../constants/video_constants.dart';

/// Video configuration settings (deprecated - use VideoConstants directly)
/// Kept for backward compatibility
@Deprecated('Use VideoConstants directly')
class VideoConfig {
  // Upload settings
  static const int maxVideoSizeBytes = VideoConstants.maxVideoSizeBytes;
  static const int maxVideoDurationSeconds = VideoConstants.maxVideoDurationSeconds;
  static const int minVideoDurationSeconds = VideoConstants.minVideoDurationSeconds;
  
  // Compression settings
  static const int targetVideoSizeBytes = VideoConstants.targetVideoSizeBytes;
  static const bool autoCompress = true;
  
  // Thumbnail settings
  static const int thumbnailTimeMs = VideoConstants.thumbnailTimeMs;
  static const int thumbnailQuality = VideoConstants.thumbnailQuality;
  
  // Cache settings
  static const int maxCacheSizeBytes = VideoConstants.maxCacheSizeBytes;
  static const int cacheMaxAgeDays = VideoConstants.cacheMaxAgeDays;
  static const bool enablePreloading = true;
  static const int preloadNextCount = VideoConstants.preloadNextCount;
  static const int preloadPreviousCount = VideoConstants.preloadPreviousCount;
  
  // Player settings
  static const int videoInitTimeoutSeconds = VideoConstants.videoInitTimeoutSeconds;
  static const double visibilityThreshold = VideoConstants.visibilityThreshold;
  static const bool autoPlay = true;
  static const bool loopVideos = true;
  
  // Upload settings
  static const int uploadTimeoutSeconds = VideoConstants.uploadTimeoutSeconds;
  static const int maxRetryAttempts = VideoConstants.maxRetryAttempts;
}

