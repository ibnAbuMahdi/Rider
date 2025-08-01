import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../models/campaign.dart';
import '../providers/campaign_provider.dart';
import '../providers/location_provider.dart';
import '../providers/verification_provider.dart';
import '../storage/hive_service.dart';

class RandomVerificationAlgorithm {
  static const int _minIntervalHours = 24; // Once per day
  static const int _workingHourStart = 8; // 8 AM
  static const int _workingHourEnd = 18; // 8 PM
  static const double _stationarySpeedThreshold = 1.0; // Speed in m/s (3.6 km/h)
  static const Duration _stationaryDuration = Duration(minutes: 5); // Must be stationary for 5 minutes
  static const double _verificationProbability = 0.7; // 70% chance when conditions are met
  
  final Ref _ref;
  
  RandomVerificationAlgorithm(this._ref);
  
  /// Check if should trigger random verification based on geofence assignments
  Future<bool> shouldTriggerVerification() async {
    if (kDebugMode) {
      print('🎯 RANDOM VERIFICATION: Checking if should trigger verification');
    }
    
    // Check if rider has active geofence assignments
    final hasActiveGeofences = _ref.read(hasActiveGeofenceAssignmentsProvider);
    if (!hasActiveGeofences) {
      if (kDebugMode) {
        print('🎯 RANDOM VERIFICATION: No active geofence assignments - skipping');
      }
      return false;
    }
    
    // Check if already has pending verification
    final hasActive = _ref.read(hasActiveVerificationProvider);
    if (hasActive) {
      if (kDebugMode) {
        print('🎯 RANDOM VERIFICATION: Already has active verification - skipping');
      }
      return false;
    }
    
    // Check if already done today (once per day rule)
    final lastRequestTime = await _getLastVerificationTime();
    final now = DateTime.now();
    
    if (lastRequestTime != null) {
      final hoursSinceLastRequest = now.difference(lastRequestTime).inHours;
      if (hoursSinceLastRequest < _minIntervalHours) {
        if (kDebugMode) {
          print('🎯 RANDOM VERIFICATION: Already done today (${hoursSinceLastRequest}h < ${_minIntervalHours}h)');
        }
        return false;
      }
    }
    
    // Check working hours (8 AM to 6 PM)
    final currentHour = now.hour;
    if (currentHour < _workingHourStart || currentHour >= _workingHourEnd) {
      if (kDebugMode) {
        print('🎯 RANDOM VERIFICATION: Outside working hours (${currentHour}h not between ${_workingHourStart}h-${_workingHourEnd}h)');
      }
      return false;
    }
    
    // Check if rider is currently within an active geofence
    final currentPosition = _ref.read(locationProvider).currentPosition;
    if (currentPosition == null) {
      if (kDebugMode) {
        print('🎯 RANDOM VERIFICATION: No current position - skipping');
      }
      return false;
    }
    
    // Check if rider is stationary (speed below threshold)
    final speed = currentPosition.speed ?? 0.0;
    if (speed > _stationarySpeedThreshold) {
      if (kDebugMode) {
        print('🎯 RANDOM VERIFICATION: Rider is moving (${speed.toStringAsFixed(1)} m/s > ${_stationarySpeedThreshold} m/s)');
      }
      return false;
    }
    
    // Check if rider has been stationary long enough
    final isStationaryLongEnough = await _hasBeenStationaryLongEnough(currentPosition);
    if (!isStationaryLongEnough) {
      if (kDebugMode) {
        print('🎯 RANDOM VERIFICATION: Not stationary long enough (need ${_stationaryDuration.inMinutes} minutes)');
      }
      return false;
    }
    
    // Check if rider is within their assigned geofences
    final activeGeofences = _ref.read(activeGeofenceAssignmentsProvider);
    bool withinAssignedGeofence = false;
    
    for (final geofenceAssignment in activeGeofences) {
      final distance = _calculateDistance(
        currentPosition.latitude,
        currentPosition.longitude,
        geofenceAssignment.centerLatitude,
        geofenceAssignment.centerLongitude,
      );
      
      if (distance <= geofenceAssignment.radiusMeters) {
        withinAssignedGeofence = true;
        if (kDebugMode) {
          print('🎯 RANDOM VERIFICATION: Within assigned geofence: ${geofenceAssignment.geofenceName}');
        }
        break;
      }
    }
    
    if (!withinAssignedGeofence) {
      if (kDebugMode) {
        print('🎯 RANDOM VERIFICATION: Not within any assigned geofence - skipping');
      }
      return false;
    }
    
    // Random probability check
    final random = Random();
    final shouldTrigger = random.nextDouble() < _verificationProbability;
    
    if (kDebugMode) {
      print('🎯 RANDOM VERIFICATION: Probability check - should trigger: $shouldTrigger');
    }
    
    return shouldTrigger;
  }
  
