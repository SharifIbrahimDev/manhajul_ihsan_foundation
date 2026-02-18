import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/app_models.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  Function(Map<String, dynamic>)? _onMessageTap;
  Function(Map<String, dynamic>)? _onBackgroundMessage;

  String? get fcmToken => _fcmToken;

  // Initialize notification service
  Future<void> initialize({
    Function(Map<String, dynamic>)? onMessageTap,
    Function(Map<String, dynamic>)? onBackgroundMessage,
  }) async {
    _onMessageTap = onMessageTap;
    _onBackgroundMessage = onBackgroundMessage;

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Initialize Firebase messaging
    await _initializeFirebaseMessaging();

    // Request permissions
    await _requestPermissions();

    // Get FCM token
    await _getFCMToken();

    // Setup message handlers
    _setupMessageHandlers();

    debugPrint('✅ NotificationService initialized');
  }

  // Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationTap(response.payload);
      },
    );

    // Create notification channels for Android
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }
  }

  // Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    const List<AndroidNotificationChannel> channels = [
      AndroidNotificationChannel(
        'messages',
        'Messages',
        description: 'Notifications for new chat messages',
        importance: Importance.high,
        sound: RawResourceAndroidNotificationSound('message_tone'),
      ),
      AndroidNotificationChannel(
        'transactions',
        'Transactions',
        description: 'Notifications for financial transactions',
        importance: Importance.high,
        sound: RawResourceAndroidNotificationSound('transaction_tone'),
      ),
      AndroidNotificationChannel(
        'announcements',
        'Announcements',
        description: 'Foundation announcements and updates',
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound('announcement_tone'),
      ),
      AndroidNotificationChannel(
        'user_updates',
        'User Updates',
        description: 'User role changes and account updates',
        importance: Importance.defaultImportance,
      ),
    ];

    for (final channel in channels) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  // Initialize Firebase messaging
  Future<void> _initializeFirebaseMessaging() async {
    // Configure foreground notification presentation options for iOS
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  // Request notification permissions
  Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        criticalAlert: false,
        announcement: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ iOS notification permissions granted');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('⚠️ iOS provisional notification permissions granted');
      } else {
        debugPrint('❌ iOS notification permissions denied');
      }
    }

    // Request local notification permissions
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestPermission();
  }

  // Get FCM token
  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      debugPrint('📱 FCM Token: $_fcmToken');

      // Save token locally
      if (_fcmToken != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', _fcmToken!);
      }
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
    }
  }

  // Setup message handlers
  void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📨 Foreground message received: ${message.messageId}');
      _handleForegroundMessage(message);
    });

    // Handle background message taps
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🔔 Background message tapped: ${message.messageId}');
      _handleMessageTap(message.data);
    });

    // Handle token refresh
    _firebaseMessaging.onTokenRefresh.listen((String token) {
      _fcmToken = token;
      debugPrint('🔄 FCM Token refreshed: $token');
      // Update token on server
      _updateTokenOnServer(token);
    });
  }

  // Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;

    if (notification != null) {
      await showLocalNotification(
        title: notification.title ?? 'Manhajul Ihsan Foundation',
        body: notification.body ?? 'You have a new notification',
        payload: data,
        channelId: _getChannelId(data['type']),
      );
    }
  }

  // Handle notification tap
  void _handleNotificationTap(String? payload) {
    if (payload != null && _onMessageTap != null) {
      try {
        // Parse payload if it's JSON
        final data = <String, dynamic>{'payload': payload};
        _onMessageTap!(data);
      } catch (e) {
        debugPrint('❌ Error handling notification tap: $e');
      }
    }
  }

  // Handle message tap
  void _handleMessageTap(Map<String, dynamic> data) {
    if (_onMessageTap != null) {
      _onMessageTap!(data);
    }
  }

  // Show local notification
  Future<void> showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
    String? channelId,
    String? imageUrl,
    List<String>? actions,
  }) async {
    try {
      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        channelId ?? 'default',
        _getChannelName(channelId ?? 'default'),
        channelDescription: _getChannelDescription(channelId ?? 'default'),
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFFFFA726), // AppTheme.primaryColor
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: _getNotificationStyle(body, imageUrl),
        actions: actions?.asMap().entries.map((entry) {
          return AndroidNotificationAction(
            'action_${entry.key}',
            entry.value,
          );
        }).toList(),
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        threadIdentifier: 'manhajul_ihsan_foundation',
      );

      NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        id,
        title,
        body,
        platformDetails,
        payload: payload?.toString(),
      );
    } catch (e) {
      debugPrint('❌ Error showing local notification: $e');
    }
  }

  // Get notification style based on content
  DefaultStyleInformation? _getNotificationStyle(String body, String? imageUrl) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return BigPictureStyleInformation(
        FilePathAndroidBitmap(imageUrl),
        contentTitle: 'New Image',
        htmlFormatContentTitle: true,
        summaryText: body,
        htmlFormatSummaryText: true,
      );
    } else if (body.length > 50) {
      return BigTextStyleInformation(
        body,
        htmlFormatBigText: true,
        contentTitle: 'Manhajul Ihsan Foundation',
        htmlFormatContentTitle: true,
      );
    }
    return null;
  }

  // Send notification for new message
  Future<void> sendMessageNotification({
    required String recipientUserId,
    required String senderName,
    required String message,
    required String chatRoomId,
    required bool isGroupChat,
    String? groupName,
  }) async {
    final title = isGroupChat
        ? '$senderName in $groupName'
        : senderName;

    final body = message.length > 100
        ? '${message.substring(0, 100)}...'
        : message;

    final data = {
      'type': 'message',
      'chatRoomId': chatRoomId,
      'senderId': senderName,
      'isGroupChat': isGroupChat.toString(),
      'timestamp': DateTime.now().toIso8601String(),
    };

    await _sendNotificationToUser(
      userId: recipientUserId,
      title: title,
      body: body,
      data: data,
      channelId: 'messages',
    );
  }

  // Send notification for new transaction
  Future<void> sendTransactionNotification({
    required String recipientUserId,
    required String transactionType,
    required double amount,
    required String category,
    String? description,
  }) async {
    final title = transactionType == 'credit'
        ? 'New Contribution Received'
        : 'Expense Recorded';

    final body = transactionType == 'credit'
        ? 'You have received ₦${amount.toStringAsFixed(2)} for $category'
        : '₦${amount.toStringAsFixed(2)} has been spent on $category';

    final data = {
      'type': 'transaction',
      'transactionType': transactionType,
      'amount': amount.toString(),
      'category': category,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await _sendNotificationToUser(
      userId: recipientUserId,
      title: title,
      body: body,
      data: data,
      channelId: 'transactions',
    );
  }

  // Send notification for role update
  Future<void> sendRoleUpdateNotification({
    required String recipientUserId,
    required String newRole,
    required String updatedBy,
  }) async {
    final title = 'Role Updated';
    final body = '$updatedBy has updated your role to $newRole';

    final data = {
      'type': 'role_update',
      'newRole': newRole,
      'updatedBy': updatedBy,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await _sendNotificationToUser(
      userId: recipientUserId,
      title: title,
      body: body,
      data: data,
      channelId: 'user_updates',
    );
  }

  // Send announcement notification
  Future<void> sendAnnouncementNotification({
    required List<String> recipientUserIds,
    required String title,
    required String message,
    String? imageUrl,
  }) async {
    final data = {
      'type': 'announcement',
      'title': title,
      'message': message,
      'imageUrl': imageUrl ?? '',
      'timestamp': DateTime.now().toIso8601String(),
    };

    for (final userId in recipientUserIds) {
      await _sendNotificationToUser(
        userId: userId,
        title: title,
        body: message,
        data: data,
        channelId: 'announcements',
      );
    }
  }

  // Send notification to specific user
  Future<void> _sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    required Map<String, dynamic> data,
    String? channelId,
  }) async {
    // In production, you would call your backend API to send the notification
    // For now, we'll simulate it with a local notification
    await showLocalNotification(
      title: title,
      body: body,
      payload: data,
      channelId: channelId,
    );

    debugPrint('📤 Notification sent to user $userId: $title');
  }

  // Update token on server
  Future<void> _updateTokenOnServer(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);

      // In production, send token to your backend
      debugPrint('🔄 Token updated on server: $token');
    } catch (e) {
      debugPrint('❌ Error updating token on server: $e');
    }
  }

  // Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('✅ Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('❌ Error subscribing to topic $topic: $e');
    }
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('❌ Error unsubscribing from topic $topic: $e');
    }
  }

  // Subscribe to role-based topics
  Future<void> subscribeToRoleTopics(UserRole role) async {
    // Unsubscribe from all role topics first
    final allRoles = ['president', 'registrar', 'cashier', 'user'];
    for (final roleStr in allRoles) {
      await unsubscribeFromTopic('role_$roleStr');
    }

    // Subscribe to new role topic
    await subscribeToTopic('role_${role.value.toLowerCase()}');
    await subscribeToTopic('all_users'); // General announcements
  }

  // Get channel ID based on notification type
  String _getChannelId(String? type) {
    switch (type) {
      case 'message':
        return 'messages';
      case 'transaction':
        return 'transactions';
      case 'announcement':
        return 'announcements';
      case 'role_update':
        return 'user_updates';
      default:
        return 'default';
    }
  }

  // Get channel name
  String _getChannelName(String channelId) {
    switch (channelId) {
      case 'messages':
        return 'Messages';
      case 'transactions':
        return 'Transactions';
      case 'announcements':
        return 'Announcements';
      case 'user_updates':
        return 'User Updates';
      default:
        return 'General';
    }
  }

  // Get channel description
  String _getChannelDescription(String channelId) {
    switch (channelId) {
      case 'messages':
        return 'Notifications for new chat messages';
      case 'transactions':
        return 'Notifications for financial transactions';
      case 'announcements':
        return 'Foundation announcements and updates';
      case 'user_updates':
        return 'User role changes and account updates';
      default:
        return 'General app notifications';
    }
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  // Clear specific notification
  Future<void> clearNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  // Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _localNotifications.pendingNotificationRequests();
  }

  // Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final androidImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      return await androidImplementation?.areNotificationsEnabled() ?? false;
    } else if (Platform.isIOS) {
      final settings = await _firebaseMessaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    }
    return false;
  }

  // Show notification settings
  Future<void> showNotificationSettings() async {
    if (Platform.isAndroid) {
      final androidImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.requestPermission();
    }
  }
}

extension on AndroidFlutterLocalNotificationsPlugin? {
  Future<void> requestPermission() async {}
}