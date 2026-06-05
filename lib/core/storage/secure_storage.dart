import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wrapper around FlutterSecureStorage for JWT and app secrets.
class SecureStorageService {
  SecureStorageService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // ── Key constants ────────────────────────────────────────────
  static const String _jwtKey = 'jwt_token';
  static const String _refreshKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _onboardedKey = 'onboarding_complete';

  // ── JWT ──────────────────────────────────────────────────────

  static Future<void> saveToken(String token) =>
      _storage.write(key: _jwtKey, value: token);

  static Future<String?> getToken() => _storage.read(key: _jwtKey);

  static Future<void> deleteToken() => _storage.delete(key: _jwtKey);

  // ── Refresh Token ────────────────────────────────────────────

  static Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _refreshKey, value: token);

  static Future<String?> getRefreshToken() =>
      _storage.read(key: _refreshKey);

  static Future<void> deleteRefreshToken() =>
      _storage.delete(key: _refreshKey);

  // ── User ID ──────────────────────────────────────────────────

  static Future<void> saveUserId(String userId) =>
      _storage.write(key: _userIdKey, value: userId);

  static Future<String?> getUserId() => _storage.read(key: _userIdKey);

  // ── Onboarding ───────────────────────────────────────────────

  static Future<void> setOnboardingComplete() =>
      _storage.write(key: _onboardedKey, value: 'true');

  static Future<bool> isOnboardingComplete() async {
    final val = await _storage.read(key: _onboardedKey);
    return val == 'true';
  }

  // ── Generic ──────────────────────────────────────────────────

  static Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  static Future<String?> read(String key) => _storage.read(key: key);

  static Future<void> delete(String key) => _storage.delete(key: key);

  /// Clears all secure storage — call on logout.
  static Future<void> clearAll() => _storage.deleteAll();

  /// Returns true if a valid JWT is stored.
  static Future<bool> hasToken() async {
    final token = await _storage.read(key: _jwtKey);
    return token != null && token.isNotEmpty;
  }
}
