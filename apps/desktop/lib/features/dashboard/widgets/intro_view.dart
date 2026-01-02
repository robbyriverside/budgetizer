import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../loading/loading_controller.dart';

class IntroView extends ConsumerWidget {
  const IntroView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(32),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Welcome to Budgetizer",
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Text(
                "No cashflow data is currently available in this database.",
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              Text(
                "Get Started:",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.bolt, color: Colors.amber),
                title: const Text("Generate Mock Data"),
                subtitle: const Text(
                  "Create random transactions to explore the app",
                ),
                onTap: () {
                  ref
                      .read(loadingControllerProvider.notifier)
                      .startMockLoading(count: 30);
                  _showLoadingDialog(context, ref);
                },
                tileColor: Colors.amber.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.description, color: Colors.blue),
                title: const Text("Import Statements"),
                subtitle: const Text("Load transactions from statement files"),
                onTap: () {
                  // Navigate to Load Screen or show dialog
                  // For now just show a simple dialog or redirect
                  ref
                      .read(loadingControllerProvider.notifier)
                      .setDataSourceType(DataSourceType.statements);
                  // We don't have a direct "start loading" for statements here without input
                  // So we might want to navigate to loading screen logic?
                  // Just reuse the Loading Screen for now if complex configuration is needed?
                  // But requirements said "Move DB Selection to Landing Page" and "Intro Material"
                  // Re-using loading screen logic here is fine, but maybe inline it?
                  // Let's just create a quick dialog for entering DB name.
                  _showStatementDialog(context, ref);
                },
                tileColor: Colors.blue.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.account_balance, color: Colors.green),
                title: const Text("Connect Bank"),
                subtitle: const Text("Connect via Plaid (Coming Soon)"),
                enabled: false,
                tileColor: Colors.grey.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLoadingDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final state = ref.watch(loadingControllerProvider);
            if (!state.isLoading && state.processedCount > 0) {
              // Loading Done, Commit!
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                await ref
                    .read(loadingControllerProvider.notifier)
                    .commitTransactions();
                if (context.mounted) Navigator.pop(context);
              });
            }
            return AlertDialog(
              title: const Text("Generating Data..."),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(),
                  const SizedBox(height: 10),
                  Text("${state.processedCount} transactions generated"),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showStatementDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Load Statements"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Statement DB Name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(loadingControllerProvider.notifier)
                  .loadFromStatementsDb(controller.text);
              _showLoadingDialog(context, ref);
            },
            child: const Text("Load"),
          ),
        ],
      ),
    );
  }
}
