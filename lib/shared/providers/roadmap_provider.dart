import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_interceptors.dart';
import '../../core/network/dio_client.dart';
import '../../core/storage/local_database.dart';
import '../../models/roadmap_model.dart';

// ─────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────

class RoadmapState {
  final List<RoadmapModel> roadmaps;
  final bool isLoading;
  final String? error;
  final bool hasLoaded;

  const RoadmapState({
    this.roadmaps = const [],
    this.isLoading = false,
    this.error,
    this.hasLoaded = false,
  });

  RoadmapState copyWith({
    List<RoadmapModel>? roadmaps,
    bool? isLoading,
    String? error,
    bool? hasLoaded,
  }) {
    return RoadmapState(
      roadmaps: roadmaps ?? this.roadmaps,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasLoaded: hasLoaded ?? this.hasLoaded,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────

class RoadmapNotifier extends StateNotifier<RoadmapState> {
  final Dio _dio;

  RoadmapNotifier(this._dio) : super(const RoadmapState());

  // ── Fetch all roadmaps ────────────────────────────────────────

  Future<void> fetchRoadmaps({bool forceRefresh = false}) async {
    if (state.isLoading) return;

    // Load from local cache first for instant display
    if (!forceRefresh && !state.hasLoaded) {
      final cached = await LocalDatabase.getAllRoadmaps();
      if (cached.isNotEmpty) {
        state = state.copyWith(roadmaps: cached, hasLoaded: true);
      }
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _dio.get(ApiConstants.roadmaps);
      final data = response.data;

      List<dynamic> list;
      if (data is List) {
        list = data;
      } else if (data is Map<String, dynamic>) {
        list = data['roadmaps'] as List<dynamic>? ??
            data['data'] as List<dynamic>? ??
            [];
      } else {
        list = [];
      }

      final roadmaps = list
          .map((j) => RoadmapModel.fromJson(j as Map<String, dynamic>))
          .toList();

      // Cache each roadmap locally
      for (final r in roadmaps) {
        await LocalDatabase.saveRoadmap(r);
      }

      state = state.copyWith(
        roadmaps: roadmaps,
        isLoading: false,
        hasLoaded: true,
      );
    } on DioException catch (e) {
      final ex = ApiException.fromDioError(e);
      state = state.copyWith(isLoading: false, error: ex.message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load roadmaps.',
      );
    }
  }

  // ── Create roadmap ────────────────────────────────────────────

  Future<RoadmapModel?> createRoadmap(Map<String, dynamic> payload) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _dio.post(ApiConstants.roadmaps, data: payload);
      final data = response.data as Map<String, dynamic>;
      final roadmapData =
          data['roadmap'] as Map<String, dynamic>? ?? data;
      final roadmap = RoadmapModel.fromJson(roadmapData);

      await LocalDatabase.saveRoadmap(roadmap);

      state = state.copyWith(
        roadmaps: [roadmap, ...state.roadmaps],
        isLoading: false,
      );
      return roadmap;
    } on DioException catch (e) {
      final ex = ApiException.fromDioError(e);
      state = state.copyWith(isLoading: false, error: ex.message);
      return null;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create roadmap.',
      );
      return null;
    }
  }

  // ── Delete roadmap ────────────────────────────────────────────

  Future<bool> deleteRoadmap(String id) async {
    try {
      await _dio.delete(ApiConstants.roadmapById(id));
      await LocalDatabase.deleteRoadmap(id);
      state = state.copyWith(
        roadmaps: state.roadmaps.where((r) => r.id != id).toList(),
      );
      return true;
    } on DioException catch (e) {
      final ex = ApiException.fromDioError(e);
      state = state.copyWith(error: ex.message);
      return false;
    } catch (_) {
      return false;
    }
  }

  // ── Update roadmap locally (after level completion, etc.) ─────

  void updateRoadmapLocally(RoadmapModel updated) {
    final list = state.roadmaps.map((r) {
      return r.id == updated.id ? updated : r;
    }).toList();
    state = state.copyWith(roadmaps: list);
    LocalDatabase.saveRoadmap(updated);
  }

  RoadmapModel? getRoadmapById(String id) {
    try {
      return state.roadmaps.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

// ─────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────

final roadmapProvider =
    StateNotifierProvider<RoadmapNotifier, RoadmapState>((ref) {
  return RoadmapNotifier(DioClient.instance);
});

/// Convenience: sorted active roadmaps first
final activeRoadmapsProvider = Provider<List<RoadmapModel>>((ref) {
  final roadmaps = ref.watch(roadmapProvider).roadmaps;
  final active = roadmaps.where((r) => !r.isCompleted).toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return active;
});

final completedRoadmapsProvider = Provider<List<RoadmapModel>>((ref) {
  return ref
      .watch(roadmapProvider)
      .roadmaps
      .where((r) => r.isCompleted)
      .toList();
});
