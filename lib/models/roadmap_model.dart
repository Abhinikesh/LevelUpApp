class RoadmapModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String type; // study / gym / work / custom
  final String source; // manual / ai / ocr
  final int totalLevels;
  final int currentLevel;
  final bool isCompleted;
  final bool examMode;
  final DateTime? deadline;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? coverEmoji;
  final int totalXpReward;
  final int xpEarned;

  const RoadmapModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description = '',
    required this.type,
    required this.source,
    required this.totalLevels,
    required this.currentLevel,
    this.isCompleted = false,
    this.examMode = false,
    this.deadline,
    required this.createdAt,
    this.updatedAt,
    this.coverEmoji,
    this.totalXpReward = 0,
    this.xpEarned = 0,
  });

  // ── Computed Properties ──────────────────────────────────────

  double get progressPercent {
    if (totalLevels == 0) return 0.0;
    return (currentLevel / totalLevels).clamp(0.0, 1.0);
  }

  int get daysRemaining {
    if (deadline == null) return -1;
    return deadline!.difference(DateTime.now()).inDays;
  }

  bool get isOverdue {
    if (deadline == null) return false;
    return DateTime.now().isAfter(deadline!) && !isCompleted;
  }

  bool get isUrgent {
    final remaining = daysRemaining;
    return remaining >= 0 && remaining <= 3 && !isCompleted;
  }

  int get levelsRemaining => totalLevels - currentLevel;

  String get typeEmoji {
    switch (type) {
      case 'gym':
        return '💪';
      case 'study':
        return '📚';
      case 'work':
        return '💼';
      case 'custom':
        return '🎯';
      default:
        return '🗺️';
    }
  }

  String get proofTypeLabel {
    switch (type) {
      case 'gym':
        return 'Photo Proof';
      case 'study':
        return 'Quiz';
      case 'work':
        return 'Submission';
      default:
        return 'Verification';
    }
  }

  factory RoadmapModel.fromJson(Map<String, dynamic> json) {
    return RoadmapModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      type: json['type'] as String? ?? 'custom',
      source: json['source'] as String? ?? 'manual',
      totalLevels: (json['totalLevels'] as num?)?.toInt() ?? 0,
      currentLevel: (json['currentLevel'] as num?)?.toInt() ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
      examMode: json['examMode'] as bool? ?? false,
      deadline: json['deadline'] != null
          ? DateTime.tryParse(json['deadline'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
      coverEmoji: json['coverEmoji'] as String?,
      totalXpReward: (json['totalXpReward'] as num?)?.toInt() ?? 0,
      xpEarned: (json['xpEarned'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'type': type,
      'source': source,
      'totalLevels': totalLevels,
      'currentLevel': currentLevel,
      'isCompleted': isCompleted,
      'examMode': examMode,
      'deadline': deadline?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'coverEmoji': coverEmoji,
      'totalXpReward': totalXpReward,
      'xpEarned': xpEarned,
    };
  }

  RoadmapModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? type,
    String? source,
    int? totalLevels,
    int? currentLevel,
    bool? isCompleted,
    bool? examMode,
    DateTime? deadline,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? coverEmoji,
    int? totalXpReward,
    int? xpEarned,
  }) {
    return RoadmapModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      source: source ?? this.source,
      totalLevels: totalLevels ?? this.totalLevels,
      currentLevel: currentLevel ?? this.currentLevel,
      isCompleted: isCompleted ?? this.isCompleted,
      examMode: examMode ?? this.examMode,
      deadline: deadline ?? this.deadline,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      coverEmoji: coverEmoji ?? this.coverEmoji,
      totalXpReward: totalXpReward ?? this.totalXpReward,
      xpEarned: xpEarned ?? this.xpEarned,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is RoadmapModel && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'RoadmapModel($title, $currentLevel/$totalLevels)';
}
