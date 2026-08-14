import 'package:budget/ai/services/financial_score_calculator.dart';
import 'package:budget/ai/helpers/financial_summary_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('financial score grades are mapped correctly', () {
    final calculator = FinancialScoreCalculator();

    expect(calculator.getGrade(95), 'A+');
    expect(calculator.getGrade(80), 'A');
    expect(calculator.getGrade(70), 'B');
    expect(calculator.getGrade(60), 'C');
    expect(calculator.getGrade(50), 'D');
    expect(calculator.getGrade(49), 'F');
  });

  test('financial summary lists categories from highest to lowest spending',
      () {
    const summary = FinancialSummary(
      monthlySpending: 500,
      monthlyIncome: 1000,
      subscriptionTotal: 0,
      categoryTotals: {'Food': 125, 'Rent': 300, 'Travel': 75},
      monthlyHistory: [],
    );

    final prompt = summary.toPromptString();
    expect(prompt.indexOf('- Rent:'), lessThan(prompt.indexOf('- Food:')));
    expect(prompt.indexOf('- Food:'), lessThan(prompt.indexOf('- Travel:')));
  });
}
