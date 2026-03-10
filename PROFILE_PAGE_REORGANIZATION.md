# Profile / More Actions Page Reorganization

## Overview
The Profile / More Actions page has been reorganized into 7 logical sections for better user experience and navigation.

## New Page Structure

### SECTION 1 — PRO + SETTINGS + LOGIN (TOP SECTION)
**Components:**
- Cashew Pro Banner (existing, shown at top via PageFramework)
- Pro, Settings, Login (horizontal row of 3 equal-width buttons)

**Layout:** 
- Banner at top (full-width)
- Single horizontal row with 3 columns:
  - Pro (opens Premium page)
  - Settings (opens Settings page)
  - Login/Account (opens login or account page)

**Design:**
- Each button displays icon above text (column layout)
- Equal width for all three buttons
- 8px spacing between buttons
- Outlined card style with rounded corners
- Icons and text centered vertically

### SECTION 2 — ASK ANY QUESTION
**Components:**
- Ask Any Question card (opens https://abc.com)

**Features:**
- Large highlighted card to emphasize the feature
- Uses `openUrl()` function to launch external URL
- Icon: question_answer (outlined/rounded based on settings)

**Layout:** Full-width card

### SECTION 3 — SPENDING SUMMARY
**Components:**
- All Spending Summary

**Layout:** Full-width card

### SECTION 4 — FINANCIAL PLANNING
**Components:**
- Goals
- Loans
- Scheduled

**Layout:** 2-column grid (2 rows, with second row having only 1 item)

### SECTION 5 — MONEY MANAGEMENT
**Components:**
- Accounts
- Budgets
- Categories

**Layout:** 2-column grid (2 rows, with second row having only 1 item)

### SECTION 6 — SUPPORT
**Components:**
- Feedback
- Privacy Policy (new, opens https://cashewapp.web.app/privacy.html)

**Layout:** 2-column grid (1 row × 2 columns)

### SECTION 7 — LEGAL & ACCOUNT
**Components:**
- Delete Account (warning style with red icon)

**Features:**
- Delete Account shows confirmation popup before action
- Warning icon and styling to indicate destructive action

**Layout:** Single item (left-aligned in 2-column grid)

## Changes Made

### Added Components:
1. **Ask Any Question** - New card that opens https://abc.com
2. **Privacy Policy** - New button that opens privacy policy URL
3. **Delete Account** - New button with warning popup confirmation
4. **Pro Button** - Quick access to Premium page in horizontal row
5. **_LoginButtonColumn** - Custom widget for Login/Account button in column layout

### Reorganized Components:
1. **Pro, Settings, Login** displayed in single horizontal row at top (Section 1)
2. Grouped **Goals, Loans, Scheduled** together in Section 4
3. Grouped **Accounts, Budgets, Categories** together in Section 5
4. Created dedicated **Support** section (Section 6)
5. Created dedicated **Legal & Account** section (Section 7)

### Removed from Main View:
- **Subscriptions** - Removed from profile page
- **Titles (Associated Titles)** - Removed from profile page
- **About Cashew (Licenses)** - Removed from profile page
- Bill Splitter shortcut (conditional, was shown based on settings)
- Notifications shortcut (conditional, was shown based on settings)
- These features are still accessible through Settings or other navigation paths

## Design Considerations

### Dark Theme Compatibility
- All components use existing theme-aware widgets
- Icons respect `appStateSettings["outlinedIcons"]` setting
- Colors use theme color scheme

### Consistent Spacing
- Maintained existing padding: `EdgeInsetsDirectional.symmetric(horizontal: 4)`
- Maintained existing vertical spacing: `EdgeInsetsDirectional.symmetric(vertical: 5, horizontal: 4)`

### Scrollable Layout
- Page remains scrollable via `PageFramework`
- All sections stack vertically in a Column widget

### Existing Navigation
- All navigation routes preserved
- All existing functionality maintained
- No logic changes to underlying screens

## Implementation Details

### File Modified:
- `lib/pages/settingsPage.dart` - `MorePages` class

### Key Functions Used:
- `openUrl(String url)` - Opens external URLs
- `openBottomSheet()` - Shows bottom sheets
- `openPopup()` - Shows confirmation dialogs
- `SettingsContainer` - Standard button/card widget
- `SettingsContainerOpenPage` - Button that opens a page

### Conditional Rendering:
- All sections only render when `hasSideNavigation == false`
- When sidebar is present, shows `SettingsPageContent()` instead

## Testing Checklist

- [ ] Cashew Pro banner displays at top
- [ ] Pro, Settings, and Login buttons display in single horizontal row
- [ ] All three top buttons have equal width
- [ ] Icons display above text in each button
- [ ] 8px spacing between top row buttons
- [ ] Pro button opens Premium page
- [ ] Settings button opens Settings page
- [ ] Login button shows "Login" when not logged in
- [ ] Login button shows "Account" when logged in
- [ ] Login button opens login flow when not logged in
- [ ] Login button opens Accounts page when logged in
- [ ] Ask Any Question opens https://abc.com
- [ ] All Spending Summary opens wallet details
- [ ] Goals opens objectives list
- [ ] Loans opens credit/debt transactions
- [ ] Scheduled opens upcoming/overdue transactions
- [ ] Accounts opens edit wallets page
- [ ] Budgets opens budget page
- [ ] Categories opens edit categories page
- [ ] Feedback opens rating popup
- [ ] Privacy Policy opens privacy URL
- [ ] Delete Account shows confirmation popup
- [ ] Dark theme works correctly
- [ ] Page is scrollable
- [ ] All icons display correctly (outlined/rounded)
- [ ] Subscriptions NOT shown on profile page
- [ ] Titles NOT shown on profile page
- [ ] About Cashew NOT shown on profile page

## Future Enhancements

1. Implement actual delete account functionality
2. Add analytics tracking for "Ask Any Question" clicks
3. Consider adding section headers for better visual separation
4. Add loading states for external URL launches
5. Localize new strings ("Ask Any Question", "Privacy Policy", "Delete Account")