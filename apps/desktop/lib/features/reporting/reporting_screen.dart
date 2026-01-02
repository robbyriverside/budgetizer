import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/split_view.dart';
import 'reporting_controller.dart';

class ReportingScreen extends ConsumerStatefulWidget {
  const ReportingScreen({super.key});

  @override
  ConsumerState<ReportingScreen> createState() => _ReportingScreenState();
}

class _ReportingScreenState extends ConsumerState<ReportingScreen> {
  // Sorting state for the tag table
  int _sortColumnIndex = 1; // Default sort by Amount (index 1)
  bool _sortAscending = false; // Default desc

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(reportingControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Reporting"),
        actions: [
          reportAsync.when(
            data: (state) {
              return _buildHeaderActions(context, ref, state);
            },
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
        ],
      ),
      body: reportAsync.when(
        data: (state) => _buildBody(context, ref, state),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error: $err")),
      ),
    );
  }

  Widget _buildHeaderActions(
    BuildContext context,
    WidgetRef ref,
    ReportingState state,
  ) {
    return Row(
      children: [
        // Report Selector
        DropdownButton<String>(
          value: state.currentReportName,
          dropdownColor: Colors.grey[850],
          style: const TextStyle(color: Colors.white, fontSize: 16),
          underline: Container(),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.tealAccent),
          onChanged: (newValue) {
            if (newValue != null) {
              ref
                  .read(reportingControllerProvider.notifier)
                  .loadReport(newValue);
            }
          },
          items: state.availableReports.map((report) {
            return DropdownMenuItem(
              value: report,
              child: Text(report.toUpperCase()),
            );
          }).toList(),
        ),
        const SizedBox(width: 20),

        // Save Button (Always Visible)
        FilledButton.icon(
          onPressed: () => _handleSave(context, ref, state),
          icon: const Icon(Icons.save),
          label: const Text("Save Report"),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(width: 16),

        // Delete Button (Only if not default)
        if (state.currentReportName != 'All Budgets')
          IconButton(
            onPressed: () =>
                _handleDelete(context, ref, state.currentReportName),
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            tooltip: "Delete Report",
          ),

        if (state.currentReportName != 'All Budgets') const SizedBox(width: 16),
      ],
    );
  }

  Future<void> _handleSave(
    BuildContext context,
    WidgetRef ref,
    ReportingState state,
  ) async {
    // ... Save logic remains mostly same
    String? reportName = state.currentReportName;
    bool isDefaultBudget =
        reportName == 'All Budgets' || reportName == 'budget';
    // 'budget' legacy check

    if (isDefaultBudget) {
      final controller = TextEditingController(
        text: "Report ${DateTime.now().toString().split(' ')[0]}",
      );
      final newName = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Save Report As"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "The default 'All Budgets' report cannot be overwritten as it is dynamically generated.",
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                decoration: const InputDecoration(labelText: "Report Name"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text("Save"),
            ),
          ],
        ),
      );
      if (newName != null && newName.isNotEmpty) {
        if (newName == 'All Budgets' || newName == 'budget') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Cannot overwrite default report.")),
          );
          return;
        }
        reportName = newName;
      } else {
        return;
      }
    } else {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text("Overwrite '$reportName'?"),
          content: const Text("This will update the existing report."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel"),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Overwrite"),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    final success = await ref
        .read(reportingControllerProvider.notifier)
        .saveReport(reportName);

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Report '$reportName' saved.")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to save report '$reportName'."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleDelete(
    BuildContext context,
    WidgetRef ref,
    String reportName,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Delete '$reportName'?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref
          .read(reportingControllerProvider.notifier)
          .deleteReport(reportName);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Report '$reportName' deleted.")),
        );
      }
    }
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, ReportingState state) {
    // Prepare sorted list for bottom table
    final sortedTags = List<SpendingTag>.from(state.allTags);
    if (_sortColumnIndex == 0) {
      // Sort by Name
      sortedTags.sort(
        (a, b) => _sortAscending
            ? a.name.compareTo(b.name)
            : b.name.compareTo(a.name),
      );
    } else {
      // Sort by Amount
      sortedTags.sort(
        (a, b) => _sortAscending
            ? a.amount.compareTo(b.amount)
            : b.amount.compareTo(a.amount),
      );
    }

    return SplitView(
      axis: Axis.vertical,
      initialRatio: 0.6,
      minRatio: 0.3,
      // Top: Active Report Area (Drag Target)
      child1: DragTarget<String>(
        onWillAcceptWithDetails: (details) {
          // Only accept tags not already in list
          return !state.reportItems.any((i) => i.tagName == details.data);
        },
        onAcceptWithDetails: (details) {
          _handleTagDrop(context, ref, details.data, state);
        },
        builder: (context, candidateData, rejectedData) {
          return Container(
            // "Background should be off-white, like paper"
            // Using a warm off-white, e.g., Floral White or similar.
            color: candidateData.isNotEmpty
                ? Colors.teal.withValues(alpha: 0.1)
                : const Color(0xFFFAF9F6), // Off-white / Paper
            child: Column(
              children: [
                _buildSectionHeader(
                  "Active Report Items",
                  Icons.analytics,
                  isPaper: true,
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    buildDefaultDragHandles: false,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 24,
                    ),
                    itemCount: state.reportItems.length,
                    onReorder: (oldIndex, newIndex) {
                      ref
                          .read(reportingControllerProvider.notifier)
                          .reorderItems(oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      final item = state.reportItems[index];
                      // Key is required for ReorderableListView
                      return Container(
                        key: ValueKey(item.id),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: _buildReportRow(context, ref, item, index),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      // Bottom: Tag Table
      child2: Column(
        children: [
          _buildSectionHeader(
            "Available Tags",
            Icons.table_chart,
            isPaper: false,
          ),
          // We use a custom header row + ListView because standard DataTable rows aren't Draggable easily
          // Actually, we can use a Header Row and then a ListView of Draggable Rows
          _buildTableHeader(),
          Expanded(
            child: ListView.builder(
              itemCount: sortedTags.length,
              itemBuilder: (context, index) {
                final tag = sortedTags[index];
                return _buildDraggableTableRow(tag, index % 2 == 0);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ... (Header methods same)

  Widget _buildTableHeader() {
    return Material(
      color: Colors.grey[850],
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: InkWell(
                onTap: () => _updateSort(0),
                child: Row(
                  children: [
                    const Text(
                      "Tag Name",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (_sortColumnIndex == 0)
                      Icon(
                        _sortAscending
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        size: 16,
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: InkWell(
                onTap: () => _updateSort(1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text(
                      "Spending",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (_sortColumnIndex == 1)
                      Icon(
                        _sortAscending
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        size: 16,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateSort(int columnIndex) {
    setState(() {
      if (_sortColumnIndex == columnIndex) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumnIndex = columnIndex;
        _sortAscending = true;
      }
    });
  }

  Widget _buildDraggableTableRow(SpendingTag tag, bool isAlternating) {
    final rowContent = Container(
      color: isAlternating
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                if (tag.isBudgeted)
                  const Icon(Icons.check, size: 16, color: Colors.teal),
                const SizedBox(width: 8),
                Text(
                  tag.name,
                  style: TextStyle(
                    color: tag.isBudgeted ? Colors.grey : Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              "\$${tag.amount.toStringAsFixed(2)}",
              textAlign: TextAlign.right,
              style: TextStyle(
                color: tag.isBudgeted ? Colors.grey : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (tag.isBudgeted) return rowContent;

    return Draggable<String>(
      data: tag.name,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: 300,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black45)],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(tag.name),
              Text("\$${tag.amount.toStringAsFixed(2)}"),
            ],
          ),
        ),
      ),
      child: rowContent,
    );
  }

  void _handleTagDrop(
    BuildContext context,
    WidgetRef ref,
    String tagName,
    ReportingState state,
  ) {
    final tag = state.allTags.firstWhere((t) => t.name == tagName);

    // If has existing budget and frequency, use it
    if (tag.existingBudget != null) {
      ref
          .read(reportingControllerProvider.notifier)
          .addReportItem(
            tagName,
            tag.existingBudget!,
            tag.existingFrequency ?? BudgetFrequency.monthly,
          );
    } else {
      showDialog<BudgetResult>(
        context: context,
        builder: (ctx) => _SetBudgetDialog(tagName: tagName),
      ).then((result) {
        if (result != null) {
          ref
              .read(reportingControllerProvider.notifier)
              .addReportItem(tagName, result.amount, result.frequency);
        }
      });
    }
  }

  Widget _buildSectionHeader(
    String title,
    IconData icon, {
    required bool isPaper,
  }) {
    // If paper mode, use dark text on light bg. Else light text on dark bg.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: isPaper ? Colors.grey[200] : Colors.white10,
      width: double.infinity,
      child: Row(
        children: [
          Icon(icon, size: 20, color: isPaper ? Colors.black54 : Colors.grey),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isPaper ? Colors.black87 : Colors.white70,
              fontSize: 14,
            ),
          ),
          if (isPaper) ...[
            const Spacer(),
            const Text(
              "PRINT PREVIEW",
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReportRow(
    BuildContext context,
    WidgetRef ref,
    ReportItem item,
    int index,
  ) {
    // Single line: Fandle | Tag | Spending | Graph | Limit | Freq
    // On Paper: Black text.

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red.withValues(alpha: 0.1),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.red),
      ),
      onDismissed: (_) {
        ref
            .read(reportingControllerProvider.notifier)
            .removeReportItem(item.id);
      },
      child: Material(
        color: Colors.transparent, // Let paper bg show? Or white strip?
        // Let's make it look like a printed line or a very clean row.
        child: InkWell(
          onDoubleTap: () {
            showDialog<BudgetResult>(
              context: context,
              builder: (ctx) => _SetBudgetDialog(
                tagName: item.tagName,
                initialAmount: item.budgetAmount,
                initialFrequency: item.frequency,
              ),
            ).then((result) {
              if (result != null) {
                ref
                    .read(reportingControllerProvider.notifier)
                    .updateBudget(
                      item.tagName,
                      result.amount,
                      result.frequency,
                    );
              }
            });
          },
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.black12),
              ), // Divider
            ),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
            child: Row(
              children: [
                // 0. Drag Handle (Start)
                ReorderableDragStartListener(
                  index: index,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.grab,
                    child: const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Icon(
                        Icons.drag_indicator,
                        color: Colors.black26,
                        size: 20,
                      ),
                    ),
                  ),
                ),

                // 1. Tag Name
                Expanded(
                  flex: 3,
                  child: Text(
                    item.tagName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),

                // 2. Spending
                SizedBox(
                  width: 80,
                  child: Text(
                    "\$${item.actualAmount.toStringAsFixed(0)}",
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ),

                const SizedBox(width: 24),

                // 3. Graph (Minimal detail, ~200px)
                // "minimal data detail, and only needs a few hundred pixels in width"
                SizedBox(
                  width: 200,
                  height: 30, // Compact height
                  child: CustomPaint(
                    painter: BudgetChartPainter(
                      budget: item.budgetAmount,
                      spending: item.actualAmount,
                      frequency: item.frequency,
                    ),
                  ),
                ),

                const SizedBox(width: 24),

                // 4. Limit
                SizedBox(
                  width: 80,
                  child: Text(
                    "\$${item.budgetAmount.toStringAsFixed(0)}",
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ),

                const SizedBox(width: 16),

                // 5. Frequency
                SizedBox(
                  width: 60,
                  child: Text(
                    item.frequency.label,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),

                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BudgetResult {
  final double amount;
  final BudgetFrequency frequency;
  BudgetResult(this.amount, this.frequency);
}

class _SetBudgetDialog extends StatefulWidget {
  final String tagName;
  final double? initialAmount;
  final BudgetFrequency? initialFrequency;

  const _SetBudgetDialog({
    required this.tagName,
    this.initialAmount,
    this.initialFrequency,
  });

  @override
  State<_SetBudgetDialog> createState() => _SetBudgetDialogState();
}

class _SetBudgetDialogState extends State<_SetBudgetDialog> {
  late TextEditingController _controller;
  late BudgetFrequency _frequency;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialAmount?.toString() ?? '',
    );
    _frequency = widget.initialFrequency ?? BudgetFrequency.monthly;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Set Budget for ${widget.tagName}"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: const InputDecoration(
              prefixText: "\$ ",
              labelText: "Amount",
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<BudgetFrequency>(
            value: _frequency,
            decoration: const InputDecoration(labelText: "Frequency"),
            items: BudgetFrequency.values
                .map((f) => DropdownMenuItem(value: f, child: Text(f.label)))
                .toList(),
            onChanged: (val) {
              if (val != null) setState(() => _frequency = val);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        FilledButton(
          onPressed: () {
            final val = double.tryParse(_controller.text);
            if (val != null) {
              Navigator.pop(context, BudgetResult(val, _frequency));
            }
          },
          child: const Text("Set Budget"),
        ),
      ],
    );
  }
}

class BudgetChartPainter extends CustomPainter {
  final double budget;
  final double spending;
  final BudgetFrequency frequency;

  BudgetChartPainter({
    required this.budget,
    required this.spending,
    required this.frequency,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Minimal aesthetic for print
    final paint = Paint()..strokeWidth = 2; // Thinner lines

    // Limits
    final double maxW = size.width;
    // We assume the bar width represents the Budget Limit (100% capacity)
    // Or Time?
    // Previous logic: Width = Time?
    // User said: "minimal data detail... a few hundred pixels"
    // "Single line... starting with tag, then spending, followed by graph... finally limit"

    // Let's stick to the Bulletin-style chart or Timeline chart?
    // "vertical lines for each period... horizontal line for limit... horizontal line for spending"
    // This sounds like a Timeline view.

    // 1. Background Bar (Time / Period)
    paint.color = Colors.grey.withValues(alpha: 0.1);
    paint.style = PaintingStyle.fill;
    final barRect = Rect.fromLTWH(0, 5, maxW, size.height - 10);
    canvas.drawRect(barRect, paint);

    // 2. Vertical Dividers (Periods)
    paint.color = Colors.grey.withValues(alpha: 0.3);
    paint.style = PaintingStyle.stroke;

    // Edges
    canvas.drawLine(Offset(0, 5), Offset(0, size.height - 5), paint);
    canvas.drawLine(Offset(maxW, 5), Offset(maxW, size.height - 5), paint);

    int divisions = 1;
    if (frequency == BudgetFrequency.weekly) {
      divisions = 4;
    }

    if (divisions > 1) {
      final step = maxW / divisions;
      for (int i = 1; i < divisions; i++) {
        final x = step * i;
        canvas.drawLine(Offset(x, 5), Offset(x, size.height - 5), paint);
      }
    }

    // 3. Limit Line
    // "Horizontal line for limit"
    // If X is Time, Limit is constant rate.
    // Let's draw a thin Blue line across the top?
    paint.color = Colors.blue.withValues(alpha: 0.8);
    paint.strokeWidth = 2;
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(maxW, size.height / 2),
      paint,
    );

    // 4. Spending Line
    // "Horizontal line for spending"
    // Is spending accumulating over time?
    // Let's draw a thicker/colored line overlaid relative to % of budget consumed.
    // If user spent 50% of budget, draw line 50% width.
    double percent = budget > 0 ? spending / budget : 0.0;
    if (percent > 1.0) percent = 1.0; // Cap visual at 100% width? Or turn red?

    // If over budget, make red. Else green.
    paint.color = spending > budget ? Colors.red : Colors.green;
    paint.strokeWidth = 4;

    // Draw slightly offset or on top?
    // Let's draw it just below the Limit line
    final double y = size.height / 2 + 3;
    canvas.drawLine(Offset(0, y), Offset(maxW * percent, y), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
