import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/vyra_theme.dart';
import '../models/user_profile.dart';
import '../services/api_service.dart';
import 'profile_screen.dart';

class FindFriendsScreen extends StatefulWidget {
  const FindFriendsScreen({super.key});

  @override
  State<FindFriendsScreen> createState() => _FindFriendsScreenState();
}

class _FindFriendsScreenState extends State<FindFriendsScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  List<UserProfile> _suggestedUsers = [];
  List<UserProfile> _searchResults = [];
  bool _isLoading = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadSuggestedUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestedUsers() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final users = await _apiService.getSuggestedUsers();
      if (mounted) {
        setState(() {
          _suggestedUsers = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _isLoading = true;
    });

    try {
      final users = await _apiService.searchUsers(query);
      if (mounted) {
        setState(() {
          _searchResults = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Expanded(child: Text('Search failed. Please try again.')),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VyRaTheme.primaryBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                VyRaTheme.primaryBlack,
                VyRaTheme.darkGrey,
                VyRaTheme.primaryBlack,
              ],
            ),
          ),
        ),
        title: Container(
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
              Icon(
                Icons.person_search_rounded,
                color: VyRaTheme.primaryCyan,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Find Friends',
                style: TextStyle(
                  color: VyRaTheme.textWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2, end: 0),
        centerTitle: true,
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
      ),
      body: Column(
        children: [
          // Enhanced Search Bar
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              gradient: LinearGradient(
                colors: [
                  VyRaTheme.darkGrey,
                  VyRaTheme.mediumGrey,
                ],
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
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Search by username...',
                hintStyle: TextStyle(
                  color: VyRaTheme.textGrey.withOpacity(0.7),
                  fontSize: 16,
                ),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(8),
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
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
              onChanged: (value) {
                setState(() {}); // Update UI for clear button
                if (value.isEmpty) {
                  _performSearch('');
                } else {
                  // Debounce search
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (_searchController.text == value && mounted) {
                      _performSearch(value);
                    }
                  });
                }
              },
              onSubmitted: _performSearch,
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),
          
          // Content
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
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
                        const SizedBox(height: 20),
                        Text(
                          _isSearching ? 'Searching...' : 'Loading suggestions...',
                          style: const TextStyle(
                            color: VyRaTheme.textGrey,
                            fontSize: 14,
                          ),
                        ).animate().fadeIn(delay: 200.ms),
                      ],
                    ),
                  )
                : _isSearching
                    ? _buildSearchResults()
                    : _buildSuggestedUsers(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return Center(
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
              child: Icon(
                Icons.search_off_rounded,
                color: VyRaTheme.textGrey,
                size: 48,
              ),
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),
            const Text(
              'No users found',
              style: TextStyle(
                color: VyRaTheme.textWhite,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ).animate(delay: 200.ms).fadeIn(),
            const SizedBox(height: 8),
            Text(
              'Try searching with a different username',
              style: const TextStyle(
                color: VyRaTheme.textGrey,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ).animate(delay: 300.ms).fadeIn(),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return _buildUserCard(_searchResults[index], index);
      },
    );
  }

  Widget _buildSuggestedUsers() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: VyRaTheme.primaryCyan.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: VyRaTheme.primaryCyan,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Suggested For You',
                style: TextStyle(
                  color: VyRaTheme.textWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2, end: 0),
        Expanded(
          child: _suggestedUsers.isEmpty
              ? Center(
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
                        child: Icon(
                          Icons.people_outline_rounded,
                          color: VyRaTheme.textGrey,
                          size: 48,
                        ),
                      ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                      const SizedBox(height: 24),
                      const Text(
                        'No suggestions available',
                        style: TextStyle(
                          color: VyRaTheme.textWhite,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ).animate(delay: 200.ms).fadeIn(),
                      const SizedBox(height: 8),
                      const Text(
                        'Try searching for someone!',
                        style: TextStyle(
                          color: VyRaTheme.textGrey,
                          fontSize: 14,
                        ),
                      ).animate(delay: 300.ms).fadeIn(),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _suggestedUsers.length,
                  itemBuilder: (context, index) {
                    return _buildUserCard(_suggestedUsers[index], index);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildUserCard(UserProfile user, int index) {
    return GestureDetector(
      onTap: () {
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
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              VyRaTheme.darkGrey,
              VyRaTheme.darkGrey.withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: VyRaTheme.primaryCyan.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: VyRaTheme.primaryCyan.withOpacity(0.08),
              blurRadius: 15,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          children: [
            // Enhanced Profile Picture
            GestureDetector(
              onTap: () {
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
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      VyRaTheme.primaryCyan,
                      VyRaTheme.primaryCyan.withOpacity(0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: VyRaTheme.primaryCyan.withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Container(
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: VyRaTheme.mediumGrey,
                    image: user.profileImageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(user.profileImageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: user.profileImageUrl == null
                      ? const Icon(
                          Icons.person,
                          color: VyRaTheme.textWhite,
                          size: 24,
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: () {
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '@${user.username}',
                            style: const TextStyle(
                              color: VyRaTheme.primaryCyan,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (user.isVerified) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: VyRaTheme.primaryCyan,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.verified,
                              color: VyRaTheme.primaryBlack,
                              size: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (user.displayName != null && user.displayName!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        user.displayName!,
                        style: const TextStyle(
                          color: VyRaTheme.textWhite,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: VyRaTheme.mediumGrey.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: VyRaTheme.primaryCyan.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.people_rounded,
                            color: VyRaTheme.primaryCyan,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '${_formatCount(user.followersCount)} followers',
                              style: const TextStyle(
                                color: VyRaTheme.textGrey,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
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
            ),
            const SizedBox(width: 12),
            // Enhanced Follow Button
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    VyRaTheme.primaryCyan,
                    VyRaTheme.primaryCyan.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: VyRaTheme.primaryCyan.withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    await _apiService.followUser(user.id);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check_circle, color: Colors.white, size: 18),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Followed successfully!',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: Colors.green.shade600,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          margin: const EdgeInsets.all(16),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                      // Refresh the list
                      if (_isSearching) {
                        _performSearch(_searchController.text);
                      } else {
                        _loadSuggestedUsers();
                      }
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.error, color: Colors.white, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Failed to follow: ${e.toString()}',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: Colors.red.shade700,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          margin: const EdgeInsets.all(16),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: VyRaTheme.primaryBlack,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_add, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Follow',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ).animate(delay: (index * 50).ms)
          .fadeIn(duration: 400.ms)
          .slideX(begin: 0.1, end: 0, duration: 400.ms),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}