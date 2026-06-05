import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_interceptors.dart';
import '../../core/network/dio_client.dart';
import '../../core/storage/secure_storage.dart';
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
      await getMe();
    }
  }

  // ── Login ─────────────────────────────────────────────────────

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: {'email': email, 'password': password},
      );
      final data = response.data as Map<String, dynamic>;
      final token = data['token'] as String?;
      final refreshToken = data['refreshToken'] as String?;
      final userData = data['user'] as Map<String, dynamic>?;

      if (token != null) {
        await SecureStorageService.saveToken(token);
      }
      if (refreshToken != null) {
        await SecureStorageService.saveRefreshToken(refreshToken);
      }

      final user = userData != null ? UserModel.fromJson(userData) : null;
      if (user != null) {
        await SecureStorageService.saveUserId(user.id);
      }

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
    try {
      final response = await _dio.post(
        ApiConstants.register,
        data: {'name': name, 'email': email, 'password': password},
      );
      final data = response.data as Map<String, dynamic>;
      final token = data['token'] as String?;
      final refreshToken = data['refreshToken'] as String?;
      final userData = data['user'] as Map<String, dynamic>?;

      if (token != null) {
        await SecureStorageService.saveToken(token);
      }
      if (refreshToken != null) {
        await SecureStorageService.saveRefreshToken(refreshToken);
      }

      final user = userData != null ? UserModel.fromJson(userData) : null;
      if (user != null) {
        await SecureStorageService.saveUserId(user.id);
      }

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
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _dio.get(ApiConstants.me);
      final data = response.data as Map<String, dynamic>;
      final userData =
          data['user'] as Map<String, dynamic>? ?? data;
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
    try {
      await _dio.post(ApiConstants.logout);
    } catch (_) {}
    await SecureStorageService.clearAll();
    DioClient.reset();
    state = const AuthState();
  }

  // ── Update user locally (after profile edit) ──────────────────

  void updateLocalUser(UserModel user) {
    state = state.copyWith(currentUser: user);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// ─────────────────────────────────────────────────────────────
// Provider
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
