import 'dart:convert';
import 'dart:typed_data';

import 'package:budgetizer_dart/budgetizer_dart.dart'; // For FinancialEntity and other core types if needed, or local imports
// Assuming AIService interface is in ai_service.dart
import 'package:budgetizer_dart/src/services/ai_service.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
// If env is needed:
// import 'package:dotenv/dotenv.dart'; // But better to pass key in constructor

class GeminiAIService implements AIService {
  final String apiKey;
  late final GenerativeModel _model;

  GeminiAIService({required this.apiKey}) {
    _model = GenerativeModel(
      model: 'gemini-flash-latest',
      apiKey: apiKey,
      generationConfig: GenerationConfig(temperature: 0),
    );
  }

  @override
  Future<AIAnalysisResult> analyzeTransaction(
    String description, {
    String? context,
  }) async {
    // Basic implementation for single transaction analysis if needed,
    // or just return Mock behavior if we only care about PDF for now.
    // Let's implement basic text analysis too.
    final prompt = '''
    Analyze this bank transaction:
    Description: "$description"
    Context: "${context ?? ''}"
    
    Return JSON:
    {
      "vendorName": "Clean Vendor Name",
      "tags": ["Tag1", "Tag2"],
      "suggestedRegex": "Regex to match this vendor",
      "type": "Expense" | "Income" | "Transfer"
    }
    ''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final text = response.text;
      if (text == null) throw Exception('No response from AI');

      final json = _extractJson(text);
      return AIAnalysisResult(
        vendorName: (json['vendorName'] as String?) ?? description,
        tags: (json['tags'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        suggestedRegex: (json['suggestedRegex'] as String?) ?? '',
        type: (json['type'] as String?) ?? 'Expense',
      );
    } catch (e) {
      // Fallback
      return AIAnalysisResult(
        vendorName: description,
        tags: ['Uncategorized'],
        suggestedRegex: '',
        type: 'Expense',
      );
    }
  }

  @override
  Future<List<Map<String, dynamic>>> extractTransactionsFromPdf(
    Uint8List pdfBytes,
  ) async {
    final prompt = '''
    You are a financial assistant. Extract all transactions from the provided bank statement PDF.
    
    For each transaction, identify the "vendor_name" and suggest a "regex" pattern that could uniquely identify this vendor in the future based on the description.
    
    Return a valid JSON array where each object has:
    - date: ISO 8601 string (YYYY-MM-DD). If year is missing, assume current year.
    - amount: number (negative for credits, positive for debits).
    - description: original description text.
    - vendor_name: cleaned up merchant name.
    - regex: A regex string (CASE INSENSITIVE compatible) that matches the description for this vendor. Example: "(?i)Amazon" for description "AMAZON MKTPLACE".
    - category: array of strings (suggested categories e.g. ["Groceries", "Shopping"]).
    
    Output ONLY valid JSON.
    ''';

    final content = [
      Content.multi([
        TextPart(prompt),
        DataPart('application/pdf', pdfBytes),
      ]),
    ];

    print('Sending PDF to Gemini (${pdfBytes.length} bytes)...');
    final response = await _model.generateContent(content);
    final text = response.text;

    if (text == null) {
      throw Exception('Empty response from Gemini');
    }

    try {
      final jsonList = _extractJsonList(text);
      return jsonList.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Failed to parse AI response: $text');
      rethrow;
    }
  }

  Map<String, dynamic> _extractJson(String text) {
    try {
      // Find first { and last }
      final start = text.indexOf('{');
      final end = text.lastIndexOf('}');
      if (start == -1 || end == -1) throw FormatException('No JSON found');
      final jsonStr = text.substring(start, end + 1);
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      print('JSON Parse Error: $e\nText: $text');
      rethrow;
    }
  }

  List<dynamic> _extractJsonList(String text) {
    try {
      // Find first [ and last ]
      final start = text.indexOf('[');
      final end = text.lastIndexOf(']');
      if (start == -1 || end == -1) {
        throw FormatException('No JSON array found');
      }
      final jsonStr = text.substring(start, end + 1);
      return jsonDecode(jsonStr) as List<dynamic>;
    } catch (e) {
      print('JSON List Parse Error: $e\nText: $text');
      rethrow;
    }
  }
}
