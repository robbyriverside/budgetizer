import 'dart:io';
import 'package:budgetizer_dart/budgetizer_dart.dart';
import 'package:dotenv/dotenv.dart';

BankService getBankService() {
  // Load environment vars (merging with Platform environment)
  var env = DotEnv(includePlatformEnvironment: true)..load();

  final clientId = env['PLAID_CLIENT_ID'];
  final secret = env['PLAID_SECRET'];

  // In a real app we'd also need the Plaid Environment (Sandbox/Dev/Prod)
  // defaulting to sandbox for safety

  if (clientId != null &&
      clientId.isNotEmpty &&
      secret != null &&
      secret.isNotEmpty) {
    print('🔐 Using PlaidBankService (Client ID found)');
    return PlaidBankService(
      clientId: clientId,
      secret: secret,
      environment: env['PLAID_ENV'] ?? 'sandbox',
      accessToken: env['PLAID_ACCESS_TOKEN'],
    );
  }

  print('⚠️  Using MockBankService (PLAID_CLIENT_ID not set)');
  return getMockBankService();
}

BankService getMockBankService() {
  return MockBankService(
    resourceLoader: (path) async {
      // Map 'assets/data/mock_transactions.json' to local CLI file
      if (path.contains('mock_transactions.json')) {
        final file = File('assets/mock_transactions.json');
        if (await file.exists()) {
          return file.readAsString();
        }
      }
      throw Exception('Asset not found: $path');
    },
  );
}

AIService getAIService() {
  var env = DotEnv(includePlatformEnvironment: true)..load();
  final apiKey = env['GEMINI_API_KEY'];

  if (apiKey != null && apiKey.isNotEmpty) {
    return GeminiAIService(apiKey: apiKey);
  }

  print('⚠️  Using MockAIService (GEMINI_API_KEY not set)');
  return MockAIService();
}
