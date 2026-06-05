import 'package:budget/ai/services/financial_score_calculator.dart';
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
}
