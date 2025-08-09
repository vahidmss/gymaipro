# 🧭 Navigation Module

## 📋 Overview

This module contains all navigation-related components for the GymAI application, organized in a clean and maintainable structure.

## 📁 Structure

```
navigation/
├── README.md                    # This documentation
├── screens/
│   └── main_navigation_screen.dart  # Main navigation screen with PageView
├── widgets/
│   ├── custom_bottom_navigation.dart # Custom bottom navigation bar
│   └── gymai_logo.dart              # GymAI logo widget
├── models/
│   └── navigation_item.dart         # Navigation item model
├── utils/
│   └── navigation_utils.dart        # Navigation utility functions
└── constants/
    └── navigation_constants.dart    # Navigation constants
```

## 🎯 Components

### Main Navigation Screen
- **File**: `screens/main_navigation_screen.dart`
- **Purpose**: Main container with PageView for switching between sections
- **Features**: 
  - 5 main sections (Chat, Workout, Dashboard, Nutrition, Profile)
  - Smooth page transitions
  - Custom action cards for workout and nutrition sections

### Custom Bottom Navigation
- **File**: `widgets/custom_bottom_navigation.dart`
- **Purpose**: Custom bottom navigation bar with central GymAI logo
- **Features**:
  - 5 navigation items
  - Central prominent GymAI logo button
  - Smooth animations and visual feedback

### GymAI Logo Widget
- **File**: `widgets/gymai_logo.dart`
- **Purpose**: Custom GymAI logo with dumbbell and AI indicator
- **Features**:
  - Scalable design
  - Gradient effects and shadows
  - Optional animation support

## 🚀 Usage

### Basic Navigation Setup
```dart
import 'package:gymaipro/navigation/screens/main_navigation_screen.dart';

// In your app's main route
MaterialPageRoute(
  builder: (_) => const MainNavigationScreen(),
)
```

### Using Navigation Items
```dart
import 'package:gymaipro/navigation/models/navigation_item.dart';

// Create navigation items
final items = [
  NavigationItem(
    index: 0,
    label: 'چت',
    icon: Icons.chat,
    route: '/chat',
  ),
  // ... more items
];
```

## 🎨 Design Principles

- **Consistency**: All navigation components follow the same design language
- **Accessibility**: Support for screen readers and keyboard navigation
- **Performance**: Optimized animations and smooth transitions
- **Responsive**: Works across different screen sizes

## 🔧 Customization

### Adding New Navigation Items
1. Update `navigation_constants.dart` with new item definitions
2. Modify `main_navigation_screen.dart` to include new sections
3. Update `custom_bottom_navigation.dart` for visual representation

### Styling Changes
- Colors: Modify `AppTheme` constants
- Animations: Adjust duration and curve values in navigation widgets
- Layout: Update padding and spacing in navigation components

## 📱 Navigation Flow

```
Main Navigation Screen
├── Chat (index 0) → ChatMainScreen
├── Workout (index 1) → Workout Section with Action Cards
├── Dashboard (index 2) → DashboardScreen (Central)
├── Nutrition (index 3) → Nutrition Section with Action Cards
└── Profile (index 4) → ProfileScreen
```

## 🔄 State Management

- **Current Index**: Managed in `MainNavigationScreen`
- **Page Controller**: Handles smooth page transitions
- **Navigation State**: Preserved during app lifecycle

---

**Developer**: AI Assistant  
**Version**: 1.0  
**Last Updated**: 2024 