import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/vyra_theme.dart';
import '../widgets/neon_appbar.dart';
import '../models/club.dart';
import '../models/video_item.dart';
import '../services/api_service.dart';
import '../widgets/video_player_widget.dart';
import '../config/app_config.dart';
import 'home_feed_screen.dart';

class ClubsScreen extends StatefulWidget {
  const ClubsScreen({super.key});

  @override
  State<ClubsScreen> createState() => _ClubsScreenState();
}

class _ClubsScreenState extends State<ClubsScreen> {
  final ApiService _apiService = ApiService();
  List<Club> _clubs = [];
  String? _selectedCategory;
  bool _isLoading = true;
  final List<String> _categories = [
    'All',
    'Music',
    'Tech',
    'Fashion',
    'Dance',
    'Comedy',
    'Art',
    'Food',
    'Fitness',
    'Gaming',
  ];

  @override
  void initState() {
    super.initState();
    _loadClubs();
  }

  Future<void> _loadClubs() async {
    setState(() => _isLoading = true);
    try {
      final clubs = await _apiService.getClubs(
        category: _selectedCategory == 'All' ? null : _selectedCategory,
      );
      if (mounted) {
        setState(() {
          _clubs = clubs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load clubs'),
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
      appBar: NeonAppBar(
        title: 'VyRa Clubs',
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
            icon: const Icon(Icons.add, color: VyRaTheme.primaryCyan),
            onPressed: () => _showCreateClubDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Category Filter
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category || 
                    (_selectedCategory == null && category == 'All');
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = category == 'All' ? null : category;
                    });
                    _loadClubs();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? VyRaTheme.primaryCyan : VyRaTheme.darkGrey,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected 
                            ? VyRaTheme.primaryCyan 
                            : VyRaTheme.primaryCyan.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        category,
                        style: TextStyle(
                          color: isSelected ? VyRaTheme.primaryBlack : VyRaTheme.textWhite,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Clubs List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: VyRaTheme.primaryCyan),
                  )
                : _clubs.isEmpty
                    ? Center(
                        child: Text(
                          'No clubs found',
                          style: const TextStyle(color: VyRaTheme.textGrey, fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _clubs.length,
                        itemBuilder: (context, index) {
                          return _buildClubCard(_clubs[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildClubCard(Club club) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/club-feed',
          arguments: {'clubId': club.id, 'clubName': club.name},
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: VyRaTheme.darkGrey,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: VyRaTheme.primaryCyan.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Club Cover
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: VyRaTheme.mediumGrey,
                borderRadius: BorderRadius.circular(12),
                image: club.coverImage != null
                    ? DecorationImage(
                        image: NetworkImage(club.coverImage!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: club.coverImage == null
                  ? const Icon(Icons.group, color: VyRaTheme.primaryCyan, size: 32)
                  : null,
            ),
            const SizedBox(width: 16),
            // Club Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    club.name,
                    style: const TextStyle(
                      color: VyRaTheme.textWhite,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    club.description,
                    style: const TextStyle(
                      color: VyRaTheme.textGrey,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.people, color: VyRaTheme.primaryCyan, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${club.memberCount} members',
                        style: const TextStyle(
                          color: VyRaTheme.textGrey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: VyRaTheme.primaryCyan.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          club.category,
                          style: const TextStyle(
                            color: VyRaTheme.primaryCyan,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, color: VyRaTheme.primaryCyan, size: 20),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/club-feed',
                  arguments: {'clubId': club.id, 'clubName': club.name},
                );
              },
            ),
          ],
        ),
      ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.2, end: 0, duration: 300.ms),
    );
  }

  void _showCreateClubDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    String selectedCategory = 'Music';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: VyRaTheme.darkGrey,
          title: const Text('Create Club', style: TextStyle(color: VyRaTheme.textWhite)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: VyRaTheme.textWhite),
                decoration: InputDecoration(
                  labelText: 'Club Name',
                  labelStyle: const TextStyle(color: VyRaTheme.textGrey),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: VyRaTheme.primaryCyan.withOpacity(0.3)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: VyRaTheme.primaryCyan),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                style: const TextStyle(color: VyRaTheme.textWhite),
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: const TextStyle(color: VyRaTheme.textGrey),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: VyRaTheme.primaryCyan.withOpacity(0.3)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: VyRaTheme.primaryCyan),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                dropdownColor: VyRaTheme.darkGrey,
                style: const TextStyle(color: VyRaTheme.textWhite),
                decoration: InputDecoration(
                  labelText: 'Category',
                  labelStyle: const TextStyle(color: VyRaTheme.textGrey),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: VyRaTheme.primaryCyan.withOpacity(0.3)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: VyRaTheme.primaryCyan),
                  ),
                ),
                items: _categories
                    .where((c) => c != 'All')
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => selectedCategory = value);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: VyRaTheme.textGrey)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                try {
                  await _apiService.createClub(
                    nameController.text.trim(),
                    descController.text.trim(),
                    selectedCategory,
                  );
                  if (mounted) {
                    Navigator.pop(context);
                    _loadClubs();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Club created successfully!'),
                        backgroundColor: VyRaTheme.primaryCyan,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString()),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: VyRaTheme.primaryButton,
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}

// Club Feed Screen - merged from club_feed_screen.dart
class ClubFeedScreen extends StatefulWidget {
  final String clubId;
  final String clubName;

  const ClubFeedScreen({
    super.key,
    required this.clubId,
    required this.clubName,
  });

  @override
  State<ClubFeedScreen> createState() => _ClubFeedScreenState();
}

class _ClubFeedScreenState extends State<ClubFeedScreen> {
  final ApiService _apiService = ApiService();
  List<VideoItem> _videos = [];
  bool _isLoading = true;
  final Map<String, bool> _isLiked = {};

  @override
  void initState() {
    super.initState();
    _loadClubFeed();
  }

  Future<void> _loadClubFeed() async {
    setState(() => _isLoading = true);
    try {
      final videos = await _apiService.getClubFeed(widget.clubId);
      if (mounted) {
        setState(() {
          _videos = videos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load club feed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleLike(String videoId) async {
    try {
      final wasLiked = _isLiked[videoId] ?? false;
      setState(() {
        _isLiked[videoId] = !wasLiked;
      });
      await _apiService.likeVideo(videoId);
    } catch (e) {
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
                  fontSize: 16,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VyRaTheme.primaryBlack,
      appBar: AppBar(
        backgroundColor: VyRaTheme.primaryBlack,
        elevation: 0,
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
        title: Text(
          widget.clubName,
          style: const TextStyle(
            color: VyRaTheme.textWhite,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: VyRaTheme.primaryCyan),
            )
          : _videos.isEmpty
              ? Center(
                  child: Text(
                    'No videos in this club yet',
                    style: const TextStyle(color: VyRaTheme.textGrey, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: _videos.length,
                  itemBuilder: (context, index) {
                    final video = _videos[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: VideoPlayerWidget(
                        video: video,
                        isLiked: _isLiked[video.id] ?? false,
                        onLike: () => _handleLike(video.id),
                        onComment: () {},
                        onBuzz: () => _handleBuzz(video.id),
                        onShare: () => _handleShare(video),
                      ),
                    );
                  },
                ),
    );
  }
}

