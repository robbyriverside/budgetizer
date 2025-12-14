import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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
      vendorName: json['vendor_name'] ?? json['name'] ?? 'Unknown',
      amount: (json['amount'] as num).toDouble(),
      tags: List<String>.from(json['category'] ?? []),
      pending: json['pending'],
      isInitialized: true,
      cashflowId: 'checking_1', // Default for legacy data
    );
  }

  BankTransaction copyWith({
    bool? isInitialized,
    String? vendorName,
    List<String>? tags,
    List<String>? removedTags,
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
      cashflowId: cashflowId,
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

abstract class BankService {
  Future<List<Cashflow>> fetchCashflows();
  Future<List<BankTransaction>> fetchTransactions(String cashflowId);
  Future<void> updateTransaction(BankTransaction transaction);
  Future<List<Tag>> fetchTags();
  Future<void> updateTag(Tag tag);
  // Smart Tagging: Returns likely vendor and default tags based on description
  Future<Map<String, dynamic>> analyzeTransaction(String description);
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

  Map<String, List<BankTransaction>> _transactionsByAccount = {};
  final List<Tag> _tags = [];
  bool _isFirstLoad = true;

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
    // "AI" Mock Logic
    final upper = description.toUpperCase();
    if (upper.contains('TARGET')) {
      return {
        'vendor': 'Target',
        'tags': ['Target', 'Groceries', 'Home Goods', 'Clothing'],
      };
    }
    if (upper.contains('NETFLIX')) {
      return {
        'vendor': 'Netflix',
        'tags': ['Netflix', 'Subscription', 'Streaming', 'Movies'],
      };
    }
    if (upper.contains('UBER')) {
      return {
        'vendor': 'Uber',
        'tags': ['Uber', 'Transport'],
      };
    }
    return {
      'vendor': description,
      'tags': ['Uncategorized'],
    };
  }
}

@riverpod
BankService bankService(Ref ref) {
  return MockBankService();
}
