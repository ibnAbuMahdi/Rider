import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/hourly_tracking_models.dart';
import '../models/location_record.dart';
import '../models/campaign.dart';
import '../storage/hive_service.dart';
import 'notification_service.dart';
import 'earnings_service.dart';
import 'location_service.dart';
import 'location_service.dart';
import 'api_service.dart';
import 'location_api_service.dart';

class HourlyTrackingService {
  static HourlyTrackingService? _instance;
  static HourlyTrackingService get instance => _instance ??= HourlyTrackingService._();
  
  HourlyTrackingService._();

  // Configuration constants - optimized for debugging with faster sampling
  static const Duration SAMPLE_INTERVAL = Duration(seconds: 30);
  static const Duration RETRY_WINDOW = Duration(seconds: 20); // Reduced from 2 minutes
  static const int MAX_RETRY_ATTEMPTS = 2; // Reduced from 3 for faster debugging
  static const double MIN_ACCURACY_THRESHOLD = 2000.0; // 2km for debugging
  static const Duration MIN_BILLABLE_TIME = Duration(seconds: 30); // Reduced from 10 minutes for debugging
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

    // Try to recover any existing window from storage
    await _recoverCurrentWindow();
    
    // Sync any pending windows from previous sessions
    await syncPendingWindows();

    // Start periodic sampling
    _startPeriodicSampling();
    
    // Start window processing timer (every 3 minutes for debugging)
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

