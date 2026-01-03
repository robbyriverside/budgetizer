import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'startup_widget.g.dart';

@Riverpod(keepAlive: true)
Future<void> appStartup(Ref ref) {
  throw UnimplementedError('appStartupProvider must be overridden');
}

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
