/// Prompt template for transaction categorization.
class CategorizationPrompt {
  static String system() {
    return '''You are a financial transaction categorizer. Given a merchant name and transaction note, classify it into one of the user's existing categories. Return ONLY the exact category name from the list, nothing else.''';
  }

  static String user({
    required String merchantName,
    required String note,
    required List<String> categories,
  }) {
    return '''Merchant: "$merchantName"
Note: "$note"
Available categories: [${categories.join(', ')}]

Respond with just the category name.''';
  }
}
