import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:cli/commands/transactions_command.dart';
import 'package:cli/commands/budgets_command.dart';

// IMPORTANT: budgetizer_dart must rely on sqflite_common_ffi for CLI DB access
// We need to initialize FFI at the top level.
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:dotenv/dotenv.dart';

void main(List<String> arguments) async {
  // Load .env file
  var env = DotEnv(includePlatformEnvironment: true)..load();

  // Initialize FFI for SQLite on Desktop/CLI
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final runner = CommandRunner('budgetizer', 'Budgetizer CLI Tools')
    ..addCommand(TransactionsCommand())
    ..addCommand(BudgetsCommand());

  try {
    await runner.run(arguments);
  } on UsageException catch (e) {
    print(e);
    exit(64); // Exit code for usage error
  } catch (e) {
    print('An error occurred: $e');
    exit(1);
  }
}
