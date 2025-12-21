import 'dart:convert';
import 'package:flutter/services.dart';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:plaid_dart/plaid_dart.dart';

part 'bank_service.g.dart';

class Tag {
  final String name;
  final double? budgetLimit;
  final int? frequency; // 0 = Monthly, X = Every X Days
  final String? regex;

  Tag({required this.name, this.budgetLimit, this.frequency, this.regex});

  Tag copyWith({
    String? name,
    double? budgetLimit,
    int? frequency,
    String? regex,
  }) {
    return Tag(
      name: name ?? this.name,
      budgetLimit: budgetLimit ?? this.budgetLimit,
      frequency: frequency ?? this.frequency,
      regex: regex ?? this.regex,
    );
  }
}

class BankTransaction {
  final String id;
  final DateTime date;
  final String description; // Original description from bank
  final String vendorName; // Extracted Vendor Name (e.g. Target)
  final double amount;
  final List<String> tags; // Current active tags
  final List<String> removedTags; // Tags removed by user
  final bool pending;
  final bool isInitialized;
  final String cashflowId; // Link to specific account

  BankTransaction({
    required this.id,
    required this.date,
    required this.description,
    required this.vendorName,
    required this.amount,
    required this.tags,
    this.removedTags = const [],
    required this.pending,
    this.isInitialized = true,
    required this.cashflowId,
  });

  factory BankTransaction.fromJson(Map<String, dynamic> json) {
    return BankTransaction(
      id: json['transaction_id'],
      date: DateTime.parse(json['date']),
      description: json['name'] ?? 'Unknown',
      vendorName:
          json['merchant_name'] ??
          json['name'] ??
          'Unknown', // Plaid uses merchant_name
      amount: (json['amount'] as num).toDouble(),
      tags: List<String>.from(json['category'] ?? []),
      pending: json['pending'] ?? false,
      isInitialized: true,
      cashflowId: 'checking_1', // Default, will be overwritten by service
    );
  }

  BankTransaction copyWith({
    bool? isInitialized,
    String? vendorName,
    List<String>? tags,
    List<String>? removedTags,
    String? cashflowId,
  }) {
    return BankTransaction(
      id: id,
      date: date,
      description: description,
      vendorName: vendorName ?? this.vendorName,
      amount: amount,
      tags: tags ?? this.tags,
      removedTags: removedTags ?? this.removedTags,
      pending: pending,
      isInitialized: isInitialized ?? this.isInitialized,
      cashflowId: cashflowId ?? this.cashflowId,
    );
  }
}

class Cashflow {
  final String id;
  final String name;
  final String type; // Checking, Savings, Credit Card
  final double balance;

  Cashflow({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
  });
}

class DataSource {
  final String id;
  final String name;
  final String type; // 'plaid', 'manual'
  final String? accessToken; // Stored securely
  final String? itemId;

  DataSource({
    required this.id,
    required this.name,
    required this.type,
    this.accessToken,
    this.itemId,
  });
}

abstract class BankService {
  Future<List<Cashflow>> fetchCashflows();
  Future<List<BankTransaction>> fetchTransactions(String cashflowId);
  Future<void> updateTransaction(BankTransaction transaction);
  Future<List<Tag>> fetchTags();
  Future<void> updateTag(Tag tag);
  Future<Map<String, dynamic>> analyzeTransaction(String description);

  // Plaid specific
  Future<String> createLinkToken();
  Future<void> exchangePublicToken(String publicToken);
  bool get isConnected;
}

class PlaidBankService implements BankService {
  final PlaidClient _client;

  DataSource? _connectedSource;
  final List<Tag> _tags = [];

  PlaidBankService({
    required String clientId,
    required String secret,
    String environment = 'sandbox',
  }) : _client = PlaidClient(
         clientId: clientId,
         secret: secret,
         environment: environment,
       );

  @override
  bool get isConnected => _connectedSource?.accessToken != null;

  @override
  Future<String> createLinkToken() async {
    return _client.createLinkToken(userId: 'user_123'); // Fixed user ID for now
  }

