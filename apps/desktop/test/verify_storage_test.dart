import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:budgetizer_dart/budgetizer_dart.dart';

void main() async {
  print('Running Storage Verification...');

  // Initialize FFI loader
  sqfliteFfiInit();
  final databaseFactory = databaseFactoryFfi;

  final dbService = DatabaseService();

  // 1. Initialize DB with FFI factory
  await dbService.init(databaseFactory, Directory.current.path);

  // Clean state
  // await dbService.deleteDb(); // Optional: reset db for clean test

  print('\n-- Testing Save Cycle --');

  // Create Dummy Data
  final cycleDate = DateTime(2025, 12, 1);
  final cycle = Cycle(startDate: cycleDate);

  final transactions = [
    BankTransaction(
      id: 'tx_store_1',
      date: DateTime(2025, 12, 5),
      description: 'Grocery Store',
      vendorName: 'Kroger',
      amount: -120.50,
      tags: ['Kroger', 'Groceries'],
      pending: false,
      cashflowId: 'checking_1',
    ),
    BankTransaction(
      id: 'tx_store_2',
      date: DateTime(2025, 12, 6),
      description: 'Gas Station',
      vendorName: 'Shell',
      amount: -45.00,
      tags: ['Shell', 'Gas'],
      pending: false,
      cashflowId: 'checking_1',
    ),
  ];

  final cashflowCycle = Cashflow(
    id: 'cycle_2025_12',
    seriesId: 'checking_1',
    cycle: cycle,
    transactions: transactions,
  );

  final key = 'checking_1_2025-12-01';

  // Save
  await dbService.saveCycle(key, cashflowCycle, 'checking', 'checking_1');
  print('Saved cycle with key: $key');

  // 2. Retrieve Cycle
  print('\n-- Testing Retrieve Cycle --');
  final retrieved = await dbService.getCycle(key);

  if (retrieved != null) {
    print('SUCCESS: Cycle retrieved.');
    print('Transaction Count: ${retrieved.transactions.length}');
    if (retrieved.transactions.first.vendorName == 'Kroger') {
      print('SUCCESS: Data integrity verified (Vendor: Kroger).');
    } else {
      print('FAILURE: Data mismatch.');
    }
  } else {
    print('FAILURE: Cycle not found.');
  }

  // 3. Test Query by Cashflow ID
  print('\n-- Testing Query by Cashflow ID --');
  // Add another cycle for same account earlier
  final key2 = 'checking_1_2025-11-01';
  final cycle2 = Cashflow(
    id: 'cycle_2025_11',
    seriesId: 'checking_1',
    cycle: Cycle(startDate: DateTime(2025, 11, 1)),
    transactions: [],
  );
  await dbService.saveCycle(key2, cycle2, 'checking', 'checking_1');

  final list = await dbService.getCyclesForCashflow('checking_1');
  print('Cycles found for checking_1: ${list.length}');

  if (list.length >= 2) {
    // Check sorting (Newest first)
    if (list[0].cycle.startDate.isAfter(list[1].cycle.startDate)) {
      print('SUCCESS: Cycles sorted correctly (Newest first).');
    } else {
      print('FAILURE: Sort order incorrect.');
    }
  } else {
    print('FAILURE: Did not retrieve all cycles.');
  }

  print('\nVerification Complete.');
}
