import 'package:test/test.dart';
import 'package:budgetizer/core/services/budget_service.dart';

void main() {
  late BudgetService service;

  setUp(() {
    service = BudgetService();
  });

  group('BudgetService - Monthly (Freq 0)', () {
    test('Calculates monthly period correctly for 30-day month', () {
      final month = DateTime(2023, 11); // November = 30 days
      final periods = service.calculatePeriods(
        month: month,
        frequency: 0,
        baseLimit: 1000,
      );

      expect(periods.length, 1);
      expect(periods.first.startDate, DateTime(2023, 11, 1));
      expect(periods.first.endDate, DateTime(2023, 11, 30));
      expect(periods.first.limit, 1000.0);
    });

    test('Calculates monthly period correctly for 31-day month', () {
      final month = DateTime(2023, 10); // October = 31 days
      final periods = service.calculatePeriods(
        month: month,
        frequency: 0,
        baseLimit: 500,
      );

      expect(periods.length, 1);
      expect(periods.first.endDate.day, 31);
      expect(periods.first.limit, 500.0);
    });
  });

  group('BudgetService - Frequency 15 (Half Month)', () {
    test('Exact Split: 30 days / 15 freq = 2 periods', () {
      final month = DateTime(2023, 11); // Nov = 30
      final periods = service.calculatePeriods(
        month: month,
        frequency: 15,
        baseLimit: 1500, // $100 per day roughly
      );

      expect(periods.length, 2);

      // Period 1: Days 1-15
      expect(periods[0].startDate.day, 1);
      expect(periods[0].endDate.day, 15);
      expect(periods[0].limit, 1500.0); // Full limit

      // Period 2: Days 16-30 (15 days)
      expect(periods[1].startDate.day, 16);
      expect(periods[1].endDate.day, 30);
      expect(periods[1].limit, 1500.0); // Full limit
    });

    test('Merge Remainder: 31 days / 15 freq', () {
      // 31 / 15 => 2 remain 1.
      // 1 < 7.5 (half of 15). So should merge to last.
      // Expect 2 periods: 1-15, 16-31.
      final month = DateTime(2023, 10); // Oct = 31
      final periods = service.calculatePeriods(
        month: month,
        frequency: 15,
        baseLimit: 150.0,
      );

      expect(periods.length, 2);

      // Period 1: 15 days
      expect(periods[0].endDate.day, 15);
      expect(periods[0].limit, 150.0);

      // Period 2: 16 days (16-31)
      expect(periods[1].startDate.day, 16);
      expect(periods[1].endDate.day, 31);
      // Prorated: (16 / 15) * 150 = 160
      expect(periods[1].limit, 160.0);
    });
  });

  group('BudgetService - Weekly (Freq 7)', () {
    test('Standard Month (30 days)', () {
      // 30 / 7 => 4 remain 2.
      // 2 < 3.5. Merge to last.
      // Expected:
      // 1: 1-7 (7)
      // 2: 8-14 (7)
      // 3: 15-21 (7)
      // 4: 22-30 (9) -- Merged
      final month = DateTime(2023, 11);
      final periods = service.calculatePeriods(
        month: month,
        frequency: 7,
        baseLimit: 70.0,
      );

      expect(periods.length, 4);
      expect(periods.last.endDate.day, 30);
      // Last period length = 9 days. Limit = 9/7 * 70 = 90.
      expect(periods.last.limit, 90.0);
    });
  });

  group('BudgetService - Complex Remainder Logic', () {
    test('Long Remainder: 30 days / 8 freq', () {
      // 30 / 8 => 3 remain 6.
      // 6 > 4 (half of 8). Independent period.
      // Expected:
      // 1: 1-8
      // 2: 9-16
      // 3: 17-24
      // 4: 25-30 (6 days)
      final month = DateTime(2023, 11); // Nov 30
      final periods = service.calculatePeriods(
        month: month,
        frequency: 8,
        baseLimit: 80.0,
      );

      expect(periods.length, 4);

      // Period 3
      expect(periods[2].endDate.day, 24);

      // Period 4 (Standalone)
      expect(periods[3].startDate.day, 25);
      expect(periods[3].endDate.day, 30);
      // Limit: 6/8 * 80 = 60
      expect(periods[3].limit, 60.0);
    });

    test('Short Remainder Case: 30 days / 13 freq', () {
      // 30 / 13 => 2 remain 4.
      // 4 < 6.5. Merge.
      // Expected:
      // 1: 1-13 (13 days)
      // 2: 14-30 (17 days)
      final periods = service.calculatePeriods(
        month: DateTime(2023, 11),
        frequency: 13,
        baseLimit: 130.0,
      );

      expect(periods.length, 2);
      expect(periods[1].startDate.day, 14);
      expect(periods[1].endDate.day, 30);
      // Limit: 17/13 * 130 = 170
      expect(periods[1].limit, 170.0);
    });
  });

  group('BudgetService - Leap Year Edge Cases', () {
    test('Feb Leap Year (29 days) - Weekly', () {
      // 2024 is leap year. Feb = 29.
      // 29 / 7 => 4 remain 1.
      // 1 < 3.5. Merge.
      // Last period should be 1 + 7 + 1 = 8 days? No.
      // 1-7, 8-14, 15-21...
      // Previous Iteration 3: 15-21. Next Start 22.
      // Iteration 4: 22-28. Remainder 1 (Day 29).
      // 29 - 28 = 1. 1 < 3.5.
      // So period 4 becomes 22-29 (8 days).
      final periods = service.calculatePeriods(
        month: DateTime(2024, 2),
        frequency: 7,
        baseLimit: 70.0,
      );

      expect(periods.length, 4);
      expect(periods.last.endDate.day, 29);
      expect(periods.last.limit, 80.0);
    });

    test('Feb Non-Leap (28 days) - Weekly', () {
      // 28 / 7 => 4 exact.
      final periods = service.calculatePeriods(
        month: DateTime(2023, 2),
        frequency: 7,
        baseLimit: 70.0,
      );

      expect(periods.length, 4);
      expect(periods.last.endDate.day, 28);
      expect(periods.last.limit, 70.0);
    });
  });
}
