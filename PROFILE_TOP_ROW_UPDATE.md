# Profile Page - Top Row Update

## Overview
Updated the Profile / More Actions page to display Pro, Settings, and Login as three equal-width buttons in a single horizontal row at the top of the page.

## Changes Made

### Visual Layout
**Before:**
```
[Cashew Pro Banner]
[Settings & Customization - Full Width]
[Login - Full Width]
```

**After:**
```
[Cashew Pro Banner]
[ Pro ] [ Settings ] [ Login ]  ← Single horizontal row
```

### Implementation Details

#### 1. Top Row Structure
```dart
Row(
  children: [
    Expanded(child: ProButton),      // Opens Premium page
    SizedBox(width: 8),               // Spacing
    Expanded(child: SettingsButton),  // Opens Settings page
    SizedBox(width: 8),               // Spacing
    Expanded(child: LoginButton),     // Opens Login/Account
  ],
)
```

#### 2. Button Layout (Column Style)
Each button uses `isOutlinedColumn: true` which creates:
- Icon displayed at top (30px size)
- Text displayed below icon (13px font)
- Centered alignment
- Outlined border (2px)
- Rounded corners (10px radius)
- Vertical padding (14px top/bottom)

#### 3. Custom Login Button Widget
Created `_LoginButtonColumn` widget that:
- Shows "Login" icon when not logged in
- Shows "Account" icon when logged in
- Opens login flow when not logged in
- Opens Accounts page when logged in
- Matches the visual style of Pro and Settings buttons
- Updates dynamically based on login state

### Files Modified

**`lib/pages/settingsPage.dart`:**
1. Updated `MorePages` class to use horizontal Row layout
2. Added `_LoginButtonColumn` custom widget
3. Added import for `AccountsPage`

### Design Features

✅ **Equal Width Buttons**
- All three buttons use `Expanded` widget
- Ensures equal distribution of space

✅ **Consistent Spacing**
- 8px spacing between buttons using `SizedBox(width: 8)`
- Maintains visual balance

✅ **Icon Above Text**
- Uses `isOutlinedColumn: true` for Pro and Settings
- Custom column layout for Login button
- Icons: 30px size
- Text: 13px font size

✅ **Dark Theme Compatible**
- Uses theme-aware colors
- Border color adapts to Material You setting
- Text color uses theme opacity

✅ **Responsive Icons**
- Respects `appStateSettings["outlinedIcons"]` setting
- Switches between outlined and rounded icons

### Navigation Behavior

| Button | Not Logged In | Logged In |
|--------|--------------|-----------|
| **Pro** | Opens Premium page | Opens Premium page |
| **Settings** | Opens Settings page | Opens Settings page |
| **Login** | Opens login flow | Opens Accounts page |

### Button States

**Login Button:**
- **Not Logged In:**
  - Label: "Login"
  - Icon: `Icons.login_outlined` or `Icons.login_rounded`
  - Action: Triggers `signInAndSync()`

- **Logged In:**
  - Label: "Account"
  - Icon: `Icons.account_circle_outlined` or `Icons.account_circle_rounded`
  - Action: Opens `AccountsPage()`

### Code Structure

```dart
// Custom Login Button Widget
class _LoginButtonColumn extends StatefulWidget {
  // Handles login state and navigation
  // Matches visual style of other buttons
  // Updates dynamically when login state changes
}

// Top Row Layout
Row(
  children: [
    Expanded(
      child: SettingsContainerOpenPage(
        isOutlinedColumn: true,
        openPage: PremiumPage(),
        title: "Pro",
        icon: Icons.star,
      ),
    ),
    SizedBox(width: 8),
    Expanded(
      child: SettingsContainerOpenPage(
        isOutlinedColumn: true,
        openPage: SettingsPageFramework(),
        title: "Settings",
        icon: Icons.settings,
      ),
    ),
    SizedBox(width: 8),
    Expanded(
      child: _LoginButtonColumn(),
    ),
  ],
)
```

### Benefits

1. **Space Efficiency** - Uses horizontal space better, reduces vertical scrolling
2. **Quick Access** - All three primary actions visible at once
3. **Visual Balance** - Equal-width buttons create clean, organized appearance
4. **Consistent Design** - All buttons follow same visual pattern
5. **Better UX** - Reduces taps needed to access key features

### Testing Notes

- Verify equal width distribution on different screen sizes
- Test login state transitions (logged out → logged in)
- Confirm icon style changes (outlined/rounded setting)
- Check dark theme appearance
- Validate navigation to correct pages
- Test on both phone and tablet layouts

### Future Enhancements

1. Add subtle animations on button press
2. Consider adding badge indicators (e.g., "Pro" badge for premium users)
3. Add haptic feedback on button tap
4. Consider localization for button labels
5. Add loading state for login button during authentication