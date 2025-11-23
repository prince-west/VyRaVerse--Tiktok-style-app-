import 'package:flutter/material.dart';
import '../theme/vyra_theme.dart';
import '../models/user_profile.dart';
import '../services/api_service.dart';
import 'profile_screen.dart';

class FollowersScreen extends StatefulWidget {
  const FollowersScreen({super.key});

  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen> {
  final ApiService _apiService = ApiService();
  List<UserProfile> _users = [];
  bool _isLoading = true;
  String? _userId;
  String? _username;
  String? _type; // 'followers' or 'following'

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _userId = args['userId'] as String?;
      _username = args['username'] as String?;
      _type = args['type'] as String? ?? 'followers';
      _loadUsers();
    }
  }

  Future<void> _loadUsers() async {
    if (_userId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      List<UserProfile> users;
      if (_type == 'following') {
        users = await _apiService.getFollowing(_userId!);
      } else {
        users = await _apiService.getFollowers(_userId!);
      }

      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VyRaTheme.primaryBlack,
      appBar: AppBar(
        backgroundColor: VyRaTheme.primaryBlack,
        title: Text(
          _type == 'following' ? 'Following' : 'Followers',
          style: const TextStyle(color: VyRaTheme.textWhite),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: VyRaTheme.textWhite),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: VyRaTheme.primaryCyan),
            )
          : _users.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _type == 'following' ? Icons.person_add : Icons.people,
                        size: 80,
                        color: VyRaTheme.textGrey,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _type == 'following'
                            ? 'Not following anyone yet'
                            : 'No followers yet',
                        style: const TextStyle(
                          color: VyRaTheme.textGrey,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    return _buildUserItem(user);
                  },
                ),
    );
  }

  Widget _buildUserItem(UserProfile user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: VyRaTheme.darkGrey,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: VyRaTheme.primaryCyan.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
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
            child: CircleAvatar(
              radius: 30,
              backgroundColor: VyRaTheme.mediumGrey,
              backgroundImage: user.profileImageUrl != null
                  ? NetworkImage(user.profileImageUrl!)
                  : null,
              child: user.profileImageUrl == null
                  ? const Icon(
                      Icons.person,
                      color: VyRaTheme.textWhite,
                      size: 24,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user.displayName ?? user.username,
                      style: const TextStyle(
                        color: VyRaTheme.textWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (user.isVerified) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.verified,
                        color: VyRaTheme.primaryCyan,
                        size: 16,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '@${user.username}',
                  style: const TextStyle(
                    color: VyRaTheme.textGrey,
                    fontSize: 14,
                  ),
                ),
                if (user.bio != null && user.bio!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    user.bio!,
                    style: const TextStyle(
                      color: VyRaTheme.textGrey,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (_type == 'followers' && user.isFollowing != true)
            ElevatedButton(
              onPressed: () async {
                final success = await _apiService.followUser(user.id);
                if (success && mounted) {
                  setState(() {
                    _users = _users.map((u) {
                      if (u.id == user.id) {
                        return u.copyWith(isFollowing: true);
                      }
                      return u;
                    }).toList();
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: VyRaTheme.primaryCyan,
                foregroundColor: VyRaTheme.primaryBlack,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('Follow'),
            ),
        ],
      ),
    );
  }
}

