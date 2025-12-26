import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../dashboard/controllers/dashboard_controller.dart';

part 'reporting_controller.g.dart';

@riverpod
class ReportingController extends _$ReportingController {
  @override
  Future<List<ReportItem>> build() async {
    final transactions = await ref.watch(bankTransactionListProvider.future);

    // Aggregate by tag
    final Map<String, double> actuals = {};
    for (var tx in transactions) {
      if (tx.amount < 0 && tx.tags.isNotEmpty) {
        // Assume first tag is primary for budget
        final tag = tx.tags.first;
        actuals[tag] = (actuals[tag] ?? 0) + tx.amount.abs();
      }
    }

    // Mock Budget limits for demo (since we don't have a BudgetService yet)
    final budgets = {
      'Groceries': 500.0,
      'Dining': 300.0,
      'Transport': 200.0,
      'Entertainment': 100.0,
      'Utilities': 250.0,
    };

    final List<ReportItem> items = [];
    actuals.forEach((tag, actual) {
      final budget = budgets[tag] ?? 0;
      if (actual > 0) {
        items.add(
          ReportItem(tagName: tag, budgetAmount: budget, actualAmount: actual),
        );
      }
    });

    // Sort by % spent (descending)
    items.sort((a, b) => b.percentSpent.compareTo(a.percentSpent));

    return items;
  }
}

class ReportItem {
  final String tagName;
  final double budgetAmount;
  final double actualAmount;

  ReportItem({
    required this.tagName,
    required this.budgetAmount,
    required this.actualAmount,
  });

  double get percentSpent => budgetAmount == 0
      ? (actualAmount > 0 ? 100.0 : 0)
      : (actualAmount / budgetAmount);
}
