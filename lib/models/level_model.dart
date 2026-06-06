enum LevelState { completed, active, locked }

/// Alias used by map_view_screen
typedef LevelStatus = LevelState;

enum ProofType { quiz, photo, code, voice, timer, screenshot, text }

class LevelModel {
  final String id;
  final String roadmapId;
  final int levelNumber;
  final String title;
  final String description;
  final String proofType; // quiz/photo/code/voice/timer/screenshot/text
  final int estimatedMinutes;
  final bool isLocked;
  final bool isCompleted;
  final int xpReward;
  final DateTime? completedAt;
  final List<String> topics;
  final String? notes;
  final Map<String, dynamic>? verificationData;

  const LevelModel({
    required this.id,
    required this.roadmapId,
    required this.levelNumber,
    required this.title,
    this.description = '',
    this.proofType = 'text',
    this.estimatedMinutes = 30,
    this.isLocked = true,
    this.isCompleted = false,
    this.xpReward = 100,
    this.completedAt,
    this.topics = const [],
    this.notes,
    this.verificationData,
  });

  // ── Computed ──────────────────────────────────────────────────

  LevelState get state {
    if (isCompleted) return LevelState.completed;
    if (!isLocked) return LevelState.active;
    return LevelState.locked;
  }

  /// Alias for state — used by UI widgets
  LevelState get status => state;

  String get proofTypeLabel {
    switch (proofType) {
      case 'quiz': return 'Quiz';
      case 'photo': return 'Photo Proof';
      case 'code': return 'Code Review';
      case 'voice': return 'Voice Explain';
      case 'timer': return 'Timed Task';
      case 'screenshot': return 'Screenshot';
      default: return 'Written';
    }
  }

  ProofType get proofTypeEnum {
    switch (proofType) {
      case 'quiz':
        return ProofType.quiz;
      case 'photo':
        return ProofType.photo;
      case 'code':
        return ProofType.code;
      case 'voice':
        return ProofType.voice;
      case 'timer':
        return ProofType.timer;
      case 'screenshot':
        return ProofType.screenshot;
      default:
        return ProofType.text;
    }
  }

  String get proofTypeIcon {
    switch (proofType) {
      case 'quiz':
        return '🧠';
      case 'photo':
        return '📸';
      case 'code':
        return '💻';
      case 'voice':
        return '🎤';
      case 'timer':
        return '⏱️';
      case 'screenshot':
        return '🖼️';
      default:
        return '✍️';
    }
  }

  String get estimatedTime {
    if (estimatedMinutes < 60) return '${estimatedMinutes}m';
    final hours = estimatedMinutes ~/ 60;
    final mins = estimatedMinutes % 60;
    return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
  }

  factory LevelModel.fromJson(Map<String, dynamic> json) {
    return LevelModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      roadmapId: json['roadmapId'] as String? ?? '',
      levelNumber: (json['levelNumber'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      proofType: json['proofType'] as String? ?? 'text',
      estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt() ?? 30,
      isLocked: json['isLocked'] as bool? ?? true,
      isCompleted: json['isCompleted'] as bool? ?? false,
      xpReward: (json['xpReward'] as num?)?.toInt() ?? 100,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
      topics: (json['topics'] as List<dynamic>?)
              ?.map((t) => t as String)
              .toList() ??
          [],
      notes: json['notes'] as String?,
      verificationData:
          json['verificationData'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'roadmapId': roadmapId,
      'levelNumber': levelNumber,
      'title': title,
      'description': description,
      'proofType': proofType,
      'estimatedMinutes': estimatedMinutes,
      'isLocked': isLocked,
      'isCompleted': isCompleted,
      'xpReward': xpReward,
      'completedAt': completedAt?.toIso8601String(),
      'topics': topics,
      'notes': notes,
      'verificationData': verificationData,
    };
  }

  LevelModel copyWith({
    String? id,
    String? roadmapId,
    int? levelNumber,
    String? title,
    String? description,
    String? proofType,
    int? estimatedMinutes,
    bool? isLocked,
    bool? isCompleted,
    int? xpReward,
    DateTime? completedAt,
    List<String>? topics,
    String? notes,
    Map<String, dynamic>? verificationData,
  }) {
    return LevelModel(
      id: id ?? this.id,
      roadmapId: roadmapId ?? this.roadmapId,
      levelNumber: levelNumber ?? this.levelNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      proofType: proofType ?? this.proofType,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      isLocked: isLocked ?? this.isLocked,
      isCompleted: isCompleted ?? this.isCompleted,
      xpReward: xpReward ?? this.xpReward,
      completedAt: completedAt ?? this.completedAt,
      topics: topics ?? this.topics,
      notes: notes ?? this.notes,
      verificationData: verificationData ?? this.verificationData,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is LevelModel && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'LevelModel(#$levelNumber $title, state: ${state.name})';
}
