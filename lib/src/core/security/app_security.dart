import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
// import 'package:secure_application/secure_application.dart';  // Commented out
import '../storage/hive_service.dart';

class AppSecurity {
  static const String _deviceIdKey = 'device_id';
  static String? _cachedDeviceId;

  static Future<void> initialize() async {
    try {
      // Prevent screenshots in production
      if (!kDebugMode) {
        await _preventScreenshots();
      }
      
      // Verify device consistency
      await _verifyDevice();
      
      if (kDebugMode) {
        print('🔒 App security initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to initialize app security: $e');
      }
    }
  }

  static Future<void> _preventScreenshots() async {
    try {
      // Note: secure_application uses a widget-based approach
      // For now, we'll use a simpler approach with a flag
      // The actual implementation should be done at the widget level
      if (kDebugMode) {
        print('🔒 Screenshot prevention configured (widget-level implementation required)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to prevent screenshots: $e');
      }
    }
  }

  static Future<String> getDeviceId() async {
    if (_cachedDeviceId != null) {
      return _cachedDeviceId!;
    }

    try {
      final deviceInfo = DeviceInfoPlugin();
      String deviceId;

      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? '';
      } else {
        deviceId = 'unknown_device';
      }

      _cachedDeviceId = deviceId;
      return deviceId;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get device ID: $e');
      }
      return 'error_device_id';
    }
  }

  static Future<bool> _verifyDevice() async {
    try {
      final currentDeviceId = await getDeviceId();
      final storedDeviceId = HiveService.getSetting<String>(_deviceIdKey);

      if (storedDeviceId == null) {
        // First time setup
        await HiveService.saveSetting(_deviceIdKey, currentDeviceId);
        return true;
      }

      if (storedDeviceId != currentDeviceId) {
        // Device mismatch - potential account sharing
        await _reportSuspiciousActivity('device_mismatch', {
          'stored_device_id': storedDeviceId,
          'current_device_id': currentDeviceId,
        });
        return false;
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Device verification failed: $e');
      }
      return false;
    }
  }

  static Future<void> _reportSuspiciousActivity(
    String activityType,
    Map<String, dynamic> details,
  ) async {
    try {
      // Store suspicious activity locally
      final activities = HiveService.getSetting<List<dynamic>>('suspicious_activities') ?? [];
      activities.add({
        'type': activityType,
        'details': details,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      // Keep only last 50 activities
      if (activities.length > 50) {
        activities.removeRange(0, activities.length - 50);
      }
      
      await HiveService.saveSetting('suspicious_activities', activities);
      
      if (kDebugMode) {
        print('🚨 Suspicious activity reported: $activityType');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to report suspicious activity: $e');
      }
    }
  }

  static Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await deviceInfo.androidInfo;
        return {
          'platform': 'Android',
          'model': androidInfo.model,
          'manufacturer': androidInfo.manufacturer,
          'version': androidInfo.version.release,
          'sdk_int': androidInfo.version.sdkInt,
          'brand': androidInfo.brand,
          'device': androidInfo.device,
        };
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return {
          'platform': 'iOS',
          'model': iosInfo.model,
          'name': iosInfo.name,
          'system_name': iosInfo.systemName,
          'system_version': iosInfo.systemVersion,
        };
      }
      
      return {'platform': 'Unknown'};
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get device info: $e');
      }
      return {'platform': 'Error'};
    }
  }

  static Future<bool> checkAppIntegrity() async {
    try {
      // Check if running on emulator
      final deviceInfo = await getDeviceInfo();
      
      if (defaultTargetPlatform == TargetPlatform.android) {
        final isEmulator = deviceInfo['brand'] == 'google' && 
                          deviceInfo['device']?.toString().contains('generic') == true;
        
        if (isEmulator) {
          await _reportSuspiciousActivity('emulator_detected', deviceInfo);
          return false;
        }
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ App integrity check failed: $e');
      }
      return true; // Don't block on error
    }
  }

  static List<Map<String, dynamic>> getSuspiciousActivities() {
    try {
      final activities = HiveService.getSetting<List<dynamic>>('suspicious_activities') ?? [];
      return activities.cast<Map<String, dynamic>>();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get suspicious activities: $e');
      }
      return [];
    }
  }

  static Future<void> clearSuspiciousActivities() async {
    try {
      await HiveService.saveSetting('suspicious_activities', <Map<String, dynamic>>[]);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to clear suspicious activities: $e');
      }
    }
  }
}
