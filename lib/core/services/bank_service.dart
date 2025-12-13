import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bank_service.g.dart';

class Tag {
  final String name;
  final double? budgetLimit;
  final String? frequency; // 'weekly', 'monthly'
  final String? regex;

  Tag({required this.name, this.budgetLimit, this.frequency, this.regex});

  Tag copyWith({
    String? name,
    double? budgetLimit,
    String? frequency,
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
  final String name;
  final double amount;
  final List<String> tags; // Renamed from category
  final bool pending;

  final bool isInitialized;
  // type removed

  BankTransaction({
    required this.id,
    required this.date,
    required this.name,
    required this.amount,
    required this.tags,
    required this.pending,
    this.isInitialized = true,
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
    );
  }
}

// TransactionType enum removed - Types are now Tags

abstract class BankService {
  Future<List<BankTransaction>> fetchTransactions();
  Future<void> updateTransaction(BankTransaction transaction);
  Future<List<Tag>> fetchTags();
  Future<void> updateTag(Tag tag);
  Future<List<String>> getVendorTags(String vendorTag);
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
    if (_tags.isEmpty) {
      try {
        final String response = await rootBundle.loadString(
          'assets/data/db_tags.json',
        );
        final Map<String, dynamic> data = json.decode(response);
        final List<dynamic> tagList = data['tags'];

        for (var t in tagList) {
          _tags.add(
            Tag(
              name: t['name'],
              // description: t['description'], // Tag model needs desc update if we want it too
              regex: t['regex'],
              // type: t['type'],
            ),
          );
        }
      } catch (e) {
        print("Error loading tags: $e");
      }
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
  Future<List<String>> getVendorTags(String vendorTag) async {
    // Mock AI Logic: Return hardcoded defaults based on Vendor Tag
    // In real app, this queries the AI/Vendor DB
    switch (vendorTag.toUpperCase()) {
      case 'TARGET':
        return ['Target', 'Groceries', 'Home Goods', 'Clothing'];
      case 'SHELL':
        return ['Shell', 'Gas', 'Auto'];
      case 'STARBUCKS':
        return ['Starbucks', 'Dining', 'Coffee'];
      case 'UBER RIDE':
      case 'UBER':
        return ['Uber', 'Transport', 'Services'];
      case 'WHOLE FOODS':
        return ['Whole Foods', 'Groceries', 'Dining'];
      case 'MORTGAGE PAYMENT': // Example of strict mapping
        return ['Mortgage Payment', 'Housing', 'Fixed'];
      default:
        // Fallback: Just the vendor tag and a default 'Uncategorized' if unknown?
        // Or AI matching would happen here.
        return [vendorTag, 'Uncategorized'];
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
        tags: ['UBER RIDE'],
        pending: false,
        isInitialized: false,
      ),
      BankTransaction(
        id: 'new_${now.millisecondsSinceEpoch}_2',
        date: now,
        name: 'WHOLE FOODS',
        amount: -102.30,
        tags: ['WHOLE FOODS'],
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
