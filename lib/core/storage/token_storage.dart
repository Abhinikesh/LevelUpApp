import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _tokenKey = 'stepup_token';
  static const _userKey = 'stepup_user';
  static const _storage = FlutterSecureStorage();

  static Future<void> saveToken(String token) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
    } else {
      await _storage.write(key: _tokenKey, value: token);
    }
  }

  static Future<String?> getToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } else {
      return await _storage.read(key: _tokenKey);
    }
  }

  static Future<void> saveUser(String userJson) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, userJson);
    } else {
      await _storage.write(key: _userKey, value: userJson);
    }
  }

  static Future<String?> getUser() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userKey);
    } else {
      return await _storage.read(key: _userKey);
    }
  }

  static Future<void> clearAll() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
    } else {
      await _storage.deleteAll();
    }
  }
}
