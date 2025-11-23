import 'dart:io';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../models/video_item.dart';
import '../services/video_cache_service.dart';

/// Manages multiple video player controllers for feed
class VideoPlayerControllerManager {
  final VideoCacheService _cacheService = VideoCacheService();
  final Map<String, VideoPlayerController> _controllers = {};
  final Map<String, ChewieController> _chewieControllers = {};
  final Set<String> _initializing = {};

  /// Initialize video controller
  Future<void> initializeVideo(VideoItem video) async {
    if (_controllers.containsKey(video.id) || _initializing.contains(video.id)) {
      return;
    }

    _initializing.add(video.id);

    try {
      VideoPlayerController? controller;

      if (video.isLocal && video.videoPath != null) {
        final file = File(video.videoPath!);
        if (await file.exists()) {
          controller = VideoPlayerController.file(file);
        }
      } else if (video.videoUrl != null && video.videoUrl!.isNotEmpty) {
        // Try cached file first
        final cachedFile = await _cacheService.getCachedFile(video.videoUrl!);
        if (cachedFile != null && await cachedFile.exists()) {
          controller = VideoPlayerController.file(cachedFile);
        } else {
          controller = VideoPlayerController.networkUrl(
            Uri.parse(video.videoUrl!),
          );
          // Preload in background
          _cacheService.getCachedFile(video.videoUrl!);
        }
      }

      if (controller != null) {
        await controller.initialize();

        final chewieController = ChewieController(
          videoPlayerController: controller,
          autoPlay: false,
          looping: true,
          showControls: false,
          aspectRatio: controller.value.aspectRatio,
        );

        _controllers[video.id] = controller;
        _chewieControllers[video.id] = chewieController;
      }
    } catch (e) {
      // Handle error
    } finally {
      _initializing.remove(video.id);
    }
  }

  /// Get controller for video
  ChewieController? getController(String videoId) {
    return _chewieControllers[videoId];
  }

  /// Play video
  void playVideo(String videoId) {
    _chewieControllers[videoId]?.play();
  }

  /// Pause video
  void pauseVideo(String videoId) {
    _chewieControllers[videoId]?.pause();
  }

  /// Pause all videos
  void pauseAll() {
    for (var controller in _chewieControllers.values) {
      controller.pause();
    }
  }

  /// Dispose controller
  void disposeController(String videoId) {
    _controllers[videoId]?.dispose();
    _chewieControllers[videoId]?.dispose();
    _controllers.remove(videoId);
    _chewieControllers.remove(videoId);
  }

  /// Dispose all controllers
  void disposeAll() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    for (var controller in _chewieControllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    _chewieControllers.clear();
  }

  /// Preload videos
  Future<void> preloadVideos(List<VideoItem> videos) async {
    final urls = videos
        .where((v) => v.videoUrl != null && v.videoUrl!.isNotEmpty)
        .map((v) => v.videoUrl!)
        .toList();
    
    await _cacheService.preloadVideos(urls);
  }
}

