import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bank_service.g.dart';

class Tag {
  final String name;
  final double? budgetLimit;
  final String? frequency; // 'weekly', 'monthly'

  Tag({required this.name, this.budgetLimit, this.frequency});

  Tag copyWith({String? name, double? budgetLimit, String? frequency}) {
    return Tag(
      name: name ?? this.name,
      budgetLimit: budgetLimit ?? this.budgetLimit,
      frequency: frequency ?? this.frequency,
    );
  }
}

class BankTransaction {
  final String id;
  final DateTime date;
  final String name;
  final double amount;
  final List<String> tags; // Renamed from category
  final bool pending;

  final bool isInitialized;
  final TransactionType? type;
  // budgetLimit removed - now lives on Tag

  BankTransaction({
    required this.id,
    required this.date,
    required this.name,
    required this.amount,
    required this.tags,
    required this.pending,
    this.isInitialized = true,
    this.type,
  });

  factory BankTransaction.fromJson(Map<String, dynamic> json) {
    return BankTransaction(
      id: json['transaction_id'],
      date: DateTime.parse(json['date']),
      name: json['name'],
      amount: (json['amount'] as num).toDouble(),
      tags: List<String>.from(
        json['category'] ?? [],
      ), // Map legacy category to tags
      pending: json['pending'],
      isInitialized: true,
    );
  }

  BankTransaction copyWith({
    bool? isInitialized,
    TransactionType? type,
    String? name,
    List<String>? tags,
  }) {
    return BankTransaction(
      id: id,
      date: date,
      name: name ?? this.name,
      amount: amount,
      tags: tags ?? this.tags,
      pending: pending,
      isInitialized: isInitialized ?? this.isInitialized,
      type: type ?? this.type,
    );
  }
}

enum TransactionType { fixed, variable, income, transfer }

abstract class BankService {
  Future<List<BankTransaction>> fetchTransactions();
  Future<void> updateTransaction(BankTransaction transaction);
  Future<List<Tag>> fetchTags();
  Future<void> updateTag(Tag tag);
}

class MockBankService implements BankService {
  List<BankTransaction> _currentTransactions = [];
  final List<Tag> _tags = []; // In-memory tag storage for mock
  bool _isFirstLoad = true;

  @override
  Future<List<BankTransaction>> fetchTransactions() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500)); // Faster for dev

    if (_isFirstLoad) {
      final String response = await rootBundle.loadString(
        'assets/data/mock_transactions.json',
      );
      final List<dynamic> data = json.decode(response);
      _currentTransactions = data
          .map((json) => BankTransaction.fromJson(json))
          .toList();
      _isFirstLoad = false;
    } else {
      // Append 2-3 new random transactions
      _currentTransactions.insertAll(0, _generateRandomTransactions());
    }

    return _currentTransactions;
  }

  @override
  Future<void> updateTransaction(BankTransaction transaction) async {
    final index = _currentTransactions.indexWhere(
      (t) => t.id == transaction.id,
    );
    if (index != -1) {
      _currentTransactions[index] = transaction;
    }
  }

  @override
  Future<List<Tag>> fetchTags() async {
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

  List<BankTransaction> _generateRandomTransactions() {
    // Basic randomizer for V1 testing
    final now = DateTime.now();
    return [
      BankTransaction(
        id: 'new_${now.millisecondsSinceEpoch}_1',
        date: now,
        name: 'UBER RIDE',
        amount: -24.50,
        tags: [],
        pending: false,
        isInitialized: false,
      ),
      BankTransaction(
        id: 'new_${now.millisecondsSinceEpoch}_2',
        date: now,
        name: 'WHOLE FOODS',
        amount: -102.30,
        tags: [],
        pending: true,
        isInitialized: false,
      ),
    ];
  }
}

@riverpod
BankService bankService(Ref ref) {
  // Switch to RealBankService later
  return MockBankService();
}