    // Clear current window from storage
    await HiveService.clearCurrentHourlyWindow();

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
      if (_isTracking) {
        if (kDebugMode) {
          final now = DateTime.now();
          final withinHours = _isWithinWorkingHours();
          print('⏰ SAMPLING CHECK: Current time: ${now.hour}:${now.minute}, within working hours: $withinHours, tracking: $_isTracking');
        }
        
        // For debugging: Allow tracking outside working hours, but log it
        if (_isWithinWorkingHours() || kDebugMode) {
          await _attemptLocationSample();
        }
      }
    });
  }

  /// Start window processing (every 3 minutes for debugging)
  void _startWindowProcessing() {
    final now = DateTime.now();
    // Start processing immediately, then every 3 minutes
    Timer(const Duration(seconds: 5), () {
      _processWindow();
      _windowProcessingTimer = Timer.periodic(const Duration(minutes: 3), (timer) {
        _processWindow();
      });
    });
  }

  /// Process current window and start new one
  Future<void> _processWindow() async {
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
    if (kDebugMode) {
      print('⏰ Attempting location sample (attempt ${_currentRetryCount + 1}/${MAX_RETRY_ATTEMPTS + 1})');
    }
    
    try {
      final position = await _getLocationSample();
      
      if (position != null) {
        if (kDebugMode) {
          print('⏰ Got location sample: accuracy ${position.accuracy.toStringAsFixed(1)}m');
        }
        await _processSample(position);
        _currentRetryCount = 0;
        return;
      } else {
        if (kDebugMode) {
          print('⏰ Location sample returned null');
        }
      }
      
      // Retry if poor accuracy or failed
      if (_currentRetryCount < MAX_RETRY_ATTEMPTS) {
        _currentRetryCount++;
        final retryDelay = Duration(seconds: 5 * _currentRetryCount); // Faster exponential backoff for debugging
        
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
      // Try high accuracy first with longer timeout for debugging
      final highAccuracyPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 30), // Increased from 15s
      );
      
      if (highAccuracyPosition.accuracy <= 2000.0) {
        return highAccuracyPosition;
      }
      
      // Fall back to medium accuracy with longer timeout
      final bestPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium, // Less demanding
        timeLimit: const Duration(seconds: 30), // Increased from 15s
      );
      
      // For debugging, accept any position (even if accuracy is poor)
      if (kDebugMode && bestPosition.accuracy > MIN_ACCURACY_THRESHOLD) {
        print('⚠️ Using poor accuracy location for debugging: ${bestPosition.accuracy.toStringAsFixed(1)}m');
      }
      return bestPosition; // Accept any position for debugging
          
      return null;
      
    } catch (e) {
      if (kDebugMode) {
        print('🚨 Location sampling failed: $e');
      }
      
      // Final fallback: try to get last known position for debugging
      try {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          if (kDebugMode) {
            print('🔄 Using last known position as fallback: accuracy ${lastKnown.accuracy.toStringAsFixed(1)}m');
          }
          return lastKnown;
        }
      } catch (fallbackError) {
        if (kDebugMode) {
          print('🚨 Last known position fallback failed: $fallbackError');
        }
      }
      
      return null;
    }
  }

  /// Process a valid location sample
  /// IMPORTANT: All location samples are recorded regardless of geofence status.
  /// Only samples INSIDE the geofence count towards earnings calculations.
  /// This ensures continuous location tracking while maintaining proper earnings logic.
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
    
    try {
      // Get geofence from LocationService
      final locationService = LocationService.instance;
      final assignments = locationService.geofenceAssignments;
      
      if (kDebugMode) {
        print('🔍 GEOFENCE CHECK: Looking for geofence ID: $_currentGeofenceId');
        print('🔍 Available assignments:');
        for (final assignment in assignments) {
          print('🔍   - ${assignment.geofenceName}: ${assignment.geofenceId}');
        }
      }
      
      for (final assignment in assignments) {
        if (assignment.geofenceId == _currentGeofenceId) {
          // Calculate distance from geofence center using assignment data
          final distance = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            assignment.centerLatitude,
            assignment.centerLongitude,
          );
          
          // Check if within radius (add small buffer for GPS accuracy)
          final radiusMeters = assignment.radiusMeters.toDouble();
          final isInside = distance <= (radiusMeters + 50); // 50m buffer
          
          if (kDebugMode) {
            print('📍 Geofence check: ${isInside ? "INSIDE" : "OUTSIDE"} (distance: ${distance.toStringAsFixed(1)}m, radius: ${radiusMeters}m)');
          }
          
          return isInside;
        }
      }
      
      if (kDebugMode) {
        print('⚠️ Geofence $_currentGeofenceId not found in assignments');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking geofence position: $e');
      }
      return false;
    }
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

  /// Start a new tracking window (3-minute windows for debugging)
  Future<void> _startNewWindow() async {
    final now = DateTime.now();
    final windowStart = now; // Start window at current time
    final windowEnd = windowStart.add(const Duration(minutes: 3)); // 3-minute windows

    _currentWindow = HourlyTrackingWindow(
      id: _uuid.v4(),
      startTime: windowStart,
      endTime: windowEnd,
      geofenceId: _currentGeofenceId!,
      campaignId: _currentCampaignId!,
      assignmentId: _currentAssignmentId, // Add assignment ID for earnings attribution
      samples: [],
      status: WindowStatus.active,
      failureEvents: [],
    );

    await _saveCurrentWindow();

    if (kDebugMode) {
      final startStr = '${windowStart.hour.toString().padLeft(2, '0')}:${windowStart.minute.toString().padLeft(2, '0')}';
      final endStr = '${windowEnd.hour.toString().padLeft(2, '0')}:${windowEnd.minute.toString().padLeft(2, '0')}';
      print('⏰ Started new 3-minute window: $startStr-$endStr');
    }
  }

  /// Finalize current window and process for earnings immediately
  Future<void> _finalizeCurrentWindow() async {
    if (_currentWindow == null) return;

    _currentWindow = _currentWindow!.copyWith(
      status: _isValidWindow(_currentWindow!) ? WindowStatus.completed : WindowStatus.invalid,
    );

    if (kDebugMode) {
      print('⏰ Finalized window: ${_currentWindow!.status}, ${_currentWindow!.samples.length} samples');
    }
    
    // Process earnings immediately if window is valid
    if (_currentWindow!.status == WindowStatus.completed) {
      await _calculateWindowEarnings(_currentWindow!);
    }
    
    // Save the processed window
    await _saveCompletedWindow(_currentWindow!);

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
        // Save to pending sync even if below minimum for backend validation
        await HiveService.saveCompletedHourlyWindow(window);
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

      // Check network connectivity before making API calls
      final hasNetwork = await _hasNetworkConnectivity();
      if (!hasNetwork) {
        if (kDebugMode) {
          print('🌐 No network connectivity - saving window locally for later sync');
        }
        // Save to pending sync when offline
        await HiveService.saveCompletedHourlyWindow(window);
        return;
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
          print('  - Amount: ₦$backendAmount');
          print('  - Effective time: $backendMinutes minutes');
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
        // Save to pending sync for retry when connection is restored
        await HiveService.saveCompletedHourlyWindow(window);
        return;
      }

    } catch (e) {
      if (kDebugMode) {
        print('🚨 Failed to calculate window earnings: $e');
      }
      // Save to pending sync for retry when connection is restored
      await HiveService.saveCompletedHourlyWindow(window);
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
      if (kDebugMode) {
        print('⏰ EFFECTIVE TIME: Insufficient geofence samples: ${geofenceSamples.length} < $MIN_SAMPLES_REQUIRED');
      }
      return Duration.zero;
    }

    Duration totalTime = Duration.zero;
    
    if (kDebugMode) {
      print('⏰ EFFECTIVE TIME: Calculating from ${geofenceSamples.length} geofence samples');
    }
    
    for (int i = 0; i < geofenceSamples.length - 1; i++) {
      final currentSample = geofenceSamples[i];
      final nextSample = geofenceSamples[i + 1];
      
      final segmentDuration = nextSample.timestamp.difference(currentSample.timestamp);
      
      if (kDebugMode) {
        print('⏰   Segment $i: ${segmentDuration.inSeconds}s (${segmentDuration.inMilliseconds}ms)');
      }
      
      // Cap segment duration to prevent anomalies (max 2 minutes between samples for 30s sampling)
      if (segmentDuration <= const Duration(minutes: 2)) {
        totalTime += segmentDuration;
        if (kDebugMode) {
          print('⏰     Added to total (within 2min cap)');
        }
      } else {
        if (kDebugMode) {
          print('⏰     Skipped (exceeds 2min cap)');
        }
      }
    }
    
    if (kDebugMode) {
      print('⏰ EFFECTIVE TIME: Total calculated: ${totalTime.inSeconds}s (${totalTime.inMilliseconds}ms)');
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

      // Ensure minimum billable time (30 seconds for debugging)
      if (effectiveTime.inSeconds < 30) {
        return 0.0;
      }

      // Round up minutes for billing
      final effectiveMinutes = effectiveTime.inMinutes.toDouble();
      final billableMinutes = (effectiveMinutes % 1 > 0) ? effectiveMinutes.ceil() : effectiveMinutes.toInt();

      // Get hourly rate from current assignment (uses SAME data as home screen)
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
        print('  - Hourly rate: ₦$hourlyRate/hr');
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
        window.samples.map((s) => s.accuracy <= 2000 ? 1.0 : 0.5).reduce((a, b) => a + b) / totalSamples;
    
    return ((geofenceRatio + accuracyScore) / 2 - failurePenalty).clamp(0.0, 1.0);
  }

  /// Check if current time is within working hours (7 AM - 6 PM)
  bool _isWithinWorkingHours() {
    final now = DateTime.now();
    final hour = now.hour;
    return hour >= WORKING_START_HOUR && hour < WORKING_END_HOUR;
  }

  /// Check if device has network connectivity
  Future<bool> _hasNetworkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking connectivity: $e');
      }
      return false; // Assume offline if error
    }
  }

  /// Validate if window has sufficient data for earnings calculation
  bool _isValidWindow(HourlyTrackingWindow window) {
    final geofenceSamples = window.samples.where((s) => s.isWithinGeofence).length;
    final effectiveTime = _calculateEffectiveWorkingTime(window);
    final hasMinimumTime = effectiveTime >= MIN_BILLABLE_TIME;
    
    if (kDebugMode) {
      print('⏰ WINDOW VALIDATION:');
      print('⏰   Total samples: ${window.samples.length}');
      print('⏰   Geofence samples: $geofenceSamples (required: >= $MIN_SAMPLES_REQUIRED)');
      print('⏰   Effective time: ${effectiveTime.inMilliseconds}ms / ${effectiveTime.inSeconds}s (required: >= ${MIN_BILLABLE_TIME.inSeconds}s)');
      print('⏰   Samples check: ${geofenceSamples >= MIN_SAMPLES_REQUIRED}');
      print('⏰   Time check: $hasMinimumTime');
      print('⏰   Overall valid: ${geofenceSamples >= MIN_SAMPLES_REQUIRED && hasMinimumTime}');
    }
    
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

  /// Get the hourly rate from the current assignment (uses SAME data as home screen)
  Future<double> _getCurrentHourlyRate() async {
    try {
      // Get rate from LocationService assignments (SAME data as home screen uses)
      final locationService = LocationService.instance;
      final assignments = locationService.geofenceAssignments;
      
      if (kDebugMode) {
        print('🔍 DEBUGGING RATE LOOKUP:');
        print('   - Current geofence ID: $_currentGeofenceId');
        print('   - Current assignment ID: $_currentAssignmentId');
        print('   - Available assignments: ${assignments.length}');
        for (int i = 0; i < assignments.length; i++) {
          final a = assignments[i];
          print('   - [$i] ${a.geofenceName} (ID: ${a.geofenceId}) - Type: ${a.rateType} - Rate: ₦${a.ratePerHour}/hr');
        }
      }
      
      // Look for current geofence assignment
      for (final assignment in assignments) {
        if (assignment.geofenceId == _currentGeofenceId && 
            assignment.rateType == 'per_hour') {
          final rate = assignment.ratePerHour ?? 0.0;
          if (kDebugMode) {
            print('✅ FOUND EXACT MATCH: ₦$rate/hr for ${assignment.geofenceName} (${assignment.geofenceId})');
            print('   - This is the SAME rate the home screen should display!');
          }
          return rate;
        }
      }
      
      // Third: If we have assignment ID, look for any per_hour assignment
      if (_currentAssignmentId != null) {
        for (final assignment in assignments) {
          if (assignment.id == _currentAssignmentId && 
              assignment.rateType == 'per_hour') {
            final rate = assignment.ratePerHour ?? 0.0;
            if (kDebugMode) {
              print('📊 Found hourly rate from assignment ID: ₦$rate/hr for assignment ${assignment.id}');
            }
            return rate;
          }
        }
      }
      
      // No rate found - return 0.0 instead of hardcoded 500.0 fallback
      if (kDebugMode) {
        print('⚠️ No hourly rate found. Using 0.0 instead of fallback rate');
        print('  - Available assignments: ${assignments.length}');
        for (final assignment in assignments) {
          print('    - ${assignment.geofenceName} (${assignment.rateType}): ₦${assignment.ratePerHour}/hr');
        }
      }
      return 0.0;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting hourly rate: $e');
      }
      return 0.0;
    }
  }

  /// Periodic sync method to be called from background services
  static Future<void> performPeriodicSync() async {
    try {
      final instance = HourlyTrackingService.instance;
      
      // Check connectivity before attempting sync
      final hasNetwork = await instance._hasNetworkConnectivity();
      if (!hasNetwork) {
        if (kDebugMode) {
          print('🌐 PERIODIC SYNC: No network connectivity - skipping sync');
        }
        return;
      }
      
      await instance.syncPendingWindows();
      
      if (kDebugMode) {
        print('⏰ PERIODIC SYNC: Completed hourly tracking sync');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ PERIODIC SYNC: Failed: $e');
      }
    }
  }

  /// Check if there are pending windows that need sync
  static bool hasPendingWindows() {
    try {
      final pendingWindows = HiveService.getPendingSyncWindows();
      return pendingWindows.isNotEmpty;
    } catch (e) {
      return false;
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
        print('🕐 EARNINGS UPDATE: Added ₦$backendAmount to LocationService for assignment $assignmentId');
        print('🕐 Total earnings now: ₦${locationService.totalGeofenceEarnings}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to update LocationService earnings: $e');
      }
    }
  }

  /// Recover current window from storage after app restart
  Future<void> _recoverCurrentWindow() async {
    try {
      final windowData = HiveService.getCurrentHourlyWindow();
      if (windowData != null) {
        // Recreate window from stored data
        _currentWindow = _windowFromJson(windowData);
        
        if (kDebugMode) {
          print('🔄 Recovered current window: ${_currentWindow?.id} with ${_currentWindow?.samples.length ?? 0} samples');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to recover current window: $e');
      }
    }
  }

  /// Create window from JSON data
  HourlyTrackingWindow? _windowFromJson(Map<String, dynamic> data) {
    try {
      final window = HourlyTrackingWindow(
        id: data['id'] ?? _uuid.v4(),
        geofenceId: data['geofence_id'] ?? _currentGeofenceId ?? '',
        assignmentId: data['assignment_id'] ?? _currentAssignmentId,
        campaignId: data['campaign_id'] ?? _currentCampaignId ?? '',
        startTime: DateTime.tryParse(data['start_time'] ?? '') ?? DateTime.now(),
        endTime: DateTime.tryParse(data['end_time'] ?? '') ?? DateTime.now(),
        samples: [],
        status: WindowStatus.active,
        failureEvents: [],
      );
      
      // Restore samples
      final samplesData = List<Map<String, dynamic>>.from(data['samples'] ?? []);
      for (final sampleData in samplesData) {
        final sample = LocationSample(
          id: sampleData['id'] ?? _uuid.v4(),
          latitude: sampleData['latitude']?.toDouble() ?? 0.0,
          longitude: sampleData['longitude']?.toDouble() ?? 0.0,
          accuracy: sampleData['accuracy']?.toDouble() ?? 0.0,
          timestamp: DateTime.tryParse(sampleData['timestamp'] ?? '') ?? DateTime.now(),
          isWithinGeofence: sampleData['is_within_geofence'] ?? false,
          speed: sampleData['speed']?.toDouble(),
          heading: sampleData['heading']?.toDouble(),
        );
        window.addSample(sample);
      }
      
      return window;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to create window from JSON: $e');
      }
      return null;
    }
  }

  /// Sync pending hourly tracking windows with backend when online
  Future<void> syncPendingWindows() async {
    try {
      // Check network connectivity before attempting sync
      final hasNetwork = await _hasNetworkConnectivity();
      if (!hasNetwork) {
        if (kDebugMode) {
          print('🌐 SYNC: No network connectivity - skipping sync');
        }
        return;
      }

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
        
        // Cap segment duration to prevent anomalies (max 2 minutes for 30s sampling)
        if (segmentMinutes <= 2) {
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
    final accuracyScore = samples.map((s) => (s['accuracy'] ?? 100) <= 2000 ? 1.0 : 0.5).reduce((a, b) => a + b) / samples.length;
    
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