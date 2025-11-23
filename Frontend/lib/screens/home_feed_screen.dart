import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/vyra_theme.dart';
import '../widgets/neon_appbar.dart';
import '../widgets/video_player_widget.dart';
import '../widgets/optimized_video_item_widget.dart';
import '../models/video_item.dart';
import '../services/local_storage.dart';
import '../services/api_service.dart';
import '../services/video_cache_service.dart';
import '../models/user_profile.dart';
import '../config/app_config.dart';
import '../utils/video_url_helper.dart';
import 'profile_screen.dart';

// ============================================================================
// BATTLE PAIR MODEL
// ============================================================================
class BattlePair {
  final VideoItem left;
  final VideoItem right;

  BattlePair({required this.left, required this.right});
}

// ============================================================================
// MAIN HOME FEED SCREEN
// ============================================================================
class HomeFeedScreen extends StatefulWidget {
  final VoidCallback? onRefresh;
  
  const HomeFeedScreen({super.key, this.onRefresh});

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> 
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final PageController _pageController = PageController();
  final PageController _horizontalPageController = PageController();
  final LocalStorageService _storage = LocalStorageService();
  final ApiService _apiService = ApiService();
  final VideoCacheService _cacheService = VideoCacheService();
  
  UserProfile? _currentUser;
  List<VideoItem> _videos = [];
  int _currentIndex = 0;
  int _currentHorizontalPage = 0;
  bool _isOnPageTurning = false;
  
  final Map<String, VideoPlayerController> _controllers = {};
  final Map<String, ChewieController> _chewieControllers = {};
  final Map<String, bool> _isLiked = {};
  final Map<String, bool> _isBuzzed = {}; // Track buzz state
  final Map<String, int> _videoLikes = {};
  
  List<BattlePair> _battles = [];
  bool _battlesLoading = true;
  final Map<String, VideoPlayerController> _battleControllers = {};
  final Map<String, String?> _selectedVote = {};
  
