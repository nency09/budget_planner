# FinGenie - Play Store Release Checklist

## ✅ COMPLETED STEPS

### 1. App Optimization
- ✅ R8 code shrinking enabled
- ✅ Resource shrinking enabled
- ✅ Expected size reduction: 20-40%

### 2. Security & Signing
- ✅ Signing key created: `fingenie-release-key.jks`
- ✅ Key properties configured
- ✅ Backup created at: `D:\FinGenie_Backups\`
- ✅ .gitignore updated to protect keys
- ✅ Git protection verified

### 3. App Identity
- ✅ App name: FinGenie
- ✅ Package: com.budget.tracker_app
- ✅ Version: 5.4.3 (Build 416)
- ✅ All "Cashew" references replaced

### 4. App Icon
- ✅ Icon updated and generated
- ✅ All sizes created for Android/iOS

### 5. Licenses
- ✅ Android SDK licenses accepted

---

## 🚀 NEXT STEPS

### Step 1: Build Release Bundle
```bash
cd Cashew/budget
build_release.bat
```

Or manually:
```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

### Step 2: Locate Release File
File will be at: `build/app/outputs/bundle/release/app-release.aab`

### Step 3: Upload to Play Store
1. Go to: https://play.google.com/console
2. Select/Create your app
3. Production → Create new release
4. Upload: app-release.aab
5. Add release notes
6. Submit for review

---

## 🔐 SIGNING KEY CREDENTIALS

**Location:** D:\FinGenie_Backups\CREDENTIALS.txt

**Quick Reference:**
- Store Password: fingenie2025
- Key Password: fingenie2025
- Key Alias: fingenie
- Keystore File: fingenie-release-key.jks

⚠️ **CRITICAL:** Never lose these files! Make additional backups to:
- External hard drive
- Cloud storage (private folder)
- Password manager

---

## 📋 PLAY STORE REQUIREMENTS

### Required Assets:
- [ ] App icon (512×512 px)
- [ ] Feature graphic (1024×500 px)
- [ ] Screenshots (minimum 2)
- [ ] Short description (80 chars max)
- [ ] Full description (4000 chars max)
- [ ] Privacy policy URL: https://fingenie.vurlex.in/policy

### App Information:
- Category: Finance
- Content rating: Everyone
- Target audience: Adults
- Pricing: Free (with in-app purchases)

---

## 📊 EXPECTED RESULTS

**Before Optimization:**
- Debug APK: ~127 MB

**After Optimization:**
- Release AAB: ~70-80 MB
- User download: ~40-50 MB (Play Store optimizes)

---

## ⚠️ IMPORTANT NOTES

1. **Backup Signing Key:** Already done at D:\FinGenie_Backups\
2. **Never Commit Keys:** Protected by .gitignore
3. **Test Before Upload:** Install release build on real device
4. **Version Increment:** Update version in pubspec.yaml for future releases

---

## 🆘 TROUBLESHOOTING

### Build Fails?
```bash
flutter clean
flutter pub get
flutter doctor
```

### Icon Not Updated?
```bash
dart run flutter_launcher_icons
```

### Signing Error?
Check that `android/key.properties` and `android/fingenie-release-key.jks` exist

---

**Last Updated:** April 7, 2026
**Status:** Ready for Release Build
