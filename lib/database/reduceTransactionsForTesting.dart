import 'package:budget/struct/databaseGlobal.dart';
import 'package:flutter/foundation.dart';

/// Reduces the number of transactions for easier AI analysis testing
/// Keeps only the most recent transactions (default: last 20)
/// This makes it easier to verify AI analysis is working with real data
Future<void> reduceTransactionsForTesting({int keepCount = 20}) async {
  debugPrint('🔧 Reducing transactions to $keepCount most recent for AI testing...');
  
  try {
    // Get all transactions sorted by date (newest first)
    final allTransactions = await database.allTransactions;
    final originalCount = allTransactions.length;
    
    if (originalCount <= keepCount) {
      debugPrint('ℹ️ Only $originalCount transactions exist, no reduction needed.');
      return;
    }
    
    allTransactions.sort((a, b) => b.dateCreated.compareTo(a.dateCreated));
    
    // Get transactions to delete (all except the most recent keepCount)
    final transactionsToDelete = allTransactions.skip(keepCount).toList();
    final transactionPksToDelete = transactionsToDelete
        .map((t) => t.transactionPk)
        .toList();
    
    debugPrint('🗑️ Deleting ${transactionPksToDelete.length} old transactions (keeping $keepCount most recent)...');
    
    // Delete the transactions
    await database.deleteTransactions(
      transactionPksToDelete,
      updateSharedEntry: false,
    );
    
    debugPrint('✅ Successfully reduced transactions from $originalCount to $keepCount');
    debugPrint('📊 You now have $keepCount transactions to verify AI analysis');
  } catch (e, stackTrace) {
    debugPrint('❌ Error reducing transactions: $e');
    debugPrint('Stack trace: $stackTrace');
    rethrow;
  }
}
