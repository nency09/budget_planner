import 'package:budget/database/tables.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/currencyFunctions.dart';
import 'package:flutter/foundation.dart';

/// Helper class to calculate real financial data from database for AI analysis
class FinancialDataHelper {
  /// Get all transactions in a date range with currency conversion
  static Future<List<Transaction>> _getTransactionsInRange(
    DateTime start,
    DateTime end,
  ) async {
    final allTransactions = await database.allTransactions;
    debugPrint('📊 FinancialDataHelper: Total transactions in database: ${allTransactions.length}');
    
    final startDate = start.subtract(Duration(seconds: 1));
    final endDate = end.add(Duration(days: 1));
    
    final filtered = allTransactions.where((t) {
      final isInRange = t.dateCreated.isAfter(startDate) && 
                       t.dateCreated.isBefore(endDate);
      final isPaid = t.paid;
      return isInRange && isPaid;
    }).toList();
    
    debugPrint('📊 FinancialDataHelper: Transactions in range (${start.toString().substring(0, 10)} to ${end.toString().substring(0, 10)}): ${filtered.length}');
    debugPrint('📊 FinancialDataHelper: Date range - Start: $startDate, End: $endDate');
    
    return filtered;
  }

  /// Calculate total income and expenses for a date range
  static Future<Map<String, double>> calculateIncomeExpenses({
    required DateTime start,
    required DateTime end,
  }) async {
    final transactions = await _getTransactionsInRange(start, end);
    final allWallets = await database.getAllWallets();
    final allWalletsObj = AllWallets(
      list: allWallets,
      indexedByPk: {for (var w in allWallets) w.walletPk: w},
    );

    double totalIncome = 0;
    double totalExpenses = 0;
    int incomeCount = 0;
    int expenseCount = 0;

    debugPrint('💰 FinancialDataHelper: Processing ${transactions.length} transactions...');
    
    for (var transaction in transactions) {
      final ratio = amountRatioToPrimaryCurrencyGivenPk(
        allWalletsObj,
        transaction.walletFk,
      );
      final amount = transaction.amount.abs() * ratio;

      if (transaction.income) {
        totalIncome += amount;
        incomeCount++;
        debugPrint('  💵 Income: ${transaction.name} = ₹${amount.toStringAsFixed(2)}');
      } else {
        totalExpenses += amount;
        expenseCount++;
        debugPrint('  💸 Expense: ${transaction.name} = ₹${amount.toStringAsFixed(2)}');
      }
    }

    debugPrint('💰 FinancialDataHelper: RESULTS - Income: ₹${totalIncome.toStringAsFixed(2)} ($incomeCount transactions), Expenses: ₹${totalExpenses.toStringAsFixed(2)} ($expenseCount transactions)');

    return {
      'income': totalIncome,
      'expenses': totalExpenses,
    };
  }

  /// Get category breakdown for a date range
  static Future<List<Map<String, dynamic>>> getCategoryBreakdown({
    required DateTime start,
    required DateTime end,
  }) async {
    final transactions = await _getTransactionsInRange(start, end);
    final allWallets = await database.getAllWallets();
    final allWalletsObj = AllWallets(
      list: allWallets,
      indexedByPk: {for (var w in allWallets) w.walletPk: w},
    );

    Map<String, double> categoryTotals = {};

    debugPrint('📂 FinancialDataHelper: Calculating category breakdown from ${transactions.length} transactions...');

    for (var transaction in transactions) {
      if (!transaction.income && transaction.categoryFk != "0") {
        final category = await database.getCategory(transaction.categoryFk).$2;
        final ratio = amountRatioToPrimaryCurrencyGivenPk(
          allWalletsObj,
          transaction.walletFk,
        );
        final amount = transaction.amount.abs() * ratio;
        categoryTotals[category.name] =
            (categoryTotals[category.name] ?? 0) + amount;
        debugPrint('  📁 ${category.name}: +₹${amount.toStringAsFixed(2)} (Total: ₹${categoryTotals[category.name]!.toStringAsFixed(2)})');
      }
    }

    // Sort by amount descending
    final sorted = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Calculate total for percentage calculation
    final totalSpending = sorted.fold<double>(0.0, (sum, entry) => sum + entry.value);

    debugPrint('📂 FinancialDataHelper: Category breakdown - ${sorted.length} categories');
    debugPrint('📂 FinancialDataHelper: Total spending: ₹${totalSpending.toStringAsFixed(2)}');
    
    final result = sorted.map((e) {
      final percentage = totalSpending > 0 ? (e.value / totalSpending * 100) : 0.0;
      debugPrint('  📊 ${e.key}: ₹${e.value.toStringAsFixed(2)} (${percentage.toStringAsFixed(1)}%)');
      return {
        'category': e.key,
        'name': e.key, // Also include 'name' for prompt compatibility
        'amount': e.value,
        'percentage': percentage,
      };
    }).toList();

    return result;
  }

