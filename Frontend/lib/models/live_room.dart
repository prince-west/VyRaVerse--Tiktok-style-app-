class LiveRoom {
  final String id;
  final String hostId;
  final String hostName;
  final String title;
  final String description;
  final String status; // scheduled, live, ended
  final int viewerCount;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime createdAt;

  LiveRoom({
    required this.id,
    required this.hostId,
    required this.hostName,
    required this.title,
    this.description = '',
    this.status = 'scheduled',
    this.viewerCount = 0,
    this.startedAt,
    this.endedAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'host': hostId,
        'hostName': hostName,
        'title': title,
        'description': description,
        'status': status,
        'viewerCount': viewerCount,
        'startedAt': startedAt?.toIso8601String(),
        'endedAt': endedAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory LiveRoom.fromJson(Map<String, dynamic> json) => LiveRoom(
        id: json['id'] as String,
        hostId: json['host'] as String,
        hostName: json['hostName'] as String,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        status: json['status'] as String? ?? 'scheduled',
        viewerCount: json['viewerCount'] as int? ?? 0,
        startedAt: json['startedAt'] != null
            ? DateTime.parse(json['startedAt'] as String)
            : null,
        endedAt: json['endedAt'] != null
            ? DateTime.parse(json['endedAt'] as String)
            : null,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
      );
}

class LiveBattle {
  final String id;
  final String liveRoomId;
  final String participant1Id;
  final String participant1Name;
  final String participant2Id;
  final String participant2Name;
  final int participant1Votes;
  final int participant2Votes;
  final String? winnerId;
  final DateTime startedAt;
  final DateTime? endedAt;

  LiveBattle({
    required this.id,
    required this.liveRoomId,
    required this.participant1Id,
    required this.participant1Name,
    required this.participant2Id,
    required this.participant2Name,
    this.participant1Votes = 0,
    this.participant2Votes = 0,
    this.winnerId,
    DateTime? startedAt,
    this.endedAt,
  }) : startedAt = startedAt ?? DateTime.now();

  factory LiveBattle.fromJson(Map<String, dynamic> json) => LiveBattle(
        id: json['id'] as String,
        liveRoomId: json['live_room'] as String,
        participant1Id: json['participant1'] as String,
        participant1Name: json['participant1Name'] as String,
        participant2Id: json['participant2'] as String,
        participant2Name: json['participant2Name'] as String,
        participant1Votes: json['participant1Votes'] as int? ?? 0,
        participant2Votes: json['participant2Votes'] as int? ?? 0,
        winnerId: json['winner'] as String?,
        startedAt: json['startedAt'] != null
            ? DateTime.parse(json['startedAt'] as String)
            : null,
        endedAt: json['endedAt'] != null
            ? DateTime.parse(json['endedAt'] as String)
            : null,
      );
}

