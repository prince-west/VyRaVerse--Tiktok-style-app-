class StatusItem {
  final String id;
  final String userId;
  final String? imageUrl;
  final String? videoUrl;
  final String caption;
  final DateTime expiresAt;
  final int viewsCount;
  final List<Map<String, dynamic>> stickers;
  final String? pollQuestion;
  final List<Map<String, dynamic>> pollOptions;
  final String? musicUrl;
  final DateTime? countdownTimer;
  final bool askMeAnything;
  final DateTime createdAt;

  StatusItem({
    required this.id,
    required this.userId,
    this.imageUrl,
    this.videoUrl,
    this.caption = '',
    required this.expiresAt,
    this.viewsCount = 0,
    this.stickers = const [],
    this.pollQuestion,
    this.pollOptions = const [],
    this.musicUrl,
    this.countdownTimer,
    this.askMeAnything = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'user': userId,
        'image': imageUrl,
        'video': videoUrl,
        'caption': caption,
        'expiresAt': expiresAt.toIso8601String(),
        'viewsCount': viewsCount,
        'stickers': stickers,
        'pollQuestion': pollQuestion,
        'pollOptions': pollOptions,
        'musicUrl': musicUrl,
        'countdownTimer': countdownTimer?.toIso8601String(),
        'askMeAnything': askMeAnything,
        'createdAt': createdAt.toIso8601String(),
      };

  factory StatusItem.fromJson(Map<String, dynamic> json) => StatusItem(
        id: json['id'] as String,
        userId: json['user'] as String,
        imageUrl: json['image'] as String?,
        videoUrl: json['video'] as String?,
        caption: json['caption'] as String? ?? '',
        expiresAt: DateTime.parse(json['expiresAt'] as String),
        viewsCount: json['viewsCount'] as int? ?? 0,
        stickers: (json['stickers'] as List<dynamic>?)
                ?.map((e) => e as Map<String, dynamic>)
                .toList() ??
            [],
        pollQuestion: json['pollQuestion'] as String?,
        pollOptions: (json['pollOptions'] as List<dynamic>?)
                ?.map((e) => e as Map<String, dynamic>)
                .toList() ??
            [],
        musicUrl: json['musicUrl'] as String?,
        countdownTimer: json['countdownTimer'] != null
            ? DateTime.parse(json['countdownTimer'] as String)
            : null,
        askMeAnything: json['askMeAnything'] as bool? ?? false,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
      );
}

