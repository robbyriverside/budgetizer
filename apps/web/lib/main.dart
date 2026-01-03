import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgetizer_dart/budgetizer_dart.dart' hide FirebaseService;
import 'package:budgetizer_ui/budgetizer_ui.dart';
import 'services/firebase_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    ProviderScope(
      overrides: [
        storageRepositoryProvider.overrideWithValue(FirebaseService()),
        appStartupProvider.overrideWith((ref) async {
          // No specific init for simple usage
        }),
      ],
      child: const AppStartupWidget(child: BudgetizerApp()),
    ),
  );
}
