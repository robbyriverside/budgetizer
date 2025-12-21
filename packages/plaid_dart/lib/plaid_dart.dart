import 'dart:convert';
import 'package:http/http.dart' as http;

class PlaidClient {
  final String clientId;
  final String secret;
  final String environment;
  final http.Client _httpClient;

  PlaidClient({
    required this.clientId,
    required this.secret,
    this.environment = 'sandbox',
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  String get _baseUrl {
    switch (environment) {
      case 'production':
        return 'https://production.plaid.com';
      case 'development':
        return 'https://development.plaid.com';
      case 'sandbox':
      default:
        return 'https://sandbox.plaid.com';
    }
  }

  /// Creates a Link Token.
  /// https://plaid.com/docs/api/link/#linktokencreate
  Future<String> createLinkToken({required String userId}) async {
    final response = await _post('/link/token/create', {
      'client_id': clientId,
      'secret': secret,
      'client_name': 'Budgetizer',
      'language': 'en',
      'country_codes': ['US'],
      'user': {'client_user_id': userId},
      'products': ['transactions'],
    });

    if (response.statusCode != 200) {
      throw Exception('Failed to create link token: ${response.body}');
    }

    final data = jsonDecode(response.body);
    return data['link_token'];
  }

  /// Exchanges a public token for an access token.
  /// https://plaid.com/docs/api/tokens/#itempublic_tokenexchange
  Future<String> exchangePublicToken(String publicToken) async {
    final response = await _post('/item/public_token/exchange', {
      'client_id': clientId,
      'secret': secret,
      'public_token': publicToken,
    });

    if (response.statusCode != 200) {
      throw Exception('Failed to exchange public token: ${response.body}');
    }

    final data = jsonDecode(response.body);
    return data['access_token'];
  }

  /// Fetches transactions for an access token.
  /// https://plaid.com/docs/api/products/transactions/#transactionsget
  Future<Map<String, dynamic>> getTransactions(
    String accessToken, {
    required String startDate,
    required String endDate,
  }) async {
    final response = await _post('/transactions/get', {
      'client_id': clientId,
      'secret': secret,
      'access_token': accessToken,
      'start_date': startDate,
      'end_date': endDate,
    });

    if (response.statusCode != 200) {
      throw Exception('Failed to get transactions: ${response.body}');
    }

    return jsonDecode(response.body);
  }

  /// Creates a public token for Sandbox testing purposes.
  /// This allows testing the flow without the Link UI.
  /// https://plaid.com/docs/api/sandbox/#sandboxpublic_tokencreate
  Future<String> createSandboxPublicToken({
    String institutionId = 'ins_109508',
    List<String> initialProducts = const ['transactions'],
  }) async {
    if (environment != 'sandbox') {
      throw Exception(
        'createSandboxPublicToken can only be used in sandbox environment',
      );
    }

    final response = await _post('/sandbox/public_token/create', {
      'client_id': clientId,
      'secret': secret,
      'institution_id': institutionId,
      'initial_products': initialProducts,
    });

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to create sandbox public token: ${response.body}',
      );
    }

    final data = jsonDecode(response.body);
    return data['public_token'];
  }

  Future<http.Response> _post(String endpoint, Map<String, dynamic> body) {
    return _httpClient.post(
      Uri.parse('$_baseUrl$endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
  }
}
