# Invite Friends Feature Implementation

## Overview
Added an "Invite Friends" feature to the Profile/More Actions page and moved "Delete Account" to the Settings page.

## Changes Made

### 1. Profile/More Actions Page (`lib/pages/settingsPage.dart`)

#### Section 6 - Updated
- **Removed**: Delete Account button
- **Added**: Invite Friends button next to Privacy Policy

**Invite Friends Implementation**:
```dart
SettingsContainer(
  onTap: () async {
    await Share.share(
      'I am using this AI Money Manager app to track my expenses. Try it here: https://cashewapp.web.app',
      subject: 'Check out this AI Money Manager app!',
    );
  },
  title: "Invite Friends",
  icon: appStateSettings["outlinedIcons"]
      ? Icons.share_outlined
      : Icons.share_rounded,
  isOutlined: true,
)
```

**Features**:
- Opens system share sheet
- Allows sharing via WhatsApp, Telegram, Email, SMS, and other installed apps
- Pre-filled message: "I am using this AI Money Manager app to track my expenses. Try it here: https://cashewapp.web.app"
- Uses the existing `share_plus: ^10.0.0` package

### 2. Settings Page (`lib/pages/settingsPage.dart`)

#### New Section - Account
Added a new "Account" section at the bottom of Settings with the Delete Account option:

```dart
SettingsHeader(title: "account".tr()),

SettingsContainer(
  title: "Delete Account",
  description: "Permanently delete your account and all data",
  icon: Icons.delete_forever_rounded,
  onTap: () {
    openPopup(
      context,
      icon: Icons.warning_rounded,
      title: "Delete Account",
      description: "This action cannot be undone. Are you sure you want to delete your account and all associated data?",
      onCancel: () {
        popRoute(context);
      },
      onCancelLabel: "Cancel",
      onSubmit: () {
        // Add delete account logic here
        popRoute(context);
      },
      onSubmitLabel: "Delete",
    );
  },
)
```

### 3. Import Added
Added `share_plus` import to `settingsPage.dart`:
```dart
import 'package:share_plus/share_plus.dart';
```

## User Flow

### Invite Friends
1. User opens Profile/More Actions page
2. User taps "Invite Friends" button (next to Privacy Policy)
3. System share sheet opens
4. User can select any app (WhatsApp, Telegram, Email, SMS, etc.)
5. Pre-filled message is shared with the selected app

### Delete Account
1. User opens Settings page (from Profile/More Actions → Settings)
2. Scrolls to the bottom "Account" section
3. Taps "Delete Account"
4. Warning popup appears with confirmation
5. User can Cancel or Delete

## Benefits
- More accessible sharing feature in the Profile section
- Delete Account is now in a more appropriate location (Settings)
- Uses native system share functionality for better UX
- Works across all platforms (iOS, Android, Web)

## Package Used
- `share_plus: ^10.0.0` (already installed in the project)

## Testing Checklist
- [ ] Invite Friends button appears next to Privacy Policy
- [ ] Tapping Invite Friends opens system share sheet
- [ ] Share message contains correct text and link
- [ ] Can share via WhatsApp, Telegram, Email, SMS
- [ ] Delete Account appears in Settings under "Account" section
- [ ] Delete Account shows warning popup
- [ ] Cancel button works correctly
- [ ] Delete button triggers account deletion (when logic is implemented)
