import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:budgetizer_dart/budgetizer_dart.dart';

export 'package:budgetizer_dart/budgetizer_dart.dart';

part 'bank_service.g.dart';

@riverpod
BankService bankService(Ref ref) {
  // Check env vars to decide which service to use
  // This is a simple toggle. In real app, might be dynamic configuration.
  final clientId = dotenv.env['PLAID_CLIENT_ID'];
  final secret = dotenv.env['PLAID_SECRET'];

  // Resource loader for Flutter assets
  Future<String> flutterResourceLoader(String path) {
    return rootBundle.loadString(path);
  }

  if (clientId != null &&
      clientId.isNotEmpty &&
      secret != null &&
      secret.isNotEmpty) {
    return PlaidBankService(
      clientId: clientId,
      secret: secret,
      resourceLoader: flutterResourceLoader,
    );
  }

  return MockBankService(resourceLoader: flutterResourceLoader);
}
