import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/vyra_theme.dart';
import '../services/api_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _leaderboard = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _isLoading = true);
    final leaderboard = await _apiService.getLeaderboard();
    setState(() {
      _leaderboard = leaderboard;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VyRaTheme.primaryBlack,
      appBar: AppBar(
        backgroundColor: VyRaTheme.primaryBlack,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: VyRaTheme.textWhite),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Weekly Leaderboard',
          style: TextStyle(
            color: VyRaTheme.primaryCyan,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: VyRaTheme.primaryCyan),
            onPressed: _loadLeaderboard,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: VyRaTheme.primaryCyan),
            )
          : _leaderboard.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.emoji_events_outlined,
                        size: 80,
                        color: VyRaTheme.textGrey,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'No leaderboard data yet',
                        style: TextStyle(
                          color: VyRaTheme.textGrey,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Start engaging to earn points!',
                        style: TextStyle(
                          color: VyRaTheme.textGrey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _leaderboard.length,
                  itemBuilder: (context, index) {
                    final entry = _leaderboard[index];
                    final rank = index + 1;
                    final username = entry['user__username'] ?? 'Unknown';
                    final points = entry['total_points'] ?? 0;

                    return _buildLeaderboardItem(rank, username, points, index);
                  },
                ),
    );
  }

  Widget _buildLeaderboardItem(int rank, String username, int points, int index) {
    final isTopThree = rank <= 3;
    final rankColor = rank == 1
        ? Colors.amber
        : rank == 2
            ? Colors.grey[400]!
            : rank == 3
                ? Colors.brown[400]!
                : VyRaTheme.primaryCyan;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VyRaTheme.darkGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isTopThree
              ? rankColor.withOpacity(0.5)
              : VyRaTheme.primaryCyan.withOpacity(0.3),
          width: isTopThree ? 2 : 1,
        ),
        boxShadow: isTopThree
            ? [
                BoxShadow(
                  color: rankColor.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Rank Badge
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isTopThree ? rankColor : VyRaTheme.mediumGrey,
              boxShadow: isTopThree
                  ? [
                      BoxShadow(
                        color: rankColor.withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                rank == 1 ? '🥇' : rank == 2 ? '🥈' : rank == 3 ? '🥉' : '$rank',
                style: TextStyle(
                  color: isTopThree
                      ? VyRaTheme.primaryBlack
                      : VyRaTheme.textWhite,
                  fontSize: rank <= 3 ? 24 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '@$username',
                  style: TextStyle(
                    color: isTopThree ? rankColor : VyRaTheme.textWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.stars,
                      color: VyRaTheme.primaryCyan,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$points VyRa Points',
                      style: const TextStyle(
                        color: VyRaTheme.primaryCyan,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Trophy Icon for top 3
          if (isTopThree)
            Icon(
              Icons.emoji_events,
              color: rankColor,
              size: 24,
            ),
        ],
      ),
    ).animate(delay: (index * 50).ms).fadeIn(duration: 300.ms).slideX(
          begin: 0.1,
          end: 0,
          duration: 300.ms,
        );
  }
}

