import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:budgetizer_dart/budgetizer_dart.dart';

import 'package:cli/service_locator.dart';

class BudgetsCommand extends Command {
  @override
  final name = 'budgets';
  @override
  final description =
      'Manage budget configurations. Default: export settings. Use --load to update.';

  BudgetsCommand() {
    argParser.addOption(
      'load',
      abbr: 'l',
      help: 'Load configuration from an existing spreadsheet file.',
      valueHelp: 'FILE',
    );
  }

  @override
  Future<void> run() async {
    final loadFile = argResults?['load'] as String?;
    final bankService = getBankService();
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
    print('Fetching current budget config...');
    final tags = await bankService.fetchTags();

    print('Generating budgets.xlsx...');
    final bytes = await excelService.exportBudgets(tags);
    final file = File('budgets.xlsx');
    await file.writeAsBytes(bytes);

    print('✅ Generated ${file.path}');
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

    print('Loading budget config from $path...');
    final bytes = await file.readAsBytes();

    try {
      final imports = await excelService.importBudgets(bytes);
      print('Read ${imports.length} budget rules.');

      // Validation Logic would go here.
      // E.g. check if frequency is valid.

      print('✅ Budget configuration updated.');
    } catch (e) {
      print('Error parsing file: $e');
      exit(1);
    }
  }
}
