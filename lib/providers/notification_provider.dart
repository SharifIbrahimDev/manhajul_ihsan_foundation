import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/app_models.dart';

class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String? type; // e.g., 'transaction', 'chat', 'system'

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'type': type,
    };
  }

  factory AppNotification.fromMap(String id, Map<String, dynamic> map) {
    return AppNotification(
      id: id,
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
      type: map['type'],
    );
  }
}

class NotificationProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  int _unreadCount = 0;
  String? _currentUserId;

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _unreadCount;
  String? get currentUserId => _currentUserId;

  Future<void> initialize(String userId) async {
    _currentUserId = userId;
    _isLoading = true;
    notifyListeners();

    try {
      // Load from Firestore
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      _notifications = snapshot.docs
          .map((doc) => AppNotification.fromMap(doc.id, doc.data()))
          .toList();

      _unreadCount = _notifications.where((n) => !n.isRead).length;

      // Request permission for notifications
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Get FCM token (may not work on web during development)
      try {
        final token = await messaging.getToken();
        debugPrint('FCM Token: $token');
      } catch (e) {
        debugPrint('FCM Token retrieval failed (expected on web): $e');
      }

      // Listen to foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _handleMessage(message);
      });

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  void _handleMessage(RemoteMessage message) {
    final notification = AppNotification(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: message.notification?.title ?? 'New Notification',
      message: message.notification?.body ?? '',
      timestamp: DateTime.now(),
      isRead: false,
      type: message.data['type'],
    );

    // Add to local list
    _notifications.insert(0, notification);
    _unreadCount++;
    notifyListeners();
    
    // Note: We don't save to Firestore here because the notification 
    // should ideally be saved by the sender or a Cloud Function 
    // to ensure all participants get it.
  }

  // Send a notification to specific user (saves to Firestore)
  Future<void> sendNotification({
    required String recipientId,
    required String title,
    required String message,
    String? type,
  }) async {
    try {
      final docRef = _firestore
          .collection('users')
          .doc(recipientId)
          .collection('notifications')
          .doc();

      final notification = AppNotification(
        id: docRef.id,
        title: title,
        message: message,
        timestamp: DateTime.now(),
        isRead: false,
        type: type,
      );

      await docRef.set(notification.toMap());
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }

  // Send broadcast notification to a topic
  Future<void> sendTopicNotification({
    required String topic,
    required String title,
    required String message,
    String? type,
  }) async {
    // In a real app, this would be an HTTP call to FCM or a Cloud Function.
    // For now, we'll simulate by adding to current users if they match the topic
    // or just documenting the intent.
    debugPrint('Topic notification intended for $topic: $title');
  }

  Future<void> markAsRead(String notificationId) async {
    if (_currentUserId == null) return;

    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1 && !_notifications[index].isRead) {
      try {
        await _firestore
            .collection('users')
            .doc(_currentUserId)
            .collection('notifications')
            .doc(notificationId)
            .update({'isRead': true});

        _notifications[index] = AppNotification(
          id: _notifications[index].id,
          title: _notifications[index].title,
          message: _notifications[index].message,
          timestamp: _notifications[index].timestamp,
          isRead: true,
          type: _notifications[index].type,
        );
        _unreadCount = (_unreadCount - 1).clamp(0, _notifications.length);
        notifyListeners();
      } catch (e) {
        debugPrint('Error marking notification as read: $e');
      }
    }
  }

  Future<void> markAllAsRead() async {
    if (_currentUserId == null) return;

    try {
      final batch = _firestore.batch();
      final unreadNotifications = _notifications.where((n) => !n.isRead).toList();

      for (var n in unreadNotifications) {
        final docRef = _firestore
            .collection('users')
            .doc(_currentUserId)
            .collection('notifications')
            .doc(n.id);
        batch.update(docRef, {'isRead': true});
      }

      await batch.commit();

      for (int i = 0; i < _notifications.length; i++) {
        if (!_notifications[i].isRead) {
          _notifications[i] = AppNotification(
            id: _notifications[i].id,
            title: _notifications[i].title,
            message: _notifications[i].message,
            timestamp: _notifications[i].timestamp,
            isRead: true,
            type: _notifications[i].type,
          );
        }
      }
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  Future<void> subscribeToRoleTopics(UserRole role) async {
    if (kIsWeb) {
      debugPrint('Topic subscription is not supported on web.');
      return;
    }
    try {
      final messaging = FirebaseMessaging.instance;
      
      // Subscribe to role-specific topic
      await messaging.subscribeToTopic(role.value.toLowerCase());
      
      // Subscribe to all users topic
      await messaging.subscribeToTopic('all_users');
      
      debugPrint('Subscribed to topics: ${role.value.toLowerCase()}, all_users');
    } catch (e) {
      debugPrint('Error subscribing to topics: $e');
    }
  }
}
