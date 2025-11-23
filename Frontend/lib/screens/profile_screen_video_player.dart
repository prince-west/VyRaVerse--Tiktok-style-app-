import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../theme/vyra_theme.dart';
import '../models/video_item.dart';
import '../utils/video_url_helper.dart';

// ============================================================================
// FULL-SCREEN VIDEO PLAYER (TikTok-style)
// ============================================================================
class FullScreenVideoPlayer extends StatefulWidget {
  final List<VideoItem> videos;
  final int initialIndex;

  const FullScreenVideoPlayer({
    super.key,
    required this.videos,
    required this.initialIndex,
  });

  @override
  State<FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<FullScreenVideoPlayer> {
  late PageController _pageController;
  int _currentIndex = 0;
  final Map<String, VideoPlayerController> _controllers = {};
  final Map<String, ChewieController> _chewieControllers = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _pageController.addListener(_onPageChanged);
    _initializeVideo(widget.videos[_currentIndex]);
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    for (var controller in _chewieControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onPageChanged() {
    final newIndex = _pageController.page?.round() ?? _currentIndex;
    if (newIndex != _currentIndex && newIndex >= 0 && newIndex < widget.videos.length) {
      setState(() {
        _currentIndex = newIndex;
      });
      _pauseAllVideos();
      _initializeVideo(widget.videos[_currentIndex]);
    }
  }

  void _pauseAllVideos() {
    for (var chewie in _chewieControllers.values) {
      chewie.pause();
    }
  }

  Future<void> _initializeVideo(VideoItem video) async {
    if (_controllers.containsKey(video.id)) return;

    try {
      VideoPlayerController? controller;

      if (video.videoUrl != null && video.videoUrl!.isNotEmpty) {
        final videoUrl = VideoUrlHelper.normalizeVideoUrl(video.videoUrl);
        
        if (videoUrl == null) {
          return;
        }
        
        controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      } else if (video.isLocal && video.videoPath != null) {
        final file = File(video.videoPath!);
        if (await file.exists()) {
          controller = VideoPlayerController.file(file);
        }
      }

      if (controller == null) return;

      final videoController = controller!; // Non-null after check

      await videoController.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Video load timeout'),
      );

      if (!mounted) {
        videoController.dispose();
        return;
      }

      final chewieController = ChewieController(
        videoPlayerController: videoController,
        autoPlay: true,
        looping: true,
        showControls: false,
        aspectRatio: videoController.value.aspectRatio,
        errorBuilder: (context, errorMessage) => Container(
          color: VyRaTheme.primaryBlack,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Video unavailable',
                  style: TextStyle(color: VyRaTheme.textGrey),
                ),
              ],
            ),
          ),
        ),
      );

      if (mounted) {
        setState(() {
          _controllers[video.id] = videoController;
          _chewieControllers[video.id] = chewieController;
        });
        chewieController.play();
      }
    } catch (e) {
      debugPrint('Video init error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VyRaTheme.primaryBlack,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            physics: const BouncingScrollPhysics(),
            itemCount: widget.videos.length,
            itemBuilder: (ctx, index) {
              final video = widget.videos[index];
              final chewie = _chewieControllers[video.id];
              
              if (chewie == null) {
                return Container(
                  color: VyRaTheme.primaryBlack,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: VyRaTheme.primaryCyan,
                    ),
                  ),
                );
              }

              return Stack(
                fit: StackFit.expand,
                children: [
                  Center(
                    child: AspectRatio(
                      aspectRatio: chewie.aspectRatio ?? 16 / 9,
                      child: Chewie(controller: chewie),
                    ),
                  ),
                  // Video info overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '@${video.username}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (video.description.isNotEmpty)
                            Text(
                              video.description,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

