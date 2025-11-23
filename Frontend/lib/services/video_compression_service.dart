import 'dart:io';
import 'package:video_compress/video_compress.dart';
import 'package:video_player/video_player.dart';
import '../models/video_item.dart' show VideoCompressionResult;

/// Service for video compression
class VideoCompressionService {
  static const int maxVideoSizeBytes = 20 * 1024 * 1024; // 20MB
  static const int maxVideoDurationSeconds = 60;

  /// Compress video to target size
  static Future<VideoCompressionResult?> compressVideo({
    required String videoPath,
    VideoQuality quality = VideoQuality.MediumQuality,
    int? targetSizeBytes,
    bool deleteOrigin = false,
  }) async {
    try {
      final file = File(videoPath);
      if (!await file.exists()) {
        throw Exception('Video file does not exist');
      }

      final originalSize = await file.length();
      final targetSize = targetSizeBytes ?? maxVideoSizeBytes;

      // First compression attempt
      var compressedVideo = await VideoCompress.compressVideo(
        videoPath,
        quality: quality,
        deleteOrigin: false,
        includeAudio: true,
      );

      if (compressedVideo == null) {
        throw Exception('Compression failed');
      }

      var compressedFile = compressedVideo.file;
      if (compressedFile == null) {
        throw Exception('Compressed file is null');
      }

      var compressedSize = await compressedFile.length();

      // If still too large, compress again with lower quality
      if (compressedSize > targetSize && compressedVideo.path != null) {
        final moreCompressed = await VideoCompress.compressVideo(
          compressedVideo.path!,
          quality: VideoQuality.LowQuality,
          deleteOrigin: true,
          includeAudio: true,
        );

        if (moreCompressed?.file != null) {
          final newFile = moreCompressed!.file;
          if (newFile != null) {
            compressedFile = newFile;
            compressedSize = await compressedFile.length();
          }
        }
      }
      
      // Ensure compressedFile is not null
      if (compressedFile == null) {
        throw Exception('Final compressed file is null');
      }

      // Get video duration
      final controller = VideoPlayerController.file(compressedFile);
      await controller.initialize();
      final duration = controller.value.duration;
      controller.dispose();

      // Delete original if requested
      if (deleteOrigin && file.path != compressedFile.path) {
        try {
          await file.delete();
        } catch (e) {
          // Ignore deletion errors
        }
      }

      return VideoCompressionResult(
        compressedFile: compressedFile,
        path: compressedFile.path,
        originalSizeBytes: originalSize,
        compressedSizeBytes: compressedSize,
        compressionRatio: compressedSize / originalSize,
        duration: duration,
        success: true,
      );
    } catch (e) {
      return VideoCompressionResult(
        compressedFile: File(videoPath),
        path: videoPath,
        originalSizeBytes: 0,
        compressedSizeBytes: 0,
        compressionRatio: 1.0,
        duration: Duration.zero,
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Compress video with progress callback
  static Future<VideoCompressionResult?> compressVideoWithProgress({
    required String videoPath,
    VideoQuality quality = VideoQuality.MediumQuality,
    required Function(double progress) onProgress,
  }) async {
    // Note: video_compress doesn't support progress callbacks directly
    // This is a placeholder for future implementation
    onProgress(0.0);
    
    final result = await compressVideo(
      videoPath: videoPath,
      quality: quality,
    );
    
    onProgress(1.0);
    return result;
  }
}

