import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_interceptors.dart';
import '../../core/network/dio_client.dart';
import '../../core/storage/local_database.dart';
import '../../models/level_model.dart';

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
  }) {
    return LevelState(
      levels: levels ?? this.levels,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasLoaded: hasLoaded ?? this.hasLoaded,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Notifier  (family — takes roadmapId)
// ─────────────────────────────────────────────────────────────

class LevelNotifier extends StateNotifier<LevelState> {
  final Dio _dio;
  final String roadmapId;

  LevelNotifier(this._dio, this.roadmapId) : super(const LevelState()) {
    fetchLevels();
  }

  // ── Fetch levels ──────────────────────────────────────────────

  Future<void> fetchLevels({bool forceRefresh = false}) async {
    if (state.isLoading) return;

    // Local cache first
    if (!forceRefresh && !state.hasLoaded) {
      final cached = await LocalDatabase.getLevels(roadmapId);
      if (cached.isNotEmpty) {
        state = state.copyWith(levels: cached, hasLoaded: true);
      }
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _dio.get(
        ApiConstants.roadmapLevels(roadmapId),
      );
      final data = response.data;

      List<dynamic> list;
      if (data is List) {
        list = data;
      } else if (data is Map<String, dynamic>) {
        list = data['levels'] as List<dynamic>? ??
            data['data'] as List<dynamic>? ??
            [];
      } else {
        list = [];
      }

      final levels = list
          .map((j) => LevelModel.fromJson(j as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.levelNumber.compareTo(b.levelNumber));

      await LocalDatabase.saveLevels(levels);

      state = state.copyWith(
        levels: levels,
        isLoading: false,
        hasLoaded: true,
      );
    } on DioException catch (e) {
      final ex = ApiException.fromDioError(e);
      state = state.copyWith(isLoading: false, error: ex.message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load levels.',
      );
    }
  }

  // ── Complete level ────────────────────────────────────────────

  Future<bool> completeLevel(
    String levelId, {
    Map<String, dynamic>? verificationPayload,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _dio.post(
        ApiConstants.completeLevel(levelId),
        data: verificationPayload,
      );
      final data = response.data as Map<String, dynamic>;

      // Server returns updated level + next level
      final updatedLevelData =
          data['level'] as Map<String, dynamic>?;
      final nextLevelData =
          data['nextLevel'] as Map<String, dynamic>?;

      final updatedLevels = state.levels.map((l) {
        if (l.id == levelId) {
          return updatedLevelData != null
              ? LevelModel.fromJson(updatedLevelData)
              : l.copyWith(
                  isCompleted: true,
                  completedAt: DateTime.now(),
                );
        }
        if (nextLevelData != null) {
          final next = LevelModel.fromJson(nextLevelData);
          if (l.id == next.id) return next;
        }
        return l;
      }).toList();

      await LocalDatabase.saveLevels(updatedLevels);
      state = state.copyWith(levels: updatedLevels, isLoading: false);
      return true;
    } on DioException catch (e) {
      // Offline: queue action
      final ex = ApiException.fromDioError(e);
      if (ex.statusCode == null) {
        await LocalDatabase.addPendingAction('completeLevel', {
          'levelId': levelId,
          'roadmapId': roadmapId,
          'verificationPayload': verificationPayload,
        });
        // Optimistic update
        final updatedLevels = state.levels.map((l) {
          return l.id == levelId
              ? l.copyWith(isCompleted: true, completedAt: DateTime.now())
              : l;
        }).toList();
        state = state.copyWith(levels: updatedLevels, isLoading: false);
        return true;
      }
      state = state.copyWith(isLoading: false, error: ex.message);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to complete level.',
      );
      return false;
    }
  }

  // ── Helpers ──────────────────────────────────────────────────

  LevelModel? getActiveLevel() {
    try {
      return state.levels
          .firstWhere((l) => l.state == LevelStateEnum.active);
    } catch (_) {
      return null;
    }
  }

  LevelModel? getLevelById(String id) {
    try {
      return state.levels.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

// Alias to avoid conflict with model enum name
typedef LevelStateEnum = LevelState_; // workaround — using extension below

extension LevelModelStateExt on LevelModel {
  LevelState_ get state {
    if (isCompleted) return LevelState_.completed;
    if (!isLocked) return LevelState_.active;
    return LevelState_.locked;
  }
}

enum LevelState_ { completed, active, locked }

// ─────────────────────────────────────────────────────────────
// Provider  (family)
// ─────────────────────────────────────────────────────────────

final levelProvider = StateNotifierProvider.family<LevelNotifier, LevelState,
    String>((ref, roadmapId) {
  return LevelNotifier(DioClient.instance, roadmapId);
});

/// Convenience: active level for a roadmap
final activeLevelProvider =
    Provider.family<LevelModel?, String>((ref, roadmapId) {
  final levels = ref.watch(levelProvider(roadmapId)).levels;
  try {
    return levels.firstWhere((l) => !l.isCompleted && !l.isLocked);
  } catch (_) {
    return null;
  }
});

/// Convenience: completed count
final completedLevelsCountProvider =
    Provider.family<int, String>((ref, roadmapId) {
  return ref
      .watch(levelProvider(roadmapId))
      .levels
      .where((l) => l.isCompleted)
      .length;
});
