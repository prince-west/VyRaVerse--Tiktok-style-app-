class VyRaConstants {
  // Marketing Tagline
  static const String marketingTagline =
      "This is what KNUST and Legon students are using to chat — a blend of TikTok + Snapchat vibes. Join VyRaVerse, start trends, earn badges, and grow your audience!";

  // App Info
  static const String appName = "VyRaVerse";
  static const String appTagline = "Your Creative Social Universe";
  static const String appVersion = "1.0.0";

  // API Configuration
  // NOTE: These are now configured via AppConfig
  // Use AppConfig.baseUrl and AppConfig.mediaUrl instead
  @Deprecated('Use AppConfig.baseUrl instead')
  static const String baseUrl = "http://localhost:8000/api";
  @Deprecated('Use AppConfig.mediaUrl instead')
  static const String mediaUrl = "http://localhost:8000/media";

  // VyRa Points Values
  static const int pointsUpload = 10;
  static const int pointsLike = 1;
  static const int pointsComment = 2;
  static const int pointsBuzz = 3;
  static const int pointsShare = 1;
  static const int pointsBattleVote = 1;
  static const int pointsStartingBonus = 100;

  // Badge Names
  static const String badgeFirstUpload = "First Upload";
  static const String badgeFirstLike = "First Like";
  static const String badgeFirstComment = "First Comment";
  static const String badgeFirstBuzz = "First Buzz";
  static const String badgeFirstBattle = "First Battle";
  static const String badgeTopCreator = "Top Creator";
  static const String badgeTrendsetter = "Trendsetter";
  static const String badgeViral = "Viral";
  static const String badgeVerified = "Verified";

  // Privacy Options
  static const String privacyPublic = "Public";
  static const String privacyFriends = "Friends";
  static const String privacyPrivate = "Private";

  // Notification Types
  static const String notificationLike = "like";
  static const String notificationComment = "comment";
  static const String notificationFollow = "follow";
  static const String notificationBuzz = "buzz";
  static const String notificationBattle = "battle";
  static const String notificationMention = "mention";

  // Default Values
  static const String defaultProfileImage = "assets/images/default_profile.gif";
  static const String defaultThemeAccent = "Black-Cyan";
  static const int defaultPageSize = 20;
  static const int leaderboardSize = 10;

  // Time Formats
  static const String timeFormatJustNow = "Just now";
  static const String timeFormatMinutes = "m ago";
  static const String timeFormatHours = "h ago";
  static const String timeFormatDays = "d ago";
  static const String timeFormatWeeks = "w ago";
  static const String timeFormatMonths = "mo ago";
}

