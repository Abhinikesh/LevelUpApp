import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/level_model.dart';
import '../../models/roadmap_model.dart';
import 'auth_provider.dart';
import 'level_provider.dart';
import 'roadmap_provider.dart';

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

class DashboardNotifier extends StateNotifier<DashboardState> {
  final Ref ref;
  DashboardNotifier(this.ref) : super(const DashboardState());

  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // 1. Call GET /api/auth/me to update user data
      await ref.read(authProvider.notifier).getMe();

      // 2. Call GET /api/roadmaps to update roadmaps list
      await ref.read(roadmapProvider.notifier).fetchRoadmaps(forceRefresh: true);

      // 3. Find first incomplete roadmap as active
      final roadmaps = ref.read(roadmapProvider).roadmaps;
      final incomplete = roadmaps.where((r) => !r.isCompleted).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (incomplete.isNotEmpty) {
        final active = incomplete.first;

        // 4. Load its levels
        await ref.read(levelProvider(active.id).notifier).fetchLevels(forceRefresh: true);

        // 5. Find active level (not completed, not locked)
        final levels = ref.read(levelProvider(active.id)).levels;
        LevelModel? activeLvl;
        try {
          activeLvl = levels.firstWhere((l) => !l.isCompleted && !l.isLocked);
        } catch (_) {
          try {
            activeLvl = levels.firstWhere((l) => !l.isCompleted);
          } catch (_) {
            if (levels.isNotEmpty) {
              activeLvl = levels.last;
            }
          }
        }

        state = state.copyWith(
          isLoading: false,
          activeRoadmap: active,
          activeLevel: activeLvl,
        );
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
}

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  return DashboardNotifier(ref);
});
