import '../interfaces/storage_repository.dart';
import '../models/financial_entities.dart';

class FirebaseService implements StorageRepository {
  // TODO: Add Firestore instance

  @override
  Future<void> close() async {
    // No-op for Firebase usually
  }

  @override
  Future<void> deleteReport(String name) async {
    // TODO: implement deleteReport
    throw UnimplementedError();
  }

  @override
  Future<List<String>> getAllReportNames() async {
    // TODO: implement getAllReportNames
    throw UnimplementedError();
  }

  @override
  Future<Cashflow?> getCycle(String key) async {
    // TODO: implement getCycle
    throw UnimplementedError();
  }

  @override
  Future<List<Cashflow>> getCyclesForCashflow(String cashflowId) async {
    // TODO: implement getCyclesForCashflow
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>?> getReport(String name) async {
    // TODO: implement getReport
    throw UnimplementedError();
  }

  @override
  Future<String?> getSetting(String key) async {
    // TODO: implement getSetting
    throw UnimplementedError();
  }

  @override
  Future<void> reset() async {
    // TODO: implement reset
    throw UnimplementedError();
  }

  @override
  Future<void> saveCycle(
      String key, Cashflow cycleData, String type, String cashflowId) async {
    // TODO: implement saveCycle
    throw UnimplementedError();
  }

  @override
  Future<void> saveReport(String name, Map<String, dynamic> data) async {
    // TODO: implement saveReport
    throw UnimplementedError();
  }

  @override
  Future<void> saveSetting(String key, String value) async {
    // TODO: implement saveSetting
    throw UnimplementedError();
  }

  @override
  Future<void> setEphemeralMode(bool enabled) async {
    // No-op for Firebase or switch to a temp collection
    print('setEphemeralMode not implemented for Firebase');
  }
}
