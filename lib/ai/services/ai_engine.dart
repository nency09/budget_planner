import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import 'package:budget/ai/models/ai_insight.dart';
import 'package:budget/ai/models/financial_score.dart';
import 'package:budget/ai/models/spending_prediction.dart';
import 'package:budget/ai/models/ai_advice.dart';
import 'package:budget/ai/prompts/categorization_prompt.dart';
import 'package:budget/ai/prompts/insights_prompt.dart';
import 'package:budget/ai/prompts/score_prompt.dart';
import 'package:budget/ai/prompts/prediction_prompt.dart';
import 'package:budget/ai/prompts/advice_prompt.dart';
import 'package:budget/ai/prompts/chat_prompt.dart';
import 'package:budget/ai/services/ai_cache_service.dart';
import 'package:budget/ai/services/ai_cost_controller.dart';

/// Core AI service powered by Google Gemini (gemini-2.0-flash).
///
/// All AI features go through this service. It handles:
/// - Prompt construction
/// - API calls to Gemini
/// - Caching via [AICacheService]
/// - Rate limiting via [AICostController]
class AIEngine {
  static final AIEngine _instance = AIEngine._internal();
  factory AIEngine() => _instance;
  AIEngine._internal();

  final AICacheService _cache = AICacheService();
  final AICostController _costController = AICostController();

  GenerativeModel? _model;
  String? _apiKey;

