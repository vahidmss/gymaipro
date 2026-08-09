# Navigation Module

## Overview

Main shell uses a 4-tab `IndexedStack` plus a center **+** action (not a tab).

## Structure

```
navigation/
├── screens/
│   ├── main_navigation_screen.dart
│   └── more_screen.dart
├── widgets/
│   ├── custom_bottom_navigation.dart
│   ├── plus_action_sheet.dart
│   └── more_menu_sheet.dart   # legacy → navigates to More tab
├── models/
│   └── navigation_item.dart
├── utils/
│   └── navigation_utils.dart
└── constants/
    └── navigation_constants.dart
```

## Bottom navigation (role-aware)

### Athlete
`خانه | باشگاه من | [+] | پیام‌ها | بیشتر`

- خانه → DashboardScreen (+ هیرو مربی AI)
- باشگاه من → MyClubMainScreen
- + → plus action sheet
- پیام‌ها → ChatMainScreen
- بیشتر → MoreScreen (شامل مربی AI)

مربی AI روی خانه هیرو است و در بیشتر هم هست؛ تب پایین نیست.

### Trainer
`خانه | میز کار | [+] | پیام‌ها | بیشتر`

- میز کار → TrainerDashboardScreen
- پیام‌ها → ChatMainScreen (immersive; bottom bar hidden)
- مربی AI / آکادمی live under More (or push)

Academy is **not** a bottom tab; use `MainNavigationScreen.openAcademy()`.

## Tab indices

| Index | Constant | Content |
|------:|----------|---------|
| 0 | homeIndex | Dashboard |
| 1 | hubIndex | MyClub / Trainer desk |
| 2 | roleTabIndex | Coach AI / Messages |
| 3 | moreIndex | MoreScreen |

Plus is `onPlusTap` only — no index.
