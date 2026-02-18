import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../core/utils/app_theme.dart';
import '../../providers/notification_provider.dart';
import '../../core/widgets/empty_state_widget.dart';

class NotificationListScreen extends StatelessWidget {
  const NotificationListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded),
            onPressed: () {
              context.read<NotificationProvider>().markAllAsRead();
            },
            tooltip: 'Mark all as read',
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, notificationProvider, child) {
          if (notificationProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            );
          }

          final notifications = notificationProvider.notifications;

          if (notifications.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.notifications_off_rounded,
              title: 'No Notifications',
              message: 'You\'re all caught up! We\'ll notify you when something important happens.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              if (notificationProvider.currentUserId != null) {
                await notificationProvider.initialize(notificationProvider.currentUserId!);
              }
            },
            color: AppTheme.primaryColor,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                indent: 80,
                color: Colors.grey.shade100,
              ),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _buildNotificationItem(context, notification, notificationProvider);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context, 
    AppNotification notification,
    NotificationProvider provider,
  ) {
    final isRead = notification.isRead;
    
    return InkWell(
      onTap: () {
        if (!isRead) {
          provider.markAsRead(notification.id);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isRead ? Colors.transparent : AppTheme.primaryColor.withValues(alpha: 0.03),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getNotificationColor(notification.type).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getNotificationIcon(notification.type),
                color: _getNotificationColor(notification.type),
                size: 24,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Content
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
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: TextStyle(
                      fontSize: 14,
                      color: isRead ? Colors.grey.shade600 : Colors.black54,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    timeago.format(notification.timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'transaction':
        return Icons.account_balance_wallet_rounded;
      case 'chat':
        return Icons.chat_bubble_rounded;
      case 'system':
        return Icons.info_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getNotificationColor(String? type) {
    switch (type) {
      case 'transaction':
        return Colors.green;
      case 'chat':
        return Colors.blue;
      case 'system':
        return Colors.orange;
      default:
        return AppTheme.primaryColor;
    }
  }
}
