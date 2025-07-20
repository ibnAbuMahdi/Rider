import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'src/app.dart';
import 'src/core/storage/hive_service.dart';
import 'src/core/security/app_security.dart';
import 'src/core/services/crash_reporting.dart';
import 'src/core/services/notification_service.dart';
import 'src/core/services/location_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set up comprehensive error handling
  _setupErrorHandling();
  
  // Initialize core services
  await _initializeApp();
  
  runApp(
    ProviderScope(
      child: StikaRiderApp(),
    ),
  );
}

Future<void> _initializeApp() async {
  try {
    // Initialize Hive for offline storage
    await Hive.initFlutter();
    await HiveService.initialize();
    
    // Initialize security features
    await AppSecurity.initialize();
    
    // Initialize crash reporting
    await CrashReporting.initialize();
    
    // Initialize notification service
    await NotificationService.initialize();
    
    // Initialize location service
    await LocationService.initialize();
    
    // Set system UI style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    
    // Lock orientation to portrait
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    
  } catch (e) {
    debugPrint('Error initializing app: $e');
    // Continue with app launch even if some services fail
  }
}

// Set up comprehensive error handling for the app
void _setupErrorHandling() {
  // Catch Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    if (kDebugMode) {
      print('🚨 FLUTTER ERROR:');
      print('🚨 Error: ${details.exception}');
      print('🚨 Stack: ${details.stack}');
      print('🚨 Library: ${details.library}');
      print('🚨 Context: ${details.context}');
      print('🚨 Timestamp: ${DateTime.now().toIso8601String()}');
    }
    
    // In production, send to crash reporting service
    // CrashReporting.recordError(details.exception, details.stack);
    
    FlutterError.presentError(details);
  };
  
  // Catch errors not handled by Flutter
  PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) {
      print('🚨 PLATFORM ERROR:');
      print('🚨 Error: $error');
      print('🚨 Stack: $stack');
      print('🚨 Error Type: ${error.runtimeType}');
      print('🚨 Timestamp: ${DateTime.now().toIso8601String()}');
    }
    
    // In production, send to crash reporting service
    // CrashReporting.recordError(error, stack);
    
    return true;
  };
}