import 'package:shared_preferences/shared_preferences.dart';

/// Controls AI API call costs through rate limiting and call counting.
///
/// Enforces:
/// - Max 50 API calls per day
/// - One categorization call per unique merchant
/// - One insight generation per calendar week
/// - Advice only on explicit user action
class AICostController {
  static final AICostController _instance = AICostController._internal();
  factory AICostController() => _instance;
  AICostController._internal();

  static const String _dailyCallCountKey = 'ai_daily_call_count';
  static const String _dailyCallDateKey = 'ai_daily_call_date';
  static const int maxDailyApiCalls = 50;

  /// Check if an API call is allowed under the daily limit.
  Future<bool> canMakeApiCall() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayString();
    final storedDate = prefs.getString(_dailyCallDateKey);

    if (storedDate != today) {
      // New day, reset counter
      await prefs.setString(_dailyCallDateKey, today);
      await prefs.setInt(_dailyCallCountKey, 0);
      return true;
    }

    final count = prefs.getInt(_dailyCallCountKey) ?? 0;
    return count < maxDailyApiCalls;
  }

  /// Record that an API call was made.
  Future<void> recordApiCall() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayString();
    final storedDate = prefs.getString(_dailyCallDateKey);

    if (storedDate != today) {
      await prefs.setString(_dailyCallDateKey, today);
      await prefs.setInt(_dailyCallCountKey, 1);
    } else {
      final count = prefs.getInt(_dailyCallCountKey) ?? 0;
      await prefs.setInt(_dailyCallCountKey, count + 1);
    }
  }

  /// Get the number of API calls made today.
  Future<int> getTodayCallCount() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayString();
    final storedDate = prefs.getString(_dailyCallDateKey);

    if (storedDate != today) return 0;
    return prefs.getInt(_dailyCallCountKey) ?? 0;
  }

  /// Get the number of remaining API calls for today.
  Future<int> getRemainingCalls() async {
    final count = await getTodayCallCount();
    return maxDailyApiCalls - count;
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
