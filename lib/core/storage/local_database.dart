import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../models/roadmap_model.dart';
import '../../models/level_model.dart';

/// SQLite local database for offline caching and pending actions.
class LocalDatabase {
  LocalDatabase._();

  static Database? _db;

  static Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  // ── Init ──────────────────────────────────────────────────────

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'stepup.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE roadmaps (
        id TEXT PRIMARY KEY,
        data TEXT NOT NULL,
        lastSync INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE levels (
        id TEXT PRIMARY KEY,
        roadmapId TEXT NOT NULL,
        data TEXT NOT NULL,
        lastSync INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE pending_actions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        actionType TEXT NOT NULL,
        payload TEXT NOT NULL,
        createdAt INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE user_cache (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    ''');

    // Indexes for faster queries
    await db.execute(
      'CREATE INDEX idx_levels_roadmapId ON levels (roadmapId)',
    );
    await db.execute(
      'CREATE INDEX idx_pending_createdAt ON pending_actions (createdAt)',
    );
  }

  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Future migrations go here
  }

  // ── Roadmaps ──────────────────────────────────────────────────

  static Future<void> saveRoadmap(RoadmapModel roadmap) async {
    final db = await database;
    await db.insert(
      'roadmaps',
      {
        'id': roadmap.id,
        'data': jsonEncode(roadmap.toJson()),
        'lastSync': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<RoadmapModel?> getRoadmap(String id) async {
    final db = await database;
    final rows = await db.query(
      'roadmaps',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return RoadmapModel.fromJson(
      jsonDecode(rows.first['data'] as String) as Map<String, dynamic>,
    );
  }

  static Future<List<RoadmapModel>> getAllRoadmaps() async {
    final db = await database;
    final rows = await db.query('roadmaps', orderBy: 'lastSync DESC');
    return rows
        .map(
          (r) => RoadmapModel.fromJson(
            jsonDecode(r['data'] as String) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  static Future<void> deleteRoadmap(String id) async {
    final db = await database;
    await db.delete('roadmaps', where: 'id = ?', whereArgs: [id]);
    await db.delete('levels', where: 'roadmapId = ?', whereArgs: [id]);
  }

  // ── Levels ────────────────────────────────────────────────────

  static Future<void> saveLevels(List<LevelModel> levels) async {
    final db = await database;
    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final level in levels) {
      batch.insert(
        'levels',
        {
          'id': level.id,
          'roadmapId': level.roadmapId,
          'data': jsonEncode(level.toJson()),
          'lastSync': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  static Future<List<LevelModel>> getLevels(String roadmapId) async {
    final db = await database;
    final rows = await db.query(
      'levels',
      where: 'roadmapId = ?',
      whereArgs: [roadmapId],
      orderBy: "json_extract(data, '\$.levelNumber') ASC",
    );
    return rows
        .map(
          (r) => LevelModel.fromJson(
            jsonDecode(r['data'] as String) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  static Future<LevelModel?> getLevel(String id) async {
    final db = await database;
    final rows = await db.query(
      'levels',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return LevelModel.fromJson(
      jsonDecode(rows.first['data'] as String) as Map<String, dynamic>,
    );
  }

  // ── Pending Actions ──────────────────────────────────────────

  static Future<int> addPendingAction(
    String actionType,
    Map<String, dynamic> payload,
  ) async {
    final db = await database;
    return db.insert('pending_actions', {
      'actionType': actionType,
      'payload': jsonEncode(payload),
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  static Future<List<Map<String, dynamic>>> getPendingActions() async {
    final db = await database;
    final rows = await db.query(
      'pending_actions',
      orderBy: 'createdAt ASC',
    );
    return rows.map((r) {
      return {
        'id': r['id'] as int,
        'actionType': r['actionType'] as String,
        'payload': jsonDecode(r['payload'] as String) as Map<String, dynamic>,
        'createdAt': DateTime.fromMillisecondsSinceEpoch(
          r['createdAt'] as int,
        ),
      };
    }).toList();
  }

  static Future<void> deletePendingAction(int id) async {
    final db = await database;
    await db.delete(
      'pending_actions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> clearPendingActions() async {
    final db = await database;
    await db.delete('pending_actions');
  }

  // ── User Cache ────────────────────────────────────────────────

  static Future<void> saveUserCache(String key, String value) async {
    final db = await database;
    await db.insert(
      'user_cache',
      {
        'key': key,
        'value': value,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<String?> getUserCache(String key) async {
    final db = await database;
    final rows = await db.query(
      'user_cache',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  static Future<void> deleteUserCache(String key) async {
    final db = await database;
    await db.delete('user_cache', where: 'key = ?', whereArgs: [key]);
  }

  static Future<void> clearUserCache() async {
    final db = await database;
    await db.delete('user_cache');
  }

  // ── Maintenance ──────────────────────────────────────────────

  static Future<void> clearAll() async {
    final db = await database;
    await db.delete('roadmaps');
    await db.delete('levels');
    await db.delete('pending_actions');
    await db.delete('user_cache');
  }

  static Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
