# Setup INR Currency and Reduce Transactions

## Changes Made

### 1. ✅ Quick Questions Fixed
- Quick questions in AI Insights now actually call the Groq API
- Shows loading dialog while processing
- Displays AI response in a dialog
- Uses real financial data from your transactions

### 2. ✅ Currency Changed to INR
- Default wallet currency changed from USD to INR in preview data
- New wallets will default to INR

### 3. ✅ Transaction Reduction Function
- Created `reduceTransactionsForTesting()` function
- Keeps only the most recent transactions (default: 20)
- Makes it easier to verify AI analysis

## How to Use

### Update Existing Wallets to INR

If you have existing wallets with USD currency, you can update them:

**Option 1: Via Code (Recommended)**
Add this to your app initialization (e.g., in `main.dart` after database is initialized):

```dart
import 'package:budget/database/updateWalletCurrencyToINR.dart';

// In your initialization code:
await updateAllWalletsToINR();
```

**Option 2: Manual Update**
1. Go to Settings → Wallets
2. Edit each wallet
3. Change currency from USD to INR

### Reduce Transactions for Testing

To reduce the number of transactions for easier AI verification:

**Option 1: Via Code**
Add this to your app initialization:

```dart
import 'package:budget/database/reduceTransactionsForTesting.dart';

// Keep only the 20 most recent transactions
await reduceTransactionsForTesting(keepCount: 20);

// Or keep more/fewer:
await reduceTransactionsForTesting(keepCount: 10); // Keep only 10
```

**Option 2: Manual Delete**
1. Go to Transactions page
2. Select old transactions
3. Delete them manually

## Testing Quick Questions

1. Make sure Groq API key is configured in `.env`:
   ```
   GROQ_API_KEY=gsk_your_key_here
   ```

2. Restart the app

3. Go to AI Insights tab

4. Click any quick question:
   - "💸 Why am I overspending?"
   - "💰 How to save more?"
   - "🔄 Review subscriptions"
   - "📉 Reduce food expenses"

5. Wait for AI response (shows loading dialog)

6. View the answer in the dialog

## Notes

- Quick questions now use real transaction data from your database
- Financial context includes:
  - Monthly income
  - Monthly expenses
  - Top 5 spending categories
  - Currency symbol (₹ for INR)

- The AI will analyze your actual spending patterns and provide personalized advice

## Troubleshooting

**Quick questions not working?**
- Check that Groq API key is in `.env` file
- Restart the app completely (not just hot reload)
- Check console logs for errors

**Currency not showing INR?**
- Update existing wallets using the code above
- Or manually change in wallet settings

**Too many transactions?**
- Use `reduceTransactionsForTesting()` function
- Or manually delete old transactions
