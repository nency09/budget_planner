import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service that manages local caching of AI responses.
///
/// Uses SharedPreferences for lightweight cache storage.
/// Each cache entry has a TTL-based expiration.
class AICacheService {
  static final AICacheService _instance = AICacheService._internal();
  factory AICacheService() => _instance;
  AICacheService._internal();

  static const String _cachePrefix = 'ai_cache_';

  /// Get a cached result by key. Returns null if not found or expired.
  Future<Map<String, dynamic>?> get(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_cachePrefix$key');
    if (raw == null) return null;

    try {
      final entry = json.decode(raw) as Map<String, dynamic>;
      final expiresAt = DateTime.parse(entry['expiresAt'] as String);

      if (DateTime.now().isAfter(expiresAt)) {
        // Cache expired, remove it
        await prefs.remove('$_cachePrefix$key');
        return null;
      }

      return entry['data'] as Map<String, dynamic>?;
    } catch (e) {
      // Corrupt entry, remove it
      await prefs.remove('$_cachePrefix$key');
      return null;
    }
  }

  /// Store a result with a given TTL duration.
  Future<void> set(
    String key,
    Map<String, dynamic> data, {
    required Duration ttl,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final entry = {
      'data': data,
      'createdAt': DateTime.now().toIso8601String(),
      'expiresAt': DateTime.now().add(ttl).toIso8601String(),
    };
    await prefs.setString('$_cachePrefix$key', json.encode(entry));
  }

  /// Store a result that never expires (e.g. merchant categorization).
  Future<void> setPermanent(String key, Map<String, dynamic> data) async {
    return set(key, data, ttl: const Duration(days: 365 * 10));
  }

  /// Remove a specific cache entry.
  Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_cachePrefix$key');
  }

  /// Check if a valid (non-expired) cache entry exists.
  Future<bool> has(String key) async {
    return (await get(key)) != null;
  }

  /// Clear all AI cache entries.
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys =
        prefs.getKeys().where((k) => k.startsWith(_cachePrefix)).toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  /// Get cache key for merchant categorization.
  static String categorizationKey(String merchantName) {
    return 'cat:${merchantName.trim().toLowerCase()}';
  }

  /// Get cache key for weekly insights.
  static String weeklyInsightKey(DateTime date) {
    // ISO week format: yyyy-Www
    final weekNumber = _isoWeekNumber(date);
    return 'insight:week:${date.year}-W${weekNumber.toString().padLeft(2, '0')}';
  }

  /// Get cache key for monthly financial score.
  static String scoreKey(DateTime date) {
    return 'score:${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  /// Get cache key for monthly prediction.
  static String predictionKey(DateTime date) {
    return 'predict:${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  /// Get cache key for advice (hash-based).
  static String adviceKey(String question, String contextHash) {
    return 'advice:${question.hashCode}_$contextHash';
  }

  static int _isoWeekNumber(DateTime date) {
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }
}
