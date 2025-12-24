import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/bank_service.dart';

// 1. Dashboard State
class DashboardState {
  final Set<String> selection;
  final String? selectedTag;

  const DashboardState({required this.selection, this.selectedTag});

  DashboardState copyWith({Set<String>? selection, String? selectedTag}) {
    return DashboardState(
      selection: selection ?? this.selection,
      selectedTag: selectedTag,
    );
  }
}

// 2. Dashboard Controller
class DashboardController extends Notifier<DashboardState> {
  @override
  DashboardState build() {
    return const DashboardState(selection: {}, selectedTag: null);
  }

  void selectTransaction(String id, {bool multiSelect = false}) {
    var newSelection = {...state.selection};

    if (multiSelect) {
      if (newSelection.contains(id)) {
        newSelection.remove(id);
      } else {
        newSelection.add(id);
      }
    } else {
      newSelection = {id};
    }
    state = state.copyWith(selection: newSelection, selectedTag: null);
  }

  void selectTag(String? tagName) {
    state = state.copyWith(selectedTag: tagName);
  }

  void clearSelection() {
    state = const DashboardState(selection: {}, selectedTag: null);
  }

  Future<void> initializeTransaction({
    required String id,
    required List<String> tags,
  }) async {
    final service = ref.read(bankServiceProvider);
    final currentList =
        ref.read(bankTransactionListProvider).asData?.value ?? [];

    final tx = currentList.firstWhere((t) => t.id == id);

    // Initial tags become the "active tags"
    // For V1, we just overwrite tags. In real model, we might keep "auto tags" separate.
    final updatedTx = tx.copyWith(isInitialized: true, tags: tags);

    await service.updateTransaction(updatedTx);
    ref.invalidate(bankTransactionListProvider);
  }

  Future<void> removeTagFromTransaction(
    String transactionId,
    String tag,
  ) async {
    final service = ref.read(bankServiceProvider);
    final currentList =
        ref.read(bankTransactionListProvider).asData?.value ?? [];

    final tx = currentList.firstWhere((t) => t.id == transactionId);

    // UI Logic: Cannot remove the Vendor Name if it's treated as a tag?
    // User story says: "User removes details... but Vendor might remain"
    // We treat tags as mutable set.
    final index = tx.tags.indexOf(tag);
    if (index == 0) return; // Vendor tag is immutable

    final updatedTags = List<String>.from(tx.tags)..remove(tag);
    final updatedRemoved = List<String>.from(tx.removedTags)..add(tag);

    final updatedTx = tx.copyWith(
      tags: updatedTags,
      removedTags: updatedRemoved,
    );

    await service.updateTransaction(updatedTx);
    ref.invalidate(bankTransactionListProvider);
  }

  Future<void> addTagToTransaction(String transactionId, String tag) async {
    final service = ref.read(bankServiceProvider);
    final currentList =
        ref.read(bankTransactionListProvider).asData?.value ?? [];

    final tx = currentList.firstWhere((t) => t.id == transactionId);
    final updatedTags = List<String>.from(tx.tags)..add(tag);
    final updatedRemoved = List<String>.from(tx.removedTags)
      ..remove(tag); // Remove from removed list if adding back

    final updatedTx = tx.copyWith(
      tags: updatedTags,
      removedTags: updatedRemoved,
    );

    await service.updateTransaction(updatedTx);
    ref.invalidate(bankTransactionListProvider);
  }

  // restoreVendorTags removed as it conflicts with new persistent "removedTags" model

  Future<void> updateTagLimit(
    String tagName,
    double? limit,
    int? frequency,
  ) async {
    final service = ref.read(bankServiceProvider);
    final tags = await service.fetchTags();
    final existingTag = tags.firstWhere(
      (t) => t.name == tagName,
      orElse: () => Tag(name: tagName),
    );

    final updatedTag = existingTag.copyWith(
      budgetLimit: limit,
      frequency: frequency,
    );
    await service.updateTag(updatedTag);
  }
}

// 3. Providers using Standard Syntax
final dashboardControllerProvider =
    NotifierProvider<DashboardController, DashboardState>(
      DashboardController.new,
    );

// Current Cashflow Provider
class CurrentCashflowNotifier extends Notifier<String> {
  @override
  String build() => 'checking_1';

  void set(String id) => state = id;
}

final currentCashflowProvider =
    NotifierProvider<CurrentCashflowNotifier, String>(
      CurrentCashflowNotifier.new,
    );

// Bank Transaction List Provider
final bankTransactionListProvider = FutureProvider<List<BankTransaction>>((
  ref,
) async {
  final service = ref.watch(bankServiceProvider);
  final cashflowId = ref.watch(currentCashflowProvider);
  return service.fetchTransactions(cashflowId);
});

// Derived Provider for Calculations
final dashboardCalculationsProvider = Provider<Map<String, double>>((ref) {
  final transactions =
      ref.watch(bankTransactionListProvider).asData?.value ?? [];
  final dashboardState = ref.watch(dashboardControllerProvider);
  final selection = dashboardState.selection;

  // If selection is empty, use ALL transactions. Otherwise use SELECTED.
  final targetTransactions = selection.isEmpty
      ? transactions
      : transactions.where((t) => selection.contains(t.id)).toList();

  double income = 0;
  double expense = 0;

  for (var t in targetTransactions) {
    if (t.amount < 0) {
      income += t.amount.abs();
    } else {
      expense += t.amount;
    }
  }

  return {'income': income, 'expense': expense, 'net': income - expense};
});
