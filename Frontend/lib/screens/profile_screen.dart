import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/vyra_theme.dart';
import '../models/user_profile.dart';
import '../models/video_item.dart' show VideoItem, VideoAnalytics;
import '../models/profile_skin.dart';
import '../services/local_storage.dart';
import '../services/api_service.dart';
import 'profile_screen_video_player.dart';

// ============================================================================
// MAIN PROFILE SCREEN - THE MASTERPIECE
// ============================================================================
class ProfileScreen extends StatefulWidget {
  final String? username;
  final String? userId;
  final bool isViewingOther;

  const ProfileScreen({
    super.key,
    this.username,
    this.userId,
    this.isViewingOther = false,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> 
    with SingleTickerProviderStateMixin {
  final LocalStorageService _storage = LocalStorageService();
  final ApiService _apiService = ApiService();
  
  UserProfile? _profile;
  bool _isLoading = true;
  File? _profileImage;
  List<VideoItem> _videos = [];
  List<ProfileSkin> _skins = [];
  List<Map<String, dynamic>> _transactions = [];
  List<VideoAnalytics> _analytics = [];

  @override
  void initState() {
    super.initState();
    _initializeProfile();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _initializeProfile() async {
    await _loadProfile();
    if (!widget.isViewingOther && mounted) {
      await Future.wait([_loadWallet(), _loadAnalytics()]);
    }
  }

  Future<void> _loadProfile() async {
    try {
      UserProfile? profile;
      List<VideoItem> videos = [];
      
      if (widget.isViewingOther && widget.username != null) {
        // Load other user's profile and their videos from API
        profile = await _apiService.getProfileByUsername(widget.username!);
        if (profile != null) {
          videos = await _apiService.getVideos(username: profile.username);
        } else {
          // If profile not found, show error
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('User not found'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      } else {
        // Load current user's profile and their videos from API
        profile = await _apiService.getProfile();
        if (profile != null && profile.username.isNotEmpty) {
          videos = await _apiService.getVideos(username: profile.username);
        }
      }
      
      if (mounted) {
        setState(() {
          _profile = profile;
          _videos = videos;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      // Only fallback to local storage if viewing own profile and API fails
      if (!widget.isViewingOther) {
        final fallback = await _storage.getUserProfile();
        if (fallback != null && mounted) {
          final allVideos = await _storage.getVideos();
          setState(() {
            _profile = fallback;
            _videos = allVideos.where((v) => v.username == fallback.username).toList();
            _isLoading = false;
          });
        } else if (mounted) {
          setState(() => _isLoading = false);
        }
      } else {
        // When viewing other user, don't use fallback - show error
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load profile: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _loadWallet() async {
    try {
      final skins = await _apiService.getProfileSkins();
      final transactions = await _apiService.getVyraPointsTransactions();
      if (mounted) {
        setState(() {
          _skins = skins;
          _transactions = transactions;
        });
      }
    } catch (e) {
      debugPrint('Wallet load error: $e');
    }
  }

  Future<void> _loadAnalytics() async {
    try {
      final analytics = await _apiService.getMyAnalytics();
      if (mounted) setState(() => _analytics = analytics);
    } catch (e) {
      debugPrint('Analytics load error: $e');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    // Use pickMedia to support all image formats (jpg, png, gif, webp, bmp, etc.)
    final picked = await picker.pickMedia(
      imageQuality: 85, // Maintain good quality while reducing file size
    );
    if (picked != null && mounted) {
      try {
        // Check if it's an image by checking mime type first, then file extension
        bool isImage = false;
        
        // Check mime type if available
        final mimeType = picked.mimeType?.toLowerCase() ?? '';
        if (mimeType.startsWith('image/')) {
          isImage = true;
        } else {
          // Fallback to file extension check
          final fileName = picked.name.toLowerCase();
          final imageExtensions = [
            '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', 
            '.heic', '.heif', '.tiff', '.tif', '.ico', '.svg',
            '.raw', '.cr2', '.nef', '.orf', '.sr2', '.dng'
          ];
          isImage = imageExtensions.any((ext) => fileName.endsWith(ext)) || 
                    fileName.contains('image') ||
                    fileName.isEmpty; // If no extension, assume it's valid from pickMedia
        }
        
        if (isImage || picked.mimeType == null) {
          // Accept the image - pickMedia should only return images anyway
          final imageFile = File(picked.path);
          setState(() => _profileImage = imageFile);
          
          // Automatically upload the profile image
          await _uploadProfileImage(imageFile);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please select a valid image file'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        // If there's any error, try to accept it anyway since pickMedia should filter
        debugPrint('Image picker error: $e');
        try {
          final imageFile = File(picked.path);
          setState(() => _profileImage = imageFile);
          
          // Try to upload even if there was a validation error
          await _uploadProfileImage(imageFile);
        } catch (fileError) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error loading image: ${fileError.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    }
  }

  Future<void> _uploadProfileImage(File imageFile) async {
    if (!await imageFile.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image file not found'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      setState(() => _isLoading = true);
      
      final success = await _apiService.updateProfile({}, profileImage: imageFile);
      
      if (mounted) {
        setState(() => _isLoading = false);
        
        if (success) {
          // Clear local image state - will use server image after reload
          setState(() => _profileImage = null);
          
          // Reload profile to get updated image URL
          await _loadProfile();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Profile picture updated successfully!'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to upload profile picture'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editProfile() async {
    if (_profile == null) return;
    
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => _EditDialog(profile: _profile!),
    );

    if (result != null && mounted) {
      final updated = _profile!.copyWith(
        displayName: result['displayName'],
        bio: result['bio'],
      );
      await _storage.saveUserProfile(updated);
      setState(() => _profile = updated);
    }
  }

  Future<void> _handleFollow() async {
    if (_profile == null || _isLoading) return;
    
    setState(() => _isLoading = true);

    try {
      final success = _profile!.isFollowing
          ? await _apiService.unfollowUser(_profile!.id)
          : await _apiService.followUser(_profile!.id);

      if (success && mounted) {
        final wasFollowing = _profile!.isFollowing;
        setState(() {
          _profile = _profile!.copyWith(
            isFollowing: !wasFollowing,
            followersCount: wasFollowing 
                ? (_profile!.followersCount - 1).clamp(0, 999999999)
                : _profile!.followersCount + 1,
          );
          _isLoading = false;
        });
        _showSnack(!wasFollowing ? 'Following ✨' : 'Unfollowed');
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack('Connection error', isError: true);
    }
  }

  Future<void> _purchaseSkin(ProfileSkin skin) async {
    try {
      final result = await _apiService.purchaseSkin(skin.id);
      if (mounted) {
        _showSnack('Skin unlocked! ✨ ${result['remainingPoints']} points left');
        await Future.wait([_loadProfile(), _loadWallet()]);
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
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  // ============================================================================
  // BUILD METHOD - THE EXPERIENCE BEGINS
  // ============================================================================
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: VyRaTheme.primaryBlack,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [VyRaTheme.primaryCyan, const Color(0xFF00D4FF)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: VyRaTheme.primaryCyan.withOpacity(0.5),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const CircularProgressIndicator(
                  color: VyRaTheme.primaryBlack,
                  strokeWidth: 3,
                ),
              ).animate(onPlay: (c) => c.repeat())
                  .shimmer(duration: 1500.ms, color: Colors.white.withOpacity(0.5))
                  .shake(duration: 1500.ms, hz: 2),
              const SizedBox(height: 24),
              Text(
                'Loading Profile...',
                style: TextStyle(
                  color: VyRaTheme.textGrey,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ).animate(onPlay: (c) => c.repeat())
                  .fadeIn(duration: 800.ms)
                  .then()
                  .fadeOut(duration: 800.ms),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: VyRaTheme.primaryBlack,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildGlowingAppBar(),
          SliverToBoxAdapter(
            child: widget.isViewingOther
                ? _buildOtherUserLayout()
                : _buildOwnProfileLayout(),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // GLOWING ANIMATED APP BAR
  // ============================================================================
  Widget _buildGlowingAppBar() {
    return SliverAppBar(
      expandedHeight: 220,
      floating: false,
      pinned: true,
      backgroundColor: VyRaTheme.primaryBlack,
      leading: widget.isViewingOther ? _buildGlassButton(
        Icons.arrow_back_ios_new,
        () => Navigator.pop(context),
      ) : null,
      actions: !widget.isViewingOther ? [
        _buildGlassButton(Icons.settings_rounded, () {
          Navigator.pushNamed(context, '/settings');
        }),
      ] : null,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                VyRaTheme.primaryCyan.withOpacity(0.3),
                Colors.transparent,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: VyRaTheme.primaryCyan.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Text(
            _profile?.displayName ?? _profile?.username ?? 'Profile',
            style: const TextStyle(
              color: VyRaTheme.textWhite,
              fontWeight: FontWeight.w800,
              fontSize: 18,
              letterSpacing: 0.5,
              shadows: [
                Shadow(color: VyRaTheme.primaryCyan, blurRadius: 20),
                Shadow(color: VyRaTheme.primaryCyan, blurRadius: 40),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.3, end: 0),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Animated gradient background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    VyRaTheme.primaryBlack,
                    VyRaTheme.primaryCyan.withOpacity(0.15),
                    const Color(0xFF00D4FF).withOpacity(0.1),
                    VyRaTheme.darkGrey,
                  ],
                  stops: const [0.0, 0.3, 0.6, 1.0],
                ),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
                .shimmer(duration: 3000.ms, color: VyRaTheme.primaryCyan.withOpacity(0.1)),
            // Floating particles effect
            ...List.generate(15, (i) => Positioned(
              left: (i * 50.0) % 400,
              top: (i * 30.0) % 200,
              child: Container(
                width: 4 + (i % 3) * 2,
                height: 4 + (i % 3) * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: VyRaTheme.primaryCyan.withOpacity(0.3),
                  boxShadow: [
                    BoxShadow(
                      color: VyRaTheme.primaryCyan.withOpacity(0.5),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true))
                  .moveY(
                    begin: 0,
                    end: -30 - (i % 20),
                    duration: (2000 + i * 100).ms,
                  )
                  .fadeIn(duration: 1000.ms)
                  .then()
                  .fadeOut(duration: 1000.ms),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassButton(IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                VyRaTheme.darkGrey.withOpacity(0.6),
                VyRaTheme.darkGrey.withOpacity(0.3),
              ],
            ),
            border: Border.all(
              color: VyRaTheme.primaryCyan.withOpacity(0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: VyRaTheme.primaryCyan.withOpacity(0.3),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(icon, color: VyRaTheme.primaryCyan, size: 20),
        ),
      ).animate().scale(delay: 100.ms).shimmer(
        duration: 2000.ms,
        color: VyRaTheme.primaryCyan.withOpacity(0.2),
      ),
    );
  }

  // ============================================================================
  // OTHER USER LAYOUT
  // ============================================================================
  Widget _buildOtherUserLayout() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              _buildMagneticAvatar(),
              const SizedBox(height: 12),
              _buildNameSection(),
              const SizedBox(height: 12),
              _buildNeonStatsGrid(),
              const SizedBox(height: 12),
              _buildFollowActionBar(),
              if (_profile?.bio != null && _profile!.bio!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _profile!.bio!,
                    style: TextStyle(
                      color: VyRaTheme.textWhite,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const Divider(color: VyRaTheme.darkGrey, height: 1),
        _buildVideoGallery(),
      ],
    );
  }

  // ============================================================================
  // OWN PROFILE LAYOUT
  // ============================================================================
  Widget _buildOwnProfileLayout() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMagneticAvatar(),
              const SizedBox(height: 12),
              _buildNameSection(),
              const SizedBox(height: 12),
              _buildNeonStatsGrid(),
              const SizedBox(height: 12),
              _buildCompactVyRaPoints(),
              const SizedBox(height: 12),
              _buildEditActions(),
              if (_profile?.bio != null && _profile!.bio!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _profile!.bio!,
                    style: TextStyle(
                      color: VyRaTheme.textWhite,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 1,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                VyRaTheme.primaryCyan.withOpacity(0.5),
                Colors.transparent,
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 1,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          color: VyRaTheme.darkGrey.withOpacity(0.5),
        ),
        const SizedBox(height: 4),
        _buildVideosTab(),
      ],
    );
  }

  // ============================================================================
  // MAGNETIC LEVITATING AVATAR
  // ============================================================================
  Widget _buildMagneticAvatar() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main avatar container
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: _profile?.isVerified == true
                ? LinearGradient(
                    colors: [
                      VyRaTheme.primaryCyan,
                      const Color(0xFF00D4FF),
                      VyRaTheme.primaryCyan,
                    ],
                  )
                : LinearGradient(
                    colors: [
                      VyRaTheme.lightGrey.withOpacity(0.3),
                      VyRaTheme.lightGrey.withOpacity(0.1),
                    ],
                  ),
            boxShadow: _profile?.isVerified == true
                ? [
                    BoxShadow(
                      color: VyRaTheme.primaryCyan.withOpacity(0.6),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                    BoxShadow(
                      color: const Color(0xFF00D4FF).withOpacity(0.4),
                      blurRadius: 50,
                      spreadRadius: 10,
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: ClipOval(
              child: _profileImage != null
                  ? Image.file(_profileImage!, fit: BoxFit.cover)
                  : _profile?.profileImageUrl != null
                      ? Image.network(
                          _profile!.profileImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildDefaultAvatar(),
                        )
                      : _buildDefaultAvatar(),
            ),
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true))
            .shimmer(duration: 2500.ms, color: Colors.white.withOpacity(0.3))
            .scale(
              begin: const Offset(1, 1),
              end: const Offset(1.03, 1.03),
              duration: 2000.ms,
            ),
        // Edit button for own profile
        if (!widget.isViewingOther)
          Positioned(
            bottom: 5,
            right: 5,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [VyRaTheme.primaryCyan, Color(0xFF00D4FF)],
                  ),
                  border: Border.all(color: VyRaTheme.primaryBlack, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: VyRaTheme.primaryCyan.withOpacity(0.8),
                      blurRadius: 20,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: VyRaTheme.primaryBlack,
                  size: 12,
                ),
              ).animate(onPlay: (c) => c.repeat())
                  .scale(
                    duration: 1500.ms,
                    begin: const Offset(1, 1),
                    end: const Offset(1.15, 1.15),
                  )
                  .then()
                  .scale(
                    duration: 1500.ms,
                    begin: const Offset(1.15, 1.15),
                    end: const Offset(1, 1),
                  ),
            ),
          ),
        // Verified badge
        if (_profile?.isVerified == true)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [VyRaTheme.primaryCyan, Color(0xFF00D4FF)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: VyRaTheme.primaryCyan.withOpacity(0.8),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.verified,
                color: VyRaTheme.primaryBlack,
                size: 20,
              ),
            ).animate(onPlay: (c) => c.repeat())
                .rotate(duration: 3000.ms, begin: 0, end: 1)
                .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.5)),
          ),
      ],
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            VyRaTheme.mediumGrey,
            VyRaTheme.darkGrey,
          ],
        ),
      ),
      child: const Icon(
        Icons.person_rounded,
        color: VyRaTheme.textWhite,
        size: 40,
      ),
    );
  }

  // ============================================================================
  // NAME & BIO SECTION
  // ============================================================================
  Widget _buildNameSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _profile?.displayName ?? _profile?.username ?? 'VyRaVerse User',
              style: const TextStyle(
                color: VyRaTheme.textWhite,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (_profile?.isVerified == true) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.verified,
                color: VyRaTheme.primaryCyan,
                size: 18,
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '@${_profile?.username ?? 'username'}',
          style: TextStyle(
            color: VyRaTheme.textGrey,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // TIKTOK-STYLE STATS ROW
  // ============================================================================
  Widget _buildNeonStatsGrid() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildSimpleStat(
          _formatCount(_profile?.followersCount ?? 0),
          'Followers',
          () {
            if (_profile != null) {
              Navigator.pushNamed(context, '/followers', arguments: {
                'userId': _profile!.id,
                'username': _profile!.username,
                'type': 'followers',
              });
            }
          },
        ),
        _buildSimpleStat(
          _formatCount(_profile?.followingCount ?? 0),
          'Following',
          () {
            if (_profile != null) {
              Navigator.pushNamed(context, '/followers', arguments: {
                'userId': _profile!.id,
                'username': _profile!.username,
                'type': 'following',
              });
            }
          },
        ),
        _buildSimpleStat(
          _formatCount(_profile?.totalBuzz ?? 0),
          'Buzz',
          null,
        ),
      ],
    );
  }

  Widget _buildSimpleStat(String value, String label, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: VyRaTheme.textWhite,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: VyRaTheme.textGrey,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHoloStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    VoidCallback? onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.2),
              color.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.5), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.2),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 15,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(icon, color: color, size: 24),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  duration: 1500.ms,
                  begin: const Offset(1, 1),
                  end: const Offset(1.1, 1.1),
                ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                shadows: [
                  Shadow(color: color, blurRadius: 15),
                ],
              ),
            ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3, end: 0),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: VyRaTheme.textGrey.withOpacity(0.9),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.9, 0.9)),
    );
  }

  Widget _buildCompactVyRaPoints() {
    return GestureDetector(
      onTap: () => _navigateToWallet(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFD700).withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFFFD700).withOpacity(0.4),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.stars_rounded,
              color: const Color(0xFFFFD700),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              '${_formatCount(_profile?.vyraPoints ?? 0)} VyRa Points',
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToWallet() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _WalletScreen(
          profile: _profile,
          skins: _skins,
          transactions: _transactions,
          onPurchaseSkin: _purchaseSkin,
        ),
      ),
    );
  }

  Widget _buildVyRaPointsCard() {
    return GestureDetector(
      onTap: () {
        if (!widget.isViewingOther) {
          _navigateToWallet();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFFFD700).withOpacity(0.3),
              const Color(0xFFFFA500).withOpacity(0.2),
              const Color(0xFFFF8C00).withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFFFD700), width: 2.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withOpacity(0.5),
              blurRadius: 25,
              spreadRadius: 3,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withOpacity(0.6),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.stars_rounded,
                color: VyRaTheme.primaryBlack,
                size: 24,
              ),
            ).animate(onPlay: (c) => c.repeat())
                .rotate(duration: 3000.ms, begin: 0, end: 1)
                .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.5)),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'VYRA POINTS',
                  style: TextStyle(
                    color: const Color(0xFFFFD700).withOpacity(0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatCount(_profile?.vyraPoints ?? 0),
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    shadows: [
                      Shadow(color: Color(0xFFFFD700), blurRadius: 20),
                    ],
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true))
                    .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.3)),
              ],
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: const Color(0xFFFFD700).withOpacity(0.8),
              size: 20,
            ).animate(onPlay: (c) => c.repeat(reverse: true))
                .moveX(duration: 1000.ms, begin: 0, end: 5),
          ],
        ),
      ).animate().fadeIn(delay: 400.ms, duration: 800.ms).slideX(begin: 0.3, end: 0),
    );
  }

  // ============================================================================
  // FOLLOW ACTION BAR
  // ============================================================================
  Widget _buildFollowActionBar() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _isLoading ? null : _handleFollow,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                gradient: _profile?.isFollowing == true
                    ? LinearGradient(
                        colors: [
                          VyRaTheme.darkGrey,
                          VyRaTheme.darkGrey.withOpacity(0.8),
                        ],
                      )
                    : const LinearGradient(
                        colors: [VyRaTheme.primaryCyan, Color(0xFF00D4FF)],
                      ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _profile?.isFollowing == true
                      ? VyRaTheme.lightGrey.withOpacity(0.3)
                      : VyRaTheme.primaryCyan,
                  width: 2,
                ),
                boxShadow: _profile?.isFollowing == true
                    ? []
                    : [
                        BoxShadow(
                          color: VyRaTheme.primaryCyan.withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
              ),
              child: _isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: VyRaTheme.primaryBlack,
                          strokeWidth: 3,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _profile?.isFollowing == true
                              ? Icons.check_circle_rounded
                              : Icons.person_add_rounded,
                          color: _profile?.isFollowing == true
                              ? VyRaTheme.textWhite
                              : VyRaTheme.primaryBlack,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _profile?.isFollowing == true ? 'Following' : 'Follow',
                          style: TextStyle(
                            color: _profile?.isFollowing == true
                                ? VyRaTheme.textWhite
                                : VyRaTheme.primaryBlack,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
            ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.95, 0.95)),
          ),
        ),
        const SizedBox(width: 12),
        _buildGlassActionButton(Icons.message_rounded, () {
          Navigator.pushNamed(context, '/chat', arguments: {
            'userId': _profile?.id,
            'username': _profile?.username,
          });
        }),
        const SizedBox(width: 8),
        _buildGlassActionButton(Icons.more_vert_rounded, () {
          _showUserMenu();
        }),
      ],
    ).animate().fadeIn(delay: 600.ms, duration: 600.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildGlassActionButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              VyRaTheme.darkGrey.withOpacity(0.6),
              VyRaTheme.darkGrey.withOpacity(0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: VyRaTheme.primaryCyan.withOpacity(0.4),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: VyRaTheme.primaryCyan.withOpacity(0.2),
              blurRadius: 15,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Icon(icon, color: VyRaTheme.primaryCyan, size: 20),
      ),
    );
  }

  void _showUserMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              VyRaTheme.darkGrey,
              VyRaTheme.primaryBlack,
            ],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: VyRaTheme.primaryCyan.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: VyRaTheme.textGrey.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 24),
            _buildMenuOption(Icons.block_rounded, 'Block User', Colors.red, () async {
              Navigator.pop(ctx);
              final confirm = await _showConfirmDialog(
                'Block User',
                'Are you sure you want to block ${_profile?.username}?',
              );
              if (confirm == true) _blockUser();
            }),
            const SizedBox(height: 12),
            _buildMenuOption(Icons.flag_rounded, 'Report User', Colors.orange, () {
              Navigator.pop(ctx);
              _showReportDialog();
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.2),
              color.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.4), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showConfirmDialog(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: VyRaTheme.darkGrey,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: VyRaTheme.primaryCyan.withOpacity(0.3), width: 2),
        ),
        title: Text(title, style: const TextStyle(color: VyRaTheme.textWhite)),
        content: Text(message, style: const TextStyle(color: VyRaTheme.textGrey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: VyRaTheme.textGrey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _blockUser() async {
    try {
      await _apiService.blockUser(_profile!.id);
      if (mounted) {
        _showSnack('User blocked', isError: true);
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnack(e.toString(), isError: true);
    }
  }

  void _showReportDialog() {
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
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: VyRaTheme.primaryCyan.withOpacity(0.3), width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Report User',
              style: TextStyle(
                color: VyRaTheme.textWhite,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 24),
            ...[
              ('Spam', Icons.report_rounded),
              ('Harassment', Icons.warning_rounded),
              ('Inappropriate Content', Icons.block_rounded),
              ('Other', Icons.more_horiz_rounded),
            ].map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildReportOption(item.$1, item.$2, () {
                Navigator.pop(ctx);
                _showSnack('Report submitted. Thank you! 🙏');
              }),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildReportOption(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              VyRaTheme.primaryCyan.withOpacity(0.1),
              Colors.transparent,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: VyRaTheme.primaryCyan.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: VyRaTheme.primaryCyan, size: 20),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                color: VyRaTheme.textWhite,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // EDIT ACTIONS
  // ============================================================================
  Widget _buildEditActions() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _editProfile,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [VyRaTheme.primaryCyan, Color(0xFF00D4FF)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: VyRaTheme.primaryCyan.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.edit_rounded, color: VyRaTheme.primaryBlack, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Edit Profile',
                    style: TextStyle(
                      color: VyRaTheme.primaryBlack,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.95, 0.95)),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0);
  }


  Widget _buildVideosTab() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildGlowingBadges(),
              const SizedBox(height: 20),
            ],
          ),
        ),
        _buildVideoGallery(),
      ],
    );
  }

  Widget _buildWalletTab() {
    return DefaultTabController(
      length: 2,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenHeight = MediaQuery.of(context).size.height;
          final headerHeight = 200;
          final tabBarHeight = 50;
          final availableHeight = (screenHeight * 0.5).clamp(400.0, 600.0);
          
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: _buildVyRaPointsCard(),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      VyRaTheme.darkGrey.withOpacity(0.5),
                      VyRaTheme.darkGrey.withOpacity(0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFFD700).withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: TabBar(
                  indicator: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withOpacity(0.5),
                        blurRadius: 15,
                      ),
                    ],
                  ),
                  labelColor: VyRaTheme.primaryBlack,
                  unselectedLabelColor: VyRaTheme.textGrey,
                  labelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                  tabs: const [
                    Tab(text: 'Skins Store'),
                    Tab(text: 'Transactions'),
                  ],
                ),
              ),
              SizedBox(
                height: availableHeight,
                child: TabBarView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildSkinsGrid(),
                    _buildTransactionsList(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    if (_analytics.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    VyRaTheme.primaryCyan.withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Icon(
                Icons.analytics_outlined,
                size: 48,
                color: VyRaTheme.textGrey.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No analytics yet',
              style: TextStyle(
                color: VyRaTheme.textGrey,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Upload videos to see your stats',
              style: TextStyle(
                color: VyRaTheme.textGrey.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        Row(
          children: [
            Expanded(child: _buildAnalyticsCard(
              'Total Views',
              _analytics.fold(0, (sum, a) => sum + a.totalViews).toString(),
              Icons.visibility_rounded,
              VyRaTheme.primaryCyan,
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildAnalyticsCard(
              'Avg Engagement',
              '${(_analytics.fold(0.0, (sum, a) => sum + a.engagementRate) / _analytics.length).toStringAsFixed(1)}%',
              Icons.trending_up_rounded,
              const Color(0xFFFF6B35),
            )),
          ],
        ),
        const SizedBox(height: 16),
        _buildViewsChart(),
        const SizedBox(height: 16),
        _buildTopHashtags(),
      ],
    );
  }

  Widget _buildAnalyticsCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 15,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: color,
                    fontSize: 18,
              fontWeight: FontWeight.w900,
              shadows: [Shadow(color: color, blurRadius: 15)],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: VyRaTheme.textGrey,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildViewsChart() {
    if (_analytics.isEmpty) return const SizedBox.shrink();
    
    final viewsData = _analytics.first.viewsPerDay;
    if (viewsData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              VyRaTheme.darkGrey.withOpacity(0.5),
              VyRaTheme.darkGrey.withOpacity(0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: VyRaTheme.primaryCyan.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: const Center(
          child: Text(
            'No view data yet',
            style: TextStyle(color: VyRaTheme.textGrey, fontSize: 16),
          ),
        ),
      );
    }

    final maxViews = viewsData.values.reduce((a, b) => a > b ? a : b);
    final spots = viewsData.entries
        .take(7)
        .toList()
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.value.toDouble()))
        .toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            VyRaTheme.darkGrey.withOpacity(0.5),
            VyRaTheme.darkGrey.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: VyRaTheme.primaryCyan.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: VyRaTheme.primaryCyan.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.show_chart_rounded,
                  color: VyRaTheme.primaryCyan,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Views Over Time',
                style: TextStyle(
                  color: VyRaTheme.textWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxViews / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: VyRaTheme.primaryCyan.withOpacity(0.1),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: VyRaTheme.primaryCyan,
                    barWidth: 4,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 6,
                          color: VyRaTheme.primaryCyan,
                          strokeWidth: 3,
                          strokeColor: VyRaTheme.primaryBlack,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          VyRaTheme.primaryCyan.withOpacity(0.3),
                          VyRaTheme.primaryCyan.withOpacity(0.05),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    shadow: Shadow(
                      color: VyRaTheme.primaryCyan.withOpacity(0.5),
                      blurRadius: 10,
                    ),
                  ),
                ],
                minY: 0,
                maxY: maxViews.toDouble() * 1.2,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildTopHashtags() {
    final allHashtags = <String, int>{};
    for (var analytics in _analytics) {
      for (var tag in analytics.topHashtags) {
        allHashtags[tag] = (allHashtags[tag] ?? 0) + 1;
      }
    }

    final topHashtags = allHashtags.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (topHashtags.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            VyRaTheme.darkGrey.withOpacity(0.5),
            VyRaTheme.darkGrey.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: VyRaTheme.primaryCyan.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: VyRaTheme.primaryCyan.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.tag_rounded,
                  color: VyRaTheme.primaryCyan,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Top Hashtags',
                style: TextStyle(
                  color: VyRaTheme.textWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...topHashtags.take(5).map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    VyRaTheme.primaryCyan.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: VyRaTheme.primaryCyan.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: VyRaTheme.primaryCyan.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.tag_rounded,
                      color: VyRaTheme.primaryCyan,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '#${entry.key}',
                      style: const TextStyle(
                        color: VyRaTheme.primaryCyan,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: VyRaTheme.primaryCyan.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${entry.value}',
                      style: const TextStyle(
                        color: VyRaTheme.primaryCyan,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0);
  }

  // ============================================================================
  // GLOWING BADGES
  // ============================================================================
  Widget _buildGlowingBadges() {
    if (_profile?.badges.isEmpty ?? true) {
      return const SizedBox.shrink(); // Remove huge trophy icon
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withOpacity(0.5),
                    blurRadius: 15,
                  ),
                ],
              ),
              child: const Icon(Icons.emoji_events_rounded, color: VyRaTheme.primaryBlack, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Badges',
              style: TextStyle(
                color: VyRaTheme.textWhite,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFFD700).withOpacity(0.3),
                    const Color(0xFFFFA500).withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFFFD700).withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              child: Text(
                '${_profile!.badges.length}',
                style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ).animate().fadeIn().slideX(begin: -0.2, end: 0),
        const SizedBox(height: 20),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: _profile!.badges.asMap().entries.map((entry) {
            final index = entry.key;
            final badge = entry.value;
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFFFD700).withOpacity(0.3),
                    const Color(0xFFFFA500).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFFFD700),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withOpacity(0.6),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      color: VyRaTheme.primaryBlack,
                      size: 24,
                    ),
                  ).animate(onPlay: (c) => c.repeat())
                      .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.5))
                      .rotate(duration: 3000.ms, begin: 0, end: 0.05)
                      .then()
                      .rotate(duration: 3000.ms, begin: 0.05, end: 0),
                  const SizedBox(height: 14),
                  Text(
                    badge,
                    style: const TextStyle(
                      color: VyRaTheme.textWhite,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ).animate(delay: (index * 100).ms).fadeIn(duration: 600.ms).scale(begin: const Offset(0.8, 0.8));
          }).toList(),
        ),
      ],
    );
  }

  // ============================================================================
  // VIDEO GALLERY
  // ============================================================================
  Widget _buildVideoGallery() {
    if (_videos.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              VyRaTheme.darkGrey.withOpacity(0.5),
              VyRaTheme.darkGrey.withOpacity(0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFB026FF).withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Icon(
                Icons.video_library_outlined,
                size: 48,
                color: VyRaTheme.textGrey.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No videos yet',
              style: TextStyle(
                color: VyRaTheme.textGrey,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start creating to see videos here',
              style: TextStyle(
                color: VyRaTheme.textGrey.withOpacity(0.7),
                fontSize: 15,
              ),
            ),
          ],
        ),
      ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9));
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.75,
      ),
      itemCount: _videos.length,
      itemBuilder: (ctx, index) => _buildVideoCard(_videos[index], index),
    );
  }

  Widget _buildVideoCard(VideoItem video, int index) {
    return GestureDetector(
      onTap: () {
        // Navigate to full-screen video player (TikTok-style)
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
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              VyRaTheme.darkGrey,
              VyRaTheme.darkGrey.withOpacity(0.7),
            ],
          ),
          border: Border.all(
            color: VyRaTheme.primaryCyan.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: VyRaTheme.primaryCyan.withOpacity(0.2),
              blurRadius: 15,
              spreadRadius: 1,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              (video.thumbnailUrl != null || video.videoUrl != null)
                  ? Image.network(
                      video.thumbnailUrl ?? video.videoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildVideoPlaceholder(),
                    )
                  : _buildVideoPlaceholder(),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
              ),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(14),
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
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: VyRaTheme.primaryBlack,
                    size: 22,
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                left: 10,
                right: 10,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _formatCount(video.likes),
                        style: const TextStyle(
                          color: VyRaTheme.textWhite,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          shadows: [
                            Shadow(color: Colors.black, blurRadius: 8),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ).animate(delay: (index * 50).ms).fadeIn(duration: 500.ms).scale(begin: const Offset(0.8, 0.8)),
    );
  }

  Widget _buildVideoPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            VyRaTheme.mediumGrey,
            VyRaTheme.darkGrey,
          ],
        ),
      ),
      child: const Icon(
        Icons.play_circle_outline_rounded,
        color: VyRaTheme.primaryCyan,
        size: 36,
      ),
    );
  }

  // ============================================================================
  // SKINS GRID
  // ============================================================================
  Widget _buildSkinsGrid() {
    if (_skins.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFFD700).withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Icon(
                Icons.palette_outlined,
                size: 48,
                color: VyRaTheme.textGrey.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No skins available',
              style: TextStyle(
                color: VyRaTheme.textGrey,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: _skins.length,
      itemBuilder: (ctx, index) => _buildSkinCard(_skins[index], index),
    );
  }

  Widget _buildSkinCard(ProfileSkin skin, int index) {
    final canAfford = (_profile?.vyraPoints ?? 0) >= skin.costPoints;
    
    return GestureDetector(
      onTap: () => _showSkinDialog(skin),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: skin.isPremium
                ? [
                    const Color(0xFFFFD700).withOpacity(0.3),
                    const Color(0xFFFFA500).withOpacity(0.1),
                  ]
                : [
                    VyRaTheme.darkGrey,
                    VyRaTheme.darkGrey.withOpacity(0.5),
                  ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: skin.isPremium
                ? const Color(0xFFFFD700)
                : VyRaTheme.primaryCyan.withOpacity(0.4),
            width: skin.isPremium ? 2.5 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: skin.isPremium
                  ? const Color(0xFFFFD700).withOpacity(0.4)
                  : VyRaTheme.primaryCyan.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Color(int.parse(skin.primaryColor.replaceFirst('#', '0xFF'))),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Color(int.parse(skin.primaryColor.replaceFirst('#', '0xFF'))).withOpacity(0.5),
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: skin.previewImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          skin.previewImage!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.palette_rounded,
                          color: Color(int.parse(skin.secondaryColor.replaceFirst('#', '0xFF'))),
                          size: 32,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              skin.name,
              style: const TextStyle(
                color: VyRaTheme.textWhite,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.stars_rounded, color: Color(0xFFFFD700), size: 18),
                const SizedBox(width: 6),
                Text(
                  '${skin.costPoints}',
                  style: TextStyle(
                    color: canAfford ? const Color(0xFFFFD700) : Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ).animate(delay: (index * 100).ms).fadeIn(duration: 600.ms).scale(begin: const Offset(0.85, 0.85)),
    );
  }

  void _showSkinDialog(ProfileSkin skin) {
    final canAfford = (_profile?.vyraPoints ?? 0) >= skin.costPoints;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: VyRaTheme.darkGrey,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: skin.isPremium
                ? const Color(0xFFFFD700)
                : VyRaTheme.primaryCyan.withOpacity(0.5),
            width: 2,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                skin.name,
                style: const TextStyle(
                  color: VyRaTheme.textWhite,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (skin.isPremium)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'PREMIUM',
                  style: TextStyle(
                    color: VyRaTheme.primaryBlack,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (skin.previewImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(skin.previewImage!, height: 200),
              ),
            const SizedBox(height: 16),
            Text(
              skin.description,
              style: const TextStyle(
                color: VyRaTheme.textGrey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFFD700).withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFFFD700).withOpacity(0.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.stars_rounded, color: Color(0xFFFFD700), size: 20),
                  const SizedBox(width: 10),
                  Text(
                    '${skin.costPoints} Points',
                    style: TextStyle(
                      color: canAfford ? const Color(0xFFFFD700) : Colors.red,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: VyRaTheme.textGrey)),
          ),
          ElevatedButton(
            onPressed: canAfford
                ? () {
                    Navigator.pop(ctx);
                    _purchaseSkin(skin);
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: VyRaTheme.primaryCyan,
              disabledBackgroundColor: VyRaTheme.darkGrey,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Purchase',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TRANSACTIONS LIST
  // ============================================================================
  Widget _buildTransactionsList() {
    if (_transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFFD700).withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 48,
                color: VyRaTheme.textGrey.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No transactions yet',
              style: TextStyle(
                color: VyRaTheme.textGrey,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: _transactions.length,
      itemBuilder: (ctx, index) {
        final tx = _transactions[index];
        final isEarned = tx['transactionType'] == 'earned' || tx['transactionType'] == 'reward';
        final color = isEarned ? Colors.green : Colors.red;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.15),
                color.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withOpacity(0.4), width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 15,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isEarned ? Icons.add_circle_rounded : Icons.remove_circle_rounded,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx['description'] ?? 'Transaction',
                      style: const TextStyle(
                        color: VyRaTheme.textWhite,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tx['createdAt'] ?? '',
                      style: TextStyle(
                        color: VyRaTheme.textGrey.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${isEarned ? '+' : '-'}${tx['points'] ?? 0}',
                  style: TextStyle(
                    color: color,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ).animate(delay: (index * 50).ms).fadeIn(duration: 500.ms).slideX(begin: -0.2, end: 0);
      },
    );
  }
}

// ============================================================================
// EDIT PROFILE DIALOG
// ============================================================================
class _EditDialog extends StatefulWidget {
  final UserProfile profile;

  const _EditDialog({required this.profile});

  @override
  State<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<_EditDialog> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.displayName);
    _bioController = TextEditingController(text: widget.profile.bio);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: VyRaTheme.darkGrey,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(
          color: VyRaTheme.primaryCyan.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              VyRaTheme.darkGrey,
              VyRaTheme.darkGrey.withOpacity(0.8),
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [VyRaTheme.primaryCyan, Color(0xFF00D4FF)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    color: VyRaTheme.primaryBlack,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Edit Profile',
                  style: TextStyle(
                    color: VyRaTheme.textWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            _buildTextField(
              controller: _nameController,
              label: 'Display Name',
              icon: Icons.person_rounded,
              maxLines: 1,
            ),
            const SizedBox(height: 18),
            _buildTextField(
              controller: _bioController,
              label: 'Bio',
              icon: Icons.description_rounded,
              maxLines: 4,
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: VyRaTheme.textGrey,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, {
                      'displayName': _nameController.text,
                      'bio': _bioController.text,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VyRaTheme.primaryCyan,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 14,
                    ),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      color: VyRaTheme.primaryBlack,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required int maxLines,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            VyRaTheme.primaryBlack.withOpacity(0.5),
            VyRaTheme.primaryBlack.withOpacity(0.3),
          ],
        ),
        border: Border.all(
          color: VyRaTheme.primaryCyan.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(
          color: VyRaTheme.textWhite,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: VyRaTheme.textGrey.withOpacity(0.8),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Icon(icon, color: VyRaTheme.primaryCyan, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.all(18),
        ),
      ),
    );
  }
}

// ============================================================================
// WALLET SCREEN
// ============================================================================
class _WalletScreen extends StatefulWidget {
  final UserProfile? profile;
  final List<ProfileSkin> skins;
  final List<Map<String, dynamic>> transactions;
  final Function(ProfileSkin) onPurchaseSkin;

  const _WalletScreen({
    required this.profile,
    required this.skins,
    required this.transactions,
    required this.onPurchaseSkin,
  });

  @override
  State<_WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<_WalletScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VyRaTheme.primaryBlack,
      appBar: AppBar(
        backgroundColor: VyRaTheme.primaryBlack,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: VyRaTheme.textWhite),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'VyRa Wallet',
          style: TextStyle(
            color: VyRaTheme.textWhite,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildVyRaPointsCard(),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  VyRaTheme.darkGrey.withOpacity(0.5),
                  VyRaTheme.darkGrey.withOpacity(0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFFD700).withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withOpacity(0.5),
                    blurRadius: 15,
                  ),
                ],
              ),
              labelColor: VyRaTheme.primaryBlack,
              unselectedLabelColor: VyRaTheme.textGrey,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
              tabs: const [
                Tab(text: 'Skins Store'),
                Tab(text: 'Transactions'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const BouncingScrollPhysics(),
              children: [
                _buildSkinsGrid(),
                _buildTransactionsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVyRaPointsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFFD700).withOpacity(0.3),
            const Color(0xFFFFA500).withOpacity(0.2),
            const Color(0xFFFF8C00).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFD700), width: 2.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.5),
            blurRadius: 25,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withOpacity(0.6),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.stars_rounded,
              color: VyRaTheme.primaryBlack,
              size: 24,
            ),
          ).animate(onPlay: (c) => c.repeat())
              .rotate(duration: 3000.ms, begin: 0, end: 1)
              .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.5)),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'VYRA POINTS',
                style: TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_formatCount(widget.profile?.vyraPoints ?? 0)}',
                style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  shadows: [
                    Shadow(
                      color: Color(0xFFFFD700),
                      blurRadius: 20,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  Widget _buildSkinsGrid() {
    if (widget.skins.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFFD700).withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Icon(
                Icons.palette_outlined,
                size: 48,
                color: VyRaTheme.textGrey.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No skins available',
              style: TextStyle(
                color: VyRaTheme.textGrey,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: widget.skins.length,
      itemBuilder: (ctx, index) => _buildSkinCard(widget.skins[index], index),
    );
  }

  Widget _buildSkinCard(ProfileSkin skin, int index) {
    final canAfford = (widget.profile?.vyraPoints ?? 0) >= skin.costPoints;
    
    return GestureDetector(
      onTap: () => _showSkinDialog(skin),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: skin.isPremium
                ? [
                    const Color(0xFFFFD700).withOpacity(0.3),
                    const Color(0xFFFFA500).withOpacity(0.1),
                  ]
                : [
                    VyRaTheme.darkGrey,
                    VyRaTheme.darkGrey.withOpacity(0.5),
                  ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: skin.isPremium
                ? const Color(0xFFFFD700)
                : VyRaTheme.primaryCyan.withOpacity(0.4),
            width: skin.isPremium ? 2.5 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: skin.isPremium
                  ? const Color(0xFFFFD700).withOpacity(0.4)
                  : VyRaTheme.primaryCyan.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Color(int.parse(skin.primaryColor.replaceFirst('#', '0xFF'))),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Color(int.parse(skin.primaryColor.replaceFirst('#', '0xFF'))).withOpacity(0.5),
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: skin.previewImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          skin.previewImage!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.palette_rounded,
                          color: Color(int.parse(skin.secondaryColor.replaceFirst('#', '0xFF'))),
                          size: 32,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              skin.name,
              style: const TextStyle(
                color: VyRaTheme.textWhite,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.stars_rounded, color: Color(0xFFFFD700), size: 18),
                const SizedBox(width: 6),
                Text(
                  '${skin.costPoints}',
                  style: TextStyle(
                    color: canAfford ? const Color(0xFFFFD700) : Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ).animate(delay: (index * 100).ms).fadeIn(duration: 500.ms).scale(begin: const Offset(0.8, 0.8)),
    );
  }

  void _showSkinDialog(ProfileSkin skin) {
    final canAfford = (widget.profile?.vyraPoints ?? 0) >= skin.costPoints;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: VyRaTheme.darkGrey,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: skin.isPremium
                ? const Color(0xFFFFD700)
                : VyRaTheme.primaryCyan.withOpacity(0.5),
            width: 2,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                skin.name,
                style: const TextStyle(
                  color: VyRaTheme.textWhite,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (skin.isPremium)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'PREMIUM',
                  style: TextStyle(
                    color: VyRaTheme.primaryBlack,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (skin.previewImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(skin.previewImage!, height: 200),
              ),
            const SizedBox(height: 16),
            Text(
              skin.description,
              style: const TextStyle(
                color: VyRaTheme.textGrey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFFD700).withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFFFD700).withOpacity(0.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.stars_rounded, color: Color(0xFFFFD700), size: 20),
                  const SizedBox(width: 10),
                  Text(
                    '${skin.costPoints} Points',
                    style: TextStyle(
                      color: canAfford ? const Color(0xFFFFD700) : Colors.red,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: VyRaTheme.textGrey)),
          ),
          ElevatedButton(
            onPressed: canAfford
                ? () {
                    widget.onPurchaseSkin(skin);
                    Navigator.pop(context);
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: VyRaTheme.primaryCyan,
              disabledBackgroundColor: Colors.grey,
            ),
            child: const Text('Purchase', style: TextStyle(color: VyRaTheme.primaryBlack)),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    if (widget.transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: VyRaTheme.textGrey.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            const Text(
              'No transactions yet',
              style: TextStyle(
                color: VyRaTheme.textGrey,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: widget.transactions.length,
      itemBuilder: (ctx, index) {
        final tx = widget.transactions[index];
        final isEarned = tx['transactionType'] == 'earned' || tx['transactionType'] == 'reward';
        final color = isEarned ? Colors.green : Colors.red;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.15),
                color.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withOpacity(0.4), width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 15,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isEarned ? Icons.add_circle_rounded : Icons.remove_circle_rounded,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx['description'] ?? 'Transaction',
                      style: const TextStyle(
                        color: VyRaTheme.textWhite,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tx['createdAt'] ?? '',
                      style: TextStyle(
                        color: VyRaTheme.textGrey.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${isEarned ? '+' : '-'}${tx['points'] ?? 0}',
                  style: TextStyle(
                    color: color,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ).animate(delay: (index * 50).ms).fadeIn(duration: 500.ms).slideX(begin: -0.2, end: 0);
      },
    );
  }
}