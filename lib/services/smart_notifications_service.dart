import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart' show getBudgetDate;
import 'package:budget/struct/currencyFunctions.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/notificationsGlobal.dart';
import 'package:budget/struct/settings.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// Smart Notifications Service
/// Provides high-value, AI-powered notifications that users actually want
class SmartNotificationsService {
  static final SmartNotificationsService _instance =
      SmartNotificationsService._internal();
  factory SmartNotificationsService() => _instance;
  SmartNotificationsService._internal();

  // Notification IDs
  static const int weeklyMoneyStoryId = 1000;
  static const int savingsOpportunityId = 1001;
  static const int positiveWinId = 1002;
  static const int budgetWarningId = 1003;
  static const int transactionInsightId = 1004;
  static const int subscriptionReminderID = 1005;
  static const int reactivationNudgeId = 1006;

  // Frequency tracking keys
  static const String lastWeeklySummaryKey = 'lastWeeklySummary';
  static const String lastSavingsOpportunityKey = 'lastSavingsOpportunity';
  static const String lastPositiveWinKey = 'lastPositiveWin';
  static const String lastBudgetWarningKey = 'lastBudgetWarning';
  static const String scheduledSubscriptionIdsKey =
      'scheduledSmartSubscriptionIds';

  /// 1. Weekly "Money Story" summary
  /// Sends once per week with spending insights
  Future<void> scheduleWeeklyMoneyStory({bool ignoreFrequency = false}) async {
    if (!_canSendNotification('weeklyInsights')) return;
    if (!ignoreFrequency &&
        !_respectsFrequencyLimit(lastWeeklySummaryKey, days: 7)) {
      return;
    }

    final summary = await _generateWeeklySummary();
    if (summary == null) return;

    final scheduled = await _scheduleNotification(
      id: weeklyMoneyStoryId,
      title: '📊 Your Weekly Money Story',
      body: summary,
      payload: 'weekly_summary',
      scheduledDate: _getNextWeeklyTime(),
    );

    if (scheduled) await _updateLastSent(lastWeeklySummaryKey);
  }

  /// 2. Smart Savings Opportunity
  /// Detects unused subscriptions, high fees, duplicate services
  Future<void> checkAndNotifySavingsOpportunity() async {
    if (!_canSendNotification('savingsOpportunities')) return;
    if (!_respectsFrequencyLimit(lastSavingsOpportunityKey, days: 3)) return;

    final opportunity = await _detectSavingsOpportunity();
    if (opportunity == null) return;

    final sent = await _sendImmediateNotification(
      id: savingsOpportunityId,
      title: '💡 Smart Savings Tip',
      body: opportunity['message']!,
      payload: opportunity['action']!,
    );

    if (sent) await _updateLastSent(lastSavingsOpportunityKey);
  }

  /// 3. Positive "Win" Notifications
  /// Celebrates achievements and milestones
  Future<void> checkAndNotifyPositiveWins() async {
    if (!_canSendNotification('goalReminders')) return;
    if (!_respectsFrequencyLimit(lastPositiveWinKey, days: 7)) return;

    final win = await _detectPositiveWin();
    if (win == null) return;

    final sent = await _sendImmediateNotification(
      id: positiveWinId,
      title: '🎉 ${win['title']}',
      body: win['message']!,
      payload: win['action']!,
    );
    if (sent) await _updateLastSent(lastPositiveWinKey);
  }

  /// 4. Budget Warning / Risk Alert
  /// Gentle warnings about budget overruns
  Future<void> checkAndNotifyBudgetWarnings() async {
    if (!_canSendNotification('budgetAlerts')) return;
    if (!_respectsFrequencyLimit(lastBudgetWarningKey, days: 7)) return;

    final warning = await _detectBudgetRisk();
    if (warning == null) return;

    final sent = await _sendImmediateNotification(
      id: budgetWarningId,
      title: '⚠️ Budget Alert',
      body: warning['message']!,
      payload: warning['action']!,
    );

    if (sent) await _updateLastSent(lastBudgetWarningKey);
  }

