# Firebase Authentication Configuration Fix

## Issues to Fix:
1. **Google Sign-In**: Missing SHA-1 fingerprint
2. **Email Authentication**: reCAPTCHA configuration error

## 🔧 Step 1: Fix Google Sign-In (SHA-1 Fingerprint)

### Your SHA-1 Fingerprint:
```
80:B9:97:AF:AC:41:A6:0A:07:6F:56:5A:F8:2E:D0:24:00:E9:87:AC
```

### Instructions:
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `budget-app-flutter-9c60a`
3. Go to **Project Settings** (gear icon)
4. Select the **General** tab
5. Scroll down to **Your apps** section
6. Find your Android app: `com.fingenie.budgettracker`
7. Click **Add fingerprint**
8. Paste the SHA-1 fingerprint: `80:B9:97:AF:AC:41:A6:0A:07:6F:56:5A:F8:2E:D0:24:00:E9:87:AC`
9. Click **Save**
10. **Download the updated `google-services.json`** file
11. Replace the current `android/app/google-services.json` with the new one

## 🔧 Step 2: Fix Email Authentication (reCAPTCHA)

### Option A: Configure reCAPTCHA (Recommended for Production)
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `budget-app-flutter-9c60a`
3. Go to **Authentication** → **Settings** → **Advanced**
4. Under **reCAPTCHA Enforcement**, configure the settings:
   - Enable reCAPTCHA for email/password authentication
   - Add your app's domain to authorized domains
5. Go to **Authentication** → **Settings** → **Authorized domains**
6. Add your domains (for development, add `localhost`)

### Option B: Disable reCAPTCHA (Temporary for Development)
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `budget-app-flutter-9c60a`
3. Go to **Authentication** → **Settings** → **Advanced**
4. Under **reCAPTCHA Enforcement**, set to **Disabled** for development
5. **⚠️ Remember to re-enable for production!**

## 🔧 Step 3: Enable Authentication Methods

Make sure these are enabled in Firebase Console:
1. Go to **Authentication** → **Sign-in method**
2. Enable **Email/Password**
3. Enable **Google** (if you want Google Sign-In)

## 🧪 Testing

After making these changes:
1. Clean and rebuild the app: `flutter clean && flutter pub get`
2. Test Google Sign-In
3. Test Email Sign-In with a new email address
4. Test Email Sign-Up

## 📱 Alternative: Use Firebase Auth Emulator (Development Only)

For development, you can use the Firebase Auth Emulator:
1. Install Firebase CLI: `npm install -g firebase-tools`
2. Run: `firebase emulators:start --only auth`
3. The app will automatically use the emulator in debug mode

## 🔍 Troubleshooting

### If Google Sign-In still fails:
- Ensure the SHA-1 fingerprint is correctly added
- Check that the package name matches: `com.fingenie.budgettracker`
- Download and replace the `google-services.json` file

### If Email Auth still fails:
- Check Firebase Console logs for detailed error messages
- Ensure Email/Password authentication is enabled
- Try disabling reCAPTCHA temporarily for testing

### Generate SHA-1 for Different Keystores:
```bash
# Debug keystore (development)
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# Release keystore (production)
keytool -list -v -keystore /path/to/your/release.keystore -alias your-alias
```

## 📋 Current Status

✅ **Fixed in Code:**
- Added SHA-1 fingerprint to google-services.json
- Improved error handling for reCAPTCHA issues
- Better user-friendly error messages

⚠️ **Requires Firebase Console Configuration:**
- Add SHA-1 fingerprint to Firebase project
- Configure reCAPTCHA settings
- Download updated google-services.json

Once you complete the Firebase Console steps, both Google Sign-In and Email Authentication should work properly!