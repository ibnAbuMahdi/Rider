import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'random_verification_algorithm.dart';

class RandomVerificationBackgroundService {
  static const Duration _checkInterval = Duration(minutes: 15);
  
  Timer? _timer;
  final Ref _ref;
  bool _isRunning = false;
  DateTime? _nextCheckTime;
  
  RandomVerificationBackgroundService(this._ref);
  
  /// Start the background service
  void start() {
    if (_isRunning) return;
    
    _isRunning = true;
    
    if (kDebugMode) {
      print('🎯 RANDOM VERIFICATION SERVICE: Starting background service');
    }
    
    // Set initial next check time
    _nextCheckTime = DateTime.now().add(_checkInterval);
    
    // Check immediately on start
    _checkAndTriggerVerification();
    
    // Schedule periodic checks
    _timer = Timer.periodic(_checkInterval, (timer) {
      // Update next check time when timer fires
      _nextCheckTime = DateTime.now().add(_checkInterval);
      _checkAndTriggerVerification();
    });
  }
  
  /// Stop the background service
  void stop() {
    if (!_isRunning) return;
    
    try {
      _timer?.cancel();
      _timer = null;
      _isRunning = false;
      _nextCheckTime = null;
      
      if (kDebugMode) {
        print('🎯 RANDOM VERIFICATION SERVICE: Stopped background service');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🎯 RANDOM VERIFICATION SERVICE: Error during stop (non-fatal): $e');
      }
      // Force cleanup even if error occurs
      _timer = null;
      _isRunning = false;
      _nextCheckTime = null;
    }
  }
  
  /// Check for pending verifications and try to trigger new ones
  Future<void> _checkAndTriggerVerification() async {
    // Don't run if service is not running (safety check)
    if (!_isRunning) {
      if (kDebugMode) {
        print('🎯 RANDOM VERIFICATION SERVICE: Check skipped - service not running');
      }
      return;
    }
    
    try {
      if (kDebugMode) {
        print('🎯 RANDOM VERIFICATION SERVICE: Performing periodic check');
      }
      
      final algorithm = _ref.read(randomVerificationAlgorithmProvider);
      
      // First, check for any pending verifications from server
      final hasPending = await algorithm.checkForPendingVerification();
      if (hasPending) {
        if (kDebugMode) {
          print('🎯 RANDOM VERIFICATION SERVICE: Found pending verification from server');
        }
        return; // Don't create new if pending exists
      }
      
      // Check again if service is still running before proceeding
      if (!_isRunning) {
        if (kDebugMode) {
          print('🎯 RANDOM VERIFICATION SERVICE: Check cancelled - service stopped during execution');
        }
        return;
      }
      
      // Try to trigger a new random verification
      final triggered = await algorithm.tryTriggerVerification();
      if (triggered) {
        if (kDebugMode) {
          print('🎯 RANDOM VERIFICATION SERVICE: Successfully triggered random verification');
        }
      } else {
        if (kDebugMode) {
          print('🎯 RANDOM VERIFICATION SERVICE: Random verification not triggered (conditions not met)');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('🎯 RANDOM VERIFICATION SERVICE: Error during check: $e');
      }
      // Continue running even if check fails - don't crash the service
    }
  }
  
  /// Manual trigger for testing or when app comes to foreground
  Future<void> triggerManualCheck() async {
    if (kDebugMode) {
      print('🎯 RANDOM VERIFICATION SERVICE: Manual check requested');
    }
    
    await _checkAndTriggerVerification();
  }
  
  /// Get service status
  bool get isRunning => _isRunning;
  
  /// Get next check time
  DateTime? get nextCheckTime {
    if (_timer == null || !_isRunning) return null;
    return _nextCheckTime;
  }
}

// Provider for the background service
final randomVerificationBackgroundServiceProvider = Provider<RandomVerificationBackgroundService>((ref) {
  final service = RandomVerificationBackgroundService(ref);
  
  // Automatically start the service when created
  service.start();
  
  // Clean up when disposed
  ref.onDispose(() {
    try {
      if (kDebugMode) {
        print('🎯 RANDOM VERIFICATION SERVICE: Provider disposing, stopping service');
      }
      service.stop();
    } catch (e) {
      if (kDebugMode) {
        print('🎯 RANDOM VERIFICATION SERVICE: Error during provider disposal (non-fatal): $e');
      }
    }
  });
  
  return service;
});

// Helper provider to trigger manual checks
final triggerRandomVerificationCheckProvider = FutureProvider.family<void, void>((ref, _) async {
  final service = ref.read(randomVerificationBackgroundServiceProvider);
  await service.triggerManualCheck();
});