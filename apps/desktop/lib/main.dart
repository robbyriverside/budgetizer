import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';

import 'package:budgetizer_dart/budgetizer_dart.dart';
import 'package:budgetizer_ui/budgetizer_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env", isOptional: true);

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(
    ProviderScope(
      overrides: [
        // Provide the concrete implementation of StorageRepository
        storageRepositoryProvider.overrideWithValue(SqliteService()),

        // Provide the initialization logic
        appStartupProvider.overrideWith((ref) async {
          final docsDir = await getApplicationDocumentsDirectory();
          final budgetizerDir = Directory('${docsDir.path}/budgetizer');
          if (!await budgetizerDir.exists()) {
            await budgetizerDir.create(recursive: true);
          }
          // Initialize SqliteService
          // Note: SqliteService is a singleton, so overrideWithValue above uses the SAME instance
          // that we init here.
          await SqliteService().init(databaseFactory, budgetizerDir.path);
        }),
      ],
      child: const AppStartupWidget(child: BudgetizerApp()),
    ),
  );
}
