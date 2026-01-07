import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgetizer_dart/budgetizer_dart.dart';
import '../../core/widgets/split_view.dart';
import '../../widgets/transaction_list_tile.dart';
import 'loading_controller.dart';
import '../../core/services/tag_service.dart';

class LoadingScreen extends ConsumerStatefulWidget {
  const LoadingScreen({super.key});

  @override
  ConsumerState<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends ConsumerState<LoadingScreen> {
  String? _selectedTag;
  final TextEditingController _statementsDbController = TextEditingController();
  final TextEditingController _mockCountController = TextEditingController(
    text: '50',
  );

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loadingControllerProvider);
    final tagState = ref.watch(tagServiceProvider);

    // Sort tags by count desc
    final sortedTags = state.tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Filter transactions for right side
    final relevantTransactions = _selectedTag == null
        ? <BankTransaction>[]
        : state.loadedTransactions
              .where((t) => t.tags.contains(_selectedTag))
              .toList();

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyZ, meta: true): () {
          ref.read(loadingControllerProvider.notifier).undoLastTagAction();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Undoing last tag change..."),
              duration: Duration(milliseconds: 500),
            ),
          );
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              state.isLoading ? "Loading Transactions..." : "Load Data",
            ),
            actions: [SizedBox(width: 16)],
          ),
          body: Column(
            children: [
              // Configuration Header
              Card(
                margin: EdgeInsets.all(8),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text("Data Source: "),
                          SizedBox(width: 8),
                          DropdownButton<DataSourceType>(
                            value: state.dataSourceType,
                            items: const [
                              DropdownMenuItem(
                                value: DataSourceType.mock,
                                child: Text("Mock Generator"),
                              ),
                              DropdownMenuItem(
                                value: DataSourceType.plaid,
                                child: Text("Plaid (Bank)"),
                              ),
                              DropdownMenuItem(
                                value: DataSourceType.statements,
                                child: Text("Statements DB"),
                              ),
                            ],
                            onChanged: state.isLoading
                                ? null
                                : (val) {
                                    if (val != null) {
                                      ref
                                          .read(
                                            loadingControllerProvider.notifier,
                                          )
                                          .setDataSourceType(val);
                                    }
                                  },
                          ),
                          Spacer(),
                          if (!state.isLoading &&
                              state.loadedTransactions.isNotEmpty)
                            FilledButton.icon(
                              onPressed: () async {
                                await ref
                                    .read(loadingControllerProvider.notifier)
                                    .commitTransactions();
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              },
                              icon: Icon(Icons.check),
                              label: Text("Import to DB"),
                            ),
                        ],
                      ),
                      SizedBox(height: 16),
                      // Dynamic Config Section
                      if (state.dataSourceType == DataSourceType.mock)
                        Row(
                          children: [
                            const Text("Mock Count (Max 500): "),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 80,
                              child: TextField(
                                controller: _mockCountController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: state.isLoading
                                  ? null
                                  : () {
                                      int count =
                                          int.tryParse(
                                            _mockCountController.text,
                                          ) ??
                                          50;
                                      if (count > 500) count = 500;
                                      if (count < 1) count = 1;
                                      _mockCountController.text = count
                                          .toString();

                                      ref
                                          .read(
                                            loadingControllerProvider.notifier,
                                          )
                                          .startMockLoading(count: count);
                                    },
                              child: const Text("Generate Mock Data"),
                            ),
                          ],
                        ),
                      if (state.dataSourceType == DataSourceType.plaid)
                        Row(
                          children: [
                            Text("Plaid Integration: "),
                            SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: null,
                              child: Text("Connect Account (Coming Soon)"),
                            ),
                          ],
                        ),
                      if (state.dataSourceType == DataSourceType.statements)
                        Row(
                          children: [
                            Text("Statements DB Name: "),
                            SizedBox(width: 8),
                            SizedBox(
                              width: 200,
                              child: TextField(
                                controller: _statementsDbController,
                                decoration: InputDecoration(
                                  hintText: "e.g. '2025_jan'",
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: state.isLoading
                                  ? null
                                  : () {
                                      ref
                                          .read(
                                            loadingControllerProvider.notifier,
                                          )
                                          .loadFromStatementsDb(
                                            _statementsDbController
                                                    .text
                                                    .isNotEmpty
                                                ? _statementsDbController.text
                                                : 'default',
                                          );
                                    },
                              child: Text("Load Statements"),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              Divider(),
              // Main Content
              Expanded(
                child: SplitView(
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
                              selectedTileColor: Colors.teal.withValues(
                                alpha: 0.2,
                              ),
                              title: Text(entry.key),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // LED Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      border: Border.all(
                                        color: Colors.cyanAccent.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.cyanAccent.withValues(
                                            alpha: 0.2,
                                          ),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      '${entry.value}',
                                      style: const TextStyle(
                                        color: Colors.cyanAccent,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Courier',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
                            return TransactionListTile(
                              transaction: tx,
                              tagTypeMap: tagState.value?.tagTypeMap,
                              onTagTap: (tag) {
                                setState(() {
                                  _selectedTag = tag;
                                });
                              },
                              onTagDeleted: (tag) {
                                final isValid = ref
                                    .read(tagServiceProvider.notifier)
                                    .validateTagRemoval(tx.tags, tag);

                                if (!isValid) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      backgroundColor: Colors.red,
                                      content: Text(
                                        "Cannot remove: Transaction must have at least one Market or Service tag.",
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                ref
                                    .read(loadingControllerProvider.notifier)
                                    .removeTagFromTransaction(tx.id, tag);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
