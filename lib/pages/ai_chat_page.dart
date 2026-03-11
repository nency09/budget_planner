import 'package:budget/ai/models/ai_advice.dart';
import 'package:budget/ai/services/ai_chat_service.dart' as chat;
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
  final chat.AIChatService _chatService = chat.AIChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  FinancialContext? _financialContext;
  int? _currentSessionId;
  List<chat.ChatSession> _sessions = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _initializeChatPage();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeChatPage() async {
    await _loadFinancialContext();
    await _startNewChatSession();
    await _refreshSessions();
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

  /// Start a brand new chat session (like ChatGPT "New Chat").
  Future<void> _startNewChatSession() async {
    final newId = await _chatService.createSession();
    if (!mounted) return;
    setState(() {
      _currentSessionId = newId;
      _messages
        ..clear();
      _addWelcomeMessage();
    });
    _scrollToBottom();
  }

  Future<void> _refreshSessions() async {
    final sessions = await _chatService.getSessions();
    if (!mounted) return;
    setState(() {
      _sessions = sessions;
    });
  }

  /// Load an existing chat session and display its messages.
  Future<void> _openSession(chat.ChatSession session) async {
    final messages = await _chatService.getMessages(session.id);
    if (!mounted) return;
    setState(() {
      _currentSessionId = session.id;
      _messages
        ..clear()
        ..addAll(messages.map(
          (m) => ChatMessage(
            text: m.message,
            isUser: m.role == 'user',
            timestamp: m.timestamp,
          ),
        ));
    });
    _scrollToBottom();
  }

  /// Show delete confirmation dialog for a chat session.
  Future<void> _showDeleteDialog(chat.ChatSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete chat?'),
        content: Text(
          'Are you sure you want to delete "${session.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteSession(session);
    }
  }

  /// Delete a chat session and update the UI.
  Future<void> _deleteSession(chat.ChatSession session) async {
    try {
      await _chatService.deleteSession(session.id);
      
      // If the deleted session was the current one, start a new session
      if (session.id == _currentSessionId) {
        await _startNewChatSession();
      }
      
      // Refresh the sessions list
      await _refreshSessions();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chat deleted'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting session: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete chat'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
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

    try {
      // Each open AI Money Coach screen should already have a session, but
      // defensively create one if it's missing.
      _currentSessionId ??= await _chatService.createSession();

      // Show user message immediately in UI (AIChatService will persist it).
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

      // Get or use cached financial context
      if (_financialContext == null) {
        await _loadFinancialContext();
      }

      final allWallets = Provider.of<AllWallets>(this.context, listen: false);
      final fallbackCurrencySymbol = getCurrencyString(allWallets);

      // Keep financial context up to date, but actual AI prompt building happens
      // inside AIChatService using a compact FinancialSummary.
      _financialContext ??= FinancialContext(
        monthlyIncome: 0,
        monthlyExpenses: 0,
        topCategories: [],
        currency: fallbackCurrencySymbol,
      );

      // Call AI via session-based chat service (persists assistant reply)
      final response = await _chatService.sendMessage(
        sessionId: _currentSessionId!,
        userMessage: text,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _messages.add(ChatMessage(
            text: response.isNotEmpty
                ? response
                : 'Sorry, I couldn\'t generate a response. Please try again.',
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
        _scrollToBottom();
      }

      // Update history list (titles and previews may have changed)
      await _refreshSessions();
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
    final filteredSessions = _sessions.where((s) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return s.title.toLowerCase().contains(q) ||
          (s.lastMessagePreview ?? '').toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Money Coach'),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _isLoading
                ? null
                : () async {
                    await _startNewChatSession();
                    await _refreshSessions();
                  },
            icon: const Icon(Icons.add),
            label: const Text('New Chat'),
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Chat History',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search conversations',
                    prefixIcon: Icon(Icons.search, size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: filteredSessions.isEmpty
                    ? Center(
                        child: Text(
                          'No conversations yet',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredSessions.length,
                        itemBuilder: (context, index) {
                          final session = filteredSessions[index];
                          final isActive = session.id == _currentSessionId;
                          return ListTile(
                            selected: isActive,
                            leading: Icon(
                              Icons.chat_bubble_outline,
                              size: 20,
                            ),
                            title: Text(
                              session.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: session.lastMessagePreview != null
                                ? Text(
                                    session.lastMessagePreview!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : null,
                            onTap: _isLoading
                                ? null
                                : () async {
                                    Navigator.of(context).pop(); // close drawer
                                    await _openSession(session);
                                  },
                            onLongPress: () async {
                              await _showDeleteDialog(session);
                            },
                          );
                        },
                      ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      child: Icon(Icons.person, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'AI Money Coach',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
