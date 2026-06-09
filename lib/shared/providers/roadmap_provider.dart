import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_interceptors.dart';
import '../../core/network/dio_client.dart';
import '../../core/storage/local_database.dart';
import '../../models/roadmap_model.dart';

// ─── Mock roadmaps for demo/debug mode ───────────────────────
final _mockRoadmaps = [
  RoadmapModel(
    id: 'mock-roadmap-001',
    userId: 'mock-user-001',
    title: 'Data Structures & Algorithms',
    description: 'Master DSA from scratch — arrays, trees, graphs, DP and more.',
    type: 'study',
    source: 'ai',
    totalLevels: 30,
    currentLevel: 8,
    createdAt: DateTime.now().subtract(const Duration(days: 14)),
    coverEmoji: '🧠',
    totalXpReward: 4500,
    xpEarned: 1200,
  ),
  RoadmapModel(
    id: 'mock-roadmap-002',
    userId: 'mock-user-001',
    title: '6-Week Gym Transformation',
    description: 'Full body strength program — 5 days a week, progressive overload.',
    type: 'gym',
    source: 'manual',
    totalLevels: 42,
    currentLevel: 12,
    createdAt: DateTime.now().subtract(const Duration(days: 30)),
    coverEmoji: '💪',
    totalXpReward: 6300,
    xpEarned: 1800,
  ),
  RoadmapModel(
    id: 'mock-roadmap-003',
    userId: 'mock-user-001',
    title: 'System Design Mastery',
    description: 'Learn to design scalable distributed systems for FAANG interviews.',
    type: 'work',
    source: 'ai',
    totalLevels: 20,
    currentLevel: 3,
    createdAt: DateTime.now().subtract(const Duration(days: 5)),
    coverEmoji: '🏗️',
    totalXpReward: 3000,
    xpEarned: 450,
  ),
];

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

  Dio get dio => _dio;

  RoadmapNotifier(this._dio) : super(const RoadmapState()) {
    _restoreFromPrefsCache();
  }

  bool get _isMockMode =>
      ApiConstants.baseUrl.contains('your-backend') ||
      ApiConstants.baseUrl.isEmpty;

  static const _prefsKey = 'cached_roadmaps';

  // ── Restore from SharedPreferences on startup (instant display) ──

  Future<void> _restoreFromPrefsCache() async {
    if (_isMockMode || state.hasLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_prefsKey);
      if (cached != null) {
        final list = (jsonDecode(cached) as List<dynamic>)
            .map((j) => RoadmapModel.fromJson(j as Map<String, dynamic>))
            .toList();
        if (list.isNotEmpty && !state.hasLoaded) {
          state = state.copyWith(roadmaps: list, hasLoaded: true);
        }
      }
    } catch (_) {}
  }

  Future<void> _writeToPrefsCache(List<RoadmapModel> roadmaps) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefsKey,
        jsonEncode(roadmaps.map((r) => r.toJson()).toList()),
      );
    } catch (_) {}
  }

  // ── Fetch all roadmaps ────────────────────────────────────────

  Future<void> fetchRoadmaps({bool forceRefresh = false}) async {
    if (state.isLoading) return;

    // ── Demo / mock mode ────────────────────────────────────────
    if (_isMockMode) {
      if (!state.hasLoaded || forceRefresh) {
        state = state.copyWith(isLoading: true);
        await Future.delayed(const Duration(milliseconds: 600));
        state = state.copyWith(
          roadmaps: _mockRoadmaps,
          isLoading: false,
          hasLoaded: true,
        );
      }
      return;
    }

    // Load from local SQLite cache first for instant display
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

      // Cache to SQLite and SharedPreferences
      for (final r in roadmaps) {
        await LocalDatabase.saveRoadmap(r);
      }
      unawaited(_writeToPrefsCache(roadmaps));

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

  // ── Create roadmap (optimistic) ───────────────────────────────

  Future<RoadmapModel?> createRoadmap(Map<String, dynamic> payload) async {
    // ── Optimistic insert: build a temporary placeholder ─────────
    final tempId = 'temp-${DateTime.now().millisecondsSinceEpoch}';
    final optimisticRoadmap = RoadmapModel(
      id: tempId,
      userId: '',
      title: payload['title'] as String? ?? 'New Roadmap',
      description: payload['description'] as String? ?? '',
      type: payload['type'] as String? ?? 'custom',
      source: payload['source'] as String? ?? 'manual',
      totalLevels: (payload['levels'] as List?)?.length ?? 1,
      currentLevel: 1,
      createdAt: DateTime.now(),
      coverEmoji: null,
      totalXpReward: 0,
      xpEarned: 0,
    );

    // Insert immediately into state so the UI is instant
    final previousRoadmaps = state.roadmaps;
    state = state.copyWith(
      roadmaps: [optimisticRoadmap, ...state.roadmaps],
      isLoading: true,
      error: null,
    );

    try {
      final response = await _dio.post(ApiConstants.roadmaps, data: payload);
      final data = response.data as Map<String, dynamic>;
      final roadmapData =
          data['roadmap'] as Map<String, dynamic>? ?? data;
      final roadmap = RoadmapModel.fromJson(roadmapData);

      await LocalDatabase.saveRoadmap(roadmap);

      // Replace optimistic placeholder with real server data
      final updatedList = state.roadmaps
          .where((r) => r.id != tempId)
          .toList();
      final finalList = [roadmap, ...updatedList];

      unawaited(_writeToPrefsCache(finalList));

      state = state.copyWith(
        roadmaps: finalList,
        isLoading: false,
      );
      return roadmap;
    } on DioException catch (e) {
      // Rollback optimistic insert
      state = state.copyWith(
        roadmaps: previousRoadmaps,
        isLoading: false,
        error: ApiException.fromDioError(e).message,
      );
      return null;
    } catch (e) {
      // Rollback optimistic insert
      state = state.copyWith(
        roadmaps: previousRoadmaps,
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
      final updated = state.roadmaps.where((r) => r.id != id).toList();
      state = state.copyWith(roadmaps: updated);
      unawaited(_writeToPrefsCache(updated));
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
    unawaited(_writeToPrefsCache(list));
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

// ignore: prefer_void_to_null
Future<Null> unawaited(Future<void> future) async {
  future.catchError((_) {});
  return null;
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
