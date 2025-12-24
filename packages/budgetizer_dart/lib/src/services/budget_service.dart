class BudgetPeriod {
  final DateTime startDate;
  final DateTime endDate;
  final double limit; // Pro-rated limit for this period

  BudgetPeriod({
    required this.startDate,
    required this.endDate,
    required this.limit,
  });

  /// Helper to check if a date falls within this period
  bool contains(DateTime date) {
    // Check Date only (ignore time)
    final d = DateTime(date.year, date.month, date.day);
    final s = DateTime(startDate.year, startDate.month, startDate.day);
    final e = DateTime(endDate.year, endDate.month, endDate.day);
    return (d.isAtSameMomentAs(s) || d.isAfter(s)) &&
        (d.isAtSameMomentAs(e) || d.isBefore(e));
  }

  @override
  String toString() {
    return 'BudgetPeriod(${startDate.day}-${endDate.day}, limit: ${limit.toStringAsFixed(2)})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BudgetPeriod &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.limit == limit;
  }

  @override
  int get hashCode => Object.hash(startDate, endDate, limit);
}

class BudgetService {
  /// Calculates the budget periods for a given [month] based on the [frequency] (in days)
  /// and the [baseLimit] (limit for a standard frequency period).
  ///
  /// [month]: The month to generate periods for (uses year and month).
  /// [frequency]: Number of days in a cycle. 0 means Monthly. Max is 15.
  /// [baseLimit]: The budget limit defined for the TAG's frequency.
  List<BudgetPeriod> calculatePeriods({
    required DateTime month,
    required int frequency,
    required double baseLimit,
  }) {
    // 1. Handle Monthly Case (freq = 0)
    final daysInMonth = _getDaysInMonth(month);

    if (frequency <= 0) {
      return [
        BudgetPeriod(
          startDate: DateTime(month.year, month.month, 1),
          endDate: DateTime(month.year, month.month, daysInMonth),
          limit: baseLimit,
        ),
      ];
    }

    // 2. Clamp frequency to Max 15 per spec
    // Note: Spec says max 15. If user passes > 15, we clamp or treat as error?
    // Let's assume we treat it as valid input but logically it shouldn't happen if UI blocks it.
    // If > 15, we can just treat it as 15 or let logic handle it (might produce 1 period).
    // Let's strictly follow "period is frequency days".

    List<BudgetPeriod> periods = [];
    int currentDay = 1;

    while (currentDay <= daysInMonth) {
      int endDay = currentDay + frequency - 1;
      bool isLastPeriod = false;

      // Check if this potential period extends beyond or touches the end of the month
      if (endDay >= daysInMonth) {
        endDay = daysInMonth;
        isLastPeriod = true;
      } else {
        // Look ahead: How many days are left after this period?
        int remainingDays = daysInMonth - endDay;
        // Rules:
        // "If the last period is less than half the number of days in the Tag cycle,
        // then the last period is added to the previous period."
        if (remainingDays < (frequency / 2.0)) {
          // Merge remainder into THIS period
          endDay = daysInMonth;
          isLastPeriod = true;
        }
      }

      // Create the period
      final startDate = DateTime(month.year, month.month, currentDay);
      final endDate = DateTime(month.year, month.month, endDay);

      // Pro-rate Limit
      // "The system handles overlapping Tag cycles by pro-rating the Tag limit."
      // Formula: (Actual Days / Frequency) * Base Limit
      int actualDays = endDay - currentDay + 1;
      double proratedLimit = (actualDays / frequency) * baseLimit;

      periods.add(
        BudgetPeriod(
          startDate: startDate,
          endDate: endDate,
          limit: proratedLimit,
        ),
      );

      if (isLastPeriod) break;
      currentDay = endDay + 1;
    }

    return periods;
  }

  int _getDaysInMonth(DateTime date) {
    // Jump to next month day 0 (which is last day of current month)
    return DateTime(date.year, date.month + 1, 0).day;
  }
}
