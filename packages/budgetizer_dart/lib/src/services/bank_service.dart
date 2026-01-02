import 'dart:convert';
import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'database_service.dart';
import 'financial_service.dart';
export 'financial_service.dart';

part 'bank_service.g.dart';

class MockBankService implements BankService {
  final ResourceLoader? resourceLoader;
  final bool enableDefaultMockData;

  MockBankService({
    this.resourceLoader,
    this.enableDefaultMockData = true,
  });

  // In-Memory Storage
  final List<CashflowSeries> _cashflows = [
    CashflowSeries(
      id: 'checking_1',
      name: 'Chase Checking',
      type: CashflowType.checking,
      balance: 4520.50,
    ),
    CashflowSeries(
      id: 'savings_1',
      name: 'Chase Savings',
      type: CashflowType.savings,
      balance: 12000.00,
    ),
    CashflowSeries(
      id: 'visa_1',
      name: 'Chase Sapphire',
      type: CashflowType.creditCard,
      balance: -840.20,
    ),
  ];

  final Map<String, List<BankTransaction>> _transactionsByAccount = {};
  final List<Tag> _tags = [];
  bool _isFirstLoad = true;

  @override
  bool get isConnected => false;

  @override
  Future<String> createLinkToken() async => "mock-link-token";
  @override
  Future<void> exchangePublicToken(String publicToken) async {}