  /// Trigger random verification if conditions are met
  Future<bool> tryTriggerVerification() async {
    if (kDebugMode) {
      print('🎯 RANDOM VERIFICATION: Attempting to trigger verification');
    }
    
    if (!await shouldTriggerVerification()) {
      return false;
    }
    
    // Get current position
    final currentPosition = _ref.read(locationProvider).currentPosition;
    if (currentPosition == null) {
      if (kDebugMode) {
        print('🎯 RANDOM VERIFICATION: No position available');
      }
      return false;
    }
    double? accuracy = currentPosition.accuracy;
    double formattedAccuracy = 0.0;
    if (accuracy != null) {
      String accString = accuracy.toStringAsFixed(2); // Start with 2 decimal places
      if (accString.replaceAll('.', '').length > 8) {
        // If total digits exceed 8, truncate
        // Find how many digits we need to keep before the decimal point
        int decimalIndex = accString.indexOf('.');
        int integerPartLength = decimalIndex == -1 ? accString.length : decimalIndex;

        int digitsToKeep = 8;
        if (decimalIndex != -1) { // If there's a decimal point, it counts as one of the 8 digits
          digitsToKeep--; // For the decimal point itself
          if (integerPartLength >= digitsToKeep) {
            // If integer part alone is 7 or more digits, we'll only have integer part
            accString = accString.substring(0, digitsToKeep);
          } else {
            // integerPartLength < digitsToKeep, so we can have decimal places
            int remainingDigits = digitsToKeep - integerPartLength;
            accString = accString.substring(0, decimalIndex + 1 + min(remainingDigits, 2));
          }
        } else {
           accString = accString.substring(0, min(accString.length, 8));
        }
      }
      formattedAccuracy = double.parse(accString);
    }
if (kDebugMode) {
        print('🎯 RANDOM VERIFICATION: Accuracy - $formattedAccuracy');
      }
    // Create verification request
    final verificationNotifier = _ref.read(verificationProvider.notifier);
    final request = await verificationNotifier.createRandomVerification(
      latitude: currentPosition.latitude,
      longitude: currentPosition.longitude,
      accuracy: formattedAccuracy,
    );
    
    if (request != null) {
      // Store timestamp
      await _saveLastVerificationTime(DateTime.now());
      
      if (kDebugMode) {
        print('🎯 RANDOM VERIFICATION: Successfully created verification request: ${request.id}');
      }
      
      return true;
    } else {
      if (kDebugMode) {
        final error = _ref.read(verificationProvider).error;
        print('🎯 RANDOM VERIFICATION: Failed to create verification request: $error');
      }
      return false;
    }
  }
  
