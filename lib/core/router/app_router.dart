import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/home/presentation/home_shell.dart';
import '../../features/home/presentation/dashboard_screen.dart';
import '../../features/map/presentation/map_list_screen.dart';
import '../../features/map/presentation/map_view_screen.dart';
import '../../features/roadmap/presentation/create_roadmap_screen.dart';
import '../../features/social/presentation/social_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/roadmap/presentation/level_detail_screen.dart';
import '../../features/verification/presentation/verification_screen.dart';
import '../../features/ai_coach/presentation/ai_coach_screen.dart';
import '../../features/profile/presentation/settings_screen.dart';
import '../../shared/providers/auth_provider.dart';
import '../storage/secure_storage.dart';

// ─────────────────────────────────────────────────────────────
// Route name constants
// ─────────────────────────────────────────────────────────────

class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const signup = '/signup';
  static const home = '/home';
  static const dashboard = '/home/dashboard';
  static const map = '/home/map';
  static const create = '/home/create';
  static const social = '/home/social';
  static const profile = '/home/profile';
  static const levelDetail = '/level';
  static const verification = '/verification';
  static const coach = '/coach';
  static const settings = '/settings';
}

// ─────────────────────────────────────────────────────────────
// Router provider
// ─────────────────────────────────────────────────────────────

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: GoRouterRefreshStream(ref.watch(authProvider.notifier).stream),
    redirect: (context, state) async {
      final authState = ref.read(authProvider);
      final hasToken = await SecureStorageService.hasToken();
      final isAuthenticated = authState.isAuthenticated || hasToken;
      final location = state.matchedLocation;

      final isAuthRoute = location == AppRoutes.login ||
          location == AppRoutes.signup ||
          location == AppRoutes.splash ||
          location == AppRoutes.onboarding;

      // If not authenticated and trying to access protected route
      if (!isAuthenticated && !isAuthRoute) {
        return AppRoutes.login;
      }

      // If authenticated and on auth screen, redirect to dashboard
      if (isAuthenticated &&
          (location == AppRoutes.login || location == AppRoutes.signup)) {
        return AppRoutes.dashboard;
      }

      return null; // no redirect
    },
    routes: [
      // ── Auth routes ──────────────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (context, state) => _fade(const SplashScreen()),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (context, state) => _slide(const OnboardingScreen()),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) => _fade(const LoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.signup,
        pageBuilder: (context, state) => _slide(const SignupScreen()),
      ),

      // ── Home shell (bottom nav) ──────────────────────────────
      ShellRoute(
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            pageBuilder: (context, state) =>
                _noTransition(const DashboardScreen()),
          ),
          GoRoute(
            path: AppRoutes.map,
            pageBuilder: (context, state) =>
                _noTransition(const MapListScreen()),
          ),
          GoRoute(
            path: '${AppRoutes.map}/:roadmapId',
            pageBuilder: (context, state) {
              final roadmapId = state.pathParameters['roadmapId']!;
              return _slide(MapViewScreen(roadmapId: roadmapId));
            },
          ),
          GoRoute(
            path: AppRoutes.create,
            pageBuilder: (context, state) =>
                _slide(const CreateRoadmapScreen()),
          ),
          GoRoute(
            path: AppRoutes.social,
            pageBuilder: (context, state) =>
                _noTransition(const SocialScreen()),
          ),
          GoRoute(
            path: AppRoutes.profile,
            pageBuilder: (context, state) =>
                _noTransition(const ProfileScreen()),
          ),
        ],
      ),

      // ── Detail routes (outside shell) ────────────────────────
      GoRoute(
        path: '${AppRoutes.levelDetail}/:levelId',
        pageBuilder: (context, state) {
          final levelId = state.pathParameters['levelId']!;
          return _slide(LevelDetailScreen(levelId: levelId));
        },
      ),
      GoRoute(
        path: '${AppRoutes.verification}/:levelId/:type',
        pageBuilder: (context, state) {
          final levelId = state.pathParameters['levelId']!;
          final type = state.pathParameters['type']!;
          return _slide(VerificationScreen(levelId: levelId, proofType: type));
        },
      ),
      GoRoute(
        path: AppRoutes.coach,
        pageBuilder: (context, state) => _slide(const AICoachScreen()),
      ),
      GoRoute(
        path: AppRoutes.settings,
        pageBuilder: (context, state) => _slide(const SettingsScreen()),
      ),
    ],
    errorBuilder: (context, state) => _ErrorPage(error: state.error),
  );
});

// ─────────────────────────────────────────────────────────────
// Transition helpers
// ─────────────────────────────────────────────────────────────

CustomTransitionPage<void> _fade(Widget child) {
  return CustomTransitionPage<void>(
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}

CustomTransitionPage<void> _slide(Widget child) {
  return CustomTransitionPage<void>(
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final tween = Tween(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic));
      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 350),
  );
}

CustomTransitionPage<void> _noTransition(Widget child) {
  return CustomTransitionPage<void>(
    child: child,
    transitionsBuilder: (_, __, ___, c) => c,
    transitionDuration: Duration.zero,
  );
}

// ─────────────────────────────────────────────────────────────
// Error page
// ─────────────────────────────────────────────────────────────

class _ErrorPage extends StatelessWidget {
  final Exception? error;
  const _ErrorPage({this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🚫', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            const Text(
              'Page not found',
              style: TextStyle(
                color: Color(0xFFF0F0FF),
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error?.toString() ?? 'Unknown route',
              style: const TextStyle(color: Color(0xFF8B8BAE)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => context.go(AppRoutes.dashboard),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Stream-based Listenable for GoRouter
// ─────────────────────────────────────────────────────────────
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