  /// 5. Transaction Insight
  /// Asks about big transactions or categorization
  Future<void> notifyTransactionInsight(
      Transaction transaction, double amount) async {
    if (!_canSendNotification('transactionInsights')) return;
    if (amount < 1000) return; // Only for significant transactions

    await _sendImmediateNotification(
      id: transactionInsightId,
      title: '💳 Large Transaction Detected',
      body:
          'You spent ₹${amount.toStringAsFixed(0)}. Should I help categorize this?',
      payload: 'transaction_${transaction.transactionPk}',
    );
  }

  /// 6. Subscription Reminder
  /// Reminds before recurring subscriptions
  Future<void> scheduleSubscriptionReminders() async {
    if (!_canSendNotification('subscriptionReminders')) return;

    final upcomingSubscriptions = await _getUpcomingSubscriptions();
    for (final id in _readIntList(scheduledSubscriptionIdsKey)) {
      await flutterLocalNotificationsPlugin.cancel(id);
    }

    final scheduledIds = <int>[];

    for (final sub in upcomingSubscriptions) {
      final id = _subscriptionNotificationId(sub['id'] as String);
      final scheduled = await _scheduleNotification(
        id: id,
        title: '🔔 Subscription Renewal',
        body:
            '${sub['name']} ₹${sub['amount']} renews tomorrow. Still using it?',
        payload: 'subscription_${sub['id']}',
        scheduledDate: sub['reminderDate'],
      );
      if (scheduled) scheduledIds.add(id);
    }
    await updateSettings(scheduledSubscriptionIdsKey, scheduledIds,
        updateGlobalState: false);
  }

  Future<void> _cancelSubscriptionReminders() async {
    for (final id in _readIntList(scheduledSubscriptionIdsKey)) {
      await flutterLocalNotificationsPlugin.cancel(id);
    }
    await updateSettings(scheduledSubscriptionIdsKey, const <int>[],
        updateGlobalState: false);
  }

  /// 7. Re-activation Nudge
  /// Gentle reminder if user hasn't opened app in 14+ days
  Future<void> scheduleReactivationNudge() async {
    if (!_canSendNotification('notifications')) return;
    const daysSinceOpened = 14;

    await _scheduleNotification(
      id: reactivationNudgeId,
      title: '👋 Quick Check-In',
      body:
          'A lot can change in $daysSinceOpened days. Want a 30-second AI check-up?',
      payload: 'reactivation',
      scheduledDate: DateTime.now().add(const Duration(days: 14)),
    );
  }

  // ============================================================================
  // HELPER METHODS - Detection & Analysis
  // ============================================================================

