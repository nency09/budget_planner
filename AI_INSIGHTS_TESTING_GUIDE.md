# AI Insights Testing Guide

## Prerequisites

1. **Gemini API Key Setup**
   - Create a `.env` file in `Cashew/budget/` directory (if not already created)
   - Add your Gemini API key:
     ```
     GEMINI_API_KEY=your_api_key_here
     ```
   - Get your API key from: https://aistudio.google.com/apikey

2. **Verify API Key is Loaded**
   - Run the app and check the debug console
   - You should see: `"Successfully loaded .env file"` or `"Gemini key found in .env, configuring AIEngine"`
   - If you see warnings, the API key wasn't loaded correctly

## How to Access AI Insights

### Method 1: Bottom Navigation Bar
- The AI Insights page is one of the **5 fixed tabs** in the bottom navigation
- Look for the **sparkle/auto_awesome icon** (✨) in the bottom nav
- Tap it to open the AI Insights page

### Method 2: Settings/More Menu
- Go to Settings/More menu
- Look for "AI Insights" option
- Tap to navigate to the page

## Testing Each Feature

### 1. Financial Health Score
**What it does:** Calculates a 0-100 score based on your financial metrics

**How to test:**
1. On the AI Insights page, find the **Financial Score** card (top section)
2. Tap the card or the score area
3. You should see a loading indicator
4. After a few seconds, you'll see:
   - A score (0-100)
   - Color-coded indicator (green/yellow/red)
   - Breakdown of factors
   - AI-generated recommendations

**Expected behavior:**
- ✅ Shows loading spinner while calculating
- ✅ Displays score with visual indicator
- ✅ Shows detailed breakdown
- ✅ Provides actionable recommendations

**If it fails:**
- Check console for API errors
- Verify API key is valid
- Check internet connection

---

### 2. Weekly Insights
**What it does:** Analyzes your spending patterns for the past week and provides insights

**How to test:**
1. Scroll to the **"Weekly Insights"** section
2. Tap the **"Generate Insights"** button
3. Wait for the AI to analyze your data
4. You'll see:
   - Summary of your week
   - Top spending categories
   - Savings opportunities
   - Personalized tips

**Expected behavior:**
- ✅ Shows loading indicator
- ✅ Displays summary text
- ✅ Lists multiple insights with icons
- ✅ Each insight has title and description

**Note:** Currently uses demo data. Real data integration is marked with `TODO` comments.

---

### 3. Spending Prediction
**What it does:** Predicts your spending for the next month based on historical patterns

**How to test:**
1. Scroll to the **"Spending Prediction"** section
2. Tap the **"Predict Next Month"** button
3. Wait for the prediction
4. You'll see:
   - Predicted total spending amount
   - Confidence percentage
   - Warning if spending is high

**Expected behavior:**
- ✅ Shows loading indicator
- ✅ Displays predicted amount
- ✅ Shows confidence level (0-100%)
- ✅ May show warnings if spending is concerning

**Note:** Currently uses demo historical data. Real data integration is marked with `TODO` comments.

---

### 4. Subscription Detection
**What it does:** Automatically detects recurring subscriptions from your transactions

**How to test:**
- This feature is currently a **placeholder**
- It will scan transactions for recurring patterns
- No button to test yet - coming soon

---

### 5. Ask AI Money Coach
**What it does:** Chat interface for asking financial questions

**How to test:**
- Currently shows **"Coming Soon"** message
- Tap the card to see a snackbar notification
- Full chat interface is not yet implemented

---

### 6. Quick Questions
**What it does:** Pre-defined question chips for quick AI responses

**How to test:**
- Tap any of the question chips:
  - 💸 "Why am I overspending?"
  - 💰 "How to save more?"
  - 🔄 "Review subscriptions"
  - 📉 "Reduce food expenses"
- Currently shows "Coming Soon" snackbar
- Full implementation coming soon

## Debugging Tips

### Check if API Key is Working
1. Open the app
2. Check the debug console for:
   ```
   Gemini key found in .env, configuring AIEngine
   ```
3. If you see warnings, check:
   - `.env` file exists in `Cashew/budget/`
   - File contains: `GEMINI_API_KEY=your_key`
   - No extra spaces or quotes around the key
   - Key is valid (get a new one from Google AI Studio)

### Check API Calls
- Open debug console
- Look for messages like:
  - `AIEngine: Gemini API error: ...` (if there's an error)
  - `AIEngine: Daily API call limit reached` (if you hit rate limits)
  - `AIEngine: Empty response from Gemini` (if response is empty)

### Test with Real Data
Currently, the AI features use **demo/placeholder data**. To test with real data:

1. Find `TODO` comments in `ai_insights_page.dart`:
   - Line ~609: Replace demo income/expenses
   - Line ~651: Replace demo category breakdown
   - Line ~699: Replace demo historical months

2. Replace with actual database queries:
   ```dart
   // Example: Get real income/expenses
   final income = await database.getTotalIncome();
   final expenses = await database.getTotalExpenses();
   ```

## Expected API Response Times

- **Financial Score:** 2-5 seconds
- **Weekly Insights:** 3-6 seconds
- **Spending Prediction:** 3-6 seconds

If responses take longer than 10 seconds, check:
- Internet connection
- API key validity
- Gemini API status

## Common Issues

### Issue: "Configure your API key" message
**Solution:** 
- Verify `.env` file exists and has correct key
- Restart the app after adding/changing the key
- Check console for loading errors

### Issue: Black screen or app crashes
**Solution:**
- The `.env` loading is now wrapped in try-catch
- App should work even without API key (features just won't work)
- If still crashing, check for other errors in console

### Issue: API calls fail
**Solution:**
- Verify API key is valid at https://aistudio.google.com/apikey
- Check internet connection
- Check if you've hit rate limits (free tier has limits)
- Verify the key has proper permissions

## Next Steps for Full Implementation

To make AI Insights work with real data:

1. **Replace demo data** in `_loadFinancialScore()`, `_loadWeeklyInsights()`, and `_loadPrediction()`
2. **Add database queries** to get:
   - Total income/expenses
   - Category breakdowns
   - Historical spending data
3. **Implement chat interface** for "Ask AI Money Coach"
4. **Add subscription detection** logic
5. **Wire up quick questions** to actual AI responses

## Testing Checklist

- [ ] API key is loaded (check console)
- [ ] Can navigate to AI Insights page
- [ ] Financial Score button works
- [ ] Weekly Insights button works
- [ ] Spending Prediction button works
- [ ] Loading indicators appear
- [ ] Results display correctly
- [ ] Error handling works (test with invalid key)
- [ ] App doesn't crash if API fails

---

**Happy Testing! 🚀**