  /// Check for pending verifications from server
  Future<bool> checkForPendingVerification() async {
    try {
      final verificationNotifier = _ref.read(verificationProvider.notifier);
      final pendingRequest = await verificationNotifier.checkForPendingVerification();
      
      if (pendingRequest != null) {
        if (kDebugMode) {
          print('🎯 RANDOM VERIFICATION: Found pending verification: ${pendingRequest.id}');
        }
        return true;
      }
      
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('🎯 RANDOM VERIFICATION: Error checking for pending verification: $e');
      }
      return false;
    }
  }
  
  /// Check if rider has been stationary long enough
  Future<bool> _hasBeenStationaryLongEnough(Position position) async {
    // Get recent location records to check if stationary
    // For now, we'll check based on the last known stationary time
    final lastStationaryTime = await _getLastStationaryTime();
    
    if (lastStationaryTime == null) {
      // First time being stationary, record it
      await _saveLastStationaryTime(DateTime.now());
      return false;
    }
    
    final timeSinceStationary = DateTime.now().difference(lastStationaryTime);
    
    // If enough time has passed while stationary
    if (timeSinceStationary >= _stationaryDuration) {
      return true;
    }
    
    return false;
  }
  
  /// Calculate distance between two points in meters
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // Earth radius in meters
    
    final double lat1Rad = lat1 * (pi / 180);
    final double lat2Rad = lat2 * (pi / 180);
    final double deltaLatRad = (lat2 - lat1) * (pi / 180);
    final double deltaLonRad = (lon2 - lon1) * (pi / 180);
    
    final double a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        sin(deltaLonRad / 2) * sin(deltaLonRad / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  Future<DateTime?> _getLastVerificationTime() async {
    return HiveService.getLastRandomVerificationTime();
  }
  
  Future<void> _saveLastVerificationTime(DateTime time) async {
    await HiveService.saveLastRandomVerificationTime(time);
  }
  
  Future<DateTime?> _getLastStationaryTime() async {
    return HiveService.getLastStationaryTime();
  }
  
  Future<void> _saveLastStationaryTime(DateTime time) async {
    await HiveService.saveLastStationaryTime(time);
  }
  
  Future<void> _clearStationaryTime() async {
    await HiveService.clearLastStationaryTime();
  }
  
  /// Get status information for debugging
  Future<Map<String, dynamic>> getStatusInfo() async {
    final hasActiveGeofences = _ref.read(hasActiveGeofenceAssignmentsProvider);
    final hasActiveRequest = _ref.read(hasActiveVerificationProvider);
    final currentPosition = _ref.read(locationProvider).currentPosition;
    final activeGeofences = _ref.read(activeGeofenceAssignmentsProvider);
    final lastRequestTime = await _getLastVerificationTime();
    final lastStationaryTime = await _getLastStationaryTime();
    final now = DateTime.now();
    
    return {
      'has_active_geofences': hasActiveGeofences,
      'active_geofences_count': activeGeofences.length,
      'has_active_request': hasActiveRequest,
      'has_position': currentPosition != null,
      'current_speed': currentPosition?.speed,
      'is_stationary': (currentPosition?.speed ?? 0.0) <= _stationarySpeedThreshold,
      'last_request_time': lastRequestTime?.toIso8601String(),
      'hours_since_last_request': lastRequestTime != null
          ? now.difference(lastRequestTime).inHours
          : null,
      'last_stationary_time': lastStationaryTime?.toIso8601String(),
      'minutes_stationary': lastStationaryTime != null
          ? now.difference(lastStationaryTime).inMinutes
          : null,
      'current_hour': now.hour,
      'is_working_hours': now.hour >= _workingHourStart && now.hour < _workingHourEnd,
      'can_request_verification': await shouldTriggerVerification(),
    };
  }
}

// Provider
final randomVerificationAlgorithmProvider = Provider<RandomVerificationAlgorithm>((ref) {
  return RandomVerificationAlgorithm(ref);
});

// Helper providers
final canTriggerRandomVerificationProvider = FutureProvider<bool>((ref) async {
  final algorithm = ref.watch(randomVerificationAlgorithmProvider);
  return algorithm.shouldTriggerVerification();
});

final randomVerificationStatusProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final algorithm = ref.watch(randomVerificationAlgorithmProvider);
  return algorithm.getStatusInfo();
});