  @override
  Future<List<CashflowSeries>> fetchCashflows() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    // In a real scenario, we might iterate known cashflow IDs or store a list of series in DB.
    // For now, we'll return our fixed list, but we might want to update their balances
    // based on what's in the DB?
    // For simplicity, we just return the static list structure,
    // but fetchTransactions will handle the actual data.
    return _cashflows;
  }

  @override
  Future<List<BankTransaction>> fetchTransactions(String cashflowId) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    // 1. Try to load from DB first
    try {
      final db = DatabaseService();
      // We only use DB if it's initialized.
      if (db.db != null) {
        final cycles = await db.getCyclesForCashflow(cashflowId);
        if (cycles.isNotEmpty) {
          final allTxs = cycles.expand((c) => c.transactions).toList();

          // Update in-memory cache
          _transactionsByAccount[cashflowId] = allTxs;
          _isFirstLoad = false;
          return allTxs;
        }
      }
    } catch (e) {}

    // 2. Fallback to default mock data if DB was empty
    if (_isFirstLoad) {
      await _initializeMockData();
      _isFirstLoad = false;

      // OPTIONAL: Persist this default data to DB so it sticks?
      // Let's do it to ensure consistency.
      final txs = _transactionsByAccount[cashflowId];
      if (txs != null && txs.isNotEmpty) {
        await importTransactions(txs);
      }
    }

    final txs = List<BankTransaction>.from(
        _transactionsByAccount[cashflowId] ?? <BankTransaction>[]);

    return txs;
  }

  Future<void> _initializeMockData() async {
    if (!enableDefaultMockData) return;

    // Load checking from file if exists, or generate basic ones
    if (resourceLoader != null) {
      try {
        final String response = await resourceLoader!(
          'assets/data/mock_transactions.json',
        );
        final List<dynamic> data = json.decode(response) as List<dynamic>;

        // Assign legacy mock data to checking
        _transactionsByAccount['checking_1'] = data.map((json) {
          final tx = BankTransaction.fromJson(json as Map<String, dynamic>);
          // Enrich specific ones for demo
          if (tx.description.contains('TARGET')) {
            return tx.copyWith(
              vendorName: 'Target',
              tags: ['Target', 'Groceries', 'Home Goods', 'Clothing'],
            );
          }
          return tx;
        }).toList();
      } catch (e) {
        _transactionsByAccount['checking_1'] = <BankTransaction>[];
      }
    } else {
      // Default Regression Data for Checking
      _transactionsByAccount['checking_1'] = [
        _createTx('checking_1', 'Starbucks', -5.40, ['Coffee', 'Dining']),
        _createTx('checking_1', 'Target', -45.22, ['Groceries', 'Home']),
        _createTx('checking_1', 'Chevron', -50.00, ['Gas', 'Auto']),
        _createTx('checking_1', 'Paycheck', 2500.00, ['Income']),
        _createTx('checking_1', 'Netflix', -15.99, ['Subscription']),
      ];
    }

    // Generate Savings Data
    _transactionsByAccount['savings_1'] = [
      _createTx('savings_1', 'Transfer from Checking', 500.0, [
        'Transfer',
        'Savings',
      ]),
      _createTx('savings_1', 'Interest Payment', 12.50, ['Interest', 'Income']),
    ];

    // Generate detailed Credit Card Data
    _transactionsByAccount['visa_1'] = [
      _createTx('visa_1', 'UBER RIDE', -24.50, ['Uber', 'Transport']),
      _createTx('visa_1', 'NETFLIX', -15.99, [
        'Netflix',
        'Subscription',
        'Streaming',
        'Movies',
      ]),
      _createTx('visa_1', 'TARGET', -84.22, [
        'Target',
        'Groceries',
        'Home Goods',
        'Clothing',
      ]),
      _createTx('visa_1', 'SHELL STATION', -45.00, ['Shell', 'Gas', 'Auto']),
    ];
  }

  BankTransaction _createTx(
    String accountId,
    String desc,
    double amount,
    List<String> tags,
  ) {
    return BankTransaction(
      id: '${accountId}_${DateTime.now().millisecondsSinceEpoch}_${(amount * 100).toInt()}',
      date: DateTime.now().subtract(
        Duration(days: (amount % 30).toInt().abs()),
      ),
      description: desc,
      vendorName: desc, // Simple default
      amount: amount,
      tags: tags,
      pending: false,
      cashflowId: accountId,
    );
  }

  @override
  Future<void> updateTransaction(BankTransaction transaction) async {
    final list = _transactionsByAccount[transaction.cashflowId];
    if (list != null) {
      final index = list.indexWhere((t) => t.id == transaction.id);
      if (index != -1) {
        list[index] = transaction;
        // Persist update
        await importTransactions([transaction]);
      } else {}
    } else {}
  }

  @override
  Future<void> importTransactions(List<BankTransaction> transactions) async {
    _isFirstLoad = false;

    // 1. Update In-Memory Map
    for (var tx in transactions) {
      final acct = tx.cashflowId;
      if (!_transactionsByAccount.containsKey(acct)) {
        _transactionsByAccount[acct] = [];
      }
      // Check for dupe by ID
      final existingIndex =
          _transactionsByAccount[acct]!.indexWhere((t) => t.id == tx.id);
      if (existingIndex != -1) {
        _transactionsByAccount[acct]![existingIndex] = tx;
      } else {
        _transactionsByAccount[acct]!.add(tx);
      }
    }

    // 2. Persist to Database (Group by Account & Cycle)
    try {
      final db = DatabaseService();
      if (db.db == null) {
        return;
      }

      // Group by Cashflow Key
      final Map<String, List<BankTransaction>> byCashflow = {};
      for (var tx in transactions) {
        byCashflow.putIfAbsent(tx.cashflowId, () => []).add(tx);
      }

      for (var cashflowId in byCashflow.keys) {
        final txs = byCashflow[cashflowId]!;

        // Group by Month (Cycle)
        // Key: "YYYY-MM"
        final Map<String, List<BankTransaction>> byMonth = {};
        for (var tx in txs) {
          final key =
              "${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}";
          byMonth.putIfAbsent(key, () => []).add(tx);
        }

        for (var monthKey in byMonth.keys) {
          final newTxs = byMonth[monthKey]!;
          final parts = monthKey.split('-');
          final year = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final cycleStart = DateTime(year, month, 1);

          final cycleKey = "${cashflowId}_${monthKey}";

          // Load existing cycle to merge
          Cashflow? existingCycle = await db.getCycle(cycleKey);

          List<BankTransaction> mergedTxs = [];
          if (existingCycle != null) {
            mergedTxs = List.from(existingCycle.transactions);
          }

          // Merge newTxs into mergedTxs
          for (var tx in newTxs) {
            final idx = mergedTxs.indexWhere((t) => t.id == tx.id);
            if (idx != -1) {
              mergedTxs[idx] = tx; // Update
            } else {
              mergedTxs.add(tx); // Insert
            }
          }

          // Create updated Cycle object
          final updatedCycle = Cashflow(
            id: cycleKey, // Use key as ID for simplicity
            seriesId: cashflowId,
            cycle: Cycle(startDate: cycleStart),
            transactions: mergedTxs,
            // We aren't calculating balances here properly yet, but that's fine for now
            openingBalance: existingCycle?.openingBalance ?? 0.0,
            closingBalance: existingCycle?.closingBalance ?? 0.0,
          );

          // Save
          await db.saveCycle(cycleKey, updatedCycle, 'checking',
              cashflowId); // Type hardcoded for now or derived?
        }
      }
    } catch (e) {}
  }

  @override
  Future<List<Tag>> fetchTags() async {
    if (_tags.isEmpty) {
      // Basic initial tags
      _tags.addAll([
        Tag(name: 'Groceries', budgetLimit: 400, frequency: 7),
        Tag(name: 'Dining', budgetLimit: 200, frequency: 0),
        Tag(name: 'Gas'),
        Tag(name: 'Clothing'),
      ]);
    }
    return _tags;
  }

  @override
  Future<void> updateTag(Tag tag) async {
    final index = _tags.indexWhere((t) => t.name == tag.name);
    if (index != -1) {
      _tags[index] = tag;
    } else {
      _tags.add(tag);
    }
  }

  @override
  Future<Map<String, dynamic>> analyzeTransaction(String description) async {
    return {
      'vendor': description,
      'tags': ['Uncategorized'],
    };
  }
}

@riverpod
BankService bankService(Ref ref) {
  // Use Platform.environment for pure Dart env vars
  final clientId = Platform.environment['PLAID_CLIENT_ID'];
  final secret = Platform.environment['PLAID_SECRET'];

  // Default loader can be null or file system based depending on usage
  // For CLI, we might want to read from local disk if assets are available
  ResourceLoader? loader;

  if (clientId != null &&
      clientId.isNotEmpty &&
      secret != null &&
      secret.isNotEmpty) {
    return PlaidBankService(
      clientId: clientId,
      secret: secret,
      resourceLoader: loader,
    );
  }

  return MockBankService(resourceLoader: loader);
}
