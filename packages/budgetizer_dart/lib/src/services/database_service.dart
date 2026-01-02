import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite_common/sqlite_api.dart'; // Abstract Interface
// Note: In pure Dart CLI, we must use sqflite_common_ffi.
// Ideally we abstract "Mobile" vs "Desktop/CLI" initialization.

import '../models/financial_entities.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  DatabaseFactory? _factory;
  String? _dbPath;
  bool _isTemporary = false;

  /// Initialize the database with a specific factory.
  /// [isTemporary] determines if the database is in a temporary location.
  /// [dbName] optional name for the database file (defaults to budgetizer.db)
  Future<void> init(
    DatabaseFactory factory,
    String dirPath, {
    bool isTemporary = false,
    String dbName = 'budgetizer.db',
  }) async {
    // If we are already initialized and the mode is different, close and re-open
    if (_database != null) {
      if (_isTemporary == isTemporary && _dbPath != null) {
        // already initialized in the correct mode
        return;
      }
      await close();
    }

    _factory = factory;
    _isTemporary = isTemporary;

    if (isTemporary) {
      final tempDir = Directory.systemTemp.createTempSync('budgetizer_temp_');
      _dbPath = join(tempDir.path, dbName);
    } else {
      _dbPath = join(dirPath, dbName);
    }

    // Ensure directory exists
    try {
      final dir = Directory(dirname(_dbPath!));
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
    } catch (_) {}

    _database = await factory.openDatabase(
      _dbPath!,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
  }

  /// Close the current database connection
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// Reset the database (clear all tables) - mostly for use with Temporary DBs
  Future<void> reset() async {
    if (_database == null) return;

    // We can either drop tables or delete the file.
    // For simplicity, let's close, delete, and re-open.
    await close();
    if (_dbPath != null) {
      final file = File(_dbPath!);
      if (await file.exists()) {
        await file.delete();
      }
    }
    // Re-open (this will trigger onCreate)
    if (_factory != null && _dbPath != null) {
      _database = await _factory!.openDatabase(
        _dbPath!,
        options: OpenDatabaseOptions(
          version: 2,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        ),
      );
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // 4.1 Account Storage Ref: "one column is the key... another column contains the JSONB content"
    await db.execute('''
      CREATE TABLE cashflow_cycles (
        cycle_key TEXT PRIMARY KEY,
        cashflow_id TEXT NOT NULL,
        cashflow_type TEXT NOT NULL,
        cycle_date TEXT NOT NULL,
        json_content JSONB NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_cashflow_id ON cashflow_cycles(cashflow_id)',
    );

    // 4.2 Report Storage
    await _createReportsTable(db);

    // 4.3 Settings Storage
    await _createSettingsTable(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add reports and settings tables
      await _createReportsTable(db);
      await _createSettingsTable(db);
    }
  }

  Future<void> _createReportsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS reports (
        name TEXT PRIMARY KEY,
        json_content JSONB NOT NULL
      )
    ''');
  }

  Future<void> _createSettingsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  /// Save or Update a Cycle (Cashflow instance representing a period)
  /// [key] should be unique for the cycle, e.g. "checking_1_2025-12"
  Future<void> saveCycle(
    String key,
    Cashflow cycleData,
    String type,
    String cashflowId,
  ) async {
    if (_database == null) {
      throw Exception('Database not initialized. Call init() first.');
    }

    final jsonContent = jsonEncode(cycleData.toJson());

    await _database!.insert(
        'cashflow_cycles',
        {
          'cycle_key': key,
          'cashflow_id': cashflowId,
          'cashflow_type': type,
          'cycle_date': cycleData.cycle.startDate.toIso8601String().substring(
                0,
                10,
              ), // YYYY-MM-DD
          'json_content': jsonContent,
        },
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Retrieve a specific cycle by key
  Future<Cashflow?> getCycle(String key) async {
    if (_database == null) {
      throw Exception('Database not initialized. Call init() first.');
    }

    final List<Map<String, dynamic>> maps = await _database!.query(
      'cashflow_cycles',
      where: 'cycle_key = ?',
      whereArgs: [key],
    );

    if (maps.isNotEmpty) {
      final jsonStr = maps.first['json_content'] as String;
      return Cashflow.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
    }
    return null;
  }

  /// Get all cycles for a specific account (Cashflow Series)
  Future<List<Cashflow>> getCyclesForCashflow(String cashflowId) async {
    if (_database == null) {
      throw Exception('Database not initialized. Call init() first.');
    }

    final List<Map<String, dynamic>> maps = await _database!.query(
      'cashflow_cycles',
      where: 'cashflow_id = ?',
      whereArgs: [cashflowId],
      orderBy: 'cycle_date DESC', // Newest first
    );

    return maps.map((m) {
      final jsonStr = m['json_content'] as String;
      return Cashflow.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
    }).toList();
  }

  // --- REPORT METHODS ---

  Future<void> saveReport(String name, Map<String, dynamic> data) async {
    if (_database == null) throw Exception('DB not initialized');
    await _database!.insert(
      'reports',
      {'name': name, 'json_content': jsonEncode(data)},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getReport(String name) async {
    if (_database == null) throw Exception('DB not initialized');
    final maps = await _database!.query(
      'reports',
      where: 'name = ?',
      whereArgs: [name],
    );
    if (maps.isNotEmpty) {
      return jsonDecode(maps.first['json_content'] as String)
          as Map<String, dynamic>;
    }
    return null;
  }

  Future<List<String>> getAllReportNames() async {
    if (_database == null) return [];
    final maps = await _database!.query('reports', columns: ['name']);
    return maps.map((m) => m['name'] as String).toList();
  }

  Future<void> deleteReport(String name) async {
    if (_database == null) throw Exception('DB not initialized');
    await _database!.delete('reports', where: 'name = ?', whereArgs: [name]);
  }

  // --- SETTINGS METHODS ---

  Future<void> saveSetting(String key, String value) async {
    if (_database == null) throw Exception('DB not initialized');
    await _database!.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key) async {
    if (_database == null) return null;
    try {
      final maps = await _database!.query(
        'settings',
        where: 'key = ?',
        whereArgs: [key],
      );
      if (maps.isNotEmpty) {
        return maps.first['value'] as String;
      }
    } catch (_) {
      // Allow graceful fail if table doesn't exist yet (though it should)
    }
    return null;
  }

  /// Helper to delete db for testing
  Future<void> deleteDb() async {
    if (_factory != null && _dbPath != null) {
      if (_database != null && _database!.isOpen) {
        await _database!.close();
        _database = null;
      }
      await _factory!.deleteDatabase(_dbPath!);
    }
  }

  // Expose underlying DB for direct query if needed (verification)
  Database? get db => _database;
}
