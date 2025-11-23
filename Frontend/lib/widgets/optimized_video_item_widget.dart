import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:http/http.dart' as http;
import '../theme/vyra_theme.dart';
import '../models/video_item.dart';
import '../services/video_cache_service.dart';
import '../utils/video_url_helper.dart';
import '../config/app_config.dart';
import 'video_action_bar.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Optimized video item widget with proper lifecycle management
/// Uses cached video player and visibility detection for performance
class OptimizedVideoItemWidget extends StatefulWidget {
  final VideoItem video;
  final int pageIndex;
  final int currentPageIndex;
  final bool isPaused;
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

  const OptimizedVideoItemWidget({
    super.key,
    required this.video,
    required this.pageIndex,
    required this.currentPageIndex,
    this.isPaused = false,
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
  State<OptimizedVideoItemWidget> createState() => _OptimizedVideoItemWidgetState();
}

class _OptimizedVideoItemWidgetState extends State<OptimizedVideoItemWidget>
    with TickerProviderStateMixin {
  VideoPlayerController? _controller;
  ChewieController? _chewieController;
  final VideoCacheService _cacheService = VideoCacheService();
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _showPlayPauseIcon = false;
  bool _showLikeAnimation = false;
  bool _isDisposed = false;
  bool _isImage = false; // Track if content is an image
  
  late AnimationController _playPauseController;
  late AnimationController _doubleTapLikeController;
  late Animation<double> _playPauseAnimation;
  late Animation<double> _doubleTapLikeAnimation;
  late Animation<double> _heartScaleAnimation;
  Timer? _singleTapTimer;
  DateTime? _lastTapTime;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializePlayer();
  }

  void _initializeAnimations() {
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

  Future<void> _initializePlayer() async {
    if (_isDisposed || !mounted) return;

    try {
      VideoPlayerController? controller;

      // Validate video URL first
      debugPrint('OptimizedVideoItemWidget: Initializing video ${widget.video.id}');
      debugPrint('  - videoUrl: ${widget.video.videoUrl}');
      debugPrint('  - isLocal: ${widget.video.isLocal}');
      debugPrint('  - videoPath: ${widget.video.videoPath}');
      debugPrint('  - thumbnailUrl: ${widget.video.thumbnailUrl}');
      
      String? videoUrlToUse = widget.video.videoUrl;
      
      // Check if file is an image by extension or URL
      final url = videoUrlToUse ?? '';
      final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'];
      _isImage = imageExtensions.any((ext) => url.toLowerCase().contains(ext));
      
      // If it's an image, don't try to load as video
      if (_isImage) {
        debugPrint('OptimizedVideoItemWidget: Detected image file, displaying as image');
        if (mounted) {
          setState(() {
            _isInitialized = true;
            _hasError = false;
          });
        }
        return;
      }
      
      // Fallback: Try to construct URL from video ID if no URL provided
      if ((videoUrlToUse == null || videoUrlToUse.isEmpty) && widget.video.id.isNotEmpty) {
        debugPrint('OptimizedVideoItemWidget: No videoUrl, trying to construct from ID');
        // Try common video URL patterns
        videoUrlToUse = '${AppConfig.mediaUrl}/videos/${widget.video.id}.mp4';
        debugPrint('OptimizedVideoItemWidget: Constructed URL: $videoUrlToUse');
      }
      
      if (videoUrlToUse != null && videoUrlToUse.isNotEmpty) {
        final normalizedUrl = VideoUrlHelper.normalizeVideoUrl(videoUrlToUse);
        
        if (normalizedUrl == null) {
          debugPrint('OptimizedVideoItemWidget: Failed to normalize URL: $videoUrlToUse');
          throw Exception('Invalid video URL: $videoUrlToUse');
        }
        
        debugPrint('OptimizedVideoItemWidget: Loading video from: $normalizedUrl');
        
        try {
          // Try cached file first
          final cachedFile = await _cacheService.getCachedFile(normalizedUrl);
          
          if (cachedFile != null && await cachedFile.exists()) {
            controller = VideoPlayerController.file(cachedFile);
          } else {
            controller = VideoPlayerController.networkUrl(Uri.parse(normalizedUrl));
            _cacheService.getCachedFile(normalizedUrl); // Background cache
          }
        } catch (e) {
          debugPrint('Error creating controller: $e');
          // If video fails, check if it might be an image
          final isImageUrl = imageExtensions.any((ext) => normalizedUrl.toLowerCase().contains(ext));
          if (isImageUrl) {
            debugPrint('OptimizedVideoItemWidget: Video load failed, but appears to be image');
            _isImage = true;
            if (mounted) {
              setState(() {
                _isInitialized = true;
                _hasError = false;
              });
            }
            return;
          }
          throw Exception('Failed to load video from: $normalizedUrl');
        }
      } else if (widget.video.isLocal && widget.video.videoPath != null && !kIsWeb) {
        try {
          final file = File(widget.video.videoPath!);
          if (await file.exists()) {
            final path = file.path.toLowerCase();
            if (imageExtensions.any((ext) => path.endsWith(ext))) {
              _isImage = true;
              if (mounted) {
                setState(() {
                  _isInitialized = true;
                  _hasError = false;
                });
              }
              return;
            }
            controller = VideoPlayerController.file(file);
          }
        } catch (e) {
          debugPrint('Error with local file: $e');
        }
      }

      if (controller == null) {
        // If no controller but we have a URL, might be an image
        if (videoUrlToUse != null && imageExtensions.any((ext) => videoUrlToUse!.toLowerCase().contains(ext))) {
          _isImage = true;
          if (mounted) {
            setState(() {
              _isInitialized = true;
              _hasError = false;
            });
          }
          return;
        }
        final errorMsg = 'No valid video source. '
            'videoUrl: ${widget.video.videoUrl}, '
            'isLocal: ${widget.video.isLocal}, '
            'videoPath: ${widget.video.videoPath}';
        debugPrint('OptimizedVideoItemWidget ERROR: $errorMsg');
        throw Exception(errorMsg);
      }

      try {
        await controller.initialize().timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw TimeoutException('Video load timeout'),
        );
      } catch (e) {
        // If video initialization fails, check if it's an image
        final url = videoUrlToUse ?? widget.video.videoUrl ?? '';
        if (imageExtensions.any((ext) => url.toLowerCase().contains(ext))) {
          debugPrint('OptimizedVideoItemWidget: Video init failed, treating as image');
          controller.dispose();
          _isImage = true;
          if (mounted) {
            setState(() {
              _isInitialized = true;
              _hasError = false;
            });
          }
          return;
        }
        rethrow;
      }

      if (_isDisposed || !mounted) {
        controller.dispose();
        return;
      }

      final chewieController = ChewieController(
        videoPlayerController: controller,
        autoPlay: false, // CRITICAL: Never auto-play - we control playback manually
        looping: true,
        showControls: false,
        aspectRatio: controller.value.aspectRatio,
        errorBuilder: (context, errorMessage) => _buildErrorWidget(errorMessage),
      );

      controller.addListener(_videoListener);

      if (mounted) {
        setState(() {
          _controller = controller;
          _chewieController = chewieController;
          _isInitialized = true;
          _hasError = false;
        });

        // Only play if this is the current page and not paused
        if (widget.pageIndex == widget.currentPageIndex && !widget.isPaused) {
          // Small delay to ensure previous video is paused
          Future.delayed(const Duration(milliseconds: 50), () {
            if (mounted && !_isDisposed && _chewieController != null && 
                widget.pageIndex == widget.currentPageIndex && !widget.isPaused) {
              _chewieController?.play();
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Video init error: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _isInitialized = true;
        });
      }
    }
  }

  void _videoListener() {
    if (_controller == null || _isDisposed) return;
    
    if (_controller!.value.hasError) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = _controller!.value.errorDescription ?? 'Unknown error';
        });
      }
    }
  }

  @override
  void didUpdateWidget(OptimizedVideoItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Handle page changes
    if (oldWidget.currentPageIndex != widget.currentPageIndex) {
      if (widget.pageIndex == widget.currentPageIndex && !widget.isPaused) {
        _chewieController?.play();
      } else {
        _chewieController?.pause();
      }
    }
    
    // Handle pause state changes
    if (oldWidget.isPaused != widget.isPaused) {
      if (widget.isPaused) {
        _chewieController?.pause();
      } else if (widget.pageIndex == widget.currentPageIndex) {
        _chewieController?.play();
      }
    }
  }

  void _handleVisibilityChanged(VisibilityInfo info) {
    if (_isDisposed || _chewieController == null) return;
    
    // Pause if less than 70% visible
    final visibilityFraction = info.visibleFraction;
    if (visibilityFraction < 0.7) {
      _chewieController?.pause();
    } else if (widget.pageIndex == widget.currentPageIndex && !widget.isPaused) {
      _chewieController?.play();
    }
  }

  void _handleSingleTap() {
    // Handle tap for videos only (images don't need play/pause)
    if (_isImage || _hasError) return;
    
    if (_chewieController == null || _controller == null) return;
    
    // Check if this might be a double tap
    final now = DateTime.now();
    if (_lastTapTime != null && now.difference(_lastTapTime!) < const Duration(milliseconds: 300)) {
      // This might be a double tap, cancel single tap timer
      _singleTapTimer?.cancel();
      _singleTapTimer = null;
      return;
    }
    
    _lastTapTime = now;
    
    // Delay single tap to allow double tap detection
    _singleTapTimer?.cancel();
    _singleTapTimer = Timer(const Duration(milliseconds: 300), () {
      if (_isDisposed || !mounted) return;
      
      try {
        // Get current playing state before any operations
        final isPlaying = _chewieController!.videoPlayerController.value.isPlaying;
        
        if (isPlaying) {
          // Pause both Chewie and underlying controller immediately
          _chewieController!.pause();
          _controller!.pause();
        } else {
          // Play both Chewie and underlying controller immediately
          _chewieController!.play();
          _controller!.play();
        }
        
        // Update UI state
        if (mounted) {
          setState(() {
            _showPlayPauseIcon = true;
          });
        }

        // Animate play/pause icon
        _playPauseController.forward().then((_) {
          _playPauseController.reverse();
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              setState(() => _showPlayPauseIcon = false);
            }
          });
        });
      } catch (e) {
        debugPrint('Error in _handleSingleTap: $e');
      }
    });
  }

  void _handleDoubleTap() {
    debugPrint('OptimizedVideoItemWidget: Double tap detected!');
    // Cancel any pending single tap
    _singleTapTimer?.cancel();
    _singleTapTimer = null;
    
    // Handle double tap like
    if (mounted) {
      setState(() => _showLikeAnimation = true);
    }
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

  Widget _buildImageWidget() {
    final imageUrl = widget.video.videoUrl ?? widget.video.thumbnailUrl;
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(color: VyRaTheme.primaryBlack);
    }
    
    final normalizedUrl = VideoUrlHelper.normalizeVideoUrl(imageUrl);
    if (normalizedUrl == null) {
      return Container(color: VyRaTheme.primaryBlack);
    }
    
    return SizedBox.expand(
      child: Image.network(
        normalizedUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: VyRaTheme.primaryBlack,
            child: Center(
              child: CircularProgressIndicator(
                color: VyRaTheme.primaryCyan,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: VyRaTheme.primaryBlack,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, color: VyRaTheme.textGrey, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load image',
                    style: TextStyle(color: VyRaTheme.textGrey),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorWidget(String? errorMessage) {
    final isNoSource = errorMessage?.contains('No valid video source') ?? false;
    
    return Container(
      color: VyRaTheme.primaryBlack,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isNoSource ? Icons.video_library_outlined : Icons.error_outline,
              color: isNoSource ? VyRaTheme.textGrey : Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              isNoSource ? 'No video available' : 'Video unavailable',
              style: TextStyle(color: VyRaTheme.textGrey, fontSize: 16),
            ),
            if (errorMessage != null && !isNoSource) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  errorMessage,
                  style: TextStyle(color: VyRaTheme.textGrey, fontSize: 12),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            if (!isNoSource) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _hasError = false;
                    _isInitialized = false;
                  });
                  _initializePlayer();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: VyRaTheme.primaryCyan,
                  foregroundColor: VyRaTheme.primaryBlack,
                ),
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _singleTapTimer?.cancel();
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    _chewieController?.dispose();
    _playPauseController.dispose();
    _doubleTapLikeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('video_${widget.video.id}'),
      onVisibilityChanged: _handleVisibilityChanged,
      child: GestureDetector(
        onTap: _handleSingleTap,
        onDoubleTap: _handleDoubleTap,
        behavior: HitTestBehavior.translucent, // Translucent to allow proper double tap detection
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (!_isInitialized)
              Container(
                color: VyRaTheme.primaryBlack,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        color: VyRaTheme.primaryCyan,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Loading video...',
                        style: TextStyle(color: VyRaTheme.textGrey),
                      ),
                    ],
                  ),
                ),
              )
            else if (_hasError)
              _buildErrorWidget(_errorMessage)
            else if (_isImage)
              // Display image instead of video
              _buildImageWidget()
            else if (_chewieController != null)
              AbsorbPointer(
                // Absorb pointer events from Chewie but allow parent GestureDetector to detect them
                absorbing: true,
                child: SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller!.value.size.width,
                      height: _controller!.value.size.height,
                      child: Chewie(controller: _chewieController!),
                    ),
                  ),
                ),
              )
            else
              Container(color: VyRaTheme.primaryBlack),
            
            // Volume control
            if (_isInitialized && !_hasError)
              Positioned(
                top: 60, // Moved down to avoid hiding behind notification button
                right: 16,
                child: GestureDetector(
                  onTap: () {
                    if (_controller != null) {
                      setState(() {
                        _controller!.setVolume(
                          _controller!.value.volume > 0 ? 0 : 1,
                        );
                      });
                    }
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
            if (_showPlayPauseIcon && _chewieController != null)
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
                          _chewieController!.videoPlayerController.value.isPlaying
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
            if (_isInitialized && !_hasError)
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
            
            // Action buttons - moved down for TikTok-like positioning
            if (_isInitialized && !_hasError)
              Positioned(
                bottom: 20, // Much lower position for TikTok-like layout
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
            
            // Video progress indicator
            if (_isInitialized && !_hasError && _controller != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ValueListenableBuilder(
                  valueListenable: _controller!,
                  builder: (context, value, child) {
                    if (!value.isInitialized) return const SizedBox.shrink();
                    
                    final progress = value.position.inMilliseconds /
                        value.duration.inMilliseconds.clamp(1, double.maxFinite);
                    
                    return Container(
                      height: 2,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                      ),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          VyRaTheme.primaryCyan,
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
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

