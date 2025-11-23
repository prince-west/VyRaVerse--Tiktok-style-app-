// ENHANCED SEARCH SCREEN
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/vyra_theme.dart';
import '../models/video_item.dart';
import '../models/user_profile.dart';
import '../services/api_service.dart';
import 'profile_screen_video_player.dart';
import 'profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();
  
  List<VideoItem> _videos = [];
  List<UserProfile> _users = [];
  List<String> _trendingHashtags = [];
  String _searchQuery = '';
  bool _isSearching = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTrending();
  }

  Future<void> _loadTrending() async {
    setState(() => _isLoading = true);
    try {
      final videos = await _apiService.getVideos();
      if (mounted) {
        setState(() {
          _videos = videos.take(10).toList();
          _trendingHashtags = _extractHashtags(videos);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<String> _extractHashtags(List<VideoItem> videos) {
    final hashtags = <String>{};
    for (var video in videos) {
      if (video.hashtags != null) {
        for (var tag in video.hashtags!) {
          hashtags.add(tag);
        }
      }
    }
    return hashtags.take(10).toList();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _searchQuery = '';
        _users = [];
      });
      _loadTrending();
      return;
    }

    setState(() {
      _isSearching = true;
      _isLoading = true;
      _searchQuery = query.trim();
    });

    try {
      final videos = await _apiService.searchVideos(_searchQuery);
      final users = await _apiService.searchUsers(_searchQuery);
      
      if (mounted) {
        setState(() {
          _videos = videos;
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
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
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        constraints: const BoxConstraints(maxHeight: 50),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          gradient: LinearGradient(
                            colors: [VyRaTheme.darkGrey, VyRaTheme.mediumGrey],
                          ),
                          border: Border.all(
                            color: VyRaTheme.primaryCyan.withOpacity(0.3),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: VyRaTheme.primaryCyan.withOpacity(0.1),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(
                            color: VyRaTheme.textWhite,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          onSubmitted: _performSearch,
                          decoration: InputDecoration(
                            hintText: 'Search videos, users, hashtags...',
                            hintStyle: TextStyle(
                              color: VyRaTheme.textGrey.withOpacity(0.7),
                              fontSize: 15,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(8),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: VyRaTheme.primaryCyan.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.search,
                                color: VyRaTheme.primaryCyan,
                                size: 20,
                              ),
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: VyRaTheme.mediumGrey,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.clear,
                                        color: VyRaTheme.textGrey,
                                        size: 16,
                                      ),
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      _performSearch('');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                          ),
                          onChanged: (value) {
                            setState(() {});
                            if (value.isEmpty) {
                              _performSearch('');
                            } else {
                              Future.delayed(const Duration(milliseconds: 500), () {
                                if (_searchController.text == value && mounted) {
                                  _performSearch(value);
                                }
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (!_isSearching)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
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
                          child: const Icon(
                            Icons.trending_up_rounded,
                            color: VyRaTheme.primaryCyan,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Trending Hashtags',
                          style: TextStyle(
                            color: VyRaTheme.textWhite,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2, end: 0),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _trendingHashtags.map((hashtag) {
                        return GestureDetector(
                          onTap: () {
                            _searchController.text = hashtag.substring(1);
                            _performSearch(hashtag.substring(1));
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  VyRaTheme.darkGrey,
                                  VyRaTheme.darkGrey.withOpacity(0.7),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: VyRaTheme.primaryCyan.withOpacity(0.5),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: VyRaTheme.primaryCyan.withOpacity(0.1),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.tag_rounded,
                                  color: VyRaTheme.primaryCyan,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  hashtag,
                                  style: const TextStyle(
                                    color: VyRaTheme.primaryCyan,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ).animate(delay: (hashtag.hashCode % 500).ms)
                              .fadeIn(duration: 400.ms)
                              .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
                        );
                      }).toList(),
                    ),
                  ],
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
          else if (_videos.isEmpty && _users.isEmpty && _isSearching)
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
                            VyRaTheme.mediumGrey.withOpacity(0.3),
                            VyRaTheme.mediumGrey.withOpacity(0.1),
                          ],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: VyRaTheme.textGrey.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.search_off_rounded,
                        color: VyRaTheme.textGrey,
                        size: 64,
                      ),
                    ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                    const SizedBox(height: 24),
                    const Text(
                      'No results found',
                      style: TextStyle(
                        color: VyRaTheme.textWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ).animate(delay: 200.ms).fadeIn(),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (_isSearching && _users.isNotEmpty && index < _users.length) {
                    return _buildUserCard(_users[index], index);
                  } else {
                    final videoIndex = _isSearching && _users.isNotEmpty 
                        ? index - _users.length 
                        : index;
                    if (videoIndex < _videos.length) {
                      return _buildVideoCard(_videos[videoIndex], videoIndex);
                    }
                  }
                  return const SizedBox.shrink();
                },
                childCount: _isSearching 
                    ? _users.length + _videos.length 
                    : _videos.length,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserCard(UserProfile user, int index) {
    return GestureDetector(
      onTap: () {
        // Navigate to the user's profile screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileScreen(
              username: user.username,
              userId: user.id,
              isViewingOther: true,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [VyRaTheme.darkGrey, VyRaTheme.darkGrey.withOpacity(0.7)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: VyRaTheme.primaryCyan.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [VyRaTheme.primaryCyan, VyRaTheme.primaryCyan.withOpacity(0.6)],
                ),
              ),
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: VyRaTheme.mediumGrey,
                ),
                child: const Icon(Icons.person, color: VyRaTheme.textWhite, size: 30),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '@${user.username}',
                    style: const TextStyle(
                      color: VyRaTheme.primaryCyan,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (user.displayName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      user.displayName!,
                      style: const TextStyle(
                        color: VyRaTheme.textWhite,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: ElevatedButton(
              onPressed: () async {
                try {
                  await _apiService.followUser(user.id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Followed successfully'),
                        backgroundColor: VyRaTheme.primaryCyan,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
                style: ElevatedButton.styleFrom(
                  backgroundColor: VyRaTheme.primaryCyan,
                  foregroundColor: VyRaTheme.primaryBlack,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Follow',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: (index * 50).ms).fadeIn(duration: 400.ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildVideoCard(VideoItem video, int index) {
    return GestureDetector(
      onTap: () {
        // Navigate to full-screen video player with all videos
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (ctx) => FullScreenVideoPlayer(
              videos: _videos,
              initialIndex: index,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              VyRaTheme.darkGrey,
              VyRaTheme.darkGrey.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: VyRaTheme.primaryCyan.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: VyRaTheme.primaryCyan.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          children: [
            // Video thumbnail with play overlay
            Container(
              width: 120,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: VyRaTheme.primaryCyan.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Video thumbnail
                    video.thumbnailUrl != null && video.thumbnailUrl!.isNotEmpty
                        ? Image.network(
                            video.thumbnailUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: VyRaTheme.mediumGrey,
                              child: const Icon(
                                Icons.video_library,
                                color: VyRaTheme.textGrey,
                                size: 30,
                              ),
                            ),
                          )
                        : Container(
                            color: VyRaTheme.mediumGrey,
                            child: const Icon(
                              Icons.video_library,
                              color: VyRaTheme.textGrey,
                              size: 30,
                            ),
                          ),
                    // Gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.6),
                          ],
                        ),
                      ),
                    ),
                    // Play button overlay
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              VyRaTheme.primaryCyan.withOpacity(0.9),
                              const Color(0xFF00D4FF).withOpacity(0.9),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: VyRaTheme.primaryCyan.withOpacity(0.6),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: VyRaTheme.primaryBlack,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '@${video.username}',
                    style: const TextStyle(
                      color: VyRaTheme.primaryCyan,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    video.description,
                    style: const TextStyle(
                      color: VyRaTheme.textWhite,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.favorite, color: Colors.red, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${video.likes}',
                        style: const TextStyle(
                          color: VyRaTheme.textGrey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.comment, color: VyRaTheme.textGrey, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${video.comments}',
                        style: const TextStyle(
                          color: VyRaTheme.textGrey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: (index * 50).ms).fadeIn(duration: 400.ms).slideX(begin: -0.1, end: 0);
  }
}