class Sound {
  final String id;
  final String title;
  final String? artist;
  final String? audioUrl;
  final int duration; // in seconds
  final String? coverImage;
  final String? uploaderId;
  final String? uploaderName;
  final int usageCount;
  final DateTime createdAt;

  Sound({
    required this.id,
    required this.title,
    this.artist,
    this.audioUrl,
    this.duration = 0,
    this.coverImage,
    this.uploaderId,
    this.uploaderName,
    this.usageCount = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'audioUrl': audioUrl,
        'duration': duration,
        'coverImage': coverImage,
        'uploader': uploaderId,
        'uploaderName': uploaderName,
        'usageCount': usageCount,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Sound.fromJson(Map<String, dynamic> json) => Sound(
        id: json['id'] as String,
        title: json['title'] as String,
        artist: json['artist'] as String?,
        audioUrl: json['audioUrl'] as String?,
        duration: json['duration'] as int? ?? 0,
        coverImage: json['coverImage'] as String?,
        uploaderId: json['uploader'] as String?,
        uploaderName: json['uploaderName'] as String?,
        usageCount: json['usageCount'] as int? ?? 0,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
      );
}

