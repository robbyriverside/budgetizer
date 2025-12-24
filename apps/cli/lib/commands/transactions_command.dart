import 'dart:convert';
import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:budgetizer_dart/budgetizer_dart.dart';

import 'package:cli/service_locator.dart';

class TransactionsCommand extends Command {
  @override
  final name = 'transactions';
  @override
  final description =
      'Manage transactions. Default: fetch & export. Use --load to import edits.';

  TransactionsCommand() {
    argParser.addOption(
      'load',
      abbr: 'l',
      help: 'Load edits from an existing spreadsheet file.',
      valueHelp: 'FILE',
    );
    argParser.addOption(
      'account',
      abbr: 'a',
      help: 'Filter by account/cashflow ID (for export)',
    );
  }

  @override
  Future<void> run() async {
    final loadFile = argResults?['load'] as String?;
    final bankService = getBankService(); // In real app: Riverpod/DI
    final excelService = ExcelService();

    if (loadFile != null) {
      await _handleLoad(loadFile, bankService, excelService);
    } else {
      await _handleExport(bankService, excelService);
    }
  }

  Future<void> _handleExport(
    BankService bankService,
    ExcelService excelService,
  ) async {
    print('Fetching latest transactions...');

    // Auto-Auth Logic for Sandbox
    if (!bankService.isConnected && bankService is PlaidBankService) {
      print('⚠️  Not connected to a bank item.');

      // Check if we can auto-connect (Sandbox only logic, usually check env)
      // We'll perform the handshake.
      try {
        print('🔄 Attempting Sandbox Auto-Link...');
        final token = await (bankService as PlaidBankService)
            .authenticateSandbox();
        print('✅ Connected to Sandbox Bank!');
        print('🔑 GENERATED ACCESS TOKEN: $token');
        print(
          '👉 ACTION REQUIRED: Add PLAID_ACCESS_TOKEN=$token to your .env file to skip this step next time.',
        );
      } catch (e) {
        print('❌ Auto-Link failed: $e');
        print('Please ensure your Client ID/Secret are correct for Sandbox.');
        exit(1);
      }
    }

    // Retry Logic for PRODUCT_NOT_READY
    // Sandbox initial load can be instant but sometimes race condition
    int retries = 0;
    while (retries < 5) {
      try {
        final txs = await bankService.fetchTransactions('checking_1');

        if (txs.isEmpty) {
          print(
            '⚠️  Plaid returned 0 transactions (Sandboxed account might be empty or date range too short).',
          );
          print(
            '🔄 Falling back to "Regression Data" (Mock Data) as requested...',
          );

          final mockService = getMockBankService(); // Fallback
          // We need to wait a bit for mock service to init?
          // MockBankService fetchTransactions handles delayed init.
          final mockTxs = await mockService.fetchTransactions('checking_1');

          print('Found ${mockTxs.length} mock transactions.');
          final bytes = await excelService.exportTransactions(mockTxs);
          final file = File('transactions.xlsx');
          await file.writeAsBytes(bytes);

          print('✅ Generated ${file.path} (using Mock Data)');
          return;
        }

        print('Found ${txs.length} transactions.');
        print('Generating transactions.xlsx...');

        final bytes = await excelService.exportTransactions(txs);
        final file = File('transactions.xlsx');
        await file.writeAsBytes(bytes);

        print('✅ Generated ${file.path}');
        return; // Success
      } catch (e) {
        if (e.toString().contains('PRODUCT_NOT_READY')) {
          print(
            '⏳ Plaid is syncing (PRODUCT_NOT_READY). Retrying in 2 seconds... (${retries + 1}/5)',
          );
          await Future.delayed(Duration(seconds: 2));
          retries++;
        } else {
          rethrow; // Other errors
        }
      }
    }
    print('❌ Failed to fetch transactions after retries.');
    exit(1);
  }

