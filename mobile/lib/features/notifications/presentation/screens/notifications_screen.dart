import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:medileger/features/notifications/data/models/notification_model.dart';
import 'package:medileger/features/notifications/data/providers/notification_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Implement filter
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Filter coming soon')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () {
              // TODO: Mark all as read
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Marked all as read')),
              );
            },
          ),
        ],
      ),
      body: notifications.isEmpty
          ? _buildEmptyState(context)
          : _buildNotificationsList(context, notifications),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 80,
            color: colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Notifications',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(
      BuildContext context, List<NotificationModel> notifications) {
    final colorScheme = Theme.of(context).colorScheme;

    // Group notifications by date
    final Map<String, List<NotificationModel>> groupedNotifications = {};

    for (final notification in notifications) {
      final dateKey = _getDateKey(notification.timestamp);
      if (!groupedNotifications.containsKey(dateKey)) {
        groupedNotifications[dateKey] = [];
      }
      groupedNotifications[dateKey]!.add(notification);
    }

    // Sort the keys by date (most recent first)
    final sortedKeys = groupedNotifications.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final dateKey = sortedKeys[index];
        final notificationsForDate = groupedNotifications[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                dateKey,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
              ),
            ),
            ...notificationsForDate.map((notification) =>
                _buildNotificationCard(context, notification)),
          ],
        );
      },
    );
  }

  String _getDateKey(DateTime date) {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today';
    } else if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return 'Yesterday';
    } else {
      return DateFormat('MMMM d, y').format(date);
    }
  }

  Widget _buildNotificationCard(
      BuildContext context, NotificationModel notification) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final timeFormat = DateFormat('h:mm a');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withOpacity(0.5),
          width: 1,
        ),
      ),
      color: notification.isRead
          ? colorScheme.surface
          : colorScheme.primaryContainer.withOpacity(0.12),
      child: InkWell(
        onTap: () {
          // TODO: Handle notification tap
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: notification.getColor(context).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  notification.icon,
                  color: notification.getColor(context),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: notification.isRead
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          timeFormat.format(notification.timestamp),
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: textTheme.bodyMedium?.copyWith(
                        color: notification.isRead
                            ? colorScheme.onSurfaceVariant
                            : colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Action buttons based on notification type
                    if (notification.type == NotificationType.expiryAlert ||
                        notification.type == NotificationType.lowStock)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _buildActionButton(
                            context,
                            'View Details',
                            Icons.visibility_outlined,
                            notification.getColor(context),
                          ),
                          const SizedBox(width: 8),
                          _buildActionButton(
                            context,
                            notification.type == NotificationType.lowStock
                                ? 'Order'
                                : 'Manage',
                            notification.type == NotificationType.lowStock
                                ? Icons.shopping_cart_outlined
                                : Icons.settings_outlined,
                            notification.getColor(context),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
      BuildContext context, String label, IconData icon, Color color) {
    return OutlinedButton.icon(
      onPressed: () {
        // TODO: Handle action
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label action coming soon')),
        );
      },
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(0, 32),
        textStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
