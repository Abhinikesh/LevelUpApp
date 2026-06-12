import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../../models/level_model.dart';
import 'auth_provider.dart';
import 'dashboard_provider.dart';
import 'roadmap_provider.dart';

// ─────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────

class LevelState {
  final List<LevelModel> levels;
  final bool isLoading;
  final String? error;
  final bool hasLoaded;

  const LevelState({
    this.levels = const [],
    this.isLoading = false,
    this.error,
    this.hasLoaded = false,
  });

  LevelState copyWith({
    List<LevelModel>? levels,
    bool? isLoading,
    String? error,
    bool? hasLoaded,
  }) =>
      LevelState(
        levels: levels ?? this.levels,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        hasLoaded: hasLoaded ?? this.hasLoaded,
      );
}

// ─────────────────────────────────────────────────────────────
// Mock level generator
// ─────────────────────────────────────────────────────────────

List<LevelModel> _mockLevels(String roadmapId) {
  const dsaTitles = [
    'Arrays & Slicing', 'Two Pointers', 'Sliding Window', 'Binary Search',
    'Linked Lists', 'Stacks & Queues', 'Trees — Basics', 'BFS & DFS',
    'Heaps & Priority Queues', 'Tries', 'Dynamic Programming I',
    'DP — Subsequences', 'DP — Knapsack', 'Graphs Intro', 'Dijkstra',
    'Bellman-Ford', 'Floyd-Warshall', 'Backtracking', 'Greedy Algorithms',
    'Bit Manipulation', 'Sorting Deep Dive', 'Hashing', 'Union-Find',
    'Segment Trees', 'Monotonic Stack', 'Matrix Problems', 'Intervals',
    'Math & Number Theory', 'String Algorithms', 'Final Challenge',
  ];
  const gymTitles = [
    'Mobility Warmup', 'Push Day I', 'Pull Day I', 'Leg Day I',
    'Core & Abs', 'Push Day II', 'Pull Day II', 'Leg Day II',
    'Cardio HIIT', 'Strength Test', 'Upper Body Superset',
    'Lower Body Superset', 'Full Body Circuit', 'Active Recovery',
    'Push Day III', 'Pull Day III', 'Leg Day III', 'Core Strength',
    'Power Training', 'Endurance Run', 'Push Day IV', 'Pull Day IV',
    'Leg Day IV', 'Mobility & Stretch', 'Upper Hypertrophy',
    'Lower Hypertrophy', 'Full Body Power', 'Deload Week',
    'Max Strength Test', 'Final Fitness Check', 'Recovery Protocol',
    'Functional Strength', 'Sprint Training', 'Olympic Lifting Intro',
    'Plyometrics', 'Yoga & Flexibility', 'HIIT Cardio II',
    'Peak Week Prep', 'Transformation Test', 'Graduation Day',
    'Celebration Workout', 'Recovery & Reflection',
  ];
  const systemTitles = [
    'Scalability Basics', 'Load Balancing', 'Caching Strategies',
    'SQL vs NoSQL', 'CAP Theorem', 'Consistent Hashing',
    'Message Queues', 'API Design', 'Rate Limiting',
    'Authentication Systems', 'Microservices', 'Event Sourcing',
    'Service Mesh', 'CDN & Edge', 'Database Sharding',
    'Distributed Locks', 'Search Systems', 'Stream Processing',
    'Observability', 'Final Design Review',
  ];

  final titles = roadmapId.contains('001')
      ? dsaTitles
      : roadmapId.contains('002')
          ? gymTitles
          : systemTitles;

  const proofTypes = ['quiz', 'voice', 'quiz', 'photo', 'quiz'];
  final completedCount = roadmapId.contains('001')
      ? 7
      : roadmapId.contains('002')
          ? 11
          : 2;

  return List.generate(titles.length, (i) {
    final num = i + 1;
    final isCompleted = i < completedCount;
    final isActive = i == completedCount;
    return LevelModel(
      id: '$roadmapId-level-$num',
      roadmapId: roadmapId,
      levelNumber: num,
      title: i < titles.length ? titles[i] : 'Level $num',
      description:
          'Master the concepts in this level to unlock the next challenge. '
          'Apply your knowledge through hands-on practice.',
      proofType: proofTypes[i % proofTypes.length],
      estimatedMinutes: 20 + (i % 4) * 10,
      isLocked: !isCompleted && !isActive,
      isCompleted: isCompleted,
      xpReward: 100 + (i % 3) * 50,
      completedAt: isCompleted
          ? DateTime.now().subtract(Duration(days: completedCount - i))
          : null,
      topics: ['Concept ${i + 1}A', 'Concept ${i + 1}B', 'Practice ${i + 1}'],
    );
  });
}

