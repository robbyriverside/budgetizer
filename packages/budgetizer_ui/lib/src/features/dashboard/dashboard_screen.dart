import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'controllers/dashboard_controller.dart';
import '../../core/services/bank_service.dart';
import 'widgets/inspector_panel.dart';
import 'widgets/tag_inspector_panel.dart';
import '../../core/widgets/split_view.dart';
import '../../widgets/transaction_list_tile.dart';
import '../../core/services/tag_service.dart';

import '../loading/loading_screen.dart' as apps_loading;
import '../vendors/vendor_screen.dart' as apps_vendors;
import '../reporting/reporting_screen.dart' as apps_reporting;
import '../app/controllers/app_controller.dart';
import 'widgets/intro_view.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Get Transactions
    final transactionsAsync = ref.watch(bankTransactionListProvider);
    // 2. Get Selection
    final dashboardState = ref.watch(dashboardControllerProvider);
    final selection = dashboardState.selection;

    // 3. Get Cashflows
    final currentCashflowId = ref.watch(currentCashflowProvider);

    // 4. Get App State (DB Selection)
    final appState = ref.watch(appControllerProvider);
    final tagState = ref.watch(tagServiceProvider);

    return Scaffold(
      body: SplitView(
        axis: Axis.horizontal,
        initialRatio: 0.7,
        minRatio: 0.5,
        minExtentSecond: 320,
        // A. Main Content (The Stream) and B. Sidebar
        child1: Column(
          children: [
            // Header (Breadcrumbs + Balance)
            _buildHeader(context, ref, currentCashflowId, appState),

            // Content
            Expanded(
              child: transactionsAsync.when(
                data: (transactions) {
                  // AUTO DETECT FIRST TIME USER / EMPTY DB
                  // If no transactions, show Intro View
                  if (transactions.isEmpty) {
                    return const IntroView();
                  }

                  final uninitialized = transactions
                      .where((t) => !t.isInitialized)
                      .toList();
                  final initialized = transactions
                      .where((t) => t.isInitialized)
                      .toList();

                  return Column(
                    children: [
                      // Cycle Progress Bar (Only show if we have data)
                      _buildCycleProgress(),
                      Expanded(
                        child: ListView(
                          children: [
                            // 1. Uninitialized
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
                                return TransactionListTile(
                                  key: ValueKey(tx.id),
                                  transaction: tx,
                                  tagTypeMap: tagState.value?.tagTypeMap,
                                  selected: isSelected,
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
                                  onTagDeleted: (tag) {
                                    final isValid = ref
                                        .read(tagServiceProvider.notifier)
                                        .validateTagRemoval(tx.tags, tag);
                                    if (!isValid) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          backgroundColor: Colors.red,
                                          content: Text(
                                            "Cannot remove: Transaction must have at least one Market tag.",
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    ref
                                        .read(
                                          dashboardControllerProvider.notifier,
                                        )
                                        .removeTagFromTransaction(tx.id, tag);
                                  },
                                );
                              }),
                              Divider(color: Colors.white24, thickness: 2),
                            ],
                            // 2. Initialized
                            if (initialized.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  "Posted Transactions",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                              ...initialized.map((tx) {
                                final isSelected = selection.contains(tx.id);
                                return TransactionListTile(
                                  key: ValueKey(tx.id),
                                  transaction: tx,
                                  tagTypeMap: tagState.value?.tagTypeMap,
                                  selected: isSelected,
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
                                  onTagDeleted: (tag) {
                                    final isValid = ref
                                        .read(tagServiceProvider.notifier)
                                        .validateTagRemoval(tx.tags, tag);
                                    if (!isValid) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          backgroundColor: Colors.red,
                                          content: Text(
                                            "Cannot remove: Transaction must have at least one Market tag.",
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    ref
                                        .read(
                                          dashboardControllerProvider.notifier,
                                        )
                                        .removeTagFromTransaction(tx.id, tag);
                                  },
                                );
                              }),
                            ],
                          ],
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),

        child2: Container(
          decoration: BoxDecoration(
            color: Colors.black26,
            border: Border(left: BorderSide(color: Colors.white12)),
          ),
          child: _buildRightSidebar(
            ref,
            selection.isNotEmpty,
            dashboardState,
            transactionsAsync,
          ),
        ),
      ),
    );
  }

  Widget _buildRightSidebar(
    WidgetRef ref,
    bool hasSelection,
    DashboardState dashboardState,
    AsyncValue<List<BankTransaction>> transactionsAsync,
  ) {
    final topContent = Column(
      children: [
        _buildToolbar(ref, hasSelection),
        Divider(color: Colors.white12),
        Expanded(child: _buildInspector(dashboardState)),
      ],
    );

    // If Tag Inspector is NOT visible, just return topContent
    if (dashboardState.selectedTag == null) return topContent;

    return SplitView(
      axis: Axis.vertical,
      mode: SplitViewMode.fixedSecond,
      initialExtent: 280,
      minExtentSecond: 200,
      child1: topContent,
      child2: transactionsAsync.when(
        data: (transactions) {
          bool isVendor = false;
          if (dashboardState.selection.isNotEmpty) {
            final selectedTxId = dashboardState.selection.first;
            final tx =
                transactions.where((t) => t.id == selectedTxId).firstOrNull ??
                (transactions.isNotEmpty ? transactions[0] : null);

            // If tx found
            if (tx != null &&
                tx.tags.isNotEmpty &&
                tx.tags.first == dashboardState.selectedTag) {
              isVendor = true;
            }
          }
          return TagInspectorPanel(
            tagName: dashboardState.selectedTag!,
            isVendor: isVendor,
          );
        },
        loading: () => const SizedBox(),
        error: (_, __) => const SizedBox(),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    String currentCashflowId,
    AppState appState,
  ) {
    final cashflowsAsync = ref.watch(cashflowListProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Cashflow Selector AND DB Selector
          Row(
            children: [
              // DB Selector Toggle
              DropdownButton<TargetDbType>(
                value: appState.targetDbType,
                dropdownColor: Color(0xFF2C2C2C),
                style: TextStyle(fontSize: 14, color: Colors.white70),
                underline: SizedBox(),
                items: TargetDbType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Row(
                      children: [
                        Icon(
                          type == TargetDbType.permanent
                              ? Icons.storage
                              : Icons.memory,
                          size: 16,
                          color: type == TargetDbType.permanent
                              ? Colors.blueAccent
                              : Colors.orangeAccent,
                        ),
                        SizedBox(width: 8),
                        Text(
                          type == TargetDbType.permanent
                              ? "Core DB"
                              : "Temp DB",
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    ref
                        .read(appControllerProvider.notifier)
                        .setTargetDbType(val);
                  }
                },
              ),
              Container(
                height: 30,
                width: 1,
                color: Colors.white24,
                margin: EdgeInsets.symmetric(horizontal: 16),
              ),
              // Cashflow Selector
              // Cashflow Selector
              cashflowsAsync.when(
                data: (cashflows) {
                  if (cashflows.isNotEmpty) {
                    final current = cashflows.firstWhere(
                      (c) => c.id == currentCashflowId,
                      orElse: () => cashflows.first,
                    );
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            DropdownButton<String>(
                              value: current.id,
                              underline: SizedBox(),
                              icon: Icon(
                                Icons.arrow_drop_down,
                                color: Colors.tealAccent,
                              ),
                              dropdownColor: Color(0xFF2C2C2C),
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              onChanged: (newValue) {
                                ref
                                    .read(currentCashflowProvider.notifier)
                                    .set(newValue!);
                                ref.invalidate(bankTransactionListProvider);
                              },
                              items: cashflows.map((c) {
                                return DropdownMenuItem(
                                  value: c.id,
                                  child: Text(c.name),
                                );
                              }).toList(),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "Cycle (Oct)",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "\$${current.balance.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Text(
                      "No Cashflows",
                      style: TextStyle(color: Colors.grey),
                    );
                  }
                },
                loading: () => SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (err, stack) => Text(
                  'Error loading cashflows',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),

          // Right: Actions
          Row(
            children: [
              // LOAD DATA Button - Removed/Simplified?
              // User said "Move DB selection to landing page... trans action viewer... show introductory material... since there is no saved last cashflow"
              // If we are in Intro Mode, the "Load Data" is in the Intro body.
              // If we are in "Normal" mode, we might still want "Load Data" in the header to add MORE data?
              // The original "Load Data" button navigated to LoadingScreen.
              // Now "IntroView" handles loading for first time.
              // We should probably keep "Load Data" available but simpler?
              // Or keep it as is, pointing to LoadingScreen?
              // The requirement: "Move DB selection...".
              // I'll keep "Load Data" button for now, but maybe it should open the same "Intro/Load" logic or the old LoadingScreen if specific configuration is needed?
              // I'll keep it pointing to LoadingScreen for now as a fallback/advanced load, but we might want to refactor LoadingScreen later.
              FilledButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const apps_loading.LoadingScreen(),
                    ),
                  );
                  ref.invalidate(bankTransactionListProvider);
                },
                icon: Icon(Icons.download),
                label: Text("Load Data"),
              ),
              const SizedBox(width: 16),

              // REPORT BUTTON
              FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const apps_reporting.ReportingScreen(),
                    ),
                  );
                },
                icon: Icon(Icons.analytics),
                label: Text("Report"),
              ),
              const SizedBox(width: 16),

              // VENDOR BUTTON
              FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const apps_vendors.VendorScreen(),
                    ),
                  );
                },
                icon: Icon(Icons.store),
                label: Text("Vendors"),
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
