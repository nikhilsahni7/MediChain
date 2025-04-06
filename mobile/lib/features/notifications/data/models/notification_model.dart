import 'package:flutter/material.dart';

enum NotificationType {
  expiryAlert,
  lowStock,
  newMedicine,
  securityAlert,
  systemUpdate,
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationType type;
  final bool isRead;
  final Map<String, dynamic>? metadata;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.isRead = false,
    this.metadata,
  });

  IconData get icon {
    switch (type) {
      case NotificationType.expiryAlert:
        return Icons.warning_amber_rounded;
      case NotificationType.lowStock:
        return Icons.inventory_2_outlined;
      case NotificationType.newMedicine:
        return Icons.medication_outlined;
      case NotificationType.securityAlert:
        return Icons.security;
      case NotificationType.systemUpdate:
        return Icons.system_update;
    }
  }

  Color getColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (type) {
      case NotificationType.expiryAlert:
        return Colors.red;
      case NotificationType.lowStock:
        return Colors.orange;
      case NotificationType.newMedicine:
        return colorScheme.primary;
      case NotificationType.securityAlert:
        return Colors.red.shade700;
      case NotificationType.systemUpdate:
        return Colors.blue;
    }
  }

  // Factory constructor for demo data
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      timestamp: DateTime.parse(json['timestamp']),
      type: NotificationType.values.byName(json['type']),
      isRead: json['isRead'] ?? false,
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
      'isRead': isRead,
      'metadata': metadata,
    };
  }
}
