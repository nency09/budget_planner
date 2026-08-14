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
import 'package:budget/ai/helpers/finance_question_validator.dart';
import 'package:budget/ai/providers/groq_provider.dart';
import 'package:budget/ai/providers/openai_provider.dart';
import 'package:budget/struct/databaseGlobal.dart';

/// AI Provider types
enum AIProviderType {
  gemini,
  groq,
  openai, // Primary provider for Phase 1
}

/// Core AI service supporting multiple providers (Gemini, Groq, etc.).
///
/// All AI features go through this service. It handles:
/// - Prompt construction
/// - API calls to various AI providers
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
  AIProviderType _providerType =
      AIProviderType.openai; // Default to OpenAI for Phase 1
  final GroqProvider _groqProvider = GroqProvider();
  final OpenAIProvider _openaiProvider = OpenAIProvider();

  /// Initialize with API key. Supports OpenAI (primary), Gemini, or Groq.
  ///
  /// For OpenAI (Phase 1): Use OPENAI_API_KEY in .env (gpt-4o-mini)
  /// For Groq: Use GROQ_API_KEY in .env (free alternative)
  /// For Gemini: Use GEMINI_API_KEY in .env (requires billing setup)
  void configure({required String apiKey, AIProviderType? providerType}) {
    _apiKey = apiKey;

    // Use provided provider type, or auto-detect based on key format
    if (providerType != null) {
      _providerType = providerType;
      debugPrint('AIEngine: Using specified provider: ${providerType.name}');
    } else if (apiKey.startsWith('sk-')) {
      // OpenAI API keys start with 'sk-'
      _providerType = AIProviderType.openai;
      debugPrint('AIEngine: Auto-detected OpenAI provider from key format');
    } else if (apiKey.startsWith('gsk_') || apiKey.length == 56) {
      // Groq API keys typically start with 'gsk_' or are 56 chars
      _providerType = AIProviderType.groq;
      debugPrint('AIEngine: Auto-detected Groq provider from key format');
    } else {
      _providerType = AIProviderType.gemini;
      debugPrint('AIEngine: Auto-detected Gemini provider from key format');
    }

    if (_providerType == AIProviderType.openai) {
      _openaiProvider.configure(apiKey: apiKey);
      debugPrint('✅ AIEngine: Configured with OpenAI provider (gpt-4o-mini)');
    } else if (_providerType == AIProviderType.groq) {
      _groqProvider.configure(apiKey: apiKey);
      debugPrint('✅ AIEngine: Configured with Groq provider');
    } else {
      _model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.3,
          maxOutputTokens: 1000,
          responseMimeType: 'text/plain',
        ),
      );
      debugPrint('✅ AIEngine: Configured with Gemini provider');
    }
  }

  bool get isConfigured {
    if (_providerType == AIProviderType.openai) {
      return _openaiProvider.isConfigured;
    } else if (_providerType == AIProviderType.groq) {
      return _groqProvider.isConfigured;
    }
    return _apiKey != null && _apiKey!.isNotEmpty && _model != null;
  }

  AIProviderType get providerType => _providerType;

  /// Send a general chat request through whichever provider was configured at
  /// startup. This keeps all AI features on the same provider and rate limit.
  Future<String?> chat({
    required String systemPrompt,
    required String userPrompt,
  }) {
    return _callAI(systemPrompt: systemPrompt, userPrompt: userPrompt);
  }

  /// Get provider name as string for display
  String get providerName {
    switch (_providerType) {
      case AIProviderType.openai:
        return 'OpenAI';
      case AIProviderType.groq:
        return 'Groq';
      case AIProviderType.gemini:
        return 'Gemini';
    }
  }

  // ---------------------------------------------------------------------------
  // 1. Smart Categorization
  // ---------------------------------------------------------------------------

  /// Categorize a transaction by merchant name.
  /// Runs ONCE per unique merchant — result is permanently cached in database.
  ///
  /// Phase 1 Implementation: Uses database table instead of SharedPreferences
  Future<String?> categorizeTransaction({
    required String merchantName,
    required String transactionNote,
    required List<String> existingCategories,
  }) async {
    if (existingCategories.isEmpty) return null;

    // Normalize merchant name (lowercase, trimmed)
    final normalizedMerchant = merchantName.trim().toLowerCase();

    // Check database cache first (Phase 1 requirement)
    try {
      final cached =
          await database.getMerchantCategoryCache(normalizedMerchant);
      if (cached != null) {
        debugPrint(
            '✅ AIEngine: Found cached category for "$merchantName": ${cached.predictedCategory}');
        // Return the category name (String), not the cached object
        final String categoryName = cached.predictedCategory;
        // Validate it's still in the existing categories list
        final match = existingCategories.firstWhere(
          (String c) => c.toLowerCase() == categoryName.toLowerCase(),
          orElse: () => '',
        );
        if (match.isNotEmpty) {
          return match;
        } else {
          debugPrint(
              '⚠️ AIEngine: Cached category "$categoryName" no longer exists, will re-categorize');
        }
      }
    } catch (e) {
      debugPrint('⚠️ AIEngine: Error checking database cache: $e');
    }

    // Check Associated Titles (existing logic) before calling AI
    try {
      final associatedTitles = await database.getAllAssociatedTitles();
      for (var associated in associatedTitles) {
        if (merchantName
                .toLowerCase()
                .contains(associated.title.toLowerCase()) ||
            associated.title
                .toLowerCase()
                .contains(merchantName.toLowerCase())) {
          debugPrint(
              '✅ AIEngine: Found category from Associated Titles: ${associated.categoryFk}');
          // Cache this in database for future use
          await database.createOrUpdateMerchantCategoryCache(
            merchantName: normalizedMerchant,
            predictedCategory: associated.categoryFk,
            confidence: 1.0,
          );
          return associated.categoryFk;
        }
      }
    } catch (e) {
      debugPrint('⚠️ AIEngine: Error checking Associated Titles: $e');
    }

    // If not found, call AI (OpenAI for Phase 1)
    if (!isConfigured) {
      debugPrint('⚠️ AIEngine: Not configured, cannot categorize');
      return null;
    }

    debugPrint('🤖 AIEngine: Calling AI to categorize "$merchantName"');

    final response = await _callAI(
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
        // Store in database cache (Phase 1 requirement)
        try {
          await database.createOrUpdateMerchantCategoryCache(
            merchantName: normalizedMerchant,
            predictedCategory: match,
            confidence: 0.9, // AI prediction confidence
          );
          debugPrint(
              '✅ AIEngine: Cached category "$match" for "$merchantName" in database');
        } catch (e) {
          debugPrint('⚠️ AIEngine: Error caching category: $e');
        }
        return match;
      } else {
        debugPrint('⚠️ AIEngine: AI returned invalid category: "$category"');
      }
    }

    // Fallback to "Other" if AI fails
    debugPrint('⚠️ AIEngine: AI categorization failed, using default "Other"');
    return null; // Let caller handle default
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
    // ALWAYS log the real data being used (even if cached)
    debugPrint('🤖 AIEngine: REAL DATA RECEIVED (calculated from database):');
    debugPrint(
        '   📅 Period: ${_formatDate(weekStart)} to ${_formatDate(weekEnd)}');
    debugPrint('   💵 Income: ₹$totalIncome');
    debugPrint('   💸 Spent: ₹$totalSpent');
    debugPrint('   📂 Categories: ${categoryBreakdown.length}');
    for (var cat in categoryBreakdown) {
      debugPrint(
          '      - ${cat['name']}: ₹${cat['amount']} (${cat['percentage']}%)');
    }
    debugPrint('   ✅ This is 100% REAL data from your transaction database!');

    // 1) Check persistent weekly insights table first (DB cache)
    try {
      final existing = await database.getWeeklyInsight(weekStart);
      if (existing != null) {
        debugPrint(
            '💾 Using cached weekly insight from database (week starting ${_formatDate(weekStart)})');
        return AIInsight(
          summary: existing.insightText,
          topTip: '', // Top tip is embedded in text for now
          insights: const [],
        );
      }
    } catch (e) {
      debugPrint('AIEngine: Error reading weekly insight from database: $e');
    }

    // 2) Legacy in-memory/shared-pref cache (fallback)
    final cacheKey = AICacheService.weeklyInsightKey(weekStart);
    final cached = await _cache.get(cacheKey);
    if (cached != null) {
      debugPrint(
          '💾 Using cached weekly insight from AICacheService (week starting ${_formatDate(weekStart)})');
      return AIInsight.fromJson(cached);
    }

    debugPrint('🌐 Calling AI API with REAL data...');

    final userPrompt = InsightsPrompt.user(
      startDate: _formatDate(weekStart),
      endDate: _formatDate(weekEnd),
      income: totalIncome,
      spent: totalSpent,
      categoryBreakdown: categoryBreakdown,
    );

    debugPrint('🤖 AIEngine: Full prompt being sent to AI:');
    debugPrint(userPrompt);

    final response = await _callGeminiJson(
      systemPrompt: InsightsPrompt.system(),
      userPrompt: userPrompt,
    );

    if (response != null) {
      try {
        final insight = AIInsight.fromJson(response);

        // Persist to weekly insights table so we never recompute this week again.
        try {
          await database.createOrUpdateWeeklyInsight(
            weekStart: weekStart,
            weekEnd: weekEnd,
            insightText: insight.summary,
          );
          debugPrint(
              '✅ AIEngine: Saved weekly insight to database for week starting ${_formatDate(weekStart)}');
        } catch (e) {
          debugPrint('AIEngine: Error saving weekly insight to database: $e');
        }

        // Also keep short-lived cache for fast re-open within the same session.
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
    // ALWAYS log the real data being used (even if cached)
    debugPrint('🤖 AIEngine: REAL DATA RECEIVED (calculated from database):');
    debugPrint('   💵 Income: ₹$totalIncome');
    debugPrint('   💸 Expenses: ₹$totalExpenses');
    debugPrint(
        '   📊 Savings Rate: ${(savingsRate * 100).toStringAsFixed(1)}%');
    debugPrint(
        '   🎯 Budget Adherence: ${(budgetAdherence * 100).toStringAsFixed(1)}%');
    debugPrint('   📂 Categories: $numCategories');
    debugPrint('   🔄 Recurring: $recurringExpenseCount');
    debugPrint('   ✅ This is 100% REAL data from your transaction database!');

    final cacheKey = AICacheService.scoreKey(DateTime.now());
    final cached = await _cache.get(cacheKey);
    if (cached != null) {
      debugPrint(
          '💾 Using cached AI response (data was recalculated from database above)');
      return FinancialScore.fromJson(cached);
    }

    debugPrint('🌐 Calling AI API with REAL data...');

    final userPrompt = ScorePrompt.user(
      income: totalIncome,
      expenses: totalExpenses,
      savingsRate: savingsRate,
      budgetAdherence: budgetAdherence,
      numCategories: numCategories,
      recurringCount: recurringExpenseCount,
    );

    debugPrint('🤖 AIEngine: Full prompt being sent to AI:');
    debugPrint(userPrompt);

    final response = await _callGeminiJson(
      systemPrompt: ScorePrompt.system(),
      userPrompt: userPrompt,
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
    // ALWAYS log the real data being used (even if cached)
    debugPrint('🤖 AIEngine: REAL DATA RECEIVED (calculated from database):');
    debugPrint('   📅 Historical months: ${historicalMonths.length}');
    for (var month in historicalMonths) {
      debugPrint('      - ${month['month']}: ₹${month['total']}');
    }
    debugPrint('   📂 Current categories: ${currentCategories.length}');
    for (var cat in currentCategories) {
      debugPrint('      - ${cat['name']}: ₹${cat['amount']}');
    }
    debugPrint('   ✅ This is 100% REAL data from your transaction database!');

    final cacheKey = AICacheService.predictionKey(DateTime.now());
    final cached = await _cache.get(cacheKey);
    if (cached != null) {
      debugPrint(
          '💾 Using cached AI response (data was recalculated from database above)');
      return SpendingPrediction.fromJson(cached);
    }

    debugPrint('🌐 Calling AI API with REAL data...');

    final userPrompt = PredictionPrompt.user(
      historicalMonths: historicalMonths,
      currentCategories: currentCategories,
    );

    debugPrint('🤖 AIEngine: Full prompt being sent to AI:');
    debugPrint(userPrompt);

    final response = await _callGeminiJson(
      systemPrompt: PredictionPrompt.system(),
      userPrompt: userPrompt,
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
  /// Validates that the question is finance-related before processing.
  Future<AIAdvice?> generateAdvice({
    required String userQuestion,
    required FinancialContext context,
  }) async {
    // Check if the question is finance-related
    if (!FinanceQuestionValidator.isFinanceQuestion(userQuestion)) {
      debugPrint('🚫 AIEngine: Rejected non-finance question: "$userQuestion"');
      // Return a rejection advice object
      return AIAdvice(
        answer: FinanceQuestionValidator.getRejectionMessage(),
        actionItems: [],
      );
    }

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

        // Additional validation: check if AI response is finance-related
        if (!_isFinancialAdvice(advice.answer)) {
          debugPrint(
              '🚫 AIEngine: AI returned non-financial advice, replacing with rejection');
          return AIAdvice(
            answer: FinanceQuestionValidator.getRejectionMessage(),
            actionItems: [],
          );
        }

        await _cache.set(cacheKey, advice.toJson(),
            ttl: const Duration(hours: 24));
        return advice;
      } catch (e) {
        debugPrint('AIEngine: Failed to parse advice response: $e');
      }
    }
    return null;
  }

  /// Check if the AI advice response appears to be finance-related.
  bool _isFinancialAdvice(String advice) {
    final lowerAdvice = advice.toLowerCase();

    // If response contains rejection phrases, it's valid
    if (lowerAdvice.contains('only help with') ||
        lowerAdvice.contains('finance') ||
        lowerAdvice.contains('budget') ||
        lowerAdvice.contains('financial')) {
      return true;
    }

    // Check for obvious non-financial topics
    final nonFinancialIndicators = [
      'capital of',
      'president of',
      'national animal',
      'weather',
      'recipe',
      'movie',
      'sports',
      'celebrity',
      'history of',
      'geography',
      'science',
      'technology',
      'programming',
      'coding',
      'software'
    ];

    for (final indicator in nonFinancialIndicators) {
      if (lowerAdvice.contains(indicator)) {
        return false;
      }
    }

    return true; // Assume it's financial if no clear non-financial indicators
  }

  // ---------------------------------------------------------------------------
  // 6. Answer User Query (Chat)
  // ---------------------------------------------------------------------------

  /// Free-form Q&A about the user's finances.
  /// Validates that the query is finance-related before processing.
  Future<String?> answerUserQuery({
    required String query,
    required FinancialContext context,
    List<Map<String, String>> conversationHistory = const [],
  }) async {
    // Check if the query is finance-related
    if (!FinanceQuestionValidator.isFinanceQuestion(query)) {
      debugPrint('🚫 AIEngine: Rejected non-finance query: "$query"');
      return FinanceQuestionValidator.getRejectionMessage();
    }

    final response = await _callGemini(
      systemPrompt: ChatPrompt.system(),
      userPrompt: ChatPrompt.user(
        query: query,
        financialContext: context.toPromptString(),
        conversationHistory: conversationHistory,
      ),
    );

    // Additional validation: check if AI response is finance-related
    if (response != null && !_isFinancialAdvice(response)) {
      debugPrint(
          '🚫 AIEngine: AI returned non-financial response, replacing with rejection');
      return FinanceQuestionValidator.getRejectionMessage();
    }

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
        final allSimilar =
            amounts.every((a) => (a - avg).abs() / (avg == 0 ? 1 : avg) < 0.1);

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

  /// Call AI provider and return raw text response.
  /// Phase 1: Supports OpenAI (primary), Groq, and Gemini
  Future<String?> _callAI({
    required String systemPrompt,
    required String userPrompt,
  }) async {
    if (!isConfigured) {
      debugPrint('AIEngine: API key not configured');
      return null;
    }

    if (!(await _costController.canMakeApiCall())) {
      debugPrint('AIEngine: Daily API call limit reached');
      return null;
    }

    // Use OpenAI if configured (Phase 1 primary provider)
    if (_providerType == AIProviderType.openai) {
      try {
        final response = await _openaiProvider.callAPI(
          systemPrompt: systemPrompt,
          userPrompt: userPrompt,
          maxTokens: 500,
        );
        await _costController.recordApiCall();
        return response;
      } catch (e) {
        debugPrint('AIEngine: OpenAI API error: $e');
        return null;
      }
    }

    // Use Groq if configured
    if (_providerType == AIProviderType.groq) {
      try {
        final response = await _groqProvider.callAPI(
          systemPrompt: systemPrompt,
          userPrompt: userPrompt,
        );
        await _costController.recordApiCall();
        return response;
      } catch (e) {
        debugPrint('AIEngine: Groq API error: $e');
        return null;
      }
    }

    // Use Gemini
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
      final errorMsg = e.toString();
      debugPrint('AIEngine: Gemini API error: $e');

      // Check for quota/rate limit errors
      if (errorMsg.contains('quota') ||
          errorMsg.contains('rate limit') ||
          errorMsg.contains('exceeded')) {
        debugPrint(
            'AIEngine: Quota/Rate limit exceeded. Please check your Gemini API plan.');

        // Check if limit is 0 (free tier not enabled)
        if (errorMsg.contains('limit: 0')) {
          debugPrint(
              'AIEngine: CRITICAL - Free tier quota limit is 0. This means:');
          debugPrint(
              'AIEngine: 1. Free tier may not be enabled for your project');
          debugPrint(
              'AIEngine: 2. You may need to enable the Generative AI API in Google Cloud Console');
          debugPrint(
              'AIEngine: 3. Check quota settings at: https://console.cloud.google.com/apis/api/generativelanguage.googleapis.com/quotas');
        }

        // Extract retry time if available
        final retryMatch =
            RegExp(r'Please retry in ([\d.]+)s').firstMatch(errorMsg);
        if (retryMatch != null) {
          final retrySeconds = double.tryParse(retryMatch.group(1) ?? '0') ?? 0;
          debugPrint(
              'AIEngine: Rate limit - retry after ${retrySeconds.toStringAsFixed(0)} seconds');
        }
      }
    }
    return null;
  }

  /// Legacy method name - redirects to _callAI
  @Deprecated('Use _callAI instead')
  Future<String?> _callGemini({
    required String systemPrompt,
    required String userPrompt,
  }) async {
    return _callAI(systemPrompt: systemPrompt, userPrompt: userPrompt);
  }

  /// Call AI provider expecting a JSON response, parse and return as Map.
  Future<Map<String, dynamic>?> _callGeminiJson({
    required String systemPrompt,
    required String userPrompt,
  }) async {
    if (!isConfigured) {
      debugPrint('AIEngine: API key not configured');
      return null;
    }

    if (!(await _costController.canMakeApiCall())) {
      debugPrint('AIEngine: Daily API call limit reached');
      return null;
    }

    // Use Groq if configured
    if (_providerType == AIProviderType.groq) {
      try {
        final response = await _groqProvider.callAPIJson(
          systemPrompt: systemPrompt,
          userPrompt: userPrompt,
        );
        await _costController.recordApiCall();
        return response;
      } catch (e) {
        debugPrint('AIEngine: Groq API error: $e');
        return null;
      }
    }

    // Use Gemini
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
      final errorMsg = e.toString();
      debugPrint('AIEngine: Gemini API error: $e');

      // Check for quota/rate limit errors
      if (errorMsg.contains('quota') ||
          errorMsg.contains('rate limit') ||
          errorMsg.contains('exceeded')) {
        debugPrint(
            'AIEngine: Quota/Rate limit exceeded. Please check your Gemini API plan.');

        // Check if limit is 0 (free tier not enabled)
        if (errorMsg.contains('limit: 0')) {
          debugPrint(
              'AIEngine: CRITICAL - Free tier quota limit is 0. This means:');
          debugPrint(
              'AIEngine: 1. Free tier may not be enabled for your project');
          debugPrint(
              'AIEngine: 2. You may need to enable the Generative AI API in Google Cloud Console');
          debugPrint(
              'AIEngine: 3. Check quota settings at: https://console.cloud.google.com/apis/api/generativelanguage.googleapis.com/quotas');
        }

        // Extract retry time if available
        final retryMatch =
            RegExp(r'Please retry in ([\d.]+)s').firstMatch(errorMsg);
        if (retryMatch != null) {
          final retrySeconds = double.tryParse(retryMatch.group(1) ?? '0') ?? 0;
          debugPrint(
              'AIEngine: Rate limit - retry after ${retrySeconds.toStringAsFixed(0)} seconds');
        }
      }
    }
    return null;
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