  /// Get number of unique categories used
  static Future<int> getCategoryCount({
    required DateTime start,
    required DateTime end,
  }) async {
    final transactions = await _getTransactionsInRange(start, end);
    final uniqueCategories = transactions
        .where((t) => !t.income && t.categoryFk != "0")
        .map((t) => t.categoryFk)
        .toSet();
    return uniqueCategories.length;
  }

  /// Get recurring expense count (subscriptions/repetitive transactions)
  static Future<int> getRecurringExpenseCount() async {
    final allTransactions = await database.allTransactions;
    final recurring = allTransactions.where((t) {
      return !t.income &&
          t.paid &&
          (t.type == TransactionSpecialType.subscription ||
              t.type == TransactionSpecialType.repetitive ||
              (t.reoccurrence != null && t.periodLength != null));
    }).toList();
    return recurring.length;
  }

  /// Calculate budget adherence (how well user sticks to budgets)
  static Future<double> calculateBudgetAdherence({
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      // Get all budgets
      final budgets = await database.getAllBudgets();
      if (budgets.isEmpty) return 0.5; // Default if no budgets

      int budgetsWithinLimit = 0;
      int totalBudgets = 0;

      for (var budget in budgets) {
        final startDate = budget.startDate;
        final endDate = budget.endDate;
        // Skip budgets without date range
        if (startDate == null || endDate == null) continue;

        // Check if budget period overlaps with our date range
        if (startDate.isAfter(end) || endDate.isBefore(start)) {
          continue;
        }

        totalBudgets++;

        // Get actual spending for this budget
        final budgetTransactions = await _getTransactionsInRange(
          startDate,
          endDate,
        );

        final allWallets = await database.getAllWallets();
        final allWalletsObj = AllWallets(
          list: allWallets,
          indexedByPk: {for (var w in allWallets) w.walletPk: w},
        );

        double actualSpending = 0;
        for (var t in budgetTransactions) {
          if (!t.income &&
              t.paid &&
              (t.sharedReferenceBudgetPk == budget.budgetPk ||
                  budget.budgetPk == "0")) {
            final ratio = amountRatioToPrimaryCurrencyGivenPk(
              allWalletsObj,
              t.walletFk,
            );
            actualSpending += t.amount.abs() * ratio;
          }
        }

        // Check if within budget limit
        if (budget.amount > 0 && actualSpending <= budget.amount) {
          budgetsWithinLimit++;
        }
      }

      if (totalBudgets == 0) return 0.5;
      return budgetsWithinLimit / totalBudgets;
    } catch (e) {
      debugPrint('Error calculating budget adherence: $e');
      return 0.5; // Default value
    }
  }

  /// Get historical monthly spending for predictions
  static Future<List<Map<String, dynamic>>> getHistoricalMonthlySpending({
    int months = 3,
  }) async {
    final now = DateTime.now();
    final List<Map<String, dynamic>> history = [];

    for (int i = months; i >= 1; i--) {
      final monthStart = DateTime(now.year, now.month - i, 1);
      final monthEnd = DateTime(now.year, now.month - i + 1, 0, 23, 59, 59);

      final data = await calculateIncomeExpenses(
        start: monthStart,
        end: monthEnd,
      );

      final monthNames = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];

      final monthName = monthNames[monthStart.month - 1];
      final total = data['expenses'] ?? 0.0;
      debugPrint('📅 Historical month ${monthName}: ₹${total.toStringAsFixed(2)}');
      
      history.add({
        'month': monthName,
        'total': total,
      });
    }

    return history;
  }

  /// Get current month category spending for predictions
  static Future<List<Map<String, dynamic>>> getCurrentMonthCategories() async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = now;

    final breakdown = await getCategoryBreakdown(start: monthStart, end: monthEnd);
    
    // Ensure 'name' field exists for prediction prompt compatibility
    return breakdown.map((item) => {
      'category': item['category'],
      'name': item['name'] ?? item['category'], // Use name if available, fallback to category
      'amount': item['amount'],
    }).toList();
  }
}
