import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/level_model.dart';
import '../../models/roadmap_model.dart';
import 'auth_provider.dart';
import 'level_provider.dart';
import 'roadmap_provider.dart';

// ─────────────────────────────────────────────────────────────
// TodayXp — persists daily XP across sessions, resets on new day
// ─────────────────────────────────────────────────────────────

class TodayXpNotifier extends StateNotifier<int> {
  TodayXpNotifier() : super(0) {
    _load();
  }

  static String get _todayKey {
    final date = DateTime.now().toIso8601String().split('T')[0];
    return 'xp_earned_$date';
  }

  static String get _dateStoredKey => 'xp_date_stored';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final storedDate = prefs.getString(_dateStoredKey) ?? '';
    final todayDate = DateTime.now().toIso8601String().split('T')[0];

    if (storedDate != todayDate) {
      // New day — reset
      await prefs.setInt(_todayKey, 0);
      await prefs.setString(_dateStoredKey, todayDate);
      state = 0;
    } else {
      state = prefs.getInt(_todayKey) ?? 0;
    }
  }

  Future<void> addXp(int amount) async {
    if (amount <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    final todayDate = DateTime.now().toIso8601String().split('T')[0];
    // Ensure date reset if day changed
    final storedDate = prefs.getString(_dateStoredKey) ?? '';
    if (storedDate != todayDate) {
      await prefs.setString(_dateStoredKey, todayDate);
      state = amount;
    } else {
      state = state + amount;
    }
    await prefs.setInt(_todayKey, state);
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    state = 0;
    await prefs.setInt(_todayKey, 0);
  }
}

final todayXpProvider = StateNotifierProvider<TodayXpNotifier, int>((ref) {
  return TodayXpNotifier();
});

// ─────────────────────────────────────────────────────────────
// Dashboard State
// ─────────────────────────────────────────────────────────────

class DashboardState {
  final bool isLoading;
  final String? error;
  final RoadmapModel? activeRoadmap;
  final LevelModel? activeLevel;

  const DashboardState({
    this.isLoading = false,
    this.error,
    this.activeRoadmap,
    this.activeLevel,
  });

  DashboardState copyWith({
    bool? isLoading,
    String? error,
    RoadmapModel? activeRoadmap,
    LevelModel? activeLevel,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      activeRoadmap: activeRoadmap ?? this.activeRoadmap,
      activeLevel: activeLevel ?? this.activeLevel,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Dashboard Notifier
// ─────────────────────────────────────────────────────────────

class DashboardNotifier extends StateNotifier<DashboardState> {
  final Ref ref;
  DashboardNotifier(this.ref) : super(const DashboardState());

  static const _cachedUserKey = 'cached_user';
  static const _cachedActiveRoadmapKey = 'cached_active_roadmap';

  Future<void> loadDashboard() async {
    // ── Step 1: Show cached data IMMEDIATELY (instant first paint) ──
    await _restoreFromCache();

    // ── Step 2: Set loading overlay (subtle — cached data already shown) ──
    state = state.copyWith(isLoading: true, error: null);

    try {
      // ── Step 3: Parallel API calls — user + roadmaps concurrently ──
      await Future.wait([
        ref.read(authProvider.notifier).getMe(),
        ref.read(roadmapProvider.notifier).fetchRoadmaps(forceRefresh: true),
      ]);

      // ── Step 4: Find the most-recently active incomplete roadmap ──
      final roadmaps = ref.read(roadmapProvider).roadmaps;
      final incomplete = roadmaps.where((r) => !r.isCompleted).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (incomplete.isNotEmpty) {
        final active = incomplete.first;

        // ── Step 5: Fetch levels for active roadmap ──
        await ref
            .read(levelProvider(active.id).notifier)
            .fetchLevels(forceRefresh: true);

        // ── Step 6: Find the next unlocked/active level ──
        final levels = ref.read(levelProvider(active.id)).levels;
        LevelModel? activeLvl;
        try {
          activeLvl = levels.firstWhere((l) => !l.isCompleted && !l.isLocked);
        } catch (_) {
          try {
            activeLvl = levels.firstWhere((l) => !l.isCompleted);
          } catch (_) {
            if (levels.isNotEmpty) activeLvl = levels.last;
          }
        }

        state = state.copyWith(
          isLoading: false,
          activeRoadmap: active,
          activeLevel: activeLvl,
        );

        // ── Step 7: Persist active roadmap to cache ──
        _cacheActiveRoadmap(active);
      } else {
        state = state.copyWith(
          isLoading: false,
          activeRoadmap: null,
          activeLevel: null,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to sync dashboard: $e',
      );
    }
  }

  Future<void> _restoreFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Restore cached active roadmap for instant display
      final cachedRoadmapJson = prefs.getString(_cachedActiveRoadmapKey);
      if (cachedRoadmapJson != null) {
        final roadmap = RoadmapModel.fromJson(
          jsonDecode(cachedRoadmapJson) as Map<String, dynamic>,
        );
        // Show cached state without isLoading=false so spinner still shows
        state = DashboardState(
          isLoading: false,
          activeRoadmap: roadmap,
          activeLevel: null,
        );
      }
    } catch (_) {
      // Cache miss is fine — proceed with fresh load
    }
  }

  Future<void> _cacheActiveRoadmap(RoadmapModel roadmap) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _cachedActiveRoadmapKey,
        jsonEncode(roadmap.toJson()),
      );
    } catch (_) {}
  }
}

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  return DashboardNotifier(ref);
});
