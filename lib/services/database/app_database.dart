import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'album_organizer.db');
    return openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await _createV1Tables(db);
        await _createV2Tables(db);
        await _createV3Tables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createV2Tables(db);
        }
        if (oldVersion < 3) {
          await _createV3Tables(db);
        }
      },
    );
  }

  Future<void> _createV1Tables(Database db) async {
        await db.execute('''
          CREATE TABLE processed_records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            asset_id TEXT NOT NULL,
            source_album_id TEXT NOT NULL,
            target_album_id TEXT,
            action TEXT NOT NULL,
            processed_at INTEGER NOT NULL,
            session_id TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE pending_delete (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            asset_id TEXT NOT NULL UNIQUE,
            source_album_id TEXT NOT NULL,
            marked_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            session_id TEXT NOT NULL UNIQUE,
            source_album_id TEXT NOT NULL,
            target_album_id TEXT NOT NULL,
            started_at INTEGER NOT NULL,
            is_completed INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE app_settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_processed_source ON processed_records(source_album_id)',
        );
        await db.execute(
          'CREATE INDEX idx_processed_session ON processed_records(session_id)',
        );
  }

  Future<void> _createV2Tables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS screenshot_scan_cache (
        bucket TEXT PRIMARY KEY,
        asset_ids TEXT NOT NULL,
        scanned_at INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _createV3Tables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS footprint_assets (
        asset_id TEXT PRIMARY KEY,
        lat REAL NOT NULL,
        lng REAL NOT NULL,
        city_key TEXT NOT NULL,
        city_name TEXT NOT NULL,
        district TEXT,
        taken_at INTEGER,
        scanned_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS footprint_scan_meta (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        last_full_scan_at INTEGER,
        total_with_gps INTEGER NOT NULL DEFAULT 0,
        total_without_gps INTEGER NOT NULL DEFAULT 0,
        total_cities INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_footprint_city ON footprint_assets(city_key)',
    );
  }
}
