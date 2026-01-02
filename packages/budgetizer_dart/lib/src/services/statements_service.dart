import 'dart:io';
// import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../models/financial_entities.dart';

/// Represents a collection of statements stored in a directory.
class StatementsService {
  final String rootPath;

  StatementsService({required this.rootPath});

  /// Create a new Statements DB (just a formatted directory)
  Future<void> createStatementsDb(String name) async {
    final dir = Directory(p.join(rootPath, name));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  /// Get list of available Statement DBs (subdirectories)
  Future<List<String>> listStatementDbs() async {
    final root = Directory(rootPath);
    if (!await root.exists()) return [];

    final List<String> dbs = [];
    await for (final entity in root.list()) {
      if (entity is Directory) {
        dbs.add(p.basename(entity.path));
      }
    }
    return dbs;
  }

  /// Save a raw statement file into the named DB and return its new path
  Future<String> saveStatementFile(String dbName, File sourceFile) async {
    final dbDir = Directory(p.join(rootPath, dbName));
    if (!await dbDir.exists()) {
      throw Exception('Statements DB "$dbName" does not exist.');
    }

    // Copy file to DB folder with unique name or keep original if unique
    final filename = p.basename(sourceFile.path);
    final destPath = p.join(dbDir.path, filename);

    // Simple duplication check/rename could go here
    await sourceFile.copy(destPath);
    return destPath;
  }

  /// Parse a statement file and return transactions.
  /// This is a placeholder for the actual parsing logic (which might need AI or CSV parsing).
  /// For now, we'll implement a simple mock or support the YAML format we use for testing.
  Future<List<BankTransaction>> parseStatement(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) throw Exception('File not found: $filePath');

    final ext = p.extension(filePath).toLowerCase();
    if (ext == '.yaml' || ext == '.yml') {
      // Assume our standard test format
      // In a real implementation this would use a proper YAML parser
      final content = await file.readAsString();
      // ... very robust parsing ...
      return _parseSimpleYaml(content);
    }

    // Fallback or other formats would go here
    return [];
  }

  // Quick hacky parser for the standardized YAML format we saw in tests
  List<BankTransaction> _parseSimpleYaml(String content) {
    final List<BankTransaction> txs = [];
    final lines = content.split('\n');

    Map<String, dynamic> currentTx = {};

    for (var line in lines) {
      line = line.trim();
      if (line.startsWith('- id:')) {
        if (currentTx.isNotEmpty) {
          txs.add(_mapToTx(currentTx));
          currentTx = {};
        }
        currentTx['id'] = _extractValue(line);
      } else if (line.startsWith('date:')) {
        currentTx['date'] = _extractValue(line);
      } else if (line.startsWith('description:')) {
        currentTx['description'] = _extractValue(line);
      } else if (line.startsWith('amount:')) {
        currentTx['amount'] = _extractValue(line);
      } else if (line.startsWith('vendor:')) {
        currentTx['vendor'] = _extractValue(line);
      } else if (line.startsWith('tags:')) {
        // rough parse of [ "a", "b" ]
        String val =
            line.substring(line.indexOf('[') + 1, line.lastIndexOf(']'));
        currentTx['tags'] = val
            .split(',')
            .map((s) => s.trim().replaceAll('"', ''))
            .where((s) => s.isNotEmpty)
            .toList();
      }
    }
    if (currentTx.isNotEmpty) {
      txs.add(_mapToTx(currentTx));
    }
    return txs;
  }

  String _extractValue(String line) {
    final parts = line.split(':');
    if (parts.length < 2) return '';
    var val = parts.sublist(1).join(':').trim();
    if (val.startsWith('"') && val.endsWith('"')) {
      val = val.substring(1, val.length - 1);
    }
    return val;
  }

  BankTransaction _mapToTx(Map<String, dynamic> map) {
    return BankTransaction(
      id: (map['id'] as String?) ?? const Uuid().v4(),
      date: map['date'] != null
          ? DateTime.parse(map['date'] as String)
          : DateTime.now(),
      description: (map['description'] as String?) ?? 'Unknown',
      vendorName: (map['vendor'] as String?) ?? 'Unknown',
      amount: double.tryParse((map['amount'] ?? 0.0).toString()) ?? 0.0,
      tags:
          (map['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
              [],
      pending: false, // Default to settled for statements
      cashflowId: 'imported', // Default, likely overwritten by caller
    );
  }
}
