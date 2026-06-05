import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_interceptors.dart';
import '../../core/network/dio_client.dart';
import '../../core/storage/local_database.dart';
import '../../models/level_model.dart';

// ─────────────────────────────────────────────────────────────
// State  (renamed LevelsState to avoid clash with LevelState enum)
// ─────────────────────────────────────────────────────────────

class LevelsState {
  final List<LevelModel> levels;
  final bool isLoading;
  final String? error;
  final bool hasLoaded;

  const LevelsState({
    this.levels = const [],
    this.isLoading = false,
    this.error,
    this.hasLoaded = false,
  });

  LevelsState copyWith({
    List<LevelModel>? levels,
    bool? isLoading,
    String? error,
    bool? hasLoaded,
  }) {
    return LevelsState(
      levels: levels ?? this.levels,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasLoaded: hasLoaded ?? this.hasLoaded,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Notifier  (family — keyed by roadmapId)
// ─────────────────────────────────────────────────────────────

class LevelNotifier extends StateNotifier<LevelsState> {
  final Dio _dio;
  final String roadmapId;

  LevelNotifier(this._dio, this.roadmapId) : super(const LevelsState()) {
    fetchLevels();
  }

  Future<void> fetchLevels({bool forceRefresh = false}) async {
    if (state.isLoading) return;

    // Load from SQLite cache first for instant display
    if (!forceRefresh && !state.hasLoaded) {
      final cached = await LocalDatabase.getLevels(roadmapId);
      if (cached.isNotEmpty) {
        state = state.copyWith(levels: cached, hasLoaded: true);
      }
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _dio.get(ApiConstants.roadmapLevels(roadmapId));
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
      state = state.copyWith(levels: levels, isLoading: false, hasLoaded: true);
    } on DioException catch (e) {
      final ex = ApiException.fromDioError(e);
      state = state.copyWith(isLoading: false, error: ex.message);
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'Failed to load levels.');
    }
  }

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
      final updatedLevelData = data['level'] as Map<String, dynamic>?;
      final nextLevelData = data['nextLevel'] as Map<String, dynamic>?;

      final updatedLevels = state.levels.map((l) {
        if (l.id == levelId) {
          return updatedLevelData != null
              ? LevelModel.fromJson(updatedLevelData)
              : l.copyWith(isCompleted: true, completedAt: DateTime.now());
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
      final ex = ApiException.fromDioError(e);
      if (ex.statusCode == null) {
        // Offline: optimistic update + queue
        await LocalDatabase.addPendingAction('completeLevel', {
          'levelId': levelId,
          'roadmapId': roadmapId,
          'verificationPayload': verificationPayload,
        });
        final updated = state.levels.map((l) {
          return l.id == levelId
              ? l.copyWith(isCompleted: true, completedAt: DateTime.now())
              : l;
        }).toList();
        state = state.copyWith(levels: updated, isLoading: false);
        return true;
      }
      state = state.copyWith(isLoading: false, error: ex.message);
      return false;
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'Failed to complete level.');
      return false;
    }
  }

  LevelModel? getActiveLevel() {
    try {
      return state.levels.firstWhere((l) => l.state == LevelState.active);
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

// ─────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────

final levelProvider =
    StateNotifierProvider.family<LevelNotifier, LevelsState, String>(
  (ref, roadmapId) => LevelNotifier(DioClient.instance, roadmapId),
);

final activeLevelProvider = Provider.family<LevelModel?, String>((ref, roadmapId) {
  final levels = ref.watch(levelProvider(roadmapId)).levels;
  try {
    return levels.firstWhere((l) => l.state == LevelState.active);
  } catch (_) {
    return null;
  }
});

final completedLevelsCountProvider =
    Provider.family<int, String>((ref, roadmapId) {
  return ref
      .watch(levelProvider(roadmapId))
      .levels
      .where((l) => l.isCompleted)
      .length;
});
