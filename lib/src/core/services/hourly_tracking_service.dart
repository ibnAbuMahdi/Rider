import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import '../models/hourly_tracking_models.dart';
import '../models/location_record.dart';
import '../models/campaign.dart';
import '../storage/hive_service.dart';
import 'notification_service.dart';
import 'earnings_service.dart';
import 'location_service.dart';
import 'api_service.dart';
import 'location_api_service.dart';

class HourlyTrackingService {
  static HourlyTrackingService? _instance;
  static HourlyTrackingService get instance => _instance ??= HourlyTrackingService._();
  
  HourlyTrackingService._();

  // Configuration constants based on requirements
  static const Duration SAMPLE_INTERVAL = Duration(minutes: 5);
  static const Duration RETRY_WINDOW = Duration(minutes: 2);
  static const int MAX_RETRY_ATTEMPTS = 3;
  static const double MIN_ACCURACY_THRESHOLD = 50.0; // meters
  static const Duration MIN_BILLABLE_TIME = Duration(minutes: 10);
  static const int MIN_SAMPLES_REQUIRED = 2;
  
  // Working hours: 7 AM to 6 PM (universal)
  static const int WORKING_START_HOUR = 7;
  static const int WORKING_END_HOUR = 18;

  Timer? _samplingTimer;
  Timer? _retryTimer;
  Timer? _windowProcessingTimer;
  
  int _currentRetryCount = 0;
  HourlyTrackingWindow? _currentWindow;
  final List<HourlyTrackingWindow> _completedWindows = [];
  bool _isTracking = false;
  String? _currentGeofenceId;
  String? _currentCampaignId;
  String? _currentAssignmentId;  // Track assignment ID for proper earnings attribution
  
  // Initialize services - simplified for now to avoid complex dependencies
  final NotificationService _notificationService = NotificationService();
  // TODO: Initialize EarningsService properly when needed
  EarningsService? _earningsService;
  
  EarningsService get earningsService {
    _earningsService ??= EarningsService(ApiService.instance, LocationApiService(ApiService.instance));
    return _earningsService!;
  }
  final Uuid _uuid = const Uuid();

  /// Start hourly tracking for a specific geofence assignment
  Future<void> startHourlyTracking({
    required String geofenceId,
    required String campaignId,
    String? assignmentId,
  }) async {
    if (_isTracking) {
      await stopHourlyTracking();
    }

    _currentGeofenceId = geofenceId;
    _currentCampaignId = campaignId;
    _currentAssignmentId = assignmentId;
    _isTracking = true;

    if (kDebugMode) {
      print('⏰ Starting hourly tracking for geofence: $geofenceId');
    }

    // Start periodic sampling
    _startPeriodicSampling();
    
    // Start window processing timer (every hour)
    _startWindowProcessing();
    
    // TODO: Implement showTrackingNotification in NotificationService
    // await _notificationService.showTrackingNotification(
    //   'Hourly Tracking Active',
    //   'Earning ₦/hour while in geofence area'
    // );
  }

  /// Stop hourly tracking
  Future<void> stopHourlyTracking() async {
    _isTracking = false;
    _samplingTimer?.cancel();
    _retryTimer?.cancel();
    _windowProcessingTimer?.cancel();

    // Process any pending window
    if (_currentWindow != null) {
      await _finalizeCurrentWindow();
    }

    // Process all completed windows
    await _processCompletedWindows();

    _currentGeofenceId = null;
    _currentCampaignId = null;
    _currentAssignmentId = null;
    _currentWindow = null;

    if (kDebugMode) {
      print('⏰ Hourly tracking stopped');
    }
  }

  /// Start periodic location sampling
  void _startPeriodicSampling() {
    _samplingTimer = Timer.periodic(SAMPLE_INTERVAL, (timer) async {
      if (_isWithinWorkingHours() && _isTracking) {
        await _attemptLocationSample();
      }
    });
  }

  /// Start window processing (every hour on the hour)
  void _startWindowProcessing() {
    final now = DateTime.now();
    final nextHour = DateTime(now.year, now.month, now.day, now.hour + 1, 0, 0);
    final timeUntilNextHour = nextHour.difference(now);

    // Wait until next hour, then process every hour
    Timer(timeUntilNextHour, () {
      _processHourlyWindow();
      _windowProcessingTimer = Timer.periodic(const Duration(hours: 1), (timer) {
        _processHourlyWindow();
      });
    });
  }

