import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import '../theme/vyra_theme.dart';
import '../models/video_item.dart';
import 'video_action_bar.dart';
import 'package:flutter_animate/flutter_animate.dart';

class VideoPlayerWidget extends StatefulWidget {
  final VideoItem video;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onBuzz;
  final VoidCallback onShare;
  final VoidCallback? onBoost;
  final VoidCallback? onProfileTap;
  final bool isLiked;
  final bool isBuzzed;
  final AnimationController? heartController;
  final AnimationController? shareController;

  const VideoPlayerWidget({
    super.key,
    required this.video,
    required this.onLike,
    required this.onComment,
    required this.onBuzz,
    required this.onShare,
    this.onBoost,
    this.onProfileTap,
    this.isLiked = false,
    this.isBuzzed = false,
    this.heartController,
    this.shareController,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget>
    with TickerProviderStateMixin {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _showPlayPauseIcon = false;
  bool _showLikeAnimation = false;
  late AnimationController _playPauseController;
  late AnimationController _doubleTapLikeController;
  late Animation<double> _playPauseAnimation;
  late Animation<double> _doubleTapLikeAnimation;
  late Animation<double> _heartScaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _playPauseController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _doubleTapLikeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _playPauseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _playPauseController, curve: Curves.easeInOut),
    );
    _doubleTapLikeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _doubleTapLikeController, curve: Curves.elasticOut),
    );
    _heartScaleAnimation = Tween<double>(begin: 0.0, end: 1.2).animate(
      CurvedAnimation(parent: _doubleTapLikeController, curve: Curves.elasticOut),
    );
  }

  Future<void> _initializeVideo() async {
    VideoPlayerController? controller;
    
    if (widget.video.isLocal && widget.video.videoPath != null) {
      try {
        final file = File(widget.video.videoPath!);
        if (await file.exists()) {
          controller = VideoPlayerController.file(file);
        }
      } catch (e) {
        debugPrint('Error creating file controller: $e');
      }
    } else if (widget.video.videoUrl != null && widget.video.videoUrl!.isNotEmpty) {
      try {
        controller = VideoPlayerController.networkUrl(
          Uri.parse(widget.video.videoUrl!),
        );
      } catch (e) {
        debugPrint('Error creating network controller: $e');
      }
    }

    if (controller != null) {
      try {
        await controller.initialize().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException('Video initialization timeout');
          },
        );
        if (mounted) {
          setState(() {
            _controller = controller;
            _isInitialized = true;
          });
          // Ensure video plays
          await _controller!.play();
          _controller!.setLooping(true);
          // Make sure it's actually playing
          if (!_controller!.value.isPlaying) {
            await _controller!.play();
          }
        }
      } catch (e) {
        debugPrint('Video initialization error: $e');
        // Handle initialization error
        if (mounted) {
          setState(() => _isInitialized = true);
        }
        controller.dispose();
      }
    } else {
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    }
  }

  void _handleSingleTap() {
    if (_controller != null) {
      setState(() {
        if (_controller!.value.isPlaying) {
          _controller!.pause();
          _showPlayPauseIcon = true;
        } else {
          _controller!.play();
          _showPlayPauseIcon = true;
        }
      });

      _playPauseController.forward().then((_) {
        _playPauseController.reverse();
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            setState(() => _showPlayPauseIcon = false);
          }
        });
      });
    }
  }

  void _handleDoubleTap() {
    setState(() => _showLikeAnimation = true);
    widget.onLike();
    _doubleTapLikeController.forward().then((_) {
      _doubleTapLikeController.reverse();
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() => _showLikeAnimation = false);
        }
      });
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    _playPauseController.dispose();
    _doubleTapLikeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleSingleTap,
      onDoubleTap: _handleDoubleTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _isInitialized && _controller != null
              ? SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller!.value.size.width,
                      height: _controller!.value.size.height,
                      child: VideoPlayer(_controller!),
                    ),
                  ),
                )
              : Container(
                  color: VyRaTheme.primaryBlack,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: VyRaTheme.primaryCyan,
                    ),
                  ),
                ),
          // Volume control
          Positioned(
            top: 16,
            right: 16,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _controller!.setVolume(
                    _controller!.value.volume > 0 ? 0 : 1,
                  );
                });
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                  boxShadow: VyRaTheme.neonGlow,
                ),
                child: Icon(
                  (_controller?.value.volume ?? 0) > 0
                      ? Icons.volume_up
                      : Icons.volume_off,
                  color: VyRaTheme.textWhite,
                  size: 20,
                ),
              ),
            ),
          ),
          // Play/Pause overlay
          if (_showPlayPauseIcon)
            Center(
              child: AnimatedBuilder(
                animation: _playPauseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _playPauseAnimation.value,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                        boxShadow: VyRaTheme.neonGlow,
                      ),
                      child: Icon(
                        _controller?.value.isPlaying == true
                            ? Icons.play_arrow
                            : Icons.pause,
                        color: VyRaTheme.textWhite,
                        size: 32,
                      ),
                    ),
                  );
                },
              ),
            ),
          // Double tap like animation
          if (_showLikeAnimation)
            Center(
              child: AnimatedBuilder(
                animation: _doubleTapLikeAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _heartScaleAnimation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.8),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.red,
                        size: 100,
                      ),
                    ),
                  );
                },
              ),
            ),
          // Video info overlay
          Positioned(
            bottom: 70,
            left: 16,
            right: 90,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: widget.onProfileTap,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: VyRaTheme.primaryCyan,
                            width: 1.5,
                          ),
                          boxShadow: VyRaTheme.neonGlow,
                        ),
                        child: ClipOval(
                          child: widget.video.thumbnailUrl != null
                              ? Image.network(
                                  widget.video.thumbnailUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildDefaultAvatar(),
                                )
                              : _buildDefaultAvatar(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: widget.onProfileTap,
                            child: Text(
                              '@${widget.video.username}',
                              style: const TextStyle(
                                color: VyRaTheme.textWhite,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.video.description,
                            style: const TextStyle(
                              color: VyRaTheme.textWhite,
                              fontSize: 14,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (widget.video.hashtags.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: widget.video.hashtags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: VyRaTheme.primaryCyan.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: VyRaTheme.primaryCyan,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '#$tag',
                          style: const TextStyle(
                            color: VyRaTheme.primaryCyan,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
          // Action buttons
          Positioned(
            bottom: 70,
            right: 16,
            child: VideoActionBar(
              likes: widget.video.likes,
              comments: widget.video.comments,
              buzz: widget.video.buzzCount,
              shares: widget.video.shares,
              isLiked: widget.isLiked,
              isBuzzed: widget.isBuzzed,
              onLike: widget.onLike,
              onComment: widget.onComment,
              onBuzz: widget.onBuzz,
              onShare: widget.onShare,
              onBoost: widget.onBoost,
              boostScore: widget.video.boostScore,
              onProfileTap: widget.onProfileTap,
              profileImageUrl: widget.video.thumbnailUrl,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildDefaultAvatar() {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: VyRaTheme.mediumGrey,
      ),
      child: const Icon(
        Icons.person,
        color: VyRaTheme.textWhite,
        size: 24,
      ),
    );
  }
}

