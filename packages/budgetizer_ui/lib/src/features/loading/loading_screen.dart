import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgetizer_dart/budgetizer_dart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/widgets/split_view.dart';
import 'loading_controller.dart';

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
        title: Text(state.isLoading ? "Loading Transactions..." : "Load Data"),
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
                                      .read(loadingControllerProvider.notifier)
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
                            onChanged: (val) {
                              // Basic validation or clamping could happen here
                              // But we'll enforce on submit.
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: state.isLoading
                              ? null
                              : () {
                                  int count =
                                      int.tryParse(_mockCountController.text) ??
                                      50;
                                  if (count > 500) count = 500;
                                  if (count < 1) count = 1;
                                  _mockCountController.text = count
                                      .toString(); // Sync back clamped val

                                  ref
                                      .read(loadingControllerProvider.notifier)
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
                          onPressed: null, // Not implemented fully yet
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
                                      .read(loadingControllerProvider.notifier)
                                      .loadFromStatementsDb(
                                        _statementsDbController.text.isNotEmpty
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
                          selectedTileColor: Colors.teal.withValues(alpha: 0.2),
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
                                    fontFamily:
                                        'Courier', // Monospace for LED look
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Delete Button
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  size: 18,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  final deletedTag = entry.key;
                                  ref
                                      .read(loadingControllerProvider.notifier)
                                      .deleteTag(deletedTag);

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "Tag '$deletedTag' deleted",
                                      ),
                                      action: SnackBarAction(
                                        label: "UNDO",
                                        onPressed: () {
                                          ref
                                              .read(
                                                loadingControllerProvider
                                                    .notifier,
                                              )
                                              .undoDeleteTag(deletedTag);
                                        },
                                      ),
                                    ),
                                  );
                                },
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
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 4.0,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            tx.vendorName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Text(
                                            tx.description,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '\$${tx.amount.abs().toStringAsFixed(2)}',
                                      style: GoogleFonts.robotoMono(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: tx.tags.map((tag) {
                                    return InputChip(
                                      label: Text(
                                        tag,
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                      labelPadding: const EdgeInsets.symmetric(
                                        horizontal: 2,
                                      ),
                                      visualDensity: VisualDensity.compact,
                                      backgroundColor: Colors.teal.withValues(
                                        alpha: 0.1,
                                      ),
                                      deleteIcon: const Icon(
                                        Icons.close,
                                        size: 14,
                                      ),
                                      onDeleted: () {
                                        ref
                                            .read(
                                              loadingControllerProvider
                                                  .notifier,
                                            )
                                            .removeTagFromTransaction(
                                              tx.id,
                                              tag,
                                            );
                                      },
                                      onPressed: () {
                                        setState(() {
                                          _selectedTag = tag;
                                        });
                                      },
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
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
    );
  }
}
