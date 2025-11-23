import 'dart:io';
import '../models/video_item.dart' show VideoMetadata, VideoCompressionResult;
import '../services/video_helper_services.dart' show VideoMetadataService;
import '../services/video_compression_service.dart';
import '../constants/video_constants.dart';

// ============================================================================
// VIDEO UTILITIES - Validation and compression helpers
// ============================================================================

/// Utility for validating videos
class VideoValidator {
  /// Validate video file
  static Future<ValidationResult> validateVideo(String videoPath) async {
    final file = File(videoPath);
    
    // Check file exists
    if (!await file.exists()) {
      return ValidationResult(
        isValid: false,
        error: 'Video file does not exist',
      );
    }

    // Check file size
    final size = await file.length();
    if (size > VideoConstants.maxVideoSizeBytes) {
      return ValidationResult(
        isValid: false,
        error: 'Video file is too large (max ${VideoConstants.maxVideoSizeBytes / (1024 * 1024)}MB)',
      );
    }

    // Check format
    final extension = videoPath.split('.').last.toLowerCase();
    if (!VideoConstants.supportedFormats.contains(extension)) {
      return ValidationResult(
        isValid: false,
        error: 'Unsupported video format. Supported: ${VideoConstants.supportedFormats.join(", ")}',
      );
    }

    // Extract and validate metadata
    final metadata = await VideoMetadataService.extractMetadata(videoPath);
    if (metadata == null) {
      return ValidationResult(
        isValid: false,
        error: 'Could not read video metadata',
      );
    }

    // Check duration
    if (metadata.duration.inSeconds < VideoConstants.minVideoDurationSeconds) {
      return ValidationResult(
        isValid: false,
        error: 'Video is too short (min ${VideoConstants.minVideoDurationSeconds}s)',
      );
    }

    if (metadata.duration.inSeconds > VideoConstants.maxVideoDurationSeconds) {
      return ValidationResult(
        isValid: false,
        error: 'Video is too long (max ${VideoConstants.maxVideoDurationSeconds}s)',
      );
    }

    return ValidationResult(
      isValid: true,
      metadata: metadata,
    );
  }
}

class ValidationResult {
  final bool isValid;
  final String? error;
  final VideoMetadata? metadata;

  ValidationResult({
    required this.isValid,
    this.error,
    this.metadata,
  });
}

/// Utility wrapper for video compression
class VideoCompressor {
  /// Compress video to target size
  static Future<VideoCompressionResult?> compress({
    required String videoPath,
    int? targetSizeBytes,
    bool deleteOrigin = false,
  }) async {
    return await VideoCompressionService.compressVideo(
      videoPath: videoPath,
      targetSizeBytes: targetSizeBytes,
      deleteOrigin: deleteOrigin,
    );
  }

  /// Compress with progress callback
  static Future<VideoCompressionResult?> compressWithProgress({
    required String videoPath,
    required Function(double progress) onProgress,
  }) async {
    return await VideoCompressionService.compressVideoWithProgress(
      videoPath: videoPath,
      onProgress: onProgress,
    );
  }
}

