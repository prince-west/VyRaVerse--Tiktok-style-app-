import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/video_upload_state.dart';
import '../services/video_upload_service.dart';
import '../services/video_compression_service.dart';
import '../services/video_helper_services.dart' show ThumbnailGeneratorService, VideoMetadataService;
import '../models/video_item.dart';
import '../models/video_item.dart' show VideoMetadata;

/// Controller for managing video upload state and flow
class VideoUploadController extends ChangeNotifier {
  final VideoUploadService _uploadService = VideoUploadService();
  
  VideoUploadState _state = const VideoUploadState();
  VideoUploadState get state => _state;

  XFile? _selectedVideo;
  File? _compressedVideo;
  File? _thumbnail;
  VideoMetadata? _metadata;

  XFile? get selectedVideo => _selectedVideo;
  File? get compressedVideo => _compressedVideo;
  File? get thumbnail => _thumbnail;
  VideoMetadata? get metadata => _metadata;
  
  // Setter for thumbnail (used when recording provides it)
  set thumbnail(File? value) {
    _thumbnail = value;
    notifyListeners();
  }

  /// Set selected video
  Future<void> setVideo(XFile videoFile) async {
    _selectedVideo = videoFile;
    _updateState(_state.copyWith(status: UploadStatus.idle));
    
    // Extract metadata
    if (!kIsWeb) {
      _metadata = await VideoMetadataService.extractMetadata(videoFile.path);
      notifyListeners();
    }
  }

  /// Compress video
  Future<bool> compressVideo() async {
    if (_selectedVideo == null || kIsWeb) return false;

    _updateState(_state.copyWith(status: UploadStatus.compressing));
    
    final result = await VideoCompressionService.compressVideo(
      videoPath: _selectedVideo!.path,
    );

    if (result != null && result.success) {
      _compressedVideo = result.compressedFile;
      _updateState(_state.copyWith(status: UploadStatus.idle));
      return true;
    } else {
      _updateState(_state.copyWith(
        status: UploadStatus.error,
        errorMessage: result?.errorMessage ?? 'Compression failed',
      ));
      return false;
    }
  }

  /// Generate thumbnail
  Future<bool> generateThumbnail() async {
    if (_selectedVideo == null) return false;

    final videoPath = _compressedVideo?.path ?? _selectedVideo!.path;
    
    _updateState(_state.copyWith(status: UploadStatus.generatingThumbnail));
    
    _thumbnail = await ThumbnailGeneratorService.generateThumbnail(
      videoPath: videoPath,
    );

    if (_thumbnail != null) {
      _updateState(_state.copyWith(status: UploadStatus.idle));
      return true;
    } else {
      _updateState(_state.copyWith(
        status: UploadStatus.error,
        errorMessage: 'Thumbnail generation failed',
      ));
      return false;
    }
  }

  /// Upload video
  Future<VideoItem?> uploadVideo({
    required String description,
    String? privacy,
    List<String>? hashtags,
    String? location,
  }) async {
    if (_selectedVideo == null) {
      _updateState(_state.copyWith(
        status: UploadStatus.error,
        errorMessage: 'No video selected',
      ));
      return null;
    }

    final videoPath = _compressedVideo?.path ?? _selectedVideo!.path;

    return await _uploadService.uploadVideo(
      videoPath: videoPath,
      description: description,
      privacy: privacy,
      hashtags: hashtags,
      location: location,
      videoFile: kIsWeb ? _selectedVideo : null,
      thumbnailFile: _thumbnail,
      onProgress: _updateState,
    );
  }

  /// Reset state
  void reset() {
    _selectedVideo = null;
    _compressedVideo = null;
    _thumbnail = null;
    _metadata = null;
    _state = const VideoUploadState();
    notifyListeners();
  }

  void _updateState(VideoUploadState newState) {
    _state = newState;
    notifyListeners();
  }
}

