import 'dart:io';
import 'dart:typed_data';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as video_thumbnail;
import 'package:path_provider/path_provider.dart';
import '../models/video_item.dart' show VideoMetadata;

// ============================================================================
// VIDEO HELPER SERVICES - Permissions, metadata, thumbnails
// ============================================================================

/// Service for handling video-related permissions
class VideoPermissionService {
  /// Request camera permission
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Request microphone permission
  static Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Request storage permission (for reading videos from gallery)
  static Future<bool> requestStoragePermission() async {
    if (await Permission.storage.isGranted) {
      return true;
    }
    
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  /// Request all video recording permissions
  static Future<bool> requestVideoPermissions() async {
    final cameraGranted = await requestCameraPermission();
    final microphoneGranted = await requestMicrophonePermission();
    
    return cameraGranted && microphoneGranted;
  }

  /// Check if all video permissions are granted
  static Future<bool> hasVideoPermissions() async {
    final cameraGranted = await Permission.camera.isGranted;
    final microphoneGranted = await Permission.microphone.isGranted;
    
    return cameraGranted && microphoneGranted;
  }

  /// Open app settings if permissions are denied
  static Future<void> openSettings() async {
    await openAppSettings();
  }

  /// Check if permissions are permanently denied
  static Future<bool> arePermissionsPermanentlyDenied() async {
    final cameraStatus = await Permission.camera.status;
    final micStatus = await Permission.microphone.status;
    
    return cameraStatus.isPermanentlyDenied || micStatus.isPermanentlyDenied;
  }
}

/// Service for extracting video metadata
class VideoMetadataService {
  /// Extract metadata from video file
  static Future<VideoMetadata?> extractMetadata(String videoPath) async {
    try {
      final file = File(videoPath);
      if (!await file.exists()) {
        return null;
      }

      final controller = VideoPlayerController.file(file);
      await controller.initialize();

      final size = await file.length();
      final duration = controller.value.duration;
      final sizeInfo = controller.value.size;

      final metadata = VideoMetadata(
        duration: duration,
        fileSizeBytes: size,
        width: sizeInfo.width.toInt(),
        height: sizeInfo.height.toInt(),
        aspectRatio: sizeInfo.aspectRatio,
        format: _getFormatFromPath(videoPath),
        frameRate: controller.value.size.width / controller.value.size.height, // Approximation
        hasAudio: true, // Assume true, can be enhanced
      );

      controller.dispose();
      return metadata;
    } catch (e) {
      return null;
    }
  }

  /// Extract metadata from network video URL
  static Future<VideoMetadata?> extractMetadataFromUrl(String videoUrl) async {
    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await controller.initialize();

      final duration = controller.value.duration;
      final sizeInfo = controller.value.size;

      final metadata = VideoMetadata(
        duration: duration,
        fileSizeBytes: 0, // Unknown for network videos
        width: sizeInfo.width.toInt(),
        height: sizeInfo.height.toInt(),
        aspectRatio: sizeInfo.aspectRatio,
        format: _getFormatFromPath(videoUrl),
        frameRate: sizeInfo.width / sizeInfo.height,
        hasAudio: true,
      );

      controller.dispose();
      return metadata;
    } catch (e) {
      return null;
    }
  }

  static String _getFormatFromPath(String path) {
    final extension = path.split('.').last.toLowerCase();
    return extension;
  }

  /// Validate video meets requirements
  static Future<bool> validateVideo({
    required String videoPath,
    int? maxDurationSeconds,
    int? maxSizeBytes,
  }) async {
    final metadata = await extractMetadata(videoPath);
    if (metadata == null) return false;

    if (maxDurationSeconds != null) {
      if (metadata.duration.inSeconds > maxDurationSeconds) {
        return false;
      }
    }

    if (maxSizeBytes != null) {
      if (metadata.fileSizeBytes > maxSizeBytes) {
        return false;
      }
    }

    return true;
  }
}

/// Service for generating video thumbnails
class ThumbnailGeneratorService {
  /// Generate thumbnail at specific time
  static Future<File?> generateThumbnail({
    required String videoPath,
    int timeMs = 3000, // Default: 3 seconds
    int quality = 75,
    int? width,
    int? height,
  }) async {
    try {
      final thumbnailData = await video_thumbnail.VideoThumbnail.thumbnailData(
        video: videoPath,
        imageFormat: video_thumbnail.ImageFormat.JPEG,
        timeMs: timeMs,
        quality: quality,
        maxWidth: width ?? 0,
        maxHeight: height ?? 0,
      );

      if (thumbnailData == null) {
        return null;
      }

      final tempDir = await getTemporaryDirectory();
      final thumbnailFile = File(
        '${tempDir.path}/thumbnail_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      await thumbnailFile.writeAsBytes(thumbnailData);
      return thumbnailFile;
    } catch (e) {
      return null;
    }
  }

  /// Generate multiple thumbnails for video timeline
  static Future<List<File>> generateThumbnails({
    required String videoPath,
    int count = 10,
    int quality = 50,
  }) async {
    final thumbnails = <File>[];
    
    try {
      // Get video duration first
      final controller = VideoPlayerController.file(File(videoPath));
      await controller.initialize();
      final duration = controller.value.duration;
      controller.dispose();

      final interval = duration.inMilliseconds ~/ (count + 1);

      for (int i = 1; i <= count; i++) {
        final timeMs = interval * i;
        final thumbnail = await generateThumbnail(
          videoPath: videoPath,
          timeMs: timeMs,
          quality: quality,
        );
        
        if (thumbnail != null) {
          thumbnails.add(thumbnail);
        }
      }
    } catch (e) {
      // Return whatever thumbnails we managed to generate
    }

    return thumbnails;
  }

  /// Generate thumbnail as bytes
  static Future<Uint8List?> generateThumbnailBytes({
    required String videoPath,
    int timeMs = 3000,
    int quality = 75,
  }) async {
    try {
      return await video_thumbnail.VideoThumbnail.thumbnailData(
        video: videoPath,
        imageFormat: video_thumbnail.ImageFormat.JPEG,
        timeMs: timeMs,
        quality: quality,
      );
    } catch (e) {
      return null;
    }
  }
}

