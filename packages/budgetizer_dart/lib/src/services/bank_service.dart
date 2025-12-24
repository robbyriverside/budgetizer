import 'dart:convert';
import 'dart:io';

import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'financial_service.dart';
export 'financial_service.dart';

part 'bank_service.g.dart';

class MockBankService implements BankService {
  final ResourceLoader? resourceLoader;

  MockBankService({this.resourceLoader});

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
    return _cashflows;
  }

  @override
  Future<List<BankTransaction>> fetchTransactions(String cashflowId) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    if (_isFirstLoad) {
      await _initializeMockData();
      _isFirstLoad = false;
    }

    return _transactionsByAccount[cashflowId] ?? <BankTransaction>[];
  }

  Future<void> _initializeMockData() async {
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
      }
    }
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
