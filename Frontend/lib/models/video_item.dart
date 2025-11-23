import 'dart:io';
import 'package:flutter/foundation.dart' show debugPrint;

// ============================================================================
// VIDEO MODELS - All video-related data models
// ============================================================================

class VideoItem {
  final String id;
  final String username;
  final String userId;
  final String description;
  final String? videoUrl;
  final String? videoPath;
  final bool isLocal;
  final int likes;
  final int comments;
  final int shares;
  final int buzzCount;
  final String? privacy;
  final String? location;
  final List<String> hashtags;
  final bool allowComments;
  final bool allowDuet;
  final bool allowStitch;
  final int boostScore;
  final String collabType;
  final bool sensitiveFlag;
  final double? latitude;
  final double? longitude;
  final String? soundId;
  final DateTime createdAt;
  final String? thumbnailUrl;

  VideoItem({
    required this.id,
    required this.username,
    required this.userId,
    required this.description,
    this.videoUrl,
    this.videoPath,
    this.isLocal = false,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.buzzCount = 0,
    this.privacy = 'Public',
    this.location,
    this.hashtags = const [],
    this.allowComments = true,
    this.allowDuet = true,
    this.allowStitch = true,
    this.boostScore = 0,
    this.collabType = 'none',
    this.sensitiveFlag = false,
    this.latitude,
    this.longitude,
    this.soundId,
    DateTime? createdAt,
    this.thumbnailUrl,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'userId': userId,
        'description': description,
        'videoUrl': videoUrl,
        'videoPath': videoPath,
        'isLocal': isLocal,
        'likes': likes,
        'comments': comments,
        'shares': shares,
        'buzzCount': buzzCount,
        'privacy': privacy,
        'location': location,
        'hashtags': hashtags,
        'allowComments': allowComments,
        'allowDuet': allowDuet,
        'allowStitch': allowStitch,
        'boostScore': boostScore,
        'collabType': collabType,
        'sensitiveFlag': sensitiveFlag,
        'latitude': latitude,
        'longitude': longitude,
        'soundId': soundId,
        'createdAt': createdAt.toIso8601String(),
        'thumbnailUrl': thumbnailUrl,
      };

  factory VideoItem.fromJson(Map<String, dynamic> json) {
    // Handle videoUrl - check multiple possible field names
    String? videoUrl = json['videoUrl'] as String?;
    if (videoUrl == null || videoUrl.isEmpty) {
      videoUrl = json['video_url'] as String?;
    }
    if (videoUrl == null || videoUrl.isEmpty) {
      videoUrl = json['videoFile'] as String?;
    }
    if (videoUrl == null || videoUrl.isEmpty) {
      videoUrl = json['video_file'] as String?;
    }
    // Check if video_file is an object with a url property
    if (videoUrl == null && json['video_file'] is Map) {
      final videoFileObj = json['video_file'] as Map<String, dynamic>;
      videoUrl = videoFileObj['url'] as String?;
    }
    // Clean up URL - remove null string
    if (videoUrl == 'null' || videoUrl == null || videoUrl.isEmpty) {
      videoUrl = null;
    }
    
    // Debug logging
    if (videoUrl == null) {
      debugPrint('VideoItem.fromJson: No videoUrl found. Available keys: ${json.keys.toList()}');
      debugPrint('  videoUrl: ${json['videoUrl']}');
      debugPrint('  video_url: ${json['video_url']}');
      debugPrint('  videoFile: ${json['videoFile']}');
      debugPrint('  video_file: ${json['video_file']}');
    } else {
      debugPrint('VideoItem.fromJson: Found videoUrl: $videoUrl');
    }
    
    return VideoItem(
        id: json['id']?.toString() ?? '',
        username: json['username'] as String? ?? '',
        userId: json['userId']?.toString() ?? json['user_id']?.toString() ?? '',
        description: json['description'] as String? ?? '',
        videoUrl: videoUrl,
        videoPath: json['videoPath'] as String? ?? json['video_path'] as String?,
        isLocal: json['isLocal'] as bool? ?? json['is_local'] as bool? ?? false,
        likes: json['likes'] as int? ?? 0,
        comments: json['comments'] as int? ?? 0,
        shares: json['shares'] as int? ?? 0,
        buzzCount: json['buzzCount'] as int? ?? json['buzz_count'] as int? ?? 0,
        privacy: json['privacy'] as String?,
        location: json['location'] as String?,
        hashtags: (json['hashtags'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        allowComments: json['allowComments'] as bool? ?? json['allow_comments'] as bool? ?? true,
        allowDuet: json['allowDuet'] as bool? ?? json['allow_duet'] as bool? ?? true,
        allowStitch: json['allowStitch'] as bool? ?? json['allow_stitch'] as bool? ?? true,
        boostScore: json['boostScore'] as int? ?? json['boost_score'] as int? ?? 0,
        collabType: json['collabType'] as String? ?? json['collab_type'] as String? ?? 'none',
        sensitiveFlag: json['sensitiveFlag'] as bool? ?? json['sensitive_flag'] as bool? ?? false,
        latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
        longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
        soundId: json['soundId']?.toString() ?? json['sound_id']?.toString(),
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : (json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null),
        thumbnailUrl: json['thumbnailUrl'] as String? ?? json['thumbnail_url'] as String?,
      );
  }

  VideoItem copyWith({
    String? id,
    String? username,
    String? userId,
    String? description,
    String? videoUrl,
    String? videoPath,
    bool? isLocal,
    int? likes,
    int? comments,
    int? shares,
    int? buzzCount,
    String? privacy,
    String? location,
    List<String>? hashtags,
    bool? allowComments,
    bool? allowDuet,
    bool? allowStitch,
    int? boostScore,
    String? collabType,
    bool? sensitiveFlag,
    double? latitude,
    double? longitude,
    String? soundId,
    DateTime? createdAt,
    String? thumbnailUrl,
  }) =>
      VideoItem(
        id: id ?? this.id,
        username: username ?? this.username,
        userId: userId ?? this.userId,
        description: description ?? this.description,
        videoUrl: videoUrl ?? this.videoUrl,
        videoPath: videoPath ?? this.videoPath,
        isLocal: isLocal ?? this.isLocal,
        likes: likes ?? this.likes,
        comments: comments ?? this.comments,
        shares: shares ?? this.shares,
        buzzCount: buzzCount ?? this.buzzCount,
        privacy: privacy ?? this.privacy,
        location: location ?? this.location,
        hashtags: hashtags ?? this.hashtags,
        allowComments: allowComments ?? this.allowComments,
        allowDuet: allowDuet ?? this.allowDuet,
        allowStitch: allowStitch ?? this.allowStitch,
        boostScore: boostScore ?? this.boostScore,
        collabType: collabType ?? this.collabType,
        sensitiveFlag: sensitiveFlag ?? this.sensitiveFlag,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        soundId: soundId ?? this.soundId,
        createdAt: createdAt ?? this.createdAt,
        thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      );
}

// ============================================================================
// Video Metadata Model
// ============================================================================

/// Video metadata model for video information
class VideoMetadata {
  final Duration duration;
  final int fileSizeBytes;
  final int width;
  final int height;
  final double aspectRatio;
  final String format; // mp4, mov, etc.
  final int bitrate;
  final double frameRate;
  final bool hasAudio;

  const VideoMetadata({
    required this.duration,
    required this.fileSizeBytes,
    required this.width,
    required this.height,
    required this.aspectRatio,
    required this.format,
    this.bitrate = 0,
    this.frameRate = 0,
    this.hasAudio = true,
  });

  String get fileSizeMB => (fileSizeBytes / (1024 * 1024)).toStringAsFixed(2);
  String get fileSizeFormatted => _formatBytes(fileSizeBytes);
  String get durationFormatted => _formatDuration(duration);
  bool get isPortrait => height > width;
  bool get isLandscape => width > height;
  bool get isSquare => width == height;

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toJson() => {
        'duration': duration.inMilliseconds,
        'fileSizeBytes': fileSizeBytes,
        'width': width,
        'height': height,
        'aspectRatio': aspectRatio,
        'format': format,
        'bitrate': bitrate,
        'frameRate': frameRate,
        'hasAudio': hasAudio,
      };

  factory VideoMetadata.fromJson(Map<String, dynamic> json) => VideoMetadata(
        duration: Duration(milliseconds: json['duration'] as int),
        fileSizeBytes: json['fileSizeBytes'] as int,
        width: json['width'] as int,
        height: json['height'] as int,
        aspectRatio: (json['aspectRatio'] as num).toDouble(),
        format: json['format'] as String,
        bitrate: json['bitrate'] as int? ?? 0,
        frameRate: (json['frameRate'] as num?)?.toDouble() ?? 0,
        hasAudio: json['hasAudio'] as bool? ?? true,
      );
}

// ============================================================================
// Video Compression Result Model
// ============================================================================

/// Video compression result model
class VideoCompressionResult {
  final File compressedFile;
  final String path;
  final int originalSizeBytes;
  final int compressedSizeBytes;
  final double compressionRatio;
  final Duration duration;
  final bool success;
  final String? errorMessage;

  const VideoCompressionResult({
    required this.compressedFile,
    required this.path,
    required this.originalSizeBytes,
    required this.compressedSizeBytes,
    required this.compressionRatio,
    required this.duration,
    this.success = true,
    this.errorMessage,
  });

  String get originalSizeMB => (originalSizeBytes / (1024 * 1024)).toStringAsFixed(2);
  String get compressedSizeMB => (compressedSizeBytes / (1024 * 1024)).toStringAsFixed(2);
  String get sizeReduction => '${((1 - compressionRatio) * 100).toStringAsFixed(1)}%';
}

// ============================================================================
// Video Filter Model
// ============================================================================

/// Video filter model for AR filters and effects
class VideoFilter {
  final String id;
  final String name;
  final String displayName;
  final String? iconUrl;
  final FilterType type;
  final Map<String, dynamic>? parameters;

  const VideoFilter({
    required this.id,
    required this.name,
    required this.displayName,
    this.iconUrl,
    required this.type,
    this.parameters,
  });

  static const List<VideoFilter> defaultFilters = [
    VideoFilter(
      id: 'none',
      name: 'none',
      displayName: 'Original',
      type: FilterType.none,
    ),
    VideoFilter(
      id: 'vintage',
      name: 'vintage',
      displayName: 'Vintage',
      type: FilterType.color,
    ),
    VideoFilter(
      id: 'black_white',
      name: 'black_white',
      displayName: 'B&W',
      type: FilterType.color,
    ),
    VideoFilter(
      id: 'warm',
      name: 'warm',
      displayName: 'Warm',
      type: FilterType.color,
    ),
    VideoFilter(
      id: 'cool',
      name: 'cool',
      displayName: 'Cool',
      type: FilterType.color,
    ),
    VideoFilter(
      id: 'bright',
      name: 'bright',
      displayName: 'Bright',
      type: FilterType.color,
    ),
  ];
}

enum FilterType {
  none,
  color,
  blur,
  distortion,
  sticker,
  ar,
}

// ============================================================================
// Video Analytics Model
// ============================================================================

class VideoAnalytics {
  final String id;
  final String videoId;
  final int totalViews;
  final Map<String, int> viewsPerDay;
  final double engagementRate;
  final String? peakViewTime;
  final List<String> topHashtags;
  final Map<String, dynamic> demographics;
  final DateTime createdAt;
  final DateTime updatedAt;

  VideoAnalytics({
    required this.id,
    required this.videoId,
    this.totalViews = 0,
    this.viewsPerDay = const {},
    this.engagementRate = 0.0,
    this.peakViewTime,
    this.topHashtags = const [],
    this.demographics = const {},
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'video': videoId,
        'totalViews': totalViews,
        'viewsPerDay': viewsPerDay,
        'engagementRate': engagementRate,
        'peakViewTime': peakViewTime,
        'topHashtags': topHashtags,
        'demographics': demographics,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory VideoAnalytics.fromJson(Map<String, dynamic> json) => VideoAnalytics(
        id: json['id'] as String? ?? '',
        videoId: json['video'] as String,
        totalViews: json['totalViews'] as int? ?? 0,
        viewsPerDay: (json['viewsPerDay'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, v as int)) ??
            {},
        engagementRate: (json['engagementRate'] as num?)?.toDouble() ?? 0.0,
        peakViewTime: json['peakViewTime'] as String?,
        topHashtags: (json['topHashtags'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        demographics: json['demographics'] as Map<String, dynamic>? ?? {},
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : null,
      );
}

