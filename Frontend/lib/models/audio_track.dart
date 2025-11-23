/// Audio track model for background music
class AudioTrack {
  final String id;
  final String title;
  final String? artist;
  final String? coverImage;
  final Duration duration;
  final String audioUrl;
  final int usageCount;
  final String? category;

  const AudioTrack({
    required this.id,
    required this.title,
    this.artist,
    this.coverImage,
    required this.duration,
    required this.audioUrl,
    this.usageCount = 0,
    this.category,
  });

  String get durationFormatted {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'coverImage': coverImage,
        'duration': duration.inSeconds,
        'audioUrl': audioUrl,
        'usageCount': usageCount,
        'category': category,
      };

  factory AudioTrack.fromJson(Map<String, dynamic> json) => AudioTrack(
        id: json['id'] as String,
        title: json['title'] as String,
        artist: json['artist'] as String?,
        coverImage: json['coverImage'] as String?,
        duration: Duration(seconds: json['duration'] as int),
        audioUrl: json['audioUrl'] as String,
        usageCount: json['usageCount'] as int? ?? 0,
        category: json['category'] as String?,
      );
}

