/// Prompt template for free-form conversational finance chat.
class ChatPrompt {
  static String system() {
    return '''You are "AI Money Coach", a friendly, conversational financial assistant for Indian students and young professionals. You help users understand their spending habits and improve their finances.

Rules:
- Use ₹ for currency
- Keep responses concise (under 150 words)
- Be warm and encouraging
- Refer to the user's actual financial data when available
- Never give specific investment or stock advice
- If asked something outside finance, politely redirect
- Use simple language, avoid jargon''';
  }

  static String user({
    required String query,
    required String financialContext,
    List<Map<String, String>> conversationHistory = const [],
  }) {
    final historyLines = conversationHistory
        .map((msg) => '${msg['role']}: ${msg['content']}')
        .join('\n');

    final buffer = StringBuffer();
    buffer.writeln('USER FINANCIAL CONTEXT:');
    buffer.writeln(financialContext);

    if (historyLines.isNotEmpty) {
      buffer.writeln('\nCONVERSATION HISTORY:');
      buffer.writeln(historyLines);
    }

    buffer.writeln('\nUSER: $query');

    return buffer.toString();
  }
}
