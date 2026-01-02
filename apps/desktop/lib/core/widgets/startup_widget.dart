import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgetizer_dart/budgetizer_dart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';

final appStartupProvider = FutureProvider<void>((ref) async {
  // 1. Initialize Database
  final docsDir = await getApplicationDocumentsDirectory();
  final budgetizerDir = Directory('${docsDir.path}/budgetizer');
  if (!await budgetizerDir.exists()) {
    await budgetizerDir.create(recursive: true);
  }

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    await DatabaseService().init(databaseFactoryFfi, budgetizerDir.path);
  } else {
    // Mobile (Android/iOS)
    await DatabaseService().init(databaseFactory, budgetizerDir.path);
  }
});

class AppStartupWidget extends ConsumerWidget {
  final Widget child;
  const AppStartupWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startupState = ref.watch(appStartupProvider);

    return startupState.when(
      data: (_) => child,
      loading: () => const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text("Initializing Budgetizer..."),
              ],
            ),
          ),
        ),
      ),
      error: (e, st) => MaterialApp(
        home: Scaffold(body: Center(child: Text("Error: $e"))),
      ),
    );
  }
}
