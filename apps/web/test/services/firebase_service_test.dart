import 'package:budgetizer_dart/budgetizer_dart.dart' hide FirebaseService;

import 'package:web/services/firebase_service.dart'; // Correct package name
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

// Assuming package name is 'budgetizer_web' based on standard pubspec name
// If import fails, we will check pubspec.yaml name

void main() {
  group('FirebaseService Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirebaseService service;

    setUp(() async {
      fakeFirestore = FakeFirebaseFirestore();
      service = FirebaseService(firestore: fakeFirestore);
    });

    test('saveCycle saves data to Firestore', () async {
      final cycle = Cashflow(
        id: '123',
        seriesId: 'series_1',
        openingBalance: 1000.0,
        cycle: Cycle(startDate: DateTime.now()),
        transactions: [],
      );

      await service.saveCycle('cycle_1', cycle, 'monthly', 'flow_1');

      final snapshot = await fakeFirestore
          .collection('cashflow_cycles')
          .doc('cycle_1')
          .get();
      expect(snapshot.exists, isTrue);
      expect(snapshot.data()?['type'], equals('monthly'));
      expect(snapshot.data()?['cashflow_id'], equals('flow_1'));
    });

    test('getCycle retrieval from Firestore', () async {
      final cycleData = Cashflow(
        id: '456',
        seriesId: 'series_2',
        openingBalance: 2000.0,
        cycle: Cycle(startDate: DateTime.now()),
        transactions: [],
      );

      // Pre-populate data using the service (or direct DB manipulation)
      await service.saveCycle('cycle_2', cycleData, 'monthly', 'flow_2');

      final retrieved = await service.getCycle('cycle_2');
      expect(retrieved, isNotNull);
      expect(retrieved!.openingBalance, equals(2000.0));
    });

    test('saveSetting and getSetting', () async {
      await service.saveSetting('theme', 'dark');
      final value = await service.getSetting('theme');
      expect(value, equals('dark'));
    });

    test('getSetting returns null for missing key', () async {
      final value = await service.getSetting('missing_key');
      expect(value, isNull);
    });
  });
}
