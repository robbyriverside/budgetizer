import 'dart:math';
import '../models/financial_entities.dart';

/// Service to generate realistic mock transaction data for user testing.
/// Generates 2.5 months of data (M-2, M-1, and first 18 days of M).
class MockTransactionGenerator {
  final Random _random;

  MockTransactionGenerator({int? seed}) : _random = Random(seed ?? 42);

  /// Generates a list of bank transactions spanning from 2 months ago to the current date.
  /// [referenceDate] defaults to DateTime.now() if not provided.
  List<BankTransaction> generateTransactions({DateTime? referenceDate}) {
    final now = referenceDate ?? DateTime.now();
    // Start from the 1st of M-2
    // e.g. if now is Dec 23, M-2 is Oct. Start from Oct 1.
    // Actually, user wants "2 months of previous-month transactions".
    // Let's interpret: Full Month M-2, Full Month M-1, and days 1-18 of Month M.

    final currentMonthStart = DateTime(now.year, now.month, 1);
    final mMinus1Start = DateTime(now.year, now.month - 1, 1);
    final mMinus2Start = DateTime(now.year, now.month - 2, 1);

    final transactions = <BankTransaction>[];

    // Generate for Month M-2
    transactions
        .addAll(_generateMonthTransactions(mMinus2Start, isPartial: false));

    // Generate for Month M-1
    transactions
        .addAll(_generateMonthTransactions(mMinus1Start, isPartial: false));

    // Generate for Month M (partial, up to 18th)
    transactions.addAll(_generateMonthTransactions(currentMonthStart,
        isPartial: true, limitDay: 18));

    // Sort by date descending (newest first)
    transactions.sort((a, b) => b.date.compareTo(a.date));

    return transactions;
  }

  List<BankTransaction> _generateMonthTransactions(DateTime startOfMonth,
      {required bool isPartial, int limitDay = 31}) {
    final transactions = <BankTransaction>[];
    final year = startOfMonth.year;
    final month = startOfMonth.month;

    // Determine last day to generate for
    final daysInMonth = _getDaysInMonth(year, month);
    final lastDay = isPartial ? min(limitDay, daysInMonth) : daysInMonth;

    // 1. Recurring Transactions (Fixed Dates)

    // Rent: 1st of month
    if (lastDay >= 1) {
      transactions.add(_createTx(year, month, 1, "Rent Payment", "Landlord Inc",
          -2500.0, ["Housing", "Rent", "Service"]));
    }

    // Salary: 1st and 15th
    if (lastDay >= 1) {
      transactions.add(_createTx(year, month, 1, "Direct Deposit - Salary",
          "Tech Corp", 4000.0, ["Income", "Salary"]));
    }
    if (lastDay >= 15) {
      transactions.add(_createTx(year, month, 15, "Direct Deposit - Salary",
          "Tech Corp", 4000.0, ["Income", "Salary"]));
    }

    // Utilities: ~10th
    if (lastDay >= 10) {
      final amount = -120.0 - _random.nextDouble() * 50.0; // 120-170
      transactions.add(_createTx(year, month, 10, "Electric Bill", "City Power",
          amount, ["Utilities", "Service"]));
    }

    // Internet: ~12th
    if (lastDay >= 12) {
      transactions.add(_createTx(year, month, 12, "Internet Service", "Comcast",
          -89.99, ["Utilities", "Internet", "Service"]));
    }

    // Subscription: ~5th
    if (lastDay >= 5) {
      transactions.add(_createTx(year, month, 5, "Netflix Subscription",
          "Netflix", -15.99, ["Entertainment", "Subscription", "Service"]));
    }

    // Subscription: ~20th
    if (lastDay >= 20) {
      transactions.add(_createTx(year, month, 20, "Spotify Premium", "Spotify",
          -11.99, ["Entertainment", "Subscription", "Service"]));
    }

    // 2. Variable Transactions (Randomized Dates)
    // Groceries: ~Weekly (e.g. 4 times a month)
    // We'll try to scatter them.
    for (int i = 0; i < 5; i++) {
      // Attempt up to 5 times
      final day =
          2 + i * 7 + _random.nextInt(3); // vaguely weekly: 2, 9, 16, 23
      if (day <= lastDay) {
        final amount = -50.0 - _random.nextDouble() * 150.0; // 50-200
        final vendor =
            ["Whole Foods", "Trader Joe's", "Safeway"][_random.nextInt(3)];
        transactions.add(_createTx(year, month, day, "Grocery Purchase", vendor,
            amount, ["Groceries", "Food", "Store"]));
      }
    }

    // Dining Out: ~Randomly 6-8 times
    int diningCount = 6 + _random.nextInt(3);
    for (int i = 0; i < diningCount; i++) {
      final day = 1 + _random.nextInt(lastDay);
      final amount = -15.0 - _random.nextDouble() * 60.0; // 15-75
      final vendor = [
        "Chipotle",
        "Olive Garden",
        "Local Cafe",
        "Sushi Place",
        "Burger King"
      ][_random.nextInt(5)];
      transactions.add(_createTx(year, month, day, "Restaurant Payment", vendor,
          amount, ["Dining", "Food", "Restaurant"]));
    }

    // Clothes / Shopping: ~Randomly 1-2 times
    int shoppingCount = 1 + _random.nextInt(2);
    for (int i = 0; i < shoppingCount; i++) {
      final day = 1 + _random.nextInt(lastDay);
      final amount = -40.0 - _random.nextDouble() * 100.0; // 40-140
      final vendor = ["Zara", "H&M", "Uniqlo", "Target"][_random.nextInt(4)];
      transactions.add(_createTx(year, month, day, "Clothing Purchase", vendor,
          amount, ["Shopping", "Clothing", "Store"]));
    }

    // Coffee: ~Randomly 10-15 times
    int coffeeCount = 10 + _random.nextInt(6);
    for (int i = 0; i < coffeeCount; i++) {
      final day = 1 + _random.nextInt(lastDay);
      final amount = -4.0 - _random.nextDouble() * 4.0; // 4-8
      final vendor =
          ["Starbucks", "Peet's Coffee", "Philz Coffee"][_random.nextInt(3)];
      transactions.add(_createTx(year, month, day, "Coffee Shop", vendor,
          amount, ["Dining", "Coffee", "Market"]));
    }

    // System/Bank Fees: Occasional
    if (_random.nextDouble() < 0.3 && lastDay >= 28) {
      // 30% chance
      transactions.add(_createTx(year, month, 28, "Monthly Maintenance Fee",
          "Bank", -5.00, ["Fees", "System"]));
    }

    return transactions;
  }

  BankTransaction _createTx(int year, int month, int day, String desc,
      String vendor, double amount, List<String> tags) {
    // Ensure 2 decimal places logic if strictly needed, but double is fine.
    // Create consistent ID
    final date = DateTime(year, month, day);
    final id = "mock_${year}_${month}_${day}_${desc.hashCode}_${amount.abs()}";

    return BankTransaction(
      id: id,
      date: date,
      description: desc,
      vendorName: vendor,
      amount: double.parse(amount.toStringAsFixed(2)),
      tags: tags,
      pending: false, // Mock data is usually posted
      cashflowId: "mock_checking",
      isInitialized: true,
    );
  }

  int _getDaysInMonth(int year, int month) {
    if (month == 12) return DateTime(year + 1, 1, 0).day;
    return DateTime(year, month + 1, 0).day;
  }
}
