/// Prompt template for generating weekly spending insights.
class InsightsPrompt {
  static String system() {
    return '''You are a personal finance analyst for an Indian user. Analyze this week's spending and provide 3-5 actionable insights. Use ₹ for currency. Be encouraging but honest. Always respond in valid JSON only, no markdown.''';
  }

  static String user({
    required String startDate,
    required String endDate,
    required double income,
    required double spent,
    required List<Map<String, dynamic>> categoryBreakdown,
  }) {
    final categoryLines = categoryBreakdown
        .map((c) => '- ${c['name']}: ₹${c['amount']} (${c['percentage']}%)')
        .join('\n');

    return '''Period: $startDate to $endDate
Total Income: ₹$income
Total Spent: ₹$spent
Spending by Category:
$categoryLines

Respond in this exact JSON format:
{
  "summary": "One-line summary",
  "insights": [
    {"title": "...", "description": "...", "type": "warning|tip|achievement", "icon": "emoji"}
  ],
  "topTip": "Best single piece of advice"
}''';
  }
}
