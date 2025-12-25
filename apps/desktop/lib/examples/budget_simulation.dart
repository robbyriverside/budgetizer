import 'package:budgetizer_dart/budgetizer_dart.dart';

void main() {
  print("=== Budget Logic & Tag Indexing Simulation (Step 6) ===\n");

  // 1. Setup Services
  final budgetService = BudgetService();
  final store = TransactionStore();

  // 2. Define Scenario
  // Requirement: 31-Day Month, Frequency 7 Days.
  // Month: October 2023 (31 Days)
  final month = DateTime(2023, 10);
  const tagName = "Groceries";
  const double weeklyLimit = 100.0;
  const int frequency = 7;

  print("Scenario Configuration:");
  print("  Month: ${month.year}-${month.month} (31 Days)");
  print("  Tag: $tagName");
  print(
    "  Base Limit: \$${weeklyLimit.toStringAsFixed(2)} / ${frequency} days",
  );
  print("------------------------------------------------------\n");

  // 3. Calculate Periods
  // Expected:
  // 1-7, 8-14, 15-21, 22-31 (Merged 10 days because remainder 3 < 3.5)
  // Limit for last period: 10/7 * 100 = 142.86
  final periods = budgetService.calculatePeriods(
    month: month,
    frequency: frequency,
    baseLimit: weeklyLimit,
  );

  print("Calculated Budget Periods:");
  for (int i = 0; i < periods.length; i++) {
    print("  Period ${i + 1}: ${periods[i]}");
  }
  print("\n------------------------------------------------------\n");

  // 4. Simulate Weeks Loading
  // We will simulate time passing by day 5, 12, 19, 26, 31.

  // Helper to generate transaction
  BankTransaction makeTx(int day, double amount, String desc) {
    return BankTransaction(
      id: "tx_${day}_$desc",
      date: DateTime(month.year, month.month, day),
      description: desc,
      vendorName: "Store",
      amount:
          amount, // Negative for expense? Model says abs() usually, let's use positive for expense here or adjust logic.
      // Logic in app treats negative as expense usually.
      // Let's stick to: Negative = Expense
      tags: [tagName, "Store"],
      pending: false,
      cashflowId: "checking",
    );
  }

  final checkDates = [5, 12, 19, 26, 31];
  final transactionsBatches = [
    // Week 1 (Day 1-7): Spent $50
    [makeTx(2, -20.0, "Milk"), makeTx(5, -30.0, "Bread")],
    // Week 2 (Day 8-14): Spent $110 (Over $100 limit!)
    [makeTx(9, -60.0, "Steak"), makeTx(13, -50.0, "Wine")],
    // Week 3 (Day 15-21): Spent $20
    [makeTx(16, -20.0, "Snacks")],
    // Week 4 Part 1 (22-28): Spent $80
    [makeTx(23, -80.0, "Bulk Buy")],
    // Week 4 Extended (29-31): Spent $40
    [makeTx(30, -40.0, "Last Minute")],
  ];

  for (int i = 0; i < checkDates.length; i++) {
    int currentDay = checkDates[i];
    print("\n>>> SIMULATING TIME: Day $currentDay <<<");

    // Load transactions for this batch
    if (i < transactionsBatches.length) {
      print("  [Loading new transactions...]");
      store.addAll(transactionsBatches[i]);
    }

    // Identify Current Period
    final currentDate = DateTime(month.year, month.month, currentDay);
    final currentPeriod = periods.firstWhere(
      (p) => p.contains(currentDate),
      orElse: () => periods.last,
    );

    // Fetch Transactions for Tag from Index (O(1) Step 6)
    final allTagTransactions = store.getTransactionsByTag(tagName);

    // Filter for current Period
    // Note: In real app, we might optimize this query further, but filtering list is fine here.
    final currentPeriodTx = allTagTransactions
        .where((t) => currentPeriod.contains(t.date))
        .toList();

    double totalSpent = 0;
    for (var t in currentPeriodTx) {
      if (t.amount < 0) totalSpent += t.amount.abs();
    }

    final variance = currentPeriod.limit - totalSpent;

    print(
      "  Active Period: ${currentPeriod.startDate.day}-${currentPeriod.endDate.day}",
    );
    print("  Budget Limit : \$${currentPeriod.limit.toStringAsFixed(2)}");
    print("  Spent so far : \$${totalSpent.toStringAsFixed(2)}");
    print("  Remaining    : \$${variance.toStringAsFixed(2)}");

    if (variance < 0) {
      print(
        "  STATUS       : 🚨 OVER BUDGET by \$${variance.abs().toStringAsFixed(2)}",
      );
    } else {
      print("  STATUS       : ✅ ON TRACK");
    }
  }

  print("\n=== Simulation Complete ===");
}
