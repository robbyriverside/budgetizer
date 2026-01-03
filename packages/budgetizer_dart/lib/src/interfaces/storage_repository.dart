import '../models/financial_entities.dart';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'storage_repository.g.dart';

@Riverpod(keepAlive: true)
StorageRepository storageRepository(Ref ref) {
  throw UnimplementedError('StorageRepository must be overridden');
}

abstract class StorageRepository {
  /// Save or Update a Cycle (Cashflow instance representing a period)
  Future<void> saveCycle(
    String key,
    Cashflow cycleData,
    String type,
    String cashflowId,
  );

  /// Retrieve a specific cycle by key
  Future<Cashflow?> getCycle(String key);

  /// Get all cycles for a specific account (Cashflow Series)
  Future<List<Cashflow>> getCyclesForCashflow(String cashflowId);

  // --- REPORT METHODS ---

  Future<void> saveReport(String name, Map<String, dynamic> data);

  Future<Map<String, dynamic>?> getReport(String name);

  Future<List<String>> getAllReportNames();

  Future<void> deleteReport(String name);

  // --- SETTINGS METHODS ---

  Future<void> saveSetting(String key, String value);

  Future<String?> getSetting(String key);

  /// Switch between permanent and ephemeral (temporary) storage mode
  Future<void> setEphemeralMode(bool enabled);

  /// Reset the storage (clear all data)
  Future<void> reset();

  /// Close the connection
  Future<void> close();
}