  @override
  Future<void> exchangePublicToken(String publicToken) async {
    final accessToken = await _client.exchangePublicToken(publicToken);

    // In a real app, we would fetch Item details to get the ID.
    // For now, we'll generate a placeholder ID or assume it works.
    // Ideally PlaidClient also exposes /item/get.
    // For this simple demo:
    _connectedSource = DataSource(
      id: 'plaid_item_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Plaid Bank',
      type: 'plaid',
      accessToken: accessToken,
      itemId: 'unknown_item_id',
    );
  }

  @override
  Future<List<Cashflow>> fetchCashflows() async {
    if (_connectedSource?.accessToken == null) return [];

    // START TODO: Add accounts/get to PlaidClient
    // For now, returning empty list as PlaidClient doesn't support accounts/get yet
    // This is valid as per the current scope of fixing step 1 transaction list.
    return [];
    // END TODO
  }

  @override
  Future<List<BankTransaction>> fetchTransactions(String cashflowId) async {
    if (_connectedSource?.accessToken == null) return [];

    // For sandbox/demo, we'll just fetch the last 30 days
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 30));

    // Plaid requires YYYY-MM-DD
    String formatDate(DateTime d) =>
        "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

    final response = await _client.getTransactions(
      _connectedSource!.accessToken!,
      startDate: formatDate(startDate),
      endDate: formatDate(now),
    );

    final transactions = response['transactions'] as List;

    final result = transactions
        .map<BankTransaction>((tx) {
          return BankTransaction.fromJson(
            tx,
          ).copyWith(cashflowId: tx['account_id']);
        })
        .where((t) => cashflowId == 'ALL' || t.cashflowId == cashflowId)
        .toList();

    return result;
  }

  @override
  Future<void> updateTransaction(BankTransaction transaction) async {
    // No-op for now
  }

  @override
  Future<List<Tag>> fetchTags() async {
    if (_tags.isEmpty) {
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
    // Reuse the simple logic from Mock implementation for now
    final upper = description.toUpperCase();
    if (upper.contains('TARGET')) {
      return {
        'vendor': 'Target',
        'tags': ['Target', 'Groceries', 'Home Goods', 'Clothing'],
      };
    }
    return {
      'vendor': description,
      'tags': ['Uncategorized'],
    };
  }
}

class MockBankService implements BankService {
  // In-Memory Storage
  final List<Cashflow> _cashflows = [
    Cashflow(
      id: 'checking_1',
      name: 'Chase Checking',
      type: 'Checking',
      balance: 4520.50,
    ),
    Cashflow(
      id: 'savings_1',
      name: 'Chase Savings',
      type: 'Savings',
      balance: 12000.00,
    ),
    Cashflow(
      id: 'visa_1',
      name: 'Chase Sapphire',
      type: 'Credit Card',
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
  Future<List<Cashflow>> fetchCashflows() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _cashflows;
  }

  @override
  Future<List<BankTransaction>> fetchTransactions(String cashflowId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (_isFirstLoad) {
      await _initializeMockData();
      _isFirstLoad = false;
    }

    return _transactionsByAccount[cashflowId] ?? [];
  }

  Future<void> _initializeMockData() async {
    // Load checking from file if exists, or generate basic ones
    try {
      final String response = await rootBundle.loadString(
        'assets/data/mock_transactions.json',
      );
      final List<dynamic> data = json.decode(response);

      // Assign legacy mock data to checking
      _transactionsByAccount['checking_1'] = data.map((json) {
        final tx = BankTransaction.fromJson(json);
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
      _transactionsByAccount['checking_1'] = [];
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
  // Check env vars to decide which service to use
  // This is a simple toggle. In real app, might be dynamic configuration.
  final clientId = dotenv.env['PLAID_CLIENT_ID'];
  final secret = dotenv.env['PLAID_SECRET'];

  if (clientId != null &&
      clientId.isNotEmpty &&
      secret != null &&
      secret.isNotEmpty) {
    return PlaidBankService(clientId: clientId, secret: secret);
  }

  return MockBankService();
}