  late AnimationController _fabController;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _cacheService.initialize();
    _pageController.addListener(_scrollListener);
    _initializeData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh when screen becomes visible again (e.g., after upload)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadVideos();
    });
  }

  void _scrollListener() {
    if (_pageController.position.pixels == _pageController.position.maxScrollExtent) {
      // Load more videos when reaching the end
      _loadMoreVideos();
    }
  }

  Future<void> _loadMoreVideos() async {
    // Implement pagination if needed
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _pageController.removeListener(_scrollListener);
    _pageController.dispose();
    _horizontalPageController.dispose();
    _fabController.dispose();
    _disposeControllers();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pauseAllVideos();
    } else if (state == AppLifecycleState.resumed) {
      _resumeCurrentVideo();
    }
  }

  void _disposeControllers() {
    for (var controller in _controllers.values) {
      try {
        controller.dispose();
      } catch (e) {
        debugPrint('Error disposing video controller: $e');
      }
    }
    for (var controller in _battleControllers.values) {
      try {
        controller.dispose();
      } catch (e) {
        debugPrint('Error disposing battle controller: $e');
      }
    }
    for (var chewieController in _chewieControllers.values) {
      try {
        chewieController.dispose();
      } catch (e) {
        debugPrint('Error disposing chewie controller: $e');
      }
    }
    _controllers.clear();
    _battleControllers.clear();
    _chewieControllers.clear();
  }

  void pauseAllVideos() {
    _pauseAllVideos();
  }

  void _pauseAllVideos() {
    // OptimizedVideoItemWidget manages its own controllers, so we can't pause them directly
    // Instead, we rely on the isPaused prop and currentPageIndex to control playback
    // Only pause battle controllers which are managed here
    for (var controller in _battleControllers.values) {
      try {
        if (controller.value.isPlaying) {
          controller.pause();
        }
      } catch (e) {
        debugPrint('Error pausing battle controller: $e');
      }
    }
  }

  void _resumeCurrentVideo() {
    if (_currentIndex < _videos.length) {
      final video = _videos[_currentIndex];
      final chewie = _chewieControllers[video.id];
      try {
        chewie?.play();
      } catch (e) {
        debugPrint('Error resuming video: $e');
      }
    }
  }

  Future<void> _initializeData() async {
    await _loadCurrentUser();
    await Future.wait([
        loadVideos(),
      _loadBattles(),
    ]);
  }

  Future<void> _loadCurrentUser() async {
    try {
      final profile = await _apiService.getProfile();
      if (!_isDisposed && mounted) {
        setState(() => _currentUser = profile);
      }
    } catch (e) {
      debugPrint('Error loading user: $e');
    }
  }

  Future<void> loadVideos({bool useRecommended = false}) async {
    try {
      List<VideoItem> videos;
      if (useRecommended) {
        videos = await _apiService.getRecommendedVideos();
      } else {
        try {
          videos = await _apiService.getVideos();
        } catch (e) {
          videos = await _storage.getVideos();
        }
      }
      
      if (!_isDisposed && mounted) {
        debugPrint('HomeFeedScreen: Loaded ${videos.length} videos');
        for (var i = 0; i < videos.length && i < 3; i++) {
          final v = videos[i];
          debugPrint('  Video $i: id=${v.id}, videoUrl=${v.videoUrl}, isLocal=${v.isLocal}, videoPath=${v.videoPath}');
        }
        
        setState(() => _videos = videos);
        
        // Preload video URLs for caching
        final videoUrls = videos
            .where((v) => v.videoUrl != null && v.videoUrl!.isNotEmpty)
            .map((v) => v.videoUrl!)
            .toList();
        
        debugPrint('HomeFeedScreen: ${videoUrls.length} videos have valid URLs');
        
        // Preload first 3 videos
        if (videoUrls.isNotEmpty) {
          await _cacheService.preloadVideos(videoUrls.take(3).toList());
        }
        
        // Initialize first video immediately
        if (videos.isNotEmpty) {
          await _initializeVideo(videos[0]);
        }
      }
    } catch (e) {
      debugPrint('Error loading videos: $e');
      if (!_isDisposed && mounted) {
        setState(() => _videos = []);
      }
    }
  }

  Future<void> _loadBattles() async {
    if (!mounted) return;
    setState(() => _battlesLoading = true);
    
    try {
      final videos = await _storage.getVideos();
      final battles = <BattlePair>[];
      
      for (int i = 0; i < videos.length - 1; i += 2) {
        battles.add(BattlePair(left: videos[i], right: videos[i + 1]));
      }
      
      if (!_isDisposed && mounted) {
        setState(() {
          _battles = battles;
          _battlesLoading = false;
        });
        
        for (var battle in battles) {
          await _initializeBattle(battle);
          if (_isDisposed) break;
        }
      }
    } catch (e) {
      debugPrint('Error loading battles: $e');
      if (!_isDisposed && mounted) {
        setState(() => _battlesLoading = false);
      }
    }
  }

  Future<void> _initializeBattle(BattlePair battle) async {
    if (_isDisposed) return;
    
    try {
      final leftUrl = VideoUrlHelper.normalizeVideoUrl(battle.left.videoUrl);
      final rightUrl = VideoUrlHelper.normalizeVideoUrl(battle.right.videoUrl);
      
      if (leftUrl == null || rightUrl == null) return;
      
      final leftController = VideoPlayerController.networkUrl(Uri.parse(leftUrl));
      final rightController = VideoPlayerController.networkUrl(Uri.parse(rightUrl));
      
      await Future.wait([
        leftController.initialize(),
        rightController.initialize(),
      ]);
      
      if (!_isDisposed && mounted) {
        setState(() {
          _battleControllers['${battle.left.id}_left'] = leftController;
          _battleControllers['${battle.right.id}_right'] = rightController;
        });
        
        leftController.setLooping(true);
        rightController.setLooping(true);
        leftController.play();
        rightController.play();
      } else {
        leftController.dispose();
        rightController.dispose();
      }
    } catch (e) {
      debugPrint('Battle init error: $e');
    }
  }

  Future<void> _initializeVideo(VideoItem video) async {
    // CRITICAL: OptimizedVideoItemWidget handles all video controller creation and playback
    // This function is kept for compatibility but does nothing to prevent duplicate controllers
    // All video management is handled by OptimizedVideoItemWidget
    if (_isDisposed) return;
    
    // Just ensure like state is initialized
    if (!_isLiked.containsKey(video.id)) {
      if (mounted) {
        setState(() {
          _isLiked[video.id] = false;
        });
      }
    }
  }

  void _onPageChanged(int index) {
    if (_isDisposed || !mounted || _isOnPageTurning) return;
    
    setState(() {
      _currentIndex = index;
      _isOnPageTurning = true;
    });

    // Preload next videos
    final videoUrls = _videos
        .where((v) => v.videoUrl != null && v.videoUrl!.isNotEmpty)
        .map((v) => v.videoUrl!)
        .toList();
    _cacheService.preloadNextVideos(videoUrls, index);

    // Pause ALL videos first (including battles)
    _pauseAllVideos();

    // Don't play here - OptimizedVideoItemWidget handles its own playback
    // Just ensure the video is initialized if needed
    if (index < _videos.length) {
      final currentVideo = _videos[index];
      if (!_chewieControllers.containsKey(currentVideo.id)) {
        // Initialize if not already initialized (but don't auto-play)
        _initializeVideo(currentVideo);
      }
    }

    setState(() => _isOnPageTurning = false);
  }

  Future<void> _handleLike(String videoId) async {
    final wasLiked = _isLiked[videoId] ?? false;
    final video = _videos.firstWhere((v) => v.id == videoId);
    
    setState(() {
      _isLiked[videoId] = !wasLiked;
      _videoLikes[videoId] = (wasLiked ? -1 : 1) + (_videoLikes[videoId] ?? video.likes);
    });
    
    try {
      await _apiService.likeVideo(videoId);
      final videoIndex = _videos.indexWhere((v) => v.id == videoId);
      if (videoIndex != -1 && mounted) {
        setState(() {
          _videos[videoIndex] = _videos[videoIndex].copyWith(
            likes: _videoLikes[videoId] ?? _videos[videoIndex].likes,
          );
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLiked[videoId] = wasLiked;
          _videoLikes[videoId] = (wasLiked ? 1 : -1) + (_videoLikes[videoId] ?? video.likes);
        });
      }
      _showSnack('Failed to update like', isError: true);
    }
  }

  Future<void> _handleBuzz(String videoId) async {
    final wasBuzzed = _isBuzzed[videoId] ?? false;
    final video = _videos.firstWhere((v) => v.id == videoId);
    
    setState(() {
      _isBuzzed[videoId] = !wasBuzzed;
      final videoIndex = _videos.indexWhere((v) => v.id == videoId);
      if (videoIndex != -1) {
        _videos[videoIndex] = _videos[videoIndex].copyWith(
          buzzCount: wasBuzzed 
              ? (_videos[videoIndex].buzzCount - 1).clamp(0, double.infinity).toInt()
              : _videos[videoIndex].buzzCount + 1,
        );
      }
    });
    
    try {
      final success = await _apiService.buzzVideo(videoId);
      if (!success && mounted) {
        // Revert on failure
        setState(() {
          _isBuzzed[videoId] = wasBuzzed;
          final videoIndex = _videos.indexWhere((v) => v.id == videoId);
          if (videoIndex != -1) {
            _videos[videoIndex] = _videos[videoIndex].copyWith(
              buzzCount: wasBuzzed 
                  ? _videos[videoIndex].buzzCount + 1
                  : (_videos[videoIndex].buzzCount - 1).clamp(0, double.infinity).toInt(),
            );
          }
        });
        _showSnack('Failed to update buzz', isError: true);
      } else if (success) {
        _showSnack(wasBuzzed ? '🔥 Unbuzzed' : '🔥 Buzzed!');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isBuzzed[videoId] = wasBuzzed;
          final videoIndex = _videos.indexWhere((v) => v.id == videoId);
          if (videoIndex != -1) {
            _videos[videoIndex] = _videos[videoIndex].copyWith(
              buzzCount: wasBuzzed 
                  ? _videos[videoIndex].buzzCount + 1
                  : (_videos[videoIndex].buzzCount - 1).clamp(0, double.infinity).toInt(),
            );
          }
        });
      }
      _showSnack('Failed to buzz', isError: true);
    }
  }

  Future<void> _handleBoost(String videoId) async {
    try {
      final boostType = await showDialog<String>(
        context: context,
        builder: (ctx) => _BoostDialog(),
      );
      
      if (boostType != null) {
        final result = await _apiService.boostVideo(videoId, boostType);
        if (mounted) {
          _showSnack('Boosted! ✨ ${result['remainingPoints']} pts left');
          loadVideos(useRecommended: true);
        }
      }
    } catch (e) {
      _showSnack(e.toString(), isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : VyRaTheme.primaryCyan,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _voteBattle(String battleId, String side) {
    if (mounted) {
      setState(() => _selectedVote[battleId] = side);
    }
  }

  // ============================================================================
  // BUILD METHOD
  // ============================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VyRaTheme.primaryBlack,
      body: Stack(
        children: [
          ..._buildBackgroundParticles(),
          PageView(
            controller: _horizontalPageController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) {
              if (mounted) {
                setState(() => _currentHorizontalPage = index);
                _fabController.forward().then((_) => _fabController.reverse());
              }
            },
            children: [
              _buildFeedPage(),
              _buildBattlesPage(),
            ],
          ),
          _buildHolographicAppBar(),
          _buildTabBar(),
        ],
      ),
    );
  }

  List<Widget> _buildBackgroundParticles() {
    return List.generate(20, (i) {
      return Positioned(
        left: (i * 80.0) % MediaQuery.of(context).size.width,
        top: (i * 60.0) % MediaQuery.of(context).size.height,
        child: Container(
          width: 3 + (i % 4).toDouble(),
          height: 3 + (i % 4).toDouble(),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: VyRaTheme.primaryCyan.withOpacity(0.2),
            boxShadow: [
              BoxShadow(
                color: VyRaTheme.primaryCyan.withOpacity(0.4),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(duration: (2000 + i * 100).ms, begin: 0, end: -40 - (i % 25))
            .fadeIn(duration: 1000.ms)
            .then()
            .fadeOut(duration: 1000.ms),
      );
    });
  }

  Widget _buildHolographicAppBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          bottom: 8,
          left: 16,
          right: 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              VyRaTheme.primaryBlack.withOpacity(0.95),
              VyRaTheme.primaryBlack.withOpacity(0.8),
              VyRaTheme.primaryBlack.withOpacity(0.5),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            const Spacer(),
            _buildSubtleIconButton(Icons.person_add_outlined, () => Navigator.pushNamed(context, '/find-friends')),
            const SizedBox(width: 8),
            _buildSubtleIconButton(Icons.search, () => Navigator.pushNamed(context, '/search')),
            const SizedBox(width: 8),
            _buildSubtleIconButton(Icons.notifications_outlined, () => Navigator.pushNamed(context, '/notifications')),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtleIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: VyRaTheme.darkGrey.withOpacity(0.4),
          shape: BoxShape.circle,
          border: Border.all(
            color: VyRaTheme.primaryCyan.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Icon(icon, color: VyRaTheme.textWhite.withOpacity(0.9), size: 18),
      ),
    );
  }

  Widget _buildTabBar() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 50,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: VyRaTheme.darkGrey.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: VyRaTheme.primaryCyan.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSubtleTabButton('Feed', 0),
              const SizedBox(width: 3),
              _buildSubtleTabButton('Battles', 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubtleTabButton(String label, int pageIndex) {
    final isActive = _currentHorizontalPage == pageIndex;
    return GestureDetector(
      onTap: () {
        _horizontalPageController.animateToPage(
          pageIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  colors: [VyRaTheme.primaryCyan.withOpacity(0.8), VyRaTheme.primaryCyan.withOpacity(0.6)],
                )
              : null,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? VyRaTheme.primaryBlack : VyRaTheme.textWhite.withOpacity(0.7),
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildFeedPage() {
    if (_videos.isEmpty) {
      return _buildEmptyState(
        icon: Icons.video_library_outlined,
        title: 'No videos yet',
        subtitle: 'Tap + to create',
      );
    }

    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          physics: const BouncingScrollPhysics(),
          onPageChanged: _onPageChanged,
          itemCount: _videos.length,
          itemBuilder: (ctx, index) {
            final video = _videos[index];
            
            // Use optimized video widget
            return OptimizedVideoItemWidget(
              video: video,
              pageIndex: index,
              currentPageIndex: _currentIndex,
              isPaused: _isOnPageTurning || index != _currentIndex,
              isLiked: _isLiked[video.id] ?? false,
              isBuzzed: _isBuzzed[video.id] ?? false,
              onLike: () => _handleLike(video.id),
              onComment: () => _showCommentsSheet(video),
              onBuzz: () => _handleBuzz(video.id),
              onShare: () => _showShareSheet(video),
              onBoost: () => _handleBoost(video.id),
              onProfileTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(
                      username: video.username,
                      userId: video.userId,
                      isViewingOther: true,
                    ),
                  ),
                );
              },
            );
          },
        ),
        _buildFloatingActionBar(),
      ],
    );
  }

  Widget _buildVideoLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [VyRaTheme.primaryCyan, const Color(0xFF00D4FF)],
              ),
            ),
            child: const CircularProgressIndicator(
              color: VyRaTheme.primaryBlack,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Loading...',
            style: TextStyle(
              color: VyRaTheme.textGrey,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer(VideoItem video) {
    final currentLikes = _videoLikes[video.id] ?? video.likes;
    final updatedVideo = video.copyWith(likes: currentLikes);

    return VideoPlayerWidget(
      video: updatedVideo,
      isLiked: _isLiked[video.id] ?? false,
      onLike: () => _handleLike(video.id),
      onComment: () => _showCommentsSheet(updatedVideo),
      onBuzz: () => _handleBuzz(video.id),
      onShare: () => _showShareSheet(video),
      onBoost: () => _handleBoost(video.id),
      onProfileTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileScreen(
              username: video.username,
              userId: video.userId,
              isViewingOther: true,
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingActionBar() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 60,
      left: 10,
      child: Column(
        children: [
          _buildSubtleFloatingButton(Icons.map_outlined, Colors.green.withOpacity(0.8), 
              () => Navigator.pushNamed(context, '/universe-map')),
          const SizedBox(height: 8),
          _buildSubtleFloatingButton(Icons.group_outlined, const Color(0xFFB026FF).withOpacity(0.8),
              () => Navigator.pushNamed(context, '/clubs')),
        ],
      ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.3, end: 0),
    );
  }

  Widget _buildSubtleFloatingButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.5), width: 1),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.3), blurRadius: 12),
          ],
        ),
        child: Icon(icon, color: color, size: 19),
      ),
    );
  }

  Widget _buildBattlesPage() {
    if (_battlesLoading) {
      return _buildVideoLoading();
    }

    if (_battles.isEmpty) {
      return _buildEmptyState(
        icon: Icons.sports_mma_rounded,
        title: 'No battles yet',
        subtitle: 'Check back soon!',
      );
    }

    return PageView.builder(
      scrollDirection: Axis.vertical,
      physics: const BouncingScrollPhysics(),
      itemCount: _battles.length,
      itemBuilder: (ctx, index) => _buildBattleCard(_battles[index]),
    );
  }

  Widget _buildBattleCard(BattlePair battle) {
    final battleId = '${battle.left.id}_${battle.right.id}';
    final selectedVote = _selectedVote[battleId];

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 100, 20, 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [VyRaTheme.darkGrey, VyRaTheme.darkGrey.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: VyRaTheme.primaryCyan.withOpacity(0.5), width: 2.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.sports_mma_rounded, color: VyRaTheme.primaryCyan, size: 28),
                SizedBox(width: 16),
                Text(
                  'BATTLE',
                  style: TextStyle(
                    color: VyRaTheme.primaryCyan,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildBattleSide(
                    battle.left,
                    _battleControllers['${battle.left.id}_left'],
                    selectedVote == 'left',
                    () => _voteBattle(battleId, 'left'),
                  ),
                ),
                Container(width: 3, color: VyRaTheme.primaryCyan),
                Expanded(
                  child: _buildBattleSide(
                    battle.right,
                    _battleControllers['${battle.right.id}_right'],
                    selectedVote == 'right',
                    () => _voteBattle(battleId, 'right'),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text('@${battle.left.username}', 
                    style: const TextStyle(color: VyRaTheme.textWhite, fontWeight: FontWeight.w700)),
                const Text('VS', style: TextStyle(color: VyRaTheme.primaryCyan, fontSize: 20, fontWeight: FontWeight.w900)),
                Text('@${battle.right.username}',
                    style: const TextStyle(color: VyRaTheme.textWhite, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBattleSide(VideoItem video, VideoPlayerController? controller, bool isSelected, VoidCallback onVote) {
    return GestureDetector(
      onTap: onVote,
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? VyRaTheme.primaryCyan : VyRaTheme.primaryCyan.withOpacity(0.3),
            width: isSelected ? 3 : 2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (controller != null && controller.value.isInitialized)
                VideoPlayer(controller)
              else
                Container(
                  color: VyRaTheme.mediumGrey,
                  child: const Center(
                    child: CircularProgressIndicator(color: VyRaTheme.primaryCyan),
                  ),
                ),
              if (isSelected)
                Container(
                  color: VyRaTheme.primaryCyan.withOpacity(0.3),
                  child: const Center(
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: VyRaTheme.primaryCyan,
                      size: 60,
                    ),
                  ),
                ),
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? VyRaTheme.primaryCyan : VyRaTheme.darkGrey.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Text(
                    isSelected ? 'VOTED' : 'VOTE',
                    style: TextStyle(
                      color: isSelected ? VyRaTheme.primaryBlack : VyRaTheme.primaryCyan,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  VyRaTheme.primaryCyan.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
            child: Icon(icon, size: 100, color: VyRaTheme.textGrey.withOpacity(0.6)),
          ),
          const SizedBox(height: 32),
          Text(title, style: const TextStyle(color: VyRaTheme.textGrey, fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Text(subtitle, style: TextStyle(color: VyRaTheme.textGrey.withOpacity(0.8), fontSize: 16)),
        ],
      ),
    );
  }

  void _showCommentsSheet(VideoItem video) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => _CommentsSheet(video: video),
      ),
    );
  }

  void _showShareSheet(VideoItem video) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [VyRaTheme.darkGrey, VyRaTheme.primaryBlack],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: VyRaTheme.primaryCyan.withOpacity(0.3), width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              children: [
                Icon(Icons.share_rounded, color: VyRaTheme.primaryCyan, size: 28),
                SizedBox(width: 16),
                Text('Share Video', style: TextStyle(color: VyRaTheme.textWhite, fontSize: 24, fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildShareOption(Icons.message_rounded, 'Message', VyRaTheme.primaryCyan, () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, '/chat');
                }),
                _buildShareOption(Icons.copy_rounded, 'Copy', const Color(0xFFB026FF), () {
                  Navigator.pop(ctx);
                  _showSnack('Link copied! 📋');
                }),
                _buildShareOption(Icons.bookmark_rounded, 'Save', Colors.orange, () async {
                  Navigator.pop(ctx);
                  try {
                    await _apiService.saveVideo(video.id);
                    _showSnack('Video saved! ⭐');
                  } catch (e) {
                    _showSnack('Failed to save', isError: true);
                  }
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.6), width: 2.5),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 10),
          Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ============================================================================
// BOOST DIALOG
// ============================================================================
class _BoostDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: VyRaTheme.darkGrey,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: VyRaTheme.primaryCyan.withOpacity(0.5), width: 2),
      ),
      title: const Row(
        children: [
          Icon(Icons.rocket_launch_rounded, color: Color(0xFFFFD700), size: 28),
          SizedBox(width: 12),
          Text('Boost Video', style: TextStyle(color: VyRaTheme.textWhite, fontWeight: FontWeight.w800)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildBoostOption(context, 'glow', 'Glow Boost', '50 pts', Icons.auto_awesome_rounded, VyRaTheme.primaryCyan),
          const SizedBox(height: 14),
          _buildBoostOption(context, 'campus', 'Campus Boost', '100 pts', Icons.location_on_rounded, const Color(0xFFFF6B35)),
          const SizedBox(height: 14),
          _buildBoostOption(context, 'hashtag', 'Hashtag Boost', '75 pts', Icons.tag_rounded, const Color(0xFFB026FF)),
        ],
      ),
    );
  }

  static Widget _buildBoostOption(BuildContext context, String type, String name, String cost, IconData icon, Color color) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, type),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.2), color.withOpacity(0.05)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.5), width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: TextStyle(color: color, fontSize: 17, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(cost, style: const TextStyle(color: VyRaTheme.textGrey, fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// COMMENTS SHEET
// ============================================================================
class _CommentsSheet extends StatefulWidget {
  final VideoItem video;

  const _CommentsSheet({required this.video});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  final ApiService _apiService = ApiService();
  final List<_Comment> _comments = [];
  UserProfile? _currentUser;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final profile = await _apiService.getProfile();
      if (mounted) setState(() => _currentUser = profile);
    } catch (e) {
      debugPrint('Error loading user: $e');
    }
  }

  Future<void> _loadComments() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final commentsData = await _apiService.getComments(widget.video.id);
      if (mounted) {
        setState(() {
          _comments.clear();
          _comments.addAll(commentsData.map((data) {
            return _Comment(
              id: data['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
              userId: data['user_id']?.toString() ?? data['userId']?.toString() ?? '',
              username: data['username']?.toString() ?? 'Unknown',
              text: data['text']?.toString() ?? '',
              timestamp: data['created_at'] != null
                  ? DateTime.parse(data['created_at'])
                  : (data['createdAt'] != null
                      ? DateTime.parse(data['createdAt'])
                      : DateTime.now()),
              likes: data['likes'] is int ? data['likes'] : (int.tryParse(data['likes']?.toString() ?? '0') ?? 0),
            );
          }));
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading comments: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty || !mounted) return;

    final commentText = _commentController.text.trim();
    _commentController.clear();
    FocusScope.of(context).unfocus();

    // Optimistically add comment to UI
    final tempComment = _Comment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: _currentUser?.id ?? '',
      username: _currentUser?.username ?? 'You',
      text: commentText,
      timestamp: DateTime.now(),
      likes: 0,
    );

    setState(() => _comments.insert(0, tempComment));

    // Save to backend
    try {
      final success = await _apiService.addComment(widget.video.id, commentText);
      if (!success && mounted) {
        // Remove the comment if save failed
        setState(() {
          _comments.removeAt(0);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to post comment'),
            backgroundColor: Colors.red,
          ),
        );
      } else if (mounted) {
        // Reload comments to get the actual saved comment with correct ID
        _loadComments();
      }
    } catch (e) {
      debugPrint('Error adding comment: $e');
      if (mounted) {
        setState(() {
          _comments.removeAt(0);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to post comment'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [VyRaTheme.darkGrey, VyRaTheme.primaryBlack],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: VyRaTheme.primaryCyan.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: VyRaTheme.primaryCyan.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                const Icon(Icons.chat_bubble_rounded, color: VyRaTheme.primaryCyan, size: 28),
                const SizedBox(width: 16),
                const Text('Comments', style: TextStyle(color: VyRaTheme.textWhite, fontSize: 24, fontWeight: FontWeight.w900)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: VyRaTheme.primaryCyan.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: VyRaTheme.primaryCyan.withOpacity(0.5)),
                  ),
                  child: Text('${_comments.length}', style: const TextStyle(color: VyRaTheme.primaryCyan, fontSize: 16, fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ),
          Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, VyRaTheme.primaryCyan.withOpacity(0.5), Colors.transparent],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: VyRaTheme.primaryCyan))
                : _comments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded, size: 80, color: VyRaTheme.textGrey.withOpacity(0.6)),
                            const SizedBox(height: 24),
                            const Text('No comments yet', style: TextStyle(color: VyRaTheme.textGrey, fontSize: 20, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 12),
                            Text('Be the first to comment!', style: TextStyle(color: VyRaTheme.textGrey.withOpacity(0.7), fontSize: 15)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        physics: const BouncingScrollPhysics(),
                        itemCount: _comments.length,
                        itemBuilder: (ctx, index) => _buildCommentItem(_comments[index], index),
                      ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, VyRaTheme.primaryBlack],
              ),
              border: Border(top: BorderSide(color: VyRaTheme.primaryCyan.withOpacity(0.3), width: 2)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [VyRaTheme.primaryCyan.withOpacity(0.3), VyRaTheme.primaryCyan.withOpacity(0.1)],
                      ),
                      border: Border.all(color: VyRaTheme.primaryCyan.withOpacity(0.5), width: 2),
                    ),
                    child: const Icon(Icons.person_rounded, color: VyRaTheme.primaryCyan, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: VyRaTheme.darkGrey.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: VyRaTheme.primaryCyan.withOpacity(0.3)),
                      ),
                      child: TextField(
                        controller: _commentController,
                        style: const TextStyle(color: VyRaTheme.textWhite, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'Add a comment...',
                          hintStyle: TextStyle(color: VyRaTheme.textGrey.withOpacity(0.7), fontSize: 15),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _addComment,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [VyRaTheme.primaryCyan, Color(0xFF00D4FF)]),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: VyRaTheme.primaryCyan.withOpacity(0.6), blurRadius: 20)],
                      ),
                      child: const Icon(Icons.send_rounded, color: VyRaTheme.primaryBlack, size: 22),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(_Comment comment, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [VyRaTheme.primaryCyan.withOpacity(0.3), VyRaTheme.primaryCyan.withOpacity(0.1)],
              ),
              border: Border.all(color: VyRaTheme.primaryCyan.withOpacity(0.5), width: 2),
            ),
            child: const Icon(Icons.person_rounded, color: VyRaTheme.primaryCyan, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [VyRaTheme.darkGrey.withOpacity(0.6), VyRaTheme.darkGrey.withOpacity(0.3)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: VyRaTheme.primaryCyan.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(comment.username, style: const TextStyle(color: VyRaTheme.primaryCyan, fontSize: 15, fontWeight: FontWeight.w800)),
                      const SizedBox(width: 10),
                      Text(_formatTime(comment.timestamp), style: TextStyle(color: VyRaTheme.textGrey.withOpacity(0.7), fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(comment.text, style: const TextStyle(color: VyRaTheme.textWhite, fontSize: 14)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.favorite_border_rounded, color: VyRaTheme.textGrey.withOpacity(0.8), size: 18),
                      const SizedBox(width: 6),
                      Text('${comment.likes}', style: TextStyle(color: VyRaTheme.textGrey.withOpacity(0.8), fontSize: 13)),
                      const SizedBox(width: 20),
                      const Text('Reply', style: TextStyle(color: VyRaTheme.primaryCyan, fontSize: 13, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ).animate(delay: (index * 50).ms).fadeIn(duration: 400.ms).slideX(begin: -0.2, end: 0),
    );
  }

  String _formatTime(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);
    if (difference.inDays > 0) return '${difference.inDays}d';
    if (difference.inHours > 0) return '${difference.inHours}h';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m';
    return 'now';
  }
}

class _Comment {
  final String id;
  final String userId;
  final String username;
  final String text;
  final DateTime timestamp;
  final int likes;

  _Comment({
    required this.id,
    required this.userId,
    required this.username,
    required this.text,
    required this.timestamp,
    this.likes = 0,
  });
}