  Future<String?> _generateWeeklySummary() async {
    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: 7));

      final transactions = await database.allTransactions;
      final thisWeek = transactions
          .where((t) => t.dateCreated.isAfter(weekStart) && t.paid)
          .toList();

      if (thisWeek.isEmpty) return null;

      double thisWeekTotal = 0;
      double lastWeekTotal = 0;
      for (var t in thisWeek) {
        if (!t.income) {
          thisWeekTotal += t.amount.abs();
        }
      }

      // Compare with last week
      final lastWeekStart = weekStart.subtract(Duration(days: 7));
      final lastWeek = transactions
          .where((t) =>
              t.dateCreated.isAfter(lastWeekStart) &&
              t.dateCreated.isBefore(weekStart) &&
              t.paid)
          .toList();

      for (var t in lastWeek) {
        if (!t.income) lastWeekTotal += t.amount.abs();
      }

      final diff = lastWeekTotal - thisWeekTotal;
      if (diff > 0) {
        return 'This week you saved ₹${diff.toStringAsFixed(0)} vs last week! Want a plan to save more?';
      } else {
        return 'You spent ₹${(-diff).toStringAsFixed(0)} more this week. Let\'s find ways to cut back.';
      }
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, String>?> _detectSavingsOpportunity() async {
    // Check for unused subscriptions
    final subscriptions = await database.allTransactions;
    // Logic to detect unused subscriptions, high fees, etc.

    // Example: Unused subscription
    // return {
    //   'message': 'You paid ₹399 for a subscription you haven\'t used in 45 days. Want help cancelling?',
    //   'action': 'subscriptions'
    // };

    final now = DateTime.now();
    final recentTransactions = subscriptions
        .where((transaction) =>
            transaction.paid &&
            !transaction.income &&
            (transaction.type == TransactionSpecialType.subscription ||
                transaction.type == TransactionSpecialType.repetitive) &&
            transaction.dateCreated
                .isAfter(now.subtract(const Duration(days: 90))))
        .toList();
    final recurringByName = <String, List<Transaction>>{};
    for (final transaction in recentTransactions) {
      final name = transaction.name.trim();
      if (name.isEmpty) continue;
      recurringByName
          .putIfAbsent(name.toLowerCase(), () => [])
          .add(transaction);
    }
    for (final transactions in recurringByName.values) {
      transactions.sort((a, b) => b.dateCreated.compareTo(a.dateCreated));
      if (transactions.length < 2) continue;
      final latest = transactions.first;
      final previousAmounts = transactions
          .skip(1)
          .map((transaction) => transaction.amount.abs())
          .toList();
      final averagePrevious =
          previousAmounts.reduce((a, b) => a + b) / previousAmounts.length;
      if (averagePrevious > 0 &&
          latest.amount.abs() >= averagePrevious * 1.25) {
        return {
          'message':
              '${latest.name} increased from about ${averagePrevious.toStringAsFixed(0)} to ${latest.amount.abs().toStringAsFixed(0)}. Review this renewal.',
          'action': 'subscriptions',
        };
      }
    }
    if (recurringByName.length >= 3) {
      return {
        'message':
            'You have ${recurringByName.length} recurring payments in the last 90 days. Review the subscriptions you still use.',
        'action': 'subscriptions',
      };
    }
    return null;
  }

  Future<Map<String, String>?> _detectPositiveWin() async {
    // Check for achievements:
    // - Stayed within budget
    // - Reached goal milestone
    // - Expense logging streak

    try {
      final now = DateTime.now();
      final allWallets = await _loadAllWallets();
      final transactions = (await database.allTransactions)
          .where((transaction) =>
              transaction.paid &&
              transaction.dateCreated
                  .isAfter(now.subtract(const Duration(days: 7))))
          .toList();
      if (transactions.length < 3) return null;

      double income = 0;
      double expenses = 0;
      for (final transaction in transactions) {
        final amount = transaction.amount.abs() *
            amountRatioToPrimaryCurrencyGivenPk(
                allWallets, transaction.walletFk);
        if (transaction.income) {
          income += amount;
        } else {
          expenses += amount;
        }
      }
      if (income > 0 && expenses < income) {
        return {
          'title': 'Great week',
          'message':
              'You recorded ${expenses.toStringAsFixed(0)} in spending and stayed below this week\'s ${income.toStringAsFixed(0)} income.',
          'action': 'activity',
        };
      }
    } catch (_) {
      // A celebratory notification must never interrupt normal app use.
    }
    return null;
  }

  Future<Map<String, String>?> _detectBudgetRisk() async {
    try {
      final budgets = await database.getAllBudgets();
      final now = DateTime.now();
      final allWallets = await _loadAllWallets();
      final transactions = await database.allTransactions;

      for (final budget in budgets) {
        if (budget.archived || budget.income || budget.amount <= 0) continue;
        final period = getBudgetDate(budget, now);
        if (now.isBefore(period.start) || now.isAfter(_endOfDay(period.end))) {
          continue;
        }
        final budgetAmount = budget.amount *
            amountRatioToPrimaryCurrencyGivenPk(allWallets, budget.walletFk);
        if (budgetAmount <= 0) continue;

        double spent = 0;
        for (final transaction in transactions) {
          if (!transaction.paid || transaction.income) continue;
          if (!_isInRange(transaction.dateCreated, period.start, period.end)) {
            continue;
          }
          if (!_belongsToBudget(transaction, budget)) continue;
          spent += transaction.amount.abs() *
              amountRatioToPrimaryCurrencyGivenPk(
                  allWallets, transaction.walletFk);
        }

        final usage = spent / budgetAmount;
        final duration =
            _endOfDay(period.end).difference(period.start).inSeconds;
        final elapsed = now.difference(period.start).inSeconds;
        final elapsedRatio = duration <= 0 ? 1.0 : elapsed / duration;
        if (usage < 1 && (usage < 0.8 || usage <= elapsedRatio)) continue;

        final percent = (usage * 100).round();
        return {
          'message': usage >= 1
              ? 'You have used $percent% of your ${budget.name} budget.'
              : 'You have used $percent% of your ${budget.name} budget faster than this period is progressing.',
          'action': 'budget_$budget.budgetPk',
        };
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> _getUpcomingSubscriptions() async {
    final now = DateTime.now();
    final tomorrow =
        DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    final endOfTomorrow = tomorrow.add(const Duration(days: 1));
    final reminderDate =
        DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9);
    final subscriptions = await database.allTransactions;

    return subscriptions
        .where((transaction) =>
            !transaction.income &&
            !transaction.paid &&
            transaction.type == TransactionSpecialType.subscription &&
            !transaction.dateCreated.isBefore(tomorrow) &&
            transaction.dateCreated.isBefore(endOfTomorrow))
        .map((transaction) => <String, dynamic>{
              'id': transaction.transactionPk,
              'name': transaction.name,
              'amount': transaction.amount.abs().toStringAsFixed(0),
              'reminderDate': reminderDate,
            })
        .toList();
  }

  Future<AllWallets> _loadAllWallets() async {
    final wallets = await database.getAllWallets();
    return AllWallets(
      list: wallets,
      indexedByPk: {for (final wallet in wallets) wallet.walletPk: wallet},
    );
  }

  bool _belongsToBudget(Transaction transaction, Budget budget) {
    if (budget.addedTransactionsOnly &&
        transaction.sharedReferenceBudgetPk != budget.budgetPk) {
      return false;
    }
    if (budget.sharedKey != null &&
        transaction.sharedReferenceBudgetPk != budget.budgetPk) {
      return false;
    }
    if (budget.walletFks != null &&
        !budget.walletFks!.contains(transaction.walletFk)) {
      return false;
    }
    if (budget.categoryFks != null &&
        !budget.categoryFks!.contains(transaction.categoryFk)) {
      return false;
    }
    if (budget.categoryFksExclude?.contains(transaction.categoryFk) == true ||
        transaction.budgetFksExclude?.contains(budget.budgetPk) == true) {
      return false;
    }
    return true;
  }

  bool _isInRange(DateTime date, DateTime start, DateTime end) {
    return !date.isBefore(start) && !date.isAfter(_endOfDay(end));
  }

  DateTime _endOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

  List<int> _readIntList(String key) {
    final value = appStateSettings[key];
    if (value is! List) return const [];
    return value.whereType<num>().map((id) => id.toInt()).toList();
  }

  int _subscriptionNotificationId(String transactionPk) {
    var hash = 0;
    for (final codeUnit in transactionPk.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x3fffffff;
    }
    return subscriptionReminderID + hash;
  }

  // ============================================================================
  // NOTIFICATION HELPERS
  // ============================================================================

  Future<bool> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required String payload,
    required DateTime scheduledDate,
  }) async {
    final deliveryDate = _nextAllowedScheduledTime(scheduledDate);
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(deliveryDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'smart_notifications',
          'Smart Insights',
          channelDescription: 'Financial insights and reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
      // Financial tips do not need an exact-alarm permission. Inexact
      // scheduling is more battery-friendly and works on Android 12+.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
    return true;
  }

  Future<bool> _sendImmediateNotification({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async {
    if (_isWithinQuietHours(DateTime.now())) return false;

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'smart_notifications',
          'Smart Insights',
          channelDescription: 'Financial insights and reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
    return true;
  }

  // ============================================================================
  // GUARDRAILS & SETTINGS
  // ============================================================================

  bool _canSendNotification(String settingKey) {
    return appStateSettings['notifications'] == true &&
        (appStateSettings[settingKey] ?? true);
  }

  bool _respectsFrequencyLimit(String key, {required int days}) {
    final value = appStateSettings[key];
    final lastSent = value is DateTime
        ? value
        : value is String
            ? DateTime.tryParse(value)
            : null;
    if (lastSent == null) return true;

    final daysSince = DateTime.now().difference(lastSent).inDays;
    return daysSince >= days;
  }

  Future<void> _updateLastSent(String key) async {
    await updateSettings(key, DateTime.now(), updateGlobalState: false);
  }

  bool _isWithinQuietHours(DateTime time) {
    final quietStart = appStateSettings['quietHoursStart'] ?? 22; // 10 PM
    final quietEnd = appStateSettings['quietHoursEnd'] ?? 8; // 8 AM

    final hour = time.hour;
    // Equal start/end means quiet hours are disabled. For a range that crosses
    // midnight (for example 22:00–08:00), the two valid portions are joined
    // with OR; otherwise the hour must fall between both bounds.
    if (quietStart == quietEnd) return false;
    if (quietStart < quietEnd) {
      return hour >= quietStart && hour < quietEnd;
    }
    return hour >= quietStart || hour < quietEnd;
  }

  DateTime _nextAllowedScheduledTime(DateTime scheduledDate) {
    if (!_isWithinQuietHours(scheduledDate)) return scheduledDate;
    final quietStart = appStateSettings['quietHoursStart'] ?? 22;
    final quietEnd = appStateSettings['quietHoursEnd'] ?? 8;
    if (quietStart == quietEnd) return scheduledDate;

    final dateAtQuietEnd = DateTime(
        scheduledDate.year, scheduledDate.month, scheduledDate.day, quietEnd);
    if (quietStart < quietEnd || scheduledDate.hour < quietEnd) {
      return dateAtQuietEnd;
    }
    return dateAtQuietEnd.add(const Duration(days: 1));
  }

  DateTime _getNextWeeklyTime() {
    // Schedule for Sunday evening at 7 PM
    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, 19, 0);

    // Find next Sunday
    while (next.weekday != DateTime.sunday || next.isBefore(now)) {
      next = next.add(Duration(days: 1));
    }

    return next;
  }

  // ============================================================================
  // PUBLIC API - Initialize & Schedule
  // ============================================================================

  /// Initialize all smart notifications
  Future<void> initializeSmartNotifications() async {
    await scheduleWeeklyMoneyStory();
    await scheduleSubscriptionReminders();
    await scheduleReactivationNudge();
  }

  /// Applies changed notification preferences immediately, including cancelling
  /// reminders the user has turned off.
  Future<void> applySmartNotificationPreferences() async {
    if (!_canSendNotification('notifications')) {
      await cancelAllSmartNotifications();
      return;
    }
    if (_canSendNotification('weeklyInsights')) {
      await scheduleWeeklyMoneyStory(ignoreFrequency: true);
    } else {
      await flutterLocalNotificationsPlugin.cancel(weeklyMoneyStoryId);
    }
    if (_canSendNotification('subscriptionReminders')) {
      await scheduleSubscriptionReminders();
    } else {
      await _cancelSubscriptionReminders();
    }
    await scheduleReactivationNudge();
  }

  /// Check and send opportunistic notifications (call daily)
  Future<void> runDailyChecks() async {
    await checkAndNotifySavingsOpportunity();
    await checkAndNotifyPositiveWins();
    await checkAndNotifyBudgetWarnings();
  }

  /// Cancel all smart notifications
  Future<void> cancelAllSmartNotifications() async {
    await flutterLocalNotificationsPlugin.cancel(weeklyMoneyStoryId);
    await flutterLocalNotificationsPlugin.cancel(savingsOpportunityId);
    await flutterLocalNotificationsPlugin.cancel(positiveWinId);
    await flutterLocalNotificationsPlugin.cancel(budgetWarningId);
    await flutterLocalNotificationsPlugin.cancel(transactionInsightId);
    await _cancelSubscriptionReminders();
    await flutterLocalNotificationsPlugin.cancel(reactivationNudgeId);
  }
}
