import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../dashboard/controllers/dashboard_controller.dart';
import '../../core/services/tag_service.dart';
import 'package:budgetizer_dart/budgetizer_dart.dart';

final reportingControllerProvider =
    AsyncNotifierProvider<ReportingController, ReportingState>(
      ReportingController.new,
    );

class ReportingController extends AsyncNotifier<ReportingState> {
  @override
  @override
  Future<ReportingState> build() async {
    final transactions = await ref.watch(bankTransactionListProvider.future);
    final tagState = await ref.watch(tagServiceProvider.future);

    // 1. Calculate Actuals by Tag
    final Map<String, double> actuals = {};
    for (var tx in transactions) {
      if (tx.amount < 0 && tx.tags.isNotEmpty) {
        for (final tag in tx.tags) {
          actuals[tag] = (actuals[tag] ?? 0) + tx.amount.abs();
        }
      }
    }

    // 2. Fetch Available Reports from DB
    List<String> availableReports = ['budget'];
    final storage = ref.read(storageRepositoryProvider);
    // Only check DB if initialized
    // if (db.db != null) { // Assumption: storage is ready
    try {
      final persistedNames = await storage.getAllReportNames();
      final set = <String>{'All Budgets', ...persistedNames};
      // Remove legacy 'budget' if present in set to clean up UI (though it shouldn't be in persisted names)
      set.remove('budget');
      availableReports = set.toList();
    } catch (e) {}
    // }

    // 3. Determine Current Report Data
    // Default to 'All Budgets'
    String currentReport = 'All Budgets';

    // Check DB for last viewed report if state doesn't have value yet (first load)
    // Check DB for last viewed report if state doesn't have value yet (first load)
    if (!state.hasValue) {
      final lastViewed = await storage.getSetting('last_viewed_report');
      if (lastViewed != null &&
          (availableReports.contains(lastViewed) ||
              lastViewed == 'All Budgets')) {
        currentReport = lastViewed;
      }
    } else {
      currentReport = state.value!.currentReportName;
    }

    List<ReportItem> currentItems = [];

    if (currentReport == 'All Budgets' || currentReport == 'budget') {
      // Default Hardcoded Budget logic
      // Handle legacy 'budget' string if it somehow persists, treating same as 'All Budgets'
      final Map<String, double> knownBudgets = {
        'Groceries': 500.0,
        'Dining': 300.0,
        'Transport': 200.0,
        'Entertainment': 100.0,
        'Utilities': 250.0,
      };

      knownBudgets.forEach((tag, budget) {
        final actual = actuals[tag] ?? 0.0;
        currentItems.add(
          ReportItem(
            id: 'item_$tag',
            tagName: tag,
            budgetAmount: budget,
            actualAmount: actual,
          ),
        );
      });
    } else {
      // Load from DB
      try {
        final data = await storage.getReport(currentReport);
        if (data != null) {
          // Parse report items
          // structure: { 'items': [ ... ] } where item has tagName, budgetAmount, frequency
          final List itemsList = data['items'] ?? [];
          currentItems = itemsList.map((i) {
            final tagName = i['tagName'];
            final actual = actuals[tagName] ?? 0.0;
            return ReportItem(
              id: i['id'] ?? 'item_$tagName',
              tagName: tagName,
              budgetAmount: (i['budgetAmount'] as num).toDouble(),
              frequency: BudgetFrequency.values.firstWhere(
                (e) => e.name == (i['frequency'] ?? 'monthly'),
                orElse: () => BudgetFrequency.monthly,
              ),
              actualAmount: actual,
            );
          }).toList();
        }
      } catch (e) {}
    }

    // 4. Build Spending Tags List (Attributes budgets if they exist in currentItems)
    final Set<String> uniqueTagNames = tagState.tags.map((t) => t.name).toSet();
    uniqueTagNames.addAll(actuals.keys);
    uniqueTagNames.addAll(currentItems.map((i) => i.tagName));

    final List<SpendingTag> allTags = uniqueTagNames.map((tagName) {
      final reportItem = currentItems.cast<ReportItem?>().firstWhere(
        (i) => i!.tagName == tagName,
        orElse: () => null,
      );

      return SpendingTag(
        name: tagName,
        amount: actuals[tagName] ?? 0.0,
        existingBudget: reportItem?.budgetAmount,
        existingFrequency: reportItem?.frequency,
        isBudgeted: reportItem != null,
      );
    }).toList();

    // Sort by spend desc
    allTags.sort((a, b) => b.amount.compareTo(a.amount));

    return ReportingState(
      allTags: allTags,
      reportItems: currentItems,
      currentReportName: currentReport,
      availableReports: availableReports,
      isDirty: false,
    );
  }

