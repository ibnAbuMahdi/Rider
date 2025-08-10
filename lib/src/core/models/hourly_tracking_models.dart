import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'hourly_tracking_models.g.dart';

/// Represents a time window for hourly tracking (typically 1 hour)
@HiveType(typeId: 15)
@JsonSerializable()
class HourlyTrackingWindow {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final DateTime startTime;
  
  @HiveField(2)
  final DateTime endTime;
  
  @HiveField(3)
  final String geofenceId;
  
  @HiveField(4)
  final String campaignId;
  
  @HiveField(5)
  final List<LocationSample> samples;
  
  @HiveField(6)
  final WindowStatus status;
  
  @HiveField(7)
  final List<FailureEvent> failureEvents;

  const HourlyTrackingWindow({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.geofenceId,
    required this.campaignId,
    required this.samples,
    required this.status,
    required this.failureEvents,
  });

  factory HourlyTrackingWindow.fromJson(Map<String, dynamic> json) =>
      _$HourlyTrackingWindowFromJson(json);

  Map<String, dynamic> toJson() => _$HourlyTrackingWindowToJson(this);

  HourlyTrackingWindow copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    String? geofenceId,
    String? campaignId,
    List<LocationSample>? samples,
    WindowStatus? status,
    List<FailureEvent>? failureEvents,
  }) {
    return HourlyTrackingWindow(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      geofenceId: geofenceId ?? this.geofenceId,
      campaignId: campaignId ?? this.campaignId,
      samples: samples ?? this.samples,
      status: status ?? this.status,
      failureEvents: failureEvents ?? this.failureEvents,
    );
  }

  /// Add a location sample to this window
  void addSample(LocationSample sample) {
    samples.add(sample);
  }

  /// Add a failure event to this window
  void addFailureEvent(DateTime timestamp, String reason) {
    failureEvents.add(FailureEvent(timestamp: timestamp, reason: reason));
  }

  /// Get duration of this window
  Duration get duration => endTime.difference(startTime);

  /// Get samples that are within the geofence
  List<LocationSample> get geofenceSamples => 
      samples.where((sample) => sample.isWithinGeofence).toList();

  /// Check if window is within working hours (7 AM - 6 PM)
  bool get isWithinWorkingHours {
    final hour = startTime.hour;
    return hour >= 7 && hour < 18;
  }

  /// Calculate effective working time (time spent within geofence)
  Duration get effectiveWorkingTime {
    final geofenceSamples = this.geofenceSamples;
    
    if (geofenceSamples.length < 2) {
      return Duration.zero;
    }

    Duration totalTime = Duration.zero;
    
    for (int i = 0; i < geofenceSamples.length - 1; i++) {
      final currentSample = geofenceSamples[i];
      final nextSample = geofenceSamples[i + 1];
      
      final segmentDuration = nextSample.timestamp.difference(currentSample.timestamp);
      
      // Cap segment duration to prevent anomalies
      if (segmentDuration <= const Duration(minutes: 10)) {
        totalTime += segmentDuration;
      }
    }
    
    return totalTime;
  }

  @override
  String toString() {
    return 'HourlyTrackingWindow{id: $id, start: $startTime, samples: ${samples.length}, status: $status}';
  }
}

/// Status of a tracking window
@HiveType(typeId: 16)
enum WindowStatus {
  @HiveField(0)
  active,      // Currently collecting samples
  
  @HiveField(1)
  completed,   // Ready for earnings calculation
  
  @HiveField(2)
  invalid,     // Insufficient/poor quality data
  
  @HiveField(3)
  offline,     // No connectivity during window
  
  @HiveField(4)
  processed;   // Earnings calculated and submitted
}

/// Individual location sample within a tracking window
@HiveType(typeId: 17)
@JsonSerializable()
class LocationSample {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final double latitude;
  
  @HiveField(2)
  final double longitude;
  
  @HiveField(3)
  final double accuracy;
  
  @HiveField(4)
  final DateTime timestamp;
  
  @HiveField(5)
  final bool isWithinGeofence;
  
  @HiveField(6)
  final double? speed;
  
  @HiveField(7)
  final double? heading;

  const LocationSample({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
    required this.isWithinGeofence,
    this.speed,
    this.heading,
  });

  factory LocationSample.fromJson(Map<String, dynamic> json) =>
      _$LocationSampleFromJson(json);

  Map<String, dynamic> toJson() => _$LocationSampleToJson(this);

  LocationSample copyWith({
    String? id,
    double? latitude,
    double? longitude,
    double? accuracy,
    DateTime? timestamp,
    bool? isWithinGeofence,
    double? speed,
    double? heading,
  }) {
    return LocationSample(
      id: id ?? this.id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      timestamp: timestamp ?? this.timestamp,
      isWithinGeofence: isWithinGeofence ?? this.isWithinGeofence,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
    );
  }

  /// Check if this is a high-accuracy sample (< 20 meters)
  bool get isHighAccuracy => accuracy < 20.0;

  /// Check if this is an acceptable accuracy sample (< 50 meters)
  bool get isAcceptableAccuracy => accuracy < 50.0;

  @override
  String toString() {
    return 'LocationSample{lat: $latitude, lng: $longitude, accuracy: ${accuracy.toStringAsFixed(1)}m, inGeofence: $isWithinGeofence}';
  }
}

/// Represents a failure event during tracking
@HiveType(typeId: 18)
@JsonSerializable()
class FailureEvent {
  @HiveField(0)
  final DateTime timestamp;
  
  @HiveField(1)
  final String reason;

  const FailureEvent({
    required this.timestamp,
    required this.reason,
  });

  factory FailureEvent.fromJson(Map<String, dynamic> json) =>
      _$FailureEventFromJson(json);

  Map<String, dynamic> toJson() => _$FailureEventToJson(this);

  @override
  String toString() {
    return 'FailureEvent{timestamp: $timestamp, reason: $reason}';
  }
}

/// Result of earnings calculation for a tracking window
class EarningsResult {
  final bool isSuccess;
  final double amount;
  final Duration duration;
  final String? geofenceId;
  final DateTime? windowStart;
  final DateTime? windowEnd;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;

  const EarningsResult({
    required this.isSuccess,
    required this.amount,
    required this.duration,
    this.geofenceId,
    this.windowStart,
    this.windowEnd,
    this.errorMessage,
    this.metadata,
  });

  factory EarningsResult.success({
    required double amount,
    required Duration duration,
    String? geofenceId,
    DateTime? windowStart,
    DateTime? windowEnd,
    Map<String, dynamic>? metadata,
  }) {
    return EarningsResult(
      isSuccess: true,
      amount: amount,
      duration: duration,
      geofenceId: geofenceId,
      windowStart: windowStart,
      windowEnd: windowEnd,
      metadata: metadata,
    );
  }

  factory EarningsResult.invalid(String errorMessage) {
    return EarningsResult(
      isSuccess: false,
      amount: 0.0,
      duration: Duration.zero,
      errorMessage: errorMessage,
    );
  }

  @override
  String toString() {
    return isSuccess 
        ? 'EarningsResult{success: $amount, duration: ${duration.inMinutes}m}'
        : 'EarningsResult{error: $errorMessage}';
  }
}