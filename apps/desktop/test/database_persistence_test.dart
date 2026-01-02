import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:budgetizer_dart/budgetizer_dart.dart';
import 'package:budgetizer_dart/src/services/database_service.dart';

void main() {
  setUpAll(() {
    // Initialize FFI for desktop/CLI testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Database Persistence', () {
    late DatabaseService dbService;
    final testDir = Directory.systemTemp.createTempSync('budgetizer_test_');

    setUp(() async {
      dbService = DatabaseService();
      await dbService.init(databaseFactoryFfi, testDir.path);
    });

    tearDown(() async {
      await dbService.deleteDb();
    });

    tearDownAll(() {
      if (testDir.existsSync()) {
        testDir.deleteSync(recursive: true);
      }
    });

    test('Should save and retrieve a cycle', () async {
      final cycleKey = 'test_cycle_key';
      final cashflowId = 'test_cashflow';

      final tx1 = BankTransaction(
        id: 'tx1',
        date: DateTime.now(),
        amount: -50.0,
        description: 'Test Transaction',
        vendorName: 'Tester',
        tags: ['TestTag'],
        pending: false,
        cashflowId: cashflowId,
      );

      final cycle = Cashflow(
        id: 'flow1',
        seriesId: cashflowId,
        cycle: Cycle(startDate: DateTime(2025, 1, 1)),
        transactions: [tx1],
      );

      print('DEBUG: Saving cycle...');
      await dbService.saveCycle(cycleKey, cycle, 'checking', cashflowId);

      print('DEBUG: Retrieving cycle...');
      final retrieved = await dbService.getCycle(cycleKey);

      expect(retrieved, isNotNull);
      expect(retrieved!.transactions.length, 1);
      expect(retrieved.transactions.first.amount, -50.0);
      print('DEBUG: Cycle retrieved successfully with correct data.');
    });

    test('Should persist updates to a cycle', () async {
      final cycleKey = 'update_test_key';
      final cashflowId = 'update_cashflow';

      // 1. Initial Save
      final tx1 = BankTransaction(
        id: 'tx1',
        date: DateTime.now(),
        amount: -100.0,
        description: 'Initial',
        vendorName: 'Vendor A',
        tags: ['Tag A'],
        pending: false,
        cashflowId: cashflowId,
      );

      final initialCycle = Cashflow(
        id: 'flow1',
        seriesId: cashflowId,
        cycle: Cycle(startDate: DateTime(2025, 1, 1)),
        transactions: [tx1],
      );

      await dbService.saveCycle(cycleKey, initialCycle, 'checking', cashflowId);

      // 2. Modify and Save
      final txUpdate = tx1.copyWith(tags: ['Tag B', 'Tag A']);
      final updatedCycle = Cashflow(
        id: 'flow1',
        seriesId: cashflowId, // Keep same IDs
        cycle: Cycle(startDate: DateTime(2025, 1, 1)),
        transactions: [txUpdate],
      );

      print('DEBUG: Updating cycle with new tags...');
      await dbService.saveCycle(cycleKey, updatedCycle, 'checking', cashflowId);

      // 3. Retrieve and Verify
      final retrieved = await dbService.getCycle(cycleKey);
      expect(
        retrieved!.transactions.first.tags,
        containsAll(['Tag B', 'Tag A']),
      );
      print('DEBUG: Update persisted successfully.');
    });
  });
}
