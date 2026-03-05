/// Prompt template for calculating financial health score.
class ScorePrompt {
  static String system() {
    return '''You are a financial health scoring engine. Calculate a score from 0-100 and provide a breakdown with explanations. Target audience: Indian students and young professionals. Always respond in valid JSON only, no markdown.''';
  }

  static String user({
    required double income,
    required double expenses,
    required double savingsRate,
    required double budgetAdherence,
    required int numCategories,
    required int recurringCount,
  }) {
    return '''Monthly Income: ₹$income
Monthly Expenses: ₹$expenses
Savings Rate: ${savingsRate.toStringAsFixed(1)}%
Budget Adherence: ${budgetAdherence.toStringAsFixed(1)}%
Number of Expense Categories: $numCategories
Recurring Commitments: $recurringCount

Respond in this exact JSON format:
{
  "score": 75,
  "grade": "B+",
  "breakdown": {
    "savingsScore": {"value": 20, "max": 30, "tip": "..."},
    "budgetScore": {"value": 15, "max": 25, "tip": "..."},
    "diversityScore": {"value": 10, "max": 15, "tip": "..."},
    "commitmentScore": {"value": 20, "max": 20, "tip": "..."},
    "consistencyScore": {"value": 10, "max": 10, "tip": "..."}
  },
  "advice": "Top actionable advice"
}''';
  }
}
