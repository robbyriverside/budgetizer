import 'dart:io';
import 'package:budgetizer_dart/budgetizer_dart.dart';
import 'package:plaid_dart/plaid_dart.dart';

void main() async {
  print('Starting Transaction Loading Test...');

  // Load Env
  final env = loadEnvFile('.env');
  final clientId = env['PLAID_CLIENT_ID'];
  final secret = env['PLAID_SECRET'];

  if (clientId == null || secret == null) {
    print('Error: PLAID_CLIENT_ID and PLAID_SECRET not found in .env');
    exit(1);
  }

  // Load Tags
  final dbTagsFile = File('assets/data/db_tags.json');
  if (!dbTagsFile.existsSync()) {
    print('Error: assets/data/db_tags.json not found');
    exit(1);
  }
  final tagJson = await dbTagsFile.readAsString();
  final tagEngine = TagEngine.fromJson(tagJson);
  print('Loaded TagEngine with ${tagEngine.tags.length} initial tags.');

  // Initialize Service with Mock AI
  final aiService = MockAIService();
  final service = PlaidBankService(
    clientId: clientId,
    secret: secret,
    environment: 'sandbox',
    tagEngine: tagEngine,
    aiService: aiService,
    resourceLoader: (path) => File(path).readAsString(),
  );

  print('1. Creating Sandbox Public Token...');
  // Need PlaidClient for this as Service doesn't expose it
  final client = PlaidClient(
    clientId: clientId,
    secret: secret,
    environment: 'sandbox',
  );
  String publicToken;
  try {
    publicToken = await client.createSandboxPublicToken();
    print('   Public Token: $publicToken');
  } catch (e) {
    print('   Error creating public token: $e');
    exit(1);
  }

  print('2. Exchanging Public Token...');
  try {
    await service.exchangePublicToken(publicToken);
    print('   Access Token Exchanged.');
  } catch (e) {
    print('   Error exchanging token: $e');
    exit(1);
  }

  print('3. Fetching Transactions...');
  List<BankTransaction> transactions = [];
  try {
    // Wait a brief moment to ensure sandbox data is ready (though usually instant)
    await Future.delayed(Duration(seconds: 2));
    transactions = await service.fetchTransactions('ALL');
    print('   Fetched ${transactions.length} transactions.');
  } catch (e) {
    print('   Error fetching transactions: $e');
    exit(1);
  }

  print('4. Generating YAML Output...');
  final sb = StringBuffer();
  sb.writeln('transactions:');

  for (final tx in transactions) {
    sb.writeln('  - id: "${tx.id}"');
    sb.writeln('    date: "${tx.date.toIso8601String().split('T')[0]}"');
    sb.writeln('    description: "${tx.description}"');
    sb.writeln('    vendor: "${tx.vendorName}"');
    sb.writeln('    amount: ${tx.amount}');
    // Format tags as json-like array
    sb.writeln('    tags: [${tx.tags.map((t) => '"$t"').join(', ')}]');
  }

  final outFile = File('sandbox_transactions.yaml');
  await outFile.writeAsString(sb.toString());
  print('   Written to ${outFile.absolute.path}');
}

Map<String, String> loadEnvFile(String path) {
  final file = File(path);
  if (!file.existsSync()) return {};
  final lines = file.readAsLinesSync();
  final map = <String, String>{};
  for (var line in lines) {
    line = line.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    final parts = line.split('=');
    if (parts.length >= 2) {
      final key = parts[0].trim();
      final value = parts.sublist(1).join('=').trim();
      // Remove quotes if present
      var cleanValue = value;
      if ((value.startsWith('"') && value.endsWith('"')) ||
          (value.startsWith("'") && value.endsWith("'"))) {
        cleanValue = value.substring(1, value.length - 1);
      }
      map[key] = cleanValue;
    }
  }
  return map;
}