  void addReportItem(
    String tagName,
    double budgetAmount,
    BudgetFrequency frequency,
  ) {
    if (!state.hasValue) return;
    final currentState = state.value!;

    final existingItemIndex = currentState.reportItems.indexWhere(
      (i) => i.tagName == tagName,
    );

    final spendTag = currentState.allTags.firstWhere(
      (t) => t.name == tagName,
      orElse: () => SpendingTag(name: tagName, amount: 0, isBudgeted: false),
    );

    final newItem = ReportItem(
      id: existingItemIndex != -1
          ? currentState.reportItems[existingItemIndex].id
          : 'item_${DateTime.now().millisecondsSinceEpoch}',
      tagName: tagName,
      budgetAmount: budgetAmount,
      frequency: frequency,
      actualAmount: spendTag.amount,
    );

    List<ReportItem> newItems;
    if (existingItemIndex != -1) {
      newItems = List.from(currentState.reportItems);
      newItems[existingItemIndex] = newItem;
    } else {
      newItems = [...currentState.reportItems, newItem];
    }

    final newAllTags = currentState.allTags.map((t) {
      if (t.name == tagName) {
        return t.copyWith(
          isBudgeted: true,
          existingBudget: budgetAmount,
          existingFrequency: frequency,
        );
      }
      return t;
    }).toList();

    state = AsyncData(
      currentState.copyWith(
        reportItems: newItems,
        allTags: newAllTags,
        isDirty: true,
      ),
    );
  }

  void removeReportItem(String itemId) {
    if (!state.hasValue) return;
    final currentState = state.value!;

    ReportItem? itemToRemove;
    try {
      itemToRemove = currentState.reportItems.firstWhere((i) => i.id == itemId);
    } catch (_) {
      return; // Item not found
    }

    final newItems = currentState.reportItems
        .where((i) => i.id != itemId)
        .toList();

    // Update tag state (remove budget info)
    final newAllTags = currentState.allTags.map((t) {
      if (t.name == itemToRemove!.tagName) {
        // We keep the tag in the list, but mark as not budgeted
        return t.copyWith(
          isBudgeted: false,
          existingBudget: null, // removing budget
          existingFrequency: null,
        );
      }
      return t;
    }).toList();

    state = AsyncData(
      currentState.copyWith(
        reportItems: newItems,
        allTags: newAllTags,
        isDirty: true,
      ),
    );
  }

  void reorderItems(int oldIndex, int newIndex) {
    if (!state.hasValue) return;
    final currentState = state.value!;

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final items = [...currentState.reportItems];
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);

