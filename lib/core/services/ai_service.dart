/// Structure returned by AI analysis
class AIAnalysisResult {
  final String vendorName;
  final List<String> tags;
  final String suggestedRegex;
  final String type; // Expense, Income, Transfer

  AIAnalysisResult({
    required this.vendorName,
    required this.tags,
    required this.suggestedRegex,
    required this.type,
  });
}

abstract class AIService {
  /// Analyzes a transaction description to identify vendor and tags.
  /// [context] can provide additional info like the Bank Name (e.g. "Chase").
  Future<AIAnalysisResult> analyzeTransaction(
    String description, {
    String? context,
  });
}

class MockAIService implements AIService {
  @override
  Future<AIAnalysisResult> analyzeTransaction(
    String description, {
    String? context,
  }) async {
    // Simulate network delay
    await Future.delayed(Duration(milliseconds: 200));

    final lower = description.toLowerCase();
    final lowerContext = context?.toLowerCase() ?? '';

    if (lower.contains('sparkfun')) {
      return AIAnalysisResult(
        vendorName: 'SparkFun',
        tags: ['Electronics', 'Education', 'Hardware'],
        suggestedRegex: '(?i)SparkFun',
        type: 'Expense',
      );
    }

    if (lower.contains('united')) {
      return AIAnalysisResult(
        vendorName: 'United Airlines',
        tags: ['Travel', 'Transport'],
        suggestedRegex: '(?i)United Airlines',
        type: 'Expense',
      );
    }

    if ((lower.contains('payment') && lower.contains('thank')) ||
        lower.contains('credit card')) {
      return AIAnalysisResult(
        vendorName: 'Credit Card Payment',
        tags: ['Transfer', 'Payment'],
        suggestedRegex: '(?i)(PAYMENT.*THANK|CREDIT CARD)',
        type: 'Transfer',
      );
    }

    if (lower.contains('gusto') || lower.contains('payroll')) {
      return AIAnalysisResult(
        vendorName: 'Gusto Payroll',
        tags: ['Income', 'Salary'],
        suggestedRegex: '(?i)Gusto',
        type: 'Income',
      );
    }

    // Best Guess Logic
    if (lower.contains('touchstone') || lower.contains('climbing')) {
      return AIAnalysisResult(
        vendorName: 'Touchstone Climbing',
        tags: ['Fitness', 'Gym', 'Sports', 'Recreation'],
        suggestedRegex: '(?i)Touchstone', // Learn just the unique part
        type: 'Expense',
      );
    }

    if (lower.contains('kfc')) {
      return AIAnalysisResult(
        vendorName: 'KFC',
        tags: ['Fast Food', 'Dining'],
        suggestedRegex: '(?i)KFC',
        type: 'Expense',
      );
    }

    if (lower.contains('bicycle')) {
      return AIAnalysisResult(
        vendorName: 'Madison Bicycle Shop',
        tags: ['Sports', 'Shopping', 'Hobbies'],
        suggestedRegex: '(?i)Madison Bicycle',
        type: 'Expense',
      );
    }

    // CD Deposit
    if (lower.contains('deposit')) {
      return AIAnalysisResult(
        vendorName: 'Bank Deposit',
        tags: ['Income', 'Financial', 'Savings'],
        suggestedRegex: '(?i)DEPOSIT',
        type: 'Income',
      );
    }

    // Interest Payment (User Feedback)
    if (lower.contains('intrst') || lower.contains('interest')) {
      var vendor = 'Interest Payment';
      // If we know the bank context, use it as the vendor
      if (lowerContext.contains('chase') || lowerContext.contains('bank')) {
        vendor = context!;
        // Clean it up slightly if needed, but using context directly is safe for now
      }

      return AIAnalysisResult(
        vendorName: vendor,
        tags: ['Interest', 'Fees', 'Finance'],
        suggestedRegex: '(?i)(INTRST|INTEREST)',
        type: 'Expense',
      );
    }

    // Web Search Simulations (Common Vendors)
    if (lower.contains('starbucks')) {
      return AIAnalysisResult(
        vendorName: 'Starbucks',
        tags: ['Coffee', 'Dining', 'Drinks'],
        suggestedRegex: '(?i)Starbucks',
        type: 'Expense',
      );
    }

    if (lower.contains('mcdonald')) {
      return AIAnalysisResult(
        vendorName: "McDonald's",
        tags: ['Fast Food', 'Dining'],
        suggestedRegex: "(?i)McDonald's",
        type: 'Expense',
      );
    }

    // Default fallback - try to guess from words?
    // For Tectra Inc - assume business services?
    if (lower.contains('inc') || lower.contains('llc')) {
      return AIAnalysisResult(
        vendorName: description,
        tags: ['Business Services', 'Contractors'],
        suggestedRegex: '(?i)${RegExp.escape(description)}',
        type: 'Expense',
      );
    }

    return AIAnalysisResult(
      vendorName: description,
      tags: ['Uncategorized', 'Review Needed'],
      suggestedRegex: '',
      type: 'Expense',
    );
  }
}
