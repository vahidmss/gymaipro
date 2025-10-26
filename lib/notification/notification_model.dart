import 'package:flutter/material.dart';

enum NotificationType {
  workoutReminder,
  mealReminder,
  weightReminder,
  chatMessage,
  achievement,
  general,
}

class NotificationModel {
  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.data,
    required this.createdAt,
    this.isRead = false,
    this.imageUrl,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      body: (json['body'] as String?) ?? '',
      type: _parseNotificationType(json['type'] as String?),
      data: (json['data'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      createdAt: DateTime.parse(
        (json['created_at'] as String?) ?? DateTime.now().toIso8601String(),
      ),
      isRead: (json['is_read'] as bool?) ?? false,
      imageUrl: json['image_url'] as String?,
    );
  }
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final bool isRead;
  final String? imageUrl;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type.name,
      'data': data,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
      'image_url': imageUrl,
    };
  }

  static NotificationType _parseNotificationType(String? type) {
    switch (type) {
      case 'workout_reminder':
        return NotificationType.workoutReminder;
      case 'meal_reminder':
        return NotificationType.mealReminder;
      case 'weight_reminder':
        return NotificationType.weightReminder;
      case 'chat_message':
        return NotificationType.chatMessage;
      case 'achievement':
        return NotificationType.achievement;
      default:
        return NotificationType.general;
    }
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    bool? isRead,
    String? imageUrl,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  String get typeIcon {
    switch (type) {
      case NotificationType.workoutReminder:
        return '⏰';
      case NotificationType.mealReminder:
        return '🍽️';
      case NotificationType.weightReminder:
        return '⚖️';
      case NotificationType.chatMessage:
        return '💬';
      case NotificationType.achievement:
        return '🏆';
      case NotificationType.general:
        return '📢';
    }
  }

  String get typeTitle {
    switch (type) {
      case NotificationType.workoutReminder:
        return 'یادآوری تمرین';
      case NotificationType.mealReminder:
        return 'یادآوری وعده غذایی';
      case NotificationType.weightReminder:
        return 'یادآوری ثبت وزن';
      case NotificationType.chatMessage:
        return 'پیام جدید';
      case NotificationType.achievement:
        return 'دستاورد جدید';
      case NotificationType.general:
        return 'اعلان عمومی';
    }
  }
}

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
