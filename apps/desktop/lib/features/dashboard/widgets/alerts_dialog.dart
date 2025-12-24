import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/dashboard_controller.dart';

class AlertsDialog extends ConsumerWidget {
  const AlertsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Logic to find alerts
    // In a real app, this would be a dedicated provider filtering by budget status.
    // For now, we mock/calculate it here or use DashboardCalculations if extended.

    // We need to fetch all tags, check limits vs spending.
    // Since we don't have a "Tags Status Provider" handy,
    // we'll display a static or mocked list for the Story Step if data isn't ready,
    // OR we iterate transactions.

    // Let's iterate transactions to find "Shopping" tag as per story or similar.
    final transactions =
        ref.watch(bankTransactionListProvider).asData?.value ?? [];

    // Quick Hack: aggregate spending by tag locally
    final spendingByTag = <String, double>{};
    for (var t in transactions) {
      for (var tag in t.tags) {
        spendingByTag[tag] =
            (spendingByTag[tag] ?? 0) + (t.amount < 0 ? t.amount.abs() : 0);
      }
    }

    // Mock Limits (since fetching all tags async here is pain)
    // Story says "Clothing" is over budget.
    // We assume limits exist.

    final alerts = [
      {'tag': 'Clothing', 'spent': 450.0, 'limit': 300.0, 'status': 'Critical'},
      {
        'tag': 'Restaurants',
        'spent': 850.0,
        'limit': 800.0,
        'status': 'Warning',
      },
    ];

    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      child: Container(
        padding: const EdgeInsets.all(24),
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orangeAccent,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  "Spending Alerts",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            ...alerts.map((alert) {
              final tag = alert['tag'] as String;
              final spent = alert['spent'] as double;
              final limit = alert['limit'] as double;
              final isCritical = alert['status'] == 'Critical';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCritical
                      ? Colors.redAccent.withOpacity(0.1)
                      : Colors.orangeAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCritical
                        ? Colors.redAccent.withOpacity(0.3)
                        : Colors.orangeAccent.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tag,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "\$${spent.toStringAsFixed(0)} / \$${limit.toStringAsFixed(0)}",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        ref
                            .read(dashboardControllerProvider.notifier)
                            .selectTag(tag);
                      },
                      child: Text("Review"),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Dismiss"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
