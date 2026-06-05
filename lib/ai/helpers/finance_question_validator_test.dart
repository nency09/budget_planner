/// Test examples for the FinanceQuestionValidator.
///
/// Run this file to manually check finance question detection behavior.

import 'package:budget/ai/helpers/finance_question_validator.dart';

void main() {
  print('Testing FinanceQuestionValidator\n');

  final allowedQuestions = [
    "How much did I spend on food this month?",
    "What are my top spending categories?",
    "How can I save more money?",
    "Should I cancel any subscriptions?",
    "What's my current budget status?",
    "How do I track my expenses better?",
    "What are some good saving habits?",
    "How much is my net worth?",
    "I want to reduce my spending on entertainment",
    "Can you help me budget for next month?",
    "What's the best way to manage my finances?",
    "How much money do I have in my account?",
    "I need advice on my loan payments",
    "Help me understand my transaction history",
    "Hi",
    "Good morning",
    "Thank you",
    "What can you do?",
  ];

  final nonFinanceQuestions = [
    "What is the national animal of India?",
    "Who is the president of the USA?",
    "What is the capital of France?",
    "How do I cook pasta?",
    "What's the weather like today?",
    "Tell me a joke",
    "What's the latest movie release?",
    "How do I learn programming?",
    "Help me with coding",
    "Give me medical advice",
    "What are the symptoms of flu?",
    "Explain quantum physics",
  ];

  print('Allowed questions:');
  for (final question in allowedQuestions) {
    final isFinance = FinanceQuestionValidator.isFinanceQuestion(question);
    final status = isFinance ? 'ACCEPTED' : 'REJECTED';
    print('$status: "$question"');
  }

  print('\nNon-finance questions:');
  for (final question in nonFinanceQuestions) {
    final isFinance = FinanceQuestionValidator.isFinanceQuestion(question);
    final status = isFinance ? 'WRONGLY ACCEPTED' : 'CORRECTLY REJECTED';
    print('$status: "$question"');
  }

  print('\nRejection message:');
  print('"${FinanceQuestionValidator.getRejectionMessage()}"');

  print('\nExample valid questions:');
  for (final example in FinanceQuestionValidator.getExampleQuestions()) {
    print('- $example');
  }
}
