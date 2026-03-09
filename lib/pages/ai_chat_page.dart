import 'package:budget/ai/models/ai_advice.dart';
import 'package:budget/ai/services/ai_engine.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/struct/currencyFunctions.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AIChatPage extends StatefulWidget {
  const AIChatPage({super.key});

  @override
  State<AIChatPage> createState() => _AIChatPageState();
}

class _AIChatPageState extends State<AIChatPage> {
  final AIEngine _engine = AIEngine();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  FinancialContext? _financialContext;

  @override
  void initState() {
    super.initState();
    _loadFinancialContext();
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadFinancialContext() async {
    try {
      final allWallets = Provider.of<AllWallets>(context, listen: false);
      final currencySymbol = getCurrencyString(allWallets);

      final allTransactions = await database.allTransactions;
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      
      double monthlyIncome = 0;
      double monthlyExpenses = 0;
      Map<String, double> categoryTotals = {};
      Map<String, double> walletBalances = {};
      
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

          // Track simple per-wallet balance (net sum of amounts for this month)
          final wallet = allWallets.indexedByPk[transaction.walletFk];
          if (wallet != null) {
            final key = wallet.walletPk;
            final signedAmount = transaction.income
                ? transaction.amount.abs()
                : -transaction.amount.abs();
            walletBalances[key] = (walletBalances[key] ?? 0) + signedAmount;
          }
        }
      }
      
      final sortedCategories = categoryTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topCategories = sortedCategories.take(5).map((e) => e.key).toList();

      // Build wallet summary for prompt: name, currency, balance (this month)
      final walletSummaries = <Map<String, dynamic>>[];
      for (final wallet in allWallets.list) {
        final balance = walletBalances[wallet.walletPk] ?? 0.0;
        walletSummaries.add({
          'name': getWalletStringName(allWallets, wallet),
          'currency': wallet.currency ?? '',
          'balance': balance,
        });
      }
      
      setState(() {
        _financialContext = FinancialContext(
          monthlyIncome: monthlyIncome,
          monthlyExpenses: monthlyExpenses,
          topCategories: topCategories,
          currency: currencySymbol,
          wallets: walletSummaries,
        );
      });
    } catch (e) {
      debugPrint('Error loading financial context: $e');
    }
  }

  void _addWelcomeMessage() {
    _messages.add(ChatMessage(
      text: 'Hello! I\'m your AI Money Coach. I can help you with:\n\n'
          '• Understanding your spending patterns\n'
          '• Finding ways to save more money\n'
          '• Reviewing your subscriptions\n'
          '• Creating better budgets\n'
          '• Answering financial questions\n\n'
          'What would you like to know?',
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    if (!_engine.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('API key not configured. Please check your .env file and restart the app.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Add user message
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      // Get or use cached financial context
      if (_financialContext == null) {
        await _loadFinancialContext();
      }

      final allWallets = Provider.of<AllWallets>(this.context, listen: false);
      final fallbackCurrencySymbol = getCurrencyString(allWallets);

      final context = _financialContext ?? FinancialContext(
        monthlyIncome: 0,
        monthlyExpenses: 0,
        topCategories: [],
        currency: fallbackCurrencySymbol,
      );

      // Build conversation history
      final conversationHistory = _messages
          .where((m) => m.isUser || !m.isUser)
          .take(10) // Last 10 messages
          .map((m) => {
                'role': m.isUser ? 'user' : 'assistant',
                'content': m.text,
              })
          .toList();

      // Call AI
      final response = await _engine.answerUserQuery(
        query: text,
        context: context,
        conversationHistory: conversationHistory,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (response != null && response.isNotEmpty) {
            _messages.add(ChatMessage(
              text: response,
              isUser: false,
              timestamp: DateTime.now(),
            ));
          } else {
            _messages.add(ChatMessage(
              text: 'Sorry, I couldn\'t generate a response. Please try again.',
              isUser: false,
              timestamp: DateTime.now(),
            ));
          }
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _messages.add(ChatMessage(
            text: 'Error: ${e.toString()}',
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Money Coach'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  // Loading indicator
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ],
                    ),
                  );
                }
                return _buildMessage(_messages[index]);
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.2),
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Ask me anything about your finances...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    onPressed: _isLoading ? null : _sendMessage,
                    icon: Icon(Icons.send),
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.tertiary,
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_awesome,
                size: 18,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          if (message.isUser) ...[
            SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .secondary
                    .withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                size: 18,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
