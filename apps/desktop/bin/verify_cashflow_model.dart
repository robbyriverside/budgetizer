import 'package:budgetizer_dart/budgetizer_dart.dart';

void main() {
  print("Verifying Cashflow Models...");

  // 1. Create a Cycle
  final cycle = Cycle(startDate: DateTime(2025, 1, 1));
  print("Cycle created: ${cycle.startDate}");

  // 2. Create a CashflowSeries (Account)
  final series = CashflowSeries(
    id: 'checking_1',
    name: 'Main Checking',
    type: CashflowType.checking,
    balance: 5000.00,
  );
  print(
    "CashflowSeries created: ${series.name} (${series.type}) - Balance: \$${series.balance}",
  );

  // 3. Create a Cashflow (Period) linked to the series
  final cashflowPeriod = Cashflow(
    id: 'checking_1_jan_2025',
    seriesId: series.id,
    cycle: cycle,
    openingBalance: 4000.0,
    closingBalance: 5000.0,
  );

  print("Cashflow Period created: ${cashflowPeriod.id}");
  print("  -> Linked to Series: ${cashflowPeriod.seriesId}");
  print("  -> Opening Balance: ${cashflowPeriod.openingBalance}");

  // Validation
  assert(cashflowPeriod.seriesId == series.id);
  assert(cashflowPeriod.cycle.startDate.year == 2025);

  print("\nVerification Successful!");
}
