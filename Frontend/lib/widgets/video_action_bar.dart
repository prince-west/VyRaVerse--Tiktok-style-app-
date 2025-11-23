import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/vyra_theme.dart';

class VideoActionBar extends StatelessWidget {
  final int likes;
  final int comments;
  final int buzz;
  final int shares;
  final bool isLiked;
  final bool isBuzzed;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onBuzz;
  final VoidCallback onShare;
  final VoidCallback? onBoost;
  final int? boostScore;
  final VoidCallback? onProfileTap;
  final String? profileImageUrl;

  const VideoActionBar({
    super.key,
    required this.likes,
    required this.comments,
    required this.buzz,
    required this.shares,
    required this.isLiked,
    required this.isBuzzed,
    required this.onLike,
    required this.onComment,
    required this.onBuzz,
    required this.onShare,
    this.onBoost,
    this.boostScore,
    this.onProfileTap,
    this.profileImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (onProfileTap != null)
          GestureDetector(
            onTap: onProfileTap,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: VyRaTheme.primaryCyan, width: 1.5),
                boxShadow: VyRaTheme.neonGlow,
              ),
              child: profileImageUrl != null
                  ? ClipOval(
                      child: Image.network(
                        profileImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildDefaultAvatar(),
                      ),
                    )
                  : _buildDefaultAvatar(),
            ),
          ),
        const SizedBox(height: 12),
        _buildActionButton(
          icon: isLiked ? Icons.favorite : Icons.favorite_border,
          label: _formatCount(likes),
          onTap: onLike,
          isActive: isLiked,
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          icon: Icons.chat_bubble_outline,
          label: _formatCount(comments),
          onTap: onComment,
        ),
        const SizedBox(height: 12),
        _buildBuzzButton(),
        const SizedBox(height: 12),
        _buildActionButton(
          icon: Icons.share_outlined,
          label: _formatCount(shares),
          onTap: onShare,
        ),
        if (onBoost != null) ...[
          const SizedBox(height: 12),
          _buildActionButton(
            icon: Icons.rocket_launch,
            label: boostScore != null ? _formatCount(boostScore!) : 'Boost',
            onTap: onBoost!,
            isActive: boostScore != null && boostScore! > 0,
          ),
        ],
      ],
    );
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

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: isActive
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: VyRaTheme.neonGlow,
                  )
                : null,
            child: Icon(
              icon,
              color: isActive ? Colors.red : VyRaTheme.textWhite,
              size: 20,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: VyRaTheme.textWhite,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuzzButton() {
    return GestureDetector(
      onTap: onBuzz,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: isBuzzed
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.6),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: Colors.deepOrange.withOpacity(0.4),
                        blurRadius: 5,
                        spreadRadius: 1,
                      ),
                    ],
                  )
                : null,
            child: isBuzzed
                ? Icon(
                    Icons.local_fire_department,
                    color: Colors.orange,
                    size: 20,
                  )
                    .animate(onPlay: (controller) => controller.repeat())
                    .shimmer(
                      duration: const Duration(milliseconds: 800),
                      color: Colors.deepOrange.withOpacity(0.8),
                    )
                    .then()
                    .tint(
                      color: Colors.deepOrange,
                      duration: const Duration(milliseconds: 400),
                    )
                    .then()
                    .tint(
                      color: Colors.orange,
                      duration: const Duration(milliseconds: 400),
                    )
                : Icon(
                    Icons.local_fire_department,
                    color: Colors.orange.withOpacity(0.7),
                    size: 20,
                  ),
          ),
          Text(
            _formatCount(buzz),
            style: TextStyle(
              color: isBuzzed 
                  ? Colors.orange.withOpacity(0.9)
                  : Colors.orange.withOpacity(0.7),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
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
}

