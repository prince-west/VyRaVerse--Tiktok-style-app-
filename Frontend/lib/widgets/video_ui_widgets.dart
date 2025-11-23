import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/vyra_theme.dart';

// ============================================================================
// VIDEO UI WIDGETS - Loading, error, progress, thumbnail, stats
// ============================================================================

/// Loading shimmer widget for video placeholders
class VideoLoadingShimmer extends StatelessWidget {
  final double? width;
  final double? height;

  const VideoLoadingShimmer({
    super.key,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: VyRaTheme.darkGrey,
      highlightColor: VyRaTheme.darkGrey.withOpacity(0.5),
      child: Container(
        width: width ?? double.infinity,
        height: height ?? 300,
        decoration: BoxDecoration(
          color: VyRaTheme.darkGrey,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

/// Error widget for video playback failures
class VideoErrorWidget extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback? onRetry;

  const VideoErrorWidget({
    super.key,
    this.errorMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: VyRaTheme.primaryBlack,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Video unavailable',
              style: TextStyle(
                color: VyRaTheme.textWhite,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(
                    color: VyRaTheme.textGrey,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: VyRaTheme.primaryCyan,
                  foregroundColor: VyRaTheme.primaryBlack,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Progress indicator for video upload/download
class VideoProgressIndicator extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final String? label;
  final bool showPercentage;

  const VideoProgressIndicator({
    super.key,
    required this.progress,
    this.label,
    this.showPercentage = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: const TextStyle(
              color: VyRaTheme.textWhite,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: VyRaTheme.darkGrey,
            valueColor: const AlwaysStoppedAnimation<Color>(VyRaTheme.primaryCyan),
          ),
        ),
        if (showPercentage) ...[
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).toInt()}%',
            style: const TextStyle(
              color: VyRaTheme.textGrey,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}

/// Widget for displaying video thumbnails
class VideoThumbnailWidget extends StatelessWidget {
  final String? thumbnailUrl;
  final File? thumbnailFile;
  final String? videoUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const VideoThumbnailWidget({
    super.key,
    this.thumbnailUrl,
    this.thumbnailFile,
    this.videoUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    Widget? image;

    if (thumbnailFile != null) {
      image = Image.file(
        thumbnailFile!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) =>
            errorWidget ?? _defaultErrorWidget(),
      );
    } else if (thumbnailUrl != null && thumbnailUrl!.isNotEmpty) {
      image = CachedNetworkImage(
        imageUrl: thumbnailUrl!,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) =>
            placeholder ?? _defaultPlaceholder(),
        errorWidget: (context, url, error) =>
            errorWidget ?? _defaultErrorWidget(),
      );
    } else {
      image = _defaultPlaceholder();
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: VyRaTheme.darkGrey,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: image,
      ),
    );
  }

  Widget _defaultPlaceholder() {
    return Container(
      color: VyRaTheme.darkGrey,
      child: const Center(
        child: Icon(
          Icons.video_library,
          color: VyRaTheme.textGrey,
          size: 48,
        ),
      ),
    );
  }

  Widget _defaultErrorWidget() {
    return Container(
      color: VyRaTheme.darkGrey,
      child: const Center(
        child: Icon(
          Icons.broken_image,
          color: VyRaTheme.textGrey,
          size: 48,
        ),
      ),
    );
  }
}

/// Overlay widget showing video stats (views, likes) on thumbnail
class VideoStatsOverlay extends StatelessWidget {
  final int views;
  final int likes;
  final bool showViews;
  final bool showLikes;

  const VideoStatsOverlay({
    super.key,
    this.views = 0,
    this.likes = 0,
    this.showViews = true,
    this.showLikes = true,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 8,
      left: 8,
      right: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (showViews)
            _buildStat(Icons.visibility, _formatCount(views)),
          if (showLikes)
            _buildStat(Icons.favorite, _formatCount(likes)),
        ],
      ),
    );
  }

  Widget _buildStat(IconData icon, String count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: VyRaTheme.textWhite, size: 14),
          const SizedBox(width: 4),
          Text(
            count,
            style: const TextStyle(
              color: VyRaTheme.textWhite,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
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

