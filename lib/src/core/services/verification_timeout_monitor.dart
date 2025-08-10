import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/verification_provider.dart';

class VerificationTimeoutMonitor {
  static const Duration _checkInterval = Duration(minutes: 1);
  
  Timer? _timer;
  final Ref _ref;
  bool _isRunning = false;
  bool _urgentAlertSent = false;
  bool _timeoutWarningSent = false;
  String? _lastVerificationId;
  
  VerificationTimeoutMonitor(this._ref);
  
  /// Start monitoring verification timeouts
  void start() {
    if (_isRunning) return;
    
    _isRunning = true;
    
    if (kDebugMode) {
      print('🔔 TIMEOUT MONITOR: Starting verification timeout monitoring');
    }
    
    // Check immediately on start
    _checkTimeouts();
    
    // Schedule periodic checks every minute
    _timer = Timer.periodic(_checkInterval, (timer) {
      _checkTimeouts();
    });
  }
  
  /// Stop the timeout monitor
  void stop() {
    if (!_isRunning) return;
    
    try {
      _timer?.cancel();
      _timer = null;
      _isRunning = false;
      _resetState();
      
      if (kDebugMode) {
        print('🔔 TIMEOUT MONITOR: Stopped verification timeout monitoring');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔔 TIMEOUT MONITOR: Error during stop (non-fatal): $e');
      }
      // Force cleanup
      _timer = null;
      _isRunning = false;
      _resetState();
    }
  }
  
  /// Check for pending verification timeouts and send alerts
  Future<void> _checkTimeouts() async {
    if (!_isRunning) return;
    
    try {
      final verificationNotifier = _ref.read(verificationProvider.notifier);
      final currentRequest = _ref.read(currentVerificationRequestProvider);
      
      if (currentRequest == null) {
        // No active request, reset state
        _resetState();
        return;
      }
      
      // Reset state if verification ID changed (new verification)
      if (_lastVerificationId != currentRequest.id) {
        _resetState();
        _lastVerificationId = currentRequest.id;
      }
      
      // Check if verification has expired
      if (currentRequest.isExpired) {
        if (kDebugMode) {
          print('🔔 TIMEOUT MONITOR: Verification expired');
        }
        _resetState();
        return;
      }
      
      final remainingMinutes = currentRequest.remainingTimeInMinutes ?? 0;
      
      if (kDebugMode) {
        print('🔔 TIMEOUT MONITOR: Checking verification ${currentRequest.id} - $remainingMinutes minutes remaining');
      }
      
      // Send timeout warning (2 minutes or less)
      if (verificationNotifier.needsTimeoutWarning && !_timeoutWarningSent) {
        if (kDebugMode) {
          print('🔔 TIMEOUT MONITOR: Sending timeout warning ($remainingMinutes minutes left)');
        }
        
        await verificationNotifier.sendTimeoutWarning();
        _timeoutWarningSent = true;
      }
      
      // Send urgent alert (5 minutes or less, but not already sent timeout warning)
      else if (verificationNotifier.needsUrgentAlert && !_urgentAlertSent) {
        if (kDebugMode) {
          print('🔔 TIMEOUT MONITOR: Sending urgent alert ($remainingMinutes minutes left)');
        }
        
        await verificationNotifier.sendUrgentAlert();
        _urgentAlertSent = true;
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('🔔 TIMEOUT MONITOR: Error during timeout check: $e');
      }
      // Continue monitoring even if check fails
    }
  }
  
  /// Reset monitoring state
  void _resetState() {
    _urgentAlertSent = false;
    _timeoutWarningSent = false;
    _lastVerificationId = null;
  }
  
  /// Manual trigger for testing
  Future<void> triggerManualCheck() async {
    if (kDebugMode) {
      print('🔔 TIMEOUT MONITOR: Manual timeout check requested');
    }
    
    await _checkTimeouts();
  }
  
  /// Force send urgent alert (for testing)
  Future<void> forceUrgentAlert() async {
    try {
      final verificationNotifier = _ref.read(verificationProvider.notifier);
      await verificationNotifier.sendUrgentAlert();
      _urgentAlertSent = true;
      
      if (kDebugMode) {
        print('🔔 TIMEOUT MONITOR: Force sent urgent alert');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔔 TIMEOUT MONITOR: Error force sending urgent alert: $e');
      }
    }
  }
  
  /// Force send timeout warning (for testing)
  Future<void> forceTimeoutWarning() async {
    try {
      final verificationNotifier = _ref.read(verificationProvider.notifier);
      await verificationNotifier.sendTimeoutWarning();
      _timeoutWarningSent = true;
      
      if (kDebugMode) {
        print('🔔 TIMEOUT MONITOR: Force sent timeout warning');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔔 TIMEOUT MONITOR: Error force sending timeout warning: $e');
      }
    }
  }
  
  /// Get monitor status
  bool get isRunning => _isRunning;
  
  /// Get current monitoring state
  Map<String, dynamic> get monitoringState => {
    'isRunning': _isRunning,
    'urgentAlertSent': _urgentAlertSent,
    'timeoutWarningSent': _timeoutWarningSent,
    'lastVerificationId': _lastVerificationId,
    'nextCheckTime': _timer != null ? DateTime.now().add(_checkInterval) : null,
  };
}

// Provider for the timeout monitor
final verificationTimeoutMonitorProvider = Provider<VerificationTimeoutMonitor>((ref) {
  final monitor = VerificationTimeoutMonitor(ref);
  
  // Automatically start monitoring when created
  monitor.start();
  
  // Clean up when disposed
  ref.onDispose(() {
    try {
      if (kDebugMode) {
        print('🔔 TIMEOUT MONITOR: Provider disposing, stopping monitor');
      }
      monitor.stop();
    } catch (e) {
      if (kDebugMode) {
        print('🔔 TIMEOUT MONITOR: Error during provider disposal (non-fatal): $e');
      }
    }
  });
  
  return monitor;
});

// Helper provider to trigger manual timeout checks
final triggerTimeoutCheckProvider = FutureProvider.family<void, void>((ref, _) async {
  final monitor = ref.read(verificationTimeoutMonitorProvider);
  await monitor.triggerManualCheck();
});

// Helper provider for monitoring state
final timeoutMonitorStateProvider = Provider<Map<String, dynamic>>((ref) {
  final monitor = ref.watch(verificationTimeoutMonitorProvider);
  return monitor.monitoringState;
});