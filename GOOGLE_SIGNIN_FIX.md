# Google Sign-In Fix Instructions

The Google Sign-In is currently failing with error code 10 because the SHA-1 fingerprint is not configured in Firebase.

## To Fix Google Sign-In:

### Step 1: Get SHA-1 Fingerprint
Run this command in your project's android directory:
```bash
cd android
./gradlew signingReport
```

Look for the SHA1 fingerprint under "Variant: debug" -> "Config: debug"

### Step 2: Add SHA-1 to Firebase
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `budget-app-flutter-9c60a`
3. Go to Project Settings (gear icon)
4. Select your Android app (`com.fingenie.budgettracker`)
5. Scroll down to "SHA certificate fingerprints"
6. Click "Add fingerprint"
7. Paste the SHA1 fingerprint from Step 1
8. Click "Save"

### Step 3: Download Updated google-services.json
1. In Firebase Console, click "Download google-services.json"
2. Replace the current `android/app/google-services.json` file
3. The new file should have oauth_client entries

### Alternative: Use Email Authentication
The app now supports email/password authentication as a simpler alternative:
- Users can sign up with email and password
- No SHA-1 configuration needed
- Works immediately without additional setup

## Current Status:
- ✅ Email authentication is working
- ❌ Google Sign-In needs SHA-1 configuration
- ✅ Sign-out works for both authentication methods
- ✅ Firebase Firestore integration works with both methods