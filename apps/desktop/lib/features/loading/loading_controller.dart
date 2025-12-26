import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:budgetizer_dart/budgetizer_dart.dart';

part 'loading_controller.g.dart';

@riverpod
class LoadingController extends _$LoadingController {
  bool _mounted = true;

  @override
  LoadingState build() {
    ref.onDispose(() => _mounted = false);

    // Start loading automatically
    Future.microtask(() => _simulateLoading());
    return LoadingState(
      isLoading: true,
      processedCount: 0,
      loadedTransactions: [],
      tagCounts: {},
    );
  }

  void _simulateLoading() async {
    // Simulate incoming stream of transactions
    // In real app, this would listen to a stream from BankService/AI
    // For demo, we just add some mocked data periodically

    // Sample vendors
    final vendors = [
      ('Amazon', 'Home Goods'),
      ('Safeway', 'Groceries'),
      ('Uber', 'Transport'),
      ('Starbucks', 'Dining'),
      ('Netflix', 'Entertainment'),
    ];

    for (int i = 0; i < 20; i++) {
      if (!_mounted) return;
      if (!state.isLoading) break;

      await Future.delayed(const Duration(milliseconds: 500));
      if (!_mounted) return;

      final vendor = vendors[i % vendors.length];
      final newTx = BankTransaction(
        id: 'temp_$i',
        cashflowId: 'acc_1',
        amount: -10.0 - i,
        date: DateTime.now(),
        vendorName: vendor.$1,
        description: 'Auto-import $i',
        tags: [vendor.$2],
        pending: false,
      );

      final List<BankTransaction> currentList = [
        ...state.loadedTransactions,
        newTx,
      ];

      // Update counts
      final Map<String, int> counts = {};
      for (var tx in currentList) {
        for (var tag in tx.tags) {
          counts[tag] = (counts[tag] ?? 0) + 1;
        }
      }

      state = state.copyWith(
        processedCount: i + 1,
        loadedTransactions: currentList,
        tagCounts: counts,
      );
    }

    if (_mounted) {
      state = state.copyWith(isLoading: false);
    }
  }

  void stopLoading() {
    state = state.copyWith(isLoading: false);
  }
}

class LoadingState {
  final bool isLoading;
  final int processedCount;
  final List<BankTransaction> loadedTransactions;
  final Map<String, int> tagCounts;
  final String? selectedTag;

  LoadingState({
    required this.isLoading,
    required this.processedCount,
    required this.loadedTransactions,
    required this.tagCounts,
    this.selectedTag,
  });

  LoadingState copyWith({
    bool? isLoading,
    int? processedCount,
    List<BankTransaction>? loadedTransactions,
    Map<String, int>? tagCounts,
    String? selectedTag,
  }) {
    return LoadingState(
      isLoading: isLoading ?? this.isLoading,
      processedCount: processedCount ?? this.processedCount,
      loadedTransactions: loadedTransactions ?? this.loadedTransactions,
      tagCounts: tagCounts ?? this.tagCounts,
      selectedTag: selectedTag ?? this.selectedTag,
    );
  }
}
