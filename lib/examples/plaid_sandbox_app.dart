import 'package:budgetizer/core/services/bank_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plaid_flutter/plaid_flutter.dart';

// Entry point for the Plaid Sandbox Example
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print("Error loading .env file: $e");
    print("Ensure you have created a .env file based on .env.example");
  }

  runApp(const ProviderScope(child: PlaidSandboxApp()));
}

class PlaidSandboxApp extends StatelessWidget {
  const PlaidSandboxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plaid Sandbox Demo',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFF121212),
        useMaterial3: true,
      ),
      home: const PlaidHomePage(),
    );
  }
}

class PlaidHomePage extends ConsumerStatefulWidget {
  const PlaidHomePage({super.key});

  @override
  ConsumerState<PlaidHomePage> createState() => _PlaidHomePageState();
}

class _PlaidHomePageState extends ConsumerState<PlaidHomePage> {
  String _status = "Ready to connect";
  List<BankTransaction> _transactions = [];
  bool _loading = false;
  LinkTokenConfiguration? _linkTokenConfiguration;

  @override
  void initState() {
    super.initState();
    _checkEnv();
  }

  void _checkEnv() {
    if (dotenv.env['PLAID_CLIENT_ID'] == null ||
        dotenv.env['PLAID_SECRET'] == null) {
      setState(() {
        _status =
            "CRITICAL: .env file missing or empty. Please configure PLAID_CLIENT_ID and PLAID_SECRET.";
      });
    }
  }

  Future<void> _startPlaidLink() async {
    setState(() {
      _loading = true;
      _status = "Generating Link Token...";
    });

    try {
      final bankService = ref.read(bankServiceProvider);
      // Ensure we are using PlaidBankService
      if (bankService is! PlaidBankService) {
        setState(() {
          _status = "Error: BankService is Mock. Check your .env file.";
          _loading = false;
        });
        return;
      }

      final linkToken = await bankService.createLinkToken();

      setState(() {
        _status = "Opening Plaid Link...";
      });

      _linkTokenConfiguration = LinkTokenConfiguration(token: linkToken);

      await PlaidLink.create(configuration: _linkTokenConfiguration!);
      PlaidLink.open();

      // Listen for result handled by callbacks in PlaidLink (which are actually global/static or need stream subscription)
      // Plaid Flutter uses a Stream for results
      PlaidLink.onSuccess.listen(_onPlaidSuccess);
      PlaidLink.onExit.listen(_onPlaidExit);
    } catch (e) {
      setState(() {
        _status = "Error starting Plaid: $e";
        _loading = false;
      });
    }
  }

  Future<void> _onPlaidSuccess(LinkSuccess event) async {
    setState(() {
      _status = "Linked! Exchanging token...";
    });

    try {
      final bankService = ref.read(bankServiceProvider);
      await bankService.exchangePublicToken(event.publicToken);

      setState(() {
        _status = "Token exchanged. Fetching transactions...";
      });

      final txs = await bankService.fetchTransactions('ALL');

      setState(() {
        _transactions = txs;
        _loading = false;
        _status = "Loaded ${txs.length} transactions from Plaid Sandbox";
      });
    } catch (e) {
      setState(() {
        _status = "Error fetching data: $e";
        _loading = false;
      });
    }
  }

  void _onPlaidExit(LinkExit event) {
    if (event.error != null) {
      setState(() {
        _status = "Plaid Exit with Error: ${event.error?.description}";
        _loading = false;
      });
    } else {
      // User canceled
      setState(() {
        _loading = false;
        _status = "User canceled Plaid Link";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plaid Integration Step 1')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blueGrey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blueGrey),
              ),
              child: Text(
                _status,
                style: const TextStyle(fontSize: 16, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          if (!_loading && _transactions.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton.icon(
                onPressed: _startPlaidLink,
                icon: const Icon(Icons.link),
                label: const Text("Connect Plaid (Sandbox)"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: _transactions.length,
              itemBuilder: (context, index) {
                final tx = _transactions[index];
                return Card(
                  color: Colors.white.withValues(alpha: 0.05),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: tx.amount < 0
                          ? Colors.redAccent
                          : Colors.greenAccent,
                      child: Icon(
                        tx.amount < 0
                            ? Icons.arrow_outward
                            : Icons.arrow_downward,
                        color: Colors.black,
                      ),
                    ),
                    title: Text(
                      tx.vendorName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(tx.description),
                    trailing: Text(
                      "\$${tx.amount.toStringAsFixed(2)}",
                      style: TextStyle(
                        color: tx.amount < 0
                            ? Colors.redAccent
                            : Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