/// Mock levels with sub-levels for demonstration (roadmap id contains 'sub')
List<LevelModel> _mockSubLevels(String roadmapId) {
  final topics = [
    ('Arrays', ['Two Pointer', 'Sliding Window', 'Prefix Sum', 'Kadane\'s Algorithm']),
    ('Linked Lists', ['Reversal', 'Cycle Detection', 'Merge Sorted', 'Remove N-th Node']),
    ('Trees', ['Inorder Traversal', 'Level BFS', 'Lowest Common Ancestor', 'Path Sum']),
    ('Graphs', ['DFS Traversal', 'BFS Traversal', 'Topological Sort', 'Union Find']),
    ('Dynamic Programming', ['Fibonacci', 'Knapsack 0/1', 'LCS', 'Coin Change']),
    ('Sorting & Searching', ['Merge Sort', 'Quick Sort', 'Binary Search', 'Counting Sort']),
  ];

  return List.generate(topics.length, (i) {
    final (topic, subs) = topics[i];
    final isCompleted = i < 2;
    final isActive = i == 2;
    final levelId = '$roadmapId-level-${i + 1}';
    final subLevelList = subs.asMap().entries.map((e) {
      final subIsCompleted = isCompleted || (isActive && e.key < 2);
      return SubLevel(
        id: '$levelId-sub-${e.key}',
        parentLevelId: levelId,
        title: e.value,
        description: 'Learn and practice ${e.value} technique.',
        proofType: 'quiz',
        isCompleted: subIsCompleted,
        orderIndex: e.key,
      );
    }).toList();
    return LevelModel(
      id: levelId,
      roadmapId: roadmapId,
      levelNumber: i + 1,
      title: topic,
      description: 'Master $topic and all its sub-techniques.',
      proofType: 'quiz',
      estimatedMinutes: 60,
      isLocked: !isCompleted && !isActive,
      isCompleted: isCompleted,
      xpReward: 200,
      completedAt: isCompleted
          ? DateTime.now().subtract(Duration(days: topics.length - i))
          : null,
      topics: subs,
      subLevels: subLevelList,
    );
  });
}

// ─────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────

class LevelNotifier extends StateNotifier<LevelState> {
  final String roadmapId;
  final Ref ref;

  LevelNotifier(this.roadmapId, this.ref) : super(const LevelState());

  bool get _isMockMode =>
      ApiConstants.baseUrl.contains('your-backend') ||
      ApiConstants.baseUrl.isEmpty;

  Future<void> fetchLevels({bool forceRefresh = false}) async {
    if (state.isLoading) return;
    if (state.hasLoaded && !forceRefresh) return;

    state = state.copyWith(isLoading: true);

    if (_isMockMode) {
      await Future.delayed(const Duration(milliseconds: 500));
      // Detect if this roadmap is a sublevel demo roadmap
      final roadmaps = ref.read(roadmapProvider).roadmaps;
      final roadmap = roadmaps.where((r) => r.id == roadmapId).firstOrNull;
      final levels = (roadmap?.hasSubLevels ?? false)
          ? _mockSubLevels(roadmapId)
          : _mockLevels(roadmapId);
      state = state.copyWith(
        levels: levels,
        isLoading: false,
        hasLoaded: true,
      );
      return;
    }

    try {
      final dio = DioClient.instance;
      final response =
          await dio.get(ApiConstants.roadmapLevels(roadmapId));
      final data = response.data as Map<String, dynamic>;
      final list = (data['levels'] as List<dynamic>? ?? [])
          .map((e) => LevelModel.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(levels: list, isLoading: false, hasLoaded: true);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: 'Failed to load levels. Try again.');
    }
  }

