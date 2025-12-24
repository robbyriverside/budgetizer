import '../models/financial_entities.dart';

/// Implements Step 6: Tag Storage and Indexing
/// Maintains an inverted index for O(1) tag-to-transaction lookup.
class TransactionStore {
  // Primary Data Store
  final Map<String, BankTransaction> _transactionsById = {};

  // Inverted Index: Tag Name -> List of Transaction IDs
  final Map<String, List<String>> _tagIndex = {};

  /// Adds or Updates a transaction and refreshes the index.
  void addTransaction(BankTransaction tx) {
    // 1. If updating, remove old references from index
    if (_transactionsById.containsKey(tx.id)) {
      final oldTx = _transactionsById[tx.id]!;
      for (var tag in oldTx.tags) {
        _tagIndex[tag]?.remove(tx.id);
      }
    }

    // 2. Store Transaction
    _transactionsById[tx.id] = tx;

    // 3. Update Index
    for (var tag in tx.tags) {
      if (!_tagIndex.containsKey(tag)) {
        _tagIndex[tag] = [];
      }
      _tagIndex[tag]!.add(tx.id);
    }
  }

  /// Batch add for convenience
  void addAll(List<BankTransaction> transactions) {
    for (var tx in transactions) {
      addTransaction(tx);
    }
  }

  /// O(1) Lookup for transactions by Tag
  List<BankTransaction> getTransactionsByTag(String tagName) {
    final ids = _tagIndex[tagName];
    if (ids == null || ids.isEmpty) return [];

    return ids.map((id) => _transactionsById[id]!).toList();
  }

  /// Get all transactions
  List<BankTransaction> getAllTransactions() {
    return _transactionsById.values.toList();
  }
}
