import 'package:flutter/foundation.dart';
import 'package:budget/ai/models/ai_insight.dart';
import 'package:budget/ai/models/financial_score.dart';
import 'package:budget/ai/models/spending_prediction.dart';
import 'package:budget/ai/models/ai_advice.dart';
import 'package:budget/ai/services/ai_engine.dart';

/// Provider for managing AI state across the app.
///
/// This can be used with Flutter's Provider/ChangeNotifierProvider
/// to reactively update AI-related widgets.
class AIProvider extends ChangeNotifier {
  final AIEngine _engine = AIEngine();

  // State
  AIInsight? _weeklyInsight;
  FinancialScore? _financialScore;
  SpendingPrediction? _prediction;
  AIAdvice? _latestAdvice;
  List<DetectedSubscription> _detectedSubscriptions = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  AIInsight? get weeklyInsight => _weeklyInsight;
  FinancialScore? get financialScore => _financialScore;
  SpendingPrediction? get prediction => _prediction;
  AIAdvice? get latestAdvice => _latestAdvice;
  List<DetectedSubscription> get detectedSubscriptions =>
      _detectedSubscriptions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isConfigured => _engine.isConfigured;

  /// Configure the AI engine with an API key.
  void configure({required String apiKey}) {
    _engine.configure(apiKey: apiKey);
    notifyListeners();
  }

  /// Load weekly spending insights.
  Future<void> loadWeeklyInsights({
    required double totalIncome,
    required double totalSpent,
    required List<Map<String, dynamic>> categoryBreakdown,
    required DateTime weekStart,
    required DateTime weekEnd,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _weeklyInsight = await _engine.generateWeeklyInsights(
        totalIncome: totalIncome,
        totalSpent: totalSpent,
        categoryBreakdown: categoryBreakdown,
        weekStart: weekStart,
        weekEnd: weekEnd,
      );
    } catch (e) {
      _errorMessage = 'Failed to load insights: $e';
      debugPrint('AIProvider: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load financial health score.
  Future<void> loadFinancialScore({
    required double totalIncome,
    required double totalExpenses,
    required double savingsRate,
    required double budgetAdherence,
    required int numCategories,
    required int recurringExpenseCount,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _financialScore = await _engine.calculateFinancialScore(
        totalIncome: totalIncome,
        totalExpenses: totalExpenses,
        savingsRate: savingsRate,
        budgetAdherence: budgetAdherence,
        numCategories: numCategories,
        recurringExpenseCount: recurringExpenseCount,
      );
    } catch (e) {
      _errorMessage = 'Failed to load score: $e';
      debugPrint('AIProvider: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load spending prediction.
  Future<void> loadPrediction({
    required List<Map<String, dynamic>> historicalMonths,
    required List<Map<String, dynamic>> currentCategories,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _prediction = await _engine.predictNextMonthSpending(
        historicalMonths: historicalMonths,
        currentCategories: currentCategories,
      );
    } catch (e) {
      _errorMessage = 'Failed to load prediction: $e';
      debugPrint('AIProvider: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Ask for financial advice.
  Future<void> askAdvice({
    required String question,
    required FinancialContext context,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _latestAdvice = await _engine.generateAdvice(
        userQuestion: question,
        context: context,
      );
    } catch (e) {
      _errorMessage = 'Failed to get advice: $e';
      debugPrint('AIProvider: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Detect subscriptions from transaction list.
  Future<void> loadSubscriptionDetection({
    required List<Map<String, dynamic>> recentTransactions,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _detectedSubscriptions = await _engine.detectSubscriptions(
        recentTransactions: recentTransactions,
      );
    } catch (e) {
      _errorMessage = 'Failed to detect subscriptions: $e';
      debugPrint('AIProvider: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Check if the user has access to a given AI feature.
  /// Used for monetization gating.
  bool canAccessFeature(String featureName, String subscriptionTier) {
    const freeFeatures = ['tracking', 'basic_analytics'];
    const premiumFeatures = [
      ...freeFeatures,
      'advanced_reports',
      'cloud_backup',
      'financial_score'
    ];
    const aiProFeatures = [
      ...premiumFeatures,
      'ai_insights',
      'ai_advice',
      'spending_predictions',
      'ai_chat'
    ];

    switch (subscriptionTier) {
      case 'ai_pro':
        return aiProFeatures.contains(featureName);
      case 'premium':
        return premiumFeatures.contains(featureName);
      default:
        return freeFeatures.contains(featureName);
    }
  }
}
