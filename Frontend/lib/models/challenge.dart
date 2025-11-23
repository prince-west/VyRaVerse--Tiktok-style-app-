class Challenge {
  final String id;
  final String title;
  final String description;
  final String challengeType;
  final int pointsReward;
  final String frequency; // daily, weekly, monthly
  final bool isActive;
  final DateTime? expiresAt;
  final DateTime createdAt;

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.challengeType,
    required this.pointsReward,
    this.frequency = 'daily',
    this.isActive = true,
    this.expiresAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'challengeType': challengeType,
        'pointsReward': pointsReward,
        'frequency': frequency,
        'isActive': isActive,
        'expiresAt': expiresAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  factory Challenge.fromJson(Map<String, dynamic> json) => Challenge(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        challengeType: json['challengeType'] as String,
        pointsReward: json['pointsReward'] as int,
        frequency: json['frequency'] as String? ?? 'daily',
        isActive: json['isActive'] as bool? ?? true,
        expiresAt: json['expiresAt'] != null
            ? DateTime.parse(json['expiresAt'] as String)
            : null,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
      );
}

class UserChallengeProgress {
  final String id;
  final Challenge challenge;
  final String userId;
  final int progress;
  final int target;
  final bool completed;
  final bool claimed;
  final DateTime startedAt;
  final DateTime? completedAt;

  UserChallengeProgress({
    required this.id,
    required this.challenge,
    required this.userId,
    this.progress = 0,
    this.target = 1,
    this.completed = false,
    this.claimed = false,
    DateTime? startedAt,
    this.completedAt,
  }) : startedAt = startedAt ?? DateTime.now();

  factory UserChallengeProgress.fromJson(Map<String, dynamic> json) =>
      UserChallengeProgress(
        id: json['id'] as String? ?? '',
        challenge: Challenge.fromJson(json['challenge'] as Map<String, dynamic>),
        userId: json['user'] as String,
        progress: json['progress'] as int? ?? 0,
        target: json['target'] as int? ?? 1,
        completed: json['completed'] as bool? ?? false,
        claimed: json['claimed'] as bool? ?? false,
        startedAt: json['startedAt'] != null
            ? DateTime.parse(json['startedAt'] as String)
            : null,
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null,
      );
}