  /// Initialize with the Gemini API key.
  void configure({required String apiKey}) {
    _apiKey = apiKey;
    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.3,
        maxOutputTokens: 1000,
        responseMimeType: 'text/plain',
      ),
    );
  }

  bool get isConfigured => _apiKey != null && _apiKey!.isNotEmpty && _model != null;

  // ---------------------------------------------------------------------------
  // 1. Smart Categorization
  // ---------------------------------------------------------------------------

  /// Categorize a transaction by merchant name.
  /// Runs ONCE per unique merchant — result is permanently cached.
  Future<String?> categorizeTransaction({
    required String merchantName,
    required String transactionNote,
    required List<String> existingCategories,
  }) async {
    if (existingCategories.isEmpty) return null;

    final cacheKey = AICacheService.categorizationKey(merchantName);
    final cached = await _cache.get(cacheKey);
    if (cached != null) {
      return cached['category'] as String?;
    }

    final response = await _callGemini(
      systemPrompt: CategorizationPrompt.system(),
      userPrompt: CategorizationPrompt.user(
        merchantName: merchantName,
        note: transactionNote,
        categories: existingCategories,
      ),
    );

    if (response != null) {
      final category = response.trim();
      // Validate that the returned category is in the list
      final match = existingCategories.firstWhere(
        (c) => c.toLowerCase() == category.toLowerCase(),
        orElse: () => '',
      );
      if (match.isNotEmpty) {
        await _cache.setPermanent(cacheKey, {'category': match});
        return match;
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // 2. Weekly Spending Insights
  // ---------------------------------------------------------------------------

  /// Generate weekly insights. Runs ONCE per calendar week.
  Future<AIInsight?> generateWeeklyInsights({
    required double totalIncome,
    required double totalSpent,
    required List<Map<String, dynamic>> categoryBreakdown,
    required DateTime weekStart,
    required DateTime weekEnd,
  }) async {
    final cacheKey = AICacheService.weeklyInsightKey(weekStart);
    final cached = await _cache.get(cacheKey);
    if (cached != null) {
      return AIInsight.fromJson(cached);
    }

    final response = await _callGeminiJson(
      systemPrompt: InsightsPrompt.system(),
      userPrompt: InsightsPrompt.user(
        startDate: _formatDate(weekStart),
        endDate: _formatDate(weekEnd),
        income: totalIncome,
        spent: totalSpent,
        categoryBreakdown: categoryBreakdown,
      ),
    );

    if (response != null) {
      try {
        final insight = AIInsight.fromJson(response);
        await _cache.set(cacheKey, insight.toJson(),
            ttl: const Duration(days: 7));
        return insight;
      } catch (e) {
        debugPrint('AIEngine: Failed to parse insights response: $e');
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // 3. Financial Health Score
  // ---------------------------------------------------------------------------

  /// Calculate a financial health score (0-100).
  Future<FinancialScore?> calculateFinancialScore({
    required double totalIncome,
    required double totalExpenses,
    required double savingsRate,
    required double budgetAdherence,
    required int numCategories,
    required int recurringExpenseCount,
  }) async {
    final cacheKey = AICacheService.scoreKey(DateTime.now());
    final cached = await _cache.get(cacheKey);
    if (cached != null) {
      return FinancialScore.fromJson(cached);
    }

    final response = await _callGeminiJson(
      systemPrompt: ScorePrompt.system(),
      userPrompt: ScorePrompt.user(
        income: totalIncome,
        expenses: totalExpenses,
        savingsRate: savingsRate,
        budgetAdherence: budgetAdherence,
        numCategories: numCategories,
        recurringCount: recurringExpenseCount,
      ),
    );

    if (response != null) {
      try {
        final score = FinancialScore.fromJson(response);
        await _cache.set(cacheKey, score.toJson(),
            ttl: const Duration(days: 30));
        return score;
      } catch (e) {
        debugPrint('AIEngine: Failed to parse score response: $e');
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // 4. Spending Prediction
  // ---------------------------------------------------------------------------

  /// Predict next month's spending.
  Future<SpendingPrediction?> predictNextMonthSpending({
    required List<Map<String, dynamic>> historicalMonths,
    required List<Map<String, dynamic>> currentCategories,
  }) async {
    final cacheKey = AICacheService.predictionKey(DateTime.now());
    final cached = await _cache.get(cacheKey);
    if (cached != null) {
      return SpendingPrediction.fromJson(cached);
    }

    final response = await _callGeminiJson(
      systemPrompt: PredictionPrompt.system(),
      userPrompt: PredictionPrompt.user(
        historicalMonths: historicalMonths,
        currentCategories: currentCategories,
      ),
    );

    if (response != null) {
      try {
        final prediction = SpendingPrediction.fromJson(response);
        await _cache.set(cacheKey, prediction.toJson(),
            ttl: const Duration(days: 30));
        return prediction;
      } catch (e) {
        debugPrint('AIEngine: Failed to parse prediction response: $e');
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // 5. Financial Advice (on-demand)
  // ---------------------------------------------------------------------------

  /// Generate advice for a specific question. Only runs on user request.
  Future<AIAdvice?> generateAdvice({
    required String userQuestion,
    required FinancialContext context,
  }) async {
    final contextStr = context.toPromptString();
    final cacheKey =
        AICacheService.adviceKey(userQuestion, contextStr.hashCode.toString());
    final cached = await _cache.get(cacheKey);
    if (cached != null) {
      return AIAdvice.fromJson(cached);
    }

    final response = await _callGeminiJson(
      systemPrompt: AdvicePrompt.system(),
      userPrompt: AdvicePrompt.user(
        question: userQuestion,
        financialContext: contextStr,
      ),
    );

    if (response != null) {
      try {
        final advice = AIAdvice.fromJson(response);
        await _cache.set(cacheKey, advice.toJson(),
            ttl: const Duration(hours: 24));
        return advice;
      } catch (e) {
        debugPrint('AIEngine: Failed to parse advice response: $e');
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // 6. Answer User Query (Chat)
  // ---------------------------------------------------------------------------

  /// Free-form Q&A about the user's finances.
  Future<String?> answerUserQuery({
    required String query,
    required FinancialContext context,
    List<Map<String, String>> conversationHistory = const [],
  }) async {
    final response = await _callGemini(
      systemPrompt: ChatPrompt.system(),
      userPrompt: ChatPrompt.user(
        query: query,
        financialContext: context.toPromptString(),
        conversationHistory: conversationHistory,
      ),
    );
    return response;
  }

  // ---------------------------------------------------------------------------
  // 7. Subscription Detection
  // ---------------------------------------------------------------------------

  /// Detect subscriptions from recurring transaction patterns.
  /// This uses local heuristics (no API call needed).
  Future<List<DetectedSubscription>> detectSubscriptions({
    required List<Map<String, dynamic>> recentTransactions,
  }) async {
    // Group by merchant, check for recurring patterns
    final Map<String, List<Map<String, dynamic>>> byMerchant = {};
    for (final txn in recentTransactions) {
      final name = (txn['name'] as String?)?.trim().toLowerCase() ?? '';
      if (name.isEmpty) continue;
      byMerchant.putIfAbsent(name, () => []).add(txn);
    }

    final List<DetectedSubscription> detected = [];
    for (final entry in byMerchant.entries) {
      if (entry.value.length >= 2) {
        // Check if amounts are similar (within 10%)
        final amounts = entry.value
            .map((t) => (t['amount'] as num?)?.toDouble().abs() ?? 0)
            .toList();
        final avg = amounts.reduce((a, b) => a + b) / amounts.length;
        final allSimilar = amounts.every(
            (a) => (a - avg).abs() / (avg == 0 ? 1 : avg) < 0.1);

        if (allSimilar && avg > 0) {
          detected.add(DetectedSubscription(
            merchantName: entry.key,
            estimatedAmount: avg,
            estimatedFrequency: _guessFrequency(entry.value),
            occurrenceCount: entry.value.length,
            lastSeen: DateTime.now(),
          ));
        }
      }
    }

    return detected;
  }

  String _guessFrequency(List<Map<String, dynamic>> transactions) {
    if (transactions.length < 2) return 'monthly';
    final dates = transactions
        .map((t) => DateTime.tryParse(t['date'] as String? ?? ''))
        .whereType<DateTime>()
        .toList()
      ..sort();

    if (dates.length < 2) return 'monthly';

    int totalDays = 0;
    for (int i = 1; i < dates.length; i++) {
      totalDays += dates[i].difference(dates[i - 1]).inDays;
    }
    final avgDays = totalDays / (dates.length - 1);

    if (avgDays < 10) return 'weekly';
    if (avgDays < 45) return 'monthly';
    return 'yearly';
  }

  // ---------------------------------------------------------------------------
  // Core Gemini API Calls
  // ---------------------------------------------------------------------------

  /// Call Gemini and return raw text response.
  Future<String?> _callGemini({
    required String systemPrompt,
    required String userPrompt,
  }) async {
    if (!isConfigured) {
      debugPrint('AIEngine: Gemini API key not configured');
      return null;
    }

    if (!(await _costController.canMakeApiCall())) {
      debugPrint('AIEngine: Daily API call limit reached');
      return null;
    }

    try {
      final content = [Content.text('$systemPrompt\n\n$userPrompt')];
      final response = await _model!.generateContent(content);

      await _costController.recordApiCall();

      if (response.text != null) {
        return response.text;
      } else {
        debugPrint('AIEngine: Empty response from Gemini');
      }
    } catch (e) {
      debugPrint('AIEngine: Gemini API error: $e');
    }
    return null;
  }

  /// Call Gemini expecting a JSON response, parse and return as Map.
  Future<Map<String, dynamic>?> _callGeminiJson({
    required String systemPrompt,
    required String userPrompt,
  }) async {
    if (!isConfigured) {
      debugPrint('AIEngine: Gemini API key not configured');
      return null;
    }

    if (!(await _costController.canMakeApiCall())) {
      debugPrint('AIEngine: Daily API call limit reached');
      return null;
    }

    try {
      // Use a model configured for JSON output
      final jsonModel = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: _apiKey!,
        generationConfig: GenerationConfig(
          temperature: 0.3,
          maxOutputTokens: 1000,
          responseMimeType: 'application/json',
        ),
      );

      final content = [Content.text('$systemPrompt\n\n$userPrompt')];
      final response = await jsonModel.generateContent(content);

      await _costController.recordApiCall();

      if (response.text != null) {
        final text = response.text!.trim();
        return json.decode(text) as Map<String, dynamic>;
      } else {
        debugPrint('AIEngine: Empty response from Gemini');
      }
    } catch (e) {
      debugPrint('AIEngine: Gemini API error: $e');
    }
    return null;
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
