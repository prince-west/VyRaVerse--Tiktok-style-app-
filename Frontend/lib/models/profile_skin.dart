class ProfileSkin {
  final String id;
  final String name;
  final String description;
  final String primaryColor; // Hex color
  final String secondaryColor; // Hex color
  final double glowIntensity;
  final String borderStyle;
  final int costPoints;
  final bool isPremium;
  final String? previewImage;
  final DateTime createdAt;

  ProfileSkin({
    required this.id,
    required this.name,
    this.description = '',
    required this.primaryColor,
    required this.secondaryColor,
    this.glowIntensity = 1.0,
    this.borderStyle = 'solid',
    this.costPoints = 0,
    this.isPremium = false,
    this.previewImage,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'primaryColor': primaryColor,
        'secondaryColor': secondaryColor,
        'glowIntensity': glowIntensity,
        'borderStyle': borderStyle,
        'costPoints': costPoints,
        'isPremium': isPremium,
        'previewImage': previewImage,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ProfileSkin.fromJson(Map<String, dynamic> json) => ProfileSkin(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        primaryColor: json['primaryColor'] as String,
        secondaryColor: json['secondaryColor'] as String,
        glowIntensity: (json['glowIntensity'] as num?)?.toDouble() ?? 1.0,
        borderStyle: json['borderStyle'] as String? ?? 'solid',
        costPoints: json['costPoints'] as int? ?? 0,
        isPremium: json['isPremium'] as bool? ?? false,
        previewImage: json['previewImage'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
      );
}

class UserSkin {
  final String id;
  final ProfileSkin skin;
  final String userId;
  final DateTime purchasedAt;
  final bool isActive;

  UserSkin({
    required this.id,
    required this.skin,
    required this.userId,
    DateTime? purchasedAt,
    this.isActive = false,
  }) : purchasedAt = purchasedAt ?? DateTime.now();

  factory UserSkin.fromJson(Map<String, dynamic> json) => UserSkin(
        id: json['id'] as String? ?? '',
        skin: ProfileSkin.fromJson(json['skin'] as Map<String, dynamic>),
        userId: json['user'] as String,
        purchasedAt: json['purchasedAt'] != null
            ? DateTime.parse(json['purchasedAt'] as String)
            : null,
        isActive: json['isActive'] as bool? ?? false,
      );
}

