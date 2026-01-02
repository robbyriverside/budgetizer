import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgetizer_dart/budgetizer_dart.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;

void main() {
  late DatabaseService dbService;
  late StatementsService statementsService;
  late Directory tempDir;

  setUpAll(() {
    // Initialize FFI for SQFLite in tests
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('budgetizer_test_');
    dbService = DatabaseService();
    statementsService = StatementsService(
      rootPath: p.join(tempDir.path, 'statements'),
    );
    await Directory(statementsService.rootPath).create(recursive: true);
  });

  tearDown(() async {
    await dbService.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'DatabaseService initializes in temporary mode and can be reset',
    () async {
      // 1. Init Temp DB
      await dbService.init(databaseFactoryFfi, tempDir.path, isTemporary: true);

      // 2. Save some data
      final dummyCycle = Cashflow(
        id: 'test_cycle_1',
        seriesId: 'test_cf',
        cycle: Cycle(startDate: DateTime.now()),
        transactions: [
          BankTransaction(
            id: 'test_tx_1',
            date: DateTime.now(),
            amount: -50.0,
            vendorName: 'Test Vendor',
            description: 'Test Desc',
            tags: ['Test'],
            cashflowId: 'test_cf',
            pending: false,
          ),
        ],
        openingBalance: 1000,
        closingBalance: 950,
      );

      // Save cycle
      await dbService.saveCycle(
        'test_cycle_key',
        dummyCycle,
        'checking',
        'test_cf',
      );

      // 3. Verify it exists
      final retrieved = await dbService.getCycle('test_cycle_key');
      expect(retrieved, isNotNull);
      expect(retrieved!.transactions.first.amount, -50.0);

      // 4. Reset DB
      await dbService.reset();

      // 5. Verify it's gone
      final retrievedAfterReset = await dbService.getCycle('test_cycle_key');
      expect(retrievedAfterReset, isNull);
    },
  );

  test('StatementsService can create DB and parse transactions', () async {
    // 1. Create a named Statements DB
    final dbName = 'jan_2025';
    await statementsService.createStatementsDb(dbName);

    // 2. Check it exists
    final dbs = await statementsService.listStatementDbs();
    expect(dbs, contains(dbName));

    // 3. Create a dummy YAML statement file
    final statementContent = '''
transactions:
  - id: "tx_1"
    date: "2025-01-01"
    description: "Grocery Store"
    vendor: "Safeway"
    amount: -120.50
    tags: ["Groceries", "Food"]
  - id: "tx_2"
    date: "2025-01-02"
    description: "Gas Station"
    vendor: "Shell"
    amount: -45.00
    tags: ["Gas"]
''';
    final stmtFile = File(p.join(tempDir.path, 'stmt.yaml'));
    await stmtFile.writeAsString(statementContent);

    // 4. Save file to Statements DB
    final savedPath = await statementsService.saveStatementFile(
      dbName,
      stmtFile,
    );
    expect(File(savedPath).existsSync(), isTrue);
    expect(p.dirname(savedPath).endsWith(dbName), isTrue);

    // 5. Parse it
    final txs = await statementsService.parseStatement(savedPath);

    expect(txs.length, 2);
    expect(txs[0].vendorName, 'Safeway');
    expect(txs[0].amount, -120.50);
    expect(txs[0].tags, contains('Groceries'));
    expect(txs[1].vendorName, 'Shell');
  });
}
