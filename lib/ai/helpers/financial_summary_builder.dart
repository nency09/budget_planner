import 'package:budget/ai/helpers/financial_data_helper.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:flutter/foundation.dart';

/// Lightweight structured summary of the user's finances for AI prompts.
class FinancialSummary {
  final double monthlySpending;
  final double monthlyIncome;
  final Map<String, double> categoryTotals;
  final double subscriptionTotal;
  final List<Map<String, dynamic>> monthlyHistory; // e.g. [{month: 'Jan', total: 21000}, ...]

  const FinancialSummary({
    required this.monthlySpending,
    required this.monthlyIncome,
    required this.categoryTotals,
    required this.subscriptionTotal,
    required this.monthlyHistory,
  });

  Map<String, dynamic> toJson() {
    return {
      'monthly_spending': monthlySpending,
      'monthly_income': monthlyIncome,
      'categories': categoryTotals,
      'subscriptions': subscriptionTotal,
      'monthly_history': monthlyHistory,
    };
  }

  /// Render a compact, human-readable summary string for prompts.
  String toPromptString({String currencySymbol = '₹'}) {
    final buffer = StringBuffer();
    buffer.writeln('Monthly Income: $currencySymbol${monthlyIncome.toStringAsFixed(0)}');
    buffer.writeln('Monthly Spending: $currencySymbol${monthlySpending.toStringAsFixed(0)}');
    buffer.writeln('Subscriptions: $currencySymbol${subscriptionTotal.toStringAsFixed(0)}');

    if (categoryTotals.isNotEmpty) {
      buffer.writeln('\nSpending by category:');
      categoryTotals.entries
          .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
      for (final entry in categoryTotals.entries) {
        buffer.writeln('- ${entry.key}: $currencySymbol${entry.value.toStringAsFixed(0)}');
      }
    }

    if (monthlyHistory.isNotEmpty) {
      buffer.writeln('\nLast months:');
      for (final m in monthlyHistory) {
        buffer.writeln('- ${m['month']}: $currencySymbol${(m['total'] as num).toDouble().toStringAsFixed(0)}');
      }
    }

    return buffer.toString();
  }
}

/// Builder that aggregates Drift data into a compact FinancialSummary.
class FinancialSummaryBuilder {
  /// Build a FinancialSummary for the current month using primary currency.
  static Future<FinancialSummary> buildForCurrentMonth() async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    // Income / expenses for current month
    final incomeExpenses = await FinancialDataHelper.calculateIncomeExpenses(
      start: monthStart,
      end: now,
    );
    final income = incomeExpenses['income'] ?? 0.0;
    final spending = incomeExpenses['expenses'] ?? 0.0;

    // Category breakdown for current month
    final categoryBreakdown = await FinancialDataHelper.getCategoryBreakdown(
      start: monthStart,
      end: now,
    );
    final Map<String, double> categoryTotals = {
      for (final item in categoryBreakdown)
        (item['name'] ?? item['category']) as String:
            (item['amount'] as num).toDouble(),
    };

    // Subscription total (local detection: special types or recurring)
    final allTransactions = await database.allTransactions;
    double subscriptionTotal = 0;
    for (final t in allTransactions) {
      final isCurrentMonth = t.dateCreated.isAfter(monthStart) && t.dateCreated.isBefore(now);
      final isSubLike = !t.income &&
          (t.type == TransactionSpecialType.subscription ||
              t.type == TransactionSpecialType.repetitive ||
              (t.reoccurrence != null && t.periodLength != null));
      if (isCurrentMonth && isSubLike && t.paid) {
        subscriptionTotal += t.amount.abs();
      }
    }

    // Historical monthly expenses for trend / prediction
    final monthlyHistory =
        await FinancialDataHelper.getHistoricalMonthlySpending(months: 3);

    final summary = FinancialSummary(
      monthlySpending: spending,
      monthlyIncome: income,
      categoryTotals: categoryTotals,
      subscriptionTotal: subscriptionTotal,
      monthlyHistory: monthlyHistory,
    );

    debugPrint('📊 FinancialSummaryBuilder: Built summary: ${summary.toJson()}');
    return summary;
  }
}

