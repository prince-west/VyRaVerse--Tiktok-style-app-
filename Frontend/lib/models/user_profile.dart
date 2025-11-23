class UserProfile {
  final String id;
  final String username;
  final String? displayName;
  final String? bio;
  final String? profileImageUrl;
  final int totalLikes;
  final int totalBuzz;
  final int vyraPoints;
  final int uploadCount;
  final int followersCount;
  final int followingCount;
  final bool isFollowing;
  final bool isFollowedBy;
  final List<String> badges;
  final bool isVerified;
  final String? themeAccent;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.username,
    this.displayName,
    this.bio,
    this.profileImageUrl,
    this.totalLikes = 0,
    this.totalBuzz = 0,
    this.vyraPoints = 0,
    this.uploadCount = 0,
    this.followersCount = 0,
    this.followingCount = 0,
    this.isFollowing = false,
    this.isFollowedBy = false,
    this.badges = const [],
    this.isVerified = false,
    this.themeAccent,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'displayName': displayName,
        'bio': bio,
        'profileImageUrl': profileImageUrl,
        'totalLikes': totalLikes,
        'totalBuzz': totalBuzz,
        'vyraPoints': vyraPoints,
        'uploadCount': uploadCount,
        'followersCount': followersCount,
        'followingCount': followingCount,
        'isFollowing': isFollowing,
        'isFollowedBy': isFollowedBy,
        'badges': badges,
        'isVerified': isVerified,
        'themeAccent': themeAccent,
        'createdAt': createdAt.toIso8601String(),
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        username: json['username'] as String,
        displayName: json['displayName'] as String?,
        bio: json['bio'] as String?,
        profileImageUrl: json['profileImageUrl'] as String?,
        totalLikes: json['totalLikes'] as int? ?? 0,
        totalBuzz: json['totalBuzz'] as int? ?? 0,
        vyraPoints: json['vyraPoints'] as int? ?? 0,
        uploadCount: json['uploadCount'] as int? ?? 0,
        followersCount: json['followersCount'] as int? ?? 0,
        followingCount: json['followingCount'] as int? ?? 0,
        isFollowing: json['isFollowing'] as bool? ?? false,
        isFollowedBy: json['isFollowedBy'] as bool? ?? false,
        badges: (json['badges'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        isVerified: json['isVerified'] as bool? ?? false,
        themeAccent: json['themeAccent'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
      );

  UserProfile copyWith({
    String? id,
    String? username,
    String? displayName,
    String? bio,
    String? profileImageUrl,
    int? totalLikes,
    int? totalBuzz,
    int? vyraPoints,
    int? uploadCount,
    int? followersCount,
    int? followingCount,
    bool? isFollowing,
    bool? isFollowedBy,
    List<String>? badges,
    bool? isVerified,
    String? themeAccent,
  }) =>
      UserProfile(
        id: id ?? this.id,
        username: username ?? this.username,
        displayName: displayName ?? this.displayName,
        bio: bio ?? this.bio,
        profileImageUrl: profileImageUrl ?? this.profileImageUrl,
        totalLikes: totalLikes ?? this.totalLikes,
        totalBuzz: totalBuzz ?? this.totalBuzz,
        vyraPoints: vyraPoints ?? this.vyraPoints,
        uploadCount: uploadCount ?? this.uploadCount,
        followersCount: followersCount ?? this.followersCount,
        followingCount: followingCount ?? this.followingCount,
        isFollowing: isFollowing ?? this.isFollowing,
        isFollowedBy: isFollowedBy ?? this.isFollowedBy,
        badges: badges ?? this.badges,
        isVerified: isVerified ?? this.isVerified,
        themeAccent: themeAccent ?? this.themeAccent,
        createdAt: createdAt,
      );
}

