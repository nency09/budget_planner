/// Helper class to validate if a user question is finance-related.
/// 
/// This ensures the AI Money Coach only answers questions about:
/// - Personal finances, spending, expenses, budgets, savings
/// - Subscriptions, transactions, financial habits
/// - Using the finance app
class FinanceQuestionValidator {
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
    'cashew', 'app', 'application',
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
    'plan', 'planning', 'strategy',
    'advice', 'tip', 'tips', 'help',
    'habit', 'habits',
    'review', 'analysis', 'analyze',
  ];

  /// Check if a question contains finance-related keywords
  /// 
  /// Returns true if the question is finance-related, false otherwise.
  static bool isFinanceQuestion(String question) {
    if (question.trim().isEmpty) {
      return false;
    }
    
    // Convert to lowercase for case-insensitive matching
    final lowerQuestion = question.toLowerCase();
    
    // Check if any finance keyword is present in the question
    for (final keyword in _financeKeywords) {
      if (lowerQuestion.contains(keyword.toLowerCase())) {
        return true;
      }
    }
    
    return false;
  }

  /// Get the standard rejection message for non-finance questions
  static String getRejectionMessage() {
    return "I can only help with questions related to your finances, expenses, and budgets.";
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