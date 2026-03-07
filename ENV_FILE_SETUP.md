# .env File Setup for AI Features

## Current Priority Order

The app checks for API keys in this order:

1. **GROQ_API_KEY** (checked first - recommended)
   - Free, no quota issues
   - 14,400 requests/day
   - No billing setup needed

2. **GEMINI_API_KEY** (fallback only)
   - Only checked if GROQ_API_KEY is not found
   - Requires billing setup
   - 1,500 requests/day (free tier)

## How to Set Up

### Option 1: Use Groq (Recommended)

1. Get your Groq API key: https://console.groq.com/keys
2. Add to `.env` file:
   ```env
   GROQ_API_KEY=gsk_your_key_here
   ```
3. Restart the app

### Option 2: Use Gemini (Fallback)

1. Get your Gemini API key: https://aistudio.google.com/apikey
2. Enable billing in Google Cloud Console
3. Add to `.env` file:
   ```env
   GEMINI_API_KEY=your_key_here
   ```
4. Restart the app

### Option 3: Use Both (Groq Preferred)

If both keys are present, **Groq will be used**:
```env
GROQ_API_KEY=gsk_your_key_here
GEMINI_API_KEY=your_gemini_key_here
```

## Current .env File

Your current `.env` file has:
```
GEMINI_API_KEY=AIzaSyBUWVhCa0bXl3MQlrUSfjo-tPAjP5S_EMU
```

**To use Groq instead**, add:
```
GROQ_API_KEY=gsk_your_groq_key_here
```

The app will automatically use Groq if `GROQ_API_KEY` exists, even if `GEMINI_API_KEY` is also present.

## Verification

After adding your API key, restart the app and check the console:
- ✅ `Groq API key found in .env, configuring AIEngine with Groq` = Using Groq
- ✅ `Gemini API key found in .env, configuring AIEngine with Gemini` = Using Gemini (only if Groq not found)

---

**Get Groq API key (free):** https://console.groq.com/keys
