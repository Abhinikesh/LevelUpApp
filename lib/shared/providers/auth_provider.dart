import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_interceptors.dart';
import '../../core/network/dio_client.dart';
import '../../core/storage/secure_storage.dart';
import '../../models/badge_model.dart';
import '../../models/user_model.dart';

// ─────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────

class AuthState {
  final UserModel? currentUser;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  const AuthState({
    this.currentUser,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    UserModel? currentUser,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      currentUser: currentUser ?? this.currentUser,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Mock user factory
// ─────────────────────────────────────────────────────────────

UserModel _mockUser({String name = 'Demo User', String email = 'demo@stepup.app'}) {
  return UserModel(
    id: 'mock-user-001',
    name: name,
    email: email,
    avatar: '',
    xpTotal: 2450,
    streakCount: 7,
    longestStreak: 14,
    badges: const <BadgeModel>[],
    createdAt: DateTime.now().subtract(const Duration(days: 30)),
    level: 5,
    totalRoadmaps: 3,
    completedRoadmaps: 1,
    lastActiveDate: DateTime.now(),
  );
}

// ─────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  final Dio _dio;

  AuthNotifier(this._dio) : super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    final hasToken = await SecureStorageService.hasToken();
    if (hasToken) {
      // Try to fetch real user; fall back to cached mock
      await getMe();
    }
  }

  // ── Backend reachable check ───────────────────────────────────

  bool get _isPlaceholderBackend =>
      ApiConstants.baseUrl.contains('your-backend') ||
      ApiConstants.baseUrl.contains('localhost') ||
      ApiConstants.baseUrl.isEmpty;

  // ── Login ─────────────────────────────────────────────────────

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    // ── Demo / mock mode (no real backend configured) ─────────
    if (_isPlaceholderBackend || kDebugMode) {
      await Future.delayed(const Duration(milliseconds: 900)); // fake latency
      final mock = _mockUser(
        name: _nameFromEmail(email),
        email: email,
      );
      await SecureStorageService.saveToken('mock-jwt-token-${mock.id}');
      await SecureStorageService.saveUserId(mock.id);
      state = state.copyWith(
        isLoading: false,
        currentUser: mock,
        isAuthenticated: true,
      );
      return true;
    }

    // ── Real API call ─────────────────────────────────────────
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: {'email': email, 'password': password},
      );
      final data = response.data as Map<String, dynamic>;
      final token = data['token'] as String?;
      final refreshToken = data['refreshToken'] as String?;
      final userData = data['user'] as Map<String, dynamic>?;

      if (token != null) await SecureStorageService.saveToken(token);
      if (refreshToken != null) await SecureStorageService.saveRefreshToken(refreshToken);

      final user = userData != null ? UserModel.fromJson(userData) : null;
      if (user != null) await SecureStorageService.saveUserId(user.id);

      state = state.copyWith(
        isLoading: false,
        currentUser: user,
        isAuthenticated: token != null,
      );
      return token != null;
    } on DioException catch (e) {
      final ex = ApiException.fromDioError(e);
      state = state.copyWith(isLoading: false, error: ex.message);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Something went wrong. Please try again.',
      );
      return false;
    }
  }

  // ── Register ──────────────────────────────────────────────────

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    // ── Demo / mock mode ──────────────────────────────────────
    if (_isPlaceholderBackend || kDebugMode) {
      await Future.delayed(const Duration(milliseconds: 1100));
      final mock = _mockUser(name: name, email: email);
      await SecureStorageService.saveToken('mock-jwt-token-${mock.id}');
      await SecureStorageService.saveUserId(mock.id);
      state = state.copyWith(
        isLoading: false,
        currentUser: mock,
        isAuthenticated: true,
      );
      return true;
    }

    // ── Real API call ─────────────────────────────────────────
    try {
      final response = await _dio.post(
        ApiConstants.register,
        data: {'name': name, 'email': email, 'password': password},
      );
      final data = response.data as Map<String, dynamic>;
      final token = data['token'] as String?;
      final refreshToken = data['refreshToken'] as String?;
      final userData = data['user'] as Map<String, dynamic>?;

      if (token != null) await SecureStorageService.saveToken(token);
      if (refreshToken != null) await SecureStorageService.saveRefreshToken(refreshToken);

      final user = userData != null ? UserModel.fromJson(userData) : null;
      if (user != null) await SecureStorageService.saveUserId(user.id);

      state = state.copyWith(
        isLoading: false,
        currentUser: user,
        isAuthenticated: token != null,
      );
      return token != null;
    } on DioException catch (e) {
      final ex = ApiException.fromDioError(e);
      state = state.copyWith(isLoading: false, error: ex.message);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Registration failed. Please try again.',
      );
      return false;
    }
  }

  // ── Get Me ────────────────────────────────────────────────────

  Future<void> getMe() async {
    // In mock mode, rehydrate from stored token
    if (_isPlaceholderBackend || kDebugMode) {
      final token = await SecureStorageService.getToken();
      if (token != null && token.isNotEmpty) {
        state = state.copyWith(
          isLoading: false,
          currentUser: _mockUser(),
          isAuthenticated: true,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _dio.get(ApiConstants.me);
      final data = response.data as Map<String, dynamic>;
      final userData = data['user'] as Map<String, dynamic>? ?? data;
      final user = UserModel.fromJson(userData);

      state = state.copyWith(
        isLoading: false,
        currentUser: user,
        isAuthenticated: true,
      );
    } on DioException catch (e) {
      final ex = ApiException.fromDioError(e);
      if (ex.isUnauthorized) {
        await logout();
      } else {
        state = state.copyWith(isLoading: false, error: ex.message);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  // ── Logout ────────────────────────────────────────────────────

  Future<void> logout() async {
    if (!_isPlaceholderBackend) {
      try {
        await _dio.post(ApiConstants.logout);
      } catch (_) {}
    }
    await SecureStorageService.clearAll();
    if (!_isPlaceholderBackend) DioClient.reset();
    state = const AuthState();
  }

  // ── Update user locally ───────────────────────────────────────

  void updateLocalUser(UserModel user) {
    state = state.copyWith(currentUser: user);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// ─────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────

String _nameFromEmail(String email) {
  final local = email.split('@').first;
  final parts = local.split(RegExp(r'[._\-]'));
  return parts.map((p) {
    if (p.isEmpty) return '';
    return p[0].toUpperCase() + p.substring(1);
  }).join(' ').trim();
}

// ─────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(DioClient.instance);
});

/// Convenience: current user (nullable)
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).currentUser;
});

/// Convenience: is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});
