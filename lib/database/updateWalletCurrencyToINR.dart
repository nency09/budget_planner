import 'package:budget/struct/databaseGlobal.dart';
import 'package:drift/drift.dart' show Value;

/// Updates all wallets to use INR currency
/// Useful for converting from USD to INR
Future<void> updateAllWalletsToINR() async {
  print('Updating all wallets to INR currency...');
  
  final allWallets = await database.getAllWallets();
  int updatedCount = 0;
  
  for (var wallet in allWallets) {
    if (wallet.currency != 'inr') {
      await database.createOrUpdateWallet(
        wallet.copyWith(currency: Value('inr')),
      );
      updatedCount++;
      print('Updated wallet "${wallet.name}" from ${wallet.currency ?? "null"} to INR');
    }
  }
  
  print('✅ Updated $updatedCount wallet(s) to INR');
}
