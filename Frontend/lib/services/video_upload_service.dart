import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../models/video_item.dart';
import '../models/video_upload_state.dart';

/// Service for handling video uploads with progress tracking
class VideoUploadService {
  final ApiService _apiService = ApiService();

  /// Upload video with progress tracking
  Future<VideoItem?> uploadVideo({
    required String videoPath,
    required String description,
    String? privacy,
    List<String>? hashtags,
    String? location,
    XFile? videoFile, // For web
    File? thumbnailFile,
    required Function(VideoUploadState) onProgress,
  }) async {
    try {
      // Start upload
      onProgress(VideoUploadState(
        status: UploadStatus.uploading,
        progress: 0.0,
      ));

      VideoItem? uploadedVideo;

      if (kIsWeb && videoFile != null) {
        // Web upload with progress tracking
        final bytes = await videoFile.readAsBytes();
        final totalBytes = bytes.length;

        uploadedVideo = await _apiService.uploadVideo(
          description: description,
          videoPath: videoPath,
          privacy: privacy,
          hashtags: hashtags,
          videoBytes: bytes,
          fileName: videoFile.name,
          onUploadProgress: (sent, total) {
            final progress = total > 0 ? sent / total : 0.0;
            onProgress(VideoUploadState(
              status: UploadStatus.uploading,
              progress: progress.clamp(0.0, 1.0),
              bytesUploaded: sent,
              totalBytes: total,
            ));
          },
        );
      } else if (!kIsWeb) {
        // Mobile upload with progress tracking
        final file = File(videoPath);
        final totalBytes = await file.length();
        
        uploadedVideo = await _apiService.uploadVideo(
          description: description,
          videoPath: videoPath,
          privacy: privacy,
          hashtags: hashtags,
          onUploadProgress: (sent, total) {
            final progress = total > 0 ? sent / total : 0.0;
            onProgress(VideoUploadState(
              status: UploadStatus.uploading,
              progress: progress.clamp(0.0, 1.0),
              bytesUploaded: sent,
              totalBytes: total,
            ));
          },
        );
      }

      if (uploadedVideo == null) {
        throw Exception('Upload failed - no response from server');
      }

      // Upload complete
      onProgress(VideoUploadState(
        status: UploadStatus.completed,
        progress: 1.0,
        videoUrl: uploadedVideo.videoUrl,
        thumbnailUrl: uploadedVideo.thumbnailUrl,
      ));

      return uploadedVideo;
    } catch (e) {
      onProgress(VideoUploadState(
        status: UploadStatus.error,
        errorMessage: e.toString(),
      ));
      return null;
    }
  }

  /// Cancel upload (if supported by backend)
  Future<void> cancelUpload(String? uploadId) async {
    // Implementation depends on backend support for resumable uploads
  }
}

