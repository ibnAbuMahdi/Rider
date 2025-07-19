import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize local notifications
      const androidSettings = AndroidInitializationSettings('@drawable/ic_notification');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Request permissions
      await _requestPermissions();
      
      _isInitialized = true;
      
      if (kDebugMode) {
        print('📱 Notification service initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to initialize notifications: $e');
      }
    }
  }

  static Future<void> _requestPermissions() async {
    try {
      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to request notification permissions: $e');
      }
    }
  }

  static void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) {
      print('📱 Notification tapped: ${response.payload}');
    }
    
    // Handle notification tap
    final payload = response.payload;
    if (payload != null) {
      // Navigate based on payload
      // This would typically use a navigation service
    }
  }

  static Future<void> showVerificationRequired({
    required String campaignName,
    required int timeoutMinutes,
  }) async {
    if (!_isInitialized) return;

    try {
      const androidDetails = AndroidNotificationDetails(
        'verification_channel',
        'Verification Requests',
        channelDescription: 'Important verification requests',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        color: Color(0xFF22C55E),
        colorized: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        1001, // Verification notification ID
        'Verification Required!',
        'Take photo for $campaignName campaign. $timeoutMinutes minutes remaining.',
        details,
        payload: 'verification_required',
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to show verification notification: $e');
      }
    }
  }

  static Future<void> showPaymentReceived({
    required double amount,
    required String campaignName,
  }) async {
    if (!_isInitialized) return;

    try {
      const androidDetails = AndroidNotificationDetails(
        'payment_channel',
        'Payment Notifications',
        channelDescription: 'Payment confirmations',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        color: Color(0xFF059669),
        colorized: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        1002, // Payment notification ID
        'Payment Received! 💰',
        'You received ₦${amount.toStringAsFixed(0)} from $campaignName',
        details,
        payload: 'payment_received',
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to show payment notification: $e');
      }
    }
  }

  static Future<void> showCampaignUpdate({
    required String title,
    required String message,
  }) async {
    if (!_isInitialized) return;

    try {
      const androidDetails = AndroidNotificationDetails(
        'campaign_channel',
        'Campaign Updates',
        channelDescription: 'Campaign status updates',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        showWhen: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        1003, // Campaign notification ID
        title,
        message,
        details,
        payload: 'campaign_update',
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to show campaign notification: $e');
      }
    }
  }

  static Future<void> cancelVerificationNotification() async {
    try {
      await _notifications.cancel(1001);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to cancel verification notification: $e');
      }
    }
  }

  static Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to cancel all notifications: $e');
      }
    }
  }
}