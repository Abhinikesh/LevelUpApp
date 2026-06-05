class FriendModel {
  final String id;
  final String name;
  final String avatar;
  final int streakCount;
  final String? currentRoadmapTitle;
  final int? currentLevel;
  final String status; // pending / accepted / sent
  final int xpTotal;
  final int level;
  final DateTime? lastActiveDate;
  final DateTime? friendSince;

  const FriendModel({
    required this.id,
    required this.name,
    required this.avatar,
    required this.streakCount,
    this.currentRoadmapTitle,
    this.currentLevel,
    required this.status,
    this.xpTotal = 0,
    this.level = 1,
    this.lastActiveDate,
    this.friendSince,
  });

  bool get isAccepted => status == 'accepted';
  bool get isPending => status == 'pending';
  bool get isSent => status == 'sent';

  bool get isRecentlyActive {
    if (lastActiveDate == null) return false;
    return DateTime.now().difference(lastActiveDate!).inHours < 24;
  }

  factory FriendModel.fromJson(Map<String, dynamic> json) {
    // The API may nest user data inside a 'user' or 'friend' key
    final userData =
        json['user'] as Map<String, dynamic>? ??
        json['friend'] as Map<String, dynamic>? ??
        json;

    return FriendModel(
      id: userData['_id'] as String? ?? userData['id'] as String? ?? '',
      name: userData['name'] as String? ?? '',
      avatar: userData['avatar'] as String? ?? '',
      streakCount: (userData['streakCount'] as num?)?.toInt() ?? 0,
      currentRoadmapTitle: json['currentRoadmapTitle'] as String?,
      currentLevel: (json['currentLevel'] as num?)?.toInt(),
      status: json['status'] as String? ?? 'pending',
      xpTotal: (userData['xpTotal'] as num?)?.toInt() ?? 0,
      level: (userData['level'] as num?)?.toInt() ?? 1,
      lastActiveDate: userData['lastActiveDate'] != null
          ? DateTime.tryParse(userData['lastActiveDate'] as String)
          : null,
      friendSince: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'streakCount': streakCount,
      'currentRoadmapTitle': currentRoadmapTitle,
      'currentLevel': currentLevel,
      'status': status,
      'xpTotal': xpTotal,
      'level': level,
      'lastActiveDate': lastActiveDate?.toIso8601String(),
      'friendSince': friendSince?.toIso8601String(),
    };
  }

  FriendModel copyWith({
    String? id,
    String? name,
    String? avatar,
    int? streakCount,
    String? currentRoadmapTitle,
    int? currentLevel,
    String? status,
    int? xpTotal,
    int? level,
    DateTime? lastActiveDate,
    DateTime? friendSince,
  }) {
    return FriendModel(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      streakCount: streakCount ?? this.streakCount,
      currentRoadmapTitle: currentRoadmapTitle ?? this.currentRoadmapTitle,
      currentLevel: currentLevel ?? this.currentLevel,
      status: status ?? this.status,
      xpTotal: xpTotal ?? this.xpTotal,
      level: level ?? this.level,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      friendSince: friendSince ?? this.friendSince,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is FriendModel && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'FriendModel($name, status: $status)';
}
