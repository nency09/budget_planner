import 'package:budget/database/tables.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/notificationsGlobal.dart';
import 'package:budget/struct/settings.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// Smart Notifications Service
/// Provides high-value, AI-powered notifications that users actually want
class SmartNotificationsService {
  static final SmartNotificationsService _instance = SmartNotificationsService._internal();
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
  static const String lastBudgetWarningKey = 'lastBudgetWarning';
  static const String lastReactivationKey = 'lastReactivation';

  /// 1. Weekly "Money Story" - AI Summary
  /// Sends once per week with spending insights
  Future<void> scheduleWeeklyMoneyStory() async {
    if (!_canSendNotification('weeklyInsights')) return;
    if (!_respectsFrequencyLimit(lastWeeklySummaryKey, days: 7)) return;

    final summary = await _generateWeeklySummary();
    if (summary == null) return;

    await _scheduleNotification(
      id: weeklyMoneyStoryId,
      title: '📊 Your Weekly Money Story',
      body: summary,
      payload: 'weekly_summary',
      scheduledDate: _getNextWeeklyTime(),
    );

    _updateLastSent(lastWeeklySummaryKey);
  }

  /// 2. Smart Savings Opportunity
  /// Detects unused subscriptions, high fees, duplicate services
  Future<void> checkAndNotifySavingsOpportunity() async {
    if (!_canSendNotification('savingsOpportunities')) return;
    if (!_respectsFrequencyLimit(lastSavingsOpportunityKey, days: 3)) return;

    final opportunity = await _detectSavingsOpportunity();
    if (opportunity == null) return;

    await _sendImmediateNotification(
      id: savingsOpportunityId,
      title: '💡 Smart Savings Tip',
      body: opportunity['message']!,
      payload: opportunity['action']!,
    );

    _updateLastSent(lastSavingsOpportunityKey);
  }

  /// 3. Positive "Win" Notifications
  /// Celebrates achievements and milestones
  Future<void> checkAndNotifyPositiveWins() async {
    if (!_canSendNotification('goalReminders')) return;

    final win = await _detectPositiveWin();
    if (win == null) return;

    await _sendImmediateNotification(
      id: positiveWinId,
      title: '🎉 ${win['title']}',
      body: win['message']!,
      payload: win['action']!,
    );
  }

  /// 4. Budget Warning / Risk Alert
  /// Gentle warnings about budget overruns
  Future<void> checkAndNotifyBudgetWarnings() async {
    if (!_canSendNotification('budgetAlerts')) return;
    if (!_respectsFrequencyLimit(lastBudgetWarningKey, days: 7)) return;

    final warning = await _detectBudgetRisk();
    if (warning == null) return;

    await _sendImmediateNotification(
      id: budgetWarningId,
      title: '⚠️ Budget Alert',
      body: warning['message']!,
      payload: warning['action']!,
    );

    _updateLastSent(lastBudgetWarningKey);
  }

  /// 5. Transaction Insight
  /// Asks about big transactions or categorization
  Future<void> notifyTransactionInsight(Transaction transaction, double amount) async {
    if (!_canSendNotification('transactionInsights')) return;
    if (amount < 1000) return; // Only for significant transactions

    await _sendImmediateNotification(
      id: transactionInsightId,
      title: '💳 Large Transaction Detected',
      body: 'You spent ₹${amount.toStringAsFixed(0)}. Should I help categorize this?',
      payload: 'transaction_${transaction.transactionPk}',
    );
  }

  /// 6. Subscription Reminder
  /// Reminds before recurring subscriptions
  Future<void> scheduleSubscriptionReminders() async {
    if (!_canSendNotification('subscriptionReminders')) return;

    final upcomingSubscriptions = await _getUpcomingSubscriptions();
    
    for (var sub in upcomingSubscriptions) {
      await _scheduleNotification(
        id: subscriptionReminderID + sub.hashCode,
        title: '🔔 Subscription Renewal',
        body: '${sub['name']} ₹${sub['amount']} renews tomorrow. Still using it?',
        payload: 'subscription_${sub['id']}',
        scheduledDate: sub['reminderDate'],
      );
    }
  }

