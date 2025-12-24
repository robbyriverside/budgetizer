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

  /// Initialize the database with a specific factory.
  /// This allows dependency injection:
  /// - Flutter App: Use `databaseFactory` from `package:sqflite` (native channels).
  /// - Dart CLI: Use `databaseFactoryFfi` from `package:sqflite_common_ffi`.
  Future<void> init(DatabaseFactory factory, String dirPath) async {
    if (_database != null) return;

    _factory = factory;
    _dbPath = join(dirPath, 'budgetizer.db');

    // Ensure directory exists if acting in CLI mode
    try {
      final dir = Directory(dirname(_dbPath!));
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
    } catch (_) {}

    _database = await factory.openDatabase(
      _dbPath!,
      options: OpenDatabaseOptions(version: 1, onCreate: _onCreate),
    );
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
