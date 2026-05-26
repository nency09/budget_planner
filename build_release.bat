@echo off
echo ========================================
echo Building FinGenie Release Bundle
echo ========================================
echo.

echo Step 1: Cleaning previous builds...
call flutter clean
echo.

echo Step 2: Getting dependencies...
call flutter pub get
echo.

echo Step 3: Building release bundle (AAB)...
call flutter build appbundle --release
echo.

echo ========================================
echo Build Complete!
echo ========================================
echo.
echo Your release bundle is at:
echo build\app\outputs\bundle\release\app-release.aab
echo.
echo File size:
dir build\app\outputs\bundle\release\app-release.aab | find "app-release.aab"
echo.
echo Next: Upload this file to Google Play Console
pause
