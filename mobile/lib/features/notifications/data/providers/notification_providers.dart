import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medileger/features/notifications/data/models/notification_model.dart';

// Sample notifications for demo
final List<NotificationModel> _sampleNotifications = [
  NotificationModel(
    id: '1',
    title: 'Medicines Expiring Soon',
    message:
        '5 medicines are expiring within the next 30 days. Check inventory.',
    timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    type: NotificationType.expiryAlert,
    metadata: {'medicineCount': 5},
  ),
  NotificationModel(
    id: '2',
    title: 'Low Stock Alert',
    message: 'Paracetamol (500mg) is running low. Current quantity: 15',
    timestamp: DateTime.now().subtract(const Duration(hours: 5)),
    type: NotificationType.lowStock,
    metadata: {
      'medicineId': 'med123',
      'medicineName': 'Paracetamol',
      'quantity': 15
    },
  ),
  NotificationModel(
    id: '3',
    title: 'New Medicine Added',
    message: 'Amoxicillin (250mg) has been added to your inventory',
    timestamp: DateTime.now().subtract(const Duration(days: 1)),
    type: NotificationType.newMedicine,
    metadata: {'medicineName': 'Amoxicillin', 'quantity': 100},
  ),
  NotificationModel(
    id: '4',
    title: 'Medicine Wastage Alert',
    message: '25 units of Insulin expired without use',
    timestamp: DateTime.now().subtract(const Duration(days: 2)),
    type: NotificationType.expiryAlert,
    metadata: {'medicineName': 'Insulin', 'quantity': 25},
  ),
  NotificationModel(
    id: '5',
    title: 'Blockchain Security Alert',
    message:
        'New device accessed your hospital account. Verify if this was you.',
    timestamp: DateTime.now().subtract(const Duration(days: 3)),
    type: NotificationType.securityAlert,
  ),
  NotificationModel(
    id: '6',
    title: 'System Update',
    message: 'Medileger app updated to version 1.2.0',
    timestamp: DateTime.now().subtract(const Duration(days: 5)),
    type: NotificationType.systemUpdate,
  ),
  NotificationModel(
    id: '7',
    title: 'Low Stock Alert',
    message: 'Ibuprofen (400mg) is running low. Current quantity: 10',
    timestamp: DateTime.now().subtract(const Duration(days: 7)),
    type: NotificationType.lowStock,
    metadata: {
      'medicineId': 'med456',
      'medicineName': 'Ibuprofen',
      'quantity': 10
    },
  ),
];

// Provider for all notifications
final notificationsProvider = Provider<List<NotificationModel>>((ref) {
  return _sampleNotifications;
});

// Provider for unread notifications count
final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider);
  return notifications.where((notification) => !notification.isRead).length;
});

// Provider for recent alerts (last 24 hours)
final recentAlertsProvider = Provider<List<NotificationModel>>((ref) {
  final notifications = ref.watch(notificationsProvider);
  final twentyFourHoursAgo = DateTime.now().subtract(const Duration(hours: 24));

  return notifications
      .where((notification) =>
          notification.timestamp.isAfter(twentyFourHoursAgo) &&
          (notification.type == NotificationType.expiryAlert ||
              notification.type == NotificationType.lowStock))
      .toList();
});

// Provider for critical alerts (expiry and low stock)
final criticalAlertsProvider = Provider<List<NotificationModel>>((ref) {
  final notifications = ref.watch(notificationsProvider);

  return notifications
      .where((notification) =>
          notification.type == NotificationType.expiryAlert ||
          notification.type == NotificationType.lowStock ||
          notification.type == NotificationType.securityAlert)
      .toList();
});
