// ENHANCED UNIVERSE MAP SCREEN
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/vyra_theme.dart';
import '../models/video_item.dart';
import '../services/api_service.dart';
import '../widgets/video_player_widget.dart';
import '../config/app_config.dart';

class UniverseMapScreen extends StatefulWidget {
  const UniverseMapScreen({super.key});

  @override
  State<UniverseMapScreen> createState() => _UniverseMapScreenState();
}

class _UniverseMapScreenState extends State<UniverseMapScreen> {
  final ApiService _apiService = ApiService();
  List<VideoItem> _nearbyVideos = [];
  bool _isLoading = true;
  double? _currentLat;
  double? _currentLng;
  double _radius = 10.0;
  final Map<String, bool> _isLiked = {};

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location services are disabled'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _currentLat = 37.7749; // Fallback location
          _currentLng = -122.4194;
          _isLoading = false;
        });
        _loadNearbyVideos();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permissions are denied'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() {
            _currentLat = 37.7749; // Fallback location
            _currentLng = -122.4194;
            _isLoading = false;
          });
          _loadNearbyVideos();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permissions are permanently denied'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _currentLat = 37.7749; // Fallback location
          _currentLng = -122.4194;
          _isLoading = false;
        });
        _loadNearbyVideos();
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentLat = position.latitude;
        _currentLng = position.longitude;
      });
      _loadNearbyVideos();
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentLat = 37.7749; // Fallback location
          _currentLng = -122.4194;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to get location'),
            backgroundColor: Colors.red,
          ),
        );
        _loadNearbyVideos();
      }
    }
  }

  Future<void> _loadNearbyVideos() async {
    if (_currentLat == null || _currentLng == null) return;
    
    setState(() => _isLoading = true);
    try {
      final videos = await _apiService.getNearbyVideos(_currentLat!, _currentLng!, radius: _radius);
      if (mounted) {
        setState(() {
          _nearbyVideos = videos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load nearby videos'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VyRaTheme.primaryBlack,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            backgroundColor: VyRaTheme.primaryBlack,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: VyRaTheme.darkGrey,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: VyRaTheme.primaryCyan.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Icon(Icons.arrow_back, color: VyRaTheme.textWhite, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: VyRaTheme.darkGrey,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: VyRaTheme.primaryCyan.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: const Icon(Icons.tune, color: VyRaTheme.primaryCyan, size: 20),
                ),
                onPressed: () => _showRadiusDialog(),
              ),
            ],
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    VyRaTheme.primaryBlack,
                    VyRaTheme.darkGrey,
                    VyRaTheme.primaryBlack,
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              VyRaTheme.primaryCyan.withOpacity(0.2),
                              VyRaTheme.primaryCyan.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: VyRaTheme.primaryCyan.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.map_rounded, color: VyRaTheme.primaryCyan, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Universe Map',
                              style: TextStyle(
                                color: VyRaTheme.textWhite,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 400.ms),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading)
            SliverFillRemaining(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: VyRaTheme.primaryCyan.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const CircularProgressIndicator(
                    color: VyRaTheme.primaryCyan,
                    strokeWidth: 3,
                  ),
                ).animate(onPlay: (controller) => controller.repeat())
                    .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
              ),
            )
          else if (_currentLat == null || _currentLng == null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            VyRaTheme.primaryCyan.withOpacity(0.1),
                            VyRaTheme.primaryCyan.withOpacity(0.05),
                          ],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: VyRaTheme.textGrey.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.location_off_rounded,
                        color: VyRaTheme.primaryCyan,
                        size: 48,
                      ),
                    ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                    const SizedBox(height: 24),
                    const Text(
                      'Location not available',
                      style: TextStyle(
                        color: VyRaTheme.textWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ).animate(delay: 200.ms).fadeIn(),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _getCurrentLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: VyRaTheme.primaryCyan,
                        foregroundColor: VyRaTheme.primaryBlack,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Enable Location'),
                    ).animate(delay: 300.ms).fadeIn(),
                  ],
                ),
              ),
            )
          else
            SliverToBoxAdapter(
              child: Column(
                children: [
                  Container(
                    constraints: BoxConstraints(
                      minHeight: 300,
                      maxHeight: (MediaQuery.of(context).size.height * 0.4).clamp(300.0, 400.0),
                    ),
                    height: 350,
                    margin: const EdgeInsets.all(16),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          VyRaTheme.darkGrey,
                          VyRaTheme.mediumGrey,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: VyRaTheme.primaryCyan.withOpacity(0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: VyRaTheme.primaryCyan.withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Stack(
                        fit: StackFit.expand,
                        clipBehavior: Clip.hardEdge,
                        children: [
                          // Map-like background pattern
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  VyRaTheme.darkGrey,
                                  VyRaTheme.mediumGrey.withOpacity(0.5),
                                  VyRaTheme.darkGrey,
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              ),
                            ),
                            child: CustomPaint(
                              painter: _MapGridPainter(),
                            ),
                          ),
                          // Current location marker
                          if (_currentLat != null && _currentLng != null)
                            Positioned(
                              left: (MediaQuery.of(context).size.width * 0.4).clamp(20.0, MediaQuery.of(context).size.width - 50),
                              top: 150,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.withOpacity(0.5),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          // Video location markers
                          if (_nearbyVideos.isNotEmpty)
                            ...List.generate(
                              _nearbyVideos.length > 15 ? 15 : _nearbyVideos.length,
                              (index) {
                                try {
                                  final video = _nearbyVideos[index];
                                  // Distribute markers across the map area with proper constraints
                                  final screenWidth = MediaQuery.of(context).size.width;
                                  final mapWidth = (screenWidth - 32).clamp(200.0, 500.0);
                                  final mapHeight = 350.0;
                                  final availableWidth = (mapWidth - 80).clamp(100.0, 400.0);
                                  final availableHeight = (mapHeight - 100).clamp(100.0, 250.0);
                                  
                                  // Use modulo with safe divisor
                                  final widthMod = availableWidth > 0 ? availableWidth : 100.0;
                                  final heightMod = availableHeight > 0 ? availableHeight : 100.0;
                                  
                                  final left = (20.0 + (index * 45.0) % widthMod).clamp(10.0, mapWidth - 30);
                                  final top = (50.0 + (index * 60.0) % heightMod).clamp(10.0, mapHeight - 80);
                                  
                                  return Positioned(
                                    left: left,
                                    top: top,
                                    child: GestureDetector(
                                      onTap: () {
                                        // Could show video preview or navigate to video
                                      },
                                      child: Container(
                                        width: 16,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          color: VyRaTheme.primaryCyan,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: VyRaTheme.primaryCyan.withOpacity(0.6),
                                              blurRadius: 8,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                      ).animate(delay: (index * 50).ms)
                                          .scale(begin: const Offset(0, 0), end: const Offset(1, 1)),
                                    ),
                                  );
                                } catch (e) {
                                  if (kDebugMode) {
                                    debugPrint('Error creating video marker: $e');
                                  }
                                  return const SizedBox.shrink();
                                }
                              },
                            ),
                          // Info overlay
                          Positioned(
                            bottom: 16,
                            left: 16,
                            right: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: VyRaTheme.primaryBlack.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: VyRaTheme.primaryCyan.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.location_on,
                                          color: Colors.green,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            'You are here',
                                            style: const TextStyle(
                                              color: VyRaTheme.textWhite,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.videocam,
                                          color: VyRaTheme.primaryCyan,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            '${_nearbyVideos.length} ${_nearbyVideos.length == 1 ? 'video' : 'videos'}',
                                            style: const TextStyle(
                                              color: VyRaTheme.primaryCyan,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_nearbyVideos.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  VyRaTheme.primaryCyan.withOpacity(0.1),
                                  VyRaTheme.primaryCyan.withOpacity(0.05),
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.location_off_rounded,
                              color: VyRaTheme.primaryCyan,
                              size: 48,
                            ),
                          ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                          const SizedBox(height: 24),
                          const Text(
                            'No videos nearby',
                            style: TextStyle(
                              color: VyRaTheme.textWhite,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ).animate(delay: 200.ms).fadeIn(),
                          const SizedBox(height: 8),
                          const Text(
                            'Try adjusting your search radius',
                            style: TextStyle(
                              color: VyRaTheme.textGrey,
                              fontSize: 14,
                            ),
                          ).animate(delay: 300.ms).fadeIn(),
                        ],
                      ),
                    )
                  else
                    ..._nearbyVideos.asMap().entries.map((entry) {
                      final index = entry.key;
                      final video = entry.value;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: VideoPlayerWidget(
                          video: video,
                          isLiked: _isLiked[video.id] ?? false,
                          onLike: () => _handleLike(video.id),
                          onComment: () {},
                          onBuzz: () => _handleBuzz(video.id),
                          onShare: () => _handleShare(video),
                        ),
                      ).animate(delay: (index * 50).ms)
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: 0.1, end: 0);
                    }).toList(),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleLike(String videoId) async {
    try {
      final wasLiked = _isLiked[videoId] ?? false;
      setState(() {
        _isLiked[videoId] = !wasLiked;
      });
      await _apiService.likeVideo(videoId);
    } catch (e) {
      // Revert on error
      setState(() {
        _isLiked[videoId] = !(_isLiked[videoId] ?? false);
      });
    }
  }

  Future<void> _handleBuzz(String videoId) async {
    try {
      await _apiService.buzzVideo(videoId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('🔥 Buzz sent!'),
            backgroundColor: VyRaTheme.primaryCyan,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send buzz: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleShare(VideoItem video) async {
    try {
      // Call API to record share
      await _apiService.shareVideo(video.id);
      
      // Build share content
      final videoUrl = '${AppConfig.mediaUrl}/${video.videoUrl}';
      final shareText = video.description.isNotEmpty
          ? '${video.description}\n\nWatch on VyRaVerse: $videoUrl'
          : 'Check out this video on VyRaVerse!\n$videoUrl';
      
      // Show share options
      showModalBottomSheet(
        context: context,
        backgroundColor: VyRaTheme.darkGrey,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: VyRaTheme.textGrey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Share Video',
                style: TextStyle(
                  color: VyRaTheme.textWhite,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildShareOption(
                    Icons.share,
                    'Share',
                    () async {
                      Navigator.pop(context);
                      await Share.share(shareText);
                    },
                  ),
                  _buildShareOption(
                    Icons.copy,
                    'Copy Link',
                    () async {
                      Navigator.pop(context);
                      await Clipboard.setData(ClipboardData(text: videoUrl));
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Link copied to clipboard'),
                            backgroundColor: VyRaTheme.primaryCyan,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  _buildShareOption(
                    Icons.message,
                    'Message',
                    () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/chat');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Widget _buildShareOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: VyRaTheme.primaryBlack,
              shape: BoxShape.circle,
              border: Border.all(
                color: VyRaTheme.primaryCyan.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(icon, color: VyRaTheme.primaryCyan, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: VyRaTheme.textWhite,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showRadiusDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: VyRaTheme.darkGrey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: VyRaTheme.primaryCyan.withOpacity(0.3),
              width: 1,
            ),
          ),
          title: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  VyRaTheme.primaryCyan.withOpacity(0.2),
                  VyRaTheme.primaryCyan.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.tune, color: VyRaTheme.primaryCyan, size: 20),
                SizedBox(width: 8),
                Text(
                  'Search Radius',
                  style: TextStyle(
                    color: VyRaTheme.textWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      VyRaTheme.primaryCyan.withOpacity(0.15),
                      VyRaTheme.primaryCyan.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: VyRaTheme.primaryCyan.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  '${_radius.toStringAsFixed(1)} km',
                  style: const TextStyle(
                    color: VyRaTheme.primaryCyan,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Slider(
                value: _radius,
                min: 1.0,
                max: 50.0,
                divisions: 49,
                activeColor: VyRaTheme.primaryCyan,
                inactiveColor: VyRaTheme.mediumGrey,
                onChanged: (value) {
                  setDialogState(() => _radius = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: VyRaTheme.textGrey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _loadNearbyVideos();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: VyRaTheme.primaryCyan,
                foregroundColor: VyRaTheme.primaryBlack,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for map grid pattern
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = VyRaTheme.primaryCyan.withOpacity(0.1)
      ..strokeWidth = 1;

    // Draw grid lines
    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        paint,
      );
    }
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
