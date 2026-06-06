import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Secure storage wrapper.
/// On mobile: uses FlutterSecureStorage (encrypted).
/// On web: falls back to SharedPreferences (no native keychain on web).
class SecureStorageService {
  SecureStorageService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // ── Key constants ─────────────────────────────────────────────
  static const String _jwtKey = 'jwt_token';
  static const String _refreshKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _onboardedKey = 'onboarding_complete';

  // ── Internal read/write (platform-safe) ───────────────────────

  static Future<void> _write(String key, String value) async {
    if (kIsWeb) {
      final p = await SharedPreferences.getInstance();
      await p.setString('sec_$key', value);
    } else {
      await _storage.write(key: key, value: value);
    }
  }

  static Future<String?> _read(String key) async {
    if (kIsWeb) {
      final p = await SharedPreferences.getInstance();
      return p.getString('sec_$key');
    }
    return _storage.read(key: key);
  }

  static Future<void> _delete(String key) async {
    if (kIsWeb) {
      final p = await SharedPreferences.getInstance();
      await p.remove('sec_$key');
    } else {
      await _storage.delete(key: key);
    }
  }

  // ── JWT ───────────────────────────────────────────────────────

  static Future<void> saveToken(String token) => _write(_jwtKey, token);
  static Future<String?> getToken() => _read(_jwtKey);
  static Future<void> deleteToken() => _delete(_jwtKey);

  // ── Refresh Token ─────────────────────────────────────────────

  static Future<void> saveRefreshToken(String token) =>
      _write(_refreshKey, token);
  static Future<String?> getRefreshToken() => _read(_refreshKey);
  static Future<void> deleteRefreshToken() => _delete(_refreshKey);

  // ── User ID ───────────────────────────────────────────────────

  static Future<void> saveUserId(String userId) => _write(_userIdKey, userId);
  static Future<String?> getUserId() => _read(_userIdKey);

  // ── Onboarding ────────────────────────────────────────────────

  static Future<void> setOnboardingComplete() =>
      _write(_onboardedKey, 'true');

  static Future<bool> isOnboardingComplete() async {
    final val = await _read(_onboardedKey);
    return val == 'true';
  }

  // ── Generic ───────────────────────────────────────────────────

  static Future<void> write(String key, String value) => _write(key, value);
  static Future<String?> read(String key) => _read(key);
  static Future<void> delete(String key) => _delete(key);

  /// Clears all secure storage — call on logout.
  static Future<void> clearAll() async {
    if (kIsWeb) {
      final p = await SharedPreferences.getInstance();
      final keys = p.getKeys().where((k) => k.startsWith('sec_')).toList();
      for (final k in keys) {
        await p.remove(k);
      }
    } else {
      await _storage.deleteAll();
    }
  }

  /// Returns true if a valid JWT is stored.
  static Future<bool> hasToken() async {
    final token = await _read(_jwtKey);
    return token != null && token.isNotEmpty;
  }
}