  /// Mark a level as complete locally (optimistic update)
  void markComplete(String levelId) {
    final updated = state.levels.map((l) {
      if (l.id == levelId) {
        return l.copyWith(isCompleted: true, isLocked: false,
            completedAt: DateTime.now());
      }
      // Unlock next level
      if (l.levelNumber == _levelNumberFor(levelId) + 1) {
        return l.copyWith(isLocked: false);
      }
      return l;
    }).toList();
    state = state.copyWith(levels: updated);
  }

  /// Mark a specific sub-level as complete. If ALL sub-levels complete,
  /// mark the parent as complete and unlock the next level.
  void markSubLevelComplete(String parentLevelId, String subLevelId) {
    final updated = state.levels.map((level) {
      if (level.id != parentLevelId) return level;

      final newSubLevels = level.subLevels.map((sub) {
        if (sub.id == subLevelId) {
          return sub.copyWith(isCompleted: true, completedAt: DateTime.now());
        }
        return sub;
      }).toList();

      final allSubsDone = newSubLevels.every((s) => s.isCompleted);
      return level.copyWith(
        subLevels: newSubLevels,
        isCompleted: allSubsDone,
        completedAt: allSubsDone ? DateTime.now() : level.completedAt,
      );
    }).toList();

    // If parent is now complete, unlock next level
    final parentLevel =
        updated.where((l) => l.id == parentLevelId).firstOrNull;
    final finalList = parentLevel?.isCompleted == true
        ? updated.map((l) {
            if (l.levelNumber == (parentLevel!.levelNumber + 1)) {
              return l.copyWith(isLocked: false);
            }
            return l;
          }).toList()
        : updated;

    state = state.copyWith(levels: finalList);
  }

  Future<bool> verifyAndCompleteLevel({
    required String levelId,
    required String proofType,
    String proofUrl = '',
    Map<String, dynamic>? proofData,
    int timeSpentMinutes = 0,
  }) async {
    // ── Handle sub-level composite IDs: "parentId__sub__subId" ──
    if (levelId.contains('__sub__')) {
      final parts = levelId.split('__sub__');
      final parentId = parts[0];
      final subId = parts[1];
      markSubLevelComplete(parentId, subId);

      if (_isMockMode) {
        final parent = state.levels.where((l) => l.id == parentId).firstOrNull;
        if (parent != null) {
          final xpGain = parent.xpReward ~/ parent.subLevels.length;
          final user = ref.read(currentUserProvider);
          if (user != null) {
            final updatedXp = user.xpTotal + xpGain;
            ref.read(authProvider.notifier).updateLocalUser(user.copyWith(
              xpTotal: updatedXp,
              level: updatedXp ~/ 500 + 1,
            ));
            ref.read(todayXpProvider.notifier).addXp(xpGain);
          }
        }
        return true;
      }
      // TODO: real API call for sub-level completion
      return true;
    }

    // ── Standard level completion ─────────────────────────────
    markComplete(levelId);

    if (_isMockMode) {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        final targetLvl = state.levels.firstWhere(
          (l) => l.id == levelId,
          orElse: () => state.levels.first,
        );
        final updatedXp = user.xpTotal + targetLvl.xpReward;
        ref.read(authProvider.notifier).updateLocalUser(user.copyWith(
          xpTotal: updatedXp,
          level: updatedXp ~/ 500 + 1,
        ));
        ref.read(todayXpProvider.notifier).addXp(targetLvl.xpReward);
      }
      return true;
    }

