import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:budgetizer_dart/budgetizer_dart.dart';
import 'package:budgetizer_dart/src/services/database_service.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    // Create temp .env file with absolute path
    final dir = Directory.systemTemp.createTempSync('budgetizer_test_env_');
    final envFile = File('${dir.path}/.env.test');
    envFile.writeAsStringSync('''
PLAID_CLIENT_ID=mock_client
PLAID_SECRET=mock_secret
''');

    await dotenv.load(fileName: envFile.path);

    // Note: We can't easily clean up dotenv's internal state, but we can delete the file
    // Ideally we'd unset it, but for tests it's fine.
  });

  group('PlaidBankService Persistence Integration', () {
    late PlaidBankService service;
    late DatabaseService dbService;
    final testDir = Directory.systemTemp.createTempSync('budgetizer_svc_test_');

    setUp(() async {
      dbService = DatabaseService();
      await dbService.init(databaseFactoryFfi, testDir.path);

      // Inject loader if needed, or rely on internal logic
      service = PlaidBankService(clientId: 'test', secret: 'test');
    });

    tearDown(() async {
      await dbService.deleteDb();
    });

    tearDownAll(() {
      if (testDir.existsSync()) {
        testDir.deleteSync(recursive: true);
      }
    });

    test('updateTransaction should persist to DatabaseService', () async {
      final tx = BankTransaction(
        id: 'tx_update_1',
        date: DateTime.now(),
        amount: -25.0,
        description: 'Update Test',
        vendorName: 'Original Vendor',
        tags: ['OriginalTag'],
        pending: false,
        cashflowId: 'checking_1',
      );

      print('DEBUG: Calling updateTransaction...');
      await service.updateTransaction(tx);

      print('DEBUG: Verifying persistence in DB...');
      final cycle = await dbService.getCycle('manual_imports');
      expect(cycle, isNotNull, reason: 'Manual imports cycle should exist');

      final dbTx = cycle!.transactions.firstWhere((t) => t.id == 'tx_update_1');
      expect(dbTx.amount, -25.0);
      print('DEBUG: Persistence verified.');
    });

    test('fetchTransactions should prioritize local DB override', () async {
      final txId = 'tx_override_1';
      final cashflowId = 'checking_test';

      // 1. Simulate a transaction that would come from Plaid (we can't easily mock the private _client.getTransactions without interception,
      //    but we can test the merge logic if we can insert into the "fetched" list behavior.
      //    However, fetchTransactions calls PLaid.
      //    Since we can't mock the HTTP call easily here without mocking PlaidClient, we will focus on
      //    checking if the Manual Import IS returned. Even if Plaid returns nothing, the Manual Import should appear.

      final localTx = BankTransaction(
        id: txId,
        date: DateTime.now(),
        amount: -25.0,
        description: 'Local Override',
        vendorName: 'Local Vendor',
        tags: ['LocalTag'],
        pending: false,
        cashflowId: cashflowId,
      );

      print('DEBUG: Saving local override...');
      await service.updateTransaction(localTx);

      print('DEBUG: Fetching transactions...');
      // Note: This will likely fail to fetch from Plaid (giving empty list or error),
      // but it SHOULD proceed to load from DB.
      final results = await service.fetchTransactions(cashflowId);

      print('DEBUG: Fetched ${results.length} transactions.');
      final fetchedTx = results.firstWhere((t) => t.id == txId);

      expect(fetchedTx.description, 'Local Override');
      expect(fetchedTx.tags, contains('LocalTag'));
      print('DEBUG: Fetch priority verified.');
    });
  });
}
