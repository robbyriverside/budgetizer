import 'package:plaid_dart/plaid_dart.dart';
import '../models/financial_entities.dart';
import 'tag_engine.dart';
import 'ai_service.dart';

export '../models/financial_entities.dart';
export 'tag_engine.dart';
export 'ai_service.dart';

typedef ResourceLoader = Future<String> Function(String path);

abstract class BankService {
  Future<List<CashflowSeries>> fetchCashflows();
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
  final ResourceLoader? resourceLoader;

  DataSource? _connectedSource;
  TagEngine? _tagEngine;
  final AIService? _aiService;
  bool _tagsLoaded = false;

  PlaidBankService({
    required String clientId,
    required String secret,
    String environment = 'sandbox',
    String? accessToken,
    TagEngine? tagEngine,
    AIService? aiService,
    this.resourceLoader,
  }) : _client = PlaidClient(
         clientId: clientId,
         secret: secret,
         environment: environment,
       ),
       _tagEngine = tagEngine,
       _aiService = aiService {
    if (_tagEngine != null) {
      _tagsLoaded = true;
    }
    if (accessToken != null) {
      _connectedSource = DataSource(
        id: 'plaid_item_imported',
        name: 'Imported Account',
        type: 'plaid',
        accessToken: accessToken,
        itemId: 'unknown',
      );
    }
  }

  Future<void> _ensureTagsLoaded() async {
    if (_tagsLoaded) return;
    try {
      if (resourceLoader != null) {
        // Load Base Tags
        final jsonStr = await resourceLoader!('assets/data/db_tags.json');
        _tagEngine = TagEngine.fromJson(jsonStr);

        // Load Account Tags (Mocked path for now, would be local storage/file)
        try {
          // In a real app we'd use path_provider to get app documents directory
          // For now, we'll try to load from a known asset or ignore if not found
          // final accountTagsStr = await resourceLoader!('assets/data/account_tags.json');
          // _tagEngine!.loadAccountTags(accountTagsStr);
        } catch (_) {
          // No account tags yet
        }

        _tagsLoaded = true;
      }
    } catch (e) {
      print('Error loading db_tags.json: $e');
      // Fallback or rethrow
    }
  }

  // Allow setting locally for CLI usage if needed
  void setTagEngine(TagEngine engine) {
    _tagEngine = engine;
    _tagsLoaded = true;
  }

