import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/services/bank_service.dart';

part 'dashboard_controller.g.dart';

@riverpod
class DashboardController extends _$DashboardController {
  @override
  DashboardState build() {
    return DashboardState(selection: {}, selectedTag: null);
  }

  void selectTransaction(String id, {bool multiSelect = false}) {
    var newSelection = {...state.selection};

    if (multiSelect) {
      // Toggle logic
      if (newSelection.contains(id)) {
        newSelection.remove(id);
      } else {
        newSelection.add(id);
      }
    } else {
      // Single select logic
      // If clicking already selected item (and it's the only one), could toggle off?
      // User request says "default to single select". Usually clicking selected item keeps it selected.
      // But clicking a *different* item clears others.
      newSelection = {id};
    }

    // Always clear tag selection on transaction selection change
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

    final updatedTx = tx.copyWith(isInitialized: true, tags: tags);

    // Update Mock Service
    await service.updateTransaction(updatedTx);

    // Refresh List
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

    // Guard: Cannot remove the first tag (Vendor Tag) with current logic?
    // Actually, tags.indexOf(tag) would find it.
    // If the tag being removed is at index 0, abort.
    final index = tx.tags.indexOf(tag);
    if (index == 0) {
      // Vendor tag is immutable
      return;
    }

    final updatedTags = List<String>.from(tx.tags)..remove(tag);

    final updatedTx = tx.copyWith(tags: updatedTags);

    await service.updateTransaction(updatedTx);
    ref.invalidate(bankTransactionListProvider);
  }

  Future<void> addTagToTransaction(String transactionId, String tag) async {
    // Helper for Undo
    final service = ref.read(bankServiceProvider);
    final currentList =
        ref.read(bankTransactionListProvider).asData?.value ?? [];

    final tx = currentList.firstWhere((t) => t.id == transactionId);
    final updatedTags = List<String>.from(tx.tags)..add(tag);

    final updatedTx = tx.copyWith(tags: updatedTags);

    await service.updateTransaction(updatedTx);
    ref.invalidate(bankTransactionListProvider);
  }

  Future<void> restoreVendorTags(String transactionId) async {
    final service = ref.read(bankServiceProvider);
    final currentList =
        ref.read(bankTransactionListProvider).asData?.value ?? [];

    final tx = currentList.firstWhere((t) => t.id == transactionId);

    if (tx.tags.isEmpty) return; // Should not happen per rules

    final vendorTag = tx.tags.first;
    final defaultTags = await service.getVendorTags(vendorTag);

    // Replace current tags with defaults
    final updatedTx = tx.copyWith(tags: defaultTags);

    await service.updateTransaction(updatedTx);
    ref.invalidate(bankTransactionListProvider);
  }

  Future<void> updateTagLimit(
    String tagName,
    double? limit,
    String? frequency,
  ) async {
    final service = ref.read(bankServiceProvider);
    // Fetch existing or create new
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

    // In a real app we might need to invalidate a tags provider
  }
}

class DashboardState {
  final Set<String> selection;
  final String? selectedTag;

  const DashboardState({required this.selection, this.selectedTag});

  DashboardState copyWith({Set<String>? selection, String? selectedTag}) {
    return DashboardState(
      selection: selection ?? this.selection,
      selectedTag: selectedTag, // Allow null to clear
    );
  }
}

// Temporary Provider moved here for visibility
@riverpod
Future<List<BankTransaction>> bankTransactionList(Ref ref) async {
  final service = ref.watch(bankServiceProvider);
  return service.fetchTransactions();
}

// Derived Provider for Calculations
@riverpod
Map<String, double> dashboardCalculations(Ref ref) {
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
}
