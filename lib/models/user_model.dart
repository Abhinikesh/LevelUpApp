import 'badge_model.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String avatar;
  final int xpTotal;
  final int streakCount;
  final int longestStreak;
  final DateTime? lastActiveDate;
  final List<BadgeModel> badges;
  final DateTime createdAt;
  final String? bio;
  final String? googleId;
  final int level;
  final int totalRoadmaps;
  final int completedRoadmaps;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.avatar,
    required this.xpTotal,
    required this.streakCount,
    required this.longestStreak,
    this.lastActiveDate,
    required this.badges,
    required this.createdAt,
    this.bio,
    this.googleId,
    this.level = 1,
    this.totalRoadmaps = 0,
    this.completedRoadmaps = 0,
  });

  /// XP required to reach next level (simple formula: level * 500)
  int get xpToNextLevel => (level + 1) * 500;

  /// Fractional progress within current level
  double get levelProgress {
    final currentLevelXp = level * 500;
    final excess = xpTotal - currentLevelXp;
    return (excess / 500).clamp(0.0, 1.0);
  }

  bool get isStreakActive {
    if (lastActiveDate == null) return false;
    final diff = DateTime.now().difference(lastActiveDate!).inDays;
    return diff <= 1;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      avatar: json['avatar'] as String? ?? '',
      xpTotal: (json['xpTotal'] as num?)?.toInt() ?? 0,
      streakCount: (json['streakCount'] as num?)?.toInt() ?? 0,
      longestStreak: (json['longestStreak'] as num?)?.toInt() ?? 0,
      lastActiveDate: json['lastActiveDate'] != null
          ? DateTime.tryParse(json['lastActiveDate'] as String)
          : null,
      badges: (json['badges'] as List<dynamic>?)
              ?.map((b) => BadgeModel.fromJson(b as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      bio: json['bio'] as String?,
      googleId: json['googleId'] as String?,
      level: (json['level'] as num?)?.toInt() ?? 1,
      totalRoadmaps: (json['totalRoadmaps'] as num?)?.toInt() ?? 0,
      completedRoadmaps: (json['completedRoadmaps'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'xpTotal': xpTotal,
      'streakCount': streakCount,
      'longestStreak': longestStreak,
      'lastActiveDate': lastActiveDate?.toIso8601String(),
      'badges': badges.map((b) => b.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'bio': bio,
      'googleId': googleId,
      'level': level,
      'totalRoadmaps': totalRoadmaps,
      'completedRoadmaps': completedRoadmaps,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? avatar,
    int? xpTotal,
    int? streakCount,
    int? longestStreak,
    DateTime? lastActiveDate,
    List<BadgeModel>? badges,
    DateTime? createdAt,
    String? bio,
    String? googleId,
    int? level,
    int? totalRoadmaps,
    int? completedRoadmaps,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      xpTotal: xpTotal ?? this.xpTotal,
      streakCount: streakCount ?? this.streakCount,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      badges: badges ?? this.badges,
      createdAt: createdAt ?? this.createdAt,
      bio: bio ?? this.bio,
      googleId: googleId ?? this.googleId,
      level: level ?? this.level,
      totalRoadmaps: totalRoadmaps ?? this.totalRoadmaps,
      completedRoadmaps: completedRoadmaps ?? this.completedRoadmaps,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is UserModel && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'UserModel(id: $id, name: $name, xp: $xpTotal)';
}