  // Persistence Mock - In reality would write to file system
  Future<void> _saveAccountTags() async {
    if (_tagEngine != null) {
      // final tags = _tagEngine!.accountTags;
      // final jsonStr = jsonEncode({
      //   'tags': tags.map((t) => t.toJson()).toList(),
      // });
      // print('Saving account_tags.json: $jsonStr');
      // await File('assets/data/account_tags.json').writeAsString(jsonStr);
    }
  }

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
      name: 'Chase Bank', // Sandbox default for testing context
      type: 'plaid',
      accessToken: accessToken,
      itemId: 'unknown_item_id',
    );
  }

  /// Helper for CLI to auto-connect in Sandbox
  Future<String> authenticateSandbox() async {
    final publicToken = await _client.createSandboxPublicToken();
    final accessToken = await _client.exchangePublicToken(publicToken);

    _connectedSource = DataSource(
      id: 'plaid_item_sandbox',
      name: 'Sandbox Bank',
      type: 'plaid',
      accessToken: accessToken,
      itemId: 'sandbox_item',
    );
    return accessToken;
  }

  @override
  Future<List<CashflowSeries>> fetchCashflows() async {
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

    await _ensureTagsLoaded();

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

    final transactions = response['transactions'] as List<dynamic>;

    // Need to handle async mapping to await AI service
    final result = <BankTransaction>[];

    // Mock History for Prediction Logic (In real app, fetch from DB)
    final historyTransactions = <BankTransaction>[];

    for (var tx in transactions) {
      // Convert to object
      var transaction = BankTransaction.fromJson(
        tx as Map<String, dynamic>,
      ).copyWith(cashflowId: tx['account_id'] as String?);

      // Apply intelligent tagging (Regex first)
      if (_tagEngine != null) {
        transaction = _tagEngine!.applyTags(transaction);

        // Predict Removed Tags
        final suggested = _tagEngine!.predictRemovedTags(
          transaction,
          historyTransactions,
        );
        transaction = transaction.copyWith(suggestedRemovedTags: suggested);
      }

      // AI Fallback for Unknown Transactions (No Vendor identified)
      // We assume if Vendor matches description, it wasn't really identified by TagEngine
      // TagEngine.applyTags updates vendorName if it finds a 'Vendor' type tag.
      bool isUnknown =
          transaction.vendorName == transaction.description ||
          transaction.tags.isEmpty ||
          transaction.tags.contains('Uncategorized');

      if (isUnknown && _aiService != null) {
        try {
          // Pass connected source name (e.g. "Chase Bank") as context
          final analysis = await _aiService.analyzeTransaction(
            transaction.description,
            context: _connectedSource?.name,
          );

          // Ensure Vendor is the first tag
          final tags = List<String>.from(analysis.tags);
          if (analysis.vendorName.isNotEmpty &&
              !tags.contains(analysis.vendorName)) {
            tags.insert(0, analysis.vendorName);
          } else if (tags.contains(analysis.vendorName) &&
              tags.indexOf(analysis.vendorName) != 0) {
            tags.remove(analysis.vendorName);
            tags.insert(0, analysis.vendorName);
          }

          final suggested =
              _tagEngine?.predictRemovedTags(
                transaction,
                historyTransactions,
              ) ??
              [];

          // Update Transaction
          transaction = transaction.copyWith(
            vendorName: analysis.vendorName,
            tags: tags,
            suggestedRemovedTags: suggested,
            isInitialized: true, // Now initialized
          );

          // Add Income/Transfer tags if type dictates
          if (analysis.type == 'Income') {
            final currentTags = List<String>.from(transaction.tags);
            if (!currentTags.contains('Income')) currentTags.add('Income');
            transaction = transaction.copyWith(tags: currentTags);
          } else if (analysis.type == 'Transfer') {
            final currentTags = List<String>.from(transaction.tags);
            if (!currentTags.contains('Transfer')) currentTags.add('Transfer');
            transaction = transaction.copyWith(tags: currentTags);
          }

          // Learn the new tag
          if (analysis.suggestedRegex.isNotEmpty && _tagEngine != null) {
            // Create a new Tag object
            final newTag = Tag(
              name: analysis.vendorName,
              type: 'Vendor', // Assuming Vendor for now
              description: 'Learned from AI: ${analysis.vendorName}',
              regex: analysis.suggestedRegex,
              related: analysis.tags
                  .where((t) => t != analysis.vendorName)
                  .toList(),
            );
            _tagEngine!.learnTag(newTag);
            await _saveAccountTags(); // Persist changes
          }
        } catch (e) {
          print('AI Analysis failed for ${transaction.description}: $e');
        }
      }

      if (cashflowId == 'ALL' || transaction.cashflowId == cashflowId) {
        result.add(transaction);
      }
    }

    return result;
  }

  @override
  Future<void> updateTransaction(BankTransaction transaction) async {
    // No-op for now
  }

  @override
  Future<List<Tag>> fetchTags() async {
    await _ensureTagsLoaded();
    return _tagEngine?.tags ?? <Tag>[];
  }

  @override
  Future<void> updateTag(Tag tag) async {
    // TagEngine is currently read-only. In a real implementation, we would update the tags source.
    print('Updating tag not implemented for PlaidBankService with TagEngine');
  }

  @override
  Future<Map<String, dynamic>> analyzeTransaction(String description) async {
    await _ensureTagsLoaded();
    if (_tagEngine != null) {
      return _tagEngine!.analyzeDescription(description);
    }
    return {
      'vendor': description,
      'tags': ['Uncategorized'],
    };
  }
}
