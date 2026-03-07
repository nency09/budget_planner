# How to Set Up Billing for Gemini API

## The Problem

Your API keys show **"Quota Tier: Set up billing / Unavailable"** in Google AI Studio. This means billing is not configured, so the API won't work even though you have valid API keys.

## Solution: Enable Billing

### Step 1: Go to Google Cloud Console
1. Visit: https://console.cloud.google.com/
2. Make sure you're signed in with the same Google account that created the API keys

### Step 2: Select Your Project
1. In the top bar, click the project dropdown
2. Select your project: **`budgetPlanner`** (or whichever project your API key belongs to)

### Step 3: Enable Billing
1. In the left sidebar, click **"Billing"** (or go directly to: https://console.cloud.google.com/billing)
2. Click **"Link a billing account"** or **"Create billing account"**
3. If you don't have a billing account:
   - Click **"Create Account"**
   - Fill in your payment information
   - Accept the terms
   - Click **"Submit and enable billing"**

### Step 4: Link Billing to Your Project
1. If you just created a billing account, it should automatically link
2. If not, go to **"Billing"** → **"My Projects"**
3. Find your project (`budgetPlanner`) and click **"Change billing"**
4. Select your billing account and click **"Set account"**

### Step 5: Verify in Google AI Studio
1. Go back to: https://aistudio.google.com/apikey
2. Refresh the page
3. Your API key should now show a quota tier (like "Free tier" or "Pay-as-you-go")
4. The "Unavailable" status should be gone

## Free Tier Information

**Good News:** Google Gemini API has a **generous free tier**:
- **Free tier includes:** 15 requests per minute (RPM) and 1,500 requests per day (RPD)
- **No credit card required for free tier** in some regions
- **You only pay** if you exceed the free tier limits

## After Setting Up Billing

1. **Restart your app** (or hot restart)
2. Try the AI Insights features again
3. The error should be gone and AI features should work!

## Troubleshooting

### "Billing account already exists"
- You might already have a billing account
- Just link it to your project (Step 4 above)

### "Cannot enable billing"
- Make sure you're using a valid payment method
- Some regions have restrictions - check Google Cloud's billing support

### "Still showing Unavailable"
- Wait a few minutes for the changes to propagate
- Try refreshing the Google AI Studio page
- Make sure you're looking at the correct project

### "API still not working after billing setup"
- Double-check the API key in your `.env` file
- Verify the key is from the project with billing enabled
- Check the console for any new error messages

## Cost Information

- **Free tier:** 15 RPM, 1,500 RPD (usually enough for testing)
- **Pay-as-you-go:** Very affordable pricing after free tier
- **Monitor usage:** https://console.cloud.google.com/billing

## Quick Links

- **Google Cloud Console:** https://console.cloud.google.com/
- **Billing Setup:** https://console.cloud.google.com/billing
- **API Keys:** https://aistudio.google.com/apikey
- **Rate Limits Info:** https://ai.google.dev/gemini-api/docs/rate-limits

---

**Once billing is set up, your AI Insights features will work! 🚀**
