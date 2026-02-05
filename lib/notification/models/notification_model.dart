import 'package:flutter/material.dart';

/// Enum برای انواع اعلان‌ها
enum NotificationType {
  welcome,
  workout,
  reminder,
  achievement,
  message,
  payment,
  system;

  /// Parse from string
  static NotificationType? fromString(String? value) {
    if (value == null) return null;
    try {
      return NotificationType.values.firstWhere(
        (e) => e.name == value,
        orElse: () => NotificationType.system,
      );
    } catch (e) {
      return NotificationType.system;
    }
  }
}

/// Model برای اعلان‌ها
class NotificationItem {
  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.isRead,
    required this.type,
    this.priority = 1,
    this.data = const {},
    this.actionUrl,
    this.expiresAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['created_at'] as String),
      isRead: json['is_read'] as bool,
      type:
          NotificationType.fromString(json['type'] as String?) ??
          NotificationType.system,
      priority: json['priority'] as int? ?? 1,
      data: Map<String, dynamic>.from(json['data'] as Map? ?? {}),
      actionUrl: json['action_url'] as String?,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
    );
  }

  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  bool isRead;
  final NotificationType type;
  final int priority;
  final Map<String, dynamic> data;
  final String? actionUrl;
  final DateTime? expiresAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'created_at': timestamp.toIso8601String(),
      'is_read': isRead,
      'type': type.name,
      'priority': priority,
      'data': data,
      'action_url': actionUrl,
      'expires_at': expiresAt?.toIso8601String(),
    };
  }

  NotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? timestamp,
    bool? isRead,
    NotificationType? type,
    int? priority,
    Map<String, dynamic>? data,
    String? actionUrl,
    DateTime? expiresAt,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      data: data ?? this.data,
      actionUrl: actionUrl ?? this.actionUrl,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  /// Check if notification is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Check if notification is high priority
  bool get isHighPriority => priority >= 4;

  /// Get formatted time ago
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'همین الان';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} دقیقه پیش';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ساعت پیش';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} روز پیش';
    } else {
      final persianMonths = [
        '',
        'فروردین',
        'اردیبهشت',
        'خرداد',
        'تیر',
        'مرداد',
        'شهریور',
        'مهر',
        'آبان',
        'آذر',
        'دی',
        'بهمن',
        'اسفند',
      ];
      return '${timestamp.day} ${persianMonths[timestamp.month]}';
    }
  }
}

/// Model برای تنظیمات اعلان‌ها
class NotificationSettingsModel {
  NotificationSettingsModel({
    this.workoutReminders = true,
    this.mealReminders = true,
    this.weightReminders = true,
    this.chatNotifications = true,
    this.achievementNotifications = true,
    this.generalNotifications = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.quietStartTime,
    this.quietEndTime,
  });
  final bool workoutReminders;
  final bool mealReminders;
  final bool weightReminders;
  final bool chatNotifications;
  final bool achievementNotifications;
  final bool generalNotifications;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final TimeOfDay? quietStartTime;
  final TimeOfDay? quietEndTime;

  NotificationSettingsModel copyWith({
    bool? workoutReminders,
    bool? mealReminders,
    bool? weightReminders,
    bool? chatNotifications,
    bool? achievementNotifications,
    bool? generalNotifications,
    bool? soundEnabled,
    bool? vibrationEnabled,
    TimeOfDay? quietStartTime,
    TimeOfDay? quietEndTime,
  }) {
    return NotificationSettingsModel(
      workoutReminders: workoutReminders ?? this.workoutReminders,
      mealReminders: mealReminders ?? this.mealReminders,
      weightReminders: weightReminders ?? this.weightReminders,
      chatNotifications: chatNotifications ?? this.chatNotifications,
      achievementNotifications:
          achievementNotifications ?? this.achievementNotifications,
      generalNotifications: generalNotifications ?? this.generalNotifications,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      quietStartTime: quietStartTime ?? this.quietStartTime,
      quietEndTime: quietEndTime ?? this.quietEndTime,
    );
  }
}
