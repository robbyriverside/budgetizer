import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'controllers/dashboard_controller.dart';

import 'widgets/inspector_panel.dart';
import 'widgets/tag_inspector_panel.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Get Transactions
    final transactionsAsync = ref.watch(bankTransactionListProvider);
    // 2. Get Selection
    final dashboardState = ref.watch(dashboardControllerProvider);
    final selection = dashboardState.selection;

    return Scaffold(
      body: Row(
        children: [
          // A. Main Content (The Stream)
          Expanded(
            flex: 3,
            child: Column(
              children: [
                // Header (Breadcrumbs + Balance)
                _buildHeader(),
                // Cycle Progress Bar
                _buildCycleProgress(),
                // Transaction List
                Expanded(
                  child: transactionsAsync.when(
                    data: (transactions) {
                      // Split Transactions
                      final uninitialized = transactions
                          .where((t) => !t.isInitialized)
                          .toList();
                      final initialized = transactions
                          .where((t) => t.isInitialized)
                          .toList();

                      return ListView(
                        children: [
                          // 1. Uninitialized Queue (Only show if not empty)
                          if (uninitialized.isNotEmpty) ...[
                            Container(
                              padding: EdgeInsets.all(10),
                              color: Colors.amber.withValues(alpha: 0.1),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber,
                                    color: Colors.amber,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    "New Transactions Needs Review",
                                    style: TextStyle(
                                      color: Colors.amber,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ...uninitialized.map((tx) {
                              final isSelected = selection.contains(tx.id);
                              return ListTile(
                                selected: isSelected,
                                selectedTileColor: Colors.amber.withValues(
                                  alpha: 0.2,
                                ), // Distinct color
                                onTap: () {
                                  final isMulti =
                                      HardwareKeyboard
                                          .instance
                                          .logicalKeysPressed
                                          .contains(
                                            LogicalKeyboardKey.shiftLeft,
                                          ) ||
                                      HardwareKeyboard
                                          .instance
                                          .logicalKeysPressed
                                          .contains(
                                            LogicalKeyboardKey.shiftRight,
                                          );

                                  ref
                                      .read(
                                        dashboardControllerProvider.notifier,
                                      )
                                      .selectTransaction(
                                        tx.id,
                                        multiSelect: isMulti,
                                      );
                                },
                                leading: Icon(
                                  Icons.new_releases,
                                  color: Colors.amber,
                                ),
                                title: Text(tx.name),
                                subtitle: Text("To be initialized..."),
                                trailing: Text(
                                  '\$${tx.amount.abs().toStringAsFixed(2)}',
                                ),
                              );
                            }),
                            Divider(color: Colors.white24, thickness: 2),
                          ],

                          // 2. Initialized Transactions (Header + List)
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              "Posted Transactions",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          ...initialized.map((tx) {
                            final isSelected = selection.contains(tx.id);
                            return ListTile(
                              selected: isSelected,
                              selectedTileColor: Colors.teal.withValues(
                                alpha: 0.2,
                              ),
                              onTap: () {
                                final isMulti =
                                    HardwareKeyboard.instance.logicalKeysPressed
                                        .contains(
                                          LogicalKeyboardKey.shiftLeft,
                                        ) ||
                                    HardwareKeyboard.instance.logicalKeysPressed
                                        .contains(
                                          LogicalKeyboardKey.shiftRight,
                                        );

                                ref
                                    .read(dashboardControllerProvider.notifier)
                                    .selectTransaction(
                                      tx.id,
                                      multiSelect: isMulti,
                                    );
                              },
                              leading: Icon(
                                Icons.receipt_long,
                                color: tx.amount < 0
                                    ? Colors.green
                                    : Colors.white,
                              ),
                              title: Text(tx.name),
                              subtitle: Text(tx.tags.join(', ')),
                              trailing: Text(
                                '\$${tx.amount.abs().toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: tx.amount < 0
                                      ? Colors.greenAccent
                                      : Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }),
                        ],
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Center(child: Text('Error: $err')),
                  ),
                ),
              ],
            ),
          ),

          // B. Right Sidebar (Tools & Inspection)
          Container(
            width: 300,
            decoration: BoxDecoration(
              color: Colors.black26,
              border: Border(left: BorderSide(color: Colors.white12)),
            ),
            child: Column(
              children: [
                // Top Toolbar
                _buildToolbar(ref, selection.isNotEmpty),
                Divider(color: Colors.white12),
                // Inspector Panel
                Expanded(child: _buildInspector(dashboardState)),
                // Tag Inspector (Bottom) - Only if tag selected
                if (dashboardState.selectedTag != null)
                  TagInspectorPanel(tagName: dashboardState.selectedTag!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Checking > Cycle (Oct)",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 5),
              Text(
                "\$12,450.00",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCycleProgress() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Cycle Progress (Day 15/30)"),
              Text(
                "Projected Buffer: \$1,200",
                style: TextStyle(color: Colors.greenAccent),
              ),
            ],
          ),
          const SizedBox(height: 5),
          LinearProgressIndicator(value: 0.5, color: Colors.teal),
        ],
      ),
    );
  }

  Widget _buildToolbar(WidgetRef ref, bool hasSelection) {
    final calcs = ref.watch(dashboardCalculationsProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                hasSelection ? "Selected Totals" : "Cycle Totals",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              if (hasSelection)
                IconButton(
                  icon: const Icon(Icons.clear_all),
                  onPressed: () {
                    ref
                        .read(dashboardControllerProvider.notifier)
                        .clearSelection();
                  },
                  tooltip: "Clear Selection",
                )
              else
                IconButton(
                  icon: const Icon(Icons.sync),
                  onPressed: () {
                    // Trigger Sync
                    // ignore: unused_result
                    ref.refresh(bankTransactionListProvider);
                  },
                ),
            ],
          ),
          const SizedBox(height: 20),
          _buildCalcRow(
            "Income",
            "\$${calcs['income']?.toStringAsFixed(2)}",
            Colors.green,
          ),
          _buildCalcRow(
            "Expenses",
            "\$${calcs['expense']?.toStringAsFixed(2)}",
            Colors.white,
          ),
          const Divider(),
          _buildCalcRow(
            "Net",
            "\$${calcs['net']?.toStringAsFixed(2)}",
            Colors.tealAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildCalcRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildInspector(DashboardState state) {
    return InspectorPanel(state: state);
  }
}
