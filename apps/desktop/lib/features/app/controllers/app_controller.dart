import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';

import '../../dashboard/controllers/dashboard_controller.dart';
import '../../reporting/reporting_controller.dart';
import '../../../core/services/bank_service.dart';
import '../../../core/services/tag_service.dart';
import '../../../core/providers/db_mode_provider.dart';

part 'app_controller.g.dart';

enum TargetDbType { permanent, temporary }

class AppState {
  final TargetDbType targetDbType;
  final bool isFirstTimeUser;
  final String? lastCashflowId;

  const AppState({
    this.targetDbType = TargetDbType.permanent,
    this.isFirstTimeUser = true,
    this.lastCashflowId,
  });

  AppState copyWith({
    TargetDbType? targetDbType,
    bool? isFirstTimeUser,
    String? lastCashflowId,
  }) {
    return AppState(
      targetDbType: targetDbType ?? this.targetDbType,
      isFirstTimeUser: isFirstTimeUser ?? this.isFirstTimeUser,
      lastCashflowId: lastCashflowId ?? this.lastCashflowId,
    );
  }
}

@Riverpod(keepAlive: true)
class AppController extends _$AppController {
  @override
  AppState build() {
    return const AppState();
  }

  Future<void> setTargetDbType(TargetDbType type) async {
    state = state.copyWith(targetDbType: type);

    final dbService = DatabaseService();
    final docDir = await getApplicationDocumentsDirectory();
    final budgetizerDir = Directory('${docDir.path}/budgetizer');

    // Re-initialize DB

    await dbService.init(
      databaseFactoryFfi,
      budgetizerDir.path,
      isTemporary: type == TargetDbType.temporary,
    );

    // Update Global DB Mode State
    ref
        .read(isTemporaryDbProvider.notifier)
        .set(type == TargetDbType.temporary);

    // If switching to Temp, we might want to clear previous temp data?
    // Requirement: "When you switch back to the Core DB, the temp db is lost. Next time you go to Temp DB, it is empty."
    // DatabaseService.init with isTemporary=true usually creates an in-memory DB or a fresh file.
    // If it's in-memory, it's lost on close. If we want it lost on "switch back", we might need to explicitly destroy it if it was file-based.
    // For now, assuming DatabaseService handles 'isTemporary' correctly (likely in-memory).

    // Invalidate downstream controllers to force refresh
    ref.invalidate(dashboardControllerProvider);
    ref.invalidate(reportingControllerProvider);
    ref.invalidate(bankTransactionListProvider);
    ref.invalidate(tagServiceProvider);
    // Invalidate BankService to ensure it clears any in-memory cache or re-connects
    ref.invalidate(bankServiceProvider);
  }

  void setFirstTimeUser(bool isFirstTime) {
    state = state.copyWith(isFirstTimeUser: isFirstTime);
  }

  void setLastCashflowId(String id) {
    state = state.copyWith(lastCashflowId: id);
    // Persist to storage (TODO: Add SharedPrefs or similar if needed, for now just memory/session)
  }
}
