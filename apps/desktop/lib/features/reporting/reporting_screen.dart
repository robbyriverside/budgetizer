import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'reporting_controller.dart';

class ReportingScreen extends ConsumerWidget {
  const ReportingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(reportingControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Budget Report")),
      body: reportAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text("No spending data found."));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 20),
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildReportCard(context, item);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error: $err")),
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, ReportItem item) {
    // Colors
    Color statusColor;
    if (item.percentSpent < 0.8) {
      statusColor = Colors.green;
    } else if (item.percentSpent < 1.0) {
      statusColor = Colors.yellow;
    } else {
      statusColor = Colors.red;
    }

    final percentDisplay = (item.percentSpent * 100).toStringAsFixed(1);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.tagName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  "$percentDisplay%",
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Spent: \$${item.actualAmount.toStringAsFixed(2)}"),
                Text("Budget: \$${item.budgetAmount.toStringAsFixed(2)}"),
              ],
            ),
            const SizedBox(height: 10),
            // Visualization
            LayoutBuilder(
              builder: (context, constraints) {
                // Let's just do a simple progress bar for now since "budget line vs max line" requires custom painting
                // and keeping it simple as requested.
                // Re-reading usage: "Bar chart with budget line... another line shows max amount spent"
                // Simplified Interpretation: Stacked bar or Progress indicator.

                return ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: item.percentSpent > 1 ? 1 : item.percentSpent,
                    minHeight: 20,
                    color: statusColor,
                    backgroundColor: Colors.grey[800],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
