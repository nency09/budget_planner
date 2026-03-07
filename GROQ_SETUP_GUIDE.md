# Using Groq API Instead of Gemini

## Why Groq?

- ✅ **Completely free** - 14,400 requests per day
- ✅ **No billing setup required** - Just sign up and get API key
- ✅ **Fast responses** - Optimized for speed
- ✅ **No quota issues** - Generous free tier
- ✅ **Easy setup** - No Google Cloud Console configuration needed

## Step 1: Get Your Groq API Key

1. Go to: https://console.groq.com/
2. Sign up with your Google/GitHub account (free)
3. Go to: https://console.groq.com/keys
4. Click **"Create API Key"**
5. Copy your API key (starts with `gsk_`)

## Step 2: Update Your .env File

Open `Cashew/budget/.env` and add:

```env
GROQ_API_KEY=your_groq_api_key_here
```

**OR** if you want to keep Gemini as backup:

```env
GROQ_API_KEY=your_groq_api_key_here
GEMINI_API_KEY=your_gemini_key_here
```

**Note:** The app will use Groq if `GROQ_API_KEY` is found, otherwise it falls back to Gemini.

## Step 3: Restart Your App

1. Stop the app completely
2. Restart it (full restart, not hot reload)
3. The app will automatically detect and use Groq

## Step 4: Test AI Insights

1. Open the AI Insights page
2. You should see "API Connected" (green badge)
3. Try "Financial Score" or "Generate Insights"
4. It should work immediately!

## How It Works

The app now supports **multiple AI providers**:

1. **Groq** (recommended) - Free, fast, no setup issues
2. **Gemini** (backup) - If Groq key not found, uses Gemini

The app automatically:
- Detects which API key you have
- Uses Groq if `GROQ_API_KEY` exists
- Falls back to Gemini if only `GEMINI_API_KEY` exists
- Shows which provider is active in debug logs

## Troubleshooting

### "API Not Configured"
- Check that `.env` file has `GROQ_API_KEY=...`
- Make sure there are no quotes around the key
- Restart the app after adding the key

### Still Using Gemini
- The app prioritizes Groq over Gemini
- If you see Gemini in logs, check that `GROQ_API_KEY` is in `.env`
- Verify the key doesn't have quotes: `GROQ_API_KEY=gsk_...` (not `GROQ_API_KEY="gsk_..."`)

### API Errors
- Groq is very reliable, but if you see errors:
  - Check your API key is valid at https://console.groq.com/keys
  - Verify you haven't exceeded the free tier (14,400 requests/day)
  - Check internet connection

## Groq Free Tier Limits

- **14,400 requests per day** (very generous!)
- **30 requests per minute**
- **No credit card required**
- **No billing setup needed**

## Quick Comparison

| Feature | Groq | Gemini |
|---------|------|--------|
| Free Tier | 14,400/day | 1,500/day |
| Setup | Just sign up | Enable API + Billing |
| Speed | Very Fast | Fast |
| Reliability | High | High |
| Quota Issues | Rare | Common |

---

**Get your free Groq API key now:** https://console.groq.com/keys 🚀
