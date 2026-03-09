import 'package:budget/database/tables.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/currencyFunctions.dart';
import 'package:flutter/foundation.dart';

/// Local financial score calculator (non-AI)
/// 
/// Calculates a 0-100 financial health score based on:
/// - Savings ratio
/// - Debt level
/// - Budget adherence
/// - Expense stability
class FinancialScoreCalculator {
  /// Calculate financial health score (0-100)
  /// 
  /// This is calculated locally without AI to keep costs down
  Future<int> calculateFinancialScore({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    debugPrint('📊 FinancialScoreCalculator: Calculating score for period ${startDate.toString().substring(0, 10)} to ${endDate.toString().substring(0, 10)}');

    final allWallets = await database.getAllWallets();
    final allWalletsObj = AllWallets(
      list: allWallets,
      indexedByPk: {for (var w in allWallets) w.walletPk: w},
    );

    // Get transactions in date range
    final transactions = await database.getAllTransactions(
      start: startDate,
      end: endDate,
      paidOnly: true,
    );

    double totalIncome = 0;
    double totalExpenses = 0;
    double totalDebt = 0;
    double totalSavings = 0;
    Map<String, double> monthlySpending = {};
    double totalBudgeted = 0;
    double totalActualSpendingInBudgets = 0;

    // Calculate income, expenses, and debt
    for (var transaction in transactions) {
      final amountInPrimaryCurrency = transaction.amount *
          amountRatioToPrimaryCurrencyGivenPk(allWalletsObj, transaction.walletFk);

      if (transaction.income) {
        totalIncome += amountInPrimaryCurrency.abs();
      } else {
        totalExpenses += amountInPrimaryCurrency.abs();
        
        // Check for debt/credit transactions
        if (transaction.type == TransactionSpecialType.debt) {
          totalDebt += amountInPrimaryCurrency.abs();
        }
      }

      // Group spending by month for stability calculation
      final monthKey = '${transaction.dateCreated.year}-${transaction.dateCreated.month}';
      if (!transaction.income) {
        monthlySpending[monthKey] = (monthlySpending[monthKey] ?? 0) + amountInPrimaryCurrency.abs();
      }
    }

    totalSavings = totalIncome - totalExpenses;

    // Calculate savings ratio (0-30 points)
    double savingsRatio = totalIncome > 0 ? (totalSavings / totalIncome) : 0.0;
    int savingsScore = (savingsRatio * 30).clamp(0, 30).round();
    debugPrint('💰 Savings ratio: ${(savingsRatio * 100).toStringAsFixed(1)}% → Score: $savingsScore/30');

    // Calculate debt level (0-20 points)
    // Lower debt = higher score
    double debtRatio = totalIncome > 0 ? (totalDebt / totalIncome) : 0.0;
    int debtScore = ((1.0 - debtRatio.clamp(0.0, 1.0)) * 20).round();
    debugPrint('💳 Debt ratio: ${(debtRatio * 100).toStringAsFixed(1)}% → Score: $debtScore/20');

    // Calculate budget adherence (0-25 points)
    final budgets = await database.getAllBudgets();
    int budgetsWithinLimit = 0;
    int totalActiveBudgets = 0;

    for (var budget in budgets) {
      final budgetStart = budget.startDate;
      final budgetEnd = budget.endDate;
      if (budgetStart == null || budgetEnd == null) continue;

      // Check if budget period overlaps with our date range
      if (budgetStart.isAfter(endDate) || budgetEnd.isBefore(startDate)) {
        continue;
      }

      totalActiveBudgets++;

      final budgetAmount = budget.amount * amountRatioToPrimaryCurrencyGivenPk(allWalletsObj, budget.walletFk);
      totalBudgeted += budgetAmount;

      final budgetTransactions = await database.getAllTransactions(
        start: budgetStart,
        end: budgetEnd,
        paidOnly: true,
        walletPks: [budget.walletFk],
        categoryFks: budget.categoryFks,
        categoryFksExclude: budget.categoryFksExclude,
        isIncome: false,
      );

      double actualSpending = 0;
      for (var t in budgetTransactions) {
        actualSpending += t.amount.abs() * amountRatioToPrimaryCurrencyGivenPk(allWalletsObj, t.walletFk);
      }

      totalActualSpendingInBudgets += actualSpending;

      if (budgetAmount > 0 && actualSpending <= budgetAmount) {
        budgetsWithinLimit++;
      }
    }

    double budgetAdherence = totalActiveBudgets > 0 
        ? (budgetsWithinLimit / totalActiveBudgets) 
        : 0.5; // Default if no budgets
    int budgetScore = (budgetAdherence * 25).round();
    debugPrint('🎯 Budget adherence: ${(budgetAdherence * 100).toStringAsFixed(1)}% → Score: $budgetScore/25');

    // Calculate expense stability (0-25 points)
    // Lower variance = higher score
    double stabilityScore = 25.0;
    if (monthlySpending.length >= 2) {
      final spendingValues = monthlySpending.values.toList();
      final avg = spendingValues.reduce((a, b) => a + b) / spendingValues.length;
      
      if (avg > 0) {
        double variance = 0;
        for (var value in spendingValues) {
          variance += ((value - avg) / avg) * ((value - avg) / avg);
        }
        variance = variance / spendingValues.length;
        
        // Lower variance = higher score (max 25 points)
        stabilityScore = (25.0 * (1.0 - variance.clamp(0.0, 1.0))).round().toDouble();
      }
    }
    int stabilityScoreInt = stabilityScore.round();
    debugPrint('📈 Expense stability → Score: $stabilityScoreInt/25');

    // Calculate total score
    int totalScore = savingsScore + debtScore + budgetScore + stabilityScoreInt;
    totalScore = totalScore.clamp(0, 100);

    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('📊 FINANCIAL SCORE BREAKDOWN:');
    debugPrint('   Savings Score: $savingsScore/30');
    debugPrint('   Debt Score: $debtScore/20');
    debugPrint('   Budget Score: $budgetScore/25');
    debugPrint('   Stability Score: $stabilityScoreInt/25');
    debugPrint('   ────────────────────────────────────────────────');
    debugPrint('   TOTAL SCORE: $totalScore/100');
    debugPrint('═══════════════════════════════════════════════════════════');

    return totalScore;
  }

  /// Get grade letter based on score
  String getGrade(int score) {
    if (score >= 90) return 'A+';
    if (score >= 80) return 'A';
    if (score >= 75) return 'B+';
    if (score >= 70) return 'B';
    if (score >= 65) return 'C+';
    if (score >= 60) return 'C';
    if (score >= 50) return 'D';
    return 'F';
  }

  /// Get score breakdown for display
  Map<String, dynamic> getScoreBreakdown({
    required int savingsScore,
    required int debtScore,
    required int budgetScore,
    required int stabilityScore,
    required int totalScore,
  }) {
    return {
      'savingsScore': {'value': savingsScore, 'max': 30, 'tip': _getSavingsTip(savingsScore)},
      'debtScore': {'value': debtScore, 'max': 20, 'tip': _getDebtTip(debtScore)},
      'budgetScore': {'value': budgetScore, 'max': 25, 'tip': _getBudgetTip(budgetScore)},
      'stabilityScore': {'value': stabilityScore, 'max': 25, 'tip': _getStabilityTip(stabilityScore)},
      'totalScore': totalScore,
      'grade': getGrade(totalScore),
    };
  }

  String _getSavingsTip(int score) {
    if (score >= 25) return 'Excellent savings rate! Keep it up.';
    if (score >= 15) return 'Good savings. Try to increase by 5-10%.';
    return 'Focus on increasing your savings rate. Aim for at least 20% of income.';
  }

  String _getDebtTip(int score) {
    if (score >= 15) return 'Low debt level. Great job!';
    if (score >= 10) return 'Moderate debt. Consider paying down high-interest debt first.';
    return 'High debt level. Create a debt repayment plan.';
  }

  String _getBudgetTip(int score) {
    if (score >= 20) return 'Excellent budget adherence!';
    if (score >= 15) return 'Good budget control. Review categories where you overspend.';
    return 'Work on staying within your budget limits.';
  }

  String _getStabilityTip(int score) {
    if (score >= 20) return 'Very stable spending patterns.';
    if (score >= 15) return 'Relatively stable spending.';
    return 'Spending varies significantly. Try to create more consistent habits.';
  }
}
