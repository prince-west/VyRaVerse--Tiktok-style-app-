import 'package:flutter/material.dart';
import '../theme/vyra_theme.dart';

/// Interactive buttons for video (like, comment, share, buzz)
class VideoInteractionButtons extends StatelessWidget {
  final int likes;
  final int comments;
  final int shares;
  final bool isLiked;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onBuzz;

  const VideoInteractionButtons({
    super.key,
    required this.likes,
    required this.comments,
    required this.shares,
    this.isLiked = false,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onBuzz,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildButton(
          icon: isLiked ? Icons.favorite : Icons.favorite_border,
          count: likes,
          onTap: onLike,
          color: isLiked ? Colors.red : VyRaTheme.textWhite,
        ),
        const SizedBox(height: 16),
        _buildButton(
          icon: Icons.comment_outlined,
          count: comments,
          onTap: onComment,
        ),
        const SizedBox(height: 16),
        _buildButton(
          icon: Icons.share_outlined,
          count: shares,
          onTap: onShare,
        ),
        const SizedBox(height: 16),
        if (onBuzz != null)
          _buildButton(
            icon: Icons.local_fire_department,
            count: 0,
            onTap: onBuzz,
            color: Colors.orange,
          ),
      ],
    );
  }

  Widget _buildButton({
    required IconData icon,
    required int count,
    VoidCallback? onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: VyRaTheme.darkGrey.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color ?? VyRaTheme.textWhite,
              size: 24,
            ),
          ),
          if (count > 0) ...[
            const SizedBox(height: 4),
            Text(
              _formatCount(count),
              style: const TextStyle(
                color: VyRaTheme.textWhite,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }
}

