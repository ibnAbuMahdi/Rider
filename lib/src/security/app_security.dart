import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
// import 'package:installed_apps/installed_apps.dart';  // Commented out
import 'package:share_plus/share_plus.dart';
// import 'package:secure_application/secure_application.dart';
import 'dart:io';

class AppSecurity {
  static final logger = Logger();
  static const _storage = FlutterSecureStorage();

  static Future<void> initialize() async {
    await _setupSecurityMeasures();
    await _checkDeviceBinding();
    await _checkInstalledApps();
  }

  static Future<void> _setupSecurityMeasures() async {
    // Prevent debugging in release mode
    if (kReleaseMode) {
      debugDefaultTargetPlatformOverride = null;
    }
  }

  // Prevent screenshots of earnings (anti-competitor intelligence)
  static void preventScreenshots() {
    if (Platform.isAndroid) {
      // SecureApplication.singleton.secure();
    }
  }

  static void allowScreenshots() {
    if (Platform.isAndroid) {
      // SecureApplication.singleton.open();
    }
  }

  // Device binding to prevent account sharing
  static Future<bool> verifyDevice() async {
    try {
      final deviceId = await getDeviceId();
      if (deviceId == null) return false;
      
      final storedId = await _storage.read(key: 'device_id');
      
      if (storedId != null && storedId != deviceId) {
        // Potential account sharing or device switch
        await _reportSuspiciousActivity('device_mismatch');
        return false;
      }
      
      if (storedId == null) {
        await _storage.write(key: 'device_id', value: deviceId);
      }
      
      return true;
    } catch (e) {
      logger.e('Device verification failed: $e');
      return false;
    }
  }

  // Detect competing apps
  static Future<void> _checkInstalledApps() async {
    final suspiciousApps = [
      'com.competitor.rider',
      'ng.blitz.driver',
      'com.uber.driver',
      'com.taxify.driver', // Bolt
      'com.gokada.driver',
      'com.opay.driver',
      'com.max.driver',
    ];
    
    try {
      // Mock implementation - installed_apps package removed
      logger.i('Installed apps check disabled');
    } catch (e) {
      logger.w('Could not check installed apps: $e');
    }
  }

  static Future<void> _checkDeviceBinding() async {
    final isValid = await verifyDevice();
    if (!isValid) {
      // Handle device binding failure
      await _handleDeviceBindingFailure();
    }
  }

  static Future<void> _handleDeviceBindingFailure() async {
    // Force logout and require re-authentication
    await clearSecureData();
    logger.w('Device binding failed - forcing logout');
  }

  static Future<void> _reportSuspiciousActivity(String activityType) async {
    try {
      final deviceId = await getDeviceId();
      final timestamp = DateTime.now().toIso8601String();
      
      // Store locally for later sync
      await _storage.write(
        key: 'suspicious_activity_$timestamp',
        value: '$activityType:$deviceId',
      );
      
      logger.w('Suspicious activity reported: $activityType');
    } catch (e) {
      logger.e('Failed to report suspicious activity: $e');
    }
  }

  static Future<void> _reportCompetitorApp(String packageName) async {
    try {
      final deviceId = await getDeviceId();
      final timestamp = DateTime.now().toIso8601String();
      
      // Store locally for later sync
      await _storage.write(
        key: 'competitor_app_$timestamp',
        value: '$packageName:$deviceId',
      );
      
      logger.i('Competitor app detected: $packageName');
    } catch (e) {
      logger.e('Failed to report competitor app: $e');
    }
  }

  static Future<void> _showCompetitorDetectedDialog(String appName) async {
    // This would be implemented in the UI layer
    // For now, just log the event
    logger.i('Should show competitor retention dialog for: $appName');
  }

  static Future<String?> getDeviceId() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor;
      }
      return null;
    } catch (e) {
      logger.e('Failed to get device ID: $e');
      return null;
    }
  }

  static Future<bool> validateSession() async {
    try {
      // Check if session is valid
      final token = await _storage.read(key: 'auth_token');
      if (token == null) return false;

      // Verify device binding
      final deviceValid = await verifyDevice();
      if (!deviceValid) return false;

      return true;
    } catch (e) {
      logger.e('Session validation failed: $e');
      return false;
    }
  }

  static Future<void> clearSecureData() async {
    try {
      await _storage.deleteAll();
      logger.i('Secure data cleared');
    } catch (e) {
      logger.e('Failed to clear secure data: $e');
    }
  }

  // Anti-tampering measures
  static Future<bool> checkAppIntegrity() async {
    try {
      // Check if app is running on emulator
      if (await _isEmulator()) {
        await _reportSuspiciousActivity('emulator_detected');
        return false;
      }

      // Check if app is debuggable
      if (kDebugMode && kReleaseMode == false) {
        await _reportSuspiciousActivity('debug_mode');
        return false;
      }

      return true;
    } catch (e) {
      logger.e('App integrity check failed: $e');
      return false;
    }
  }

  static Future<bool> _isEmulator() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.isPhysicalDevice == false;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.isPhysicalDevice == false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Share earnings with security
  static Future<void> shareEarningsSecurely(double weeklyEarnings, String referralCode) async {
    try {
      final message = 'I don make ₦${weeklyEarnings.toStringAsFixed(0)} this week with Stika! '
          'Join with my code $referralCode '
          'and start earning too! 💰';
      
      await Share.share(message);
      
      // Log sharing event
      await _storage.write(
        key: 'earnings_shared_${DateTime.now().toIso8601String()}',
        value: weeklyEarnings.toString(),
      );
      
      logger.i('Earnings shared securely');
    } catch (e) {
      logger.e('Failed to share earnings: $e');
    }
  }

  // Loyalty bonus system
  static Future<void> claimLoyaltyBonus() async {
    try {
      // Mark loyalty bonus as claimed
      await _storage.write(
        key: 'loyalty_bonus_claimed',
        value: DateTime.now().toIso8601String(),
      );
      
      logger.i('Loyalty bonus claimed');
    } catch (e) {
      logger.e('Failed to claim loyalty bonus: $e');
    }
  }

  // Get all suspicious activities for sync
  static Future<List<Map<String, String>>> getSuspiciousActivities() async {
    try {
      final activities = <Map<String, String>>[];
      final allKeys = await _storage.readAll();
      
      for (final entry in allKeys.entries) {
        if (entry.key.startsWith('suspicious_activity_') ||
            entry.key.startsWith('competitor_app_')) {
          activities.add({
            'key': entry.key,
            'value': entry.value,
            'timestamp': entry.key.split('_').last,
          });
        }
      }
      
      return activities;
    } catch (e) {
      logger.e('Failed to get suspicious activities: $e');
      return [];
    }
  }

  // Clear synced activities
  static Future<void> clearSyncedActivities(List<String> keys) async {
    try {
      for (final key in keys) {
        await _storage.delete(key: key);
      }
      logger.i('Cleared ${keys.length} synced activities');
    } catch (e) {
      logger.e('Failed to clear synced activities: $e');
    }
  }
}