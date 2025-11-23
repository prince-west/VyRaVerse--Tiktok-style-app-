import 'package:flutter/foundation.dart';
import '../models/video_item.dart';
import '../repositories/video_repository.dart';
import 'video_player_controller_manager.dart';

// Make controller manager accessible
extension VideoFeedControllerExtension on VideoFeedController {
  VideoPlayerControllerManager get controllerManager => _controllerManager;
}

/// Controller for managing video feed state
class VideoFeedController extends ChangeNotifier {
  final VideoRepository _repository = VideoRepository();
  final VideoPlayerControllerManager _controllerManager = VideoPlayerControllerManager();

  List<VideoItem> _videos = [];
  int _currentIndex = 0;
  bool _isLoading = false;
  bool _hasMore = true;

  List<VideoItem> get videos => _videos;
  int get currentIndex => _currentIndex;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;

  /// Load videos
  Future<void> loadVideos({bool refresh = false}) async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      final newVideos = await _repository.getVideos();
      
      if (refresh) {
        _videos = newVideos;
      } else {
        _videos.addAll(newVideos);
      }

      // Preload first few videos
      if (_videos.isNotEmpty) {
        await _controllerManager.preloadVideos(_videos.take(3).toList());
      }

      _hasMore = newVideos.isNotEmpty;
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load recommended videos
  Future<void> loadRecommended() async {
    _isLoading = true;
    notifyListeners();

    try {
      _videos = await _repository.getRecommendedVideos();
      
      if (_videos.isNotEmpty) {
        await _controllerManager.preloadVideos(_videos.take(3).toList());
      }
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Set current video index
  void setCurrentIndex(int index) {
    if (index < 0 || index >= _videos.length) return;

    _currentIndex = index;
    
    // Pause all videos
    _controllerManager.pauseAll();
    
    // Play current video
    final currentVideo = _videos[index];
    _controllerManager.playVideo(currentVideo.id);
    
    // Preload adjacent videos
    _preloadAdjacentVideos(index);
    
    notifyListeners();
  }

  /// Preload adjacent videos
  void _preloadAdjacentVideos(int currentIndex) {
    final videosToPreload = <VideoItem>[];
    
    // Preload next 2 videos
    for (int i = 1; i <= 2 && (currentIndex + i) < _videos.length; i++) {
      videosToPreload.add(_videos[currentIndex + i]);
    }
    
    // Preload previous 1 video
    if (currentIndex > 0) {
      videosToPreload.add(_videos[currentIndex - 1]);
    }
    
    _controllerManager.preloadVideos(videosToPreload);
  }

  /// Initialize video controller
  Future<void> initializeVideo(VideoItem video) async {
    await _controllerManager.initializeVideo(video);
  }

  /// Like video
  Future<void> likeVideo(String videoId) async {
    final success = await _repository.likeVideo(videoId);
    if (success) {
      final index = _videos.indexWhere((v) => v.id == videoId);
      if (index != -1) {
        _videos[index] = _videos[index].copyWith(
          likes: _videos[index].likes + 1,
        );
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _controllerManager.disposeAll();
    super.dispose();
  }
}

