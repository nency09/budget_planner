import 'package:budget/ai/widgets/financial_score_widget.dart';
import 'package:budget/ai/models/ai_insight.dart';
import 'package:budget/ai/models/spending_prediction.dart';
import 'package:budget/ai/models/financial_score.dart';
import 'package:budget/ai/models/ai_advice.dart';
import 'package:budget/ai/services/ai_engine.dart';
import 'package:budget/ai/services/ai_cache_service.dart';
import 'package:budget/ai/helpers/financial_data_helper.dart';
import 'package:budget/pages/ai_chat_page.dart';
import 'package:budget/widgets/framework/pageFramework.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/currencyFunctions.dart';
import 'package:budget/database/tables.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AIInsightsPage extends StatefulWidget {
  const AIInsightsPage({super.key});

  @override
  State<AIInsightsPage> createState() => AIInsightsPageState();
}

class AIInsightsPageState extends State<AIInsightsPage>
    with AutomaticKeepAliveClientMixin {
  final AIEngine _engine = AIEngine();
  final AICacheService _cacheService = AICacheService();

  FinancialScore? _score;
  AIInsight? _weeklyInsight;
  SpendingPrediction? _prediction;
  bool _isLoadingScore = false;
  bool _isLoadingWeekly = false;
  bool _isLoadingPrediction = false;
  
  int _lastTransactionCount = 0;
  DateTime? _lastTransactionDate;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeTransactionTracking();
  }

  Future<void> _initializeTransactionTracking() async {
    // Get initial transaction count and latest date
    final allTransactions = await database.allTransactions;
    _lastTransactionCount = allTransactions.length;
    if (allTransactions.isNotEmpty) {
      allTransactions.sort((a, b) => b.dateCreated.compareTo(a.dateCreated));
      _lastTransactionDate = allTransactions.first.dateCreated;
    }
    debugPrint('📊 AI Insights: Initial transaction count: $_lastTransactionCount');
  }

  Future<void> _checkAndRefreshIfTransactionsChanged() async {
    // Check if transactions have changed
    final allTransactions = await database.allTransactions;
    final currentCount = allTransactions.length;
    
    DateTime? currentLatestDate;
    if (allTransactions.isNotEmpty) {
      allTransactions.sort((a, b) => b.dateCreated.compareTo(a.dateCreated));
      currentLatestDate = allTransactions.first.dateCreated;
    }

    final countChanged = currentCount != _lastTransactionCount;
    final dateChanged = currentLatestDate != _lastTransactionDate;

    if (countChanged || dateChanged) {
      debugPrint('🔄 AI Insights: Transactions changed! Count: $_lastTransactionCount → $currentCount');
      if (dateChanged) {
        debugPrint('🔄 AI Insights: Latest transaction date changed: $_lastTransactionDate → $currentLatestDate');
      }
      debugPrint('🔄 AI Insights: Clearing cache and reloading data...');
      
      // Clear all AI cache to force fresh calculations
      await _cacheService.clearAll();
      
      // Update tracking
      _lastTransactionCount = currentCount;
      _lastTransactionDate = currentLatestDate;
      
      // Clear current state to force UI refresh
      if (mounted) {
        setState(() {
          _score = null;
          _weeklyInsight = null;
          _prediction = null;
        });
      }
      
      debugPrint('✅ AI Insights: Cache cleared, data will be recalculated from database on next load');
      debugPrint('💡 AI Insights: Click "Calculate Financial Score" or "Generate Insights" to see updated data');
    }
  }

  void scrollToTop() {
    // Can be connected to a ScrollController if needed
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    // Watch for transaction changes and refresh if needed (debounced)
    return StreamBuilder<List<Transaction>>(
      stream: database.watchAllTransactions(),
      builder: (context, snapshot) {
        // Check if transactions changed whenever stream updates (debounced via postFrameCallback)
        if (snapshot.hasData && snapshot.data != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Only check once per frame to avoid excessive checks
            _checkAndRefreshIfTransactionsChanged();
          });
        }
        
        return PageFramework(
          title: 'AI Insights',
          dragDownToDismiss: false,
          listWidgets: [
            const SizedBox(height: 8),
            // Header
            _buildHeader(context),
            const SizedBox(height: 16),
            // Financial Score
            _buildFinancialScoreSection(context),
            const SizedBox(height: 8),
            // Weekly Insights
            _buildWeeklyInsightsSection(context),
            const SizedBox(height: 8),
            // Spending Prediction
            _buildPredictionSection(context),
            const SizedBox(height: 8),
            // Subscription Detection
            _buildSubscriptionSection(context),
            const SizedBox(height: 16),
            // Ask AI Coach
            _buildAskAISection(context),
            const SizedBox(height: 8),
            // Quick Actions
            _buildQuickActions(context),
            const SizedBox(height: 100),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.tertiary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Money Coach',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Your personal finance assistant',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Removed API status badge (icon + text) as per request.
        ],
      ),
    );
  }

  Widget _buildFinancialScoreSection(BuildContext context) {
    return FinancialScoreWidget(
      score: _score,
      isLoading: _isLoadingScore,
      onTap: () {
        _loadFinancialScore(context);
      },
    );
  }

  Widget _buildWeeklyInsightsSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.insights,
                color: Theme.of(context).colorScheme.tertiary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Weekly Insights',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingWeekly)
            const Center(child: CircularProgressIndicator())
          else if (_weeklyInsight != null) ...[
            _buildInsightSummary(context, _weeklyInsight!),
            const SizedBox(height: 8),
            for (final item in _weeklyInsight!.insights)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildPlaceholderInsight(
                  context,
                  icon: item.icon,
                  title: item.title,
                  description: item.description,
                ),
              ),
          ] else ...[
            _buildPlaceholderInsight(
              context,
              icon: '📊',
              title: 'Spending Analysis',
              description:
                  'AI will analyze your weekly spending patterns and highlight key trends.',
            ),
            const SizedBox(height: 8),
            _buildPlaceholderInsight(
              context,
              icon: '💰',
              title: 'Savings Opportunities',
              description:
                  'Discover where you can cut back and save more effectively.',
            ),
          ],
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: () {
                _loadWeeklyInsights(context);
              },
              icon: Icon(Icons.auto_awesome, size: 16),
              label: Text('Generate Insights'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightSummary(BuildContext context, AIInsight insight) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surface
            .withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            insight.summary,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Top tip: ${insight.topTip}',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderInsight(
    BuildContext context, {
    required String icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Spending Prediction',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingPrediction)
            const Center(child: CircularProgressIndicator())
          else if (_prediction != null)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.show_chart,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Predicted total spending: '
                    '${_prediction!.predictedTotal.toStringAsFixed(2)}\n'
                    'Confidence: ${(100 * _prediction!.confidence).round()}%',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.8),
                    ),
                  ),
                  if (_prediction!.warning != null &&
                      _prediction!.warning!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      _prediction!.warning!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .error
                            .withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ],
              ),
            )
          else
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.show_chart,
                    size: 48,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'AI will predict your next month spending\nbased on historical patterns',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: () {
                _loadPrediction(context);
              },
              icon: Icon(Icons.auto_graph, size: 16),
              label: Text('Predict Next Month'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.event_repeat,
                color: Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Subscription Detection',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'AI will scan your transactions for recurring payments\nand help track subscriptions automatically.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAskAISection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Theme.of(context)
            .colorScheme
            .primaryContainer
            .withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AIChatPage(),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline,
                    color: Theme.of(context).colorScheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ask AI Money Coach',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer,
                        ),
                      ),
                      Text(
                        'Get personalized financial advice',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Questions',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _quickActionChip(context, '💸 Why am I overspending?'),
              _quickActionChip(context, '💰 How to save more?'),
              _quickActionChip(context, '🔄 Review subscriptions'),
              _quickActionChip(context, '📉 Reduce food expenses'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickActionChip(BuildContext context, String label) {
    return ActionChip(
      label: Text(
        label,
        style: TextStyle(fontSize: 12),
      ),
      onPressed: () {
        _handleQuickQuestion(context, label);
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Future<void> _handleQuickQuestion(BuildContext context, String question) async {
    if (!_engine.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('API key not configured. Please check your .env file and restart the app.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    // Show loading dialog and store its context
    BuildContext? loadingDialogContext;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        loadingDialogContext = dialogContext;
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Asking AI...'),
            ],
          ),
        );
      },
    );

    try {
      // Get financial context from database
      final allWallets = Provider.of<AllWallets>(context, listen: false);
      final currencySymbol = getCurrencyString(allWallets);

      final allTransactions = await database.allTransactions;
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      
      // Calculate monthly income and expenses
      double monthlyIncome = 0;
      double monthlyExpenses = 0;
      Map<String, double> categoryTotals = {};
      
      for (var transaction in allTransactions) {
        if (transaction.dateCreated.isAfter(monthStart) && transaction.paid) {
          if (transaction.income) {
            monthlyIncome += transaction.amount.abs();
          } else {
            monthlyExpenses += transaction.amount.abs();
            final category = await database.getCategory(transaction.categoryFk).$2;
            categoryTotals[category.name] = 
                (categoryTotals[category.name] ?? 0) + transaction.amount.abs();
          }
        }
      }
      
      // Get top categories
      final sortedCategories = categoryTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topCategories = sortedCategories.take(5).map((e) => e.key).toList();
      
      // Create financial context
      final financialContext = FinancialContext(
        monthlyIncome: monthlyIncome,
        monthlyExpenses: monthlyExpenses,
        topCategories: topCategories,
        currency: currencySymbol,
      );
      
      // Call AI
      final response = await _engine.answerUserQuery(
        query: question,
        context: financialContext,
      );
      
      if (mounted && loadingDialogContext != null) {
        // Close loading dialog first
        Navigator.of(loadingDialogContext!).pop();
        
        if (response != null && response.isNotEmpty) {
          // Show answer in dialog
          showDialog(
            context: context,
            builder: (answerContext) => AlertDialog(
              title: Text('AI Answer'),
              content: SingleChildScrollView(
                child: Text(response),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(answerContext).pop(),
                  child: Text('Close'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to get AI response. Please try again.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted && loadingDialogContext != null) {
        // Close loading dialog
        Navigator.of(loadingDialogContext!).pop();
        debugPrint('Error in quick question: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showFeatureComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '$feature — Configure your API key to enable AI features'),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _loadFinancialScore(BuildContext context) async {
    debugPrint('AI Insights: Loading financial score...');
    debugPrint('AI Insights: isConfigured = ${_engine.isConfigured}');
    
    if (!_engine.isConfigured) {
      debugPrint('AI Insights: Engine not configured, showing error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('API key not configured. Please check your .env file and restart the app.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }
    setState(() {
      _isLoadingScore = true;
    });

    try {
      debugPrint('AI Insights: Calculating real financial data from database...');
      
      // Get real data from database
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = now;
      
      // Calculate real income and expenses
      final incomeExpenses = await FinancialDataHelper.calculateIncomeExpenses(
        start: monthStart,
        end: monthEnd,
      );
      final totalIncome = incomeExpenses['income'] ?? 0.0;
      final totalExpenses = incomeExpenses['expenses'] ?? 0.0;
      final savingsRate = totalIncome > 0 
          ? (totalIncome - totalExpenses) / totalIncome 
          : 0.0;
      
      // Get real budget adherence
      final budgetAdherence = await FinancialDataHelper.calculateBudgetAdherence(
        start: monthStart,
        end: monthEnd,
      );
      
      // Get real category count
      final numCategories = await FinancialDataHelper.getCategoryCount(
        start: monthStart,
        end: monthEnd,
      );
      
      // Get real recurring expense count
      final recurringExpenseCount = await FinancialDataHelper.getRecurringExpenseCount();
      
      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('🎯 AI INSIGHTS: REAL DATA CALCULATED FROM DATABASE');
      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('💰 Total Income: ₹${totalIncome.toStringAsFixed(2)}');
      debugPrint('💸 Total Expenses: ₹${totalExpenses.toStringAsFixed(2)}');
      debugPrint('📊 Savings Rate: ${(savingsRate * 100).toStringAsFixed(1)}%');
      debugPrint('🎯 Budget Adherence: ${(budgetAdherence * 100).toStringAsFixed(1)}%');
      debugPrint('📂 Number of Categories: $numCategories');
      debugPrint('🔄 Recurring Expenses: $recurringExpenseCount');
      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('🤖 Sending REAL data to AI engine for analysis...');
      debugPrint('═══════════════════════════════════════════════════════════');

      final score = await _engine.calculateFinancialScore(
        totalIncome: totalIncome,
        totalExpenses: totalExpenses,
        savingsRate: savingsRate,
        budgetAdherence: budgetAdherence,
        numCategories: numCategories,
        recurringExpenseCount: recurringExpenseCount,
      );
      debugPrint('AI Insights: Financial score received: ${score != null ? "Success" : "Null"}');
      if (mounted) {
        setState(() {
          _score = score;
        });
      }
    } catch (e) {
      debugPrint('AI Insights: Error loading financial score: $e');
      if (mounted) {
        final errorMsg = e.toString();
        debugPrint('AI Insights: Error message: $errorMsg');
        if (errorMsg.contains('quota') || errorMsg.contains('rate limit') || errorMsg.contains('exceeded')) {
          // Check if it's a "limit: 0" error (free tier not enabled)
          final isLimitZero = errorMsg.contains('limit: 0');
          final retryMatch = RegExp(r'Please retry in ([\d.]+)s').firstMatch(errorMsg);
          final retrySeconds = retryMatch != null 
              ? double.tryParse(retryMatch.group(1) ?? '0')?.round() ?? 0 
              : null;
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isLimitZero 
                        ? '⚠️ Free Tier Not Enabled' 
                        : '⚠️ Rate Limit Exceeded',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  if (isLimitZero)
                    Text('Your free tier quota is 0. This means the Generative AI API is not enabled.\n\nEnable it at:\nconsole.cloud.google.com/apis/library/generativelanguage.googleapis.com')
                  else if (retrySeconds != null && retrySeconds > 0)
                    Text('Rate limit reached. Please try again in ${retrySeconds} seconds.')
                  else
                    Text('Quota exceeded. Check your API plan at:\nai.google.dev/gemini-api/docs/rate-limits'),
                ],
              ),
              backgroundColor: isLimitZero ? Colors.red : Colors.orange,
              duration: Duration(seconds: isLimitZero ? 8 : 6),
              action: SnackBarAction(
                label: 'Learn More',
                textColor: Colors.white,
                onPressed: () {
                  // Could open URL if needed
                },
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${errorMsg.length > 100 ? errorMsg.substring(0, 100) + "..." : errorMsg}'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingScore = false;
        });
      }
    }
  }

  Future<void> _loadWeeklyInsights(BuildContext context) async {
    // Always check for transaction changes before loading
    await _checkAndRefreshIfTransactionsChanged();
    
    if (!_engine.isConfigured) {
      _showFeatureComingSoon(context, 'Weekly AI Insights');
      return;
    }
    setState(() {
      _isLoadingWeekly = true;
    });

    try {
      final now = DateTime.now();
      final weekStart = now.subtract(const Duration(days: 7));

      debugPrint('AI Insights: Getting real weekly data from database...');
      
      // Get real income and expenses for the week
      final incomeExpenses = await FinancialDataHelper.calculateIncomeExpenses(
        start: weekStart,
        end: now,
      );
      final totalIncome = incomeExpenses['income'] ?? 0.0;
      final totalSpent = incomeExpenses['expenses'] ?? 0.0;
      
      // Get real category breakdown for the week
      final categoryBreakdown = await FinancialDataHelper.getCategoryBreakdown(
        start: weekStart,
        end: now,
      );
      
      // Format category breakdown for AI prompt (needs 'name' and 'percentage' fields)
      final formattedBreakdown = categoryBreakdown.map((cat) {
        final totalSpending = categoryBreakdown.fold<double>(0.0, (sum, c) => sum + (c['amount'] as num).toDouble());
        final percentage = totalSpending > 0 ? ((cat['amount'] as num).toDouble() / totalSpending * 100) : 0.0;
        return {
          'name': cat['name'] ?? cat['category'],
          'category': cat['category'],
          'amount': cat['amount'],
          'percentage': percentage,
        };
      }).toList();
      
      debugPrint('AI Insights: Weekly data - Income: ₹$totalIncome, Spent: ₹$totalSpent, Categories: ${formattedBreakdown.length}');
      debugPrint('AI Insights: Category breakdown:');
      for (var cat in formattedBreakdown) {
        debugPrint('  - ${cat['name']}: ₹${cat['amount']} (${cat['percentage']}%)');
      }
      debugPrint('AI Insights: Calling generateWeeklyInsights with real data...');

      final insight = await _engine.generateWeeklyInsights(
        totalIncome: totalIncome,
        totalSpent: totalSpent,
        categoryBreakdown: formattedBreakdown,
        weekStart: weekStart,
        weekEnd: now,
      );
      if (mounted) {
        setState(() {
          _weeklyInsight = insight;
        });
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString();
        if (errorMsg.contains('quota') || errorMsg.contains('rate limit') || errorMsg.contains('exceeded')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('⚠️ Billing Not Set Up', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Your API key needs billing enabled. Go to Google AI Studio → API Keys → Set up billing'),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 6),
            ),
          );
        } else {
          _showFeatureComingSoon(context, 'Weekly AI Insights');
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingWeekly = false;
        });
      }
    }
  }

  Future<void> _loadPrediction(BuildContext context) async {
    // Always check for transaction changes before loading
    await _checkAndRefreshIfTransactionsChanged();
    
    if (!_engine.isConfigured) {
      _showFeatureComingSoon(context, 'Spending Prediction');
      return;
    }
    setState(() {
      _isLoadingPrediction = true;
    });

    try {
      debugPrint('AI Insights: Getting real historical data from database...');
      
      // Get real historical monthly spending (last 3 months)
      final historicalMonths = await FinancialDataHelper.getHistoricalMonthlySpending(months: 3);
      
      // Get real current month categories
      final currentCategories = await FinancialDataHelper.getCurrentMonthCategories();
      
      // Format categories for prediction prompt (needs 'name' field)
      final formattedCategories = currentCategories.map((cat) {
        return {
          'name': cat['name'] ?? cat['category'],
          'category': cat['category'],
          'amount': cat['amount'],
        };
      }).toList();
      
      debugPrint('AI Insights: Historical months: ${historicalMonths.length}');
      for (var month in historicalMonths) {
        debugPrint('  - ${month['month']}: ₹${month['total']}');
      }
      debugPrint('AI Insights: Current categories: ${formattedCategories.length}');
      for (var cat in formattedCategories) {
        debugPrint('  - ${cat['name']}: ₹${cat['amount']}');
      }
      debugPrint('AI Insights: Calling predictNextMonthSpending with real data...');

      final prediction = await _engine.predictNextMonthSpending(
        historicalMonths: historicalMonths,
        currentCategories: formattedCategories,
      );
      if (mounted) {
        setState(() {
          _prediction = prediction;
        });
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString();
        if (errorMsg.contains('quota') || errorMsg.contains('rate limit') || errorMsg.contains('exceeded')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('⚠️ Billing Not Set Up', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Your API key needs billing enabled. Go to Google AI Studio → API Keys → Set up billing'),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 6),
            ),
          );
        } else {
          _showFeatureComingSoon(context, 'Spending Prediction');
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPrediction = false;
        });
      }
    }
  }
}
