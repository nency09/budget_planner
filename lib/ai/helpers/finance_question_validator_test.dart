/// Test examples for the FinanceQuestionValidator
/// 
/// This file demonstrates how the validator works with various questions.
/// Run this to test the finance question detection logic.

import 'package:budget/ai/helpers/finance_question_validator.dart';

void main() {
  print('🧪 Testing Finance Question Validator\n');

  // Test finance-related questions (should return true)
  final financeQuestions = [
    "How much did I spend on food this month?",
    "What are my top spending categories?",
    "How can I save more money?",
    "Should I cancel any subscriptions?",
    "What's my current budget status?",
    "How do I track my expenses better?",
    "What are some good saving habits?",
    "How much is my net worth?",
    "I want to reduce my spending on entertainment",
    "Can you help me plan my budget for next month?",
    "What's the best way to manage my finances?",
    "How much money do I have in my account?",
    "I need advice on my loan payments",
    "Help me understand my transaction history",
  ];

  // Test non-finance questions (should return false)
  final nonFinanceQuestions = [
    "What is the national animal of India?",
    "Who is the president of the USA?",
    "What is the capital of France?",
    "How do I cook pasta?",
    "What's the weather like today?",
    "Tell me a joke",
    "What's the latest movie release?",
    "How do I learn programming?",
    "What are the symptoms of flu?",
    "Explain quantum physics",
  ];

  print('✅ Finance-related questions (should be accepted):');
  for (final question in financeQuestions) {
    final isFinance = FinanceQuestionValidator.isFinanceQuestion(question);
    final status = isFinance ? '✅ ACCEPTED' : '❌ REJECTED';
    print('$status: "$question"');
  }

  print('\n❌ Non-finance questions (should be rejected):');
  for (final question in nonFinanceQuestions) {
    final isFinance = FinanceQuestionValidator.isFinanceQuestion(question);
    final status = isFinance ? '❌ WRONGLY ACCEPTED' : '✅ CORRECTLY REJECTED';
    print('$status: "$question"');
  }

  print('\n📝 Rejection message:');
  print('"${FinanceQuestionValidator.getRejectionMessage()}"');

  print('\n💡 Example valid questions:');
  for (final example in FinanceQuestionValidator.getExampleQuestions()) {
    print('• $example');
  }
}