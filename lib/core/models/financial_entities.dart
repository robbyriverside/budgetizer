class Tag {
  final String name;
  final String? type; // Vendor, Market, System, Service
  final String? description;
  final double? budgetLimit;
  final int? frequency; // 0 = Monthly, X = Every X Days
  final String? regex;
  final List<String> related;
  final String? mccId;

  Tag({
    required this.name,
    this.type,
    this.description,
    this.budgetLimit,
    this.frequency,
    this.regex,
    this.related = const [],
    this.mccId,
  });

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      name: json['name'],
      type: json['type'],
      description: json['description'],
      // Budget limit and frequency are typically user-defined, not in db_tags.json initially,
      // but we might want to load them if they exist
      budgetLimit: json['budgetLimit']?.toDouble(),
      frequency: json['frequency'],
      regex: json['regex'],
      related: List<String>.from(json['related'] ?? []),
      mccId: json['mcc_id'],
    );
  }

  Tag copyWith({
    String? name,
    String? type,
    String? description,
    double? budgetLimit,
    int? frequency,
    String? regex,
    List<String>? related,
    String? mccId,
  }) {
    return Tag(
      name: name ?? this.name,
      type: type ?? this.type,
      description: description ?? this.description,
      budgetLimit: budgetLimit ?? this.budgetLimit,
      frequency: frequency ?? this.frequency,
      regex: regex ?? this.regex,
      related: related ?? this.related,
      mccId: mccId ?? this.mccId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (type != null) 'type': type,
      if (description != null) 'description': description,
      if (budgetLimit != null) 'budgetLimit': budgetLimit,
      if (frequency != null) 'frequency': frequency,
      if (regex != null) 'regex': regex,
      if (related.isNotEmpty) 'related': related,
      if (mccId != null) 'mcc_id': mccId,
    };
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
    // Handling Plaid JSON format where applicable, or internal format
    return BankTransaction(
      id: json['transaction_id'] ?? json['id'],
      date: DateTime.parse(json['date']),
      description: json['name'] ?? json['description'] ?? 'Unknown',
      vendorName:
          json['merchant_name'] ??
          json['vendorName'] ??
          json['name'] ??
          'Unknown',
      amount: (json['amount'] as num).toDouble(),
      tags: List<String>.from(json['category'] ?? json['tags'] ?? []),
      removedTags: List<String>.from(json['removedTags'] ?? []),
      pending: json['pending'] ?? false,
      isInitialized: json['isInitialized'] ?? true,
      cashflowId: json['account_id'] ?? json['cashflowId'] ?? 'checking_1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String().split('T')[0], // YYYY-MM-DD
      'description': description,
      'vendorName': vendorName,
      'amount': amount,
      'tags': tags,
      'removedTags': removedTags,
      'pending': pending,
      'isInitialized': isInitialized,
      'cashflowId': cashflowId,
    };
  }

  BankTransaction copyWith({
    String? id,
    DateTime? date,
    String? description,
    String? vendorName,
    double? amount,
    List<String>? tags,
    List<String>? removedTags,
    bool? pending,
    bool? isInitialized,
    String? cashflowId,
  }) {
    return BankTransaction(
      id: id ?? this.id,
      date: date ?? this.date,
      description: description ?? this.description,
      vendorName: vendorName ?? this.vendorName,
      amount: amount ?? this.amount,
      tags: tags ?? this.tags,
      removedTags: removedTags ?? this.removedTags,
      pending: pending ?? this.pending,
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
