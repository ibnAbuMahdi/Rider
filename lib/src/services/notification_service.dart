import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';
import '../core/services/api_service.dart';
import '../services/sms_service.dart';
import '../core/routing/app_router.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  static Timer? _pollingTimer;
  static const Duration pollingInterval = Duration(seconds: 30);
  static final logger = Logger();

  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  static void startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(
      pollingInterval,
      (_) => _checkForUpdates(),
    );
  }

  static void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  static Future<void> _checkForUpdates() async {
    try {
      // Check for verification requests
      final verificationCheck = await ApiService.checkVerificationRequest();
      if (verificationCheck['hasRequest'] == true) {
        await _showVerificationAlert();
      }
      
      // Check for payment updates
      final paymentCheck = await ApiService.checkPaymentStatus();
      if (paymentCheck['hasUpdate'] == true) {
        await _showPaymentUpdate(paymentCheck['amount']);
      }
      
      // Check for campaign updates
      final campaignCheck = await ApiService.checkCampaignStatus();
      if (campaignCheck['hasUpdate'] == true) {
        await _showCampaignUpdate(campaignCheck['campaign']);
      }
      
    } catch (e) {
      logger.w('Polling check failed: $e');
    }
  }

  static Future<void> _showVerificationAlert() async {
    const androidDetails = AndroidNotificationDetails(
      'verification',
      'Verification Alerts',
      channelDescription: 'Urgent verification requests',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('verification_sound'),
      largeIcon: DrawableResourceAndroidBitmap('stika_logo'),
    );
    
    const notificationDetails = NotificationDetails(android: androidDetails);
    
    await _notifications.show(
      0,
      'Verification Required NOW! ⚠️',
      'Snap your keke back! You get 5 minutes.',
      notificationDetails,
      payload: 'verification',
    );

    // Navigate to verification if app is open
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      AppRouter.navigatorKey.currentState?.pushNamed('/verification');
    }
  }

  static Future<void> _showPaymentUpdate(double amount) async {
    const androidDetails = AndroidNotificationDetails(
      'payments',
      'Payment Notifications',
      channelDescription: 'Payment confirmations',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('payment_sound'),
      largeIcon: DrawableResourceAndroidBitmap('money_icon'),
    );
    
    const notificationDetails = NotificationDetails(android: androidDetails);
    
    await _notifications.show(
      1,
      'Payment Received! 💰',
      '₦${amount.toStringAsFixed(0)} sent to your account',
      notificationDetails,
      payload: 'payment:$amount',
    );
  }

  static Future<void> _showCampaignUpdate(Map<String, dynamic> campaign) async {
    const androidDetails = AndroidNotificationDetails(
      'campaigns',
      'Campaign Updates',
      channelDescription: 'New campaign notifications',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      largeIcon: DrawableResourceAndroidBitmap('campaign_icon'),
    );
    
    const notificationDetails = NotificationDetails(android: androidDetails);
    
    await _notifications.show(
      2,
      'New Campaign Available! 🎯',
      'Check out ${campaign['name']} - earn more money!',
      notificationDetails,
      payload: 'campaign:${campaign['id']}',
    );
  }

  static Future<void> showOfflineNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'offline',
      'Offline Notifications',
      channelDescription: 'Offline mode notifications',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
    );
    
    const notificationDetails = NotificationDetails(android: androidDetails);
    
    await _notifications.show(
      99,
      'Offline Mode',
      'Your data will sync when connection returns',
      notificationDetails,
      payload: 'offline',
    );
  }

  static Future<void> dismissOfflineNotification() async {
    await _notifications.cancel(99);
  }

  static Future<void> showDailyReward(int streak, int bonus) async {
    const androidDetails = AndroidNotificationDetails(
      'rewards',
      'Daily Rewards',
      channelDescription: 'Daily login rewards',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      largeIcon: DrawableResourceAndroidBitmap('reward_icon'),
    );
    
    const notificationDetails = NotificationDetails(android: androidDetails);
    
    await _notifications.show(
      3,
      'Daily Reward! 🎉',
      'Day $streak streak - You earned ₦$bonus bonus!',
      notificationDetails,
      payload: 'reward:$bonus',
    );
  }

  static void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    
    if (payload?.startsWith('verification') == true) {
      AppRouter.navigatorKey.currentState?.pushNamed('/verification');
    } else if (payload?.startsWith('payment') == true) {
      AppRouter.navigatorKey.currentState?.pushNamed('/earnings');
    } else if (payload?.startsWith('campaign') == true) {
      AppRouter.navigatorKey.currentState?.pushNamed('/campaigns');
    } else if (payload?.startsWith('reward') == true) {
      AppRouter.navigatorKey.currentState?.pushNamed('/earnings');
    }
  }
}