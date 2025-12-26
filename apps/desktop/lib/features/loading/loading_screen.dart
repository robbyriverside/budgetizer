import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgetizer_dart/budgetizer_dart.dart';
import '../../core/widgets/split_view.dart';
import 'loading_controller.dart';

class LoadingScreen extends ConsumerStatefulWidget {
  const LoadingScreen({super.key});

  @override
  ConsumerState<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends ConsumerState<LoadingScreen> {
  String? _selectedTag;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loadingControllerProvider);

    // Sort tags by count desc
    final sortedTags = state.tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Filter transactions for right side
    final relevantTransactions = _selectedTag == null
        ? <BankTransaction>[]
        : state.loadedTransactions
              .where((t) => t.tags.contains(_selectedTag))
              .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          state.isLoading ? "Loading Transactions..." : "Load Complete",
        ),
        actions: [
          if (!state.isLoading)
            FilledButton.icon(
              onPressed: () {
                // TODO: Save logic (commit temp transactions to real store)
                Navigator.of(context).pop();
              },
              icon: Icon(Icons.check),
              label: Text("Finish & Save"),
            ),
          SizedBox(width: 16),
        ],
      ),
      body: SplitView(
        axis: Axis.horizontal,
        initialRatio: 0.3,
        minRatio: 0.2,
        child1: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Tags Found",
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: sortedTags.length,
                itemBuilder: (context, index) {
                  final entry = sortedTags[index];
                  final isSelected = entry.key == _selectedTag;
                  return ListTile(
                    selected: isSelected,
                    selectedTileColor: Colors.teal.withOpacity(0.2),
                    title: Text(entry.key),
                    trailing: Badge(label: Text('${entry.value}')),
                    onTap: () {
                      setState(() {
                        _selectedTag = entry.key;
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
        child2: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _selectedTag == null
                    ? "Select a tag to view transactions"
                    : "Transactions for '$_selectedTag'",
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: relevantTransactions.length,
                itemBuilder: (context, index) {
                  final tx = relevantTransactions[index];
                  return ListTile(
                    leading: Icon(Icons.receipt),
                    title: Text(tx.vendorName),
                    subtitle: Text(tx.description),
                    trailing: Text('\$${tx.amount.abs().toStringAsFixed(2)}'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