  /// 7. Re-activation Nudge
  /// Gentle reminder if user hasn't opened app in 14+ days
  Future<void> scheduleReactivationNudge() async {
    if (!_respectsFrequencyLimit(lastReactivationKey, days: 21)) return;

    final lastOpened = appStateSettings['lastAppOpened'] as DateTime?;
    if (lastOpened == null) return;

    final daysSinceOpened = DateTime.now().difference(lastOpened).inDays;
    if (daysSinceOpened < 14) return;

    await _scheduleNotification(
      id: reactivationNudgeId,
      title: '👋 Quick Check-In',
      body: 'A lot can change in ${daysSinceOpened} days. Want a 30-second AI check-up?',
      payload: 'reactivation',
      scheduledDate: DateTime.now().add(Duration(hours: 2)),
    );

    _updateLastSent(lastReactivationKey);
  }

  // ============================================================================
  // HELPER METHODS - Detection & Analysis
  // ============================================================================

  Future<String?> _generateWeeklySummary() async {
    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: 7));
      
      final transactions = await database.allTransactions;
      final thisWeek = transactions.where((t) => 
        t.dateCreated.isAfter(weekStart) && t.paid
      ).toList();

      if (thisWeek.isEmpty) return null;

      double thisWeekTotal = 0;
      double lastWeekTotal = 0;
      Map<String, double> categoryTotals = {};

      for (var t in thisWeek) {
        if (!t.income) {
          thisWeekTotal += t.amount.abs();
          // Track by category for insights
        }
      }

      // Compare with last week
      final lastWeekStart = weekStart.subtract(Duration(days: 7));
      final lastWeek = transactions.where((t) => 
        t.dateCreated.isAfter(lastWeekStart) && 
        t.dateCreated.isBefore(weekStart) && 
        t.paid
      ).toList();

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

    return null; // Implement detection logic
  }

  Future<Map<String, String>?> _detectPositiveWin() async {
    // Check for achievements:
    // - Stayed within budget
    // - Reached goal milestone
    // - Expense logging streak
    
    return null; // Implement detection logic
  }

  Future<Map<String, String>?> _detectBudgetRisk() async {
    try {
      final budgets = await database.getAllBudgets();
      final now = DateTime.now();

      for (var budget in budgets) {
        // Calculate budget usage percentage
        // Check if over 80% used with less than 50% of month passed
        
        // Example:
        // return {
        //   'message': 'You\'ve used 80% of your Shopping budget with 60% of month left. Need help?',
        //   'action': 'budget_${budget.budgetPk}'
        // };
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> _getUpcomingSubscriptions() async {
    // Get subscriptions renewing in next 24 hours
    return [];
  }

  // ============================================================================
  // NOTIFICATION HELPERS
  // ============================================================================

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required String payload,
    required DateTime scheduledDate,
  }) async {
    if (!_isWithinQuietHours(scheduledDate)) {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'smart_notifications',
            'Smart Insights',
            channelDescription: 'AI-powered financial insights and tips',
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
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  Future<void> _sendImmediateNotification({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async {
    if (_isWithinQuietHours(DateTime.now())) return;

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'smart_notifications',
          'Smart Insights',
          channelDescription: 'AI-powered financial insights and tips',
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
  }

  // ============================================================================
  // GUARDRAILS & SETTINGS
  // ============================================================================

  bool _canSendNotification(String settingKey) {
    return appStateSettings[settingKey] ?? true;
  }

  bool _respectsFrequencyLimit(String key, {required int days}) {
    final lastSent = appStateSettings[key] as DateTime?;
    if (lastSent == null) return true;
    
    final daysSince = DateTime.now().difference(lastSent).inDays;
    return daysSince >= days;
  }

  void _updateLastSent(String key) {
    updateSettings(key, DateTime.now(), updateGlobalState: false);
  }

  bool _isWithinQuietHours(DateTime time) {
    final quietStart = appStateSettings['quietHoursStart'] ?? 22; // 10 PM
    final quietEnd = appStateSettings['quietHoursEnd'] ?? 8; // 8 AM
    
    final hour = time.hour;
    if (quietStart < quietEnd) {
      return hour >= quietStart || hour < quietEnd;
    } else {
      return hour >= quietStart && hour < quietEnd;
    }
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
    await flutterLocalNotificationsPlugin.cancel(subscriptionReminderID);
    await flutterLocalNotificationsPlugin.cancel(reactivationNudgeId);
  }
}
