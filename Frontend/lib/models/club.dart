class Club {
  final String id;
  final String name;
  final String description;
  final String category;
  final String creatorId;
  final String creatorName;
  final String? coverImage;
  final int memberCount;
  final bool isPublic;
  final DateTime createdAt;

  Club({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.creatorId,
    required this.creatorName,
    this.coverImage,
    this.memberCount = 0,
    this.isPublic = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'category': category,
        'creator': creatorId,
        'creatorName': creatorName,
        'cover_image': coverImage,
        'memberCount': memberCount,
        'isPublic': isPublic,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Club.fromJson(Map<String, dynamic> json) => Club(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        category: json['category'] as String,
        creatorId: json['creator'] as String,
        creatorName: json['creatorName'] as String,
        coverImage: json['cover_image'] as String?,
        memberCount: json['memberCount'] as int? ?? 0,
        isPublic: json['isPublic'] as bool? ?? true,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
      );
}

