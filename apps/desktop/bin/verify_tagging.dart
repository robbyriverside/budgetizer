import 'package:budgetizer/core/services/tag_engine.dart';
import 'package:budgetizer/core/models/financial_entities.dart';

void main() {
  print('Running Tagging Verification...');

  // 1. Setup Data
  final baseTags = [
    Tag(name: 'Groceries', type: 'Market'),
    Tag(name: 'Dining', type: 'Service'),
    Tag(name: 'Target', type: 'Vendor', regex: 'TARGET'),
    Tag(name: 'Uber', type: 'Vendor', regex: 'UBER'),
  ];

  final engine = TagEngine(baseTags);

  // 2. Test Account Tags Overlay
  print('\n-- Testing Account Tags Overlay --');
  final accountTagsJson =
      '{"tags": [{"name": "MyCafe", "type": "Vendor", "regex": "MYCAFE", "related": ["Dining"]}]}';
  engine.loadAccountTags(accountTagsJson);

  if (engine.accountTags.length == 1 &&
      engine.accountTags.first.name == 'MyCafe') {
    print('SUCCESS: Account tags loaded.');
  } else {
    print('FAILURE: Account tags not loaded correctly.');
  }

  // 3. Test Prediction Logic
  print('\n-- Testing Prediction Logic --');

  // Create History: Cycle 1 Transaction where user removed 'Clothing'
  final historyTx = BankTransaction(
    id: 'tx1',
    date: DateTime.now().subtract(const Duration(days: 30)),
    description: 'TARGET STORE',
    vendorName: 'Target',
    amount: -50.0,
    tags: ['Target', 'Groceries'], // Only these remaining
    removedTags: ['Clothing'], // User removed this
    pending: false,
    cashflowId: 'checking',
  );

  // Create Current: Cycle 2 Transaction (Fresh from Bank/TagEngine)
  final currentTx = BankTransaction(
    id: 'tx2',
    date: DateTime.now(),
    description: 'TARGET STORE',
    vendorName: 'Target',
    amount: -60.0,
    tags: [
      'Target',
      'Groceries',
      'Clothing',
    ], // TagEngine applies these default
    pending: false,
    cashflowId: 'checking',
  );

  final suggestions = engine.predictRemovedTags(currentTx, [historyTx]);

  print('Current Tags: ${currentTx.tags}');
  print('History Removed: ${historyTx.removedTags}');
  print('Predicted Suggestions: $suggestions');

  if (suggestions.contains('Clothing')) {
    print('SUCCESS: Correctly predicted removal of "Clothing".');
  } else {
    print('FAILURE: Did not predict removal of "Clothing".');
  }

  // 4. Test partial match (by value description if vendor unknown)
  final historyTx2 = BankTransaction(
    id: 'tx3',
    date: DateTime.now(),
    description: 'UNKNOWN VENDOR',
    vendorName: 'Unknown',
    amount: -10,
    tags: [],
    removedTags: ['Spam'],
    pending: false,
    cashflowId: 'checking',
  );
  final currentTx2 = BankTransaction(
    id: 'tx4',
    date: DateTime.now(),
    description: 'UNKNOWN VENDOR',
    vendorName: 'Unknown',
    amount: -10,
    tags: ['Spam'],
    pending: false,
    cashflowId: 'checking',
  );

  final suggestions2 = engine.predictRemovedTags(currentTx2, [
    historyTx,
    historyTx2,
  ]);
  if (suggestions2.contains('Spam')) {
    print('SUCCESS: Correctly predicted removal based on description match.');
  } else {
    print('FAILURE: Did not predict removal based on description match.');
  }
}
