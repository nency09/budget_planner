/// Helper class to validate if a user question is finance-related.
///
/// This ensures FinGenie AI Coach only answers questions about:
/// - Personal finances, spending, expenses, budgets, savings
/// - Subscriptions, transactions, financial habits
/// - Using the finance app
class FinanceQuestionValidator {
  static const List<String> _smallTalkPhrases = [
    'hi',
    'hello',
    'hey',
    'good morning',
    'good afternoon',
    'good evening',
    'how are you',
    'thanks',
    'thank you',
    'bye',
    'goodbye',
  ];

  static const List<String> _capabilityPhrases = [
    'what can you do',
    'how can you help',
    'what do you do',
    'your capabilities',
  ];

  static const List<String> _nonFinanceIndicators = [
    'programming',
    'coding',
    'code',
    'sports',
    'movie',
    'entertainment',
    'celebrity',
    'politics',
    'president',
    'prime minister',
    'medical',
    'medicine',
    'symptoms',
    'flu',
    'legal',
    'lawyer',
    'lawsuit',
    'weather',
    'recipe',
    'cook',
    'capital of',
    'national animal',
    'quantum physics',
  ];

  /// Finance-related keywords that indicate a valid question
  static const List<String> _financeKeywords = [
    // Core finance terms
    'expense', 'expenses', 'spend', 'spending', 'spent',
    'budget', 'budgets', 'budgeting',
    'save', 'saving', 'savings', 'saved',
    'loan', 'loans', 'debt', 'debts',
    'income', 'salary', 'earnings', 'earn',
    'transaction', 'transactions', 'payment', 'payments',
    'subscription', 'subscriptions',
    'money', 'cash', 'finance', 'financial', 'finances',
    'category', 'categories',
    'goal', 'goals', 'target', 'targets',
    'account', 'accounts', 'wallet', 'wallets',
    'bank', 'banking',
    'investment', 'investments', 'invest',
    'credit', 'debit',
    'bill', 'bills', 'billing',
    'cost', 'costs', 'price', 'prices',
    'purchase', 'purchases', 'buy', 'buying', 'bought',
    'sell', 'selling', 'sold',
    'tax', 'taxes',
    'insurance',
    'retirement',
    'emergency fund',

    // Currency symbols and terms
    '₹', 'rupee', 'rupees', 'inr',
    '\$', 'dollar', 'dollars', 'usd',
    '€', 'euro', 'euros', 'eur',
    '£', 'pound', 'pounds', 'gbp',

    // App-specific terms
    'fingenie',
    'track', 'tracking', 'record', 'recording',
    'report', 'reports', 'analytics',
    'chart', 'charts', 'graph', 'graphs',
    'balance', 'balances',
    'net worth', 'networth',

    // Financial actions
    'transfer', 'transfers', 'transferring',
    'withdraw', 'withdrawal', 'withdrawals',
    'deposit', 'deposits', 'depositing',
    'refund', 'refunds',

    // Financial planning
    'financial plan', 'financial planning',
    'tip', 'tips',
    'habit', 'habits',
    'financial review', 'analysis', 'analyze',
  ];

  /// Check if a question contains finance-related keywords
  ///
  /// Returns true if the question is finance-related, false otherwise.
  static bool isFinanceQuestion(String question) {
    if (question.trim().isEmpty) {
      return false;
    }

    // Convert to lowercase for case-insensitive matching
    final lowerQuestion = question.toLowerCase().trim();

    if (isSmallTalk(question) || isCapabilityQuestion(question)) {
      return true;
    }

    final hasNonFinanceIndicator = _nonFinanceIndicators.any(
      (indicator) => lowerQuestion.contains(indicator),
    );

    // Check if any finance keyword is present in the question
    for (final keyword in _financeKeywords) {
      if (lowerQuestion.contains(keyword.toLowerCase())) {
        if (hasNonFinanceIndicator &&
            !lowerQuestion.contains('finance') &&
            !lowerQuestion.contains('financial') &&
            !lowerQuestion.contains('money') &&
            !lowerQuestion.contains('budget') &&
            !lowerQuestion.contains('expense') &&
            !lowerQuestion.contains('spend') &&
            !lowerQuestion.contains('saving') &&
            !lowerQuestion.contains('transaction') &&
            !lowerQuestion.contains('subscription') &&
            !lowerQuestion.contains('debt') &&
            !lowerQuestion.contains('loan') &&
            !lowerQuestion.contains('income') &&
            !lowerQuestion.contains('account') &&
            !lowerQuestion.contains('wallet')) {
          return false;
        }
        return true;
      }
    }

    return false;
  }

  static bool isSmallTalk(String question) {
    final lowerQuestion = question
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'^[\s,.!?]+|[\s,.!?]+$'), '');
    return _smallTalkPhrases.any((phrase) {
      return lowerQuestion == phrase;
    });
  }

  static bool isCapabilityQuestion(String question) {
    final lowerQuestion = question
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'^[\s,.!?]+|[\s,.!?]+$'), '');
    return _capabilityPhrases.any((phrase) => lowerQuestion == phrase);
  }

  /// Get the standard rejection message for non-finance questions
  static String getRejectionMessage() {
    return "I'm FinGenie AI Coach and I specialize in personal finance. I can help with expenses, budgets, savings, income, debts, transactions, subscriptions, and financial insights.";
  }

  /// Get examples of valid finance questions for user guidance
  static List<String> getExampleQuestions() {
    return [
      "How much did I spend on food this month?",
      "What are my top spending categories?",
      "How can I save more money?",
      "Should I cancel any subscriptions?",
      "What's my current budget status?",
      "How do I track my expenses better?",
      "What are some good saving habits?",
      "How much is my net worth?",
    ];
  }
}
