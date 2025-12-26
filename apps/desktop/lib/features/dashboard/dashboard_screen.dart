import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'controllers/dashboard_controller.dart';
import '../../core/services/bank_service.dart';
import 'widgets/inspector_panel.dart';
import 'widgets/tag_inspector_panel.dart';
import '../../core/widgets/split_view.dart';
import 'widgets/alerts_dialog.dart';

import '../loading/loading_screen.dart' as apps_loading;
import '../vendors/vendor_screen.dart' as apps_vendors;
import '../reporting/reporting_screen.dart' as apps_reporting;

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
            _buildHeader(context, ref, currentCashflowId),
            // Cycle Progress Bar
            _buildCycleProgress(),
            // Transaction List
            Expanded(
              child: transactionsAsync.when(
                data: (transactions) {
                  final uninitialized = transactions
                      .where((t) => !t.isInitialized)
                      .toList();
                  final initialized = transactions
                      .where((t) => t.isInitialized)
                      .toList();

                  return ListView(
                    children: [
                      // 1. Uninitialized
                      if (uninitialized.isNotEmpty) ...[
                        Container(
                          padding: EdgeInsets.all(10),
                          color: Colors.amber.withOpacity(0.1),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber, color: Colors.amber),
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
                            selectedTileColor: Colors.amber.withOpacity(0.2),
                            onTap: () {
                              final isMulti =
                                  HardwareKeyboard.instance.logicalKeysPressed
                                      .contains(LogicalKeyboardKey.shiftLeft) ||
                                  HardwareKeyboard.instance.logicalKeysPressed
                                      .contains(LogicalKeyboardKey.shiftRight);
                              ref
                                  .read(dashboardControllerProvider.notifier)
                                  .selectTransaction(
                                    tx.id,
                                    multiSelect: isMulti,
                                  );
                            },
                            leading: Icon(
                              Icons.new_releases,
                              color: Colors.amber,
                            ),
                            title: Text(tx.vendorName),
                            subtitle: Text("To be initialized..."),
                            trailing: Text(
                              '\$${tx.amount.abs().toStringAsFixed(2)}',
                            ),
                          );
                        }),
                        Divider(color: Colors.white24, thickness: 2),
                      ],
                      // 2. Initialized
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
                          selectedTileColor: Colors.teal.withOpacity(0.2),
                          onTap: () {
                            final isMulti =
                                HardwareKeyboard.instance.logicalKeysPressed
                                    .contains(LogicalKeyboardKey.shiftLeft) ||
                                HardwareKeyboard.instance.logicalKeysPressed
                                    .contains(LogicalKeyboardKey.shiftRight);
                            ref
                                .read(dashboardControllerProvider.notifier)
                                .selectTransaction(tx.id, multiSelect: isMulti);
                          },
                          leading: Icon(
                            Icons.receipt_long,
                            color: tx.amount < 0 ? Colors.green : Colors.white,
                          ),
                          title: Text(tx.vendorName),
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

    // If Tag Inspector is NOT visible, just return top content
    if (dashboardState.selectedTag == null) {
      return topContent;
    }

    // If Tag Inspector IS visible, use Vertical Split
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
            final tx = transactions.firstWhere(
              (t) => t.id == selectedTxId,
              orElse: () => transactions[0],
            );
            if (tx.tags.isNotEmpty &&
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
  ) {
    final cashflowsFuture = ref.read(bankServiceProvider).fetchCashflows();

    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Cashflow Selector
          FutureBuilder<List<CashflowSeries>>(
            future: cashflowsFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final cashflows = snapshot.data!;
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
                            if (newValue != null) {
                              ref
                                  .read(currentCashflowProvider.notifier)
                                  .set(newValue);
                              ref.invalidate(bankTransactionListProvider);
                            }
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
              }
              return CircularProgressIndicator();
            },
          ),

          // Right: Actions
          Row(
            children: [
              // ALERT BUTTON
              TextButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const AlertsDialog(),
                  );
                },
                icon: Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orangeAccent,
                ),
                label: Text(
                  "1 Alert",
                  style: TextStyle(color: Colors.orangeAccent),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.orangeAccent.withOpacity(0.1),
                ),
              ),
              const SizedBox(width: 16),

              // LOAD DATA
              FilledButton.icon(
                onPressed: () async {
                  // Navigate to Loading Screen
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const apps_loading.LoadingScreen(),
                    ),
                  );
                  // Refresh after load
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
              const SizedBox(width: 8),

              // TOOLS MENU
              PopupMenuButton<String>(
                icon: const Icon(Icons.build),
                tooltip: "Tools",
                onSelected: (value) {
                  if (value == 'vendors') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const apps_vendors.VendorScreen(),
                      ),
                    );
                  }
                },
                itemBuilder: (BuildContext context) {
                  return [
                    const PopupMenuItem(
                      value: 'vendors',
                      child: Row(
                        children: [
                          Icon(Icons.label, color: Colors.grey),
                          SizedBox(width: 8),
                          Text("Vendor Editor"),
                        ],
                      ),
                    ),
                  ];
                },
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