  /// Process current hour window and start new one
  Future<void> _processHourlyWindow() async {
    if (_currentWindow != null) {
      await _finalizeCurrentWindow();
    }
    await _startNewWindow();
  }

  /// Attempt to get a location sample with retry logic
  Future<void> _attemptLocationSample() async {
    if (_currentWindow == null) {
      await _startNewWindow();
    }

    _currentRetryCount = 0;
    await _getSampleWithRetry();
  }

  /// Get location sample with retry mechanism
  Future<void> _getSampleWithRetry() async {
    try {
      final position = await _getLocationSample();
      
      if (position != null && position.accuracy <= MIN_ACCURACY_THRESHOLD) {
        await _processSample(position);
        _currentRetryCount = 0;
        return;
      }
      
      // Retry if poor accuracy or failed
      if (_currentRetryCount < MAX_RETRY_ATTEMPTS) {
        _currentRetryCount++;
        final retryDelay = Duration(seconds: 30 * _currentRetryCount); // Exponential backoff
        
        _retryTimer = Timer(retryDelay, () => _getSampleWithRetry());
        
        if (kDebugMode) {
          print('⏰ Retrying location sample (attempt ${_currentRetryCount + 1}/$MAX_RETRY_ATTEMPTS)');
        }
      } else {
        await _handleSamplingFailure();
      }
    } catch (e) {
      await _handleSamplingError(e);
    }
  }

  /// Get a single location sample
  Future<Position?> _getLocationSample() async {
    try {
      // Try high accuracy first
      final highAccuracyPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      
      if (highAccuracyPosition.accuracy <= 20.0) {
        return highAccuracyPosition;
      }
      
      // Fall back to best available
      final bestPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 15),
      );
      
