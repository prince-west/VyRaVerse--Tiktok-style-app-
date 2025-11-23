import 'package:flutter/widgets.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:video_player/video_player.dart';

// ============================================================================
// VIDEO MIXINS - Lifecycle and visibility management
// ============================================================================

/// Mixin for handling video lifecycle (pause on background, resume on foreground)
mixin VideoLifecycleMixin<T extends StatefulWidget> on State<T>, WidgetsBindingObserver {
  final Map<String, VideoPlayerController> _videoControllers = {};
  final Map<String, bool> _wasPlaying = {};

  void registerVideoController(String id, VideoPlayerController controller) {
    _videoControllers[id] = controller;
  }

  void unregisterVideoController(String id) {
    _videoControllers.remove(id);
    _wasPlaying.remove(id);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // Pause all videos
        for (var entry in _videoControllers.entries) {
          if (entry.value.value.isPlaying) {
            _wasPlaying[entry.key] = true;
            entry.value.pause();
          } else {
            _wasPlaying[entry.key] = false;
          }
        }
        break;
      case AppLifecycleState.resumed:
        // Resume videos that were playing
        for (var entry in _videoControllers.entries) {
          if (_wasPlaying[entry.key] == true) {
            entry.value.play();
          }
        }
        break;
      default:
        break;
    }
  }
}

/// Mixin for handling video visibility (pause when not visible)
mixin VideoVisibilityMixin {
  final Map<String, VideoPlayerController> _videoControllers = {};
  final Map<String, bool> _isVisible = {};

  void registerVideoController(String id, VideoPlayerController controller) {
    _videoControllers[id] = controller;
  }

  void unregisterVideoController(String id) {
    _videoControllers.remove(id);
    _isVisible.remove(id);
  }

  void onVisibilityChanged(String videoId, VisibilityInfo info) {
    final threshold = 0.7; // 70% visible
    final isVisible = info.visibleFraction >= threshold;
    
    _isVisible[videoId] = isVisible;
    final controller = _videoControllers[videoId];
    
    if (controller != null) {
      if (isVisible && !controller.value.isPlaying) {
        controller.play();
      } else if (!isVisible && controller.value.isPlaying) {
        controller.pause();
      }
    }
  }

  VisibilityDetector createVisibilityDetector({
    required String videoId,
    required Widget child,
  }) {
    return VisibilityDetector(
      key: Key('video_$videoId'),
      onVisibilityChanged: (info) => onVisibilityChanged(videoId, info),
      child: child,
    );
  }
}