    state = AsyncData(currentState.copyWith(reportItems: items, isDirty: true));
  }

  Future<bool> saveReport(String reportName) async {
    if (!state.hasValue) return false;
    final currentState = state.value!;

    final data = {
      'items': currentState.reportItems
          .map(
            (i) => {
              'id': i.id,
              'tagName': i.tagName,
              'budgetAmount': i.budgetAmount,
              'frequency': i.frequency.name,
            },
          )
          .toList(),
    };

    final storage = ref.read(storageRepositoryProvider);
    try {
      await storage.saveReport(reportName, data);
    } catch (e) {
      return false;
    }

    final reports = {...currentState.availableReports, reportName}.toList();

    // Save as last viewed
    await storage.saveSetting('last_viewed_report', reportName);

    state = AsyncData(
      currentState.copyWith(
        currentReportName: reportName,
        isDirty: false,
        availableReports: reports,
      ),
    );
    return true;
  }

  Future<void> deleteReport(String reportName) async {
    final storage = ref.read(storageRepositoryProvider);
    try {
      await storage.deleteReport(reportName);
    } catch (e) {
      return;
    }

    if (!state.hasValue) {
      ref.invalidateSelf();
      return;
    }

    final currentState = state.value!;
    final newReports = currentState.availableReports
        .where((n) => n != reportName)
        .toList();

    if (currentState.currentReportName == reportName) {
      // Switch to default 'All Budgets'
      await storage.saveSetting('last_viewed_report', 'All Budgets');
      state = AsyncData(
        currentState.copyWith(
          currentReportName: 'All Budgets',
          availableReports: newReports,
        ),
      );
      ref.invalidateSelf();
    } else {
      state = AsyncData(currentState.copyWith(availableReports: newReports));
    }
  }

  void updateBudget(
    String tagName,
    double newAmount,
    BudgetFrequency frequency,
  ) {
    if (!state.hasValue) return;
    addReportItem(tagName, newAmount, frequency);
  }

  Future<void> loadReport(String reportName) async {
    if (!state.hasValue) return;

    // Persist selection
    final storage = ref.read(storageRepositoryProvider);
    await storage.saveSetting('last_viewed_report', reportName);

    // Switch state to new name so build() sees it
    final currentState = state.value!;
    state = AsyncData(currentState.copyWith(currentReportName: reportName));
    ref.invalidateSelf();
  }

  void refresh() {
    ref.invalidateSelf();
  }
}

class ReportingState {
  final List<SpendingTag> allTags;
  final List<ReportItem> reportItems;
  final String currentReportName;
  final List<String> availableReports;
  final bool isDirty;

  ReportingState({
    required this.allTags,
    required this.reportItems,
    required this.currentReportName,
    required this.availableReports,
    required this.isDirty,
  });

  ReportingState copyWith({
    List<SpendingTag>? allTags,
    List<ReportItem>? reportItems,
    String? currentReportName,
    List<String>? availableReports,
    bool? isDirty,
  }) {
    return ReportingState(
      allTags: allTags ?? this.allTags,
      reportItems: reportItems ?? this.reportItems,
      currentReportName: currentReportName ?? this.currentReportName,
      availableReports: availableReports ?? this.availableReports,
      isDirty: isDirty ?? this.isDirty,
    );
  }
}

enum BudgetFrequency {
  weekly,
  monthly,
  yearly;

  String get label => name[0].toUpperCase() + name.substring(1);
}

class SpendingTag {
  final String name;
  final double amount;
  final double? existingBudget; // The "Budgeted" state
  final BudgetFrequency? existingFrequency;
  final bool isBudgeted;

  SpendingTag({
    required this.name,
    required this.amount,
    this.existingBudget,
    this.existingFrequency,
    this.isBudgeted = false,
  });

  SpendingTag copyWith({
    double? existingBudget,
    BudgetFrequency? existingFrequency,
    bool? isBudgeted,
  }) {
    return SpendingTag(
      name: name,
      amount: amount,
      existingBudget:
          existingBudget, // Allow setting to null by accepting nullable and checking logic?
      // copyWith nuance: if we pass null, we usually mean "keep existing".
      // To allow clearing, we might need a specific sentinel or just rebuild.
      // For now, let's assume we rebuild if we want to clear, OR we change logic.
      // Actually, standard copyWith pattern with nullable fields is tricky.
      // Let's just use the passed value if isBudgeted is false.
      // Wait, standard copyWith: existingBudget ?? this.existingBudget.
      // If I want to set it to null, I can't.
      // Modifying copyWith to allow nullable override is cleaner.
      // Or I just reconstruct `SpendingTag` in `removeReportItem`.
      existingFrequency: existingFrequency ?? this.existingFrequency,
      isBudgeted: isBudgeted ?? this.isBudgeted,
    );
  }
}

class ReportItem {
  final String id;
  final String tagName;
  final double budgetAmount;
  final BudgetFrequency frequency;
  final double actualAmount;

  ReportItem({
    required this.id,
    required this.tagName,
    required this.budgetAmount,
    this.frequency = BudgetFrequency.monthly,
    required this.actualAmount,
  });

  double get percentSpent => budgetAmount == 0
      ? (actualAmount > 0 ? 100.0 : 0)
      : (actualAmount / budgetAmount);
}
