import 'package:flutter/material.dart';

/// Model class representing a navigation item in the app
class NavigationItem {
  const NavigationItem({
    required this.index,
    required this.label,
    required this.icon,
    this.route,
    this.color,
    this.isEnabled = true,
    this.customWidget,
    this.onTap,
  });

  /// Creates a NavigationItem from a Map
  factory NavigationItem.fromMap(Map<String, dynamic> map) {
    return NavigationItem(
      index: map['index'] as int,
      label: map['label'] as String,
      icon: map['icon'] as IconData,
      route: map['route'] as String?,
      color: map['color'] as Color?,
      isEnabled: map['isEnabled'] as bool? ?? true,
      onTap: map['onTap'] as VoidCallback?,
    );
  }
  final int index;
  final String label;
  final IconData icon;
  final String? route;
  final Color? color;
  final bool isEnabled;
  final Widget? customWidget;
  final VoidCallback? onTap;

  /// Converts NavigationItem to a Map
  Map<String, dynamic> toMap() {
    return {
      'index': index,
      'label': label,
      'icon': icon,
      'route': route,
      'color': color,
      'isEnabled': isEnabled,
      'onTap': onTap,
    };
  }

  /// Creates a copy of NavigationItem with updated properties
  NavigationItem copyWith({
    int? index,
    String? label,
    IconData? icon,
    String? route,
    Color? color,
    bool? isEnabled,
    Widget? customWidget,
    VoidCallback? onTap,
  }) {
    return NavigationItem(
      index: index ?? this.index,
      label: label ?? this.label,
      icon: icon ?? this.icon,
      route: route ?? this.route,
      color: color ?? this.color,
      isEnabled: isEnabled ?? this.isEnabled,
      customWidget: customWidget ?? this.customWidget,
      onTap: onTap ?? this.onTap,
    );
  }

  /// Checks if this navigation item is equal to another
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NavigationItem &&
        other.index == index &&
        other.label == label &&
        other.icon == icon &&
        other.route == route &&
        other.color == color &&
        other.isEnabled == isEnabled;
  }

  /// Returns the hash code for this navigation item
  @override
  int get hashCode {
    return Object.hash(index, label, icon, route, color, isEnabled);
  }

  /// Returns a string representation of the navigation item
  @override
  String toString() {
    return 'NavigationItem(index: $index, label: $label, icon: $icon, route: $route, isEnabled: $isEnabled)';
  }
}

/// Extension methods for NavigationItem
extension NavigationItemExtension on NavigationItem {
  /// Checks if this item is currently selected
  bool isSelected(int currentIndex) => index == currentIndex;

  /// Gets the display color for this item
  Color getDisplayColor(
    Color defaultColor,
    Color selectedColor,
    int currentIndex,
  ) {
    if (!isEnabled) {
      return defaultColor.withValues(alpha: 0.3);
    }
    return isSelected(currentIndex) ? selectedColor : defaultColor;
  }

  /// Gets the display opacity for this item
  double getDisplayOpacity(int currentIndex) {
    if (!isEnabled) return 0.3;
    return isSelected(currentIndex) ? 1.0 : 0.6;
  }
}

/// Collection of NavigationItem utilities
class NavigationItemUtils {
  /// Creates a list of default navigation items
  static List<NavigationItem> createDefaultItems() {
    return [
      const NavigationItem(
        index: 0,
        label: 'چت',
        icon: Icons.chat,
        route: '/chat-main',
      ),
      const NavigationItem(
        index: 1,
        label: 'تمرین',
        icon: Icons.fitness_center,
      ),
      const NavigationItem(
        index: 2,
        label: 'داشبورد',
        icon: Icons.home,
        route: '/dashboard',
      ),
      const NavigationItem(index: 3, label: 'تغذیه', icon: Icons.restaurant),
      const NavigationItem(
        index: 4,
        label: 'پروفایل',
        icon: Icons.person,
        route: '/profile',
      ),
    ];
  }

  /// Finds a navigation item by index
  static NavigationItem? findByIndex(List<NavigationItem> items, int index) {
    try {
      return items.firstWhere((item) => item.index == index);
    } catch (e) {
      return null;
    }
  }

  /// Finds a navigation item by route
  static NavigationItem? findByRoute(List<NavigationItem> items, String route) {
    try {
      return items.firstWhere((item) => item.route == route);
    } catch (e) {
      return null;
    }
  }

  /// Gets the index of a navigation item by route
  static int? getIndexByRoute(List<NavigationItem> items, String route) {
    final item = findByRoute(items, route);
    return item?.index;
  }

  /// Validates a list of navigation items
  static bool validateItems(List<NavigationItem> items) {
    if (items.isEmpty) return false;

    // Check for duplicate indices
    final indices = items.map((item) => item.index).toSet();
    if (indices.length != items.length) return false;

    // Check for duplicate labels
    final labels = items.map((item) => item.label).toSet();
    if (labels.length != items.length) return false;

    return true;
  }

  /// Sorts navigation items by index
  static List<NavigationItem> sortByIndex(List<NavigationItem> items) {
    final sortedItems = List<NavigationItem>.from(items);
    sortedItems.sort((a, b) => a.index.compareTo(b.index));
    return sortedItems;
  }
}
