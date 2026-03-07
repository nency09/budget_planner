# Groq API Troubleshooting Guide

## Issue: Groq API Key Not Working

### Step 1: Verify .env File is Saved

**IMPORTANT:** Make sure you **SAVE** the `.env` file after adding your Groq API key!

1. Open `.env` file in your editor
2. Add or update the line:
   ```env
   GROQ_API_KEY=gsk_your_key_here
   ```
3. **Press Ctrl+S (or Cmd+S on Mac) to SAVE the file**
4. Check that the file is saved by looking for the dot indicator in the editor tab

### Step 2: Verify .env File Location

The `.env` file must be in the **root of your project**:
```
D:\Projects\budget_planner\Cashew\budget\.env
```

**NOT** in:
- `assets/.env` (this won't work for development)
- Any subdirectory

### Step 3: Check .env File Contents

Run this command to verify:
```powershell
cd "D:\Projects\budget_planner\Cashew\budget"
Get-Content .env
```

You should see:
```
GROQ_API_KEY=gsk_your_key_here
```

**If you only see `GEMINI_API_KEY`, the file wasn't saved!**

### Step 4: Restart the App

After saving `.env`:
1. **Stop the app completely** (not just hot reload)
2. **Restart the app** (flutter run)
3. Check the console logs for:
   - ✅ `Groq API key found in .env, configuring AIEngine with Groq`
   - ✅ `AIEngine configured with Groq. isConfigured: true`

### Step 5: Check Debug Logs

When you try to use AI Insights, check the console for:

**Success:**
```
🚀 GroqProvider: Making API call...
GroqProvider: Model: llama-3.1-8b-instant
GroqProvider: API key length: 56
GroqProvider: API key starts with: gsk_...
✅ GroqProvider: Successfully received response
```

**Errors:**
- `❌ GroqProvider: Invalid API key` → Check your API key is correct
- `❌ GroqProvider: API key not configured` → `.env` file not loaded
- `⚠️ GroqProvider: Rate limit exceeded` → Too many requests (14,400/day limit)

### Step 6: Verify API Key Format

Groq API keys:
- Start with `gsk_`
- Are typically 56 characters long
- Example: `gsk_your_key_here`

### Step 7: Test API Key Directly

If still not working, test your API key with curl:

```powershell
$headers = @{
    "Authorization" = "Bearer gsk_your_key_here"
    "Content-Type" = "application/json"
}
$body = @{
    model = "llama-3.1-8b-instant"
    messages = @(
        @{role = "user"; content = "Hello"}
    )
} | ConvertTo-Json

Invoke-RestMethod -Uri "https://api.groq.com/openai/v1/chat/completions" -Method Post -Headers $headers -Body $body
```

If this works, the issue is in the app. If it fails, the API key is invalid.

### Common Issues

1. **File not saved**: Most common issue - make sure to save `.env`
2. **Wrong location**: `.env` must be in project root, not in `assets/`
3. **App not restarted**: Hot reload doesn't reload `.env` - need full restart
4. **Invalid API key**: Get a new key from https://console.groq.com/keys
5. **Quotes in key**: The code automatically strips quotes, but avoid them if possible

### Quick Fix Checklist

- [ ] `.env` file exists in `D:\Projects\budget_planner\Cashew\budget\.env`
- [ ] `.env` contains `GROQ_API_KEY=gsk_...` (no quotes)
- [ ] File is **SAVED** (check editor tab for unsaved indicator)
- [ ] App was **fully restarted** (not just hot reload)
- [ ] Console shows `✅ Groq API key found in .env`
- [ ] Console shows `✅ AIEngine configured with Groq. isConfigured: true`

---

**Get a new Groq API key:** https://console.groq.com/keys
