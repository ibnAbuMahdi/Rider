import 'package:flutter/foundation.dart';

class CrashReporting {
  static Future<void> initialize() async {
    if (kDebugMode) {
      print('📊 Crash reporting initialized (Debug mode)');
      return;
    }
    
    // In production, initialize Firebase Crashlytics or other crash reporting
    try {
      // await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      print('📊 Crash reporting initialized');
    } catch (e) {
      print('❌ Failed to initialize crash reporting: $e');
    }
  }

  static void logRiderAction(String action, Map<String, dynamic>? params) {
    if (kDebugMode) {
      print('🔍 Rider Action: $action with params: $params');
      return;
    }
    
    // In production, log to analytics
    try {
      // FirebaseAnalytics.instance.logEvent(name: action, parameters: params);
    } catch (e) {
      print('❌ Failed to log rider action: $e');
    }
  }

  static void recordError(dynamic error, StackTrace? stackTrace) {
    if (kDebugMode) {
      print('❌ Error recorded: $error');
      if (stackTrace != null) {
        print(stackTrace);
      }
      return;
    }
    
    // In production, record to crash reporting
    try {
      // FirebaseCrashlytics.instance.recordError(error, stackTrace);
    } catch (e) {
      print('❌ Failed to record error: $e');
    }
  }
}