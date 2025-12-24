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
      name: json['name'] as String,
      type: json['type'] as String?,
      description: json['description'] as String?,
      // Budget limit and frequency are typically user-defined, not in db_tags.json initially,
      // but we might want to load them if they exist
      budgetLimit: (json['budgetLimit'] as num?)?.toDouble(),
      frequency: json['frequency'] as int?,
      regex: json['regex'] as String?,
      related: List<String>.from(
          ((json['related'] ?? <dynamic>[]) as List<dynamic>)
              .map((dynamic e) => e as String)),
      mccId: json['mcc_id'] as String?,
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
  final List<String>
      suggestedRemovedTags; // Tags suggested for removal based on history
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
    this.suggestedRemovedTags = const [],
    required this.pending,
    this.isInitialized = true,
    required this.cashflowId,
  });

  factory BankTransaction.fromJson(Map<String, dynamic> json) {
    // Handling Plaid JSON format where applicable, or internal format
    return BankTransaction(
      id: (json['transaction_id'] ?? json['id']) as String,
      date: DateTime.parse(json['date'] as String),
      description: (json['name'] ?? json['description'] ?? 'Unknown') as String,
      vendorName: (json['merchant_name'] ??
          json['vendorName'] ??
          json['name'] ??
          'Unknown') as String,
      amount: (json['amount'] as num).toDouble(),
      tags: List<String>.from(
          (json['category'] ?? json['tags'] ?? <dynamic>[]) as Iterable),
      removedTags:
          List<String>.from((json['removedTags'] ?? <dynamic>[]) as Iterable),
      suggestedRemovedTags: List<String>.from(
        (json['suggestedRemovedTags'] ?? <dynamic>[]) as Iterable,
      ),
      pending: (json['pending'] as bool?) ?? false,
      isInitialized: (json['isInitialized'] as bool?) ?? true,
      cashflowId:
          (json['account_id'] ?? json['cashflowId'] ?? 'checking_1') as String,
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
      'suggestedRemovedTags': suggestedRemovedTags,
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
    List<String>? suggestedRemovedTags,
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
      suggestedRemovedTags: suggestedRemovedTags ?? this.suggestedRemovedTags,
      pending: pending ?? this.pending,
      isInitialized: isInitialized ?? this.isInitialized,
      cashflowId: cashflowId ?? this.cashflowId,
    );
  }
}

enum CashflowType { checking, creditCard, savings }

enum SavingsType { expense, investment }

class Cycle {
  // Definition of a time period, could be fixed (monthly) or relative
  final DateTime startDate;

  Cycle({required this.startDate});

  factory Cycle.fromJson(Map<String, dynamic> json) {
    return Cycle(startDate: DateTime.parse(json['startDate'] as String));
  }

  Map<String, dynamic> toJson() {
    return {'startDate': startDate.toIso8601String()};
  }
}

class Cashflow {
  // A specific time-bound period (e.g., January 2025)
  final String id;
  final String seriesId; // References CashflowSeries.id
  final Cycle cycle;
  final double openingBalance;
  final double closingBalance;
  final List<BankTransaction> transactions;

  Cashflow({
    required this.id,
    required this.seriesId,
    required this.cycle,
    this.openingBalance = 0.0,
    this.closingBalance = 0.0,
    this.transactions = const [],
  });

  factory Cashflow.fromJson(Map<String, dynamic> json) {
    return Cashflow(
      id: json['id'] as String,
      seriesId: (json['seriesId'] as String?) ?? '',
      cycle: Cycle.fromJson(json['cycle'] as Map<String, dynamic>),
      openingBalance: (json['openingBalance'] as num?)?.toDouble() ?? 0.0,
      closingBalance: (json['closingBalance'] as num?)?.toDouble() ?? 0.0,
      transactions: (json['transactions'] as List<dynamic>?)
              ?.map((e) => BankTransaction.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seriesId': seriesId,
      'cycle': cycle.toJson(),
      'openingBalance': openingBalance,
      'closingBalance': closingBalance,
      'transactions': transactions.map((t) => t.toJson()).toList(),
    };
  }
}

class CashflowSeries {
  // The persistent account entity (formerly Cashflow)
  final String id;
  final String name;
  final CashflowType type;
  final double balance; // Current aggregate balance
  final List<Cashflow> history; // Historical cycles

  CashflowSeries({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    this.history = const [],
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
