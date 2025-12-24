import 'dart:io';
import 'package:budgetizer_dart/budgetizer_dart.dart';
import 'package:cli/service_locator.dart';
import 'package:collection/collection.dart';

void main() async {
  print('🧪 Starting AI Determinism Test...');

  try {
    // 1. Setup
    final aiService = getAIService();
    final file = File('southwest_card.pdf');
    if (!await file.exists()) {
      print('❌ Error: southwest_card.pdf not found.');
      exit(1);
    }
    final bytes = await file.readAsBytes();

    // 2. Run 1
    print('🔄 Run 1: Extracting transactions...');
    final results1 = await aiService.extractTransactionsFromPdf(bytes);
    print('   Run 1 found ${results1.length} transactions.');

    // 3. Run 2
    print('🔄 Run 2: Extracting transactions...');
    final results2 = await aiService.extractTransactionsFromPdf(bytes);
    print('   Run 2 found ${results2.length} transactions.');

    // 4. Compare
    print('🔎 Comparing results...');

    if (results1.length != results2.length) {
      print(
        '❌ Count Mismatch: Run 1 has ${results1.length}, Run 2 has ${results2.length}.',
      );
      // Continue comparison anyway on min length
    }

    int diffCount = 0;
    final collectionEquality = const ListEquality().equals;

    for (int i = 0; i < results1.length; i++) {
      // Try to match by description/amount since order might change?
      // Assuming strict order for now from PDF extraction which should be linear.
      if (i >= results2.length) break;

      final t1 = results1[i];
      final t2 = results2[i];

      bool tagsMatch = collectionEquality(t1['category'], t2['category']);
      bool vendorMatch = t1['vendor_name'] == t2['vendor_name'];

      if (!tagsMatch || !vendorMatch) {
        diffCount++;
        if (diffCount <= 5) {
          print('⚠️  Diff at index $i:');
          print('   Desc: ${t1['description']}');
          if (!tagsMatch)
            print('   Tags: ${t1['category']} vs ${t2['category']}');
          if (!vendorMatch)
            print('   Vendor: ${t1['vendor_name']} vs ${t2['vendor_name']}');
        }
      }
    }

    if (diffCount == 0 && results1.length == results2.length) {
      print('✅ SUCCESS: Results are IDENTICAL.');
    } else {
      print('❌ FAILURE: Found $diffCount differences.');
      print(
        'Conclusion: The model is NOT fully deterministic with current settings.',
      );
    }
  } catch (e) {
    print('❌ Error: $e');
  }
}
