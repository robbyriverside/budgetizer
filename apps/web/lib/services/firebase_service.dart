import 'package:budgetizer_dart/budgetizer_dart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class FirebaseService implements StorageRepository {
  final FirebaseFirestore _firestore;

  FirebaseService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> saveCycle(
    String key,
    Cashflow cycleData,
    String type,
    String cashflowId,
  ) async {
    final data = cycleData.toJson();
    await _firestore.collection('cashflow_cycles').doc(key).set({
      'cashflow_id':
          cashflowId, // snake_case to match sqlite convention if relevant, or camelCase
      'type': type,
      'cycle_date': cycleData.cycle.startDate.toIso8601String(),
      'json_content': jsonEncode(
        data,
      ), // Storing as string to ensure exact reproduction of serialized state?
      // Or store as Map. JSONB in Sqlite is similar to Map in Firestore.
      // However, fromJson expects Map<String, dynamic>.
      // If we store as Map in Firestore, we get Map back.
      // Let's store as Map.
      'data': data,
    });
  }

  @override
  Future<Cashflow?> getCycle(String key) async {
    final doc = await _firestore.collection('cashflow_cycles').doc(key).get();
    if (doc.exists && doc.data() != null) {
      final jsonMap = doc.data()!['data'];
      if (jsonMap is Map<String, dynamic>) {
        return Cashflow.fromJson(jsonMap);
      }
    }
    return null;
  }

  @override
  Future<List<Cashflow>> getCyclesForCashflow(String cashflowId) async {
    final snapshot = await _firestore
        .collection('cashflow_cycles')
        .where('cashflow_id', isEqualTo: cashflowId)
        .orderBy('cycle_date', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final jsonMap = doc.data()['data'] as Map<String, dynamic>;
      return Cashflow.fromJson(jsonMap);
    }).toList();
  }

  @override
  Future<void> saveReport(String name, Map<String, dynamic> data) async {
    await _firestore.collection('reports').doc(name).set({
      'name': name,
      'data': data,
    });
  }

  @override
  Future<Map<String, dynamic>?> getReport(String name) async {
    final doc = await _firestore.collection('reports').doc(name).get();
    if (doc.exists && doc.data() != null) {
      return doc.data()!['data'] as Map<String, dynamic>;
    }
    return null;
  }

  @override
  Future<List<String>> getAllReportNames() async {
    final snapshot = await _firestore.collection('reports').get();
    return snapshot.docs.map((d) => d.id).toList();
  }

  @override
  Future<void> deleteReport(String name) async {
    await _firestore.collection('reports').doc(name).delete();
  }

  @override
  Future<void> saveSetting(String key, String value) async {
    await _firestore.collection('settings').doc(key).set({'value': value});
  }

  @override
  Future<String?> getSetting(String key) async {
    final doc = await _firestore.collection('settings').doc(key).get();
    if (doc.exists && doc.data() != null) {
      return doc.data()!['value'] as String?;
    }
    return null;
  }

  @override
  Future<void> setEphemeralMode(bool enabled) async {
    // No-op for now, or switch collection prefix?
    // Web might not support "Temporary DB" unless we use a different collection set.
    print('Switching ephemeral mode to $enabled (No-op on Firebase)');
  }

  @override
  Future<void> reset() async {
    // Delete all collections? Dangerous.
    // Maybe only implements for local testing?
    throw UnimplementedError('Reset not implemented for Firebase');
  }

  @override
  Future<void> close() async {
    // No explicit close needed for Firestore instance usually,
    // but we can execute termination if needed.
    // Cloud Firestore persists.
  }
}
