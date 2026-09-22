import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static Database? _db;
  static Future<Database>? _opening;
  static String? _cachedPath;

  static Future<String> databasePath() async {
    _cachedPath ??= p.join(await getDatabasesPath(), 'kargah_yar.db');
    return _cachedPath!;
  }

  static Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
      _opening = null;
    }
  }

  static Future<Database> reopen() async {
    await close();
    return instance();
  }

  static Future<Database> instance() async {
    if (_db != null) {
      return _db!;
    }
    _opening ??= _open();
    _db = await _opening!;
    return _db!;
  }

  static Future<Database> _open() async {
    final path = p.join(await getDatabasesPath(), 'kargah_yar.db');
    return openDatabase(
      path,
      version: 4,
      onCreate: (db, version) async {
        await _createV1(db);
        await _createV2(db);
        await _createV4(db);
        await _seedDefaultSettings(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createV2(db);
          await _seedDefaultSettings(db);
        }
        if (oldVersion < 3) {
          await _createV3(db);
        }
        if (oldVersion < 4) {
          await _createV4(db);
        }
      },
    );
  }

  static Future<void> _createV1(Database db) async {
    await db.execute('''
      CREATE TABLE vehicles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plate_key TEXT NOT NULL UNIQUE,
        owner_name TEXT NOT NULL,
        owner_phone TEXT NOT NULL,
        make TEXT NOT NULL,
        model TEXT NOT NULL,
        year TEXT NOT NULL,
        color TEXT NOT NULL,
        mileage INTEGER NOT NULL,
        plate_photo_path TEXT,
        vin TEXT NOT NULL DEFAULT '',
        next_service_km INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE visits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_id INTEGER NOT NULL,
        happened_at INTEGER NOT NULL,
        title TEXT NOT NULL,
        note TEXT NOT NULL,
        amount INTEGER NOT NULL,
        labor_amount INTEGER NOT NULL DEFAULT 0,
        parts_amount INTEGER NOT NULL DEFAULT 0,
        paid INTEGER NOT NULL DEFAULT 0,
        part_id INTEGER
      )
    ''');
  }

  static Future<void> _createV2(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL UNIQUE,
        note TEXT NOT NULL DEFAULT ''
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS jobs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        note TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS parts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        sku TEXT NOT NULL,
        stock INTEGER NOT NULL,
        buy_price INTEGER NOT NULL,
        sell_price INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS appointments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_id INTEGER,
        customer_name TEXT NOT NULL,
        plate_text TEXT NOT NULL,
        scheduled_at INTEGER NOT NULL,
        bay INTEGER NOT NULL,
        note TEXT NOT NULL,
        status TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _seedDefaultSettings(Database db) async {
    const defaults = <String, String>{
      'shop_name': '',
      'owner_name': '',
      'phone': '',
      'address': '',
    };
    for (final entry in defaults.entries) {
      await db.insert(
        'settings',
        {'key': entry.key, 'value': entry.value},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  static Future<void> _createV3(Database db) async {
    await db.execute("ALTER TABLE vehicles ADD COLUMN vin TEXT NOT NULL DEFAULT ''");
    await db.execute('ALTER TABLE vehicles ADD COLUMN next_service_km INTEGER NOT NULL DEFAULT 0');
    await db.execute('ALTER TABLE visits ADD COLUMN paid INTEGER NOT NULL DEFAULT 0');
    await db.execute('ALTER TABLE visits ADD COLUMN part_id INTEGER');
  }

  static Future<void> _createV4(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS visit_parts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        visit_id INTEGER NOT NULL,
        part_id INTEGER,
        name TEXT NOT NULL,
        qty INTEGER NOT NULL DEFAULT 1,
        unit_price INTEGER NOT NULL
      )
    ''');
    final visits = await db.query('visits', columns: ['id', 'part_id', 'parts_amount']);
    for (final visit in visits) {
      final partId = visit['part_id'] as int?;
      if (partId == null) {
        continue;
      }
      final parts = await db.query('parts', columns: ['name', 'sell_price'], where: 'id = ?', whereArgs: [partId], limit: 1);
      final name = parts.isEmpty ? 'قطعه' : parts.first['name'] as String;
      final price = visit['parts_amount'] as int? ?? (parts.isEmpty ? 0 : parts.first['sell_price'] as int);
      await db.insert('visit_parts', {
        'visit_id': visit['id'],
        'part_id': partId,
        'name': name,
        'qty': 1,
        'unit_price': price,
      });
    }
  }
}