      return bestPosition.accuracy <= MIN_ACCURACY_THRESHOLD ? bestPosition : null;
      
    } catch (e) {
      if (kDebugMode) {
        print('🚨 Location sampling failed: $e');
      }
      return null;
    }
  }

  /// Process a valid location sample
  Future<void> _processSample(Position position) async {
    if (_currentWindow == null) return;

    final sample = LocationSample(
      id: _uuid.v4(),
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      timestamp: DateTime.now(),
      isWithinGeofence: await _isPositionInGeofence(position),
      speed: position.speed,
      heading: position.heading,
    );

    _currentWindow!.addSample(sample);

    if (kDebugMode) {
      print('⏰ Sample added: ${sample.isWithinGeofence ? "IN" : "OUT"} geofence, accuracy: ${sample.accuracy.toStringAsFixed(1)}m');
    }

    // Save current window state
    await _saveCurrentWindow();
  }

  /// Check if position is within current geofence
  Future<bool> _isPositionInGeofence(Position position) async {
    if (_currentGeofenceId == null) return false;
    
    // TODO: Implement actual geofence boundary checking
    // This should use the geofence boundaries from the campaign data
    // For now, return true as placeholder
    return true;
  }

  /// Handle sampling failure after max retries
  Future<void> _handleSamplingFailure() async {
    if (_currentWindow != null) {
      _currentWindow!.addFailureEvent(DateTime.now(), 'max_retries_exceeded');
      await _saveCurrentWindow();
    }

    if (kDebugMode) {
      print('🚨 Location sampling failed after $MAX_RETRY_ATTEMPTS attempts');
    }
  }

  /// Handle sampling error
  Future<void> _handleSamplingError(dynamic error) async {
    if (_currentWindow != null) {
      _currentWindow!.addFailureEvent(DateTime.now(), error.toString());
      await _saveCurrentWindow();
    }

    if (kDebugMode) {
      print('🚨 Location sampling error: $error');
    }
  }

  /// Start a new tracking window
  Future<void> _startNewWindow() async {
    final now = DateTime.now();
    final hourStart = DateTime(now.year, now.month, now.day, now.hour, 0, 0);
    final hourEnd = hourStart.add(const Duration(hours: 1));

    _currentWindow = HourlyTrackingWindow(
      id: _uuid.v4(),
      startTime: hourStart,
      endTime: hourEnd,
      geofenceId: _currentGeofenceId!,
      campaignId: _currentCampaignId!,
      samples: [],
      status: WindowStatus.active,
      failureEvents: [],
    );

    await _saveCurrentWindow();

    if (kDebugMode) {
      print('⏰ Started new window: ${hourStart.hour}:00-${hourEnd.hour}:00');
    }
  }

  /// Finalize current window and queue for processing
  Future<void> _finalizeCurrentWindow() async {
    if (_currentWindow == null) return;

    _currentWindow = _currentWindow!.copyWith(
      status: _isValidWindow(_currentWindow!) ? WindowStatus.completed : WindowStatus.invalid,
    );

    _completedWindows.add(_currentWindow!);
    await _saveCompletedWindow(_currentWindow!);
    
    if (kDebugMode) {
      print('⏰ Finalized window: ${_currentWindow!.status}, ${_currentWindow!.samples.length} samples');
    }

    _currentWindow = null;
  }

  /// Process all completed windows for earnings calculation
  Future<void> _processCompletedWindows() async {
    final validWindows = _completedWindows.where((w) => w.status == WindowStatus.completed).toList();
    
    for (final window in validWindows) {
      await _calculateWindowEarnings(window);
    }
    
    _completedWindows.clear();
  }

  /// Calculate earnings for a completed window using backend as source of truth
  Future<void> _calculateWindowEarnings(HourlyTrackingWindow window) async {
    try {
      final effectiveTime = _calculateEffectiveWorkingTime(window);
      
      if (effectiveTime < MIN_BILLABLE_TIME) {
        if (kDebugMode) {
          print('⏰ Window below minimum billable time: ${effectiveTime.inMinutes} minutes');
        }
        return;
      }

      // Calculate local earnings for immediate UI update
      final localAmount = await _calculateLocalEarnings(window, effectiveTime);
      if (localAmount > 0) {
        // Show local calculation immediately to improve UX
        // Use assignment ID for earnings attribution (UX consistency)
        if (_currentAssignmentId != null) {
          await _updateLocationServiceEarnings(_currentAssignmentId!, localAmount);
          if (kDebugMode) {
            print('⏰ LOCAL CALCULATION: ₦${localAmount.toStringAsFixed(2)} (will be updated with backend result) - Assignment: $_currentAssignmentId');
          }
        } else {
          if (kDebugMode) {
            print('⚠️ LOCAL CALCULATION: No assignment ID available, earnings not tracked');
          }
        }
      }

      // Convert location samples to API format
      final locationSamples = window.samples.map((sample) => {
        'id': sample.id,
        'latitude': sample.latitude,
        'longitude': sample.longitude,
        'accuracy': sample.accuracy,
        'timestamp': sample.timestamp.toIso8601String(),
        'is_within_geofence': sample.isWithinGeofence,
        'speed': sample.speed,
        'heading': sample.heading,
      }).toList();

      // Convert failure events to API format
      final failureEvents = window.failureEvents.map((event) => {
        'timestamp': event.timestamp.toIso8601String(),
        'reason': event.reason,
      }).toList();

      // Submit to backend for calculation with assignment context
      final result = await earningsService.submitHourlyTrackingWindow(
        windowId: window.id,
        geofenceId: window.geofenceId,
        assignmentId: _currentAssignmentId,  // Pass assignment ID for proper earnings attribution
        windowStart: window.startTime,
        locationSamples: locationSamples,
        failureEvents: failureEvents,
        effectiveMinutes: effectiveTime.inMinutes.toDouble(),
        trackingQuality: _calculateTrackingQuality(window),
      );
      
      if (kDebugMode && _currentAssignmentId != null) {
        print('⏰ BACKEND SUBMISSION: Included assignment ID $_currentAssignmentId for earnings attribution');
      }

      if (result != null && result['success'] == true) {
        final backendAmount = result['calculated_amount'];
        final backendMinutes = result['effective_minutes'];
        final backendCalc = result['backend_calculation'];
        
        if (kDebugMode) {
          print('⏰ Backend calculation completed:');
          print('  - Amount: ₦${backendAmount}');
          print('  - Effective time: ${backendMinutes} minutes');
          print('  - Status: ${result['status']}');
          print('  - Backend validation: ${backendCalc['working_hours_valid'] ? '✅' : '❌'} Working hours');
          print('  - Backend validation: ${backendCalc['minimum_time_met'] ? '✅' : '❌'} Minimum time');
          print('  - Backend validation: ${backendCalc['minimum_samples_met'] ? '✅' : '❌'} Minimum samples');
        }

        // Store backend calculation result locally for reference
        await _storeBackendCalculation(window, result);
        
        // Update LocationService with backend result (adjust for difference from local calculation)
        // Use assignment ID for earnings attribution (UX consistency)
        final backendAmountDouble = backendAmount.toDouble();
        final difference = backendAmountDouble - localAmount;
        if (difference != 0 && _currentAssignmentId != null) {
          await _updateLocationServiceEarnings(_currentAssignmentId!, difference);
          if (kDebugMode) {
            print('⏰ BACKEND ADJUSTMENT: ${difference > 0 ? '+' : ''}₦${difference.toStringAsFixed(2)} (Local: ₦${localAmount.toStringAsFixed(2)}, Backend: ₦${backendAmountDouble.toStringAsFixed(2)}) - Assignment: $_currentAssignmentId');
          }
        } else if (difference == 0) {
          if (kDebugMode) {
            print('⏰ BACKEND MATCH: Backend calculation matches local calculation (₦${backendAmountDouble.toStringAsFixed(2)})');
          }
        } else {
          if (kDebugMode) {
            print('⚠️ BACKEND ADJUSTMENT: No assignment ID available, adjustment not applied');
          }
        }
        
        // Show notification if earnings were calculated
        if (backendAmount > 0) {
          // TODO: Implement showEarningsNotification in NotificationService
          // await _notificationService.showEarningsNotification(
          //   'Hourly Earnings',
          //   '₦${backendAmount.toStringAsFixed(0)} earned for ${backendCalc['billable_minutes']} minutes'
          // );
        }
        
      } else {
        if (kDebugMode) {
          print('🚨 Backend calculation failed or returned invalid result');
        }
      }

    } catch (e) {
      if (kDebugMode) {
        print('🚨 Failed to calculate window earnings: $e');
      }
    }
  }

  /// Store backend calculation result locally
  Future<void> _storeBackendCalculation(HourlyTrackingWindow window, Map<String, dynamic> result) async {
    // TODO: Store backend calculation result for local reference and sync validation
    await HiveService.saveBackendEarningsCalculation(window.id, result);
  }

  /// Calculate effective working time within geofence
  Duration _calculateEffectiveWorkingTime(HourlyTrackingWindow window) {
    final geofenceSamples = window.samples.where((s) => s.isWithinGeofence).toList();
    
    if (geofenceSamples.length < MIN_SAMPLES_REQUIRED) {
      return Duration.zero;
    }

    Duration totalTime = Duration.zero;
    
    for (int i = 0; i < geofenceSamples.length - 1; i++) {
      final currentSample = geofenceSamples[i];
      final nextSample = geofenceSamples[i + 1];
      
      final segmentDuration = nextSample.timestamp.difference(currentSample.timestamp);
      
      // Cap segment duration to prevent anomalies (max 10 minutes between samples)
      if (segmentDuration <= const Duration(minutes: 10)) {
        totalTime += segmentDuration;
      }
    }
    
    return totalTime;
  }

  /// Calculate local earnings for immediate UI feedback (before backend calculation)
  Future<double> _calculateLocalEarnings(HourlyTrackingWindow window, Duration effectiveTime) async {
    try {
      // Check working hours (7 AM - 6 PM)
      final hour = window.startTime.hour;
      if (hour < 7 || hour >= 18) {
        return 0.0; // Outside working hours
      }

      // Ensure minimum billable time (10 minutes with rounding up)
      if (effectiveTime.inMinutes < 10) {
        return 0.0;
      }

      // Round up minutes for billing
      final effectiveMinutes = effectiveTime.inMinutes.toDouble();
      final billableMinutes = (effectiveMinutes % 1 > 0) ? effectiveMinutes.ceil() : effectiveMinutes.toInt();

      // Get hourly rate from current assignment
      final hourlyRate = await _getCurrentHourlyRate();
      if (hourlyRate <= 0) {
        if (kDebugMode) {
          print('⚠️ No valid hourly rate found for assignment');
        }
        return 0.0;
      }

      // Calculate earnings: (billable_minutes / 60) * hourly_rate
      final localEarnings = (billableMinutes / 60.0) * hourlyRate;

      if (kDebugMode) {
        print('🧮 LOCAL CALCULATION:');
        print('  - Effective minutes: ${effectiveMinutes.toStringAsFixed(1)}');
        print('  - Billable minutes: $billableMinutes');
        print('  - Hourly rate: ₦${hourlyRate}/hr');
        print('  - Local earnings: ₦${localEarnings.toStringAsFixed(2)}');
      }

      return localEarnings;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Local earnings calculation error: $e');
      }
      return 0.0;
    }
  }

  /// Calculate tracking quality score (0.0 - 1.0)
  double _calculateTrackingQuality(HourlyTrackingWindow window) {
    final totalSamples = window.samples.length;
    final geofenceSamples = window.samples.where((s) => s.isWithinGeofence).length;
    final failureCount = window.failureEvents.length;
    
    if (totalSamples == 0) return 0.0;
    
    final geofenceRatio = geofenceSamples / totalSamples;
    final failurePenalty = failureCount * 0.1;
    final accuracyScore = window.samples.isEmpty ? 0.0 : 
        window.samples.map((s) => s.accuracy <= 20 ? 1.0 : 0.5).reduce((a, b) => a + b) / totalSamples;
    
    return ((geofenceRatio + accuracyScore) / 2 - failurePenalty).clamp(0.0, 1.0);
  }

  /// Check if current time is within working hours (7 AM - 6 PM)
  bool _isWithinWorkingHours() {
    final now = DateTime.now();
    final hour = now.hour;
    return hour >= WORKING_START_HOUR && hour < WORKING_END_HOUR;
  }

  /// Validate if window has sufficient data for earnings calculation
  bool _isValidWindow(HourlyTrackingWindow window) {
    final geofenceSamples = window.samples.where((s) => s.isWithinGeofence).length;
    final hasMinimumTime = _calculateEffectiveWorkingTime(window) >= MIN_BILLABLE_TIME;
    
    return geofenceSamples >= MIN_SAMPLES_REQUIRED && hasMinimumTime;
  }

  /// Save current window to local storage
  Future<void> _saveCurrentWindow() async {
    if (_currentWindow != null) {
      await HiveService.saveHourlyTrackingWindow(_currentWindow!);
    }
  }

  /// Save completed window to local storage
  Future<void> _saveCompletedWindow(HourlyTrackingWindow window) async {
    await HiveService.saveCompletedHourlyWindow(window);
  }

  /// Get rider ID
  Future<String> _getRiderId() async {
    // TODO: Get from user session or storage
    return 'rider_id';
  }

  /// Get campaign name
  Future<String> _getCampaignName(String campaignId) async {
    // TODO: Get from campaign data
    return 'Campaign Name';
  }

  /// Get the hourly rate from the current assignment
  Future<double> _getCurrentHourlyRate() async {
    try {
      if (_currentAssignmentId == null) {
        // Fallback: get from LocationService's current geofence assignments
        final locationService = LocationService.instance;
        final assignments = locationService.geofenceAssignments;
        
        for (final assignment in assignments) {
          if (assignment.geofence?.id == _currentGeofenceId && 
              assignment.geofence?.rateType == 'per_hour') {
            final rate = assignment.geofence?.ratePerHour ?? 0.0;
            if (kDebugMode) {
              print('📊 Found hourly rate from LocationService: ₦${rate}/hr');
            }
            return rate;
          }
        }
      }
      
      // If we have assignment ID, try to get it from stored data
      // For now, return a fallback rate
      if (kDebugMode) {
        print('⚠️ Using fallback hourly rate - assignment data not accessible');
      }
      return 500.0; // Fallback rate
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting hourly rate: $e');
      }
      return 500.0; // Fallback rate
    }
  }

  /// Update LocationService with hourly earnings to refresh UI
  /// Uses assignment ID for proper earnings attribution (UX consistency)
  Future<void> _updateLocationServiceEarnings(String assignmentId, double backendAmount) async {
    try {
      final locationService = LocationService.instance;
      
      // Add the new earnings to the assignment earnings in LocationService
      // This will trigger UI updates through liveTrackingStatsProvider
      await locationService.addHourlyEarnings(assignmentId, backendAmount);
      
      if (kDebugMode) {
        print('🕐 EARNINGS UPDATE: Added ₦${backendAmount} to LocationService for assignment $assignmentId');
        print('🕐 Total earnings now: ₦${locationService.totalGeofenceEarnings}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to update LocationService earnings: $e');
      }
    }
  }

  /// Sync pending hourly tracking windows with backend when online
  Future<void> syncPendingWindows() async {
    try {
      final pendingWindows = HiveService.getPendingSyncWindows();
      if (pendingWindows.isEmpty) {
        if (kDebugMode) {
          print('⏰ SYNC: No pending hourly windows to sync');
        }
        return;
      }
      
      if (kDebugMode) {
        print('⏰ SYNC: Found ${pendingWindows.length} pending hourly windows to sync');
      }
      
      int syncedCount = 0;
      for (final windowData in pendingWindows) {
        try {
          final windowId = windowData['id'] ?? 'unknown';
          final geofenceId = windowData['geofence_id'] ?? '';
          final assignmentId = windowData['assignment_id'];
          final startTimeStr = windowData['start_time'] ?? '';
          
          if (windowId == 'unknown' || geofenceId.isEmpty || startTimeStr.isEmpty) {
            if (kDebugMode) {
              print('⚠️ SYNC: Skipping invalid window data: $windowId');
            }
            continue;
          }
          
          final windowStart = DateTime.tryParse(startTimeStr);
          if (windowStart == null) {
            if (kDebugMode) {
              print('⚠️ SYNC: Invalid start time for window: $windowId');
            }
            continue;
          }
          
          // Prepare samples and failure events
          final samples = List<Map<String, dynamic>>.from(windowData['samples'] ?? []);
          final failureEvents = List<Map<String, dynamic>>.from(windowData['failure_events'] ?? []);
          
          // Calculate effective minutes from stored samples
          final effectiveMinutes = _calculateEffectiveMinutesFromSamples(samples);
          final trackingQuality = _calculateTrackingQualityFromData(samples, failureEvents);
          
          // Submit to backend
          final result = await earningsService.submitHourlyTrackingWindow(
            windowId: windowId,
            geofenceId: geofenceId,
            assignmentId: assignmentId,
            windowStart: windowStart,
            locationSamples: samples,
            failureEvents: failureEvents,
            effectiveMinutes: effectiveMinutes,
            trackingQuality: trackingQuality,
          );
          
          if (result != null && result['success'] == true) {
            // Mark as synced
            await HiveService.markWindowSynced(windowId);
            syncedCount++;
            
            if (kDebugMode) {
              print('✅ SYNC: Successfully synced window $windowId (₦${result['calculated_amount']})');
            }
            
            // Update LocationService with backend earnings if assignment available
            if (assignmentId != null) {
              final backendAmount = result['calculated_amount']?.toDouble() ?? 0.0;
              if (backendAmount > 0) {
                await _updateLocationServiceEarnings(assignmentId, backendAmount);
              }
            }
          } else {
            if (kDebugMode) {
              print('❌ SYNC: Failed to sync window $windowId: ${result?['error'] ?? 'Unknown error'}');
            }
          }
          
        } catch (e) {
          if (kDebugMode) {
            print('❌ SYNC: Error syncing individual window: $e');
          }
        }
      }
      
      if (kDebugMode) {
        print('⏰ SYNC: Completed sync of $syncedCount/${pendingWindows.length} windows');
      }
      
      // Cleanup old synced windows
      await HiveService.cleanupSyncedWindows();
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ SYNC: Failed to sync pending hourly windows: $e');
      }
    }
  }
  
  /// Calculate effective minutes from location samples (offline calculation)
  double _calculateEffectiveMinutesFromSamples(List<Map<String, dynamic>> samples) {
    final geofenceSamples = samples.where((s) => s['is_within_geofence'] == true).toList();
    
    if (geofenceSamples.length < 2) {
      return 0.0;
    }
    
    double totalMinutes = 0.0;
    for (int i = 0; i < geofenceSamples.length - 1; i++) {
      try {
        final currentTime = DateTime.parse(geofenceSamples[i]['timestamp']);
        final nextTime = DateTime.parse(geofenceSamples[i + 1]['timestamp']);
        
        final segmentMinutes = nextTime.difference(currentTime).inMilliseconds / (1000 * 60);
        
        // Cap segment duration to prevent anomalies (max 10 minutes)
        if (segmentMinutes <= 10) {
          totalMinutes += segmentMinutes;
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Error calculating segment time: $e');
        }
      }
    }
    
    return totalMinutes;
  }
  
  /// Calculate tracking quality from stored data (offline calculation)
  double _calculateTrackingQualityFromData(List<Map<String, dynamic>> samples, List<Map<String, dynamic>> failureEvents) {
    if (samples.isEmpty) return 0.0;
    
    final geofenceRatio = samples.where((s) => s['is_within_geofence'] == true).length / samples.length;
    final failurePenalty = failureEvents.length * 0.1;
    final accuracyScore = samples.map((s) => (s['accuracy'] ?? 100) <= 20 ? 1.0 : 0.5).reduce((a, b) => a + b) / samples.length;
    
    final quality = ((geofenceRatio + accuracyScore) / 2 - failurePenalty);
    return quality.clamp(0.0, 1.0);
  }
  
  /// Get count of pending sync windows
  int get pendingSyncWindowsCount {
    return HiveService.getPendingSyncWindows().length;
  }

  // Getters for external monitoring
  bool get isTracking => _isTracking;
  HourlyTrackingWindow? get currentWindow => _currentWindow;
  int get completedWindowsCount => _completedWindows.length;
}