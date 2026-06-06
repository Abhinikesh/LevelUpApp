import 'dart:convert';


import 'package:shared_preferences/shared_preferences.dart';
import '../../models/roadmap_model.dart';
import '../../models/level_model.dart';

/// Web-only in-memory + SharedPreferences cache.
/// Mirrors the LocalDatabase API so providers stay unchanged.
class LocalDatabase {
  LocalDatabase._();

  static SharedPreferences? _prefs;

  static Future<SharedPreferences> get _p async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ── Roadmaps ──────────────────────────────────────────────────

  static Future<void> saveRoadmap(RoadmapModel roadmap) async {
    final p = await _p;
    final list = p.getStringList('roadmaps') ?? [];
    final json = jsonEncode(roadmap.toJson());
    // Replace or add
    final idx = list.indexWhere((s) {
      try {
        return (jsonDecode(s) as Map)['_id'] == roadmap.id ||
            (jsonDecode(s) as Map)['id'] == roadmap.id;
      } catch (_) {
        return false;
      }
    });
    if (idx >= 0) {
      list[idx] = json;
    } else {
      list.add(json);
    }
    await p.setStringList('roadmaps', list);
  }

  static Future<RoadmapModel?> getRoadmap(String id) async {
    final all = await getAllRoadmaps();
    try {
      return all.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  static Future<List<RoadmapModel>> getAllRoadmaps() async {
    final p = await _p;
    final list = p.getStringList('roadmaps') ?? [];
    return list.map((s) {
      try {
        return RoadmapModel.fromJson(
            jsonDecode(s) as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    }).whereType<RoadmapModel>().toList();
  }

  static Future<void> deleteRoadmap(String id) async {
    final p = await _p;
    final list = p.getStringList('roadmaps') ?? [];
    list.removeWhere((s) {
      try {
        final m = jsonDecode(s) as Map;
        return m['_id'] == id || m['id'] == id;
      } catch (_) {
        return false;
      }
    });
    await p.setStringList('roadmaps', list);
  }

  // ── Levels ────────────────────────────────────────────────────

  static Future<void> saveLevels(List<LevelModel> levels) async {
    final p = await _p;
    final list = p.getStringList('levels') ?? [];
    for (final level in levels) {
      final json = jsonEncode(level.toJson());
      final idx = list.indexWhere((s) {
        try {
          return (jsonDecode(s) as Map)['_id'] == level.id ||
              (jsonDecode(s) as Map)['id'] == level.id;
        } catch (_) {
          return false;
        }
      });
      if (idx >= 0) {
        list[idx] = json;
      } else {
        list.add(json);
      }
    }
    await p.setStringList('levels', list);
  }

  static Future<List<LevelModel>> getLevels(String roadmapId) async {
    final p = await _p;
    final list = p.getStringList('levels') ?? [];
    return list.map((s) {
      try {
        return LevelModel.fromJson(
            jsonDecode(s) as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    }).whereType<LevelModel>().where((l) => l.roadmapId == roadmapId).toList();
  }

  static Future<LevelModel?> getLevel(String id) async {
    final levels = await getLevels('');
    try {
      return levels.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── Pending Actions ───────────────────────────────────────────

  static Future<int> addPendingAction(
      String actionType, Map<String, dynamic> payload) async {
    final p = await _p;
    final list = p.getStringList('pending_actions') ?? [];
    list.add(jsonEncode({'actionType': actionType, 'payload': payload}));
    await p.setStringList('pending_actions', list);
    return list.length;
  }

  static Future<List<Map<String, dynamic>>> getPendingActions() async {
    final p = await _p;
    final list = p.getStringList('pending_actions') ?? [];
    return list.map((s) {
      try {
        return jsonDecode(s) as Map<String, dynamic>;
      } catch (_) {
        return <String, dynamic>{};
      }
    }).where((m) => m.isNotEmpty).toList();
  }

  static Future<void> deletePendingAction(int id) async {
    final p = await _p;
    final list = p.getStringList('pending_actions') ?? [];
    if (id < list.length) list.removeAt(id);
    await p.setStringList('pending_actions', list);
  }

  static Future<void> clearPendingActions() async {
    final p = await _p;
    await p.remove('pending_actions');
  }

  // ── User Cache ────────────────────────────────────────────────

  static Future<void> saveUserCache(String key, String value) async {
    final p = await _p;
    await p.setString('uc_$key', value);
  }

  static Future<String?> getUserCache(String key) async {
    final p = await _p;
    return p.getString('uc_$key');
  }

  static Future<void> deleteUserCache(String key) async {
    final p = await _p;
    await p.remove('uc_$key');
  }

  static Future<void> clearUserCache() async {
    final p = await _p;
    final keys = p.getKeys().where((k) => k.startsWith('uc_')).toList();
    for (final k in keys) {
      await p.remove(k);
    }
  }

  // ── Maintenance ───────────────────────────────────────────────

  static Future<void> clearAll() async {
    final p = await _p;
    await p.remove('roadmaps');
    await p.remove('levels');
    await p.remove('pending_actions');
    final ucKeys = p.getKeys().where((k) => k.startsWith('uc_')).toList();
    for (final k in ucKeys) {
      await p.remove(k);
    }
  }

  static Future<void> close() async {
    // No-op for SharedPreferences
  }
}
