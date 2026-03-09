/// Data model for AI-generated financial advice responses.
class AIAdvice {
  final String answer;
  final List<String> actionItems;
  final DateTime generatedAt;

  AIAdvice({
    required this.answer,
    this.actionItems = const [],
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? DateTime.now();

  factory AIAdvice.fromJson(Map<String, dynamic> json) {
    return AIAdvice(
      answer: json['answer'] as String? ?? '',
      actionItems: (json['actionItems'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      generatedAt: json['generatedAt'] != null
          ? DateTime.parse(json['generatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'answer': answer,
        'actionItems': actionItems,
        'generatedAt': generatedAt.toIso8601String(),
      };
}

/// Context object passed to AI advice/chat calls.
/// Contains aggregated (non-PII) financial data.
class FinancialContext {
  final double monthlyIncome;
  final double monthlyExpenses;
  final List<String> topCategories;
  final List<String> activeBudgets;
  final List<String> savingsGoals;
  final String currency;
  // Optional per-wallet summary: name, currency code, and current balance
  final List<Map<String, dynamic>> wallets;

  FinancialContext({
    required this.monthlyIncome,
    required this.monthlyExpenses,
    required this.topCategories,
    this.activeBudgets = const [],
    this.savingsGoals = const [],
    this.currency = '₹',
    this.wallets = const [],
  });

  String toPromptString() {
    final buffer = StringBuffer();
    buffer.writeln('Monthly Income: $currency$monthlyIncome');
    buffer.writeln('Monthly Expenses: $currency$monthlyExpenses');
    buffer.writeln('Top Categories: ${topCategories.join(", ")}');
    if (activeBudgets.isNotEmpty) {
      buffer.writeln('Active Budgets: ${activeBudgets.join(", ")}');
    }
    if (savingsGoals.isNotEmpty) {
      buffer.writeln('Savings Goals: ${savingsGoals.join(", ")}');
    }
    if (wallets.isNotEmpty) {
      buffer.writeln('\nWallet balances:');
      for (final w in wallets) {
        final name = w['name']?.toString() ?? 'Wallet';
        final cur = w['currency']?.toString().toUpperCase() ?? '';
        final balance = (w['balance'] as num?)?.toDouble() ?? 0.0;
        buffer.writeln('- $name ($cur): $balance');
      }
    }
    return buffer.toString();
  }
}

/// Represents a detected recurring subscription pattern.
class DetectedSubscription {
  final String merchantName;
  final double estimatedAmount;
  final String estimatedFrequency; // "monthly", "weekly", "yearly"
  final int occurrenceCount;
  final DateTime lastSeen;

  DetectedSubscription({
    required this.merchantName,
    required this.estimatedAmount,
    required this.estimatedFrequency,
    required this.occurrenceCount,
    required this.lastSeen,
  });

  factory DetectedSubscription.fromJson(Map<String, dynamic> json) {
    return DetectedSubscription(
      merchantName: json['merchantName'] as String? ?? '',
      estimatedAmount: (json['estimatedAmount'] as num?)?.toDouble() ?? 0,
      estimatedFrequency: json['estimatedFrequency'] as String? ?? 'monthly',
      occurrenceCount: (json['occurrenceCount'] as num?)?.toInt() ?? 0,
      lastSeen: json['lastSeen'] != null
          ? DateTime.parse(json['lastSeen'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'merchantName': merchantName,
        'estimatedAmount': estimatedAmount,
        'estimatedFrequency': estimatedFrequency,
        'occurrenceCount': occurrenceCount,
        'lastSeen': lastSeen.toIso8601String(),
      };
}
