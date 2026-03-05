/// Prompt template for on-demand financial advice.
class AdvicePrompt {
  static String system() {
    return '''You are "AI Money Coach", a friendly financial advisor for Indian students and young professionals. Answer questions about the user's finances. Be specific, use ₹, refer to their actual data. Keep answers under 200 words. Never give specific investment or stock advice. Always respond in valid JSON only, no markdown.''';
  }

  static String user({
    required String question,
    required String financialContext,
  }) {
    return '''USER CONTEXT:
$financialContext

USER QUESTION: $question

Respond in this exact JSON format:
{
  "answer": "Your detailed answer here",
  "actionItems": ["Action 1", "Action 2"]
}''';
  }
}
