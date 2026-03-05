/// Prompt template for predicting next month's spending.
class PredictionPrompt {
  static String system() {
    return '''You are a spending predictor. Given the last 6 months of data, predict next month's total and per-category spending. Use ₹ for currency. Always respond in valid JSON only, no markdown.''';
  }

  static String user({
    required List<Map<String, dynamic>> historicalMonths,
    required List<Map<String, dynamic>> currentCategories,
  }) {
    final monthLines = historicalMonths
        .map((m) => '- ${m['month']}: ₹${m['total']}')
        .join('\n');
    final categoryLines = currentCategories
        .map((c) => '- ${c['name']}: ₹${c['amount']}')
        .join('\n');

    return '''Historical Monthly Totals:
$monthLines

Current Month Categories:
$categoryLines

Respond in this exact JSON format:
{
  "predictedTotal": 25000,
  "confidence": 0.78,
  "byCategory": [
    {"name": "Food", "predicted": 8000, "trend": "up|down|stable"}
  ],
  "warning": "Optional alert if overspend likely, or null"
}''';
  }
}