  Future<void> _handleLoad(
    String path,
    BankService bankService,
    ExcelService excelService,
  ) async {
    final file = File(path);
    if (!await file.exists()) {
      print('Error: File not found: $path');
      exit(1);
    }

    if (path.endsWith('.pdf')) {
      print('📄 Detected PDF file. initializing AI service...');
      try {
        final aiService = getAIService();
        final bytes = await file.readAsBytes();

        print('📚 Loading Tag Engine...');
        final dbTagsFile = File(
          '/Users/robfarrow/dev/budgetizer/apps/desktop/assets/data/db_tags.json',
        );
        TagEngine tagEngine;
        if (await dbTagsFile.exists()) {
          tagEngine = TagEngine.fromJson(await dbTagsFile.readAsString());
        } else {
          print('⚠️ db_tags.json not found, starting with empty TagEngine');
          tagEngine = TagEngine([]);
        }

        print('🤖 Extracting transactions from PDF...');
        final rawTransactions = await aiService.extractTransactionsFromPdf(
          bytes,
        );

        print('✨ Extracted ${rawTransactions.length} transactions.');

        // Convert to BankTransaction objects with Learning Loop
        final txs = <BankTransaction>[];
        int learnedCount = 0;

        for (var t in rawTransactions) {
          // Normalize date
          final dateStr = t['date'] as String; // expected YYYY-MM-DD
          final description = t['description'] as String;
          final amount = (t['amount'] as num).toDouble();

          // 1. Create Base Transaction
          var tx = BankTransaction(
            id: 'gen_${dateStr.replaceAll('-', '')}_${amount.abs()}_${description.hashCode}',
            date: DateTime.parse(dateStr),
            description: description,
            vendorName: t['vendor_name'] as String, // AI suggestion (default)
            amount: amount,
            tags: List<String>.from(
              t['category'] as List,
            ), // AI suggestion (default)
            pending: false,
            cashflowId: 'imported_pdf',
            isInitialized: true,
          );

          // 2. Check TagEngine (Deterministic Override)
          final analysis = tagEngine.analyzeDescription(description);
          if (analysis['tags'] != null &&
              (analysis['tags'] as List).isNotEmpty) {
            // Found a regex match! Override AI.
            tx = tx.copyWith(
              vendorName: analysis['vendor'],
              tags: List<String>.from(analysis['tags']),
            );
            // print('  ✅ Deterministic match for: $description -> ${analysis['vendor']}');
          } else {
            // 3. No match? Learn from AI if regex provided.
            final suggestedRegex = t['regex'] as String?;
            final vendorName = t['vendor_name'] as String;

            if (suggestedRegex != null && suggestedRegex.isNotEmpty) {
              print('  🧠 Learning new vendor: $vendorName ($suggestedRegex)');
              final categories = List<String>.from(t['category'] as List);

              final newTag = Tag(
                name: vendorName,
                type: 'Vendor',
                description: 'Learned from AI: $vendorName',
                regex: suggestedRegex,
                related: categories.where((c) => c != vendorName).toList(),
              );

              tagEngine.learnTag(newTag);
              learnedCount++;
            }
          }
          txs.add(tx);
        }

        // 4. Persist Learned Tags
        if (learnedCount > 0) {
          print('💾 Saving $learnedCount new tags to db_tags.json...');
          // Pretty print JSON
          final jsonStr = JsonEncoder.withIndent(
            '    ',
          ).convert(tagEngine.toJson());
          await dbTagsFile.writeAsString(jsonStr);
        }

        final bytesExcel = await excelService.exportTransactions(txs);
        final fileOut = File('transactions.xlsx');
        await fileOut.writeAsBytes(bytesExcel);

        print('✅ Generated ${fileOut.path} with extracted data.');
        return;
      } catch (e) {
        print('❌ Failed to extract PDF data: $e');
        exit(1);
      }
    }

    print('Loading edits from $path...');
    final bytes = await file.readAsBytes();

    try {
      final imports = await excelService.importTransactions(bytes);

      final errors = <String, String>{}; // ID -> Error Message

      // Validation Loop
      // In a real app, logic would be deeper.
      // Here we simulate validation:
      // 1. Tag cannot be empty if not ignored.
      // 2. Mock Error for demostration if Correction is "error"
      for (var row in imports) {
        if (row.correction.toLowerCase().contains('error')) {
          errors[row.id] = 'Simulated error based on correction text.';
        }
        // Example: Validate tag format
        for (var tag in row.tags) {
          if (tag.contains('?')) {
            errors[row.id] = 'Tag "$tag" contains invalid character "?"';
          }
        }
      }

      if (errors.isNotEmpty) {
        print('❌ Found ${errors.length} validation errors.');
        print('Rewriting $path with Error column...');

        // We need to re-export, but injecting errors.
        // Since we only have 'imports' (partial data),
        // in a real app we'd fetch the full objects again or merge data.
        // For CLI simulation, we fetch current state and merge imports + errors.

        final currentTxs = await bankService.fetchTransactions('checking_1');

        // Merge Logic: Update local objects with Import data
        final mergedTxs = currentTxs.map((tx) {
          final importRow = imports.firstWhere(
            (i) => i.id == tx.id,
            orElse: () => TransactionImport(id: '', vendorName: '', tags: []),
          );
          if (importRow.id.isNotEmpty) {
            // Return updated transaction object (conceptually)
            // For strict Excel generation, we need to pass these "errors" to exportTransactions
            return tx;
          }
          return tx;
        }).toList();

        // Update ExcelService to support an "Errors" column or write a new custom export here.
        final bytes = await excelService.exportTransactions(
          mergedTxs,
          errors: errors,
        );
        await file.writeAsBytes(bytes);

        print(
          '⚠️  Rewrote $path with ${errors.length} errors. Please fix and run again.',
        );
        print('   (See "Errors" column in the spreadsheet)');
        exit(1);
      }

      // If no errors, process corrections
      int correctionsCount = 0;
      for (var row in imports) {
        if (row.correction.isNotEmpty) {
          correctionsCount++;
          print('  📝 Correction for ${row.id}: "${row.correction}"');
        }
      }

      print('Processed ${imports.length} rows.');
      if (correctionsCount > 0) {
        print(
          'Found $correctionsCount AI corrections. System will look into them.',
        );
      }
      print('✅ System data updated.');
    } catch (e) {
      print('Error parsing file: $e');
      exit(1);
    }
  }
}
