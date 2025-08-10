import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'verification_sound_service.dart';

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
      
      // Initialize verification sound service
      await VerificationSoundService.initialize();
      
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
    bool isUrgent = false,
  }) async {
    if (!_isInitialized) return;

    try {
      // Play appropriate sound alert based on urgency
      if (isUrgent) {
        await VerificationSoundService.playUrgentAlert();
        await VerificationSoundService.triggerVibration(isUrgent: true);
      } else {
        await VerificationSoundService.playVerificationAlert();
        await VerificationSoundService.triggerVibration(isUrgent: false);
      }

      const androidDetails = AndroidNotificationDetails(
        'verification_channel',
        'Verification Requests',
        channelDescription: 'Important verification requests',
        importance: Importance.max,
        priority: Priority.max,
        showWhen: true,
        color: Color(0xFF22C55E),
        colorized: true,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        enableLights: true,
        ledColor: Color(0xFF22C55E),
        ledOnMs: 1000,
        ledOffMs: 500,
        playSound: true,
        ongoing: true, // Make it persistent until tapped
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.critical,
        categoryIdentifier: 'verification_category',
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        1001, // Verification notification ID
        isUrgent ? 'URGENT: Verification Required!' : 'Verification Required!',
        'Take photo for $campaignName campaign. ${timeoutMinutes > 1 ? '$timeoutMinutes minutes' : '⚠️ $timeoutMinutes minute'} remaining.',
        details,
        payload: 'verification_required',
      );

      if (kDebugMode) {
        print('📱 ${isUrgent ? 'Urgent' : 'Regular'} verification notification shown with sound');
      }
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

  /// Show timeout warning for verification (when time is running out)
  static Future<void> showVerificationTimeoutWarning({
    required String campaignName,
    required int timeoutMinutes,
  }) async {
    if (!_isInitialized) return;

    try {
      // Play timeout warning sound
      await VerificationSoundService.playTimeoutWarning();
      await VerificationSoundService.triggerVibration(isUrgent: true);

      const androidDetails = AndroidNotificationDetails(
        'verification_timeout_channel',
        'Verification Timeout Warnings',
        channelDescription: 'Urgent warnings for verification timeout',
        importance: Importance.max,
        priority: Priority.max,
        showWhen: true,
        color: Color(0xFFF97316), // Orange color
        colorized: true,
        category: AndroidNotificationCategory.alarm,
        playSound: true,
        enableLights: true,
        ledColor: Color(0xFFF97316),
        ledOnMs: 500,
        ledOffMs: 300,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        1004, // Timeout warning notification ID
        '⏰ Verification Timeout Warning',
        'Only $timeoutMinutes minute${timeoutMinutes == 1 ? '' : 's'} left for $campaignName verification!',
        details,
        payload: 'verification_timeout_warning',
      );

      if (kDebugMode) {
        print('📱 Verification timeout warning shown with sound');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to show verification timeout warning: $e');
      }
    }
  }

  /// Show verification success notification
  static Future<void> showVerificationSuccess({
    required String campaignName,
  }) async {
    if (!_isInitialized) return;

    try {
      // Play success sound
      await VerificationSoundService.playSuccessSound();

      const androidDetails = AndroidNotificationDetails(
        'verification_success_channel',
        'Verification Success',
        channelDescription: 'Verification success confirmations',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        color: Color(0xFF22C55E), // Green color
        colorized: true,
        playSound: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        1005, // Success notification ID
        '✅ Verification Completed',
        'Your verification for $campaignName campaign was successful!',
        details,
        payload: 'verification_success',
      );

      if (kDebugMode) {
        print('📱 Verification success notification shown');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to show verification success notification: $e');
      }
    }
  }

  /// Show verification failed notification
  static Future<void> showVerificationFailed({
    required String campaignName,
    required String reason,
  }) async {
    if (!_isInitialized) return;

    try {
      // Play failed sound
      await VerificationSoundService.playFailedSound();

      const androidDetails = AndroidNotificationDetails(
        'verification_failed_channel',
        'Verification Failed',
        channelDescription: 'Verification failure notifications',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        color: Color(0xFFDC2626), // Red color
        colorized: true,
        playSound: true,
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
        1006, // Failed notification ID
        '❌ Verification Failed',
        'Your verification for $campaignName campaign failed: $reason',
        details,
        payload: 'verification_failed',
      );

      if (kDebugMode) {
        print('📱 Verification failed notification shown');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to show verification failed notification: $e');
      }
    }
  }

  /// Show repeating urgent verification alert (for critical cases)
  static Future<void> showRepeatingVerificationAlert({
    required String campaignName,
    required int timeoutMinutes,
    int repeatCount = 3,
  }) async {
    if (!_isInitialized) return;

    try {
      // Play repeating sound alert
      await VerificationSoundService.playRepeatingAlert(repeatCount: repeatCount);

      // Show high-priority notification
      await showVerificationRequired(
        campaignName: campaignName,
        timeoutMinutes: timeoutMinutes,
        isUrgent: true,
      );

      if (kDebugMode) {
        print('📱 Repeating verification alert shown (repeat: $repeatCount times)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to show repeating verification alert: $e');
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