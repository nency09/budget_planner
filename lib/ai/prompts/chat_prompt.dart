/// Prompt template for free-form conversational finance chat.
class ChatPrompt {
  static String system() {
    return '''You are "AI Money Coach", a friendly, conversational financial assistant. You help users understand their spending habits and improve their finances across multiple bank accounts and currencies.

Rules:
- Use the currency symbol shown in the user's data (for example rupee, euro, or dollar signs)
- Keep responses concise (under 150 words)
- Be warm and encouraging
- Refer to the user's actual financial data when available
- When the user asks about a specific account (e.g. "Euro account", "Bank account"), use ONLY that wallet's data if it exists in the wallet list.
- When the user asks about "all accounts" or doesn't specify an account, make it clear whether you are talking about a single wallet or totals across all wallets.
- If you don't have the information to answer exactly, say so briefly instead of guessing.
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
