import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:secure_application/secure_application.dart';  // Replaced with AppSecurity
import '../utils/app_security.dart';

import 'core/constants/app_constants.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/location_provider.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/connectivity_wrapper.dart';
import 'core/services/random_verification_background_service.dart';
import 'core/services/location_service.dart';

class StikaRiderApp extends ConsumerStatefulWidget {
  const StikaRiderApp({super.key});

  @override
  ConsumerState<StikaRiderApp> createState() => _StikaRiderAppState();
}

class _StikaRiderAppState extends ConsumerState<StikaRiderApp> with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Notify location service about lifecycle changes
    LocationService.instance.handleAppLifecycleChange(state);
    
    switch (state) {
      case AppLifecycleState.detached:
        // App is being completely closed - cleanup background services
        _cleanupServices();
        break;
      case AppLifecycleState.paused:
        // App went to background - location tracking should continue
        if (kDebugMode) {
          print('🏠 APP: Going to background, location tracking should continue');
        }
        break;
      case AppLifecycleState.resumed:
        // App came back to foreground - resume normal operation
        if (kDebugMode) {
          print('🏠 APP: Returned to foreground, verifying services');
        }
        
        // Force refresh tracking stats when returning to foreground
        if (mounted) {
          try {
            final container = ProviderScope.containerOf(context, listen: false);
            if (container.exists(trackingStatsProvider)) {
              container.read(trackingStatsProvider.notifier).forceRefresh();
            }
          } catch (e) {
            if (kDebugMode) {
              print('🚨 Error refreshing tracking stats on resume: $e');
            }
          }
        }
        break;
      default:
        break;
    }
  }
  
  void _cleanupServices() {
    // This will be called when app is being completely closed
    if (mounted) {
      if (kDebugMode) {
        print('🧹 APP CLEANUP: Starting app cleanup process');
      }
      
      try {
        // Cleanup location service first (as it's a singleton)
        LocationService.instance.dispose().timeout(const Duration(seconds: 2)).catchError((e) {
          if (kDebugMode) {
            print('🚨 Location service cleanup timeout/error: $e');
          }
        });
        
        // Explicitly stop random verification service before app termination
        final container = ProviderScope.containerOf(context, listen: false);
        
        // Check if the provider exists and stop the service
        if (container.exists(randomVerificationBackgroundServiceProvider)) {
          final service = container.read(randomVerificationBackgroundServiceProvider);
          service.stop();
        }
        
        if (kDebugMode) {
          print('🧹 APP CLEANUP: Services stopped, scheduling provider invalidation');
        }
        
        // Give a small delay for cleanup, then invalidate providers
        Future.delayed(const Duration(milliseconds: 200), () {
          try {
            // Force invalidate all providers to ensure cleanup
            container.invalidate(randomVerificationBackgroundServiceProvider);
            if (kDebugMode) {
              print('🧹 APP CLEANUP: Provider invalidation completed');
            }
          } catch (e) {
            if (kDebugMode) {
              print('🚨 Provider invalidation error (non-fatal): $e');
            }
          }
        });
      } catch (e) {
        if (kDebugMode) {
          print('🚨 Cleanup error (non-fatal): $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final authState = ref.watch(authProvider);
    
    return PopScope(
      canPop: false, // Prevent default back button behavior
      onPopInvoked: (didPop) async {
        if (!didPop) {
          // Handle back button press gracefully
          if (kDebugMode) {
            print('🔙 APP: Back button pressed, initiating graceful shutdown');
          }
          
          _cleanupServices();
          
          // Wait a bit for cleanup then exit
          await Future.delayed(const Duration(milliseconds: 300));
          
          if (kDebugMode) {
            print('🔙 APP: Cleanup completed, exiting app');
          }
          
          SystemNavigator.pop();
        }
      },
      child: MaterialApp.router(
        title: AppConstants.appName,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.4)),
            ),
            child: ConnectivityWrapper(
              child: AppSecurity.secureApp(
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          );
        },
      ),
    );
  }
}