    try {
      final dio = DioClient.instance;
      final response = await dio.post(
        ApiConstants.completeLevel(levelId),
        data: {
          'proofType': proofType,
          'proofUrl': proofUrl,
          'proofData': proofData,
          'timeSpentMinutes': timeSpentMinutes,
        },
      );
      if (response.statusCode == 200) {
        final completedLvl = state.levels.firstWhere(
          (l) => l.id == levelId,
          orElse: () => state.levels.first,
        );
        ref.read(todayXpProvider.notifier).addXp(completedLvl.xpReward);
        await ref.read(authProvider.notifier).getMe();
        await ref.read(roadmapProvider.notifier).fetchRoadmaps(forceRefresh: true);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[LevelNotifier] verifyAndCompleteLevel failed: $e');
      return false;
    }
  }

  int _levelNumberFor(String levelId) {
    try {
      return state.levels.firstWhere((l) => l.id == levelId).levelNumber;
    } catch (_) {
      return 0;
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────

final levelProvider = StateNotifierProvider.family<LevelNotifier, LevelState, String>(
  (ref, roadmapId) => LevelNotifier(roadmapId, ref),
);

/// Get a single level by ID across all loaded roadmaps.
/// Also resolves composite sub-level IDs: "parentId__sub__subId"
final levelByIdProvider = Provider.family<LevelModel?, String>((ref, levelId) {
  // ── Sub-level composite ID resolution ──────────────────────
  if (levelId.contains('__sub__')) {
    final parts = levelId.split('__sub__');
    final parentId = parts[0];
    final subId = parts[1];

    // Find the parent level across all roadmaps
    final roadmaps = ref.watch(roadmapProvider).roadmaps;
    for (final r in roadmaps) {
      final s = ref.watch(levelProvider(r.id));
      try {
        final parent = s.levels.firstWhere((l) => l.id == parentId);
        final sub = parent.subLevels.firstWhere((sl) => sl.id == subId);
        // Construct a transient LevelModel representing this sub-level
        return LevelModel(
          id: sub.compositeId,
          roadmapId: parent.roadmapId,
          levelNumber: parent.levelNumber,
          title: sub.title,
          description: sub.description,
          proofType: sub.proofType,
          estimatedMinutes: parent.estimatedMinutes ~/ parent.subLevels.length,
          isLocked: !sub.isCompleted && parent.isLocked,
          isCompleted: sub.isCompleted,
          xpReward: parent.xpReward ~/ parent.subLevels.length,
          completedAt: sub.completedAt,
        );
      } catch (_) {
        // not here
      }
    }
    return null;
  }

  // ── Standard level ID lookup ────────────────────────────────
  final roadmaps = ref.watch(roadmapProvider).roadmaps;
  for (final r in roadmaps) {
    final s = ref.watch(levelProvider(r.id));
    try {
      return s.levels.firstWhere((l) => l.id == levelId);
    } catch (_) {
      // not in this roadmap
    }
  }

  // Fallback to mock roadmaps
  const roadmapIds = [
    'mock-roadmap-001',
    'mock-roadmap-002',
    'mock-roadmap-003',
    'mock-roadmap-sub-001',
  ];
  for (final rId in roadmapIds) {
    final s = ref.watch(levelProvider(rId));
    try {
      return s.levels.firstWhere((l) => l.id == levelId);
    } catch (_) {
      // not in this roadmap
    }
  }

  // fallback: parse from levelId pattern
  if (levelId.contains('-level-')) {
    final parts = levelId.split('-level-');
    final rId = parts[0];
    final num = int.tryParse(parts[1]) ?? 1;
    return _mockLevels(rId).firstWhere(
      (l) => l.levelNumber == num,
      orElse: () => _mockLevels(rId).first,
    );
  }
  return null;
});

/// Active level for a roadmap
final activeLevelProvider = Provider.family<LevelModel?, String>((ref, roadmapId) {
  final levels = ref.watch(levelProvider(roadmapId)).levels;
  try {
    return levels.firstWhere((l) => l.status == LevelStatus.active);
  } catch (_) {
    return null;
  }
});
