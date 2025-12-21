import 'dart:io';

import 'package:plaid_dart/plaid_dart.dart';

Future<void> main() async {
  // Load environment variables manually since we might not have Flutter bindings initialized
  final envFile = File('.env');
  if (!envFile.existsSync()) {
    print('Error: .env file not found.');
    exit(1);
  }

  final lines = envFile.readAsLinesSync();
  final env = <String, String>{};
  for (var line in lines) {
    if (line.trim().isEmpty || line.startsWith('#')) continue;
    final parts = line.split('=');
    if (parts.length >= 2) {
      env[parts[0].trim()] = parts.sublist(1).join('=').trim();
    }
  }

  final clientId = env['PLAID_CLIENT_ID'];
  final secret = env['PLAID_SECRET'];
  final environment = env['PLAID_ENV'] ?? 'sandbox';

  if (clientId == null || secret == null) {
    print('Error: PLAID_CLIENT_ID or PLAID_SECRET not found in .env');
    exit(1);
  }

  print('Configuration:');
  print('  Client ID:   $clientId');
  print('  Environment: $environment');

  final client = PlaidClient(
    clientId: clientId,
    secret: secret,
    environment: environment,
  );

  try {
    // 1. Create a Sandbox Public Token (This bypasses Link UI)
    print('\n[1/3] Creating Sandbox Public Token...');
    final publicToken = await client.createSandboxPublicToken();
    print('  > Public Token: $publicToken');

    // 2. Exchange for Access Token
    print('\n[2/3] Exchanging for Access Token...');
    final accessToken = await client.exchangePublicToken(publicToken);
    print('  > Access Token: $accessToken');

    // 3. Fetch Transactions
    print('\n[3/3] Fetching Transactions (last 30 days)...');
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 30));

    // Helper to format date as YYYY-MM-DD
    String fmt(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    // Retry loop for Transactions
    int retries = 5;
    while (retries > 0) {
      try {
        print('  ... Attempting to fetch (Remaining retries: $retries)');
        final response = await client.getTransactions(
          accessToken,
          startDate: fmt(startDate),
          endDate: fmt(endDate),
        );

        final transactions = response['transactions'] as List;
        print('  > Success! Loaded ${transactions.length} transactions.');

        // Print first 3 transactions as sample
        for (var i = 0; i < transactions.length && i < 3; i++) {
          final t = transactions[i];
          print('    - ${t['date']} [${t['amount']}] ${t['name']}');
        }
        break; // Success, exit loop
      } catch (e) {
        if (e.toString().contains('PRODUCT_NOT_READY')) {
          print('  > Product not ready, waiting 3 seconds...');
          await Future.delayed(const Duration(seconds: 3));
          retries--;
          if (retries == 0) {
            print('  > Timeout: Transactions did not become ready in time.');
            print(
              '  > This is common in Sandbox. The Item is linked, but data generation is slow.',
            );
          }
        } else {
          rethrow;
        }
      }
    }
  } catch (e) {
    print('\nError: $e');
    exit(1);
  }
}
