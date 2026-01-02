import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgetizer/features/reporting/reporting_controller.dart';
import 'package:budgetizer/core/services/bank_service.dart'; // Exports budgetizer_dart entities and provides bankServiceProvider
import 'package:budgetizer/core/services/tag_service.dart';
import 'package:budgetizer/features/dashboard/controllers/dashboard_controller.dart';

// Mock BankService - Fully implemented
class MockBankService implements BankService {
  List<BankTransaction> _transactions = [];

  MockBankService();

  @override
  bool get isConnected => true;

  @override
  Future<List<BankTransaction>> fetchTransactions(String cashflowId) async {
    return _transactions;
  }

  @override
  Future<void> updateTransaction(BankTransaction transaction) async {
    final index = _transactions.indexWhere((t) => t.id == transaction.id);
    if (index != -1) {
      _transactions[index] = transaction;
    }
  }

  void setTransactions(List<BankTransaction> txs) {
    _transactions = txs;
  }

  @override
  Future<Map<String, dynamic>> analyzeTransaction(String description) async =>
      {};

  @override
  Future<String> createLinkToken() async => 'mock_token';

  @override
  Future<void> exchangePublicToken(String publicToken) async {}

  @override
  Future<List<CashflowSeries>> fetchCashflows() async => [];

  @override
  Future<List<Tag>> fetchTags() async => [];

  @override
  Future<void> importTransactions(List<BankTransaction> transactions) async {}

  @override
  Future<void> updateTag(Tag tag) async {}
}

// Mock TagService
class MockTagService extends TagService {
  @override
  Future<TagState> build() async {
    return TagState(tags: [], changes: []);
  }

  @override
  Future<TagState> fetchTags() async {
    return TagState(tags: [], changes: []);
  }
}

void main() {
  test('ReportingController updates when transaction tags change', () async {
    final mockBankService = MockBankService();
    // We override the provider not the service class itself directly in overrideWith usually requires a function returning the Notifier.

    final container = ProviderContainer(
      overrides: [
        bankServiceProvider.overrideWithValue(mockBankService),
        tagServiceProvider.overrideWith(() => MockTagService()),
      ],
    );

    // 1. Setup Initial Data
    final tx1 = BankTransaction(
      id: 'tx1',
      date: DateTime.now(),
      amount: -100.0,
      description: 'Test Expense',
      vendorName: 'Unknown Vendor',
      tags: ['Groceries'], // STARTING TAG
      pending: false,
      cashflowId: 'checking_1',
    );
    mockBankService.setTransactions([tx1]);

    // 2. Read Initial Report
    // Listen to keep alive
    container.listen(reportingControllerProvider, (_, __) {});

    // Initial fetch
    await container.read(reportingControllerProvider.future);
    var reportingState = container.read(reportingControllerProvider).value!;

    // Check Groceries spending
    final groceriesTagInitial = reportingState.allTags.firstWhere(
      (t) => t.name == 'Groceries',
      orElse: () => SpendingTag(name: 'Groceries', amount: 0),
    );

    print('DEBUG: Initial Groceries Spending: ${groceriesTagInitial.amount}');
    expect(
      groceriesTagInitial.amount,
      100.0,
      reason: 'Initial Groceries spending should be 100.0',
    );

    // 3. Modify Transaction (Change tag from Groceries to Dining)
    print('DEBUG: Changing transaction tag from Groceries to Dining...');
    final updatedTx = tx1.copyWith(tags: ['Dining']);
    await mockBankService.updateTransaction(updatedTx);

    // Invalidate the transactions list provider explicitly
    // This simulates what DashboardController calls: ref.invalidate(bankTransactionListProvider);
    container.invalidate(bankTransactionListProvider);

    // 4. Wait for Report Update
    // We expect reportingController to watch bankTransactionListProvider, so it should rebuild.
    await container.read(reportingControllerProvider.future);
    reportingState = container.read(reportingControllerProvider).value!;

    // 5. Verify Groceries is now 0.0
    final groceriesTagAfter = reportingState.allTags.firstWhere(
      (t) => t.name == 'Groceries',
      orElse: () => SpendingTag(name: 'Groceries', amount: 0),
    );

    print(
      'DEBUG: Groceries Spending After Update: ${groceriesTagAfter.amount}',
    );

    expect(
      groceriesTagAfter.amount,
      0.0,
      reason: 'Groceries spending should be 0.0 after tag change',
    );
  });
}
