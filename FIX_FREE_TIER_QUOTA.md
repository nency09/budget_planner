# Fix "Free Tier Quota Limit is 0" Error

## The Problem

Your API key is connected, but you're getting this error:
```
* Quota exceeded for metric: generativelanguage.googleapis.com/generate_content_free_tier_requests, limit: 0
```

**This means:** The Generative AI API is not enabled for your Google Cloud project, so the free tier quota is set to 0.

## Solution: Enable the Generative AI API

### Step 1: Go to Google Cloud Console
1. Visit: https://console.cloud.google.com/apis/library/generativelanguage.googleapis.com
2. Make sure you're signed in with the same Google account that created your API key
3. Select your project: **`budgetPlanner`** (or the project your API key belongs to)

### Step 2: Enable the API
1. Click the **"Enable"** button
2. Wait 1-2 minutes for the API to activate
3. You should see a success message

### Step 3: Verify Quota Settings
1. Go to: https://console.cloud.google.com/apis/api/generativelanguage.googleapis.com/quotas
2. Look for quotas named:
   - `generate_content_free_tier_requests` - Should show **15 requests per minute**
   - `generate_content_free_tier_input_token_count` - Should show a token limit
3. If they still show **0**, wait a few more minutes and refresh

### Step 4: Test Again
1. Restart your app (or wait for the rate limit to reset)
2. Try the AI Insights feature again
3. It should work now!

## Alternative: Check Your Project

If you're not sure which project your API key belongs to:

1. Go to: https://aistudio.google.com/apikey
2. Find your API key
3. Check the **"Project"** column - that's the project you need to enable the API for
4. Go to Google Cloud Console and select that project
5. Then follow Step 1-3 above

## Why This Happens

- The API key is valid and connected ✅
- But the **Generative AI API service** is not enabled for your project ❌
- Without the service enabled, Google sets all quotas to 0
- Once enabled, you get the free tier (15 requests/minute, 1,500/day)

## Quick Links

- **Enable API:** https://console.cloud.google.com/apis/library/generativelanguage.googleapis.com
- **Check Quotas:** https://console.cloud.google.com/apis/api/generativelanguage.googleapis.com/quotas
- **API Keys:** https://aistudio.google.com/apikey
- **Rate Limits Info:** https://ai.google.dev/gemini-api/docs/rate-limits

---

**After enabling the API, wait 1-2 minutes, then try again!** 🚀
